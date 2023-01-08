import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/widgets/substring_highlight.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/global_model.dart';
import '../provider/repo_list_model.dart';

class EditRepos extends StatefulWidget {
  //
  EditRepos({Key? key}) : super(key: key);

  @override
  _EditReposState createState() => _EditReposState();
}

class _EditReposState extends State<EditRepos>{

  _clickRepo(RepoModel repo){
    var language = L.current(context,listen: false);
    var selectRepos = Provider.of<GlobalModel>(context, listen:false).currentEditRepos;
    // var select = selectRepos.contains(repo);
    var select = false;
    for(var r in selectRepos){
      if(r.localPath == repo.localPath){
        select = true;
        break;
      }
    }
    if(select){
      if(selectRepos.length <= 1){
        // 至少需要选择一个日记本
        EasyLoading.showInfo(language.you_need_to_choose_at_least_one);
        return;
      }else{
        selectRepos.removeWhere((element) => element.localPath == repo.localPath);
      }
    }else{
      selectRepos.add(repo);
    }
    Provider.of<GlobalModel>(context, listen:false).editReposChange(selectRepos);
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    var allRepos = Provider.of<RepoListModel>(context, listen:true).repoList.where((element) => element.isDiary).toList();
    return Scaffold(
      backgroundColor: colors.bgBodyBase_1,
      body: SafeArea(
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 导航栏
            Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => {Navigator.pop(context)},
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    child: SvgPicture.asset('static/images/nav_close.svg',width: 30,height: 30,color: colors.tintPrimary,),
                  ),
                ),
                Text(language.select_repository,style: TextStyle(fontSize: F.f16,fontWeight: FontWeight.w700,color: colors.tintPrimary),),
                Container(
                  margin: const EdgeInsets.all(15),
                  width: 30,height: 30,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...allRepos.map((e) => RepoItemWidget(
                      repo: e,
                      onClick: () => {_clickRepo(e)},
                    )).toList()
                  ]
                )
              )
            )
          ]
        )
      )
    );
  }
}

class RepoItemWidget extends StatelessWidget {
  final RepoModel repo;
  final Function? onClick; // 选择

  const RepoItemWidget({Key? key, required this.repo, this.onClick}) : super(key: key);

  _didClick(){
    if(onClick != null){
      onClick!();
    }
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var selectRepos = Provider.of<GlobalModel>(context, listen:true).currentEditRepos;
    var select = false;
    for(var r in selectRepos){
      if(r.localPath == repo.localPath){
        select = true;
        break;
      }
    }
    return GestureDetector(
        onTap: _didClick,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.only(left: 15,right: 15,top: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(repo.name,style: TextStyle(fontSize: F.f16,color: colors.tintPrimary),),
                  SvgPicture.asset(select ? 'static/images/check_box.svg' : 'static/images/check_box_un.svg', color: colors.tintGitBlue,),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                color: colors.tintSeparator,
                height: 0.5,
              )
            ],
          ),
        )
    );
  }
}
