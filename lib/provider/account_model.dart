// 各个平台的账户信息

import 'package:flutter/cupertino.dart';
import 'package:treediary/config/storage_manager.dart';

const accountTypes = ['github','gitlab','gitee','git'];

class Account {

  late String _type; //
  late String _url; //
  late String _userName;  // 用户名
  late String _password;  //
  late String _email;  //
  late String _token;  //
  late String _profile;  // 用户头像
  late String _createTime; // 创建时间
  late String _updateTime; // 更新时间


}

class AccountModel extends ChangeNotifier {
  // TODO:加密读写
  static const kAccountKey = 'kAccountKey';

  late List<Account> _accountList;

  AccountModel(){
    _accountList = [];

    var jsonStr = StorageManager.sharedPreferences.getString(kAccountKey);
    if (jsonStr == null){
      // save(false);
    }else{
      debugPrint(jsonStr);
      // var jsonObjc = convert.jsonDecode(jsonStr);
      // if (jsonObjc['language'] != null){ _language = jsonObjc['language']; }
      // if (jsonObjc['theme'] != null){ _theme = jsonObjc['theme']; }
      // if (jsonObjc['fontLevel'] != null){ _fontLevel = jsonObjc['fontLevel']; }
      // if (jsonObjc['lastTime'] != null){ _lastTime = jsonObjc['lastTime']; }
      // if (jsonObjc['userName'] != null){ _userName = jsonObjc['userName']; }
      // if (jsonObjc['userEmail'] != null){ _userEmail = jsonObjc['userEmail']; }
    }
  }
}