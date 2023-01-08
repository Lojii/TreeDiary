import 'githost.dart';

class GitHostExceptionCatcher implements GitHost {
  final GitHost _;
  GitHostExceptionCatcher(GitHost host) : _ = host;
  @override
  void uniLinkListen(OAuthCallback oAuthCallback) => _.uniLinkListen(oAuthCallback);
  @override
  void uniLinkCancel() => _.uniLinkCancel();
  @override
  Future<void> launchOAuthScreen() => _.launchOAuthScreen();
  @override
  Future<GitHostRes<UserInfo>> getUserInfo() => _.getUserInfo();
  @override
  Future<GitHostRes<List<GitHostRepo>>> listRepos() => _.listRepos();
  @override
  Future<GitHostRes<GitHostRepo?>> createRepo(String name, String description) => _.createRepo(name, description);
  @override
  Future<GitHostRes<GitHostRepo?>> getRepo(String name) => _.getRepo(name);
  @override
  Future<GitHostRes<void>> addDeployKey(String sshPublicKey, String repoFullName) => _.addDeployKey(sshPublicKey, repoFullName);
}
