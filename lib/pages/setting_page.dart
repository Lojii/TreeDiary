
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/pages/setting_theme_page.dart';
import 'package:treediary/pages/setting_userinfo_page.dart';
import 'package:treediary/pages/web_page.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../config/config.dart';
import '../config/purchase_manager.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../test_page.dart';
import '../widgets/store_viewer.dart';
import 'about_page.dart';

class SettingPage extends StatefulWidget {

  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with WidgetsBindingObserver{


  @override
  void initState() {
    super.initState();
  }

  @override
  dispose(){
    super.dispose();
  }

  Widget itemWidget(Map<String,Object> item){
    var colors =  C.current(context);
    String title = item['title'] as String;
    GestureTapCallback? func = item['func'] as GestureTapCallback?;
    return GestureDetector(
      onTap: func,
      child: Container(
        padding: const EdgeInsets.only(left: 15,top: 12,bottom: 12,right: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.tintSeparator, width: 0.5,),),),
        child:Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),),
            SvgPicture.asset('static/images/right_arrow_item.svg',color: colors.tintSecondary,)
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    List<Map<String,Object>> items = [
      {
        'title':language.global_user_info,
        'func':(){ Navigator.push(context, MaterialPageRoute(builder: (context)=> SettingUserInfoPage())); }
      },
      {
        'title':language.display_and_language,
        'func':(){ Navigator.push(context, MaterialPageRoute(builder: (context)=> const SettingThemePage())); }
      },
      if(Platform.isIOS)
        {
          'title':language.pro,
          'func':() async{
            if(!await LatestReceiptInfos.alreadyPurchase()){
              await StoreView.show(context);
            }else{
              EasyLoading.showToast(language.subscribed);
            }
          }
        },
      {
        'title':language.about,
        'func':(){ Navigator.push(context, MaterialPageRoute(builder: (context)=> const AboutPage())); }
      }
    ];

    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(language.setting, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
          ),
          backgroundColor: colors.bgBodyBase_1,
          elevation: 0.5,
          // actions: <Widget>[],
        ),
        backgroundColor: colors.bgBodyBase_1,
        body: SafeArea(
          child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...items.map((e) => itemWidget(e)).toList()
                ],
              )
          )
        )
    );
  }
}
