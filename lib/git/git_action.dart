/*
此类用于clone、检查远程链接可用性、移除远程同步链接
commit、fetch、merge、push等异步方法在git_isolate里
*/
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:treediary/model/ssh_key.dart';
import 'package:treediary/repo/repo_manager.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:provider/provider.dart';

import '../provider/global_language.dart';
import '../provider/repo_list_model.dart';
import '../utils/string_utils.dart';
import 'git_async.dart';
import 'git_callbacks.dart';


typedef GitProgressCallback = void Function(GitAsyncCallbackRes? progress);
typedef GitSuccessCallback = void Function(String? repoFullPath);
typedef GitFailureCallback = void Function(String? errorMsg);
typedef GitCheckFailureCallback = void Function(String? errorMsg,String? remoteName); // 如果检查失败，依旧返回remoteName，如果remoteName为空，则说明添加Remote失败

class GitActionContext{
  Isolate? isolate;
  ReceivePort? receivePort;
  bool isRunning = false;
  //
  close(){
    receivePort?.close();
    isolate?.kill();
  }
}

class GitAction {
  /// 如果重名，则在后面添加序号
  static Future<Directory?> _createDir({required String dirPath, int index = 0}) async {
    var dir = Directory(dirPath + (index == 0 ? '' : '$index')); // 文件夹名称后面空格+序号
    if(await dir.exists()){ return _createDir(dirPath: dirPath, index: ++index); }
    try{
      await dir.create();
    }catch(e){
      if (kDebugMode) { print('create dir $dir error:$e'); }
      return null;
    }
    return dir;
  }
  /// 创建文件夹，如果存在重名的文件夹，则在此文件夹名称后面添加序号，如果文件夹名称不合规，则使用默认文件夹名称pt_2022060323455
  static Future<String?> _createRepositoryDir(String gitUrl) async{
    Directory? appDir = await RepoManager.repoBasePath();
    if(appDir == null){ return null; }
    String uriPart = gitUrl.split('?').first; // 移除尾部参数
    String lastPart = uriPart.split('/').last; // 提取最后部分
    String namePart = lastPart.split('.git').first; // 提取名称
    String repositoryDir = '${appDir.path}/$namePart';
    var dir = await _createDir(dirPath: repositoryDir);
    if(dir == null){ // 如果创建失败，则使用默认名称pt_2022060323455
      var timeStr = DateTime.now().toString().replaceAll('-', "").replaceAll(':', '').replaceAll(' ', '').split('.').first;
      repositoryDir =  '${appDir.path}/pt_$timeStr';
      dir = await _createDir(dirPath: repositoryDir);
    }
    return dir?.path;
  }


  /// clone - clone后，将该gitUrl添加到远程同步链接里
  static clone({required String gitUrl, SSHKey? key, GitProgressCallback? progressCallback, GitSuccessCallback? successCallback, GitFailureCallback? failureCallback}) async {
    String? repositoryDir = await _createRepositoryDir(gitUrl); /// 尝试使用url里的文件夹进行命名，如果重名，则在后面添加序号
    if(repositoryDir == null){
      if(failureCallback != null){ failureCallback('文件夹创建失败'); }
      return;
    }
    Isolate? isolate;
    ReceivePort receivePort = ReceivePort();
    receivePort.listen((dynamic message) {
      if (message is GitAsyncRes) {
        int code = message.code;
        String msg = message.msg;
        var data = message.data;
        if(code == -1){ /// failure
          try{
            Directory(repositoryDir).deleteSync(recursive:true);
          }catch(e){
            if (kDebugMode) { print('clone failure and delete dir $repositoryDir failure :$e'); }
          }
          if(failureCallback != null){ failureCallback(msg); }
        }else if(code == 0){ /// success
          if(successCallback != null){ successCallback(repositoryDir); }
        }else if(code == 1){ /// progress
          if(progressCallback != null){ progressCallback(data); }
        }
        /// 释放资源
        if(code != 1){
          if (kDebugMode) { print('$gitUrl clone receivePort.close();'); }
          receivePort.close();
          if(isolate != null){
            if (kDebugMode) { print('$gitUrl clone isolate.kill();'); }
            isolate.kill();
          }
        }
      }
    });
    isolate = await Isolate.spawn(GitAsync.clone, GitAsyncArgs.clone(sendPort:receivePort.sendPort, repositoryDir:repositoryDir, gitUrl:gitUrl, sshKey:key), debugName: 'clone_isolate');
  }

  /// 检查远程链接可达性
  static check({required String repositoryDir, required String gitUrl, SSHKey? key, GitSuccessCallback? successCallback, GitCheckFailureCallback? failureCallback}) async{
    Isolate? isolate;
    ReceivePort receivePort = ReceivePort();
    receivePort.listen((dynamic message) {
      if (message is GitAsyncRes) {
        int code = message.code;
        String msg = message.msg;
        var remoteName = message.data; /// 返回远程分支在本地的名称
        if(code == -1){ /// failure
          if(failureCallback != null){ failureCallback(msg, remoteName); }
        }else if(code == 0){ /// success
          if(successCallback != null){ successCallback(remoteName); }
        }
        /// 释放资源
        if(code != 1){
          if (kDebugMode) { print('$gitUrl check receivePort.close();'); }
          receivePort.close();
          if(isolate != null){
            if (kDebugMode) { print('$gitUrl check isolate.kill();'); }
            isolate.kill();
          }
        }
      }
    });
    isolate = await Isolate.spawn(GitAsync.check, GitAsyncArgs.check(sendPort:receivePort.sendPort, repositoryDir:repositoryDir, gitUrl:gitUrl, sshKey:key), debugName: 'check_isolate');
  }

  static removeRemote(String repoPath, String gitUrl) async{
    try{
      var repository = Repository.open(repoPath);
      List<String> needRemoves = [];
      for (final remoteName in repository.remotes) {
        final remote = Remote.lookup(repo: repository, name: remoteName);
        if(remote.url == gitUrl){
          needRemoves.add(remoteName);
        }
      }
      for(var name in needRemoves){
        Remote.delete(repo: repository, name: name);
      }
    }catch(e){
      if (kDebugMode) { print('❌ removeRemote error ! $e'); }
    }
  }
  /// 检查失败，仍然添加的时候，会调用
  static String? addRemote(String repoPath, String gitUrl) {
    try{
      var repository = Repository.open(repoPath);
      String newRemoteName = StringUtils.randomString(8);
      Remote? newRemote;
      for (final remoteName in repository.remotes) {
        final remote = Remote.lookup(repo: repository, name: remoteName);
        if(remote.url == gitUrl){
          newRemote = remote;
          newRemoteName = remoteName;
          break;
        }
        remote.free();
      }
      if(newRemote == null){
        Remote.create(repo: repository, name: newRemoteName, url: gitUrl);
        newRemote = Remote.lookup(repo: repository, name: newRemoteName);
      }
      newRemote.free();
      if (kDebugMode) { print('✅ addRemote success ! $newRemoteName - $repoPath - $gitUrl'); }
      return newRemoteName;
    }catch(e){
      if (kDebugMode) { print('❌ addRemote error ! $e'); }
      return null;
    }
  }

}