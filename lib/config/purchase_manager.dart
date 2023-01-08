
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert' as convert;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:isolate_json/isolate_json.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class LatestReceiptInfos{

  static const String _latestReceiptInfosKey = '_latestReceiptInfosKey';

  late String _productId;
  late String _purchaseDate;  // 支付时间（时间戳）
  late String _expiresDate;   // 过期时间
  late String _receipt;       // 收据信息，如果过期，则使用该收据请求最新的购买信息
  String? _isTrialPeriod = 'false'; // 是否试用期
  String? _ownershipType; // 购买类型：购买者、共享者
  String? _subscriptionGroupId; //

  String get productId => _productId;
  String get receipt => _receipt;
  int get purchaseDate => int.tryParse(_purchaseDate) ?? 0;
  int get expiresDate => int.tryParse(_expiresDate) ?? 0;
  bool get isTrialPeriod => _isTrialPeriod == 'true';
  String? get ownershipType => _ownershipType;
  String? get subscriptionGroupId => _subscriptionGroupId;

  static LatestReceiptInfos? fromMap(Map map){
    String? _productId = map['product_id'];
    String? _purchaseDate = map['purchase_date_ms'];
    String? _expiresDate = map['expires_date_ms'];
    String? _receipt = map['latest_receipt'];
    String? _isTrialPeriod = map['is_trial_period'];
    String? _ownershipType = map['in_app_ownership_type'];
    String? _subscriptionGroupId = map['subscription_group_identifier'];
    if(_productId == null || _purchaseDate == null || _expiresDate == null || _receipt == null){ return null; }
    var info = LatestReceiptInfos();
    info._productId = _productId;
    info._receipt = _receipt;
    info._purchaseDate = _purchaseDate;
    info._expiresDate = _expiresDate;
    info._isTrialPeriod = _isTrialPeriod;
    info._ownershipType = _ownershipType;
    info._subscriptionGroupId = _subscriptionGroupId;
    return info;
  }

  Map<String, String> toMap(){
    Map<String, String> map = { "product_id": _productId, "purchase_date_ms": _purchaseDate, "expires_date_ms": _expiresDate, "latest_receipt": receipt };
    if(_isTrialPeriod != null){ map["is_trial_period"] = _isTrialPeriod!; }
    if(_ownershipType != null){ map["in_app_ownership_type"] = _ownershipType!; }
    if(_subscriptionGroupId != null){ map["subscription_group_identifier"] = _subscriptionGroupId!; }
    return map;
  }

  update() async{
    List infos = await loadPurchaseInfos();
    infos.removeWhere((element) => element['product_id'] == _productId);
    infos.add(toMap());
    await savePurchaseInfos(infos);
  }

  static Future<List> loadPurchaseInfos() async{
    var sp = await SharedPreferences.getInstance();
    String? oldJson = sp.getString(LatestReceiptInfos._latestReceiptInfosKey);
    // if (kDebugMode) { print('Old Purchase Infos:$oldJson'); }
    List infos = [];
    if(oldJson != null && oldJson.isNotEmpty){
      List? oldInfos = convert.jsonDecode(oldJson);
      if(oldInfos != null){
        infos = oldInfos;
      }
    }
    return infos;
  }

  static savePurchaseInfos(List newInfos) async{
    var sp = await SharedPreferences.getInstance();
    var newJson = convert.jsonEncode(newInfos);
    if (kDebugMode) { print('New Purchase Infos:$newJson'); }
    sp.setString(LatestReceiptInfos._latestReceiptInfosKey, newJson);
  }

  /// 是否有效
  static bool isEnabled(dynamic map){
    if(map is Map){
      int? expiresDate = int.tryParse(map['expires_date_ms']);
      if(expiresDate != null){
        DateTime ed = DateTime.fromMillisecondsSinceEpoch(expiresDate);
        if (kDebugMode) { print('订阅:${map['product_id']} 过期时间：' + ed.toString()); }
        return DateTime.now().millisecondsSinceEpoch < ed.millisecondsSinceEpoch;
      }
    }
    return false;
  }

  static Future<bool> alreadyPurchase() async{
    /// 国内安卓免费
    if(Platform.isAndroid){
      return true;
    }
    /// 恢复购买，如果订阅过期，则尝试恢复购买

    /// 如果为false,则移除本地存储的购买信息
    var infos = await loadPurchaseInfos();
    List needRemove = [];
    List<String> tickets = []; // 已过期的票据，用于更新订阅信息
    bool valid = false;  // 是否有效
    for(final info in infos){
      if(isEnabled(info)){
        valid = true;
      }else{
        needRemove.add(info);
        if(info is Map){
          var latestTicket = info['latest_receipt'];
          if(latestTicket != null && latestTicket is String && !tickets.contains(latestTicket)){
            tickets.add(latestTicket);
          }
        }
      }
    }
    if(needRemove.isNotEmpty){
      infos.removeWhere((element) => needRemove.contains(element));
      await savePurchaseInfos(infos);
      if(!valid && tickets.isNotEmpty){ // 本地有购买信息，但全都过期了，则开始更新订阅信息
        await EasyLoading.show();
        for(var ticket in tickets){
          // var res = await PurchaseManager.verifyPurchase(ticket);
          // if(res == VerifyPurchaseResult.success){
          //   EasyLoading.dismiss();
          //   return true;
          // }
          await PurchaseManager.verifyPurchase(ticket);
        }
        EasyLoading.dismiss();
        return await alreadyPurchase();
      }
    }
    return valid;
  }



  static clearAll(){

  }

  @override
  String toString() {
    DateTime pd = DateTime.fromMillisecondsSinceEpoch(purchaseDate);
    DateTime ed = DateTime.fromMillisecondsSinceEpoch(expiresDate);
    DateTime now = DateTime.now();
    return '$productId - 最后付费时间:$pd - 过期时间:$ed - ${now.millisecondsSinceEpoch > ed.millisecondsSinceEpoch ? '已过期' : '未过期'} - $ownershipType';
  }

}

// Purchase
enum VerifyPurchaseResult {
  success, // 成功且订阅有效
  failure, // 失败(订阅过期、无效、无法重试)
  needRetry, // 需要重试
  netError,// 网络出错
}

class PurchaseManager{

  /// 校验结果：0:成功且订阅有效   -1:失败(网络问题，需重试)   1:成功(订阅已经失效或者过期)   2:服务器问题，可稍后重试
  static Future<VerifyPurchaseResult> verifyPurchase(String verificationData) async{
    if (Platform.isIOS) {
      // final verificationData = purchaseDetails.verificationData.serverVerificationData;
      final Dio dio = Dio();
      dio.options.headers['Accept'] = 'application/json';
      dio.options.headers['Content-Type'] = 'application/json';
      final Map<String, dynamic> data = {'receipt-data': verificationData, 'password': Config.iosVerifyReceiptPassword};
      data['exclude-old-transactions'] = true;
      final body = await JsonIsolate().encodeJson(data);
      var response = await dio.post(Config.iosVerifyReceiptUrl, data: body);
      if(response.statusCode != 200){ return VerifyPurchaseResult.netError; }
      /*
      21000 没有使用HTTP POST请求方法向App Store发出请求。
      21001 此状态代码不再由App Store发送。
      21002 收据数据属性中的数据不正确或服务遇到了临时问题。再试一次。
      21003 这张收据无法验证。
      21004 您提供的共享密钥与您帐户文件中的共享密钥不匹配。
      21005 收据服务器暂时无法提供收据。再试一次。
      21006 这张收据有效，但订阅费已过期。当此状态代码返回到服务器时，接收数据也被解码并作为响应的一部分返回。只返回iOS 6风格的自动更新订阅交易收据。
      21007 这张收据来自测试环境，但它被发送到生产环境以进行验证。
      21008 这张收据来自生产环境，但它被发送到测试环境以进行验证。
      21009 内部数据访问错误。稍后再试。
      21010 用户帐号找不到或已被删除。
      */
      var status = response.data['status'];
      if(status == 21007){
        response = await dio.post(Config.iosSandboxVerifyReceiptUrl, data: body);
        status = response.data['status'];
      }
      if(status != 0){ // 出了问题
        if(status == 21005 || status == 21002){
          return VerifyPurchaseResult.needRetry;
        }else{
          return VerifyPurchaseResult.failure;
        }
      }
      List<LatestReceiptInfos> infos = [];
      var latestReceiptInfos = response.data['latest_receipt_info']; // 最新的付费
      if(latestReceiptInfos != null && latestReceiptInfos is List && latestReceiptInfos.isNotEmpty){
        for(var receiptInfo in latestReceiptInfos){
          if(receiptInfo is Map){
            String? productId = receiptInfo['product_id'];
            String? purchaseDate = receiptInfo['purchase_date_ms'];
            String? expiresDate = receiptInfo['expires_date_ms'];
            if(productId == null || purchaseDate == null || expiresDate == null){ continue; }
            DateTime ed = DateTime.fromMillisecondsSinceEpoch(int.tryParse(expiresDate) ?? 0);
            DateTime now = DateTime.now();
            receiptInfo['latest_receipt'] = response.data['latest_receipt'] ?? verificationData;
            var info = LatestReceiptInfos.fromMap(receiptInfo);
            if (kDebugMode) { print(info); }
            if(now.millisecondsSinceEpoch < ed.millisecondsSinceEpoch && info != null){ // 有效
              infos.add(info);
            }
          }
        }
      }
      if(infos.isEmpty){
        await LatestReceiptInfos.clearAll();
        return VerifyPurchaseResult.failure;
      }
      for(var info in infos){ await info.update(); }
      return VerifyPurchaseResult.success;
    }else{

      return VerifyPurchaseResult.failure;
    }
  }


}
