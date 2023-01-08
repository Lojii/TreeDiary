// 仓库信息
import 'dart:convert';
import 'dart:ffi';
// import 'dart:html';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:treediary/config/storage_manager.dart';
import 'package:treediary/git/git_action.dart';
import 'package:treediary/isolate/git_isolate.dart';
import 'package:treediary/repo/note_info.dart';
import 'package:treediary/model/ssh_key.dart';
import 'package:treediary/provider/provider_sql.dart';
import 'dart:convert' as convert;

import 'package:treediary/repo/repo_manager.dart';
import 'package:treediary/repo/sql_manager.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../config/global_data.dart';
import '../repo/repo_action.dart';
import '../utils/string_utils.dart';

// const accountTypes = ['github','gitlab','gitee','git'];

class SyncTypes {
  static const String disable = 'disable';  // 不可用
  static const String waitingSync = 'waitingSync'; // 未同步
  static const String syncing = 'syncing';  // 同步中
  static const String syncSuccess = 'syncSuccess';
  static const String syncFailure = 'syncFailure';
}
// TODO:同步状态，单独搞个Provider Map(repoPath+gitUrl:state)
// late String state; // 当前同步状态: 不可用、未同步、同步中、同步成功、同步失败

class RepoSync {

  String repoPath = ''; //
  String type = ''; // github\gitlab\gitee ...
  String lastSyncTime = ''; // 上次同步时间
  String lastCheckTime = ''; // 最新的检查时间，检查有多少变更
  String remotePath = ''; // 同步地址
  String remoteName = ''; // git 对应名称
  String sshKeyId = ''; // key Id
  String pubKey = ''; // 公钥缓存
  String pubKeyHash = ''; // 公钥Hash码
  bool isAutoSync = true; // 是否自动同步
  int unPushCount = -1; // 未推送数 -1：未检测
  int unPullCount = -1; // 未拉取数

  static String tableName = 'Sync';
  static Map<String, String> columns = {
    'repoPath': 'TEXT',
    'type': 'TEXT',
    'lastSyncTime': 'TEXT',
    'lastCheckTime': 'TEXT',
    'remotePath': 'TEXT',
    'remoteName': 'TEXT',
    'sshKeyId': 'TEXT',
    'pubKey': 'TEXT',
    'pubKeyHash': 'TEXT',
    'isAutoSync': 'INTEGER',
    'unPushCount': 'INTEGER',
    'unPullCount': 'INTEGER'
  };
  Map<String, Object> toMap(){
    return {
      'repoPath': repoPath,
      'type': type,
      'lastSyncTime': lastSyncTime,
      'lastCheckTime': lastCheckTime,
      'remotePath': remotePath,
      'remoteName': remoteName,
      'sshKeyId': sshKeyId,
      'pubKey': pubKey,
      'pubKeyHash': pubKeyHash,
      'isAutoSync': isAutoSync ? 1 : 0,
      'unPushCount': unPushCount,
      'unPullCount': unPullCount
    };
  }
  // 从sql查出后，转换成实例
  static RepoSync fromMap(Map<String, Object?> map){
    var model = RepoSync();
    if (map['repoPath'] != null){ model.repoPath = map['repoPath'] as String; }
    if (map['type'] != null){ model.type = map['type'] as String; }
    if (map['lastSyncTime'] != null){ model.lastSyncTime = map['lastSyncTime'] as String; }
    if (map['lastCheckTime'] != null){ model.lastCheckTime = map['lastCheckTime'] as String; }
    if (map['remotePath'] != null){ model.remotePath = map['remotePath'] as String; }
    if (map['remoteName'] != null){ model.remoteName = map['remoteName'] as String; }
    if (map['sshKeyId'] != null){ model.sshKeyId = map['sshKeyId'] as String; }
    if (map['pubKey'] != null){ model.pubKey = map['pubKey'] as String; }
    if (map['pubKeyHash'] != null){ model.pubKeyHash = map['pubKeyHash'] as String; }
    if (map['isAutoSync'] != null){ model.isAutoSync = map['isAutoSync'] == 1; }
    if (map['unPushCount'] != null){ model.unPushCount = map['unPushCount'] as int; }
    if (map['unPullCount'] != null){ model.unPullCount = map['unPullCount'] as int; }
    return model;
  }

  static Future<List<RepoSync>> loadRepoSyncList(Database? db, String repoPath) async {
    List maps = await db?.rawQuery('SELECT * FROM ${RepoSync.tableName} WHERE repoPath = "$repoPath"') ?? [];
    List<RepoSync> list = [];
    for(var item in maps){
      list.add(RepoSync.fromMap(item));
    }
    return list;
  }

  static save({required RepoSync model, bool needNotify = true}) async{
    if(model.repoPath.isEmpty || model.remotePath.isEmpty){ return; }
    List maps = await provider_db?.rawQuery('SELECT * FROM ${RepoSync.tableName} WHERE repoPath = "${model.repoPath}" AND remotePath = "${model.remotePath}"') ?? [];
    if(maps.isEmpty){
      await provider_db?.insert(RepoSync.tableName, model.toMap());
    }else{
      int? count = await provider_db?.update(RepoSync.tableName, model.toMap(), where: 'repoPath = ? AND remotePath = ?', whereArgs: [model.repoPath,model.remotePath]);
      print(count);
    }
    if(needNotify){
      ProviderSQLManager.notify();
    }
  }

  static delete(String repoKey, String remotePath) async{
    if(repoKey.isEmpty || remotePath.isEmpty){ return; }
    await ProviderSQLManager.delete(RepoSync.tableName, where: 'repoPath = ? AND remotePath = ?',whereArgs: [repoKey, remotePath]);
    // TODO:执行仓库内配置项删除
    Directory? repoBaseDir = await RepoManager.repoBasePath();
    String fullRepoPath = (repoBaseDir?.path ?? '') + '/' + repoKey;
    await GitAction.removeRemote(fullRepoPath, remotePath);
    ProviderSQLManager.notify();
  }

  static switchAutoSync(String repoKey, String remotePath, bool autoSync) async{
    await ProviderSQLManager.update(RepoSync.tableName, {'isAutoSync' : (autoSync ? 1 : 0)}, where: 'repoPath = ? AND remotePath = ?',whereArgs: [repoKey, remotePath]);
    ProviderSQLManager.notify();
  }

  static updateLastSyncTime(String repoKey, String remotePath) async{
    if(remotePath.isEmpty){ return; }
    var now = DateTime.now().millisecondsSinceEpoch.toString();
    await ProviderSQLManager.update(RepoSync.tableName, {'lastSyncTime' : now}, where: 'repoPath = ? AND remotePath = ?',whereArgs: [repoKey, remotePath]);
    ProviderSQLManager.notify();
  }
}

class RepoModel {

  String localPath = ''; //
  String userName = ''; // 如果为空，则使用setting_model中的用户邮箱信息
  String userEmail = ''; //
  String updateTime = ''; // 更新时间
  String visitTime = ''; // 最后访问时间
  bool isExpanded = false; // 菜单栏是否展开
  bool isSelected = false; // 是否选中
  bool isFullPath = false; // localPath是否为完整路径
  // 以下参数不存入数据库
  String name = ''; // 从config文件中读取，如果是非日记仓库，则name=仓库文件夹名称
  /// 下面三个参数是日记仓库特有的，如果缺少，则判断为非日记仓库
  String createTime = '';  //
  String version = '';  //
  String type = '';  //

  String fullPath = ''; // 完整路径，从数据库里读取或者创建之后，赋值，不存入数据库
  List<RepoSync> syncList = [];  // 同步列表

  String get key => localPath;
  bool get isDiary => version.isNotEmpty || createTime.isNotEmpty;
  String get showUserName{
    if(userName.isNotEmpty) {
      return userName;
    }
    return '';
  }

  static String tableName = 'Repo';
  static Map<String, String> columns = {
    'localPath':'TEXT',
    'userName': 'TEXT',
    'userEmail': 'TEXT',
    'updateTime': 'TEXT',
    'visitTime': 'TEXT',
    'isExpanded': 'INTEGER',
    'isSelected': 'INTEGER',
    'isFullPath': 'INTEGER',
  };
  Map<String, Object> toMap(){
    return {
      'localPath':localPath,
      'userName': userName,
      'userEmail': userEmail,
      'updateTime': updateTime,
      'visitTime': visitTime,
      'isExpanded': isExpanded ? 1 : 0,
      'isSelected': isSelected ? 1 : 0,
      'isFullPath': isFullPath ? 1 : 0,
    };
  }
  // 从sql查出后，转换成实例
  static RepoModel fromMap(Map<String, Object?> map){
    var model = RepoModel();
    if (map['localPath'] != null){ model.localPath = map['localPath'] as String; }
    if (map['userName'] != null){ model.userName = map['userName'] as String; }
    if (map['userEmail'] != null){ model.userEmail = map['userEmail'] as String; }
    if (map['updateTime'] != null){ model.updateTime = map['updateTime'] as String; }
    if (map['visitTime'] != null){ model.visitTime = map['visitTime'] as String; }
    if (map['isExpanded'] != null){ model.isExpanded = map['isExpanded'] == 1; }
    if (map['isSelected'] != null){ model.isSelected = map['isSelected'] == 1; }
    if (map['isFullPath'] != null){ model.isFullPath = map['isFullPath'] == 1; }
    return model;
  }

  // 对外方法
  static Future<List<RepoModel>> loadRepoList(Database? db) async {
    Directory? repoBaseDir = await RepoManager.repoBasePath();
    List maps = await db?.rawQuery('SELECT * FROM ${RepoModel.tableName}') ?? [];
    List<RepoModel> list = [];
    for(var item in maps){
      RepoModel r = RepoModel.fromMap(item);
      r.fullPath = (repoBaseDir?.path ?? '') + '/' + r.localPath;
      // 从本地文件中读取名称、创建时间
      var configPath = r.fullPath + '/.planting/config.json';
      var configFile = File(configPath);
      if(!await configFile.exists()){
        r.name = r.localPath;
      }else{
        var configJson = await configFile.readAsString();
        var config = convert.jsonDecode(configJson);
        if(config is Map<String, dynamic>){
          r.name = config['name'] ?? '';
          r.createTime = config['time'] ?? '';
          r.version = config['version'] ?? '';
          r.type = config['type'] ?? '';
        }
      }
      // 从同步表中读取对应同步列表
      r.syncList = await RepoSync.loadRepoSyncList(db, r.localPath);
      list.add(r);
    }
    return list;
  }

  static insertOrUpdate({required RepoModel model, bool needNotify = true}) async{
    if(model.localPath.isEmpty){ return; }
    List maps = await provider_db?.rawQuery('SELECT * FROM ${RepoModel.tableName} WHERE localPath = "${model.localPath}"') ?? [];
    if(maps.isEmpty){
      await provider_db?.insert(RepoModel.tableName, model.toMap());
    }else{
      await provider_db?.update(RepoModel.tableName, model.toMap(), where: 'localPath = ?', whereArgs: [model.localPath]);
    }
    if(needNotify) {
      ProviderSQLManager.notify();
    }
  }
  // API
  static Future<RepoModel?> load(String repoKey) async{
    String sql = 'SELECT * FROM ${RepoModel.tableName} WHERE localPath = "$repoKey"';
    List<Map<String, Object?>> maps = await ProviderSQLManager.rawQuery(sql);
    if(maps.isNotEmpty){
      Directory? repoBaseDir = await RepoManager.repoBasePath();
      RepoModel r = RepoModel.fromMap(maps.first);
      r.fullPath = (repoBaseDir?.path ?? '') + '/' + r.localPath;
      var configPath = r.fullPath + '/.planting/config.json';
      var configFile = File(configPath);
      if(!await configFile.exists()){
        r.name = r.localPath;
      }else {
        var configJson = await configFile.readAsString();
        var config = convert.jsonDecode(configJson);
        if (config is Map<String, dynamic>) {
          r.name = config['name'] ?? '';
          r.createTime = config['time'] ?? '';
          r.version = config['version'] ?? '';
          r.type = config['type'] ?? '';
        }
      }
      return r;
    }else{
      return null;
    }
  }
  /// 更新配置
  static updateConfig(String repoKey, {String? name, String? version, String? time, String? type}) async{
    RepoModel? r = await RepoModel.load(repoKey);
    if(r == null){ return; }
    if(name != null){ r.name = name; }
    if(version != null){ r.version = version; }
    if(time != null){ r.createTime = time; }
    if(type != null){ r.type = type; }
    var configFile = File(r.fullPath + '/.planting/config.json');
    Map<String,String> newConfig = {"version": r.version, "name": r.name, "type": r.type, "time": r.createTime};
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    String prettyprint = encoder.convert(newConfig);
    await configFile.writeAsString(prettyprint);
    ProviderSQLManager.notify();
  }
  /// 更新用户信息
  static updateUserInfo(String repoKey, {String? userName, String? userEmail}) async{
    Map<String, Object?> values = {};
    if(userName != null){ values['userName'] = userName; }
    if(userEmail != null){ values['userEmail'] = userEmail; }
    if(values.isEmpty){ return; }
    if(await ProviderSQLManager.update(RepoModel.tableName, values, where: 'localPath = ?', whereArgs: [repoKey]) < 0){
      print('❌ updateUserInfo error ! ');
    }
    ProviderSQLManager.notify();
  }
  /// 选中
  static select(String repoKey) async{
    if(await ProviderSQLManager.update(RepoModel.tableName, {'isSelected': false}) < 0){
      print('❌ select error ! (All)');
    }
    if(await ProviderSQLManager.update(RepoModel.tableName, {'isSelected': true}, where: 'localPath = ?', whereArgs: [repoKey]) < 0){
      print('❌ select error ! ($repoKey)');
    }
    ProviderSQLManager.notify();
  }
  /// 展开
  static expand(String repoKey) async{
    RepoModel? r = await RepoModel.load(repoKey);
    if(r == null){ return; }
    if(await ProviderSQLManager.update(RepoModel.tableName, {'isExpanded': !r.isExpanded}, where: 'localPath = ?', whereArgs: [repoKey]) < 0){
      print('❌ expand error ! ($repoKey)');
    }
    if(await ProviderSQLManager.update(RepoModel.tableName, {'isExpanded': false}, where: 'localPath != ?', whereArgs: [repoKey]) < 0){
      print('❌ expand error ! (All)');
    }
    ProviderSQLManager.notify();
  }
  /// 添加仓库
  static add(RepoModel repo) async{
    RepoModel? r = await RepoModel.load(repo.localPath);
    if(r != null){
      print('❌ add error ! ${repo.localPath} already exist !');
      return;
    }
    repo.save(updateConfig: true);
    ProviderSQLManager.notify();
  }
  /// 删除仓库
  static delete(String repoKey) async{
    // TODO:需要检查是否有未同步，或者正在同步的操作
    RepoModel? r = await RepoModel.load(repoKey);
    if(r == null){
      print('❌ delete error ! $repoKey not exist !');
      return;
    }
    // 1 文件删除
    var dir = Directory(r.fullPath);
    if(await dir.exists()){
      await dir.delete(recursive: true);
    }
    // 2 缓存数据库清理
    String deleteSQL = "DELETE FROM Note WHERE repoPath = '${r.localPath}'";
    await SQLManager.rawDelete(deleteSQL);
    // 3 设置清理
    await ProviderSQLManager.delete(RepoModel.tableName, where: 'localPath = ?', whereArgs: [r.localPath]);
    await ProviderSQLManager.delete(RepoSync.tableName, where: 'repoPath = ?', whereArgs: [r.localPath]);
    // 4 TODO:移除sshKey
    //
    // 5 通知刷新
    ProviderSQLManager.notify();
  }
  /// 保存、更新
  save({bool updateConfig = false, bool needNotify = true}) async{
    if(updateConfig){
      var configFile = File(fullPath + '/.planting/config.json');
      Map<String,String> newConfig = {"version": version, "name": name, "type": type, "time": createTime};
      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyprint = encoder.convert(newConfig);
      await configFile.writeAsString(prettyprint);
    }
    await RepoModel.insertOrUpdate(model:this, needNotify:needNotify);

    Global.setUserInfo(userName: userName, email: userEmail,repoKey: localPath ,configPath: Global.gitCommitConfigDirectoryPath);
  }
  /// 添加远程仓库链接
  Future<RepoSync?> addRemote({required String gitUrl, SSHKey? sshKey}) async{
    if(gitUrl.isEmpty){ return null; }
    try{
      /// 1、添加到git仓库
      var repository = Repository.open(fullPath);
      String remoteNewName = StringUtils.randomString(8);
      bool remoteExist = false;
      for (final remoteName in repository.remotes) {
        final remote = Remote.lookup(repo: repository, name: remoteName);
        stdout.writeln('${remote.name}  ${remote.url}');
        if(remote.url == gitUrl){
          stdout.write('$gitUrl already exist !');
          remoteExist = true;
          remoteNewName = remote.name;
          break;
        }
      }
      if(!remoteExist){
        Remote.create(repo: repository, name: remoteNewName, url: gitUrl);
      }
      /// 2、添加到数据库里
      RepoSync s = RepoSync();
      s.repoPath = localPath; //
      s.type = gitUrl.contains('github.com') ? 'github' : ''; // github\gitlab\gitee ...
      s.remotePath = gitUrl; // 同步地址
      s.remoteName = remoteNewName; // git 对应名称
      s.sshKeyId = sshKey?.id ?? ''; // key Id
      s.pubKey = sshKey?.publicKey ?? ''; // 公钥缓存
      s.pubKeyHash = sshKey?.publicKeyHash ?? ''; // 公钥Hash码
      await RepoSync.save(model:s);
      /// 3、添加到异步同步队列
      GitIsolate.share.addRepoSync(s);
      print('添加完毕');
      return s;
    }catch(e){
      print(e);
      return null;
    }

  }
  /// 刷新note表里的所有的日记数据
  Future<int?> refreshAllNote() async{
    if(fullPath.isEmpty){ return null; }
    /// 遍历文件夹fullPath里所有的md文件
    Directory rootDir = Directory(fullPath);
    if(!await rootDir.exists()){ return null; }
    List<String> mdFiles = [];
    Stream<FileSystemEntity> fileList = rootDir.list(recursive:true);
    await for(FileSystemEntity fileSystemEntity in fileList){
      if (kDebugMode) { print(fileSystemEntity.path.replaceAll(fullPath, '')); }
      if(fileSystemEntity.path.contains('$fullPath/.git')){ continue; }
      if(fileSystemEntity.path.endsWith('.md') || fileSystemEntity.path.endsWith('.MD')){
        FileSystemEntityType type = FileSystemEntity.typeSync(fileSystemEntity.path);
        if(type == FileSystemEntityType.file){
          mdFiles.add(fileSystemEntity.path);
        }
      }
    }
    /// 清空数据库里的老数据
    if(!await NoteInfo.clear(localPath)){
      if (kDebugMode) { print('清空$localPath记录失败！'); }
    }
    /// 生成新的数据，并写入数据库
    int count = 0;
    for(var md in mdFiles){
      var note = await NoteInfo.from(mdFile: md, repoLocalPath: localPath);
      await note?.saveToDB();
      if(note != null){ count ++; }
    }
    ///
    return count;
  }
}

class RepoListModel extends ChangeNotifier { // 接口都放这里，直接操作数据库，然后刷新数据

  List<RepoModel> repoList = [];
  // 当前选中仓库
  RepoModel? get currentSelectedRepo{
    for(RepoModel r in repoList) {
      if(r.isSelected){
        return r;
      }
    }
    if(repoList.isEmpty){
      // if (kDebugMode) { print('仓库为空！！！！'); }
      return null;
    }
    return repoList.first;
  }
  // 刷新列表数据
  refreshList({bool needNotify = true}) async{
    repoList = await RepoModel.loadRepoList(provider_db);
    if (needNotify){
      notifyListeners();
    }
  }

  static Future<RepoListModel> loadRepoModelList() async{
    RepoListModel model = RepoListModel();
    await model.refreshList(needNotify: false);
    return model;
  }
  // 模拟数据
  // static initTable() async{
  //   Map<String, Object> initMap = {};
  //   // Map<String, Object> initMap = {"repoList": [{"localPath": "pt_20220614181643","syncList": [],"createTime": "1655201803579","updateTime": "1655201803579","visitTime": "1657338285445","name": "失业八个月","isExpanded": false,"isSelected": false,"userName": "","userEmail": ""},{"localPath": "pt_20220614181651","syncList": [{"type": "","remotePath": "git@github.com:Lojii/07071712.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "7KN7L2RA","sshKeyId": "9W40RY8YJDJUJALO","pubKey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGM+zjA5a+gXixuZZXWW14TRCHxIN3SEpGVYskXmduo2","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/07051453.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "10TCS8U2","sshKeyId": "","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/Git07051435.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "346E2T8K","sshKeyId": "","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/07052302.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "3PHEDHIU","sshKeyId": "","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/07052228.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "93V659RM","sshKeyId": "","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/Git0701.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "Git0701","sshKeyId": "","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/070550115.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "IFAF1RXZ","sshKeyId": "","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/Git07031314.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "L5FSWEWB","sshKeyId": "","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/07071651.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "LGQPUY6M","sshKeyId": "","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/Git07050052.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "P68B367E","sshKeyId": "","autoSync": true},{"type": "","remotePath": "git@github.com:Lojii/07050122.git","state": "","lastSyncTime": "","lastUpdateTime": "","lastCheckTime": "","remoteName": "QH50IBME","sshKeyId": "","autoSync": true}],"createTime": "1655201811242","updateTime": "1655201811242","visitTime": "1657379115563","name": "东哥","isExpanded": true,"isSelected": true,"userName": "","userEmail": ""},{"localPath": "pt_20220614181654","syncList": [],"createTime": "1655201814592","updateTime": "1655201814592","visitTime": "1656495369700","name": "One Piece","isExpanded": false,"isSelected": false,"userName": "maxc","userEmail": "lojii@163.com"},{"localPath": "pt_20220614181657","syncList": [],"createTime": "1655201817226","updateTime": "1655201817226","visitTime": "1656479495948","name": "宇航员","isExpanded": false,"isSelected": false,"userName": "build","userEmail": "bbb@126.com"},{"localPath": "pt_20220614181659", "syncList": [], "createTime": "1655201819042", "updateTime": "1655201819042", "visitTime": "1656476818683", "name": "Planting", "isExpanded": false, "isSelected": false, "userName": "", "userEmail": ""}, {"localPath": "pt_20220614181701", "syncList": [], "createTime": "1655201821193", "updateTime": "1655201821193", "visitTime": "1655201821193", "name": "Planting", "isExpanded": false, "isSelected": false, "userName": "", "userEmail": ""}, {"localPath": "pt_20220614181706", "syncList": [], "createTime": "1655201826027", "updateTime": "1655201826027", "visitTime": "1656570131604", "name": "愿你", "isExpanded": false, "isSelected": false, "userName": "open", "userEmail": "opens@qq.com"}]};
  //   // Map<String, Object> initMap = {"repoList":[{"localPath":"pt_20220603143204","syncList":[],"createTime":"1654237924389","updateTime":"1654237924389","visitTime":"1657016631453","name":"有妖怪","isExpanded":false,"isSelected":false,"userName":"","userEmail":""},{"localPath":"pt_20220603143207","syncList":[],"createTime":"1654237927303","updateTime":"1654237927303","visitTime":"1656551949897","name":"再见不打扰","isExpanded":false,"isSelected":false,"userName":"","userEmail":""},{"localPath":"pt_20220603143208","syncList":[{"type":"","remotePath":"git@github.com:Lojii/07091813.git","state":"","lastSyncTime":"","lastUpdateTime":"","lastCheckTime":"","remoteName":"51MRMSZH","sshKeyId":"8YLHOQWI3OQPBWNB","autoSync":true}],"createTime":"1654237928487","updateTime":"1654237928487","visitTime":"1657016636137","name":"人生何处不相逢","isExpanded":true,"isSelected":true,"userName":"","userEmail":""},{"localPath":"pt_20220603143209","syncList":[],"createTime":"1654237929254","updateTime":"1654237929254","visitTime":"1656551903312","name":"走卒","isExpanded":false,"isSelected":false,"userName":"","userEmail":""},{"localPath":"pt_20220603143211","syncList":[],"createTime":"1654237931556","updateTime":"1654237931556","visitTime":"1656551939925","name":"我乃人间一凡夫","isExpanded":false,"isSelected":false,"userName":"","userEmail":""},{"localPath":"pt_20220603143212","syncList":[],"createTime":"1654237932756","updateTime":"1654237932756","visitTime":"1654237932756","name":"Planting","isExpanded":false,"isSelected":false,"userName":"","userEmail":""},{"localPath":"pt_20220603143213","syncList":[],"createTime":"1654237933590","updateTime":"1654237933590","visitTime":"1656117529876","name":"Planting","isExpanded":false,"isSelected":false,"userName":"","userEmail":""},{"localPath":"pt_20220603143214","syncList":[],"createTime":"1654237934425","updateTime":"1654237934425","visitTime":"1654237934425","name":"Planting","isExpanded":false,"isSelected":false,"userName":"","userEmail":""},{"localPath":"pt_20220603143215","syncList":[],"createTime":"1654237935258","updateTime":"1654237935258","visitTime":"1656230123457","name":"Planting","isExpanded":false,"isSelected":false,"userName":"","userEmail":""}],"cachePath":"","sshKeyMap":{}};
  //   List<Map<String, Object>> repoList = initMap['repoList'] as List<Map<String, Object>>;
  //   for(var repo in repoList){
  //     Repo r = Repo.fromMap(repo);
  //     List syncList = repo['syncList'] as List;
  //     for(var repoSync in syncList){
  //       RepoSync s = RepoSync.fromMap(repoSync);
  //       s.repoPath = r.localPath;
  //       print(s.pubKey);
  //       await RepoSync.save(s);
  //       r.syncList.add(s);
  //     }
  //     await Repo.insertOrUpdate(r);
  //   }
  // }
}
