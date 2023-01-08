import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/pages/web_page.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../provider/global_color.dart';
import '../../provider/global_language.dart';
import '../config/purchase_manager.dart';
import 'common/rotation_widget.dart';

const String _kMonthSubscriptionId = 'monthly_vip';
const String _kYearSubscriptionId = 'year_vip';
const List<String> _kProductIds = <String>[ _kMonthSubscriptionId, _kYearSubscriptionId,];

class StoreView extends StatefulWidget {
  const StoreView({Key? key}) : super(key: key);

  /// 如果购买成功，则返回true,否则返回空
  static Future<bool?> show(BuildContext context) async {
    return await showMaterialModalBottomSheet<bool>(
      backgroundColor:Colors.transparent,
      context: context,
      builder: (context){
        return const StoreView();
      }
    );
  }

  @override
  _StoreViewState createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView>{

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  List<ProductDetails> _products = <ProductDetails>[];   /// 商品列表
  bool _isAvailable = false;  /// 商店是否可用
  bool _loading = true; /// 初始化中
  String? _queryProductError;  /// 获取商品失败

  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      if (kDebugMode) { print('------ ------ purchaseUpdated.listen done'); }
      _subscription.cancel();
    }, onError: (Object error) {
      if (kDebugMode) { print('------ ------ purchaseUpdated.listen error: $error'); }
    });
    initStoreInfo();
    super.initState();
  }
  /// 加载商品信息
  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = <ProductDetails>[];
        _loading = false;
      });
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
    }
    /// 请求商品详情
    final ProductDetailsResponse productDetailResponse = await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _loading = false;
      });
      return;
    }
    // for(var p in productDetailResponse.productDetails){
    //   // id:year_subscription - title:年度订阅 - desc:高级版，年度订阅 - price:¥68 - rawPrice:68.0 - code:CNY - symbol:¥
    //   if (kDebugMode) {
    //     print('id:${p.id} - title:${p.title} - desc:${p.description} - price:${p.price} - rawPrice:${p.rawPrice} - code:${p.currencyCode} - symbol:${p.currencySymbol}');
    //   }
    // }
    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _loading = false;
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    super.dispose();
  }

  Widget topWidget(BuildContext context){
    var colors =  C.current(context);
    var language = L.current(context);
    return SingleChildScrollView(
      child: Container(
        color: colors.bgOnBody_1,
        padding: const EdgeInsets.only(left: 15,right: 15,top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: Image.asset('static/images/logo.png',width: 30,height: 30,)
                    //SvgPicture.asset('static/images/logo.svg',width: 30,height: 30,color: colors.tintTertiary,)
                  )
                ),
                Container(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(language.app_name,style: TextStyle(color: colors.tintPrimary,fontSize: F.f18,fontWeight: F.bold))
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),//circular(10),
                  child: Container(
                    color: const Color(0xFFFFDC83),
                    padding: const EdgeInsets.only(top: 3,bottom: 3,left: 4,right: 4),
                    child: Text('PRO',style: TextStyle(color: const Color(0xFFC97E38),fontSize: F.f18,fontWeight: F.bold),),
                  )
                )
              ],
            ),
            Container(
              padding: const EdgeInsets.only(top: 10,bottom: 10),
              child: Text(language.full_functional,style: TextStyle(color: colors.tintSecondary,fontSize: F.f16))
            ),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),//circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 10, left: 10, bottom: 10,right: 10),
                color: colors.bgOnBody_2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.unlimited_diary_creation, style: TextStyle(color: colors.tintPrimary,fontSize: F.f16)),
                    Text(language.limited_number_of_pictures, style: TextStyle(color: colors.tintPrimary,fontSize: F.f16)),
                    Text('...', style: TextStyle(color: colors.tintPrimary,fontSize: F.f16))
                  ],
                ),
              )
            ),
            bottomWidget(context, true)
          ]
        )
      )
    );
  }

  Widget bottomWidget(BuildContext context, bool clear){
    var colors =  C.current(context);
    var language = L.current(context);
    Color clearColor = Colors.transparent;

    Widget body = Container();
    if(!_isAvailable && !_loading){
      body = Container( // "Syncing files to device Max iPhone..."
        padding: const EdgeInsets.only(top: 10,bottom: 10),
        child: Text('The store is not available',style: TextStyle(color: clear ? clearColor : colors.tintError,fontSize: F.f16,fontWeight: F.medium),textAlign: TextAlign.center,)
      );
    }else{
      if (_queryProductError == null) {
        List<Widget> list = [];
        for(var product in _products){
          var priceStr = '${product.price}/${product.id == _kMonthSubscriptionId ? language.month : language.year}';
          var bgColor = product.id == _kMonthSubscriptionId ? (clear ? clearColor : const Color(0x4D4873F2)) : (clear ? clearColor : const Color(0xFF4873F2));
          var titleColor = product.id == _kMonthSubscriptionId ? (clear ? clearColor : const Color(0xFF4873F2)) : (clear ? clearColor : const Color(0xFFFFFFFF));
          list.add(Expanded(
              child: GestureDetector(
                  onTap: (){ _buy(product); },
                  child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: Container(
                          color: bgColor,
                          padding: const EdgeInsets.only(top: 10,bottom: 10),
                          child: Center(child: Text(priceStr,style: TextStyle(color: titleColor,fontSize: F.f18,fontWeight: F.bold)))
                      )
                  )
              )
          ));
          list.add(const SizedBox(width: 10));
        }
        if(list.isNotEmpty){ list.removeLast(); }
        body = Row(children: list);
      } else {
        body = Container( // "Syncing files to device Max iPhone..."
          padding: const EdgeInsets.only(top: 10,bottom: 10),
          child: Text(_queryProductError ?? '',style: TextStyle(color: clear ? clearColor : colors.tintError,fontSize: F.f16,fontWeight: F.medium),textAlign: TextAlign.center,)
        );
      }
      if (_loading) {
        body = RotationWidget(child: SvgPicture.asset('static/images/state_loading.svg',width: 40,height: 40,color: (clear ? clearColor : colors.tintPrimary)));
      }
    }


    return Container(
      padding: EdgeInsets.only(top: 10,left: (clear ? 0 : 15),right: (clear ? 0 : 15)),
      color: clear ? clearColor : colors.bgOnBody_1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          body,
          Container(
            padding: const EdgeInsets.only(top: 10),
            child: RichText(
              text: TextSpan(
                text: language.subscribe_to_the_declaration_0,
                style: TextStyle(color: clear ? clearColor : colors.tintTertiary,fontSize: F.f14),
                children: [
                  TextSpan(
                    text: language.privacy_policy,
                    style: TextStyle(color: clear ? clearColor : const Color(0xFF4873F2)),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> WebPage(url: 'http://kingtup.cn/tree_yszc',title: language.privacy_policy)));
                      },
                  ),
                  TextSpan( text: language.subscribe_to_the_declaration_1),
                  TextSpan(
                    text: language.user_agreement,
                    style: TextStyle(color: clear ? clearColor : const Color(0xFF4873F2)),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () { //
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> WebPage(url: 'http://kingtup.cn/tree_fwtk',title: language.user_agreement)));
                      },
                  ),
                  TextSpan( text: language.subscribe_to_the_declaration_2),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: (){ _restorePurchases(); },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.only(top: 10,bottom: 10,left: 10),
                  child: Text(language.restore_purchase,style: TextStyle(color: clear ? clearColor : const Color(0xFF4873F2),fontSize: F.f16),),
                )
              )
            ]
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var maxHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),//circular(10),
      child: Material(
        color:colors.bgOnBody_1,
        child: SafeArea(
          top: false,
          child: Container(
            color: Colors.transparent,
            constraints: BoxConstraints( maxHeight:maxHeight ),
            child:Stack(
              children: <Widget>[
                topWidget(context),
                Positioned(bottom: 0, left: 0, right: 0, child: bottomWidget(context, false)),
                Positioned(
                  top: 0, right: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: (){Navigator.pop(context);},
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      child: SvgPicture.asset('static/images/item_delete_bg.svg',width: 26, height: 26),
                    ),
                  )
                )
              ]
            )
          )
        )
      )
    );
  }

  _buy(ProductDetails product){
    EasyLoading.show();
    late PurchaseParam purchaseParam;
    if (Platform.isAndroid) {
      purchaseParam = GooglePlayPurchaseParam(productDetails: product, changeSubscriptionParam: null);
    } else {
      purchaseParam = PurchaseParam( productDetails: product );
    }
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  _restorePurchases() async{
    EasyLoading.show();
    await _inAppPurchase.restorePurchases();
  }

  /// 购买相关事件处理
  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    var language = L.current(context, listen: false);
    /// 恢复购买，返回空数组
    if(purchaseDetailsList.isEmpty){
      if (kDebugMode) { print('没有商品 !'); }
      EasyLoading.dismiss();
    }
    /// 完成购买
    for(var purchaseDetails in purchaseDetailsList){
      // if (kDebugMode) { print('${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
      if (purchaseDetails.status != PurchaseStatus.pending && purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
    /// 过滤重复的收据,连续的订阅，会返回多个验证数据一样的
    List<PurchaseDetails> noRepeatList = [];
    for(final PurchaseDetails purchaseDetails in purchaseDetailsList){
      bool exist = false;
      for(final PurchaseDetails p in noRepeatList){
        if(p.status == purchaseDetails.status && p.verificationData.serverVerificationData == purchaseDetails.verificationData.serverVerificationData){
          exist = true;
          break;
        }
      }
      if(!exist){ noRepeatList.add(purchaseDetails); }
    }
    ///
    for (final PurchaseDetails purchaseDetails in noRepeatList) {
      if (kDebugMode) { print(purchaseDetails.productID); }
      if (purchaseDetails.status == PurchaseStatus.pending) { /// 购买中，加载购买窗口
        // if (kDebugMode) { print('购买中:${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
      } else if (purchaseDetails.status == PurchaseStatus.error || purchaseDetails.status == PurchaseStatus.canceled) { /// 购买失败\取消
        // if (kDebugMode) { print('购买未成功:${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
        EasyLoading.dismiss();
        if(purchaseDetails.status == PurchaseStatus.error){
          EasyLoading.showToast(purchaseDetails.error != null ? purchaseDetails.error!.message : language.operation_failure);
        }
        if(purchaseDetails.status == PurchaseStatus.canceled){
          EasyLoading.showToast(language.operation_cancelled);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) { /// 购买成功、恢复成功
        final VerifyPurchaseResult validResult = await PurchaseManager.verifyPurchase(purchaseDetails.verificationData.serverVerificationData);
        EasyLoading.dismiss();
        if(validResult == VerifyPurchaseResult.success){
          EasyLoading.showToast(language.operation_success);
          Navigator.of(context).pop<bool>(true);
        }else if(validResult == VerifyPurchaseResult.failure){
          if(purchaseDetails.status == PurchaseStatus.purchased){
            EasyLoading.showToast(language.operation_failure);
          }
        }else if(validResult == VerifyPurchaseResult.netError){
          EasyLoading.showToast(language.network_error_please_try_again_later);
        }else if(validResult == VerifyPurchaseResult.needRetry){
          EasyLoading.showToast(language.server_error_please_try_again_later);
        }
      }
    }
  }
}

/// 可以实现支付队列委托来提供完成事务所需的信息。
class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    if (kDebugMode) {
      print('shouldContinueTransaction:${transaction.transactionIdentifier}');
    }
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
