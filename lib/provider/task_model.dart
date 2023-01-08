
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';

import 'package:treediary/provider/repo_list_model.dart';

import '../isolate/git_isolate.dart';

class SyncTask{
  RepoStateChange state = RepoStateChange.done; // 排队中、执行中、执行成功、执行失败
  List<String> logs = []; // 每次重试的时候重置logs
  // List<String> progress = []; // 执行中的进度log
}

/// 对接异步任务的model
class TaskModel extends ChangeNotifier {

  Map<String, Map<String, SyncTask>> repoTask = {};

  bool isBusy(){
    for(var k in repoTask.keys){
      var v = repoTask[k];
      if(v == null){ continue; }
      for(var vk in v.keys){
        var vv = v[vk];
        if(vv == null){ continue; }
        if(vv.state == RepoStateChange.syncing){
          return true;
        }
      }
    }
    return false;
  }

  reset(List<RepoModel> repoList){
    for(var repo in repoList){
      Map<String, SyncTask> syncMap = {};
      for(var syncItem in repo.syncList){
        SyncTask syncTask = SyncTask();
        syncMap[syncItem.remotePath] = syncTask;
      }
      repoTask[repo.key] = syncMap;
    }
  }

  static TaskModel create(List<RepoModel> repoList){
    TaskModel model = TaskModel();
    model.reset(repoList);
    return model;
  }
  ///
  setSyncState(String repoKey, RepoStateChange state, String? syncUrl){
    // print('setSyncState - $repoKey - $syncUrl - $state');
    var r = repoTask[repoKey];
    if(r != null && syncUrl != null){
      var s = r[syncUrl];
      if(s != null){
        s.state = state;
      }else{
        r[syncUrl] = SyncTask();
        r[syncUrl]?.state = state;
      }
    }
    if(r == null){
      repoTask[repoKey] = {}; // 新建对应数据
    }
    // print('\n------\n$repoTask\n------\n');
    notifyListeners();
  }
  /// 将所有ing的改成done
  finishAllSync(String repoKey){
    // print('finishAllSync');
    var map = repoTask[repoKey];
    if(map != null){
      for(var v in map.values){
        if(v.state == RepoStateChange.syncing || v.state == RepoStateChange.checking){
          v.state = RepoStateChange.done;
        }
      }
    }
    notifyListeners();
  }
  resetSync(String repoKey, String? syncUrl){
    if(syncUrl != null){
      repoTask[repoKey]?[syncUrl] = SyncTask();
    }else{
      var repoMap = repoTask[repoKey] ?? {};
      for(var k in repoMap.keys){
        repoMap[k] = SyncTask();
      }
    }
    notifyListeners();
  }
  ///
  setProgress(String repoKey, String? syncUrl, String progress){
    print(progress);
    repoTask[repoKey]?[syncUrl]?.logs.add(progress);
    notifyListeners();
  }
  ///
  setLogs(String repoKey, String? syncUrl, List<String> logs){
    print(logs);
    repoTask[repoKey]?[syncUrl]?.logs.addAll(logs);// = logs;
    notifyListeners();
  }

}