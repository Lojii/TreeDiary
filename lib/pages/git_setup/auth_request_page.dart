
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../apis/githost_factory.dart';
import '../../provider/global_color.dart';
import '../../provider/global_language.dart';
import 'add_remote_page_auto.dart';

class AuthRequestPage extends StatefulWidget {

  final String? repoKey; /// 如果没有repoKey，则为clone授权，否则为添加远程同步地址授权
  final GitHostType type;
  final Function? authedCall; // 授权完成后的回调

  const AuthRequestPage({Key? key, this.repoKey, required this.type, this.authedCall}) : super(key: key);

  @override
  _AuthRequestPageState createState() => _AuthRequestPageState();
}

class _AuthRequestPageState extends State<AuthRequestPage> with WidgetsBindingObserver{

  GitHost? gitHost;

  @override
  void initState() {
    super.initState();
    gitHost = createGitHost(widget.type);
    /// 授权结果监听
    gitHost?.uniLinkListen((p0) {
      /// 如果没有报错，则执行callback
      /// 如果报错，则提示错误
      if(p0 != null){
        EasyLoading.showToast(p0.toString());
      }else{
        gitHost?.uniLinkCancel();
        if(widget.authedCall != null){
          widget.authedCall!();
        }
        // Navigator.push(context, MaterialPageRoute(builder: (context)=> RemoteAutoPage(repoKey: widget.repoKey, gitHost: gitHost!)));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> RemoteAutoPage(repoKey: widget.repoKey, gitHost: gitHost!)));
      }
    });
  }

  @override
  dispose(){
    gitHost?.uniLinkCancel();
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
  buttonDidClick() async{
    await gitHost?.launchOAuthScreen();
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    String description = L.joint(language.authorization_request_tip_1, widget.type == GitHostType.GitHub ? ['Github'] : ['Gitlab']);
    String buttonTitle = L.joint(language.authorization_request_button_1, widget.type == GitHostType.GitHub ? ['Github'] : ['Gitlab']);
    // if(widget.type == GitHostType.GitHub){
    //   description = '自动操作需要您临时授权当前设备，点击前往Github，登录授权后返回，即可进入下一步操作(如果Github无法访问，请尝试切换WiFi与移动网络)';
    //   buttonTitle = '前往Github进行授权';
    // }else if(widget.type == GitHostType.GitLab){
    //   description = '自动操作需要您临时授权当前设备，点击前往GitLab，登录授权后返回，即可进入下一步操作';
    //   buttonTitle = '前往GitLab进行授权';
    // }else{
    //
    // }
    return Scaffold(
      appBar: AppBar( //导航栏
        titleSpacing:0,
        title: Text(language.authorization_request, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
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
      backgroundColor: colors.bgBodyBase_1,//fromRGBO(239, 243, 246, 1),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 30,right: 30),
                child: Text(description,textAlign: TextAlign.center,
                  style: TextStyle(color: colors.tintPrimary,fontSize: F.f16,),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 20,left: 30,right: 30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GestureDetector(
                    onTap: (){
                      buttonDidClick();
                    },
                    child: Container(
                      color: colors.bgOnBody_2,
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 10,bottom: 10),
                      child: Text(buttonTitle,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      )
    );
  }
}
