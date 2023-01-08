
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/apis/githost_factory.dart';

import '../../provider/global_color.dart';
import '../../provider/global_language.dart';
import '../../widgets/common/bottom_sheet.dart';
import 'add_remote_page_auto.dart';
import 'add_remote_page_manual.dart';
import 'auth_request_page.dart';

class SelectGitProviderPage extends StatefulWidget {

  final String? repoKey; /// 如果没有repoKey，则为clone授权，否则为添加远程同步地址授权

  const SelectGitProviderPage({Key? key, this.repoKey}) : super(key: key);

  @override
  _SelectGitProviderPageState createState() => _SelectGitProviderPageState();
}

class _SelectGitProviderPageState extends State<SelectGitProviderPage> with WidgetsBindingObserver{

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose(){
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // refreshRemoteList();
  }

  //
  clickHow(){
    print('clickHow');
  }

  // 开启外部参数监听，跳转授权页面
  itemDidClick(GitHostType type) async{
    var language = L.current(context, listen:false);
    if(type == GitHostType.Custom){
      /// 跳转普通添加页面
      Navigator.push(context, MaterialPageRoute(builder: (context)=> RemoteManualPage(repoKey: widget.repoKey, type:type)));
    }else{
      ///
      final result = await showModalFitBottomSheet(context, list: [
        SheetItem(title: language.auto_add, key: 'auto'),
        SheetItem(title: language.manually_add, key: 'manual')
      ]);
      if(result == 'auto'){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> AuthRequestPage(repoKey: widget.repoKey, type: type, authedCall: (){})));
      }else if(result == 'manual'){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> RemoteManualPage(repoKey: widget.repoKey, type:type)));
      }
    }
  }

  Widget itemWidget({required String logo, required String title, required String subTitle, required Function click}){
    var colors =  C.current(context);
    return Container(
      padding: const EdgeInsets.only(left: 15,top: 10,right: 15),
      child: GestureDetector(
        onTap: () => click(),
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
              padding: const EdgeInsets.all(15),
              color: colors.bgOnBody_1,
              child: Row(
                children: [
                  SvgPicture.asset(logo, width: 50, height: 50,color: colors.tintSecondary),
                  const SizedBox(width: 15,),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: colors.tintPrimary, fontSize: F.f20, fontWeight: FontWeight.w700),),
                      Text(subTitle, style: TextStyle(color: colors.tintSecondary, fontSize: F.f16),),
                    ],
                  ))
                ],
              )
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(language.select_service_provider, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
          ),
          backgroundColor: colors.bgBodyBase_1,
          elevation: 0.5,
          // actions: <Widget>[
          //   GestureDetector(
          //     behavior: HitTestBehavior.opaque,
          //     onTap: (){
          //       clickHow();
          //     },
          //     child: Container(
          //       padding: const EdgeInsets.only(right: 10,left: 10),
          //       child: SvgPicture.asset('static/images/how.svg',color: colors.tintPrimary),
          //     ),
          //   )
          // ],
        ),
        backgroundColor: colors.bgBodyBase_2,//fromRGBO(239, 243, 246, 1),
        body: SafeArea(
            child: Center(
              child: Column(
                children: [
                  itemWidget(logo: 'static/images/logo_github.svg', title: language.github, subTitle: language.github_tip, click: (){ itemDidClick(GitHostType.GitHub); }),
                  itemWidget(logo: 'static/images/logo_gitlab.svg', title: language.gitlab, subTitle: language.gitlab_tip, click: (){ itemDidClick(GitHostType.GitLab); }),
                  itemWidget(logo: 'static/images/logo_custom.svg', title: language.custom, subTitle: language.custom_tip, click: (){ itemDidClick(GitHostType.Custom); }),
                ],
              ),
            )
        )
    );
  }
}
