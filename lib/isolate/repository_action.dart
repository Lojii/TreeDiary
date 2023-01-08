

// 仓库的操作方法，单独方法，不需要依赖外部参数
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:treediary/config/storage_manager.dart';
import 'package:treediary/git/git_callbacks.dart';
import 'package:treediary/isolate/repo_task.dart';
import 'package:libgit2dart/libgit2dart.dart';

import '../config/global_data.dart';
import '../repo/note_info.dart';
import '../model/ssh_key.dart';
import '../provider/repo_list_model.dart';

enum RepositoryActionResultType {
  /// 数据库操作
  dataInsert, // 数据新增
  dataDelete, // 数据移除
  dataUpdate, // 数据更新
  dataRefresh,// 重建缓存
  /// 信息展示
  info,       // 弹窗提示信息
  /// 操作结果
  log,        // 普通日志
  error,      // 错误日志
  warn,       // 警告日志
  /// 进度信息
  progress,   // 进度信息
}

class RepositoryActionResult{
  RepoTaskType action; // 具体操作
  String repoKey;      // 具体仓库
  String? syncUrl;     // 具体同步地址

  RepositoryActionResultType type;
  Object data;         // 返回结果，如果是数据操作则返回NoteInfo、如果是log\error\warn\info则返回字符串
  RepositoryActionResult({required this.action, required this.repoKey, required this.type, required this.data, this.syncUrl});

  static RepositoryActionResult progress(String progress, {required RepoTaskType action, required String repoKey, String? syncUrl}){
    return RepositoryActionResult(type: RepositoryActionResultType.progress, data: progress, action: action, repoKey: repoKey, syncUrl: syncUrl);
  }

  static RepositoryActionResult error(String info, {required RepoTaskType action, required String repoKey, String? syncUrl}){
    return RepositoryActionResult(type: RepositoryActionResultType.error, data: info, action: action, repoKey: repoKey, syncUrl: syncUrl);
  }

  static RepositoryActionResult log(String info, {required RepoTaskType action, required String repoKey, String? syncUrl}){
    return RepositoryActionResult(type: RepositoryActionResultType.log, data: info, action: action, repoKey: repoKey, syncUrl: syncUrl);
  }

  static RepositoryActionResult warn(String info, {required RepoTaskType action, required String repoKey, String? syncUrl}){
    return RepositoryActionResult(type: RepositoryActionResultType.warn, data: info, action: action, repoKey: repoKey, syncUrl: syncUrl);
  }
  static List<RepositoryActionResult> dataChanges(Map<String,List<String>> changes, String repoBasePath, String repoKey, String? syncUrl, RepoTaskType action){
    List<String> newList = changes['new'] ?? [];
    List<String> modifiedList = changes['modified'] ?? [];
    List<String> deletedList = changes['deleted'] ?? [];
    List<String> renamedList = changes['renamed'] ?? [];
    List<RepositoryActionResult> results = [];
    for(var item in newList){
      if(item.endsWith('.md')){
        NoteInfo? note = NoteInfo.syncFrom(mdFile: '$repoBasePath/$repoKey/$item',repoLocalPath:repoKey);
        if(note != null){
          results.add(RepositoryActionResult(type: RepositoryActionResultType.dataInsert, data: note, action: action, repoKey: repoKey, syncUrl: syncUrl));
        }
      }
    }
    for(var item in modifiedList){
      if(item.endsWith('.md')){
        NoteInfo? note = NoteInfo.syncFrom(mdFile: '$repoBasePath/$repoKey/$item',repoLocalPath:repoKey);
        if(note != null){
          results.add(RepositoryActionResult(type: RepositoryActionResultType.dataUpdate, data: note, action: action, repoKey: repoKey, syncUrl: syncUrl));
        }
      }
    }
    for(var item in deletedList){
      if(item.endsWith('.md')){
        NoteInfo note = NoteInfo(repoKey: repoKey, mdKey: item);
        // note.repoKey = repoKey;
        // note.mdKey = item;
        results.add(RepositoryActionResult(type: RepositoryActionResultType.dataDelete, data: note, action: action, repoKey: repoKey, syncUrl: syncUrl));
      }
    }
    for(var item in renamedList){
      if(item.endsWith('.md')){
        NoteInfo? note = NoteInfo.syncFrom(mdFile: '$repoBasePath/$repoKey/$item',repoLocalPath:repoKey);
        if(note != null){
          results.add(RepositoryActionResult(type: RepositoryActionResultType.dataUpdate, data: note, action: action, repoKey: repoKey, syncUrl: syncUrl));
        }
      }
    }
    return results;
  }
}

class RepositoryAction {

  /// 返回变更详情，给外部进行数据库更新
  ///
  static List<RepositoryActionResult> commit({required String repoBasePath, required String repoKey, required String repoName, required String gitCommitConfigDirectoryPath}){
    try{
      var repository = Repository.open('$repoBasePath/$repoKey');
      // 检查变更状态
      Map<String,List<String>>? changes = _repoStatus(repository);
      if(changes != null && changes.isNotEmpty) {
        _stagingChanges(repository, changes); // 暂存变更
        _commitChanges(repo: repository, isRoot: repository.branches.isEmpty, repoKey:repoKey,gitCommitConfigDirectoryPath:gitCommitConfigDirectoryPath); // 提交变更
        repository.free();
        List<RepositoryActionResult> resList = RepositoryActionResult.dataChanges(changes, repoBasePath, repoKey, null, RepoTaskType.commit); // 返回结果列表
        resList.add(RepositoryActionResult.log('$repoName commit success ! (${resList.length} change)', action: RepoTaskType.commit, repoKey: repoKey));
        return resList;
      }
      repository.free();
      return [RepositoryActionResult.log('$repoName commit success ! (no change)', action: RepoTaskType.commit, repoKey: repoKey)];
    }catch(e){
      return [RepositoryActionResult.error('$repoName commit failure：' + e.toString(), action: RepoTaskType.commit, repoKey: repoKey)];
    }
  }

  static List<RepositoryActionResult> sync({required String gitCommitConfigDirectoryPath, required String repoBasePath, required String repoName, required String repoKey, required RepoSync syncItem, SSHKey? key, Function? progressCallback}){
    try{
      var pullResList = pull(gitCommitConfigDirectoryPath: gitCommitConfigDirectoryPath, repoBasePath: repoBasePath, repoName: repoName, repoKey: repoKey, syncItem: syncItem, key:key, progressCallback: progressCallback);
      for(var res in pullResList){ if(res.type == RepositoryActionResultType.error){ return pullResList; }} /// 报错则中断
      var pushResList = push(repoBasePath: repoBasePath, repoName: repoName, repoKey: repoKey, syncItem: syncItem, key:key, progressCallback: progressCallback);
      for(var pushRes in pushResList){ pullResList.add(pushRes); }
      return pullResList;
    }catch(e){
      return [RepositoryActionResult.error('$repoName sync failure：' + e.toString(), action: RepoTaskType.sync, repoKey: repoKey, syncUrl: syncItem.remotePath)];
    }
  }

  static List<RepositoryActionResult> pull({required String gitCommitConfigDirectoryPath, required String repoBasePath, required String repoName, required String repoKey, required RepoSync syncItem, SSHKey? key, Function? progressCallback}){
    /// 1、fetch
    /// 2、merge
    try{
      List<RepositoryActionResult> fetchResList = fetch(repoBasePath: repoBasePath, repoName: repoName, repoKey: repoKey, syncItem: syncItem, key: key, progressCallback: progressCallback);
      for(var res in fetchResList){ if(res.type == RepositoryActionResultType.error){ return fetchResList; }} /// 出错则中断
      List<RepositoryActionResult> mergeResList = merge(gitCommitConfigDirectoryPath: gitCommitConfigDirectoryPath,repoBasePath: repoBasePath, repoName: repoName, repoKey: repoKey, syncItem: syncItem, progressCallback: progressCallback);
      for(var mergeRes in mergeResList){ fetchResList.add(mergeRes); }
      return fetchResList;
    }catch(e){
      return [RepositoryActionResult.error('$repoName pull failure：' + e.toString(), action: RepoTaskType.pull, repoKey: repoKey, syncUrl: syncItem.remotePath)];
    }
  }

  static List<RepositoryActionResult> push({required String repoBasePath, required String repoName, required String repoKey, required RepoSync syncItem, SSHKey? key, Function? progressCallback}){
    try{
      var repository = Repository.open('$repoBasePath/$repoKey');
      Remote remote = Remote.lookup(repo: repository, name: syncItem.remoteName);
      Credentials? credentials;
      if(key != null){
        var username = syncItem.remotePath.split('@').first;
        if(username.isEmpty){ username = 'git'; }
        credentials = Keypair(username: username, pubKey: key.publicKeyPath ,privateKey: key.privateKeyPath,passPhrase: key.passPhrasePath);
      }
      String? currentCheckedOutBranch;
      for(var branch in repository.branches){
        if(branch.isCheckedOut){
          currentCheckedOutBranch = branch.name;
          break;
        }
      }
      if(currentCheckedOutBranch == null){
        return [RepositoryActionResult.error('$repoName push failure：no check out branch !', action: RepoTaskType.push, repoKey: repoKey, syncUrl: syncItem.remotePath)];
      }
      var gitCallbacks = GitCallbacks(
          credentials: credentials,
          callBack: (res){
            if (kDebugMode) { print(res.log); }
            if(progressCallback != null){ progressCallback(res.log); }
          }
      );
      remote.push(refspecs: ['refs/heads/$currentCheckedOutBranch'],callbacks: gitCallbacks);
      remote.free();
      repository.free();
      return [RepositoryActionResult.log('$repoName push success !', action: RepoTaskType.push, repoKey: repoKey, syncUrl: syncItem.remotePath)];
    }catch(e){
      return [RepositoryActionResult.error('$repoName push failure：' + e.toString(), action: RepoTaskType.push, repoKey: repoKey, syncUrl: syncItem.remotePath)];
    }

  }

  static List<RepositoryActionResult> fetch({required String repoBasePath, required String repoName, required String repoKey, required RepoSync syncItem, SSHKey? key, Function? progressCallback}){
    // print('------ $repoKey fetch begin ------');
    try{
      var repository = Repository.open('$repoBasePath/$repoKey');
      Remote remote = Remote.lookup(repo: repository, name: syncItem.remoteName);
      Credentials? credentials;
      if(key != null){
        var username = syncItem.remotePath.split('@').first;
        if(username.isEmpty){ username = 'git'; }
        credentials = Keypair(username: username, pubKey: key.publicKeyPath ,privateKey: key.privateKeyPath,passPhrase: key.passPhrasePath);
      }
      var gitCallbacks = GitCallbacks(
          credentials: credentials,
          callBack: (res){
            if (kDebugMode) { print(res.log); }
            if(progressCallback != null){ progressCallback(res.log); }
          }
      );
      remote.fetch(callbacks: gitCallbacks);
      remote.free();
      repository.free();
      // print('------ $repoKey fetch end ------');
      return [RepositoryActionResult.log('$repoName fetch success !', action: RepoTaskType.fetch, repoKey: repoKey, syncUrl: syncItem.remotePath)];
    }catch(e){
      // print('------ $repoKey fetch failure ------');
      return [RepositoryActionResult.error('$repoName fetch failure：' + e.toString(), action: RepoTaskType.fetch, repoKey: repoKey, syncUrl: syncItem.remotePath)];
    }
  }
  /// TODO:这个方法需要多测试，测试冲突、增删改
  static List<RepositoryActionResult> merge({required String gitCommitConfigDirectoryPath, required String repoBasePath, required String repoName, required String repoKey, required RepoSync syncItem, Function? progressCallback}){
    // print('------ $repoKey merge begin ------');
    try{
      var repository = Repository.open('$repoBasePath/$repoKey');
      // print(repository.references);
      // print(repository.branches);
      /// 远程如果有多个分支，则合并同名分支，且只合并当前checkedOut出来的分支
      /// 1、确定当前checkedOut的分支
      /// 2、从远程分支里找到与当前checkedOut分支同名的远程分支
      /// 3、合并这俩分支
      String? currentCheckedOutBranch;
      for(var branch in repository.branches){
        if(branch.isCheckedOut){
          currentCheckedOutBranch = branch.name;
          break;
        }
      }
      if(currentCheckedOutBranch == null){
        /// TODO:本地没有有效的分支，需要在本地创建一个有效的分支先，比如master分支，不然合并会出现unborn情况（猜测）
        ///
      }
      String remoteBranchName = '${syncItem.remoteName}/$currentCheckedOutBranch';
      Branch? remoteBranch;
      /// 当不存在remoteBranchName分支时，直接通过Branch.lookup去获取远程分支，会直接报错
      // Branch remoteBranch = Branch.lookup(repo: repository, name: remoteBranchName, type:GitBranch.remote);
      for(var branch in repository.branches){
        if(branch.name == remoteBranchName){
          remoteBranch = branch;
          break;
        }
      }
      if(currentCheckedOutBranch == null || remoteBranch == null){
        if(remoteBranch != null){
          remoteBranch.free();
        }
        repository.free();
        // print('------ $repoKey merge end ------');
        return [RepositoryActionResult.log('$repoName merge success (CheckedOutBranch:$currentCheckedOutBranch - RemoteBranch:$remoteBranch)!', action: RepoTaskType.merge, repoKey: repoKey, syncUrl: syncItem.remotePath)];
      }
      final theirHead = remoteBranch.target;
      final analysis = Merge.analysis(repo: repository, theirHead: theirHead);
      if (analysis.result.contains(GitMergeAnalysis.upToDate)) {
        remoteBranch.free();
        repository.free();
        // print('------ $repoKey merge end ------');
        return [RepositoryActionResult.log('$repoName merge success (The local is already up to date)!', action: RepoTaskType.merge, repoKey: repoKey, syncUrl: syncItem.remotePath)];
      }
      if (analysis.result.contains(GitMergeAnalysis.normal) || analysis.result.contains(GitMergeAnalysis.fastForward)) { // 走正常的合并流程
        final commit = AnnotatedCommit.lookup(repo: repository, oid: theirHead);
        /* 当一个文件的一个区域在两个分支中都被更改时
        GitMergeFileFavor.normal: 存在冲突则将被记录在索引中。这是默认值
        GitMergeFileFavor.ours: 在索引中创建的文件将包含任何冲突区域的“ours”端，即保留本地变更。索引不会记录冲突
        GitMergeFileFavor.theirs: 在索引中创建的文件将包含任何冲突区域的“theirs”端，即保留远程变更。索引不会记录冲突
        GitMergeFileFavor.union: 在索引中创建的文件将包含来自每一侧的每一个惟一行，这是合并两个文件的结果，即都保留。索引不会记录冲突。
        */
        /*
        GitMergeFlag.findRenames:检测发生在共同祖先和“ours”一方或共同祖先和“theirs”一方之间的重命名。这将支持合并修改后的和重命名后的文件。
        GitMergeFlag.failOnConflict:如果发生冲突，立即退出，而不是试图继续解决冲突。合并操作将失败，并且不会返回索引。
        GitMergeFlag.skipREUC:不在生成的索引上写入reuc扩展。
        noRecursive:如果合并的提交具有多个合并基，则不要构建递归合并基(通过合并多个合并基)，而只需使用第一个基。
        */
        /*
        GitMergeFileFlag.defaults:
        GitMergeFileFlag.styleMerge:创建标准的冲突合并文件。
        GitMergeFileFlag.styleDiff3:diff3-style
        GitMergeFileFlag.simplifyAlnum:为简化的diff文件压缩非字母数字区域。
        GitMergeFileFlag.ignoreWhitespace:忽略所有空白。
        GitMergeFileFlag.ignoreWhitespaceChange:忽略空白区域的变化。
        GitMergeFileFlag.ignoreWhitespaceEOL:忽略行尾的空格。
        GitMergeFileFlag.diffPatience:使用“patience diff”算法。
        GitMergeFileFlag.diffMinimal:多花点时间找出最小的差异。
        GitMergeFileFlag.styleZdiff3:zdiff3 ("zealous diff3")-style
        */
        Merge.commit(
            repo: repository,
            commit: commit,
            favor: GitMergeFileFavor.theirs, // 发生冲突，则保留远端的变更，不记录冲突
            mergeFlags: const {GitMergeFlag.findRenames}, // [mergeFlags]是[GitMergeFlag]标志的组合。默认为[GitMergeFlag.findRenames]。允许在修改后和重命名后的文件之间进行合并。
            fileFlags: const {GitMergeFileFlag.defaults}  // 创建冲突文件的风格
        );
        commit.free();
      }
      if (analysis.result.contains(GitMergeAnalysis.unborn)) { // 当前本地仓库，没有可用的分支，无法合并，需要在本地先创建对应分支,理论上不应该存在这种情况，我会在本地查到对应分支后才会合并
        // print('------ $repoKey merge end ------');
        return [RepositoryActionResult.error('$repoName merge failure：GitMergeAnalysis.unborn ！', action: RepoTaskType.merge, repoKey: repoKey, syncUrl: syncItem.remotePath)];
      }
      // return [RepositoryActionResult.log('$repoKey merge success (CheckedOutBranch:$currentCheckedOutBranch - RemoteBranch:$remoteBranch)!')];
      List<RepositoryActionResult> resList = [];
      if(repository.index.hasConflicts){
        resList.add(RepositoryActionResult.warn('$repoName - merge $remoteBranchName(${syncItem.remoteName}) into $currentCheckedOutBranch has conflicts :\n${repository.index.conflicts}', action: RepoTaskType.merge, repoKey: repoKey, syncUrl: syncItem.remotePath));
      }
      // print(repository.state);
      Map<String,List<String>>? changes = _repoStatus(repository);
      if(changes != null && changes.isNotEmpty) {
        /// 将新增、修改后的文件写入数据库并移除删除的文件
        List<RepositoryActionResult> changeResList = RepositoryActionResult.dataChanges(changes, repoBasePath, repoKey, syncItem.remotePath, RepoTaskType.merge); // 返回结果列表
        resList.addAll(changeResList);
      }
      // Make merge commit
      repository.index.write();
      var userInfo = Global.getUserInfo(repoKey: repoKey, configPath: gitCommitConfigDirectoryPath);
      var signature = Signature.create(name: userInfo['userName'] ?? 'Planting', email: userInfo['email'] ?? 'email@email.com');
      Commit.create(
        repo: repository,
        updateRef: 'HEAD',
        author: signature,
        committer: signature,
        message: 'Merge ${syncItem.remotePath}($currentCheckedOutBranch) into $currentCheckedOutBranch',
        tree: Tree.lookup(repo: repository, oid: repository.index.writeTree()),
        parents: [
          Commit.lookup(repo: repository, oid: repository.head.target),
          Commit.lookup(repo: repository, oid: theirHead),
        ],
      );
      repository.stateCleanup();
      repository.free();
      // print('------ $repoKey merge end ------');
      resList.add(RepositoryActionResult.log('$repoName merge success !', action: RepoTaskType.merge, repoKey: repoKey, syncUrl: syncItem.remotePath));
      return resList;//[RepositoryActionResult.log('$repoKey merge success !')];
    }catch(e){
      // print('------ $repoKey merge failure ------');
      return [RepositoryActionResult.error('$repoName merge failure：' + e.toString(), action: RepoTaskType.merge, repoKey: repoKey, syncUrl: syncItem.remotePath)];
    }
  }

  static List<RepositoryActionResult> diff({required String repoBasePath, required String repoName, required String repoKey, required RepoSync syncItem, Function? progressCallback}){
    return [];
  }

  /// 检查变更
  static Map<String,List<String>>? _repoStatus(Repository repo) {
    Map<String,List<String>> changeMap = {};
    List<String> newFile = [];
    List<String> modifiedFile = [];
    List<String> deletedFile = [];
    List<String> renamedFile = [];
    for (final file in repo.status.entries) {
      if (file.value.contains(GitStatus.indexNew) || file.value.contains(GitStatus.wtNew)) { // 新增
        newFile.add(file.key);
      }
      if (file.value.contains(GitStatus.indexModified) || file.value.contains(GitStatus.wtModified)) { // 修改
        modifiedFile.add(file.key);
      }
      if (file.value.contains(GitStatus.indexDeleted) || file.value.contains(GitStatus.wtDeleted)){ // 删除
        deletedFile.add(file.key);
      }
      if (file.value.contains(GitStatus.indexRenamed) || file.value.contains(GitStatus.wtRenamed)){ // 重命名
        renamedFile.add(file.key);
      }
    }
    changeMap['new'] = newFile;
    changeMap['modified'] = modifiedFile;
    changeMap['deleted'] = deletedFile;
    changeMap['renamed'] = renamedFile;
    if(newFile.isEmpty && modifiedFile.isEmpty && deletedFile.isEmpty && renamedFile.isEmpty){
      return null;
    }
    return changeMap;
  }

  /// 暂存变更
  static _stagingChanges(Repository repo, Map<String,List<String>> changes){
    List<String> newList = changes['new'] ?? [];
    List<String> modifiedList = changes['modified'] ?? [];
    List<String> deletedList = changes['deleted'] ?? [];
    List<String> renamedList = changes['renamed'] ?? [];
    final index = repo.index;
    if(newList.isNotEmpty){
      index.addAll(newList);
    }
    if(modifiedList.isNotEmpty){
      index.updateAll(modifiedList);
    }
    if(deletedList.isNotEmpty){
      index.updateAll(deletedList);
    }
    if(renamedList.isNotEmpty){
      index.updateAll(renamedList);
    }
    index.write();
  }

  /// 提交
  static _commitChanges({required Repository repo, required String repoKey, required String gitCommitConfigDirectoryPath, String? msg, bool isRoot = false}) {
    // final signature = repo.defaultSignature;
    /// 这个用户名和邮箱，需要从本地读取，每次都读取最新的
    var userInfo = Global.getUserInfo(repoKey: repoKey, configPath: gitCommitConfigDirectoryPath);
    print('------------');
    print(userInfo);
    print('------------');
    var signature = Signature.create(name: userInfo['userName'] ?? 'Planting', email: userInfo['email'] ?? 'email@email.com');
    print(signature);
    var commitMessage = msg ?? 'commit\n';
    repo.index.write();
    final oid = Commit.create(
      repo: repo,
      updateRef: 'HEAD',
      author: signature,
      committer: signature,
      message: commitMessage,
      tree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
      parents: isRoot ? [] : [Commit.lookup(repo: repo, oid: repo.head.target)],// root commit doesn't have parents
    );
    stdout.writeln('\n[${repo.head.shorthand} (root-commit) ${oid.sha.substring(0, 7)}] $commitMessage',);
  }

}