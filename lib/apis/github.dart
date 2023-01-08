
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:http/http.dart' as http;
import 'package:universal_io/io.dart' show HttpHeaders;
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import '../config/config.dart';
import 'githost.dart';

class GitHub implements GitHost {
  // static const _clientID = "796e66ad750a35dece44";
  // static const _clientSecret = "e4f3973ae0864c92a0ef057af6283f8073c7f457";

  String _accessCode = '';

  StreamSubscription? _sub;

  @override
  void uniLinkListen(OAuthCallback oAuthCallback){
    // planting://authed?code=947ed56c6006995f4708
    if(_sub != null){ return; }
    _sub = uriLinkStream.listen((Uri? uri) async {
      if(uri == null){ return; }
      if(!uri.toString().contains('authed')){ return; }
      if (kDebugMode) { print(uri); }
      var authCode = uri.queryParameters['code'] ?? "";
      if (authCode.isEmpty) {
        oAuthCallback(GitHostException.OAuthFailed);
        return;
      }
      if (kDebugMode) { print(authCode); }
      await EasyLoading.show();
      var accessCode = await _getAccessCode(authCode);
      await EasyLoading.dismiss();
      if(accessCode.exception != null){
        oAuthCallback(accessCode.exception);
        return;
      }
      if (accessCode.data != null && accessCode.data!.isEmpty) {
        oAuthCallback(GitHostException.OAuthFailed);
        return;
      }
      if (kDebugMode) { print(accessCode.data);}
      _accessCode = accessCode.data!;
      // await GitHost.saveAccessCode(_accessCodeKey, accessCode.data!);
      oAuthCallback(null);
    }, onError: (err) {
      if (kDebugMode) { print(err);}
      oAuthCallback(GitHostException.OAuthFailed);
    });
  }

  @override
  void uniLinkCancel(){
    _sub?.cancel();
    _sub = null;
  }

  Future<GitHostRes<String>> _getAccessCode(String authCode) async {
    var url = Uri.parse("https://github.com/login/oauth/access_token?client_id=${Config.githubClientID}&client_secret=${Config.githubSecret}&code=$authCode");
    try{
      var response = await http.post(url);
      if (response.statusCode != 200) {
        if (kDebugMode) { print("Github getAccessCode: Invalid response " + response.statusCode.toString() + ": " + response.body);}
        return GitHostRes(exception: GitHostException.OAuthFailed);
      }
      if (kDebugMode) { print("GithubResponse: " + response.body);}
      var map = Uri.splitQueryString(response.body);
      return GitHostRes(data: map["access_token"] ?? "");
    }catch(e){
      if (kDebugMode) { print('Github getAccessCode error:$e');}
      return GitHostRes(exception: GitHostException.OAuthFailed);
    }
  }

  @override
  Future<void> launchOAuthScreen() async {
    var url = "https://github.com/login/oauth/authorize?client_id=${Config.githubClientID}&state=${DateTime.now().millisecondsSinceEpoch}&scope=repo";
    if (kDebugMode) { print(url);}
    var _ = await launchUrl( Uri.parse(url),  mode: LaunchMode.externalApplication, );
  }

  @override
  Future<GitHostRes<List<GitHostRepo>>> listRepos() async {
    // var accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }

    try{
      var url = Uri.parse("https://api.github.com/user/repos?page=1&per_page=100");
      var headers = { HttpHeaders.authorizationHeader: _buildAuthHeader(), };
      if (kDebugMode) { print(toCurlCommand(url, headers)); }
      var response = await http.get(url, headers: headers);
      if (response.statusCode != 200) {
        if (kDebugMode) { print("Github listRepos: Invalid response " + response.statusCode.toString() + ": " + response.body); }
        if(response.statusCode == 403 || response.statusCode == 401){ // 没有权限,需要重新授权
          var ex = GitHostException.AccessCodeExpired; // 返回access过期
          return GitHostRes(exception: ex);
        }
        var ex = GitHostException.HttpResponseFail;
        return GitHostRes(exception: ex);
      }

      List<dynamic> list = jsonDecode(response.body);
      var repos = <GitHostRepo>[];
      for (var d in list) {
        var map = Map<String, dynamic>.from(d);
        var repo = repoFromJson(map);
        repos.add(repo);
      }
      return GitHostRes<List<GitHostRepo>>(data: repos);
    }catch(e){
      if (kDebugMode) { print(e);}
      return GitHostRes(exception: GitHostException(e.toString()));
    }
  }

  @override
  Future<GitHostRes<GitHostRepo>> createRepo(String name, String description) async {
    // var accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }

    try{
      var url = Uri.parse("https://api.github.com/user/repos");
      var data = <String, dynamic>{ 'name': name, 'description':description, 'private': true, };

      var headers = {
        HttpHeaders.contentTypeHeader: "application/json",
        HttpHeaders.authorizationHeader: _buildAuthHeader(),
      };

      var response = await http.post(url, headers: headers, body: json.encode(data));
      if (response.statusCode != 201) {
        if (kDebugMode) { print("Github createRepo: Invalid response " + response.statusCode.toString() + ": " + response.body); }
        if(response.statusCode == 403 || response.statusCode == 401){ // 没有权限,需要重新授权
          var ex = GitHostException.AccessCodeExpired; // 返回access过期
          return GitHostRes(exception: ex);
        }
        if (response.statusCode == 422) {
          if (response.body.contains("name already exists")) {
            var ex = GitHostException.RepoExists;
            return GitHostRes(exception: ex);
          }
        }
        var ex = GitHostException.CreateRepoFailed;
        return GitHostRes(exception: ex);
      }

      if (kDebugMode) { print("GitHub createRepo: " + response.body);}
      Map<String, dynamic> map = json.decode(response.body);
      return GitHostRes(data: repoFromJson(map));
    }catch(e){
      if (kDebugMode) { print(e); }
      return GitHostRes(exception: GitHostException(e.toString()));
    }
  }

  @override
  Future<GitHostRes<GitHostRepo?>> getRepo(String name) async {
    // var accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }

    var userInfoR = await getUserInfo();
    if(userInfoR.exception != null || userInfoR.data == null){
      return GitHostRes(exception: userInfoR.exception);
    }
    var userInfo = userInfoR.data;
    var owner = userInfo!.username;
    var url = Uri.parse("https://api.github.com/repos/$owner/$name");

    var headers = { HttpHeaders.authorizationHeader: _buildAuthHeader(), };

    var response = await http.get(url, headers: headers);
    if (response.statusCode != 200) {
      if (kDebugMode) { print("Github getRepo: Invalid response " + response.statusCode.toString() + ": " + response.body);}
      if(response.statusCode == 403 || response.statusCode == 401){ // 没有权限,需要重新授权
        var ex = GitHostException.AccessCodeExpired; // 返回access过期
        return GitHostRes(exception: ex);
      }
      return GitHostRes(exception: GitHostException.GetRepoFailed);
    }

    if (kDebugMode) { print("GitHub getRepo: " + response.body);}
    try {
      Map<String, dynamic> map = json.decode(response.body);
      return GitHostRes(data: repoFromJson(map));
    } catch (ex, st) {
      if (kDebugMode) { print("$ex - $st");}
      return GitHostRes(exception: GitHostException("$ex - $st"));
    }
  }

  @override
  Future<GitHostRes> addDeployKey(String sshPublicKey, String repo) async {
    // var accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }
    try{
      var url = Uri.parse("https://api.github.com/repos/$repo/keys");
      var now = DateTime.now();
      var data = <String, dynamic>{'title': "Planting${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}${now.second.toString().padLeft(2,'0')}", 'key': sshPublicKey, 'read_only': false,};
      var headers = { HttpHeaders.contentTypeHeader: "application/json",  HttpHeaders.authorizationHeader: _buildAuthHeader(), };

      var response = await http.post(url, headers: headers, body: json.encode(data));
      if (response.statusCode != 201) {
        if (kDebugMode) { print("Github addDeployKey: Invalid response " + response.statusCode.toString() + ": " + response.body);}
        if(response.statusCode == 403 || response.statusCode == 401){ // 没有权限,需要重新授权
          var ex = GitHostException.AccessCodeExpired; // 返回access过期
          return GitHostRes(exception: ex);
        }
        var ex = GitHostException.DeployKeyFailed;
        return GitHostRes(exception: ex);
      }
      if (kDebugMode) { print("GitHub addDeployKey: " + response.body);}
      return GitHostRes();
    }catch(e){
      if (kDebugMode) { print(e);}
      return GitHostRes(exception: GitHostException(e.toString()));
    }
  }

  static GitHostRepo repoFromJson(Map<String, dynamic> parsedJson) {
    DateTime? updatedAt;
    try {
      updatedAt = DateTime.parse(parsedJson['updated_at'].toString());
    } catch (e, st) {
      if (kDebugMode) { print("github repoFromJson:$e - $st");}
    }
    var licenseMap = parsedJson['license'];
    var fullName = parsedJson['full_name'].toString();

    var owner = parsedJson['owner'];
    var username = "";
    if (owner != null) {
      username = (owner as Map)["login"];
    } else {
      username = fullName.split('/').first;
    }

    /*
    print("");
    parsedJson.forEach((key, value) => print(" $key: $value"));
    print("");
    */

    return GitHostRepo(
      name: parsedJson['name'],
      username: username,
      fullName: fullName,
      cloneUrl: parsedJson['ssh_url'],
      updatedAt: updatedAt,
      description: parsedJson['description'] ?? "",
      stars: parsedJson['stargazers_count'],
      forks: parsedJson['forks_count'],
      issues: parsedJson['open_issues_count'],
      language: parsedJson['language'] ?? "",
      private: parsedJson['private'],
      // tags: parsedJson['topics'] ?? [],
      tags: [],
      license: licenseMap != null ? licenseMap['spdx_id'] : null,
    );
  }

  @override
  Future<GitHostRes<UserInfo>> getUserInfo() async {
    // var accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }
    try {
      var url = Uri.parse("https://api.github.com/user");
      var headers = { HttpHeaders.authorizationHeader: _buildAuthHeader(), };
      var response = await http.get(url, headers: headers);
      if (response.statusCode != 200) {
        if (kDebugMode) { print("Github getUserInfo: Invalid response " + response.statusCode.toString() + ": " + response.body);}
        if(response.statusCode == 403 || response.statusCode == 401){ // 没有权限,需要重新授权
          var ex = GitHostException.AccessCodeExpired; // 返回access过期
          return GitHostRes(exception: ex);
        }
        var ex = GitHostException.HttpResponseFail;
        return GitHostRes(exception: ex);
      }

      Map<String, dynamic>? map = jsonDecode(response.body);
      if (map == null || map.isEmpty) {
        if (kDebugMode) { print("Github getUserInfo: jsonDecode Failed " + response.statusCode.toString() + ": " + response.body);}
        var ex = GitHostException.JsonDecodingFail;
        return GitHostRes(exception: ex);
      }

      if (!map.containsKey('name')) { return GitHostRes(exception: const GitHostException('GitHub UserInfo missing name')); }
      if (!map.containsKey('email')) { return GitHostRes(exception: const GitHostException('GitHub UserInfo missing email')); }
      if (!map.containsKey('login')) { return GitHostRes(exception: const GitHostException('GitHub UserInfo missing login')); }
      var name = "";
      var email = "";
      var login = "";
      if (map['name'] is String) { name = map['name']; }
      if (map['email'] is String) { email = map['email']; }
      if (map['login'] is String) { login = map['login']; }
      return GitHostRes(data: UserInfo(name: name, email: email, username: login));
    } catch (ex, st) {
      if (kDebugMode) { print("GitHub user Info error:$ex - $st");}
      return GitHostRes(exception: GitHostException("$ex - $st"));
    }

  }

  String _buildAuthHeader() {
    return 'token $_accessCode';
  }
}
