// import 'package:flutter/cupertino.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/git/git_action.dart';
// import 'package:treediary/model/git_host_type.dart';
import 'package:treediary/model/video_item.dart';
import 'package:treediary/pages/git_setup/select_git_provider_page.dart';
import 'package:treediary/pages/setting_userinfo_page.dart';
import 'package:treediary/widgets/remote_list_item.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:ssh_key/ssh_key.dart';
// import 'package:pointycastle/asymmetric/rsa.dart';
// import 'package:pointycastle/key_generators/api.dart';
// import 'package:pointycastle/key_generators/rsa_key_generator.dart';
// import 'package:pointycastle/pointycastle.dart';
// import 'package:pointycastle/random/fortuna_random.dart';

import '../apis/githost_factory.dart';
import '../model/gps_item.dart';
import '../repo/note_info.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/repo_list_model.dart';
import '../provider/task_model.dart';
import '../repo/repo_action.dart';
import '../repo/repo_util.dart';
import '../widgets/image_viewer.dart';
import '../widgets/video_player.dart';
import '../widgets/viewer/empty_viewer.dart';
import 'git_setup/add_remote_page_auto.dart';
import 'git_setup/auth_request_page.dart';
import 'git_setup/add_remote_page_manual.dart';
import 'map_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:treediary/config/global_data.dart';

// import 'package:pointycastle/paddings/pkcs7.dart';

import 'package:basic_utils/basic_utils.dart';
import 'package:ssh_key/ssh_key.dart' as ssh_key;
import 'package:cryptography/cryptography.dart';
import 'package:openssh_ed25519/openssh_ed25519.dart';
import 'dart:convert';
import 'dart:typed_data';

// import 'package:basic_utils/src/CryptoUtils.dart';
// import 'package:pointycastle/ecc/api.dart';

class RemoteListPage extends StatefulWidget {
  static String routePath = "remoteList";

  String repoKey;

  RemoteListPage({Key? key, required this.repoKey}) : super(key: key);

  @override
  _RemoteListPageState createState() => _RemoteListPageState();
}

class _RemoteListPageState extends State<RemoteListPage> with WidgetsBindingObserver{

  List<RepoSync> items = [];
  Map<String,bool> exMap = {};

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

  // refreshRemoteList() async{
  //   var syncList = widget.repo.syncList;
  //   var repoFullPath = widget.repo.fullPath;
  //   var realList = GitAction.loadRemoteList(repoFullPath);
  //   // 有则添加，没有则删除，然后更新设置，
  //   List<RepoSync> needAddList = [];
  //   List<RepoSync> needDelList = [];
  //   for(Map<String, String> rr in realList){
  //     String name = rr['name'] ?? '';
  //     String path = rr['path'] ?? '';
  //     if(path.isEmpty){ continue; }
  //     bool needAdd = true;
  //     for(var s in syncList){
  //       if(s.remotePath == path){
  //         needAdd = false;
  //         break;
  //       }
  //     }
  //     if(needAdd){
  //       // needAddList.add(RepoSync({
  //       //   'type' : '',
  //       //   'remotePath' : path,
  //       //   'state' : '',
  //       //   'lastSyncTime' : '',
  //       //   'lastUpdateTime' : '',
  //       //   'lastCheckTime' : '',
  //       //   'remoteName' : name,
  //       //   'sshKeyId' : ''
  //       // }));
  //     }
  //   }
  //   for(var s in syncList){
  //     bool needDel = true;
  //     for(Map<String, String> rr in realList) {
  //       String name = rr['name'] ?? '';
  //       String path = rr['path'] ?? '';
  //       if (path.isEmpty) { continue; }
  //       if(path == s.remotePath){
  //         needDel = false;
  //         break;
  //       }
  //     }
  //     if(needDel){
  //       needDelList.add(s);
  //     }
  //   }
  //   // print(needAddList);
  //   // print(needDelList.map((e) => e.toMap()).toList());
  //   if(needAddList.isNotEmpty){
  //     Provider.of<RepoListModel>(context, listen:false).addSyncList(widget.repo.key, needAddList);
  //   }
  //   if(needDelList.isNotEmpty){
  //     Provider.of<RepoListModel>(context, listen:false).delSyncList(widget.repo.key, needDelList);
  //   }
  //   // setState((){ items = widget.repo.syncList; });
  // }

  addRemote(RepoModel repo) async{
    var page = SelectGitProviderPage(repoKey: widget.repoKey,);
    Navigator.push(context, MaterialPageRoute(builder: (context)=> page));
  }

  Widget itemWidget(RepoSync item, SyncTask? syncTask){
    return RemoteItemCard(syncItem: item, isExpanded: exMap[item.remoteName] ?? false , syncTask: syncTask, expandClick: (isExpanded){
      setState((){
        for(var key in exMap.keys){
          exMap[key] = false;
        }
        exMap[item.remoteName] = !isExpanded;
      });
    },);
    // return GestureDetector(
    //     onTap: (){
    //       // Navigator.push(context, MaterialPageRoute(builder: (context)=> page));
    //     },
    //     child: Container(
    //         padding: const EdgeInsets.only(left: 15,top: 12,bottom: 12,right: 10),
    //         decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color.fromRGBO(218, 218, 218, 1), width: 0.5,),),),
    //         child:Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //             children: [
    //               Text(item.remotePath,style: TextStyle(color: Color.fromRGBO(83, 83, 83, 1),fontSize: 16),),
    //               SvgPicture.asset('static/images/right_arrow_item.svg')
    //             ]
    //         )
    //     )
    // );
  }

  @override
  Widget build(BuildContext context) {
    // repoKey
    var colors =  C.current(context);
    var language = L.current(context);
    RepoModel repo = Provider.of<RepoListModel>(context, listen:true).repoList.where((element) => element.localPath == widget.repoKey).first;
    var syncTaskMap = Provider.of<TaskModel>(context, listen:true).repoTask[repo.key] ?? {};
    // print('-----------------------------↓');
    // for(var k in syncTaskMap.keys){
    //   var v = syncTaskMap[k];
    //   print('$k - ${v?.state}');
    // }
    // print('-----------------------------↑');
    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(language.repositories, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
          ),
          backgroundColor: colors.bgBody_1,
          elevation: 0.5,
          actions: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: (){
                addRemote(repo);
              },
              child: Container(
                padding: const EdgeInsets.only(right: 10,left: 10),
                child: SvgPicture.asset('static/images/add.svg', color: colors.tintPrimary,),
              ),
            )
          ],
        ),
        backgroundColor: colors.bgBodyBase_2,
        body: SafeArea(
            child:  repo.syncList.isEmpty ? const EmptyViewer(isBox: false,) : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...repo.syncList.map((e) => itemWidget(e, syncTaskMap[e.remotePath])).toList()
                  ],
                )
            )
        )
    );
  }
}
