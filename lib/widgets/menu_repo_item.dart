import 'package:flutter/material.dart';
import 'package:treediary/isolate/git_isolate.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/global_data.dart';
import '../pages/note_setting_page.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/repo_list_model.dart';
import '../provider/task_model.dart';
import '../utils/event_bus.dart';

// class RepoItemCard extends StatefulWidget{
//   Repo repo;

class RepoItemCard extends StatelessWidget {
  final RepoModel repo;
  final Map<String, SyncTask>? syncMap; //

  const RepoItemCard({Key? key, required this.repo, this.syncMap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    // print('RepoItemCard build');
    // var syncStateList = Provider.of<TaskModel>(context, listen:true).repoTask[repo.key] ?? {};
    // for(var v in syncStateList.values){
    //   print(v.state);
    // }
    return GestureDetector(
      onTap: () async {
        if(repo.isSelected){ // 展开，关闭
          await RepoModel.expand(repo.localPath);
        }else{ // 选中
          await RepoModel.select(repo.localPath);
          Bus.emit(Global.busRepoDidChange, repo);
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 15,right: 15,top: 5),
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: repo.isSelected ? colors.bgGitBlue : colors.bgOnBody_2,
            child: Column(
              children: [
                Container(
                  alignment:Alignment.center,
                  color: repo.isSelected ? colors.bgGitBlue : colors.bgOnBody_2,
                  child: Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 树名称
                      Expanded(child: Container(
                        child: Text(repo.name, style: TextStyle(fontSize: F.f16, color: repo.isSelected ? colors.solidWhite_1 : colors.tintPrimary, fontWeight: FontWeight.w500),),
                        padding: const EdgeInsets.only(left: 15,top: 10,bottom: 10),
                      )),
                      // 箭头
                      GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async => {
                            await RepoModel.expand(repo.localPath)
                          },
                          child:Container(
                            padding: const EdgeInsets.all(15),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              transform: Matrix4.rotationZ(repo.isExpanded ? 3.14159265359 : 0),
                              transformAlignment: Alignment.center,
                              child: SvgPicture.asset('static/images/menu_arrow.svg',color: repo.isSelected ? colors.solidWhite_2 : colors.tintSecondary,),
                            ),
                          )
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                    firstCurve: Curves.easeOutCirc,
                    secondCurve: Curves.easeOutCirc,
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: repo.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Container(),
                    secondChild: Container(
                      padding: const EdgeInsets.only(left: 15,top: 0,bottom: 10),
                      alignment:Alignment.center,
                      color: repo.isSelected ? colors.bgGitBlue : colors.bgOnBody_2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if(repo.syncList.isNotEmpty)
                            ...repo.syncList.map((s) => RepoSyncRow(remotePath: s.remotePath,state: syncMap?[s.remotePath]?.state,didSelected:repo.isSelected,)).toList(),
                          if(repo.syncList.isEmpty)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Text(language.synchronization_is_not_set, style: TextStyle(fontSize: F.f12, fontWeight: FontWeight.w400 ,color: repo.isSelected ? colors.solidWhite_2 : colors.tintTertiary)),
                                )
                              ],
                            ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> NoteSettingPage(repoKey: repo.localPath,)));
                            },
                            child:ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child:Container(
                                color: colors.bgGitYellow,
                                padding: const EdgeInsets.only(left: 15,right: 15,top: 5,bottom: 5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset('static/images/menu_edit.svg',color: colors.solidWhite_1,),
                                    const SizedBox(width: 5,),
                                    Text(language.edit, style: TextStyle(fontSize: F.f12,color: colors.solidWhite_1)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                )
              ],
          )
          )
        ),
      ),
    );

  }
}

class RepoSyncRow extends StatelessWidget {
  final String remotePath;
  final RepoStateChange? state; // 不可用、同步中、同步失败、同步成功
  final String type;
  final bool didSelected;
  final Function? click;

  const RepoSyncRow({Key? key, this.remotePath = '', this.state, this.type = 'git', this.didSelected = false, this.click }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    Color indicatorColor = colors.solidGray_1;
    if(state == RepoStateChange.done){}
    // sync
    if(state == RepoStateChange.syncing){ // 同步中
      indicatorColor = colors.tintWarming;
    }
    if(state == RepoStateChange.waitingForTheSync){ // 等待同步
      indicatorColor = colors.tintGitBlue;
    }
    if(state == RepoStateChange.syncSuccess){ // 同步成功
      indicatorColor = colors.tintSuccess;
    }
    if(state == RepoStateChange.syncFailure){ // 同步失败
      indicatorColor = colors.tintError;
    }
    // check
    // if(state == RepoStateChange.checking){ // 检查中
    //   indicatorColor = Colors.green;
    // }
    // if(state == RepoStateChange.waitingForTheCheck){ // 等待检查
    //   indicatorColor = Colors.blue;
    // }
    // if(state == RepoStateChange.checkSuccess){ // 检查成功
    //   indicatorColor = const Color.fromRGBO(171, 255, 119, 1);
    // }
    // if(state == RepoStateChange.checkFailure){ // 检查失败
    //   indicatorColor = const Color.fromRGBO(255, 119, 119, 1);
    // }
    return  Container(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child:Container(
                width: 6,
                height: 6,
                color: indicatorColor,
              )
          ),
          const SizedBox(width: 5),
          Expanded(
            // child: Container(
              // padding: const EdgeInsets.only(top: 4,bottom: 4),
              child:Text(remotePath, style: TextStyle(fontSize: F.f12,color: didSelected ? colors.solidWhite_1 : colors.tintSecondary)),
            // ),
          )
        ],
      ),
    );
    // return GestureDetector(
    //   onTap: (){
    //     if(click != null){
    //       click!(remotePath);
    //     }
    //   },
    //   child: Container(
    //     padding: const EdgeInsets.only(bottom: 15),
    //     child: Row(
    //       children: [
    //         ClipRRect(
    //             borderRadius: BorderRadius.circular(3),
    //             child:Container(
    //               width: 6,
    //               height: 6,
    //               color: indicatorColor,
    //             )
    //         ),
    //         const SizedBox(width: 5),
    //         Expanded(
    //           child: Container(
    //             // padding: const EdgeInsets.only(top: 4,bottom: 4),
    //             child:Text(remotePath, style: TextStyle(fontSize: F.f12,color: didSelected ? colors.solidWhite_1 : colors.tintSecondary)),
    //           ),
    //         )
    //       ],
    //     ),
    //   ),
    // );
  }
}

class RepoAddCard extends StatelessWidget{

  final VoidCallback? onPress;
  const RepoAddCard({Key? key, this.onPress,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    return Container(
      margin: const EdgeInsets.only(left: 15,right: 15,top: 5),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: colors.bgOnBody_2,
            child: Container(
              alignment:Alignment.center,
              height: 50,
              child: Flex(
                direction: Axis.horizontal,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    child: SvgPicture.asset('static/images/menu_add.svg',color: colors.tintPrimary,),
                  ),
                  Container(
                    child: Text(language.add, style: TextStyle(fontSize: F.f16, color: colors.tintPrimary, fontWeight: FontWeight.w500),),
                    padding: const EdgeInsets.only(left: 5,top: 10,bottom: 10),
                  ),
                ],
              ),
            )
          ),
        ),
      ),
    );

  }
}
