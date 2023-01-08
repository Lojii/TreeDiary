// import 'package:flutter/cupertino.dart';

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/model/video_item.dart';
import 'package:treediary/provider/setting_model.dart';
import 'package:provider/provider.dart';

import '../model/gps_item.dart';
import '../repo/note_info.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/repo_list_model.dart';
import '../widgets/image_viewer.dart';
import '../widgets/video_player.dart';
import 'map_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:treediary/config/global_data.dart';

class SettingUserInfoPage extends StatefulWidget {

  RepoModel? repo;

  SettingUserInfoPage({Key? key, this.repo}) : super(key: key);

  @override
  _SettingUserInfoPageState createState() => _SettingUserInfoPageState();
}

class _SettingUserInfoPageState extends State<SettingUserInfoPage> with WidgetsBindingObserver{

  bool saveEnable = false;

  late TextEditingController _userNameController;
  late TextEditingController _emailController;

  // late String _userName;
  // late String _email;

  @override
  void initState() {
    // _userName = Provider.of<SettingModel>(context, listen:false).userName;
    // _email = Provider.of<SettingModel>(context, listen:false).userEmail;
    _userNameController = TextEditingController();
    _emailController = TextEditingController();
    if(widget.repo == null){
      _userNameController.text = Provider.of<SettingModel>(context, listen:false).userName;
      _emailController.text = Provider.of<SettingModel>(context, listen:false).userEmail;
    }else{
      _userNameController.text = widget.repo?.userName ?? '';
      _emailController.text = widget.repo?.userEmail ?? '';
    }

    super.initState();
  }

  @override
  dispose(){
    super.dispose();
  }

  bool isEmail(String input) {
    if (input.isEmpty) return false;
    String regexEmail = "^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*\$";
    return RegExp(regexEmail).hasMatch(input);
  }

  save() async{
    var newName = _userNameController.text.trim();
    var newEmail = _emailController.text.trim();
    if(newName.isEmpty || newEmail.isEmpty){
      return;
    }
    // 邮箱判断
    if(!isEmail(newEmail)){
      var language = L.current(context,listen: false);
      EasyLoading.showInfo(language.enter_email_tip);
      return;
    }
    if(widget.repo == null) {
      Provider.of<SettingModel>(context, listen: false).switchUserEmail(newEmail);
      Provider.of<SettingModel>(context, listen: false).switchUserName(newName);
    }else{
      await RepoModel.updateUserInfo(widget.repo!.localPath, userName: newName, userEmail: newEmail);
    }
    Navigator.pop(context);
  }

  Widget itemWidget(bool isUserName){
    var colors =  C.current(context);
    var language = L.current(context);
    return Container(
      padding: const EdgeInsets.only(left: 15,top: 12,bottom: 12,right: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.tintSeparator, width: 0.5,),),),
      child: Row(
        children: [
          Text(isUserName ? '${language.user_name}:' : '${language.user_email}:', style: TextStyle(fontSize:F.f16,color: colors.tintPrimary),),
          const SizedBox(width: 15,),
          Expanded(
            child: TextField(
              controller: isUserName ? _userNameController : _emailController,
              onChanged:(value) {
                var name = widget.repo == null ? Provider.of<SettingModel>(context, listen:false).userName : widget.repo!.userName;
                var email = widget.repo == null ? Provider.of<SettingModel>(context, listen:false).userEmail : widget.repo!.userEmail;
                var newName = _userNameController.text.trim();
                var newEmail = _emailController.text.trim();
                setState((){
                  saveEnable = (name != newName || email != newEmail) && (newName.isNotEmpty && newEmail.isNotEmpty);
                });
              }, // setState((){ searchKey = value; })
              decoration: InputDecoration.collapsed(
                hintText: isUserName ? language.enter_user_name : language.enter_user_email,
                hintStyle:TextStyle(fontSize: F.f16, color: colors.tintPlaceholder),
              ),
              style:TextStyle(fontSize: F.f16,color: colors.tintSecondary),
            )
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(widget.repo == null ? language.global_user_info : '${widget.repo?.name}${language.user_info}', style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
          ),
          backgroundColor: colors.bgBodyBase_1,
          elevation: 0.5,
          actions: <Widget>[
            Container(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () async => { await save() },
                child: Flex(
                  direction: Axis.horizontal,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.only(left: 15,right: 15,top: 5,bottom: 5),
                          color: saveEnable ? colors.tintGitBlue : colors.bgBody_2,
                          child: Text(language.save,style: TextStyle(fontSize: F.f14,color: saveEnable ? colors.solidWhite_1 : colors.tintTertiary),),
                        )
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        backgroundColor: colors.bgBodyBase_1,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    itemWidget(true),
                    itemWidget(false),
                    if(widget.repo == null)
                    Container(
                      padding: const EdgeInsets.only(left: 10,right: 10,top: 14),
                      child: Text(language.user_info_tip,style: TextStyle(color: colors.tintTertiary,fontSize: F.f12)),
                    )
                  ],
                )
            )
        )
    );
  }
}
