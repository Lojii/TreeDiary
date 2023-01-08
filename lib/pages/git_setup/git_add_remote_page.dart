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

import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/isolate/git_isolate.dart';
import 'package:treediary/model/ssh_key.dart';
import 'package:treediary/pages/remote_list_page.dart';
import 'package:provider/provider.dart';
import '../../git/git_action.dart';
import '../../provider/global_color.dart';
import '../../provider/global_language.dart';
import '../../provider/repo_list_model.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:cryptography/cryptography.dart';
import 'package:openssh_ed25519/openssh_ed25519.dart';

import 'package:flutter/services.dart';

import '../../widgets/common/rotation_widget.dart';
/// TODO:改成只检查添加地址是否可用，不进行同步，同步交给后台线程，添加完毕后，提示用户是否开启该远程仓库的自动同步功能
class GitAddRemotePage extends StatefulWidget {

  final String repoKey;
  final SSHKey sshKey;
  final String gitUrl;

  const GitAddRemotePage({Key? key, required this.repoKey, required this.gitUrl, required this.sshKey, }) : super(key: key);

  @override
  _GitAddRemotePageState createState() => _GitAddRemotePageState();
}

class _GitAddRemotePageState extends State<GitAddRemotePage> with WidgetsBindingObserver{

  // init\loading\error\success
  String status = 'init';
  String title = '';
  String info = '';

  String? _remoteName;

  @override
  void initState(){
    // sshKey
    super.initState();
    // DartWidgetsBinding.instance!.addPostFrameCallback((duration) {});
  }

  @override
  void dispose() {

    super.dispose();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    addRemote();
  }
  /// TODO:添加同步到repo，并添加到异步队列，同时刷新
  addSyncToRepo(String? remoteName) async{
    /// 添加到仓库
    RepoModel? repo;
    List<RepoModel> repoList = Provider.of<RepoListModel>(context, listen:false).repoList;
    for(var r in repoList){
      if(r.key == widget.repoKey){
        repo = r;
        break;
      }
    }
    if(repo == null){ return; }
    remoteName = GitAction.addRemote(repo.fullPath, widget.gitUrl);
    if (kDebugMode) { print('add success'); }
    /// 转正key
    await widget.sshKey.upgrade();
    /// 正式添加到设置
    RepoSync newSync = RepoSync();
    newSync.repoPath = widget.repoKey;
    newSync.type = '';
    newSync.lastSyncTime = DateTime.now().millisecondsSinceEpoch.toString();
    newSync.lastCheckTime = DateTime.now().millisecondsSinceEpoch.toString();
    newSync.remotePath = widget.gitUrl;
    newSync.remoteName = remoteName ?? '';
    newSync.sshKeyId = widget.sshKey.id;
    newSync.pubKey = widget.sshKey.publicKey;
    await RepoSync.save(model:newSync);
    /// 添加到isolate
    GitIsolate.share.addRepoSync(newSync);
  }

  addRemote() async{
    var language = L.current(context, listen: false);
    RepoModel? repo;
    List<RepoModel> repoList = Provider.of<RepoListModel>(context, listen:false).repoList;
    for(var r in repoList){
      if(r.key == widget.repoKey){
        repo = r;
        break;
      }
    }
    if(repo == null){ return; }

    setState((){
      status = 'loading';
      title = language.trying_to_connect;
      info = '';
    });
    await GitAction.check(
      repositoryDir: repo.fullPath,
      gitUrl: widget.gitUrl,
      key: widget.sshKey,
      successCallback: (remoteName) async {
        if (kDebugMode) { print('check success !'); }
        _remoteName = remoteName;
        setState((){
          status = 'success';
          title = language.add_success;
          info = '';
        });
        await addSyncToRepo(remoteName);
      },
      failureCallback: (error, remoteName){
        if (kDebugMode) { print('check error:${error.toString()}'); }
        _remoteName = remoteName;
        setState((){
          status = 'error';
          title = language.add_error;
          info = error.toString();
        });
      }
    );
  }

  Widget loadingItem(){
    var colors =  C.current(context);
    return Column(
      children: [
        RotationWidget(
          child: SvgPicture.asset('static/images/state_loading.svg',width: 100,height: 100,color: colors.tintPrimary,),
        ),
        Container(
          padding: const EdgeInsets.only(top: 24),
          child: Text(title, style: TextStyle(color: colors.tintPrimary,fontSize: F.f20),textAlign: TextAlign.center,),
        ),
      ],
    );
  }

  Widget errorItem(){
    var colors =  C.current(context);
    var language = L.current(context);
    return Column(
      children: [
        SvgPicture.asset('static/images/state_failure.svg',width: 100,height: 100,color: colors.tintPrimary),
        Container(
          padding: const EdgeInsets.only(top: 24),
          // color: Colors.red,
          child: Text(title, style: TextStyle(color: colors.tintPrimary,fontSize: F.f20),textAlign: TextAlign.center,),
        ),
        Container(
          padding: const EdgeInsets.only(top: 24,bottom: 31),
          child: Text(info,style: TextStyle(color: colors.tintSecondary,fontSize: F.f18),textAlign: TextAlign.center,),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: (){
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 40,right: 40,top: 13,bottom: 13),
                  color: colors.bgOnBody_2,
                  child: Text(language.go_back,style: TextStyle(color: colors.tintPrimary,fontSize: F.f20),textAlign: TextAlign.center,),
                )
              )
            ),
            const SizedBox(width: 23,),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: (){ addRemote(); },
                child: Container(
                  padding: const EdgeInsets.only(left: 40,right: 40,top: 13,bottom: 13),
                  color: colors.bgOnBody_2,
                  child: Text(language.retry,style: TextStyle(color: colors.tintPrimary,fontSize: F.f20),textAlign: TextAlign.center,),
                )
              )
            )
          ],
        ),
        if(_remoteName != null)  // 如果remoteName为空，则说明彻底添加失败
          Container(
              // borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.only(top: 20),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async{
                await addSyncToRepo(_remoteName);
                /// 返回到同步列表页
                // Navigator.pop(context);//remoteList
                // Navigator.popUntil(context, (route){
                //   return route.settings.name == 'remoteList';
                // });
                Navigator.popUntil(context, ModalRoute.withName(RemoteListPage.routePath));
              },
              child: Container(
                padding: const EdgeInsets.only(left: 40,right: 40,top: 13,bottom: 13),
                child: Text(language.add_anyway,style: TextStyle(color: colors.tintSecondary,fontSize: F.f18,decoration: TextDecoration.underline,),textAlign: TextAlign.center,),
              )
            )
          )
      ],
    );
  }

  Widget successItem(){
    var colors =  C.current(context);
    var language = L.current(context);
    return Column(
      children: [
        SvgPicture.asset('static/images/state_success.svg',width: 100,height: 100,color: colors.tintPrimary,),
        Container(
          padding: const EdgeInsets.only(top: 24,bottom: 31),
          // color: Colors.red,
          child: Text(title, style: TextStyle(color: colors.tintPrimary,fontSize: F.f20),textAlign: TextAlign.center,),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GestureDetector(
            onTap: (){
              Navigator.popUntil(context, ModalRoute.withName(RemoteListPage.routePath));
            },
            child: Container(
              padding: const EdgeInsets.only(left: 40,right: 40,top: 13,bottom: 13),
              color: colors.bgOnBody_2,
              child: Text(language.go_back,style: TextStyle(color: colors.tintPrimary,fontSize: F.f20),textAlign: TextAlign.center,),
            )
          )
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    return WillPopScope(
      child: Container(
        color: colors.bgBodyBase_1,
        child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(status == 'loading')
                    loadingItem(),
                  if(status == 'error')
                    errorItem(),
                  if(status == 'success')
                    successItem(),
                ],
              ),
            )
        ),
      ),
      onWillPop: () async{
        return false;
      }
    );
  }
}


class CustomAnimation extends EasyLoadingAnimation {
  CustomAnimation();

  @override
  Widget buildWidget(
      Widget child,
      AnimationController controller,
      AlignmentGeometry alignment,
      ) {
    return Opacity(
      opacity: controller.value,
      child: RotationTransition(
        turns: controller,
        child: child,
      ),
    );
  }
}

