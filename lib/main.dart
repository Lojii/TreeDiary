
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:treediary/config/storage_manager.dart';
import 'package:treediary/provider/global_model.dart';
import 'package:treediary/provider/provider_sql.dart';
import 'package:treediary/provider/repo_list_model.dart';
import 'package:treediary/provider/setting_model.dart';
import 'package:treediary/provider/task_model.dart';
import 'package:treediary/repo/sql_manager.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_bugly/flutter_bugly.dart';

import 'config/global_data.dart';
import 'config/config.dart';
import 'index.dart';

// void main() async{
//
//   Provider.debugCheckInvalidValueType = null;
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
//   await Global.init();
//   await StorageManager.init();
//   configLoading();
//   await ProviderSQLManager.initDatabase();
//   await SQLManager.initDatabase();
//   SettingModel settingModel = await SettingSQL.loadSetting();
//   RepoListModel repoListModel = await RepoListModel.loadRepoModelList();
//   TaskModel taskModel = TaskModel.create(repoListModel.repoList);
//   runApp(AppPage(settingModel: settingModel, repoListModel: repoListModel,taskModel: taskModel));
//   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarBrightness: Brightness.light));

void main() {
  FlutterBugly.postCatchedException(() async{
    Provider.debugCheckInvalidValueType = null;
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    await Global.init();
    await StorageManager.init();
    configLoading();
    await ProviderSQLManager.initDatabase();
    await SQLManager.initDatabase();
    SettingModel settingModel = await SettingSQL.loadSetting();
    RepoListModel repoListModel = await RepoListModel.loadRepoModelList();
    TaskModel taskModel = TaskModel.create(repoListModel.repoList);
    runApp(AppPage(settingModel: settingModel, repoListModel: repoListModel,taskModel: taskModel));
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarBrightness: Brightness.light));
    FlutterBugly.init(androidAppId: Config.androidBuglyId, iOSAppId: Config.iOSBuglyId,);
  },onException:(FlutterErrorDetails details){
    if (kDebugMode) {
      print('------上报异常------');
      print(details);
    }
  },debugUpload: false);
}

//
void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..maskType = EasyLoadingMaskType.black;
}


class AppPage extends StatefulWidget {
  final SettingModel settingModel;
  final RepoListModel repoListModel;
  final TaskModel taskModel;
  const AppPage({Key? key, required this.settingModel, required this.repoListModel, required this.taskModel}) : super(key: key);

  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider.value(value: widget.settingModel),
          ChangeNotifierProvider.value(value: widget.repoListModel),
          ChangeNotifierProvider.value(value: widget.taskModel),
          ChangeNotifierProvider(create:(_) => GlobalModel(),),
        ],
        child: Consumer<SettingModel>(
          builder:(BuildContext context, settingModel, Widget? child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                widget.settingModel.updateLanguage(deviceLocale);
                return null;
              },
              home: const IndexPage(),
              builder: EasyLoading.init(
                builder:(context, widget) {
                  EasyLoading.init();
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),//设置文字大小不随系统设置改变
                    child: widget!,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}