import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:treediary/config/global_data.dart';
import 'package:treediary/isolate/repository_action.dart';

import '../model/ssh_key.dart';
import '../provider/repo_list_model.dart';


enum RepoTaskType {
  commit, // 遇到commit之后，重置后面所有pull、push
  fetch,
  diff,
  merge,
  pull,   // = fetch + merge
  push,   // pull 之后如果有变更则将剩余的同步列表重复执行push
  sync,   // = pull + push
  check,  // = fetch + diff
  unknown,
}

class RepoTaskParam{
  final Function? call;
  String repoBasePath;
  String repoKey;
  String repoName;
  String gitCommitConfigDirectoryPath;
  RepoTaskParam({this.call, required this.repoKey, required this.repoBasePath, required this.repoName, required this.gitCommitConfigDirectoryPath});
}

// class RepoTaskCommitParam extends RepoTaskParam{
//   RepoTaskCommitParam({Function? call, required String repoKey, required String repoBasePath}) : super(call:call, repoKey:repoKey, repoBasePath:repoBasePath);
// }

class RepoTaskSyncParam extends RepoTaskParam{
  RepoSync syncItem;
  SSHKey? key;
  RepoTaskSyncParam( {Function? call, required String repoKey, required String repoBasePath, required this.syncItem, this.key, required String repoName, required String gitCommitConfigDirectoryPath }) : super(call:call, repoKey:repoKey, repoBasePath:repoBasePath, repoName: repoName, gitCommitConfigDirectoryPath:gitCommitConfigDirectoryPath);
}

class RepoTaskCheckParam extends RepoTaskParam{
  RepoSync syncItem;
  SSHKey? key;
  RepoTaskCheckParam( {Function? call, required String repoKey, required String repoBasePath, required this.syncItem, this.key, required String repoName, required String gitCommitConfigDirectoryPath }) : super(call:call, repoKey:repoKey, repoBasePath:repoBasePath, repoName: repoName, gitCommitConfigDirectoryPath:gitCommitConfigDirectoryPath);
}














class RepoTask{
  final RepoTaskParam param;
  final RepoTaskType type;
  RepoTask({this.type = RepoTaskType.unknown, required this.param,});
}

enum RepoTaskResultType {
  done,
  progress,
  unknown,
}

class RepoTaskResult {
  final RepoTaskType taskType;
  final RepoTaskResultType resultType;
  final String? message;
  final Object? progress;
  final List<RepositoryActionResult> resList;

  RepoTaskResult( {this.resultType = RepoTaskResultType.unknown, this.taskType = RepoTaskType.unknown, this.message, this.progress, required this.resList, });
}
