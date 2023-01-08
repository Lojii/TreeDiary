
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info/package_info.dart';
import 'package:treediary/pages/web_page.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/config.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';

class AboutPage extends StatefulWidget {

  const AboutPage({Key? key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with WidgetsBindingObserver{

  String version = '';
  String appName = '';
  String bundleId = '';

  @override
  void initState() {
    super.initState();
    loadAppInfo();
  }

  @override
  dispose(){
    super.dispose();
  }

  loadAppInfo() async{
    var p = await PackageInfo.fromPlatform();
    setState(() {
      version = p.version;
      appName = p.appName;
      bundleId = p.buildNumber;
    });
  }

  Widget itemView(String title, String value, void Function() onTap){
    var colors =  C.current(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: colors.bgOnBody_2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: colors.tintPrimary, fontSize: F.f16)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: TextStyle(color: colors.tintSecondary, fontSize: F.f16), textAlign: TextAlign.right,),
                    SvgPicture.asset('static/images/right_arrow_item.svg',color: colors.tintSecondary,)
                  ],
                )
              ],
            ),
          ),
          Divider(height: 1,color: colors.tintSeparator_2,),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(language.about, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
          ),
          backgroundColor: colors.bgBodyBase_1,
          elevation: 0.5,
        ),
        backgroundColor: colors.bgBodyBase_1,
        body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 15,right: 15, top: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Column(
                          children: [
                            itemView(language.feedback,Config.feedbackEmail,() async{
                              String? encodeQueryParameters(Map<String, String> params) {
                                return params.entries.map((MapEntry<String, String> e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
                              }
                              var p = await PackageInfo.fromPlatform();
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: Config.feedbackEmail,
                                query: encodeQueryParameters(<String, String>{
                                  'subject': '${p.appName}${p.version}(${p.buildNumber}-(${Platform.operatingSystem})) Feedback',
                                }),
                              );
                              launchUrl(emailLaunchUri);
                            }),
                            itemView(language.privacy_policy,'',(){ Navigator.push(context, MaterialPageRoute(builder: (context)=> WebPage(url: 'http://kingtup.cn/tree_yszc',title: language.privacy_policy))); }),
                            itemView(language.user_agreement,'',(){ Navigator.push(context, MaterialPageRoute(builder: (context)=> WebPage(url: 'http://kingtup.cn/tree_fwtk',title: language.user_agreement))); }),
                            if(language.exName?.contains('中文') ?? false)
                              itemView('微信号','AKQL1022',(){
                                Clipboard.setData(const ClipboardData(text:'AKQL1022'));
                                EasyLoading.showToast('Copy success', duration: const Duration(seconds: 1), maskType: EasyLoadingMaskType.none);
                              })
                          ],
                        )
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    ClipRRect(
                        borderRadius:BorderRadius.circular(26),
                        child:Image.asset('static/images/logo.png',width: 110,height: 110,)
                    ),
                    Container(
                      padding: const EdgeInsets.only(bottom: 30, top: 30),
                      child: Text('$appName $version($bundleId)', style: TextStyle(color: colors.tintPrimary, fontSize: F.f16),),
                    )
                  ],
                )
              ],
            ),
        )
    );
  }
}
