// 启动页，根据该页进行跳转

//
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:treediary/pages/home_page.dart';
import 'package:treediary/pages/init_page.dart';
import 'package:treediary/provider/global_color.dart';
import 'package:treediary/provider/repo_list_model.dart';
import 'package:treediary/setting_home.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

class IndexPage extends StatefulWidget {
  static const String routeName = "/";

  const IndexPage({Key? key}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage>{
  bool hadInit = false;
  @override
  void initState() {
    // ScreenUtil.init(context);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (kDebugMode) { print('IndexPage dispose'); }
  }

  // void printScreenInformation() {
  //   print('设备宽度:${1.sw}dp');
  //   print('设备高度:${1.sh}dp');
  //   print('设备的像素密度:${ScreenUtil().pixelRatio}');
  //   print('底部安全区距离:${ScreenUtil().bottomBarHeight}dp');
  //   print('状态栏高度:${ScreenUtil().statusBarHeight}dp');
  //   print('实际宽度和字体(dp)与设计稿(dp)的比例:${ScreenUtil().scaleWidth}');
  //   print('实际高度(dp)与设计稿(dp)的比例:${ScreenUtil().scaleHeight}');
  //   print('高度相对于设计稿放大的比例:${ScreenUtil().scaleHeight}');
  //   print('系统的字体缩放比例:${ScreenUtil().textScaleFactor}');
  //   print('屏幕宽度的0.5:${0.5.sw}dp');
  //   print('屏幕高度的0.5:${0.5.sh}dp');
  //   print('屏幕方向:${ScreenUtil().orientation}');
  // }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (hadInit) {
      return;
    }
    hadInit = true;
    // 账户信息，repo信息读取，检查，核对
    Future.delayed(const Duration(seconds: 1, milliseconds: 100), () {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => route == null);
      // if(Provider.of<RepoListModel>(context, listen:false).repoList.isEmpty){
      //   Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> const InitPage()));
      // }else{
      //   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => route == null);
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    // EasyRefresh.defaultHeaderBuilder = () => ClassicHeader( showText:false, iconTheme: IconThemeData(color: colors.tintPrimary) );
    // EasyRefresh.defaultFooterBuilder = () => ClassicFooter( showText:false, iconTheme: IconThemeData(color: colors.tintPrimary) );
    return Scaffold(
      body: Container(
        color: colors.bgBodyBase_1,
        child: Center(
          child: Lottie.asset('static/file/loading.json', animate: true, width: MediaQuery.of(context).size.width / 3),
        )
      ),
    );
  }

}
