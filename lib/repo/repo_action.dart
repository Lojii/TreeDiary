import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as path;

// import 'package:treediary/common/utils/common_utils.dart';

import '../config/global_data.dart';
import 'repo_util.dart';

class RepoAction {
  /// Initialize a repository at provided path.
  ///
  /// Similar to `git init`.
  static Repository initRepo(String path) {
    final repo = Repository.init(path: path);
    stdout.writeln('Initialized empty Git repository in ${repo.path}');
    return repo;
  }

  /// Setup user name and email.
  ///
  /// Similar to:
  /// - `git config --add user.name "User Name"`
  /// - `git config --add user.email "user@email.com"`
  static setupNameAndEmail({required Repository repo, String? userName, String? userEmail}) {
    final config = repo.config;
    config['user.name'] = userName ?? 'Forester';
    config['user.email'] = userEmail ?? 'forester@planting.cn';
  }
  //
  // ///
  // /// Similar to `git add file.txt`
  // static stageUntracked({required Repository repo, required String filePath}) {
  //   final index = repo.index;
  //   index.add(filePath);
  //   index.write();
  //   stdout.writeln('\nStaged previously untracked file $filePath');
  // }
  //
  // ///
  // /// Similar to `git add file.txt`
  // static stageAllUntracked({required Repository repo, required List<String> pathspec}) {
  //   final index = repo.index;
  //   // index.add(filePath);
  //   index.addAll(pathspec);
  //   index.write();
  //   // index.removeDirectory('/');
  //   stdout.writeln('\nStaged previously untracked file $pathspec');
  // }
  // /// Stage modified file.
  // ///
  // /// Similar to `git add file.txt`
  // static stageModified({required Repository repo, required String filePath}) {
  //   final index = repo.index;
  //   index.updateAll([filePath]);
  //   index.write();
  //   stdout.writeln('\nChanges to $filePath were staged');
  // }
  //

  // 修改文件
  static modifiedFiles({required Repository repo, required List<String> filePaths}) {
    final index = repo.index;
    index.updateAll(filePaths);
    index.write();
    stdout.writeln('\nChanges to $filePaths were staged');
  }
  // 添加
  static addFiles({required Repository repo, required List<String> filePaths}) {
    final index = repo.index;
    index.addAll(filePaths);
    index.write();
    stdout.writeln('\nStaged previously untracked file $filePaths');
  }
  // 删除
  static removeFiles({required Repository repo, required List<String> filePaths}) {
    // File(path.join(repo.workdir, filePath)).deleteSync();
    repo.index.updateAll(filePaths);
    stdout.writeln('\nrm $filePaths');
  }

  // 暂存变更
  static stagingChanges(Repository repo, Map<String,List<String>> changes){
    List<String> newList = changes['new'] ?? [];
    List<String> modifiedList = changes['modified'] ?? [];
    List<String> deletedList = changes['deleted'] ?? [];
    List<String> renamedList = changes['renamed'] ?? [];
    if(newList.isNotEmpty){ addFiles(repo: repo, filePaths: newList); }
    if(modifiedList.isNotEmpty){ modifiedFiles(repo: repo, filePaths: newList); }
    if(deletedList.isNotEmpty){ removeFiles(repo: repo, filePaths: newList); }
    if(renamedList.isNotEmpty){ modifiedFiles(repo: repo, filePaths: newList); }
  }

  /// Check repository status.
  ///
  /// Similar to `git status`
  static Map<String,List<String>>? repoStatus(Repository repo) {
    print(repo.status);
    stdout.writeln('\nChanges to be committed:');
    Map<String,List<String>> changeMap = {};
    List<String> newFile = [];
    List<String> modifiedFile = [];
    List<String> deletedFile = [];
    List<String> renamedFile = [];
    for (final file in repo.status.entries) {
      if (file.value.contains(GitStatus.indexNew) || file.value.contains(GitStatus.wtNew)) { // 新增
        stdout.writeln('\t new file: \t${file.key}');
        newFile.add(file.key);
      }
      if (file.value.contains(GitStatus.indexModified) || file.value.contains(GitStatus.wtModified)) { // 修改
        stdout.writeln('\t modified: \t${file.key}');
        modifiedFile.add(file.key);
      }
      if (file.value.contains(GitStatus.indexDeleted) || file.value.contains(GitStatus.wtDeleted)){ // 删除
        stdout.writeln('\t deleted: \t${file.key}');
        deletedFile.add(file.key);
      }
      if (file.value.contains(GitStatus.indexRenamed) || file.value.contains(GitStatus.wtRenamed)){ // 重命名
        stdout.writeln('\t renamed: \t${file.key}');
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
  /// Commit changes.
  ///
  /// Similar to `git commit -m "initial commit"`
  static commitChanges({required Repository repo, String? msg, bool isRoot = false,required String gitCommitConfigDirectoryPath,required String repoKey}) {
    var userInfo = Global.getUserInfo(repoKey: repoKey, configPath: gitCommitConfigDirectoryPath);
    var signature = Signature.create(name: userInfo['userName'] ?? 'Planting', email: userInfo['email'] ?? 'email@email.com');
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

  /// View commit history.
  ///
  /// Similar to `git log`
  static viewHistory(Repository repo) {
    final commits = repo.log(oid: repo.head.target);
    for (final commit in commits) {
      stdout.writeln('\ncommit ${commit.oid.sha}');
      stdout.writeln('Author: ${commit.author.name} <${commit.author.email}>');
      stdout.writeln('Date:   ${DateTime.fromMillisecondsSinceEpoch(commit.time * 1000)} ${commit.timeOffset}',);
      stdout.writeln('\n\t${commit.message}');
    }
  }

  /// View a particular commit.
  ///
  /// Similar to `git show aaf8f1e`
  static viewCommit(Repository repo) {
    final commit = Commit.lookup(repo: repo, oid: repo.head.target);

    stdout.writeln('\ncommit ${commit.oid.sha}');
    stdout.writeln('Author: ${commit.author.name} <${commit.author.email}>');
    stdout.writeln(
      'Date:   ${DateTime.fromMillisecondsSinceEpoch(commit.time * 1000)} '
          '${commit.timeOffset}',
    );
    stdout.writeln('\n\t${commit.message}');

    final diff = Diff.treeToTree(
      repo: repo,
      oldTree: null,
      newTree: commit.tree,
    );
    stdout.writeln('\n${diff.patch}');
  }

}