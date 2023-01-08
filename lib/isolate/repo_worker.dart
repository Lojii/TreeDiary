

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:treediary/config/global_data.dart';
import 'package:treediary/config/storage_manager.dart';
import 'package:treediary/isolate/git_isolate.dart';
import 'package:treediary/isolate/repo_task.dart';
import 'package:treediary/isolate/repository_action.dart';

import '../model/ssh_key.dart';
import '../provider/repo_list_model.dart';

enum RepoWorkerStatus { idle, processing }

// class RepoAction{
//   /// 写日记后，文件写入文件夹，数据库缓存好之后，发起一个commit事件
//   /// reset的时候，队列第一个位置，发起一个commit事件
//   /// 那就commit就相当于一次不移除正在执行操作的reset事件
//   // static String commit = 'commit';
//
//   static String modeChange = 'modeChange'; // 自动、手动变更，更新队列
//   static String addSync = 'addSync'; // 添加同步，将新增的添加到队列尾部
//   static String delSync = 'delSync'; // 移除同步队列，如果正在进行，则不管
//   static String reset = 'reset';  // 重置队列，首位放一个commit事件
// }

class RepoWorker{
  final RepoModel repo;
  // final String gitCommitConfigDirectoryPath;

  late final Isolate _isolate;          //
  late final ReceivePort _receivePort;  // 接收来自线程的消息
  late final SendPort _sendPort;        // 向线程发送消息
  bool connected = false;
  bool isBusy = false; //

  final taskQueue = Queue<RepoTask>(); // 执行队列

  // 初始化
  RepoWorker(this.repo);

  Future<void> init() async {
    _receivePort = ReceivePort();
    _receivePort.listen((dynamic msg) {
      if(msg is SendPort){
        _sendPort = msg;
        connected = true;
        resetQueue();
        next();
      }else if(msg is RepoTaskResult){
        if(msg.resultType == RepoTaskResultType.done){
          /// TODO:如果返回结果中包含:needRePush,则将其他的同步链接重新走一遍，这个需求先不做
          if(msg.resList.isNotEmpty){
            /// 交给外部进行处理，提示报错、数据库更新...
            GitIsolate.share.resultHandle(msg.resList, msg.taskType);
          }
          next();
        }
        if(msg.resultType == RepoTaskResultType.progress){
          if(msg.resList.isNotEmpty){
            GitIsolate.share.progressHandle(msg.resList.first.repoKey, msg.resList.first.syncUrl, '${msg.progress}');
          }
        }
      }
    });
    _isolate = await Isolate.spawn( executor, ExecutorParams(sendPort: _receivePort.sendPort,), debugName: repo.localPath, errorsAreFatal: false,);
    // print('${repo.name} init !');
  }

  next(){
    /// 将其他状态为执行中的syncItem变更为:执行完毕
    GitIsolate.share.workStateChange(repoKey: repo.key, repoName: repo.name, state: RepoStateChange.next);
    isBusy = false;
    if(taskQueue.isEmpty){
      /// 完成
      GitIsolate.share.workStateChange(repoKey: repo.key, repoName: repo.name, state: RepoStateChange.done);
      return;
    }
    isBusy = true;
    var task = taskQueue.removeFirst();
    _sendPort.send(task);
    /// 发送之后，变更为:执行中(fetch、merge、push)
    var type = task.type;
    var param = task.param;
    if(type == RepoTaskType.commit){ // 提交

    }else if(type == RepoTaskType.sync && param is RepoTaskSyncParam){ // 状态变更:同步中
      GitIsolate.share.workStateChange(repoKey: repo.key, syncUrl: param.syncItem.remotePath, repoName: repo.name, state: RepoStateChange.syncing);
    }else if(type == RepoTaskType.check && param is RepoTaskCheckParam){ // 状态变更:检查中
      /// TODO:检查
    }else{

    }
  }

  resetQueue(){
    var repoName = repo.name;

    var repoBasePath = Global.repoBaseDir;
    var repoKey = repo.key;
    taskQueue.clear();
    taskQueue.add(RepoTask(type: RepoTaskType.commit, param: RepoTaskParam(repoKey: repoKey, repoBasePath: repoBasePath, repoName: repoName,gitCommitConfigDirectoryPath: Global.gitCommitConfigDirectoryPath)));
    // GitIsolate.share.workStateChange(repoKey: repoKey, repoName: repoName, state: '排队中(等待Commit)'); /// commit 不需要搞个中间状态，没啥意义
    for(var syncItem in repo.syncList){
      if(syncItem.isAutoSync){
        SSHKey? key = SSHKey.onlyKeyPathSync(syncItem.sshKeyId);
        taskQueue.add(RepoTask(type: RepoTaskType.sync, param: RepoTaskSyncParam(repoKey: repoKey, repoBasePath: repoBasePath, repoName: repoName, syncItem: syncItem, key: key,gitCommitConfigDirectoryPath: Global.gitCommitConfigDirectoryPath)));
        /// 加入队列后，syncItem对应的状态变更为:排队中
        GitIsolate.share.workStateChange(repoKey: repoKey, syncUrl: syncItem.remotePath, repoName: repoName, state: RepoStateChange.waitingForTheSync);
      }else{
        /// TODO:check
        // taskQueue.add(RepoTask(type: RepoTaskType.fetch, param: RepoTaskCommitParam(repoKey: repoKey, repoBasePath: repoBasePath)));
        // taskQueue.add(RepoTask(type: RepoTaskType.diff, param: RepoTaskCommitParam(repoKey: repoKey, repoBasePath: repoBasePath)));
        // GitIsolate.share.workStateChange(repoKey: repoKey, syncUrl: syncItem.remotePath, repoName: repoName, state: RepoStateChange.waitingForTheCheck);
      }
    }
  }

  // commit需要将所有任务队列重来一遍
  commit(){
    resetQueue();
    if(!isBusy){ next(); }
  }
  // 主动触发同步
  sync(String gitUrl){
    // 判断是否在队列中且队列中的是同步任务，如果不是，则直接将同步任务添加到队列
    for(var task in taskQueue){
      if(task.type == RepoTaskType.sync){
        var param = task.param;
        if(param is RepoTaskSyncParam){
          if(param.syncItem.remotePath == gitUrl){ // 已经在队列中，不需要重复添加
            return;
          }
        }
      }
    }
    var repoBasePath = Global.repoBaseDir;
    for(var syncItem in repo.syncList) {
      if(syncItem.remotePath == gitUrl){
        SSHKey? key = SSHKey.onlyKeyPathSync(syncItem.sshKeyId);
        taskQueue.add(RepoTask(type: RepoTaskType.sync,
            param: RepoTaskSyncParam(repoKey: repo.key,
                repoBasePath: repoBasePath,
                repoName: repo.name,
                syncItem: syncItem,
                key: key,
                gitCommitConfigDirectoryPath: Global.gitCommitConfigDirectoryPath
            )));

        /// 加入队列后，syncItem对应的状态变更为:排队中
        GitIsolate.share.workStateChange(repoKey: repo.key,
            syncUrl: syncItem.remotePath,
            repoName: repo.name,
            state: RepoStateChange.waitingForTheSync);
        if(!isBusy){ next(); }
        return;
      }
    }
  }

  dispose(){
    taskQueue.clear();
    _receivePort.close();
    _isolate.kill();
  }

  addRepoSync(RepoSync syncItem){
    for(var s in repo.syncList){
      if(s.remotePath == syncItem.remotePath){
        repo.syncList.remove(s);
        break;
      }
    }
    repo.syncList.insert(0, syncItem);
    resetQueue();
    if(!isBusy){ next(); }
  }
  removeRepoSync(RepoSync syncItem){

  }
  updateRepoSync(RepoSync syncItem){

  }

}

class ExecutorParams {
  SendPort sendPort;
  RepoTask? task;
  ExecutorParams({required this.sendPort, this.task});
}

executor(ExecutorParams params) {
  final receivePort = ReceivePort();
  final sendPort = params.sendPort; // 向外部发送消息
  sendPort.send(receivePort.sendPort);
  receivePort.listen((task) { // 队列操作：新增、移除、调整顺序
    List<RepositoryActionResult> resList = [];
    if(task is RepoTask){
      // print('线程内收到消息:${task.type}');
      /// commit
      if(task.type == RepoTaskType.commit){
        RepoTaskParam taskParam = task.param;
        if(taskParam.call != null){taskParam.call!();}
        resList = RepositoryAction.commit(repoBasePath: taskParam.repoBasePath, repoKey: taskParam.repoKey, repoName: taskParam.repoName,gitCommitConfigDirectoryPath: taskParam.gitCommitConfigDirectoryPath);
      }
      /// sync
      if(task.type == RepoTaskType.sync){
        RepoTaskSyncParam taskParam = task.param as RepoTaskSyncParam;
        if(taskParam.call != null){taskParam.call!();}
        resList = RepositoryAction.sync(repoBasePath: taskParam.repoBasePath, repoName: taskParam.repoName, repoKey: taskParam.repoKey, syncItem: taskParam.syncItem, key: taskParam.key, gitCommitConfigDirectoryPath: taskParam.gitCommitConfigDirectoryPath, progressCallback: (progress){
          var p = RepositoryActionResult.progress(progress, action: RepoTaskType.sync, repoKey: taskParam.repoKey, syncUrl:taskParam.syncItem.remotePath );
          sendPort.send(RepoTaskResult(taskType:task.type, resultType:RepoTaskResultType.progress, message: 'progress', resList: [p], progress:progress));
        });
      }
      /// TODO:check

      sendPort.send(RepoTaskResult(taskType:task.type, resultType:RepoTaskResultType.done, message: 'next', resList: resList));
    }else{
      resList.add(RepositoryActionResult.error('unknown task:$task', action: RepoTaskType.unknown, repoKey: ''));
      sendPort.send(RepoTaskResult(resultType:RepoTaskResultType.done, message: 'unknown task:$task', resList: resList));
    }
  });
}