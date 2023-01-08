
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/git/git_action.dart';
import 'package:treediary/model/ssh_key.dart';
import 'package:treediary/widgets/log_widget.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

import '../../provider/global_color.dart';
import '../../provider/global_language.dart';
import '../../provider/repo_list_model.dart';
import '../../repo/repo_manager.dart';
import '../../widgets/common/rotation_widget.dart';
import '../home_page.dart';
/// TODO:此页面不可返回，除非失败，如果成功，则重定向到首页，并选中该仓库，重定向到首页前，检查该仓库是否有名称，如果没有，则弹窗请求用户给一个名称
class GitClonePage extends StatefulWidget {

  final SSHKey? sshKey;
  final String gitUrl;

  const GitClonePage({Key? key, this.sshKey, required this.gitUrl}) : super(key: key);

  @override
  _GitClonePageState createState() => _GitClonePageState();
}

class _GitClonePageState extends State<GitClonePage> with WidgetsBindingObserver{

  // init\loading\error\success
  String status = 'init';
  String title = '';
  String info = '';

  List<String> logs = [];
  bool showLogs = true;

  // bool isFirst = false;

  @override
  void initState(){
    // sshKey
    super.initState();
    // DartWidgetsBinding.instance!.addPostFrameCallback((duration) {});
    Wakelock.enable();
    // var repoList = Provider.of<RepoListModel>(context, listen:false).repoList;
    // isFirst = repoList.isEmpty;
  }

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    clone();
  }
  /// 对空仓库进行初始化
  dealWithRepo(String repoFullPath) async{
    try{
      final repository = Repository.open(repoFullPath);
      if(repository.isEmpty){
        await RepoManager.initRepo(repoFullPath, repository);
      }
    }catch(e){
      if (kDebugMode) { print(e); }
    }
  }

  addToDatabase({required String repoFullPath, String? gitUrl, SSHKey? sshKey}) async{
    await dealWithRepo(repoFullPath);
    var language = L.current(context, listen: false);
    if(repoFullPath.isEmpty){
      setState((){
        status = 'error';
        title = language.clone_error;
        info = language.folder_does_not_exist;
      });
      return;
    }
    await EasyLoading.show(status: language.updating_the_local_index);
    bool res = await RepoManager.createRepo( repoFullPath: repoFullPath, gitUrl:gitUrl, sshKey:sshKey );
    await EasyLoading.dismiss();
    if(res){
      setState((){
        status = 'success';
        title = language.clone_success;
        info = '';
      });
    }else{
      setState((){
        status = 'error';
        title = language.clone_error;
        info = language.update_failed;
      });
      /// 移除已经下载创建的文件夹
      try{
        await Directory(repoFullPath).delete(recursive:true);
      }catch(e){
        if (kDebugMode) { print('addToDatabase failure and delete dir $repoFullPath failure :$e'); }
      }
    }
  }

  clone() async{
    var language = L.current(context, listen: false);
    setState((){
      status = 'loading';
      title = language.cloning;
      info = language.cloning_tip;
    });
    await GitAction.clone(
      gitUrl:widget.gitUrl,
      key:widget.sshKey,
      progressCallback:(progress) {
        if(progress != null){
          setState((){
            logs.add(progress.log);
          });
        }
      },
      successCallback:(repoFullPath) {
        addToDatabase(repoFullPath: repoFullPath ?? '', gitUrl:widget.gitUrl, sshKey:widget.sshKey);
      },
      failureCallback:(errorMsg) {
        setState((){
          status = 'error';
          title = language.clone_error;
          info = errorMsg ?? '';
        });
      }
    );
  }

  Widget loadingItem(){
    var colors =  C.current(context);
    return Container(
      padding: const EdgeInsets.only(left: 15,right: 15),
      child: Row(
        children: [
          RotationWidget(
            child: SvgPicture.asset('static/images/state_loading.svg',width: 50,height: 50,color: colors.tintPrimary,),
          ),
          const SizedBox(width: 15,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.tintPrimary,fontSize: F.f20,fontWeight: FontWeight.w700),),
                Text(info, style: TextStyle(color: colors.tintSecondary,fontSize: F.f18),),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget errorItem(){
    var colors =  C.current(context);
    var language = L.current(context);
    return Container(
      padding: const EdgeInsets.only(left: 15,right: 15),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset('static/images/state_failure.svg',width: 50,height: 50,),
              const SizedBox(width: 15,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: colors.tintPrimary,fontSize: F.f20,fontWeight: FontWeight.w700),),
                    Text(info, style: TextStyle(color: colors.tintSecondary,fontSize: F.f18),),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 25,),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GestureDetector(
                      onTap: (){
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.only(top: 10,bottom: 10),
                        color: colors.bgOnBody_2,
                        child: Text(language.go_back,style: TextStyle(color: colors.tintPrimary,fontSize: F.f18),textAlign: TextAlign.center,),
                      )
                  )
                )
              ),
              const SizedBox(width: 25,),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GestureDetector(
                    onTap: (){ clone(); },
                    child: Container(
                      padding: const EdgeInsets.only(top: 10,bottom: 10),
                      color: colors.bgOnBody_2,
                      child: Text(language.retry,style: TextStyle(color: colors.tintPrimary,fontSize: F.f18),textAlign: TextAlign.center,),
                    )
                  )
                )
              )
            ],
          )
        ],
      )
    );
  }

  Widget successItem(){
    var colors =  C.current(context);
    var language = L.current(context);
    return Container(
        padding: const EdgeInsets.only(left: 15,right: 15),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset('static/images/state_success.svg',width: 50,height: 50,),
                const SizedBox(width: 15,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.clone_success, style: TextStyle(color: colors.tintPrimary,fontSize: F.f20,fontWeight: FontWeight.w700),),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 25,),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GestureDetector(
                      onTap: (){
                        // if(isFirst){
                        //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
                        // }else{
                          Navigator.popUntil(context, (route){ return route.isFirst; });
                        // }
                      },
                      child: Container(
                        padding: const EdgeInsets.only(top: 10,bottom: 10),
                        color: colors.bgOnBody_2,
                        child: Text(language.go_back,style: TextStyle(color: colors.tintPrimary,fontSize: F.f18),textAlign: TextAlign.center,),
                      )
                    )
                  )
                )
              ],
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    return WillPopScope(
        child: Container(
          color: colors.bgBodyBase_1,
          child: SafeArea(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment. start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(showLogs)
                    const SizedBox(height: 70,),
                  if(status == 'loading')
                    loadingItem(),
                  if(status == 'error')
                    errorItem(),
                  if(status == 'success')
                    successItem(),
                  if(showLogs)
                    Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(top: 15),
                          child: LogWidget(logs: logs,),
                        )
                    ),
                  Container(
                      padding:EdgeInsets.only(top:showLogs ? 0 : 20,left: 15,right: 15),
                      width:double.infinity,
                      child:ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
                              behavior:HitTestBehavior.opaque,
                              onTap: (){ setState(() { showLogs = !showLogs; }); },
                              child:Container(
                                  color:colors.bgOnBody_2,
                                  padding:const EdgeInsets.only(top:10,bottom:10,left:30,right:30),
                                  child: Text(showLogs ? language.close_log : language.view_logs,style: TextStyle(color: colors.tintPrimary,fontSize: F.f18),textAlign: TextAlign.center,)
                              )
                          )
                      )
                  ),
                  const SizedBox(height: 30,)
                ],
              )
            ),
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

