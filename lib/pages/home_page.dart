
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/provider/setting_model.dart';
import 'package:treediary/widgets/menu_icon.dart';
import 'package:provider/provider.dart';

import 'package:treediary/provider/repo_list_model.dart';

import '../config/global_data.dart';
import '../isolate/git_isolate.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/global_model.dart';
import '../provider/provider_sql.dart';
import '../test_page.dart';
import '../utils/event_bus.dart';
import '../widgets/tag_list_drawer.dart';
import 'edit_page.dart';
import 'init_page.dart';
import 'main_folder_page.dart';
import 'menu_page.dart';
import 'main_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {

  DateTime? lastPopTime;

  late bool showTimeField;
  late bool showSearchField;

  @override
  void initState() {
    showTimeField = false;
    showSearchField = false;
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   // Provider.of<SettingModel>(context).setExtraColor(context: context);
    // });
    Bus.on('showSearchField', (show) { setState(() { showSearchField = show; }); });
    Bus.on('showTimeField', (show) { setState(() { showTimeField = show; }); });
    Bus.on(ProviderSQLManager.ProviderRefresh, (arg) { Provider.of<RepoListModel>(context, listen:false).refreshList(); });

  }

  @override
  void dispose() {
    super.dispose();
    Bus.off('showSearchField');
    Bus.off('showTimeField');
    Bus.off(ProviderSQLManager.ProviderRefresh);
    // Bus.off(Global.busCloseMainDrawer);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    Provider.of<SettingModel>(context, listen:false).didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    var language = L.current(context);
    GitIsolate().run(Provider.of<RepoListModel>(context, listen:false).repoList, context); // 开启同步线程，只会执行一次
    var colors =  C.current(context);
    EasyRefresh.defaultHeaderBuilder = () => ClassicHeader( showText:false, iconTheme: IconThemeData(color: colors.tintPrimary) );
    EasyRefresh.defaultFooterBuilder = () => ClassicFooter( showText:false, iconTheme: IconThemeData(color: colors.tintPrimary) );

    //状态控制是否显示文本组件
    var currentRepo = Provider.of<RepoListModel>(context, listen:true).currentSelectedRepo;
    bool showInit = currentRepo == null;
    Widget body = showInit ? const InitPage() : (currentRepo.isDiary ? const MainPage() : const MainFolderPage());
    String title = showInit ? language.app_name : currentRepo.name;
    List<Widget>? actions = showInit ? null : (currentRepo.isDiary ? <Widget>[ //导航栏右侧菜单
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: (){ Bus.emit(Global.busHomeSearchDidClick); },
        child: Container(
          padding: const EdgeInsets.only(left: 15,right: 4),
          child: SvgPicture.asset('static/images/home_search.svg',width: 26,height: 26,color: colors.tintPrimary,),// ,width: 26,height: 26,
        ),
      ),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: (){ Bus.emit(Global.busHomeTimeDidClick); },
        child: Container(
          padding: const EdgeInsets.only(left: 4,right: 4),
          child: SvgPicture.asset('static/images/home_field.svg',width: 26,height: 26,color: colors.tintPrimary,),// ,width: 26,height: 26,
        ),
      ),
      Builder(builder: (BuildContext context){
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: (){ Scaffold.of(context).openEndDrawer(); },
          child: Container(
            padding: const EdgeInsets.only(left: 4,right: 15),
            child: SvgPicture.asset('static/images/home_tag.svg',width: 26,height: 26,color: colors.tintPrimary,),// ,width: 26,height: 26,
          ),
        );
      }),
    ] : null);
    Widget? endDrawer = showInit ? null : (currentRepo.isDiary ? const TagListDrawer() : null);
    Widget? floatingActionButton = showInit ? null : (currentRepo.isDiary ? ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GestureDetector(
          onTap: () {
            Provider.of<GlobalModel>(context, listen:false).editReposChange([Provider.of<RepoListModel>(context, listen:false).currentSelectedRepo!]);
            Provider.of<GlobalModel>(context, listen:false).editTagsChange([]);
            Navigator.push(context, MaterialPageRoute(builder: (context)=> const EditPage()));
          },
          child: Container(
            color: colors.tintGitYellow,
            padding: const EdgeInsets.all(5),
            child: SvgPicture.asset('static/images/home_add.svg', color: colors.solidWhite_1,),
          ),
        )
    ) : null);

    return WillPopScope(
      child: Scaffold(
        appBar: AppBar( //导航栏
          leading:Builder(builder: (BuildContext context){
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: (){ Scaffold.of(context).openDrawer(); },
              child: Container(
                padding: const EdgeInsets.only(left: 15,right: 10),
                child: MenuIcon()
              ),
            );
          }),
          title: Text(title, textAlign: TextAlign.right,style: TextStyle(color: colors.tintPrimary, fontSize: F.f18,fontWeight: FontWeight.w600),),
          actions: actions,
          elevation: 0,//隐藏底部阴影分割线
          centerTitle: false,
          titleSpacing:0,
          backgroundColor: colors.bgBodyBase_2,
        ),
        drawer: const MenuDrawer(),
        endDrawer: endDrawer,
        // onEndDrawerChanged:(isOpen){ if(!isOpen){ Bus.emit(MainPage.forceRefresh); } }, /// 通知首页刷新
        floatingActionButton: floatingActionButton,
        body: body//, initPage()
      ),
      onWillPop: () async {
        if (lastPopTime == null || DateTime.now().difference(lastPopTime!) > const Duration(seconds: 1)) {
          lastPopTime = DateTime.now();
          EasyLoading.showToast("再按一次退出", duration: const Duration(seconds: 1),toastPosition: EasyLoadingToastPosition.bottom,maskType: EasyLoadingMaskType.none);
          return Future.value(false);
        } else {
          lastPopTime = null;
          // 退出app
          return Future.value(true);
        }
      }
    );


  }
}