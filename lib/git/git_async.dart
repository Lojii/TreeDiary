
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:treediary/model/ssh_key.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/string_utils.dart';
import 'package:thread/thread.dart';

import 'git_action.dart';
import 'git_callbacks.dart';

class GitAsyncRes<T>{
  int code;  // -1:失败 0:成功 1:进行中
  String msg;
  T? data;
  GitAsyncRes({this.msg = '',this.code = 0, this.data});

  static GitAsyncRes success<T>({T? data}){ return GitAsyncRes(msg: 'success', code: 0, data: data); }
  static GitAsyncRes failure<T>({String? msg, T? data}){ return GitAsyncRes(msg: msg ?? 'failure', data: data, code: -1); }
  static GitAsyncRes progress<GitAsyncCallbackRes>({GitAsyncCallbackRes? data}){ return GitAsyncRes(msg: 'progress', code: 1, data: data); }
}

class GitAsyncArgs{
  SendPort sendPort;
  String? gitUrl;
  String? repositoryDir;
  SSHKey? sshKey;

  GitAsyncArgs({required this.sendPort, this.repositoryDir, this.sshKey, this.gitUrl});

  static GitAsyncArgs clone({required SendPort sendPort,required String repositoryDir,required String gitUrl, SSHKey? sshKey}){
    return GitAsyncArgs(sendPort:sendPort, repositoryDir:repositoryDir, gitUrl:gitUrl, sshKey:sshKey);
  }

  static GitAsyncArgs check({required SendPort sendPort,required String repositoryDir,required String gitUrl, SSHKey? sshKey}){
    return GitAsyncArgs(sendPort:sendPort, repositoryDir:repositoryDir, gitUrl:gitUrl, sshKey:sshKey);
  }
}

class GitAsync {
  /// clone
  static void clone(GitAsyncArgs args) {
    SendPort sendPort = args.sendPort;
    String? gitUrl = args.gitUrl;
    String? repositoryDir = args.repositoryDir;
    SSHKey? sshKey = args.sshKey;
    if(gitUrl == null || gitUrl.isEmpty){
      sendPort.send(GitAsyncRes.failure(msg:'GitUrl cannot be empty ！'));
      return;
    }
    if(repositoryDir == null || repositoryDir.isEmpty){
      sendPort.send(GitAsyncRes.failure(msg:'Repository folder cannot be empty ！'));
      return;
    }
    try{
      Keypair? keypair;
      if(sshKey != null){
        String username = 'git';
        if(gitUrl.contains('@')){ username = gitUrl.split('@').first; }
        keypair = Keypair(username: username,pubKey: sshKey.publicKeyPath ,privateKey: sshKey.privateKeyPath,passPhrase: sshKey.passPhrasePath);
      }
      var gitCallbacks = GitCallbacks(
        credentials: keypair,
        callBack: (res){
          // if (kDebugMode) { print(res.log); }
          sendPort.send(GitAsyncRes.progress(data:res));
        }
      );
      if (kDebugMode) { print('------ clone start ------'); }
      final repository = Repository.clone( url: gitUrl, localPath: repositoryDir, callbacks:gitCallbacks);
      if (kDebugMode) { print('------ clone end ------'); }
      if (kDebugMode) { print(repository.toString()); }
      repository.free();
      sendPort.send(GitAsyncRes.success());
    }catch(e, s){
      String errorMsg = e.toString();
      if (kDebugMode) { print('------ clone failure ------\n$errorMsg \n$s'); }
      sendPort.send(GitAsyncRes.failure(msg:errorMsg));
    }
  }
  /// check
  static void check(GitAsyncArgs args){
    SendPort sendPort = args.sendPort;
    String? gitUrl = args.gitUrl;
    String? repositoryDir = args.repositoryDir;
    SSHKey? sshKey = args.sshKey;
    if(gitUrl == null || gitUrl.isEmpty){
      sendPort.send(GitAsyncRes.failure(msg:'GitUrl cannot be empty ！'));
      return;
    }
    if(repositoryDir == null || repositoryDir.isEmpty){
      sendPort.send(GitAsyncRes.failure(msg:'Repository folder cannot be empty ！'));
      return;
    }
    String? name;
    try{
      final repository = Repository.open(repositoryDir);
      String newRemoteName = StringUtils.randomString(8);
      Remote? newRemote;
      for (final remoteName in repository.remotes) {
        final remote = Remote.lookup(repo: repository, name: remoteName);
        if(remote.url == gitUrl){
          newRemote = remote;
          break;
        }
        remote.free();
      }
      if(newRemote == null){
        Remote.create(repo: repository, name: newRemoteName, url: gitUrl);
        newRemote = Remote.lookup(repo: repository, name: newRemoteName);
      }
      name = newRemoteName;
      Keypair? keypair;
      if(sshKey != null){
        // print(sshKey.privateKey.length);
        // print(sshKey.privateKeyPath);
        String username = 'git';
        if(gitUrl.contains('@')){ username = gitUrl.split('@').first; }
        keypair = Keypair(username: username,pubKey: sshKey.publicKeyPath ,privateKey: sshKey.privateKeyPath,passPhrase: sshKey.passPhrasePath);
      }
      var gitCallbacks = GitCallbacks( credentials: keypair,  callBack: (res){ if (kDebugMode) { print(res.log); } } );
      if (kDebugMode) { print('------ check start ------'); }
      List<RemoteReference> res = newRemote.ls(callbacks:gitCallbacks);
      if (kDebugMode) { print('------ check end ------'); }
      if (kDebugMode) { print(res); }
      repository.free();
      newRemote.free();
      sendPort.send(GitAsyncRes.success(data: newRemoteName));
    }catch(e, s){
      String errorMsg = e.toString();
      if (kDebugMode) { print('------ check failure ------\n$errorMsg \n$s'); }
      /// 判断，如果是协议不合法、链接不合法，则移除已添加的remote，并返回空的remoteName，不能继续添加
      var lowerStr = errorMsg.toLowerCase();
      if(lowerStr.contains('unsupported url protocol') || lowerStr.contains('failed to resolve address')){
        if(name != null){
          try {
            final repository = Repository.open(repositoryDir);
            Remote.delete(repo: repository, name: name);
            repository.free();
          }catch(e) {
            if (kDebugMode) { print('------ check : delete remote $name failure ------\n$e'); }
          }
          name = null;
        }
      }
      sendPort.send(GitAsyncRes.failure(msg:errorMsg, data: name));
    }
  }

/*
  * 1、检测链接是否可用，用于添加远程同步
  * 2、pull方法、结合fetch和merge
  * 3、fetch方法，抓取变更，用于检查同步情况
  * 4、merge方法
  * 5、push方法
  * 6、commit方法
  * 7、冲突解决方法
  * 8、clone方法
  * */

}