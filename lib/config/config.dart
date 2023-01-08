
class Config{
  static String  feedbackEmail = 'knotreport@gmail.com';
  /// 国内安卓
  static bool isMainland = true;  // 安卓免费,只支持中文
  static bool isGooglePlay = false;  // 国内安卓免费
  // static bool isGooglePlay = true;

  static String androidPayBuglyId = 'ed44e3b8cc';
  static String androidMainlandBuglyId = 'bf350a70f3';
  static String get androidBuglyId => isGooglePlay ? androidMainlandBuglyId : androidPayBuglyId;
  static String iOSBuglyId = '9b5368e030';

  /// 通用版本
  static String iosSandboxVerifyReceiptUrl = 'https://sandbox.itunes.apple.com/verifyReceipt';
  static String iosVerifyReceiptUrl = 'https://buy.itunes.apple.com/verifyReceipt';
  static String iosVerifyReceiptPassword = 'a0256650b6464220bb1a3d3c36539eb8';

  static String githubSecret = '141d3d8f2f03b4c0c238fcad1930f0d03bec72bc';
  static String githubClientID = '617899b3062e0c6840ab';

  static String gitlabSecret = '18e93b53bbafc2aa7380a6387f7a8e5ebe3778a2a6fed2fa5a5158421c566d6d';
  static String gitlabClientID = '47d4412a365158da1e43fc5fdefc96bdb23238f4d260e0e119ead21bd821df31';

  static String  authRedirectUrl = 'treediary://authed';



}