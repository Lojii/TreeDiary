import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/pages/setting_page.dart';
import 'package:provider/provider.dart';

import '../config/purchase_manager.dart';
import '../isolate/git_isolate.dart';
import '../provider/global_color.dart';
import '../provider/repo_list_model.dart';
import '../provider/setting_model.dart';
import '../provider/task_model.dart';
import '../widgets/dark_light_switcher.dart';
import '../widgets/menu_repo_item.dart';
import '../widgets/store_viewer.dart';
import 'init_page.dart';
// 心有灵犀 起冲突
class MenuDrawer extends StatefulWidget{
  const MenuDrawer({Key? key}) : super(key: key);

  @override
  MenuDrawerState createState() => MenuDrawerState();
}

class MenuDrawerState extends State <MenuDrawer>{

  _pushInitPage(){
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context)=> const InitPage(isFirstPage:false)));
  }

  toAddRepoPage() async{
    _pushInitPage();
  }

  toSettingPage(){
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context)=> SettingPage()));
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var repoList = Provider.of<RepoListModel>(context, listen:true).repoList;
    var repoTask = Provider.of<TaskModel>(context, listen:true).repoTask;
    var idDark = Provider.of<SettingModel>(context, listen:true).theme == 'dark';
    var repoUserName = Provider.of<RepoListModel>(context, listen:true).currentSelectedRepo?.userName ?? "";
    var settingUserName = Provider.of<SettingModel>(context, listen:true).userName;
    String showUserName = repoUserName;
    if(repoUserName.isEmpty){
      showUserName = settingUserName;
      if(settingUserName.isEmpty){
        showUserName = 'Planting';
      }
    }
    return Drawer(
      backgroundColor: colors.bgBody_1,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 20,right: 15,top: 10,bottom: 10), //容器内补白
              child: Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(showUserName,style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600, color: colors.tintPrimary),),
                  GestureDetector(
                    onTap: (){ Provider.of<SettingModel>(context, listen:false).switchTheme(null); },
                    child: Image(image: AssetImage(idDark ? "static/images/light@3x.png" : "static/images/dark@3x.png"), width: 50.0),
                  )
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                // child: _repoListRadio(repoList),
                child: Column(
                  children: [
                    ...repoList.map((e) => RepoItemCard(repo: e,syncMap: repoTask[e.key],)).toList(),
                    RepoAddCard(onPress: () {

                      toAddRepoPage();
                    })
                  ],
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: toSettingPage,
              child: Container(
                padding: const EdgeInsets.only(left: 15,right: 15),
                height: 60,
                child: SvgPicture.asset('static/images/menu_setting.svg',color: colors.tintSecondary,),
              )
            )
          ],
        ),
      ),
    );
  }

}


class RepoCardWidget extends StatelessWidget {
  final String? title;
  final String? type;
  final Color? bgColor;
  final VoidCallback? onPress;

  const RepoCardWidget({Key? key, this.title, this.type, this.bgColor, this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: bgColor,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Positioned(
                child: Text(type ?? '', style: const TextStyle(color: Color.fromRGBO(239, 243, 246, 0.1),fontSize: 99.0),textAlign: TextAlign.right),
                top: -20,
                right: -10,
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 50,horizontal: 10),
                // margin: const EdgeInsets.symmetric(vertical: 50,horizontal: 0),
                // constraints: const BoxConstraints( minWidth: 257,),
                width: 257,
                child: Text(title ?? '',
                  style: TextStyle(color: Colors.white,fontSize: F.f18),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}

// Visibility(
// maintainState: false,
// visible:false,
// child: Text("Visibility组件"),
// )