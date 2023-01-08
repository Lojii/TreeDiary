import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';

import '../../provider/global_color.dart';
import '../../provider/global_language.dart';
import '../../utils/utils.dart';

class UnknownViewer extends StatefulWidget {
  final String path;

  const UnknownViewer({Key? key, required this.path}) : super(key: key);
  @override
  _UnknownViewerState createState() => _UnknownViewerState();
}

class _UnknownViewerState extends State<UnknownViewer> {

  // 图标，创建时间，修改时间，文件大小，
  String? changeTime;
  String? modificationTime;
  String? fileSize;

  @override
  void initState() {
    super.initState();
    _loadFileDetail();
  }

  _loadFileDetail() async{
    File file = File(widget.path);
    var stat = await file.stat();
    int size = stat.size;
    DateTime modified = stat.modified;
    DateTime changed = stat.changed;

    setState(() {
      modificationTime = modified.toString().split('.').first;
      changeTime = changed.toString();
      fileSize = Utils.bytesConverter(size);
    });
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    L language = L.current(context);
    return Container(
      color: colors.bgBodyBase_1,
      child: Center(
        child: Container(
          padding: const EdgeInsets.only(bottom: 60,left: 60,right: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 150),
                child: SvgPicture.asset('static/images/home_file.svg', width: 150, height: 150,),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(language.file_size, style: TextStyle(color: colors.tintPrimary, fontSize: F.f14),),
                  Text(fileSize ?? '', style: TextStyle(color: colors.tintSecondary, fontSize: F.f14),),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(top: 5, bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(language.modification_time, style: TextStyle(color: colors.tintPrimary, fontSize: F.f14),),
                    Text(modificationTime ?? '', style: TextStyle(color: colors.tintSecondary, fontSize: F.f14),),
                  ],
                )
              ),
              GestureDetector(
                onTap: () async{
                  await EasyLoading.show();
                  await Share.shareFiles([widget.path]);
                  EasyLoading.dismiss();
                },
                child: ClipRRect(
                  borderRadius:BorderRadius.circular(5),
                  child:Container(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    color: colors.bgOnBody_2,
                    width: double.infinity,
                    child: Text(language.open_with_another_app, style: TextStyle(color: colors.tintPrimary, fontSize: F.f16),textAlign: TextAlign.center,),
                  )
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
