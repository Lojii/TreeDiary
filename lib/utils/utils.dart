
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui show ImageFilter, Gradient, Image, Color;
import 'dart:typed_data';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:vibration/vibration.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'dart:async';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../widgets/common/bottom_sheet.dart';


extension BytesConverter on int {
  String convertToBytes() {
    return Utils.bytesConverter(this);
  }
}


extension CharacterLimiter on String {
  String toLimit(int index) {
    return length >= index ? substring(0, index) : this;
  }
}


class Utils{

  static String bytesConverter(int bytes) {
    /// List of suffixes.
    List<String> types = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];

    /// Length of characters.
    int length = bytes.toString().length;

    if (length < 4) {
      return '$bytes ${types[0]}';
    } else {
      int index = length ~/ 3;
      String value = '${bytes / pow(1024, index)}';
      String prefix = value.contains('.') ? value.split('.').first : '$bytes';
      String suffix = value.contains('.') ? '.' + value.split('.').last : '';
      return '$prefix${suffix.toLimit(3)} ${types[index]}';
    }
  }

  static showPhoto(BuildContext context, String? url ){
    C colors = C.current(context, listen: false);
    if(url != null && url.isNotEmpty){
      ImageProvider? provider;
      if(url.toLowerCase().startsWith('http://') || url.toLowerCase().startsWith('https://')){
        provider = NetworkImage(url);
      }else{
        provider = FileImage(File(url));
      }
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor:Colors.transparent,
              elevation:0.0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 24.0),
              child: GestureDetector(
                onTap: (){ Navigator.pop(context); },
                onLongPress: () async{
                  if(await Vibration.hasVibrator() ?? false) { Vibration.vibrate(duration:50, pattern: [40, 500,], amplitude: 255, intensities:  [255]); }
                  await showSavePhotoSheet(context, url);
                },
                child: PhotoView(
                    backgroundDecoration: const BoxDecoration( color: Colors.transparent, ),
                    tightMode: true,
                    imageProvider: provider,
                    gestureDetectorBehavior:HitTestBehavior.opaque
                ),
              ),
            );
          }
      );
    }
  }

  static showSavePhotoSheet(BuildContext context, String? url) async{
    L language = L.current(context, listen: false);

    String? save = await showModalFitBottomSheet(context, list: [
      SheetItem(title: language.save_pic, key: 'save'),
    ]);
    if(save != null && save == 'save'){
      var res = await savePhoto(url: url);
      EasyLoading.showToast(res ? language.save_success : language.save_failed);
    }
  }


  //保存到相册 参数三选一
  static Future<bool> savePhoto({String? url, ui.Image? image, GlobalKey? boundaryKey}) async {
    PermissionStatus status = await getPhotosAddOnlyPermission();
    if (!status.isGranted) { return false; }

    Uint8List? imageData;

    if(url != null && url.isNotEmpty){
      if(url.toLowerCase().startsWith('http://') || url.toLowerCase().startsWith('https://')) {// 网络数据
        await EasyLoading.show();
        if(url.toLowerCase().endsWith('.gif') || url.toLowerCase().contains('.gif?')){ // gif, 额外处理
          var appTmpDir = await getTemporaryDirectory();
          var tmpFilePath = appTmpDir.path + "/temp${DateTime.now().millisecondsSinceEpoch}.gif";
          await Dio().download(url, tmpFilePath);
          if(await File(tmpFilePath).exists()){
            final result = await ImageGallerySaver.saveFile(tmpFilePath);
            EasyLoading.dismiss();
            if (result['isSuccess']) { return true; }
          }
        }else{
          var response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
          imageData = Uint8List.fromList(response.data);
          EasyLoading.dismiss();
        }
      }else{// 沙盒数据
        if(await File(url).exists()){
          final result = await ImageGallerySaver.saveFile(url);
          if (result['isSuccess']) { return true; }
        }
      }
    }
    // 截图数据
    if(boundaryKey != null){
      double dpr = window.devicePixelRatio; // 获取当前设备的像素比
      RenderRepaintBoundary? boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      if(boundary != null){
        var tmpImg = await boundary.toImage(pixelRatio: dpr);
        ByteData? byteData = await tmpImg.toByteData(format: ImageByteFormat.png);
        if(byteData != null){
          imageData = byteData.buffer.asUint8List();
        }
      }
    }
    // 原始数据
    if(image != null){
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      if(byteData != null){
        imageData = byteData.buffer.asUint8List();
      }
    }
    if(imageData != null){
      final result = await ImageGallerySaver.saveImage(imageData, quality: 100, name: DateTime.now().toIso8601String());
      if (result['isSuccess']) { return true; }
    }
    return false;
  }

  //申请存本地相册权限
  static Future<PermissionStatus> getPhotosAddOnlyPermission() async {
    if (Platform.isIOS) {
      if (await Permission.photosAddOnly.status.isDenied) { await [Permission.photosAddOnly,].request(); }
      return await Permission.photosAddOnly.status;
    } else {
      if (await Permission.storage.status.isDenied) { await [Permission.storage,].request(); }
      return await Permission.storage.status;
    }
  }

  //申请本地相册读取权限
  static Future<PermissionStatus> getPhotosPermission() async {
    if (Platform.isIOS) {
      if (await Permission.photos.status.isDenied) { await [Permission.photos,].request(); }
      return await Permission.photos.status;
    } else {
      if (await Permission.storage.status.isDenied) { await [Permission.storage,].request(); }
      return await Permission.storage.status;
    }
  }

  //申请摄像头权限
  static Future<PermissionStatus> getCameraPermission() async {
    if (await Permission.camera.status.isDenied) { await [Permission.camera,].request(); }
    return await Permission.camera.status;
  }

}