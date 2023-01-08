/*
1、展示等待授权状态页面
2、新建/选择仓库
3、进度页面
* */
// import 'package:flutter/cupertino.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/pages/git_setup/git_clone_page.dart';
import 'package:provider/provider.dart';
import '../../apis/githost_factory.dart';
import '../../model/ssh_key.dart';
import '../../provider/global_color.dart';
import '../../provider/global_language.dart';
import '../../provider/repo_list_model.dart';
import '../../widgets/common/rotation_widget.dart';
import '../remote_list_page.dart';

/// 能进这个页面，说明已经完成了授权
class RemoteAutoPage extends StatefulWidget {

  final String? repoKey;  /// 如果有repoKey，则为添加同步仓库，如果没有，则为clone
  final GitHost gitHost; /// 此实例从请求授权页面传过来，里面保存了授权的key
  final List<GitHostRepo>? repoList;

  const RemoteAutoPage({Key? key, this.repoKey, required this.gitHost, this.repoList}) : super(key: key);

  @override
  _RemoteAutoPageState createState() => _RemoteAutoPageState();
}

class _RemoteAutoPageState extends State<RemoteAutoPage> with WidgetsBindingObserver{

  late EasyRefreshController _controller;
  List<GitHostRepo>? repoList;
  int refreshState = 1; // -1:刷新失败  0:刷新中  1:刷新成功
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    repoList = widget.repoList;
    _controller = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: false,);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if(repoList == null){
      refreshList();
    }
  }

  Future<bool> refreshList() async{
    setState(() {
      refreshState = 0;
    });
    var list = await widget.gitHost.listRepos();
    if(list.exception != null){
      setState(() {
        refreshState = -1;
        errorMsg = list.exception.toString();
      });
    }else{
      setState(() {
        refreshState = 1;
        repoList = list.data;
        errorMsg = '';
      });
    }
    return list.exception == null;
  }
  /// 设置key
  Future<String?> setSSHKey(GitHostRepo gitRepo, SSHKey key) async{
    var res = await widget.gitHost.addDeployKey(key.publicKey, gitRepo.fullName);
    if(res.exception != null){
      if (kDebugMode) { print(res.exception); }
      return res.exception.toString();
    }
    return null;
  }
  /// clone
  cloneRepo(GitHostRepo gitRepo, SSHKey key){
    var page = GitClonePage(gitUrl: gitRepo.cloneUrl,sshKey: key,);
    Navigator.push(context, MaterialPageRoute(builder: (context)=> page));
  }
  /// add
  Future<String?> addRemote(GitHostRepo gitRepo, SSHKey key) async{
    /// 0、检查当前仓库是否已经添加过该同步链接(仅检查数据库里有没有，如果数据库里没有，但仓库里有，则不管，就当更新key)
    RepoModel r = Provider.of<RepoListModel>(context, listen:false).repoList.where((element) => element.localPath == widget.repoKey).first;
    for(var s in r.syncList){
      if(s.remotePath == gitRepo.cloneUrl){
        return '当前远程仓库已添加！无法重复添加';
      }
    }
    /// 1、添加到本地git仓库与数据库
    var addRes = await r.addRemote(gitUrl: gitRepo.cloneUrl, sshKey: key);
    if(addRes == null){
      if (kDebugMode) { print('添加远程仓库到本地失败'); }
      return 'Add Failure';
    }
    /// 2、转正key
    await key.upgrade(); // 转正
    return null;
  }
  /// 设置key，clone\add
  handleRepo(GitHostRepo gitRepo) async{
    if (kDebugMode) { print(gitRepo); }
    /// 设置key
    var key = await SSHKey.generate(); // 此时的key未转正
    await EasyLoading.show();
    var setKeyRes = await setSSHKey(gitRepo, key);
    await EasyLoading.dismiss();
    if(setKeyRes != null){
      if (kDebugMode) { print(setKeyRes); }
      await EasyLoading.showToast(setKeyRes);
      return;
    }
    /// clone \ add
    if(widget.repoKey == null){
      cloneRepo(gitRepo, key);
    }else{
      await EasyLoading.show();
      var errorMsg = await addRemote(gitRepo, key);
      await EasyLoading.dismiss();
      if(errorMsg != null){
        await EasyLoading.showToast(errorMsg);
      }else{
        Navigator.popUntil(context, ModalRoute.withName(RemoteListPage.routePath));
      }
    }
  }
  /// 创建仓库
  createRepo() async{
    L language = L.current(context,listen: false);
    List<String>? texts = await showTextInputDialog(
      context: context,
      textFields: [
        DialogTextField( hintText: language.enter_a_name, ),
        DialogTextField( hintText: language.enter_description, ),
      ],
      title: language.create_repository,
      message: language.creates_a_new_repository
    );
    if(texts == null){ return; }
    if(texts.first.isEmpty){
      await EasyLoading.showToast(language.the_name_cannot_be_empty);
      return;
    }
    await EasyLoading.show();
    var res = await widget.gitHost.createRepo(texts.first, texts.last);
    await EasyLoading.dismiss();
    var exception = res.exception;
    var gitRepo = res.data;
    if(exception != null){
      await EasyLoading.showToast(exception.toString());
      return;
    }
    if(gitRepo == null){
      await EasyLoading.showToast(language.load_repository_failed);
      return;
    }
    await handleRepo(gitRepo);
  }
  /// 选中仓库
  selectRepo(GitHostRepo? gitRepo) async{
    L language = L.current(context,listen: false);
    if(gitRepo == null){ return; }
    var res = await showOkCancelAlertDialog(context: context, title:language.confirm, message: gitRepo.cloneUrl);
    if(res == OkCancelResult.cancel){ return; }
    await handleRepo(gitRepo);
  }

  Widget bottomWidget(){
    L language = L.current(context,listen: false);
    var colors =  C.current(context);
    if(repoList != null ){ // 如果有数据，则返回可刷新列表
      return EasyRefresh(
        controller: _controller,
        onRefresh: () async {
          var res = await refreshList();
          _controller.finishRefresh(res ? IndicatorResult.success : IndicatorResult.fail);
        },
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                  if(repoList != null && repoList!.isEmpty){
                    return Container(
                      padding: const EdgeInsets.only(left: 15,right: 15,top: 35,bottom: 35),
                      child: Text(language.no_repository,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
                    );
                  }else{
                    var r = repoList?[index];
                    return GestureDetector(
                      onTap: () async{
                        await selectRepo(r);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(border:Border(bottom:BorderSide(width: 1,color: colors.tintSeparator))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r?.cloneUrl ?? '', style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),),
                            if(r != null && r.description.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(r.description, style: TextStyle(color: colors.tintSecondary,fontSize: F.f14),maxLines: 3,overflow:TextOverflow.ellipsis),
                              )
                          ],
                        ),
                      ),
                    );
                  }
                },
                childCount: (repoList != null && repoList!.isEmpty) ? 1 : (repoList?.length ?? 0),
              ),
            ),
          ],
        ),
      );
    }else{
      if(refreshState == 0){
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 30),
              child: RotationWidget(
                child: SvgPicture.asset('static/images/state_loading.svg',width: 60,height: 60,color: colors.tintPrimary),
              )
            )
          ]
        );
      }else if(refreshState == -1){
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 30),
              child: SvgPicture.asset('static/images/state_failure.svg',width: 60,height: 60,),
            ),
            Container(
              padding: const EdgeInsets.only(top: 10,bottom: 15),
              child: Text(language.failed_to_get_the_repository_list, style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
            ),
            if(errorMsg.isNotEmpty)
              Container(
                padding: const EdgeInsets.only(top: 5,left: 15,right: 15, bottom: 15),
                child: Text(errorMsg,style: TextStyle(color: colors.tintSecondary,fontSize: F.f14),textAlign: TextAlign.center,),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: (){ refreshList(); },
                child: Container(
                  padding: const EdgeInsets.only(left: 30,right: 30,top: 10,bottom: 10),
                  color: colors.bgOnBody_2,
                  child: Text(language.retry,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
                )
              )
            )
          ],
        );
      }else{
        return Container();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    return Scaffold(
      appBar: AppBar( //导航栏
        titleSpacing:0,
        title: Text(language.select_or_create, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
        leading: IconButton(
          onPressed: () { Navigator.pop(context); },
          icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
        ),
        backgroundColor: colors.bgBodyBase_1,
        elevation: 0.5,
      ),
      backgroundColor: colors.bgBodyBase_1,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            width: double.infinity,
            decoration: BoxDecoration(border:Border(bottom:BorderSide(width: 1,color: colors.tintSeparator))),
            child: Column(
              children: [
                // Container(
                //   width:double.infinity,
                //   padding: EdgeInsets.only(bottom: 15),
                //   child: Text('新建仓库', textAlign: TextAlign.left,style: TextStyle(color: Color.fromRGBO(83, 83, 83, 1),fontSize: 16),),
                // ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GestureDetector(
                    onTap: () async{
                      await createRepo();
                    },
                    child: Container(
                      color: colors.bgOnBody_2,
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 10,bottom: 10),
                      child: Text(language.click_to_create,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
                    ),
                  ),
                )
              ],
            ),
          ),
          // Container(
          //   padding: EdgeInsets.only(left: 15,right: 15,top: 15),
          //   width: double.infinity,
          //   child: Column(
          //     children: [
          //       Container(
          //         width:double.infinity,
          //         padding: EdgeInsets.only(bottom: 6),
          //         child: Text('远程仓库列表', textAlign: TextAlign.left,style: TextStyle(color: Color.fromRGBO(83, 83, 83, 1),fontSize: 16),),
          //       ),
          //     ],
          //   ),
          // ),
          Expanded(
            child: Container(
              width: double.infinity,
              child: bottomWidget(),
            ),
          )
        ],
      ),
    );
  }

}
