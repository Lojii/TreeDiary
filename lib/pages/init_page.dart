import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:fs_shim/fs_io.dart';
import 'package:treediary/generated/l10n.dart';
import 'package:treediary/pages/git_setup/select_git_provider_page.dart';
import 'package:treediary/provider/setting_model.dart';
import 'package:provider/provider.dart';
import 'package:treediary/repo/repo_manager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:treediary/provider/repo_list_model.dart';

import '../config/purchase_manager.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../widgets/store_viewer.dart';
import 'home_page.dart';

class InitPage extends StatefulWidget {

  final bool isFirstPage;

  const InitPage({Key? key, this.isFirstPage = true}) : super(key: key);

  @override
  _InitPageState createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  @override
  void initState() {
    super.initState();
  }
  //
  // toPage(String page){
  //   debugPrint(page);
  //   // RepoManager.createRepo();
  //   var repoList = Provider.of<RepoListModel>(context, listen:false).repoList;
  //   debugPrint('${repoList.length}');
  // }

  Future<bool> _checkEnable() async{
    var repoList = Provider.of<RepoListModel>(context, listen:false).repoList;
    if(repoList.length < 2){ return true; } // 非会员，只允许创建两个个日记本
    if(await LatestReceiptInfos.alreadyPurchase()){ return true; }
    if(await StoreView.show(context) ?? false){ return true; }
    return false;
  }

  toClone() async{
    var isEnable = await _checkEnable();
    if(!isEnable){ return; }
    Navigator.push(context, MaterialPageRoute(builder: (context)=> const SelectGitProviderPage()));
  }

  createRepo() async {
    var isEnable = await _checkEnable();
    if(!isEnable){ return; }

    await EasyLoading.show();
    var repo = await RepoManager.createLocalRepo();
    if(repo == null){
      await EasyLoading.dismiss();
      await EasyLoading.showError('Failed create !');
      return;
    }
    await EasyLoading.dismiss();
    /// 跳转首页Or返回首页
    // if(widget.isFirstPage){
    //   // Navigator.push(context, MaterialPageRoute(builder: (context)=> const HomePage()));
    //   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => route == null);
    // }else{
    //   Navigator.pop(context);
    // }
    if(!widget.isFirstPage){
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    //状态控制是否显示文本组件
    return Scaffold(
      appBar: widget.isFirstPage ? null : AppBar(
        titleSpacing:0,
        title: Text(language.add, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
        leading: IconButton(
          onPressed: () { Navigator.pop(context); },
          icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
        ),
        backgroundColor: colors.bgBody_1,
        elevation: 0.5,
        // actions: <Widget>[
        //   GestureDetector(
        //     behavior: HitTestBehavior.opaque,
        //     onTap: (){
        //       // clickHow();
        //     },
        //     child: Container(
        //       padding: const EdgeInsets.only(right: 10,left: 10),
        //       child: SvgPicture.asset('static/images/how.svg',color: colors.tintPrimary),
        //     ),
        //   )
        // ],
      ),
      backgroundColor: widget.isFirstPage ? colors.bgOnBody_2 : colors.bgBody_1,
      body: Center(
        //添加容器 外框
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CardWidget(title: language.clone_to_local,type: '恢复',bgColor:const Color.fromRGBO(41, 161, 156, 1), onPress: () => toClone()),
            const SizedBox(height: 90),
            CardWidget(title: language.create_a_new_repository,type: '创建',bgColor:const Color.fromRGBO(255, 119, 119, 1), onPress: () => createRepo())
          ],
        ),
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final String? title;
  final String? type;
  final Color? bgColor;
  final VoidCallback? onPress;

  const CardWidget({Key? key, this.title, this.type, this.bgColor, this.onPress}) : super(key: key);

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
