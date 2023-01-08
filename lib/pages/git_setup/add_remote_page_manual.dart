/*
1、点击跳转新建库按钮
2、输入仓库地址
3、SSH授权keys配置(生成新的、从其他地方导入、选择已有的)
   3.1、复制
   3.2、重新生成
   3.3、前往仓库key设置页按钮(网页)
4、执行按钮
* */
// import 'package:flutter/cupertino.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/model/ssh_key.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../apis/githost_factory.dart';
import '../../git/git_async.dart';
// import '../../model/git_host_type.dart';
import '../../provider/global_color.dart';
import '../../provider/global_language.dart';
import '../../provider/repo_list_model.dart';

import 'package:cryptography/cryptography.dart';
import 'package:openssh_ed25519/openssh_ed25519.dart';

import 'package:flutter/services.dart';

import '../../utils/string_utils.dart';
import '../remote_list_page.dart';
import 'git_clone_page.dart';
import 'git_add_remote_page.dart';

class RemoteManualPage extends StatefulWidget {

  final String? repoKey; /// 如果为空，则为clone，否则为添加同步地址
  final GitHostType type;

  const RemoteManualPage({Key? key, this.repoKey, required this.type}) : super(key: key);

  @override
  _RemoteManualPageState createState() => _RemoteManualPageState();
}

class _RemoteManualPageState extends State<RemoteManualPage> with WidgetsBindingObserver{

  SSHKey sshKey = SSHKey();
  String gitUrl = '';

  @override
  void initState(){
    // sshKey
    generateNewKeyPair(showToast:false);
    super.initState();
  }

  generateNewKeyPair({bool showToast = true}) async{
    if(showToast){ await EasyLoading.show(); }
    await sshKey.delete();
    var key = await SSHKey.generate();
    setState((){sshKey = key;});
    if(showToast){ await EasyLoading.dismiss();}
  }

  @override
  dispose(){
    super.dispose();
    print('dispose');
  }

  clickHow() {
    print('----clickHow----');

  }

  Widget  buttonItem(String title, String buttonTitle, Function buttonDidClick){
    var colors =  C.current(context);
    return Container(
      padding: EdgeInsets.only(top: 25,left: 15,right: 15),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 15),
            child: Text(title,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: (){
                buttonDidClick();
              },
              child: Container(
                color: colors.bgOnBody_2,
                width: double.infinity,
                padding: EdgeInsets.only(top: 10,bottom: 10),
                child: Text(buttonTitle,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget inputItem(String title, String placeholder,Function textDidChange){
    var colors =  C.current(context);
    return Container(
      // color: Colors.red,
      padding: EdgeInsets.only(top: 25,left: 15,right: 15),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 15),
            child: Text(title,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),),
          ),
          Container(
            padding: EdgeInsets.only(top: 10,bottom: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.tintSeparator_2, width: 0.5,),),),
            child: TextField(
              onChanged:(value) {
                textDidChange(value);
              },
              decoration: InputDecoration.collapsed(
                hintText: placeholder,
                hintStyle:TextStyle(fontSize: F.f16, color: colors.tintPlaceholder),
              ),
              style:TextStyle(fontSize: F.f16,color: colors.tintPrimary,),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget keyItem(String title, SSHKey key, Function clickCopy, Function clickReGenerate){
    var colors =  C.current(context);
    var language = L.current(context);
    return Container(
      // color: Colors.red,
      padding: EdgeInsets.only(top: 25,left: 15,right: 15),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 15),
            child: Text(title,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),),
          ),
          GestureDetector(
            onTap: (){clickCopy();},
            child: Container(
              padding: EdgeInsets.only(top: 8,bottom: 8,left: 5),
              // margin: EdgeInsets.only(top: 8,bottom: 8,left: 5,right: 5),
              color: colors.bgOnBody_2,
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(key.publicKey, style: TextStyle(fontSize: F.f14,color: colors.tintSecondary),maxLines:1)
                    )
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 10,right: 10),
                    child: Text(language.copy,style: TextStyle(color: colors.tintPrimary),),
                  )
                ]
              )
            )
          ),
          Container(
            height: 8,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: (){ clickReGenerate(); },
              child: Container(
                color: colors.bgOnBody_2,
                width: double.infinity,
                padding: EdgeInsets.only(top: 10,bottom: 10),
                child: Text(language.manually_regenerating_public_key,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
              )
            )
          )
        ]
      )
    );
  }

  toGitSync() async{
    if(gitUrl.isEmpty){
      var language = L.current(context, listen: false);
      EasyLoading.showToast(language.manually_empty_tip);
      return;
    }
    /// TODO:链接检查
    /// https://blog.csdn.net/Castlehe/article/details/119530573
    //  本地协议 : file:///xx/xx/xx
    //  http　: https://github.com/Lojii/git0731.git
    //  ssh　 : ssh://opt/git/project.git   ssh://[user@]server/project.git  [user@]server:project.git
    //  git   : git@example.com:gitProject.git
    // var uri = Uri.tryParse(gitUrl);
    // if (kDebugMode) { print('check url : $uri'); }
    // if(uri == null){
    //   if(!gitUrl.contains('@') && !gitUrl.contains(':')){
    //     EasyLoading.showToast('仓库地址不合法');
    //     return;
    //   }
    // }

    if(widget.repoKey == null){
      /// clone
      Navigator.push(context, MaterialPageRoute(builder: (context)=> GitClonePage(gitUrl: gitUrl, sshKey: sshKey,)));
    }else{
      /// addRemote
      Navigator.push(context, MaterialPageRoute(builder: (context)=> GitAddRemotePage(repoKey: widget.repoKey!, gitUrl: gitUrl, sshKey: sshKey,)));
    }
  }

  List<Widget> steps(){
    var language = L.current(context);
    if(widget.type == GitHostType.Custom){
      return [
        inputItem('1、${language.manually_input_git_url}', 'git@github.com:example/example.git', (value){ gitUrl = value; }),
        keyItem('2、${language.manually_set_public_key}',sshKey,(){
          Clipboard.setData(ClipboardData(text:sshKey.publicKey));
          EasyLoading.showToast('Copy success');
        },() { generateNewKeyPair(); }),
        buttonItem('3、${language.manually_done}',language.manually_done,(){ toGitSync(); }),
      ];
    }else{
      String name = '';
      String exampleUrl = '';
      String newUrl = '';
      String keyStepStr = '';
      String permissions = '';
      if(widget.type == GitHostType.GitHub){
        name = 'GitHub';
        newUrl = 'https://github.com/new';
        exampleUrl = 'git@github.com:example/example.git';
        keyStepStr = 'Settings -> Deploy keys -> Add deploy key';
        permissions = '【Allow write access】';
      }else if(widget.type == GitHostType.GitLab){
        name = 'GitLab';
        newUrl = 'https://gitlab.com/projects/new';
        exampleUrl = 'git@gitlab.com:example/example.git';
        keyStepStr = 'Settings -> Repository -> Deploy keys -> Add key';
        permissions = '【Grant write permissions to this key】';
      }
      return [
        buttonItem('1、${L.joint(language.manually_create_empty_1, [name])}',language.manually_to_create,() async {
          try {
            await launchUrl(Uri.parse(newUrl), mode: LaunchMode.externalApplication,);
          } catch (err, stack) {
            if (kDebugMode) { print('_launchCreateRepoPage: \n$err - \n$stack'); }
          }
        }),
        inputItem('2、${language.manually_input_git_url}',exampleUrl,(value){ gitUrl = value; }),
        keyItem('3、${language.manually_set_public_key}',sshKey,(){
          Clipboard.setData(ClipboardData(text:sshKey.publicKey));
          if (kDebugMode) { print(sshKey.publicKey); }
          EasyLoading.showToast('Copy success');
        },() { generateNewKeyPair(); }),
        buttonItem('4、${L.joint(language.manually_copy_and_set_1, [name])}:$keyStepStr。$permissions',L.joint(language.manually_to_set_public_key_1, [name]),() async{
          String url = generateSetKeyUrl();
          if(url.isEmpty){ return; }
          try {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication,);
          } catch (err, stack) {
            if (kDebugMode) { print('_launchSettingKeyPage: \n$gitUrl \n$url \n$err - \n$stack'); }
          }
        }),
        buttonItem('5、${language.manually_done}',language.manually_done,(){ toGitSync(); }),
      ];
    }
    return [];
  }

  String generateSetKeyUrl(){
    // https://github.com/settings/ssh/new
    // https://github.com/Lojii/07121433/settings/keys/new
    // https://gitlab.com/-/profile/keys
    // https://gitlab.com/Lojii/07121433/-/settings/repository
    if(gitUrl.isNotEmpty){
      // git@github.com:example/example.git
      var lastPart = gitUrl.split('.com').last;
      if(lastPart.startsWith('/')){
        lastPart = lastPart.replaceFirst('/', '');
      }else if(lastPart.startsWith(':')){
        lastPart = lastPart.replaceFirst(':', '');
      }
      var pp = lastPart.split('/');
      if(pp.length >= 2){
        String user = pp[0];
        String repo = pp[1];
        repo = repo.replaceAll('.git', '');
        if(user.isNotEmpty && repo.isNotEmpty){
          if(widget.type == GitHostType.GitHub){
            return 'https://github.com/$user/$repo/settings/keys/new';
          }else if(widget.type == GitHostType.GitLab){
            return 'https://gitlab.com/$user/$repo/-/settings/repository';
          }
        }
      }
    }
    if(widget.type == GitHostType.GitHub){
      return 'https://github.com/settings/ssh/new';
    }else if(widget.type == GitHostType.GitLab){
      return 'https://gitlab.com/-/profile/keys';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(language.manually_add, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
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
        backgroundColor: colors.bgBodyBase_1,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...steps(),
                    Container(height: 34,)
                  ],
                )
            )
        )
    );
  }
}


