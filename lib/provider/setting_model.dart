// 设置信息
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'dart:convert' as convert;
import 'package:treediary/generated/l10n.dart';
import 'package:treediary/provider/global_language.dart';
import 'package:treediary/provider/provider_sql.dart';

import 'package:treediary/provider/themes.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../config/config.dart';
import '../config/global_data.dart';
import 'global_color.dart';

// http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
const languageTypes = [
  {'auto' : 'System'},
  {'zh_Hans' : '中文-简体'},
  // {'zh_Hant' : '中文-繁体'},
  {'en' : 'English'},
  // 'de', 'es', 'fr', 'hu', 'id', 'it', 'ja', 'ko', 'pl', 'pt', 'ru', 'sv', 'vi'
];

// 12个等级,iOS系统可以设置12个等级
const fontLevels = [
  {'auto':0},// 跟随系统
  {'l1':1},{'l2':2},{'l3':3},{'l4':4},{'l5':5},{'l6':6},
  {'l7':7},{'l8':8},{'l9':9},{'l10':10},{'l11':11},{'l12':12}
];

const themeTypes = ['auto','light','dark'];

class SettingModel extends ChangeNotifier {

  static const kSettingKey = 'kSettingKey'; // 设置信息的key

  String language = 'auto';  // 语言
  String theme = 'auto';     // 主题
  String fontLevel = 'auto'; // 字体缩放等级
  String lastTime = DateTime.now().millisecondsSinceEpoch.toString();  // 上次启动时间
  String userName = 'Forester';  // 用户昵称
  String userEmail = 'forester@planting.com'; // 用户邮箱

  // 一些配置项，实时读取
  bool needMap = true; // // 国区+中文, 如果为false,则不展示地图，也不跳转地图选点页面

  C c = C.light(); // 配色
  L l = L(); // 语言
  Locale? currentDeviceLocale; // 当前系统语言

  static String tableName = 'Setting';
  static Map<String, String> columns = {
    'language':'TEXT',
    'theme': 'TEXT',
    'fontLevel': 'TEXT',
    'lastTime': 'TEXT',
    'userName': 'TEXT',
    'userEmail': 'TEXT',
  };
  Map<String, Object> toMap(){
    return {
      'language': language,
      'theme': theme,
      'fontLevel': fontLevel,
      'lastTime': lastTime,
      'userName': userName,
      'userEmail': userEmail,
    };
  }
  // 从sql查出后，转换成实例
  static SettingModel fromMap(Map<String, Object?> map){
    var model = SettingModel();
    if (map['language'] != null){ model.language = map['language'] as String; }
    if (map['theme'] != null){ model.theme = map['theme'] as String; }
    if (map['fontLevel'] != null){ model.fontLevel = map['fontLevel'] as String; }
    if (map['lastTime'] != null){ model.lastTime = map['lastTime'] as String; }
    if (map['userName'] != null){ model.userName = map['userName'] as String; }
    if (map['userEmail'] != null){ model.userEmail = map['userEmail'] as String; }
    // 加载主题
    if(model.theme == 'light'){
      model.c = C.light();
    }else if(model.theme == 'dark'){
      model.c = C.dark();
    }else{
      model.c = SchedulerBinding.instance.window.platformBrightness == Brightness.dark ? C.dark() : C.light();
    }
    // 加载语言
    model.loadLanguage(null);
    return model;
  }

  void updateLanguageFromJson(String json, String path){
    if(json.isEmpty){ return; }
    var lan = L.fromJson(json, path);
    if(lan != null){
      l = lan;
      notifyListeners();
      debugPrint('语言包设置完成！');
    }
  }
  /// 加载配置：是否展示位置、是否Pro
  void loadConfig(Locale? deviceLocale) async{
    if(deviceLocale == null){ return; }
    var timezone = await FlutterNativeTimezone.getLocalTimezone();
    List<String> limitZones = ['asia/shanghai','asia/harbin','asia/chongqing','asia/urumqi','asia/kashgar'];
    if(limitZones.contains(timezone.toLowerCase()) && (deviceLocale.toString().toLowerCase() == 'zh_hans_cn' || deviceLocale.toString().toLowerCase() == 'zh_cn')){
      if (kDebugMode) { print('needMap = false'); }
      needMap = false;
    }
  }

  // 会调用两次，启动一次，获取到系统语言后再调用一次,第一次设置为默认语言en,第二次更新系统语言，判断是否需要更换语言
  void loadLanguage(Locale? deviceLocale){
    debugPrint('loadLanguage:$deviceLocale');
    String defaultLanguage = 'static/language/en.json';
    loadConfig(deviceLocale);
    if(language == 'auto'){ // 获取系统语言，然后读取对应的语言包，如果语言包不存在，则使用默认en语言包
      if(deviceLocale == null){
        rootBundle.loadString(defaultLanguage).then((value){
          updateLanguageFromJson(value,'auto');
        }).onError((error, stackTrace){
          debugPrint('读取语言包失败：$error');
        });
      }else{
        /// 加载系统语言对应的语言包
        String firstPackage = deviceLocale.languageCode;  // zh_Hans_CN
        String secondPackage = deviceLocale.languageCode; // zh_Hans
        String thirdPackage = deviceLocale.languageCode;  // zh
        if(deviceLocale.scriptCode != null){
          firstPackage = firstPackage + "_${deviceLocale.scriptCode}";
          secondPackage = secondPackage + "_${deviceLocale.scriptCode}";
        }
        if(deviceLocale.countryCode != null){
          firstPackage = firstPackage + "_${deviceLocale.countryCode}";
        }
        /// 依次读取对应的包，直到读取到最匹配的语言包
        rootBundle.loadString('static/language/$firstPackage.json').then((value){
          updateLanguageFromJson(value,'auto');
        }).onError((error, stackTrace){
          // debugPrint(error.toString());
          rootBundle.loadString('static/language/$secondPackage.json').then((value){
            updateLanguageFromJson(value,'auto');
          }).onError((error, stackTrace){
            // debugPrint(error.toString());
            rootBundle.loadString('static/language/$thirdPackage.json').then((value){
              updateLanguageFromJson(value,'auto');
            }).onError((error, stackTrace){
              debugPrint('读取语言包失败：$error');
            });
          });
        });
      }
    }else{ // language 是语言包路径
      // 判断语言包是否存在，如果不存在，或者解析失败，则使用默认，也就是auto
      if(language.startsWith('static')){ // 从资源文件里读取
        rootBundle.loadString(language).then((value){
          updateLanguageFromJson(value,language);
        }).onError((error, stackTrace){
          debugPrint('$error \n读取语言包失败，使用默认语言包!');
          rootBundle.loadString(defaultLanguage).then((value){
            updateLanguageFromJson(value,'auto');
          }).onError((error, stackTrace){
            debugPrint('默认语言包读取失败，完蛋：$error');
          });
        });
      }else{
        /// TODO:从沙盒文件夹中读取(下个版本)

      }
    }
  }

  // 设备语言变化，调用该方法
  // https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_territory_information.html#zh_Hans
  void updateLanguage(Locale? deviceLocale){ // zh_Hans_CN: 语言_类型_国家
    // print(deviceLocale?.languageCode); // zh
    // print(deviceLocale?.countryCode);  // CN
    // print(deviceLocale?.scriptCode);   // Hans:简体  Hant:繁体
    // print(deviceLocale?.toString());
    // 查找语言方式:1、先匹配完整的比如zh_Hans_CN 2、再匹配zh_Hans 3、在匹配zh 4、都没有，则使用默认en
    currentDeviceLocale = deviceLocale;
    loadLanguage(deviceLocale);
  }

  num get currentFontLevel {
    for( var l in fontLevels){
      if (l.keys.contains(fontLevel)){
        return l.values.first;
      }
    }
    return 1;
  }

  updateLastTime() async{
    lastTime = DateTime.now().millisecondsSinceEpoch.toString();
    await save(false);
  }

  // 系统设置发生改变，主题、字体、语言设置更新
  didChangePlatformBrightness(){
    if(theme == 'auto'){
      c = SchedulerBinding.instance.window.platformBrightness == Brightness.dark ? C.dark() : C.light();
      notifyListeners();
    }
  }

  switchLanguage(L newLanguage) async{
    String exPath = newLanguage.exPath ?? 'auto';
    if(exPath == 'auto'){
      /// 重新根据系统语言加载新语言
      language = 'auto';
      loadLanguage(currentDeviceLocale);
    }else{
      l = newLanguage;
      language = exPath;
    }
    await save(true);
  }

  switchTheme(String? newTheme) async{
    if(newTheme != null){
      if(themeTypes.contains(newTheme)){ theme = newTheme; }else{ theme = 'auto'; }
    }else{
      if(theme == 'light'){
        theme = 'dark';
      }else{
        theme = 'light';
      }
    }
    // theme = 'auto';
    if(theme == 'light'){ c = C.light(); }else if(theme == 'dark'){ c = C.dark(); }else{ c = SchedulerBinding.instance.window.platformBrightness == Brightness.dark ? C.dark() : C.light(); }
    await save(true);
  }

  switchFontLevel(String level) async{
    var tmpLevel = 'auto';
    for( var l in fontLevels){
      if (l.keys.contains(level)){
        tmpLevel = level;
        break;
      }
    }
    fontLevel = tmpLevel;
    await save(true);
  }

  switchUserName(String name) async{
    if(name.isEmpty){
      userName = 'Forester';
    }else{
      userName = name;
    }
    await save(true);
  }

  switchUserEmail(String email) async{
    if(email.isEmpty){
      userEmail = 'forester@planting.com';
    }else{
      userEmail = email;
    }
    await save(true);
  }

  save(bool needNotify) async{
    if (needNotify){ notifyListeners(); }
    await SettingSQL.save(this);
  }

}

class SettingSQL{
  static Future<SettingModel> loadSetting() async{
    List? maps = await provider_db?.rawQuery('SELECT * FROM ${SettingModel.tableName}');
    if(maps != null && maps.isNotEmpty){
      return SettingModel.fromMap(maps.first);
    }else{
      SettingModel model = SettingModel();
      await SettingSQL.save(model);
      return model;
    }
  }

  static save(SettingModel model) async{
    List maps = await provider_db?.rawQuery('SELECT * FROM ${SettingModel.tableName}') ?? [];
    if(maps.isEmpty){
      await provider_db?.insert(SettingModel.tableName, model.toMap());
    }else{
      await provider_db?.update(SettingModel.tableName, model.toMap());
    }
    Global.setUserInfo(userName: model.userName, email: model.userEmail,configPath: Global.gitCommitConfigDirectoryPath);
  }
}

/// 读取assets某个文件夹下的所有文件
// final manifestJson = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
// final images = json.decode(manifestJson).keys.where((String key) => key.startsWith('assets/images'));
