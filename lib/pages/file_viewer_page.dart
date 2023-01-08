import 'dart:io';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_highlight/themes/atelier-cave-dark.dart';
import 'package:flutter_highlight/themes/atelier-cave-light.dart';
import 'package:flutter_svg/svg.dart';

import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:share_plus/share_plus.dart';
import '../provider/global_color.dart';

import '../provider/global_language.dart';
import '../widgets/common/bottom_sheet.dart';
import '../widgets/common/rotation_widget.dart';
import '../widgets/viewer/highlight_viewer.dart';
import '../widgets/viewer/md_viewer.dart';
import '../widgets/viewer/photo_viewer.dart';
import '../widgets/viewer/unknown_viewer.dart';

List<String> MD_EXTS = ['md', 'markdown'];
List<String> IMG_EXTS = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp',];

class FileViewer extends StatefulWidget {
  final String path;

  const FileViewer({Key? key,  required this.path}) : super(key: key);

  @override
  _FileViewerState createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {

  String fileType = 'unknown';
  bool isLoading = true;
  String? loadErrorMessage;
  String? strData;

  bool isPreview = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  _loadFile() async{
    L language = L.current(context,listen: false);
    if(widget.path.isEmpty){// TODO:访问了非法路径的文件
      setState(() {
        isLoading = false;
        loadErrorMessage = language.load_failed;
      });
    }

    File file = File(widget.path);
    try{
      String str = await file.readAsString();
      // print(str);
      setState(() {
        isLoading = false;
        loadErrorMessage = null;
        strData = str;
      });
    }catch(e){
      // print('file:${widget.path} is not string');
      setState(() {
        isLoading = false;
        loadErrorMessage = null;
      });
    }
  }
  
  _showMenu() async{
    var language = L.current(context, listen: false);
    List<SheetItem> actions = [
      SheetItem(title: language.share, key: 'share'),
    ];
    String suffix = widget.path.toLowerCase().split('.').last;
    if(strData != null && MD_EXTS.contains(suffix)){ // markdown 文件
      
    }
    final result = await showModalFitBottomSheet(context, list: actions);
    if(result == 'share'){
      // Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> SharePage(note: widget.note,)));
    }
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    Widget body = Container();
    String suffix = widget.path.toLowerCase().split('.').last;
    if(isLoading){
      body = Center(
        child: RotationWidget(
          child: SvgPicture.asset('static/images/state_loading.svg',width: 50,height: 50,color: colors.tintPrimary,),
        ),
      );
    }else{
      if(loadErrorMessage != null){
        body = Center(
          child: Container(
            padding: const EdgeInsets.only(left: 30,right: 30),
            child: Text(loadErrorMessage!, style: TextStyle(color: colors.tintPrimary, fontSize: F.f16),),
          )
        );
      }else{
        if(strData != null){ // 文本文件
          if(MD_EXTS.contains(suffix) && isPreview){
            body = MDViewer(mdStr: strData!, basePath: widget.path.replaceAll(widget.path.split('/').last, ''),);
          }else{
            body = HighlightViewer(str: strData!,path: widget.path,);
          }
        }else{ // 非文本文件
          if(IMG_EXTS.contains(suffix)){ // 图片
            body = PhotoViewer(path: widget.path,);
          }else{ // 其他文件，展示文件详情与导出按钮
            body = UnknownViewer(path: widget.path,);
          }
        }
      }
    }

    return Scaffold(
        appBar: AppBar( //导航栏
          title: Text(widget.path.split('/').last,textAlign: TextAlign.right,style: TextStyle(color: colors.tintPrimary, fontSize: F.f18,fontWeight: FontWeight.w600),),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
          ),
          elevation: 0,//隐藏底部阴影分割线
          centerTitle: false,
          titleSpacing:0,
          backgroundColor: colors.bgBodyBase_2,
          actions: [
            if(strData != null && MD_EXTS.contains(suffix))
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: (){
                  setState(() {
                    isPreview = !isPreview;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 10,right: 5),
                  child: SvgPicture.asset(isPreview ? 'static/images/note_code_show.svg' : 'static/images/note_markdown_show.svg', color: colors.tintPrimary)
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async{
                await EasyLoading.show();
                await Share.shareFiles([widget.path]);
                EasyLoading.dismiss();
              },
              child: Container(
                padding: const EdgeInsets.only(left: 10,right: 15),
                child: SvgPicture.asset('static/images/home_item_more.svg', color: colors.tintPrimary, width: 26, height: 26,)
              ),
            ),

          ],
        ),
        backgroundColor: colors.bgBodyBase_2,
        body: SafeArea(
          bottom: false,
          child: body
        )
    );
  }
}
