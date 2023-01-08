import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:treediary/isolate/git_isolate.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert' as convert;
// import 'package:treediary/common/utils/common_utils.dart';

import 'package:treediary/provider/repo_list_model.dart';
import '../config/global_data.dart';
import '../model/ssh_key.dart';
import '../pages/main_page.dart';
import '../utils/event_bus.dart';
import 'repo_action.dart';
import 'repo_util.dart';

class RepoManager {
  static String noteFolder = 'PlantingNote';
  /// 获取仓库根目录
  static Future<Directory?> repoBasePath() async {
    Directory? appDir;
    if (Platform.isIOS) {
      appDir = await getApplicationDocumentsDirectory();
    } else {
      appDir = await getExternalStorageDirectory();
    }

    var status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      if (statuses[Permission.storage] != PermissionStatus.granted) {
        return null;
      }
    }
    String appDocPath = appDir!.path + "/" + noteFolder;
    Directory appPath = Directory(appDocPath);
    await appPath.create(recursive: true);
    return appPath;
  }

  /// clone或者新建git仓库后，调用该方法 repoPath:仓库完整路径、gitUrl:初始clone地址、sshKey:初始key
  /// 1、添加到repo表
  /// 2、添加到sync表、转正key
  /// 3、更新note表
  /// 4、添加到isolate
  /// 5、通知全刷新
  static Future<bool> createRepo({required String repoFullPath, String? gitUrl, SSHKey? sshKey}) async{
    String repoKey = repoFullPath.split('/').last;
    // 添加到repo表
    RepoModel newRepo = RepoModel();
    newRepo.localPath = repoKey;
    newRepo.fullPath = repoFullPath;
    await newRepo.save(needNotify: false);
    // 添加到sync表、转正key
    if(gitUrl != null){
      RepoSync? newSync = await newRepo.addRemote(gitUrl: gitUrl, sshKey: sshKey);
      if(newSync == null){
        await RepoModel.delete(repoKey); // 清理上边创建保存的repo
        return false;
      }
      newRepo.syncList.add(newSync);
      await sshKey?.upgrade();
    }
    /// loadConfig 如果没有,则不需要刷新所有note
    var configFile = File(repoFullPath + '/.planting/config.json');
    if(await configFile.exists()){ // 如果不存在config，则为非日记仓库
      // 更新note表
      var noteCount = await newRepo.refreshAllNote();
      if(noteCount == null){
        return false;
      }else{
        if (kDebugMode) { print('更新$noteCount条note数据'); }
      }
    }
    // 添加到isolate
    GitIsolate.share.updateRepo(newRepo);
    /// 切换当前选择仓库为clone仓库
    await RepoModel.select(repoKey);
    Future.delayed(const Duration(seconds: 1),(){ Bus.emit(MainPage.forceRefresh); }); /// 通知首页刷新
    return true;
  }




  /* 默认先创建一个仓库，如果当前仓库size大于500M、1G、5G的时候，创建新的仓库,命名方式为:主仓库名+part+序号 */
  /*
    .planting/config.json 里保存type、name、time?、type:根据创建时间组织、根据文件夹组织
    日期文件夹组织方式:2022/05/28/120444.3245+480/1653386348067.md  原始数据，用时间戳命名
                                              1653386348067.info 记录time\GPS\tags\link\author\来源...
                                              xxx.jpg、aac、mp4、...
                                              xxx.jpg.txt
    自定义文件夹组织方式:xxx/xx/xx/xx/x.md
                                  x.info
  */
  /*
    * 0、创建前置检查，比如文件夹权限等
    * 1、创建文件夹
    * 2、创建git repo
    * 3、初始化repo，比如配置信息等
    * 4、如果是主仓库，则创建引导md和第一条md
    * 5、提交变动
    * 6、更新provider里的repo_model
    * 7、返回 成功、失败(如果失败，则移除已创建的文件和文件夹)
    * */
  /// 创建一个本地仓库
  /// name 笔记本名称（默认为Planting）
  /// type 类型 (默认time) time、folder
  /// userName 提交用户名（默认Forester）
  /// userEmail 提交用户邮件（默认forester@planting.cn）
  /// isSelected 创建，设为选中
  static Future<RepoModel?> createLocalRepo({bool isSelected = true}/*{String? name, String? type, String? userName, String? userEmail}*/) async {
    var timeStr = DateTime.now().toString(); // 2022-05-07 19:04:28.936352
    timeStr = timeStr.replaceAll('-', "").replaceAll(':', '').replaceAll(' ', '').split('.').first;
    Directory? gitDir = await repoBasePath();
    if(gitDir == null){ return null; }
    var repoKey = 'pt_' + timeStr;
    String repoDir = gitDir.path + '/' + repoKey;
    try{
      final repo = RepoAction.initRepo(repoDir + '/.git');
      /// 不需要设置用户名和邮箱，在commit的时候，实时获取设置用户名和邮箱
      // RepoAction.setupNameAndEmail(repo: repo, userName: 'forester', userEmail: 'forester@planting.com');
      await initRepo(repoDir, repo);

      RepoModel newRepo = RepoModel.fromMap({
        'localPath':repoKey,
        'userName': '',
        'userEmail': '',
        'updateTime': DateTime.now().millisecondsSinceEpoch.toString(),
        'visitTime': DateTime.now().millisecondsSinceEpoch.toString(),
        'isExpanded': 0,
        'isSelected': isSelected ? 1 : 0,
        'isFullPath': 0,
      });
      /// 添加到数据库
      await newRepo.save(needNotify: false);
      await RepoModel.select(repoKey);
      Future.delayed(const Duration(seconds: 1),(){ Bus.emit(MainPage.forceRefresh); }); /// 通知首页刷新
      /// 添加到isolate
      GitIsolate.share.updateRepo(newRepo);
      return newRepo;
    }catch(e){
      debugPrint('------------- error !' + e.toString() );
      if(Directory(repoDir).existsSync()){
        await Directory(repoDir).delete(recursive: true);
        debugPrint('------------- 删除文件夹：' + repoDir);
      }
      return null;
    }
  }

  static initRepo(String repoDir, Repository repo) async{
    /// 创建配置文件夹 .planting
    Directory configPath = Directory(repoDir + '/.planting');
    if(await configPath.exists()){
      if (kDebugMode) { print('$repoDir already initialized'); }
      return;
    }
    await configPath.create(recursive: true);
    Directory infoPath = Directory(configPath.path + '/info');
    await infoPath.create(recursive: true);
    /// 创建配置文件
    const fileName = 'config.json';
    debugPrint(configPath.path);
    final filePath = path.join(configPath.path, fileName);
    // File(filePath).createSync();
    File configFile = File(filePath);
    configFile.createSync();
    // init config.json
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    String prettyprint = encoder.convert({ 'version':'1.0.0', 'name':'Planting', 'type':'diary', 'time':DateTime.now().millisecondsSinceEpoch.toString(), });
    await configFile.writeAsString(prettyprint);
    var changes = RepoAction.repoStatus(repo);// 检查变更
    if(changes != null){
      RepoAction.stagingChanges(repo, changes);// 暂存变更
      RepoAction.commitChanges(repo: repo, msg: 'init commit \n',isRoot: true, repoKey: repoDir.split('/').last, gitCommitConfigDirectoryPath: Global.gitCommitConfigDirectoryPath);// 提交变更
    }
  }

}