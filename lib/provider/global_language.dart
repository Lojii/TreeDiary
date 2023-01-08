
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert' as convert;
import 'package:treediary/provider/setting_model.dart';
import 'package:provider/provider.dart';

class L{
  // 附加信息
  String? exPath; // 语言包路径（唯一） // auto:跟随系统
  String? exName; // 语言名称：简体中文、English、...
  String? exAuthor;
  String? exVersion;
  List<String>? exCodes;
  String? exDesc;
  String? exHomePage; // 主页
  String? exUpdateUrl; // 更新地址

  String app_name = "TreeDiary";
  // 初始页面
  String recover = "恢复";
  String create = "创建";
  String clone_to_local = "从远程备份仓库克隆到本地";
  String create_a_new_repository = "在本地新建日记仓库";
  // 首页
  String time_to_start = "时间起点";
  String enter_the_search_content = "输入搜索内容";
  String ascending = "升序";
  String descending = "降序";
  String delete = "删除";
  String share = "分享";
  String cancel = "取消";
  // 首页菜单
  String edit = "编辑";
  String add = "新增";
  String synchronization_is_not_set = "未设置同步仓库";
  // 简单编辑
  String write_something = "写点什么";
  String save = "保存";
  String add_location_information = "添加位置信息";
  String add_tags = "添加标签";
  String select_from_album = "从相册选取";
  String taking_photos = "拍照";
  String select_repository = "选择仓库";
  String you_need_to_choose_at_least_one = "至少需要选择一个";
  String enter_the_label = "输入标签后点击右侧按钮添加";
  String add_tag = "添加";
  String added_tags = "已添加";
  String recently_tags = "最近使用";
  String all_tags = "所有标签";
  String sample_tags = "标签示例";

  // 日记本设置页
  String repository_name = "日记本名称";
  String user_info = "用户信息";
  String remote_repository = "远程同步仓库";
  String local_repository_delete = "本地仓库删除";
  String rebuild_index = "重建索引";
  String enter_a_name = "输入名称";
  String global_onfiguration = "使用全局配置";
  String no_synchronization = "未设置同步仓库";
  String are_you_sure = "确定删除？";

  // 设置页
  String setting = "设置";
  String global_user_info = "全局用户信息";
  String use_skills = "使用技巧";
  String safe_setting = "安全设置";
  String display_and_language = "外观与语言设置";
  String pro = "购买订阅";
  String score = "评分";
  String share_the_app = "推荐给朋友";
  String about = "关于我们";

  // 用户信息页
  String user_name = "用户名";
  String user_email = "邮箱";
  String user_info_tip = "此用户信息仅用于Git仓库提交，不同的仓库可在仓库设置页设置使用不同的用户信息";
  String enter_user_name = "输入用户名";
  String enter_user_email = "输入邮箱";
  String enter_email_tip = "请输入正确的邮箱";

  // 关于页面

  // 远程仓库列表
  String repositories = "远程仓库列表";
  String sync = "同步";
  String syncing = "同步中";
  String retry = "重试";
  String queue = "排队中";
  String last_sync_time = "上次同步时间";
  String unsynced = "未同步";
  String auto_sync = "是否自动同步";
  String view_logs = "查看日志";
  String copy = "点击复制";
  String set_the_key = "前往设置公钥";
  String cannot_access_the_web = "无法自动跳转对应网页";//Cannot access the corresponding web page
  String delete_remote_tip = "此操作不会删除远程仓库数据";

  // 选择Git服务
  String select_service_provider = "选择Git服务";
  String github = "Github";
  String github_tip = "(推荐)无限云存储空间";
  String gitlab = "Gitlab";
  String gitlab_tip = "www.gitlab.com";
  String custom = "自定义";
  String custom_tip = "自建或者其他Git存储服务商";
  String auto_add = "授权自动添加(推荐)";
  String manually_add = "手动添加";
  // 手动添加页
  String manually_create_empty_1 = "前往%@新建空白仓库，然后复制仓库地址";
  String manually_to_create = "打开网页以新建仓库";
  String manually_input_git_url = "输入Git仓库地址";
  String manually_set_public_key = "配置SSH通讯公钥";
  String manually_regenerating_public_key = "重新生成公钥";
  String manually_copy_and_set_1 = "复制上面的公钥，打开网页，添加到%@。请确认给与读写权限";
  String manually_to_set_public_key_1 = "前往%@设置公钥";
  String manually_done = "完成";
  String manually_empty_tip = "仓库地址不能为空";
  // 请求授权页
  String authorization_request = "请求授权";
  String authorization_request_tip_1 = "自动添加需要您授权当前设备，点击前往%@，登录授权后返回，即可进入下一步操作";
  String authorization_request_button_1 = "前往%@授权页面";
  // 选择或新建仓库页
  String select_or_create = "选择或新建仓库";
  String click_to_create = "点击新建仓库";
  String no_repository = "暂无仓库，请点击上面的按钮新建仓库";
  // clone页
  String cloning = "正在clone数据...";
  String cloning_tip = "请耐心等待，请勿离开该页面";
  String close_log = "收起日志";
  String clone_error = "出错了！";
  String clone_success = "Clone成功!";
  String go_back = "返回";
  // 添加同步仓库页面
  String trying_to_connect = "正在尝试连接，请耐心等待";
  String add_anyway = "仍然添加";
  String add_error = "出错了！";
  String add_success = "连接可用！添加成功!";
  // 日志
  String logs = "日志";
  // 分享页面
  String save_pic = "保存图片";
  String save_markdown = "markdown";
  String copy_content = "复制文本";
  String more_actions = "更多操作";
  String save_success = "保存成功";
  String save_failed = "保存失败";
  String copied = "已复制";
  // 一些提示
  String folder_does_not_exist = "文件夹不存在";
  String updating_the_local_index = "正在更新本地缓存";
  String update_failed = "更新失败";
  // 主题与语言切花页面
  String appearance = "外观";
  String theme_light = "白天";
  String theme_dark = "黑夜";
  String theme_auto = "跟随系统";
  String language = "语言";
  String language_auto = "跟随系统";
  /// // 植树笔记 V1.0// 植树笔记
  String failed_to_create_folder = "文件夹创建失败";
  String add_failure = "添加远程仓库失败";
  String enter_description = "输入描述(选填)";// "Description (optional)"// 输入描述(选填)
  String create_repository = "新建远程存储仓库";//  //Create repository
  String creates_a_new_repository = "该操作将在Git服务器上创建一个新的仓库";// 该操作将在Git服务器上创建一个新的仓库 // This creates a new repository on the Git server
  String the_name_cannot_be_empty = "仓库名不能为空"; // The warehouse name cannot be empty
  String load_repository_failed = "仓库获取失败"; // 仓库获取失败 // Failed to get the repository list
  String confirm = "确定选择"; //  // confirm?
  String failed_to_get_the_repository_list = "获取仓库列表失败";//  // Failed to get the repository list
  String failed_to_get_location = "获取位置信息失败"; // 获取位置信息失败！ Failed to get location information
  String load_failed = "加载失败"; // 加载失败 Load failed
  String git_user_info = "Git用户信息";// Git user Info
  String feedback = "意见反馈"; //  feedback
  String system = "跟随系统";// 跟随系统  system
  String cannot_access = "无法访问";// 无法访问 cannot access
  String file_size = "文件大小:";//   file size
  String modification_time = "修改时间:";//  modification time
  String open_with_another_app = "使用其他应用打开";//   Open with another app
  String no_permission = "没有权限，请前往系统设置开启！";// No permission
  String no_tags = "暂无标签";//   No tags
  String no_diary = "暂无日记";// No diary
  String full_functional = "完整的功能体验";//  Full functional
  String unlimited_diary_creation = "无限创建日记本";// Unlimited diary creation
  String limited_number_of_pictures = "单篇日记添加图片上限增加到20";//   // The maximum number of images added to a single entry has been increased to 20
  String month = "月";//
  String year = "年";//
  String subscribe_to_the_declaration_0 = "订阅可以在到期24小时之前随时取消，订阅高级版即表示你接受我们的";// "Subscriptions can be cancelled at any time up to 24 hours before they expire. Subscribing to Premium means you accept our ";
  String privacy_policy = "隐私政策"; // Privacy Policy
  String subscribe_to_the_declaration_1 = "和";//" and ";
  String user_agreement = "用户协议"; // User Agreement
  String subscribe_to_the_declaration_2 = "。";// ".";
  String restore_purchase = "恢复购买";//  restore
  String operation_cancelled = "操作取消";//  Operation cancelled
  String operation_success = "操作成功";// 操作成功
  String operation_failure = "操作失败";//  operation failure
  String network_error_please_try_again_later = "网络出错，请稍后重试";// Network error, please try again later
  String server_error_please_try_again_later = "服务器出错，请稍后重试";//   Server error, please try again later
  String subscribed = "已订阅";//

  static List<String> allKeys = [
    "app_name",
    "recover","create","clone_to_local","create_a_new_repository",
    "time_to_start","enter_the_search_content","ascending","descending","delete","share","cancel",
    "edit","add","synchronization_is_not_set",
    "write_something","save","add_location_information","add_tags","select_from_album","taking_photos","select_repository","you_need_to_choose_at_least_one","enter_the_label","add_tag","added_tags","recently_tags","all_tags","sample_tags",
    "repository_name","user_info","remote_repository","local_repository_delete","rebuild_index","enter_a_name","global_onfiguration","no_synchronization","are_you_sure",
    "setting","global_user_info","use_skills","safe_setting","display_and_language","pro","score","share_the_app","about",
    "user_name","user_email","user_info_tip","enter_user_name","enter_user_email", "enter_email_tip",
    "user_agreement","privacy_policy",
    "repositories","sync","syncing","retry","queue","last_sync_time","unsynced","auto_sync","view_logs","copy","set_the_key",
    "select_service_provider","github","github_tip","gitlab","gitlab_tip","custom","custom_tip","auto_add","manually_add",
    "manually_create_empty_1","manually_to_create","manually_input_git_url","manually_set_public_key","manually_regenerating_public_key","manually_copy_and_set_1","manually_to_set_public_key_1","manually_done","manually_empty_tip",
    "authorization_request","authorization_request_tip_1","authorization_request_button_1",
    "select_or_create","click_to_create","no_repository",
    "cloning","cloning_tip","close_log","clone_error","clone_success","go_back",
    "trying_to_connect","add_anyway","add_error","add_success",
    "logs",
    "save_pic","save_markdown","copy_content","more_actions","save_success","save_failed","copied",
    "folder_does_not_exist","updating_the_local_index","update_failed",
    "cannot_access_the_web","delete_remote_tip",
    "appearance","theme_light","theme_dark","theme_auto","language","language_auto",
    "failed_to_create_folder","add_failure","enter_description","create_repository","creates_a_new_repository","the_name_cannot_be_empty","load_repository_failed","confirm","failed_to_get_the_repository_list","failed_to_get_location","load_failed","git_user_info","feedback","system","cannot_access","file_size","modification_time","open_with_another_app","no_permission","no_tags","no_diary","full_functional","unlimited_diary_creation","limited_number_of_pictures","month","year","subscribe_to_the_declaration_0","privacy_policy","subscribe_to_the_declaration_1","user_agreement","subscribe_to_the_declaration_2","restore_purchase","operation_cancelled","operation_success","operation_failure","network_error_please_try_again_later","server_error_please_try_again_later",
    "subscribed"
  ];

  void _set(String key, String? value, String path){
    String v = value ?? '';
    if(v.isEmpty){
      debugPrint('语言包 $path - $key 字段为空 ！');
      return;
    }
    if(key == "app_name"){app_name = v; }
    if(key == "recover"){recover = v; }
    if(key == "create"){create = v; }
    if(key == "clone_to_local"){clone_to_local = v; }
    if(key == "create_a_new_repository"){create_a_new_repository = v; }

    if(key == "time_to_start"){time_to_start = v; }
    if(key == "enter_the_search_content"){enter_the_search_content = v; }
    if(key == "ascending"){ascending = v; }
    if(key == "descending"){descending = v; }
    if(key == "delete"){delete = v; }
    if(key == "share"){share = v; }
    if(key == "cancel"){cancel = v; }

    if(key == "edit"){edit = v; }
    if(key == "add"){add = v; }
    if(key == "synchronization_is_not_set"){synchronization_is_not_set = v; }

    if(key == "write_something"){write_something = v; }
    if(key == "save"){save = v; }
    if(key == "add_location_information"){add_location_information = v; }
    if(key == "add_tags"){add_tags = v; }
    if(key == "select_from_album"){select_from_album = v; }
    if(key == "taking_photos"){taking_photos = v; }
    if(key == "select_repository"){select_repository = v; }
    if(key == "you_need_to_choose_at_least_one"){you_need_to_choose_at_least_one = v; }
    if(key == "enter_the_label"){enter_the_label = v; }
    if(key == "add_tag"){add_tag = v; }
    if(key == "added_tags"){added_tags = v; }
    if(key == "recently_tags"){recently_tags = v; }
    if(key == "all_tags"){all_tags = v; }
    if(key == "sample_tags"){sample_tags = v; }


    if(key == "repository_name"){repository_name = v; }
    if(key == "user_info"){user_info = v; }
    if(key == "remote_repository"){remote_repository = v; }
    if(key == "local_repository_delete"){local_repository_delete = v; }
    if(key == "rebuild_index"){rebuild_index = v; }
    if(key == "enter_a_name"){enter_a_name = v; }
    if(key == "global_onfiguration"){global_onfiguration = v; }
    if(key == "no_synchronization"){no_synchronization = v; }
    if(key == "are_you_sure"){are_you_sure = v; }

    if(key == "setting"){setting = v; }
    if(key == "global_user_info"){global_user_info = v; }
    if(key == "use_skills"){use_skills = v; }
    if(key == "safe_setting"){safe_setting = v; }
    if(key == "display_and_language"){display_and_language = v; }
    if(key == "pro"){pro = v; }
    if(key == "score"){score = v; }
    if(key == "share_the_app"){share_the_app = v; }
    if(key == "about"){about = v; }


    if(key == "user_name"){user_name = v; }
    if(key == "user_email"){user_email = v; }
    if(key == "user_info_tip"){user_info_tip = v; }
    if(key == "enter_user_name"){enter_user_name = v; }
    if(key == "enter_user_email"){enter_user_email = v; }
    if(key == "enter_email_tip"){enter_email_tip = v; }

    if(key == "user_agreement"){user_agreement = v; }
    if(key == "privacy_policy"){privacy_policy = v; }


    if(key == "repositories"){repositories = v; }
    if(key == "sync"){sync = v; }
    if(key == "syncing"){syncing = v; }
    if(key == "retry"){retry = v; }
    if(key == "queue"){queue = v; }
    if(key == "last_sync_time"){last_sync_time = v; }
    if(key == "unsynced"){unsynced = v; }
    if(key == "auto_sync"){auto_sync = v; }
    if(key == "view_logs"){view_logs = v; }
    if(key == "copy"){copy = v; }
    if(key == "set_the_key"){set_the_key = v; }
    if(key == "cannot_access_the_web"){cannot_access_the_web = v; }
    if(key == "delete_remote_tip"){delete_remote_tip = v; }

    if(key == "select_service_provider"){select_service_provider = v; }
    if(key == "github"){github = v; }
    if(key == "github_tip"){github_tip = v; }
    if(key == "gitlab"){gitlab = v; }
    if(key == "gitlab_tip"){gitlab_tip = v; }
    if(key == "custom"){custom = v; }
    if(key == "custom_tip"){custom_tip = v; }
    if(key == "auto_add"){auto_add = v; }
    if(key == "manually_add"){manually_add = v; }

    if(key == "manually_create_empty_1"){manually_create_empty_1 = v; }
    if(key == "manually_to_create"){manually_to_create = v; }
    if(key == "manually_input_git_url"){manually_input_git_url = v; }
    if(key == "manually_set_public_key"){manually_set_public_key = v; }
    if(key == "manually_regenerating_public_key"){manually_regenerating_public_key = v; }
    if(key == "manually_copy_and_set_1"){manually_copy_and_set_1 = v; }
    if(key == "manually_to_set_public_key_1"){manually_to_set_public_key_1 = v; }
    if(key == "manually_done"){manually_done = v; }
    if(key == "manually_empty_tip"){manually_empty_tip = v; }

    if(key == "authorization_request"){authorization_request = v; }
    if(key == "authorization_request_tip_1"){authorization_request_tip_1 = v; }
    if(key == "authorization_request_button_1"){authorization_request_button_1 = v; }

    if(key == "select_or_create"){select_or_create = v; }
    if(key == "click_to_create"){click_to_create = v; }
    if(key == "no_repository"){no_repository = v; }

    if(key == "cloning"){cloning = v; }
    if(key == "cloning_tip"){cloning_tip = v; }
    if(key == "close_log"){close_log = v; }
    if(key == "clone_error"){clone_error = v; }
    if(key == "clone_success"){clone_success = v; }
    if(key == "go_back"){go_back = v; }

    if(key == "trying_to_connect"){trying_to_connect = v; }
    if(key == "add_anyway"){add_anyway = v; }
    if(key == "add_error"){add_error = v; }
    if(key == "add_success"){add_success = v; }

    if(key == "logs"){logs = v; }

    if(key == "save_pic"){save_pic = v; }
    if(key == "save_markdown"){save_markdown = v; }
    if(key == "copy_content"){copy_content = v; }
    if(key == "more_actions"){more_actions = v; }
    if(key == "save_success"){save_success = v; }
    if(key == "save_failed"){save_failed = v; }
    if(key == "copied"){copied = v; }

    if(key == "folder_does_not_exist"){folder_does_not_exist = v; }
    if(key == "updating_the_local_index"){updating_the_local_index = v; }
    if(key == "update_failed"){update_failed = v; }

    if(key == "appearance"){appearance = v; }
    if(key == "theme_light"){theme_light = v; }
    if(key == "theme_dark"){theme_dark = v; }
    if(key == "theme_auto"){theme_auto = v; }
    if(key == "language"){language = v; }
    if(key == "language_auto"){language_auto = v; }

    if(key == "failed_to_create_folder"){failed_to_create_folder = v;}
    if(key == "add_failure"){add_failure = v;}
    if(key == "enter_description"){enter_description = v;}
    if(key == "create_repository"){create_repository = v;}
    if(key == "creates_a_new_repository"){creates_a_new_repository = v;}
    if(key == "the_name_cannot_be_empty"){the_name_cannot_be_empty = v;}
    if(key == "load_repository_failed"){load_repository_failed = v;}
    if(key == "confirm"){confirm = v;}
    if(key == "failed_to_get_the_repository_list"){failed_to_get_the_repository_list = v;}
    if(key == "failed_to_get_location"){failed_to_get_location = v;}
    if(key == "load_failed"){load_failed = v;}
    if(key == "git_user_info"){git_user_info = v;}
    if(key == "feedback"){feedback = v;}
    if(key == "system"){system = v;}
    if(key == "cannot_access"){cannot_access = v;}
    if(key == "file_size"){file_size = v;}
    if(key == "modification_time"){modification_time = v;}
    if(key == "open_with_another_app"){open_with_another_app = v;}
    if(key == "no_permission"){no_permission = v;}
    if(key == "no_tags"){no_tags = v;}
    if(key == "no_diary"){no_diary = v;}
    if(key == "full_functional"){full_functional = v;}
    if(key == "unlimited_diary_creation"){unlimited_diary_creation = v;}
    if(key == "limited_number_of_pictures"){limited_number_of_pictures = v;}
    if(key == "month"){month = v;}
    if(key == "year"){year = v;}
    if(key == "subscribe_to_the_declaration_0"){subscribe_to_the_declaration_0 = v;}
    if(key == "privacy_policy"){privacy_policy = v;}
    if(key == "subscribe_to_the_declaration_1"){subscribe_to_the_declaration_1 = v;}
    if(key == "user_agreement"){user_agreement = v;}
    if(key == "subscribe_to_the_declaration_2"){subscribe_to_the_declaration_2 = v;}
    if(key == "restore_purchase"){restore_purchase = v;}
    if(key == "operation_cancelled"){operation_cancelled = v;}
    if(key == "operation_success"){operation_success = v;}
    if(key == "operation_failure"){operation_failure = v;}
    if(key == "network_error_please_try_again_later"){network_error_please_try_again_later = v;}
    if(key == "server_error_please_try_again_later"){server_error_please_try_again_later = v;}
    if(key == "subscribed"){subscribed = v;}

  }

  // 拼接
  static String joint(String word, List<String> values){
    if(values.isEmpty){ return word; }
    if(values.length == 1){return word.replaceAll('%@', values.first); }
    var sp = word.split('%@');
    var newWord = '';
    for(int i = 0; i < sp.length; i++){
      newWord = newWord + sp[i] + (i < values.length ? values[i] : '');
    }
    return newWord;
  }

  static L current(BuildContext context, {bool listen = true}){
    var l =  Provider.of<SettingModel>(context, listen:listen).l;
    return l;
  }

  static Future<L?> loadFrom(String path) async{

    return null;
  }

  static checkLanguagePackage(Map<String, dynamic> pack, String path){
    for(var key in allKeys){
      if(pack[key] == null){
        debugPrint('语言包 $path - $key 字段不存在 ！');
      }
    }
  }

  static L? fromJson(String json, String path){
    if(json.isEmpty){
      return null;
    }
    try{
      var kv = convert.jsonDecode(json);
      if(kv is Map<String, dynamic>){
        var info = kv['info'];
        var data = kv['data'];
        if(data is Map<String, dynamic>){
          if (kDebugMode) { checkLanguagePackage(data, path); }
          L l = L();
          if(info is Map<String, dynamic>){
            l.exPath = path; // 语言包路径（唯一） // auto:跟随系统
            l.exName = info['name']; // 语言名称：简体中文、English、...
            l.exAuthor = info['author'];
            l.exVersion = info['version'];
            var codes = info['code'];
            if(codes != null && codes is List<String>){ l.exCodes = codes; }
            l.exDesc = info['desc'];
            l.exHomePage = info['homePage']; // 主页
            l.exUpdateUrl = info['updateUrl']; // 更新地址
          }
          for(var key in data.keys){
            l._set(key, data[key], path);
          }
          return l;
        }
      }
      return null;
    }catch(e){
      return null;
    }
  }

  static Future<List<L>> loadAll(BuildContext context, {bool needAuto = true}) async{
    /// 读取assets某个文件夹下的所有文件
    final manifestJson = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final packPaths = json.decode(manifestJson).keys.where((String key) => key.startsWith('static/language'));
    List<L> all = [];
    if(needAuto){ all.add(L.autoEmpty()); }
    for(var path in packPaths){
      try{
        var strValue = await rootBundle.loadString(path);
        var lan = fromJson(strValue, path);
        if(lan != null){ all.add(lan); }
      }catch(e){
        if (kDebugMode) { print(e); }
        continue;
      }
    }
    /// TODO:加载自定义语言包

    return all;
  }

  static L autoEmpty(){
    L l = L();
    l.exPath = 'auto';
    return l;
  }

}
