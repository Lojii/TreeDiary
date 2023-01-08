// import 'package:flutter/cupertino.dart';

import 'dart:async';
import 'dart:io';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/model/video_item.dart';
import 'package:treediary/pages/remote_list_page.dart';
import 'package:treediary/pages/setting_userinfo_page.dart';
import 'package:provider/provider.dart';

import '../isolate/git_isolate.dart';
import '../model/gps_item.dart';
import '../repo/note_info.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/repo_list_model.dart';
import '../utils/event_bus.dart';
import '../widgets/image_viewer.dart';
import '../widgets/video_player.dart';
import 'main_page.dart';
import 'map_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:treediary/config/global_data.dart';

class NoteSettingPage extends StatefulWidget {
  final String repoKey;

  NoteSettingPage({Key? key, required this.repoKey}) : super(key: key);

  @override
  _NoteSettingPageState createState() => _NoteSettingPageState();
}

class _NoteSettingPageState extends State<NoteSettingPage> with WidgetsBindingObserver{

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose(){
    super.dispose();
  }

  Widget itemWidget(String title, String value, Function action){
    // String title = item['title'] as String;
    // Widget page = item['page'] as Widget;
    var colors =  C.current(context);
    return GestureDetector(
        onTap: (){
          action();
        },
        child: Container(
          padding: const EdgeInsets.only(left: 15,top: 12,bottom: 12,right: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.tintSeparator, width: 0.5,),),),
          child:Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),),
              Expanded(
                child:Container(
                  padding: const EdgeInsets.only(left: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if(value.isNotEmpty)
                        Expanded(
                          child: Text(value,style: TextStyle(color: colors.tintSecondary,fontSize: F.f16),textAlign: TextAlign.right, overflow: TextOverflow.ellipsis,),
                        ),
                      SvgPicture.asset('static/images/right_arrow_item.svg',color: colors.tintSecondary)
                    ],
                  ),
                )
              )
            ]
          )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    var rList = Provider.of<RepoListModel>(context, listen:true).repoList.where((element) => element.localPath == widget.repoKey);
    if(rList.isEmpty){ return Container(); }
    RepoModel repo = rList.first;
    // String userInfo = '';
    // if(widget.repo.userName.isEmpty || widget.repo.userEmail.isEmpty){
    //   userInfo = '使用全局配置';
    // }else{
    //   userInfo = widget.repo.userName + ' ' + widget.repo.userEmail;
    // }
    String syncListStr = language.no_synchronization;
    if(repo.syncList.isNotEmpty){
      if(repo.syncList.length > 1){
        syncListStr = repo.syncList.length.toString();
      }else{
        syncListStr = repo.syncList.first.remotePath;
      }
    }
    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(repo.name, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
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
            // child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if(repo.isDiary)
                itemWidget(language.repository_name,repo.name,() async {
                  List<String>? text = await showTextInputDialog(
                    context: context,
                    textFields: [
                      DialogTextField(
                        hintText: language.enter_a_name,
                        initialText: repo.name,
                      ),
                    ],
                    title: language.repository_name,
                  );
                  if(text == null ){ return; }
                  String newName = '';
                  if(text.isNotEmpty){
                    newName = text.first.trim();
                  }
                  // 弹窗、修改git里的数据、然后同步设置
                  // 修改repo的名称
                  if(newName == repo.name){ return; }
                  // repo.name = newName;
                  await RepoModel.updateConfig(repo.localPath, name: newName);
                  GitIsolate.share.commit(repo.localPath);
                }),
              itemWidget(language.user_info,(repo.userName.isEmpty || repo.userEmail.isEmpty) ? language.global_onfiguration : (repo.userName + ' ' + repo.userEmail),(){
                Navigator.push(context, MaterialPageRoute(builder: (context)=> SettingUserInfoPage(repo: repo,)));
              }),
              itemWidget(language.remote_repository, syncListStr,(){
                Navigator.push(context, MaterialPageRoute(builder: (context)=> RemoteListPage(repoKey: repo.localPath,),settings: RouteSettings(name:RemoteListPage.routePath)));
              }),
              Expanded(child: Container()),
              GestureDetector(
                onTap: () async{
                  var res = await showOkCancelAlertDialog(context: context, title:language.are_you_sure);
                  if(res == OkCancelResult.cancel){
                    return;
                  }
                  await RepoModel.delete(repo.localPath);
                  if(repo.isSelected){
                    Future.delayed(const Duration(seconds: 1),(){ Bus.emit(MainPage.forceRefresh); }); /// 通知首页刷新
                  }
                  Navigator.pop(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.only(left: 60,right: 60,top: 12,bottom: 12),
                    color: colors.bgOnBody_2,
                    child: Text(language.local_repository_delete,style: TextStyle(fontSize: F.f16,color: colors.tintError),),
                  )
                ),
              ),
              Container(height: 23,)
            ],
          )
            // )
        )
    );
  }
}
