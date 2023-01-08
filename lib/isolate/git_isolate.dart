

import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:treediary/isolate/repo_task.dart';
import 'package:treediary/isolate/repo_worker.dart';
import 'package:treediary/isolate/repository_action.dart';
import 'package:provider/provider.dart';

import '../repo/note_info.dart';
import '../provider/repo_list_model.dart';
import '../provider/task_model.dart';

// GitIsolate GitIsolateShare = GitIsolate();

/// 异步操作就三种，commit\sync\check
enum RepoStateChange {
  waitingForTheSync,   // 等待同步(fetch+merge)
  syncing,    // 同步中
  syncSuccess,// 同步成功
  syncFailure,// 同步失败

  waitingForTheCheck,  // 等待检查(fetch+diff)
  checking,   // 检查中
  checkSuccess,// 检查成功
  checkFailure,// 检查失败

  next,    // 将所有正在进行中的变更为成功
  done,    // 全部完成
}

class GitIsolate{

  late BuildContext context;

  static GitIsolate share = GitIsolate();

  Map<String, RepoWorker> workers = {};

  static final GitIsolate _singleton = GitIsolate._internal();
  factory GitIsolate() => _singleton;
  GitIsolate._internal() { init(); }

  void init() {
    print('初始化');
  }

  /// 增减 通过下面的方法 ,持有context，用于实时更新外部状态
  run(List<RepoModel> repos, BuildContext c){
    if(workers.isNotEmpty){ return; }
    context = c;
    // Provider.of<TaskModel>(context, listen:false).init();
    for(var repo in repos){
      RepoWorker worker = RepoWorker(repo);
      worker.init();
      workers[repo.localPath] = worker;
    }
  }

  ///


  /// TODO:仓库增删改
  /// 一般是在新建了本地仓库，或者clone了新的仓库才会执行该操作
  updateRepo(RepoModel repo){
    RepoWorker? repoWorker = workers[repo.key];
    if(repoWorker != null){ // update
      repoWorker.resetQueue();
    }else{ // add
      RepoWorker worker = RepoWorker(repo);
      worker.init();
      workers[repo.localPath] = worker;
    }
  }
  removeRepo(String repoKey){
    RepoWorker? repoWorker = workers[repoKey];
    if(repoWorker != null){
      repoWorker.dispose();
      workers.remove(repoKey);
    }
  }
  /// TODO:远程同步地址增删改
  addRepoSync(RepoSync syncItem){
    RepoWorker? repoWorker = workers[syncItem.repoPath];
    if(repoWorker == null){
      if (kDebugMode) { print('Worker:${syncItem.repoPath} not exist !'); }
      return;
    }
    repoWorker.addRepoSync(syncItem);
  }
  removeRepoSync(RepoSync syncItem){
    RepoWorker? repoWorker = workers[syncItem.repoPath];
    if(repoWorker == null){
      print('Worker:${syncItem.repoPath} not exist !');
      return;
    }
    repoWorker.removeRepoSync(syncItem);
  }
  updateRepoSync(RepoSync syncItem){
    RepoWorker? repoWorker = workers[syncItem.repoPath];
    if(repoWorker == null){
      print('Worker:${syncItem.repoPath} not exist !');
      return;
    }
    repoWorker.updateRepoSync(syncItem);
  }
  /// 触发commit
  commit(String repoKey){
    RepoWorker? repoWorker = workers[repoKey];
    if(repoWorker == null){
      print('Worker:$repoKey not exist !');
      return;
    }
    repoWorker.commit();
  }
  /// 主动触发同步
  sync(String repoKey, String gitUrl){
    RepoWorker? repoWorker = workers[repoKey];
    if(repoWorker == null){
      print('Worker:$repoKey not exist !');
      return;
    }
    repoWorker.sync(gitUrl);
  }
  /// 运行结果处理，提示报错、数据库更新、外部状态更新...
  resultHandle(List<RepositoryActionResult> resList, RepoTaskType taskType){
    // print('------ resultHandle ------');
    List<String> logs = [];
    String repoKey = '';
    String? syncUrl;
    bool hasError = false;
    for(var res in resList){
      repoKey = res.repoKey;
      syncUrl = res.syncUrl;
      if(res.type == RepositoryActionResultType.dataInsert || res.type == RepositoryActionResultType.dataUpdate){
        var note = res.data;
        if(note is NoteInfo){
          note.saveToDB();
          logs.add('save line : ${note.mdKey}');
        }
      }
      if(res.type == RepositoryActionResultType.dataDelete){
        var note = res.data;
        if(note is NoteInfo){
          NoteInfo.deleteToDB(mdKey: note.mdKey, repoKey: note.repoKey);
          logs.add('delete line : ${note.mdKey}');
        }
      }
      if(res.type == RepositoryActionResultType.dataRefresh){ // 重建日记数据库
        /// TODO:重建日记数据库
        logs.add('refresh database ${res.repoKey}');
      }
      if(res.type == RepositoryActionResultType.info){
        var info = res.data;
        if(info is String){ logs.add(info); }
      }
      if(res.type == RepositoryActionResultType.log){
        var log = res.data;
        if(log is String){ logs.add(log); }
      }
      if(res.type == RepositoryActionResultType.warn){
        var warn = res.data;
        if(warn is String){ logs.add('⚠️ - ' + warn); }
      }
      if(res.type == RepositoryActionResultType.error){ /// 结果列表里理论上只会有一条error
        var error = res.data;
        if(error is String){ logs.add('️‼️ - ' + error); }
        hasError = true;
      }
    }
    if(hasError){ /// 如果发生报错，则将操作改成失败
      if(taskType == RepoTaskType.sync){ // syncFailure
        Provider.of<TaskModel>(context, listen:false).setSyncState(repoKey, RepoStateChange.syncFailure, syncUrl);
      }else if(taskType == RepoTaskType.check){ // checkFailure
        Provider.of<TaskModel>(context, listen:false).setSyncState(repoKey, RepoStateChange.checkFailure, syncUrl);
      }else{ // done
        Provider.of<TaskModel>(context, listen:false).setSyncState(repoKey, RepoStateChange.done, syncUrl);
      }
    }else{ /// 没有报错，则成功
      if(taskType == RepoTaskType.sync){ // syncSuccess
        Provider.of<TaskModel>(context, listen:false).setSyncState(repoKey, RepoStateChange.syncSuccess, syncUrl);
        RepoSync.updateLastSyncTime(repoKey, syncUrl ?? '');
        print('同步成功:$syncUrl');
      }else if(taskType == RepoTaskType.check){ // checkSuccess
        Provider.of<TaskModel>(context, listen:false).setSyncState(repoKey, RepoStateChange.checkSuccess, syncUrl);
      }else{ // done
        Provider.of<TaskModel>(context, listen:false).setSyncState(repoKey, RepoStateChange.done, syncUrl);
      }
    }
    Provider.of<TaskModel>(context, listen:false).setLogs(repoKey, syncUrl, logs);
  }
  /// 进度处理
  progressHandle(String repoKey, String? syncUrl, String progress){
    Provider.of<TaskModel>(context, listen:false).setProgress(repoKey, syncUrl, progress);
  }
  /// 状态处理
  workStateChange({required String repoKey, String? syncUrl, String? repoName, required RepoStateChange state}){
    // print('State Change ------ $repoKey - $syncUrl - $repoName - $state');
    if(state == RepoStateChange.done || state == RepoStateChange.next){ // 将所有正在进行的状态改为已完成
      Provider.of<TaskModel>(context, listen:false).finishAllSync(repoKey);
    }else{
      Provider.of<TaskModel>(context, listen:false).setSyncState(repoKey, state, syncUrl);
    }
  }


}