
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../provider/global_color.dart';
import '../widgets/viewer/folder_viewer.dart';

class FileBrowser extends StatefulWidget {
  final String path;

  const FileBrowser({Key? key,  required this.path}) : super(key: key);

  @override
  _FileBrowserState createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);

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
      ),
      backgroundColor: colors.bgBodyBase_2,
      body: SafeArea(
        bottom: false,
        child: FolderViewer(path: widget.path)
      )
    );
  }


}