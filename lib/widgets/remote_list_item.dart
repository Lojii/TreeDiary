import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:treediary/git/git_action.dart';
import 'package:treediary/isolate/git_isolate.dart';
import 'package:treediary/pages/log_page.dart';
// import 'package:flutter_pickers/time_picker/time_utils.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/note_setting_page.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/repo_list_model.dart';
import '../provider/task_model.dart';
import '../utils/time_utils.dart';

// class RepoItemCard extends StatefulWidget{
//   Repo repo;

class RemoteItemCard extends StatelessWidget {

  final RepoSync syncItem;
  final bool isExpanded;
  final Function expandClick;
  // final Function syncDidClick;
  // final Function deleteDidClick;
  final SyncTask? syncTask;

  const RemoteItemCard({Key? key, required this.syncItem, this.isExpanded = false, required this.expandClick, this.syncTask}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    String buttonTitle = '';
    Color buttonColor = const Color.fromRGBO(41, 161, 156, 1);
    var buttonClick = (){};
    if(syncTask?.state == RepoStateChange.syncing){ /// 同步中:按钮显示状态，无法点击
      buttonTitle = language.syncing;
      buttonColor = Colors.green;
    }else if(syncTask?.state == RepoStateChange.waitingForTheSync){ /// 等待同步中:按钮显示状态，无法点击
      buttonTitle = language.queue;
      buttonColor = Colors.blue;
    }else if(syncTask?.state == RepoStateChange.syncFailure){ /// 同步失败:按钮显示为重试，点击重试
      buttonTitle = language.retry;
      buttonColor = Colors.red;
      buttonClick = (){ GitIsolate.share.sync(syncItem.repoPath, syncItem.remotePath); };
    }else{ /// 显示同步按钮，点击触发同步操作
      buttonTitle = language.sync;
      buttonClick = (){ GitIsolate.share.sync(syncItem.repoPath, syncItem.remotePath); };
    }
    return GestureDetector(
      onTap: () => { expandClick(isExpanded) },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(left: 10,right: 10,top: 10),
        // color: Colors.green,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  alignment:Alignment.center,
                  // height: 50,
                  // color: const Color.fromRGBO(0, 0, 0, 0.05),
                  color: colors.bgOnBody_1,
                  // padding: EdgeInsets.only(right: 10),
                  child: IntrinsicHeight( // 使用IntrinsicHeight包裹Row组件使其自动推测得到高度
                    child:  Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // url、详情
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(left: 10,top: 10,right: 10,bottom: 5), // TODO:没有数量的时候，底部距离调整为10
                                child: Text(syncItem.remotePath, style: TextStyle(fontSize: F.f16, color: colors.tintPrimary),),
                              ),
                              Container(
                                padding: const EdgeInsets.only(left: 10,right: 10,bottom: 10),
                                // color: Colors.red,
                                child: Row(
                                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Text('时间:', style: TextStyle(fontSize: F.f16, fontWeight: FontWeight.w400 ,color: const Color.fromRGBO(83, 83, 83, 1))),
                                    Container(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: SvgPicture.asset('static/images/last_sync_time.svg',color: colors.tintSecondary,width: 20, height: 20,),
                                    ),
                                    Text(TimeUtils.timestampToDateStr(syncItem.lastSyncTime) ?? language.unsynced, style: TextStyle(fontSize: F.f16, fontWeight: FontWeight.w400 ,color: colors.tintSecondary)),
                                  ],
                                ),
                              )
                            ],
                          )
                        ),
                        // 按钮、状态
                        Container(
                          margin: const EdgeInsets.only(top: 10,bottom: 10,right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: GestureDetector(
                              onTap: buttonClick,
                              child: Container(
                                alignment:Alignment.center,
                                padding: const EdgeInsets.only(left: 20,right: 20),
                                color:buttonColor,
                                child: Text(buttonTitle,style: TextStyle(color: colors.solidWhite_1,fontSize: F.f16),),
                              ),
                            )
                          ),
                        )
                      ],
                    )
                  ),
                ),
                AnimatedCrossFade(
                  firstCurve: Curves.easeOutCirc,
                  secondCurve: Curves.easeOutCirc,
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: Container(),
                  secondChild: Container(
                    padding: const EdgeInsets.only(left: 10,top: 0,right: 10,bottom: 10),
                    alignment:Alignment.center,
                    // color: const Color.fromRGBO(0, 0, 0, 0.05),
                    color: colors.bgOnBody_1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 5,),
                        // // time
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     Text('上次同步时间', style: TextStyle(fontSize: F.f16, fontWeight: FontWeight.w400 ,color: const Color.fromRGBO(83, 83, 83, 1))),
                        //     Text('${TimeUtils.timestampToDateStr(syncItem.lastSyncTime)}', style: TextStyle(fontSize: F.f16, fontWeight: FontWeight.w400 ,color: const Color.fromRGBO(151, 151, 151, 1))),
                        //   ],
                        // ),
                        const SizedBox(height: 5,),
                        // auto
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(language.auto_sync, style: TextStyle(fontSize: F.f16, fontWeight: FontWeight.w400 ,color: colors.tintPrimary)),
                            Switch(
                              value: syncItem.isAutoSync,
                              onChanged: (value) async {
                                await RepoSync.switchAutoSync(syncItem.repoPath, syncItem.remotePath, value);
                              }
                            )
                          ],
                        ),
                        // key
                        Column(
                          children: [
                            // if(syncItem.sshKeyId.isNotEmpty)
                              Container(
                              // color: Colors.red,
                              // padding: EdgeInsets.only(left: 15,right: 15),
                                child: Column(
                                    children: [
                                      GestureDetector(
                                          onTap: (){
                                            Clipboard.setData(ClipboardData(text:syncItem.pubKey));
                                            EasyLoading.showToast(language.copied);
                                          },
                                          child: Container(
                                              padding: const EdgeInsets.only(top: 8,bottom: 8,left: 5),
                                              color: colors.bgOnBody_2,
                                              child: Row(
                                                  children: [
                                                    Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            SingleChildScrollView(
                                                                scrollDirection: Axis.horizontal,
                                                                child: Text('Key:${syncItem.sshKeyId.isNotEmpty ? syncItem.pubKey : 'no key'}', style: TextStyle(fontSize: F.f14,color: colors.tintPrimary),maxLines:1)
                                                            ),
                                                            // SingleChildScrollView(
                                                            //     scrollDirection: Axis.horizontal,
                                                            //     child: Container(
                                                            //       padding: EdgeInsets.only(top: 4),
                                                            //       child: Text('SHA256:E/fw2iTV31gz5rXNS7CQK9091gz5rXNS7CQK9091gz5rXNS7CQK9091gz5rXNS7CQK909', style: TextStyle(fontSize: 14,color: colors.tintSecondary),maxLines:1),
                                                            //     )
                                                            // )
                                                          ],
                                                        )
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.only(left: 10,right: 10),
                                                      child: Text(language.copy, style: TextStyle(color: colors.tintPrimary)),
                                                    )
                                                  ]
                                              )
                                          )
                                      ),
                                      Container(height: 8,),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: GestureDetector(
                                                      onTap: (){
                                                        Navigator.push(context, MaterialPageRoute(builder: (context)=> LogPage(repoKey: syncItem.repoPath, gitUrl: syncItem.remotePath,)));
                                                      },
                                                      child: Container(
                                                        color: colors.bgOnBody_2,
                                                        padding: const EdgeInsets.only(top: 10,bottom: 10),
                                                        child: Text(language.view_logs,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
                                                      )
                                                  )
                                              )
                                          ),
                                          const SizedBox( width: 10, ),
                                          Expanded(
                                              child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: GestureDetector(
                                                      onTap: () async {
                                                        var keyUrl = generateSetKeyUrl(syncItem.remotePath);
                                                        if(keyUrl.isNotEmpty){
                                                          try {
                                                            await launchUrl(Uri.parse(keyUrl), mode: LaunchMode.externalApplication,);
                                                          } catch (err) {
                                                            if (kDebugMode) { print('_launchSettingKeyPage: \n$keyUrl'); }
                                                          }
                                                        }else{
                                                          EasyLoading.showToast(language.cannot_access_the_web);
                                                        }
                                                      },
                                                      child: Container(
                                                        color: colors.bgOnBody_2,
                                                        padding: const EdgeInsets.only(top: 10,bottom: 10),
                                                        child: Text(language.set_the_key,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
                                                      )
                                                  )
                                              )
                                          )
                                        ],
                                      )
                                    ]
                                )
                            ),
                            // if(syncItem.sshKeyId.isEmpty)
                            //   Container(
                            //     // padding: const EdgeInsets.only(top: 5),
                            //     child: ClipRRect(
                            //         borderRadius: BorderRadius.circular(10),
                            //         child: GestureDetector(
                            //             onTap: (){  },
                            //             child: Container(
                            //               width: double.infinity,
                            //               color: Color.fromRGBO(239, 243, 246, 1),
                            //               padding: EdgeInsets.only(top: 10,bottom: 10),
                            //               child: Text('创建SSH通讯秘钥',style: TextStyle(color: Color.fromRGBO(83, 83, 83, 1),fontSize: 16),textAlign: TextAlign.center,),
                            //             )
                            //         )
                            //     ),
                            //   )
                          ]
                        ),
                        // del
                        Container(
                          padding: const EdgeInsets.only(top: 10),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: GestureDetector(
                                  onTap: () async {
                                    var res = await showOkCancelAlertDialog(context: context, title:language.are_you_sure,message: language.delete_remote_tip);
                                    if(res == OkCancelResult.cancel){
                                      return;
                                    }
                                    await RepoSync.delete(syncItem.repoPath, syncItem.remotePath);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    color: colors.bgOnBody_2,
                                    padding: const EdgeInsets.only(top: 10,bottom: 10),
                                    child: Text(language.delete,style: TextStyle(color: colors.tintError,fontSize: F.f16),textAlign: TextAlign.center,),
                                  )
                              )
                          ),
                        )
                      ]
                    )
                  )
                )
              ]
            )
        )
      )
    );

  }


  String generateSetKeyUrl(String gitUrl){
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
          if(gitUrl.contains('github.com')){
            return 'https://github.com/$user/$repo/settings/keys/new';
          }else if(gitUrl.contains('gitlab.com')){
            return 'https://gitlab.com/$user/$repo/-/settings/repository';
          }
        }
      }
    }
    return '';
  }
}

