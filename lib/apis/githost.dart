import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:treediary/config/storage_manager.dart';

typedef OAuthCallback = void Function(GitHostException?);

abstract class GitHost {
  void uniLinkListen(OAuthCallback oAuthCallback);
  void uniLinkCancel();

  Future<void> launchOAuthScreen();

  Future<GitHostRes<UserInfo>> getUserInfo();
  Future<GitHostRes<List<GitHostRepo>>> listRepos();
  Future<GitHostRes<GitHostRepo?>> createRepo(String name, String description);
  Future<GitHostRes<GitHostRepo?>> getRepo(String name);
  Future<GitHostRes<void>> addDeployKey(String sshPublicKey, String repoFullName);

  // static saveAccessCode(String key, String value) async{
  //   await StorageManager.sharedPreferences.setString(key, value);
  // }
  // static String accessCode(String key) {
  //   return StorageManager.sharedPreferences.getString(key) ?? '';
  // }
}

class GitHostRes<T>{
  final T? data;
  final GitHostException? exception;
  GitHostRes({this.data,this.exception});
}

class UserInfo {
  final String name;
  final String email;
  final String username;

  UserInfo({
    required this.name,
    required this.email,
    required this.username,
  });

  @override
  String toString() {
    return kDebugMode
        ? 'UserInfo{name: "$name", email: "$email", username: "$username"}'
        : 'UserInfo{name: ${name.isNotEmpty}, email: ${email.isNotEmpty}, username: ${username.isNotEmpty}}';
  }
}

class GitHostRepo {
  final String name;
  final String username;
  final String fullName;
  final String description;

  final String cloneUrl;
  final DateTime? updatedAt;

  final bool? private;
  final int? stars;
  final int? forks;
  final String? language;
  final int? issues;
  final String? license;

  final List<String> tags;

  GitHostRepo({
    required this.name,
    required this.username,
    required this.fullName,
    required this.description,
    required this.cloneUrl,
    required this.updatedAt,
    required this.private,
    required this.stars,
    required this.forks,
    required this.language,
    required this.issues,
    required this.tags,
    required this.license,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'username': username,
        'fullName': fullName,
        'description': description,
        'cloneUrl': cloneUrl,
        'updatedAt': updatedAt,
        'private': private,
        'stars': stars,
        'forks': forks,
        'language': language,
        'issues': issues,
        'tags': tags,
        'license': license,
      };

  @override
  String toString() => toJson().toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHostRepo &&
          runtimeType == other.runtimeType &&
          _mapEquals(toJson(), other.toJson());
  @override
  int get hashCode => toJson().hashCode;
}

final _mapEquals = (const MapEquality()).equals;

class GitHostException implements Exception {
  static const OAuthFailed = GitHostException("OAuthFailed");
  static const MissingAccessCode = GitHostException("MissingAccessCode");
  static const RepoExists = GitHostException("RepoExists");
  static const CreateRepoFailed = GitHostException("CreateRepoFailed");
  static const DeployKeyFailed = GitHostException("DeployKeyFailed");
  static const GetRepoFailed = GitHostException("GetRepoFailed");
  static const HttpResponseFail = GitHostException("HttpResponseFail");
  static const JsonDecodingFail = GitHostException("JsonDecodingFail");
  static const Timeout = GitHostException("Timeout");
  static const UnknownError = GitHostException("UnknownError");
  static const AccessCodeExpired = GitHostException("AccessCodeExpired");// 权限过期

  final String cause;
  const GitHostException(this.cause);

  @override
  bool operator == (Object other) => other is GitHostException && other.cause == cause;

  @override
  String toString() {
    return "GitHostException: " + cause;
  }

  @override
  int get hashCode => cause.hashCode;
}

String toCurlCommand(Uri url, Map<String, String> headers) {
  var headersStr = "";
  headers.forEach((key, value) {
    headersStr += ' -H "$key: $value" ';
  });

  return "curl -X GET '$url' $headersStr";
}
