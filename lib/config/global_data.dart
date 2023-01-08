import 'dart:io';
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../repo/repo_manager.dart';

class Global {

  static String busRepoDidChange = 'busRepoDidChange'; /// 当前选择仓库发生改变
  static String busHomeSearchDidClick = 'busHomeSearchDidClick'; /// 首页导航栏搜索按钮点击
  static String busHomeTimeDidClick = 'busHomeTimeDidClick'; /// 首页导航栏时间按钮点击

  static String globalPrefix = 'globalPrefix_';
  static String repoPrefix = 'repoPrefix_';

  static late String repoBaseDir; //
  static late String noteDatabasePath; // 日记数据库地址
  static late String settingDatabasePath; // 设置数据库地址
  static late String documentsDirectoryPath; // 文档文件夹地址
  static late String gitCommitConfigDirectoryPath; // 仓库提交用户信息文件存储文件夹

  /// 全局必备数据的初始化
  static init() async {
    // sharedPreferences = await SharedPreferences.getInstance();
    Directory? baseBase = await RepoManager.repoBasePath();
    if(baseBase == null){
      if (kDebugMode) { print('未获取到仓库base路径'); }
      return;
    }
    repoBaseDir = baseBase.path;
    if (kDebugMode) { print(repoBaseDir); }
    var databasesPath = await getDatabasesPath();
    noteDatabasePath = path.join(databasesPath, 'forest');

    Directory supportDirectory = await getApplicationSupportDirectory();
    settingDatabasePath = path.join(supportDirectory.path, 'config');
    gitCommitConfigDirectoryPath = path.join(supportDirectory.path, 'commitConfig');
    var d = Directory(gitCommitConfigDirectoryPath);
    if(!await d.exists()){
      d.create();
    }

    Directory appDir = await getApplicationDocumentsDirectory();
    documentsDirectoryPath = appDir.path;

    // print(documentsDirectoryPath);
    // print(repoBaseDir);
  }

  static Map<String, String>? _loadCommitInfoFrom(String filePath){
    try{
      File file = File(filePath);
      if(file.existsSync()){
        String mapStr = file.readAsStringSync();
        var config = convert.jsonDecode(mapStr);
        if(config is Map<String, dynamic>){
          var name = config['userName'];
          var email = config['email'];
          return { 'userName':name, 'email':email };
        }
      }
      return null;
    }catch(e){
      if (kDebugMode) { print(e); }
      return null;
    }
  }

  static Map<String, String> getUserInfo({String? repoKey, required String configPath}){
    if(repoKey != null && repoKey.isNotEmpty){ // 读取仓库用户信息
      var map = _loadCommitInfoFrom(configPath + '/' + repoPrefix + repoKey.replaceAll('/', '_'));
      if(map != null){ return map; }
    }
    var globalMap = _loadCommitInfoFrom(configPath + '/' + globalPrefix);
    if(globalMap != null){ return globalMap; }
    return { 'userName':'Forester', 'email':'forester@planting.cn' };
  }

  static bool setUserInfo({String? repoKey,required String userName, required String email, required String configPath}){
    if(userName.isEmpty || email.isEmpty){ return false; }
    try{
      Map<String,String> newConfig = { 'userName':userName, 'email':email };
      convert.JsonEncoder encoder = const convert.JsonEncoder.withIndent('  ');
      String prettyprint = encoder.convert(newConfig);
      if(repoKey != null && repoKey.isNotEmpty){ // 写入仓库用户信息
        File file = File(configPath + '/' + repoPrefix + repoKey.replaceAll('/', '_'));
        if(!file.existsSync()){ file.createSync(); }
        file.writeAsStringSync(prettyprint);
      }else{
        File file = File(configPath + '/' + globalPrefix);
        if(!file.existsSync()){ file.createSync(); }
        file.writeAsStringSync(prettyprint);
      }
      return true;
    }catch(e){
      if (kDebugMode) { print(e); }
      return false;
    }
  }
}
