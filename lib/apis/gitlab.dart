
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';
import 'package:universal_io/io.dart' show HttpHeaders;
import 'package:url_launcher/url_launcher.dart';

import '../config/config.dart';
import 'githost.dart';

import 'package:crypto/crypto.dart';

class GitLab implements GitHost {
  // static const _clientID = "2a04790be9a56d989766c327ea0db23c00d6a71f5a0cd9b67700a7f0b3ee7a95";
  // static const _clientSecret = "c6665fb9d9e093ac324381f10f8e9a1b174f3cbd50ef1aeb56f75618e8363e9b";
  // static const _accessCodeKey = "GitLab_accessCodeKey";
  var _stateOAuth = "";
  var _codeVerifier = '';
  var _codeChallenge = '';
  final _codeChallengeMethod = 'S256';
  // final _redirectUri = 'planting://authed';

  String _accessCode = '';

  StreamSubscription? _sub;

  @override
  void uniLinkListen(OAuthCallback oAuthCallback){
    // planting://authed?code=947ed56c6006995f4708
    final pkcePair = PkcePair.generate();
    _codeVerifier = pkcePair.codeVerifier;
    _codeChallenge = pkcePair.codeChallenge;
    if(_sub != null){ return; }
    _sub = uriLinkStream.listen((Uri? uri) async {
      if(uri == null){ return; }
      if(!uri.toString().contains('authed')){ return; }
      if (kDebugMode) { print(uri); }

      var url = uri.toString();
      var queryParamters = url.split('?').last;
      if (kDebugMode) { print(queryParamters); }
      var map = Uri.splitQueryString(queryParamters);
      var state = map['state'];
      var code = map['code'] ?? '';
      if (state != _stateOAuth || code.isEmpty) {
        if (kDebugMode) { print("GitLab: OAuth State incorrect");}
        if (kDebugMode) { print("Required State: " + _stateOAuth);}
        if (kDebugMode) { print("Actual State: " + state!);}
        oAuthCallback(GitHostException.OAuthFailed);
        return;
      }
      await EasyLoading.show();
      var res = await _getAccessCode(code);
      await EasyLoading.dismiss();
      if(res.exception != null){
        oAuthCallback(res.exception);
        return;
      }
      if (res.data != null && res.data!.isEmpty) {
        oAuthCallback(GitHostException.OAuthFailed);
        return;
      }
      if (kDebugMode) { print(res.data); }
      _accessCode = res.data!;
      // await GitHost.saveAccessCode(_accessCodeKey, res.data!);
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
    /*
    parameters = 'client_id=APP_ID&client_secret=APP_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI'
    RestClient.post 'https://gitlab.example.com/oauth/token', parameters
    */
    var url = Uri.parse("https://gitlab.com/oauth/token");
    var headers = { HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded", };
    var body = 'client_id=${Config.gitlabClientID}&client_secret=${Config.gitlabSecret}&code=$authCode&grant_type=authorization_code&code_verifier=$_codeVerifier&redirect_uri=${Config.authRedirectUrl}';
    try{
      var response = await http.post(url, body: body, headers: headers);
      /*
      {
      "access_token":"60fdef8b53754b9226de83a232ae18fb0c2161fa0feee739c00c6af84d151e23",
      "token_type":"Bearer",
      "expires_in":7200,
      "refresh_token":"cdcdec71cd112364cd4da5ddcc907bd04520dd857928d3d5608e24000d2636d9",
      "scope":"api",
      "created_at":1658925670
      }
      */
      if (response.statusCode != 200) {
        if (kDebugMode) { print("GitLab getAccessCode: Invalid response " + response.statusCode.toString() + ": " + response.body);}
        return GitHostRes(exception: GitHostException.OAuthFailed);
      }
      if (kDebugMode) { print("GitLabResponse: " + response.body);}
      var map = jsonDecode(response.body);
      return GitHostRes(data: map["access_token"] ?? "");
    }catch(e){
      if (kDebugMode) { print('GitLab getAccessCode error:$e');}
      return GitHostRes(exception: GitHostException.OAuthFailed);
    }
  }

  @override
  Future<void> launchOAuthScreen() async {
    _stateOAuth = DateTime.now().microsecondsSinceEpoch.toString();//_randomString(10);
    var url = "https://gitlab.com/oauth/authorize?client_id=${Config.gitlabClientID}&response_type=code&state=$_stateOAuth&code_challenge=$_codeChallenge&code_challenge_method=$_codeChallengeMethod&redirect_uri=${Config.authRedirectUrl}";
    if (kDebugMode) { print(url); }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication,);
  }

  @override
  Future<GitHostRes<List<GitHostRepo>>> listRepos() async {
    // var userInfo = await getUserInfo();
    // print(userInfo.data);
    // await createSelfAccessCode();
    // print('-------');

    // var _accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }

    try{

      var url = Uri.parse("https://gitlab.com/api/v4/projects?simple=true&membership=true&order_by=last_activity_at&access_token=$_accessCode");
      if (kDebugMode) { print(toCurlCommand(url, {}));}

      var response = await http.get(url);
      if (response.statusCode != 200) {
        if (kDebugMode) { print("GitLab listRepos: Invalid response " + response.statusCode.toString() + ": " + response.body);}
        if(response.statusCode == 401){ // 令牌过期
          var ex = GitHostException.AccessCodeExpired;
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
      return GitHostRes(data: repos);
    }catch(e){
      var ex = GitHostException(e.toString());
      return GitHostRes(exception: ex);
    }
  }

  @override
  Future<GitHostRes<GitHostRepo>> createRepo(String name, String description) async {

    // var _accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }
    try{
      var url = Uri.parse("https://gitlab.com/api/v4/projects?access_token=$_accessCode");
      var data = <String, dynamic>{'name': name, 'description': description, 'visibility': 'private',};
      if (kDebugMode) {print(data);}
      var headers = {HttpHeaders.contentTypeHeader: "application/json",};
      var response = await http.post(url, headers: headers, body: json.encode(data));
      if (response.statusCode != 201) {
        if (kDebugMode) { print("GitLab createRepo: Invalid response " + response.statusCode.toString() + ": " + response.body);}

        if (response.statusCode == 400) {
          if (response.body.contains("has already been taken")) {
            var ex = GitHostException.RepoExists;
            return GitHostRes(exception: ex);
          }
        }
        if(response.statusCode == 401){ // 令牌过期
          var ex = GitHostException.AccessCodeExpired;
          return GitHostRes(exception: ex);
        }

        var ex = GitHostException.CreateRepoFailed;
        return GitHostRes(exception: ex);
      }

      if (kDebugMode) { print("GitLab createRepo: " + response.body);}
      Map<String, dynamic> map = json.decode(response.body);
      return GitHostRes(data: repoFromJson(map));
    }catch(e){
      var ex = GitHostException(e.toString());
      return GitHostRes(exception: ex);
    }
  }

  @override
  Future<GitHostRes<GitHostRepo?>> getRepo(String name) async {
    // var _accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }

    try{
      var userInfoR = await getUserInfo();
      if(userInfoR.exception != null || userInfoR.data == null){
        return GitHostRes(exception: userInfoR.exception);
      }
      var userInfo = userInfoR.data;
      var repo = (userInfo?.username ?? '') + '%2F' + name;
      var url = Uri.parse("https://gitlab.com/api/v4/projects/$repo?access_token=$_accessCode");

      var response = await http.get(url);
      if (response.statusCode != 200) {
        if (kDebugMode) { print("GitLab getRepo: Invalid response " + response.statusCode.toString() + ": " + response.body);}
        if(response.statusCode == 401){ // 令牌过期
          var ex = GitHostException.AccessCodeExpired;
          return GitHostRes(exception: ex);
        }
        var ex = GitHostException.GetRepoFailed;
        return GitHostRes(exception: ex);
      }

      if (kDebugMode) { print("GitLab getRepo: " + response.body);}
      Map<String, dynamic> map = json.decode(response.body);
      return GitHostRes(data: repoFromJson(map));
    }catch(e){
      var ex = GitHostException(e.toString());
      return GitHostRes(exception: ex);
    }
  }

  @override
  Future<GitHostRes> addDeployKey(String sshPublicKey, String repo) async {
    // var _accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }
    try{
      repo = repo.replaceAll('/', '%2F');
      var url = Uri.parse("https://gitlab.com/api/v4/projects/$repo/deploy_keys?access_token=$_accessCode");

      var now = DateTime.now();
      var title = "Planting${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}${now.second.toString().padLeft(2,'0')}";
      var data = {'title': title, 'key': sshPublicKey, 'can_push': true,};

      var headers = {HttpHeaders.contentTypeHeader: "application/json",};

      var response = await http.post(url, headers: headers, body: json.encode(data));
      if (response.statusCode != 201) {
        if (kDebugMode) { print("GitLab addDeployKey: Invalid response " + response.statusCode.toString() + ": " + response.body);}
        if(response.statusCode == 401){ // 令牌过期
          var ex = GitHostException.AccessCodeExpired;
          return GitHostRes(exception: ex);
        }
        var ex = GitHostException.DeployKeyFailed;
        return GitHostRes(exception: ex);
      }

      if (kDebugMode) { print("GitLab addDeployKey: " + response.body);}
      return GitHostRes();
    }catch(e){
      var ex = GitHostException(e.toString());
      return GitHostRes(exception: ex);
    }
  }

  static GitHostRepo repoFromJson(Map<String, dynamic> parsedJson) {
    DateTime? updatedAt;
    try {
      updatedAt = DateTime.parse(parsedJson['last_activity_at'].toString());
    } catch (e, st) {
      if (kDebugMode) { print("GitLab repoFromJson:$e - $st");}
    }
    var licenseMap = parsedJson['license'];

    List<String> tags = [];
    var tagList = parsedJson['tag_list'];
    if (tagList is List) {
      tags = tagList.map((e) => e.toString()).toList();
    }

    var fullName = parsedJson['path_with_namespace'].toString();
    var namespace = parsedJson['namespace'];
    var username = "";
    if (namespace != null) {
      username = (namespace as Map)["path"];
    } else {
      username = fullName.split('/').first;
    }

    return GitHostRepo(
      name: parsedJson["name"],
      username: username,
      fullName: fullName,
      cloneUrl: parsedJson['ssh_url_to_repo'],
      updatedAt: updatedAt,
      description: parsedJson['description'] ?? "",
      stars: parsedJson['star_count'],
      forks: parsedJson['forks_count'],
      issues: parsedJson['open_issues_count'],
      language: parsedJson['language'],
      private: parsedJson['visibility'] == 'private',
      tags: tags,
      license: licenseMap != null ? licenseMap['nickname'] : null,
    );
  }

  @override
  Future<GitHostRes<UserInfo>> getUserInfo() async {
    // var _accessCode = GitHost.accessCode(_accessCodeKey);
    if (_accessCode.isEmpty) {
      var ex = GitHostException.MissingAccessCode;
      return GitHostRes(exception: ex);
    }
    try{
      var url = Uri.parse("https://gitlab.com/api/v4/user?access_token=$_accessCode");
      var response = await http.get(url);
      if (response.statusCode != 200) {
        if (kDebugMode) { print("GitLab getUserInfo: Invalid response " + response.statusCode.toString() + ": " + response.body);}
        if(response.statusCode == 401){ // 令牌过期
          var ex = GitHostException.AccessCodeExpired;
          return GitHostRes(exception: ex);
        }
        var ex = GitHostException.HttpResponseFail;
        return GitHostRes(exception: ex);
      }

      Map<String, dynamic>? map = jsonDecode(response.body);
      if (kDebugMode) {print(response.body);}
      if (map == null || map.isEmpty) {
        if (kDebugMode) { print("GitLab getUserInfo: jsonDecode Failed " + response.statusCode.toString() + ": " + response.body);}
        var ex = GitHostException.JsonDecodingFail;
        return GitHostRes(exception: ex);
      }
      return GitHostRes(data: UserInfo(name: map['name'], email: map['email'], username: map['username'],));
    }catch(e){
      var ex = GitHostException(e.toString());
      return GitHostRes(exception: ex);
    }
  }
}

/// A pair of ([codeVerifier], [codeChallenge]) that can be used with PKCE
/// (Proof Key for Code Exchange).
class PkcePair {
  /// The code verifier.
  final String codeVerifier;

  /// The code challenge, computed as base64Url(sha256([codeVerifier])) with
  /// padding removed as per the spec.
  final String codeChallenge;

  const PkcePair._(this.codeVerifier, this.codeChallenge);

  /// Generates a [PkcePair].
  ///
  /// [length] is the length used to generate the [codeVerifier]. It must be
  /// between 32 and 96, inclusive, which corresponds to a [codeVerifier] of
  /// length between 43 and 128, inclusive. The spec recommends a length of 32.
  factory PkcePair.generate({int length = 32}) {
    if (length < 32 || length > 96) {
      throw ArgumentError.value(length, 'length', 'The length must be between 32 and 96, inclusive.');
    }

    final random = Random.secure();
    final verifier = base64UrlEncode(List.generate(length, (_) => random.nextInt(256))).split('=')[0];
    final challenge = base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes).split('=')[0];
    return PkcePair._(verifier, challenge);
  }
}