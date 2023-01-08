import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:vibration/vibration.dart';

import '../../provider/global_color.dart';
import '../../utils/utils.dart';

class PhotoViewer extends StatefulWidget {
  final String path;

  const PhotoViewer({Key? key, required this.path}) : super(key: key);
  @override
  _PhotoViewerState createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    File file = File(widget.path);
    var body = PhotoView(
      imageProvider: FileImage(file),
      backgroundDecoration: BoxDecoration( color: colors.bgBodyBase_2, ),
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: PhotoViewComputedScale.contained * 3,
      initialScale: PhotoViewComputedScale.contained * 1,
    );
    return ClipRect(
      child:GestureDetector(
        onLongPress: () async{
          if(await Vibration.hasVibrator() ?? false) { Vibration.vibrate(duration:50, pattern: [40, 500,], amplitude: 255, intensities:  [255]); }
          await Utils.showSavePhotoSheet(context, widget.path);
        },
        child: Container(
          color: colors.bgBodyBase_2,
          child: body,
        )
      )
    );
  }
}
