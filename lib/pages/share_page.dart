
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/model/video_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import '../repo/note_info.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/repo_list_model.dart';
import '../repo/note_resource_info.dart';
import 'package:treediary/config/global_data.dart';
import 'package:share_plus/share_plus.dart';

class SharePage extends StatefulWidget {
  final NoteInfo note;

  const SharePage({Key? key,required this.note}) : super(key: key);

  @override
  _SharePageState createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> with WidgetsBindingObserver{

  List<String> imagePaths = [];
  List<VideoItem> videos = [];
  final GlobalKey imageKey = GlobalKey();
  final GlobalKey scrollKey = GlobalKey();
  final GlobalKey renderKey = GlobalKey();
  double paddingTop = 0;
  bool didChange = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose(){
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if(didChange){ return; }
    didChange = true;
    Future.delayed(const Duration(milliseconds: 300),(){
      if(mounted){
        var imageH = imageKey.currentContext?.size?.height;
        var scrollH = scrollKey.currentContext?.size?.height;
        if(imageH == null || scrollH == null){ return; }
        if(imageH >= scrollH){ return; }
        setState(() {
          paddingTop = (scrollH - imageH) / 2;
        });
      }
    });
  }

  List<Widget> tagItems(){
    List<Widget> tagItems = [];
    for(NoteResourceInfo tag in widget.note.tags){
      if(tag.payload.isEmpty){ continue; }
      Widget item = Container(
        padding: const EdgeInsets.only(right: 5),
        child: Text('#${tag.payload}',style: TextStyle(color: const Color.fromRGBO(200, 200, 200, 1),fontSize: F.f16),),
      );
      tagItems.add(item);
    }
    return tagItems;
  }

  Widget imageItemView(imagePath){
    var w = MediaQuery.of(context).size.width - 20;
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: Image.file(File(imagePath),width: w,fit: BoxFit.cover),
    );
  }

  Widget? addressView(){
    if(widget.note.formatGPS().isNotEmpty) {
      return Container(
        // padding: const EdgeInsets.only(bottom: 10),
        // width: double.infinity,
        child: Text(widget.note.formatGPS(),style: TextStyle(color: const Color.fromRGBO(200, 200, 200, 1),fontSize: F.f14),textAlign: TextAlign.right,),
      );
    }else{
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var language = L.current(context);
    var currentRepo = Provider.of<RepoListModel>(context, listen:false).currentSelectedRepo;
    if(currentRepo == null){ return Container(); }
    String timeTitle = widget.note.notePageFormatTime();
    String yearStr = timeTitle.split('\n').first;
    String dayStr = timeTitle.split('\n').last;
    // print(timeTitle);
    var tags = tagItems();

    if(imagePaths.isEmpty){
      var baseNotePath = Global.repoBaseDir + '/' + (widget.note.repoKey);
      String mdFileName = widget.note.mdKey.split('/').last;
      baseNotePath = '$baseNotePath/${widget.note.mdKey.replaceAll(mdFileName, '')}';
      for(NoteResourceInfo imgPath in widget.note.images){
        if(imgPath.payload.isEmpty){ continue; }
        imagePaths.add('$baseNotePath${imgPath.payload}');
      }
    }
    var imageViews = imagePaths.map((e) => imageItemView(e)).toList();

    var address = addressView();

    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(language.share, style: TextStyle(color: Colors.white, fontSize: F.f20),),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: Colors.white,),
          ),
          backgroundColor: Colors.black,
          elevation: 0.5,//隐藏底部阴影分割线
        ),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                  child: SingleChildScrollView(
                    key:scrollKey,//RepaintBoundary
                    child: Container(
                      padding: EdgeInsets.only(top: paddingTop),
                      child: RepaintBoundary(
                      key:renderKey,
                      child: Container(
                        key: imageKey,
                        color: Colors.transparent,
                        // padding: const EdgeInsets.only(left: 10,right: 10,top: 15,bottom: 10),
                        child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.only(left: 10,right: 10,top: 15,bottom: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      /// time、name
                                      Container(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if(yearStr.isNotEmpty && dayStr.isNotEmpty)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(yearStr, style: TextStyle(color: const Color.fromRGBO(83, 83, 83, 1),fontSize: F.f20, fontWeight: FontWeight.w700),textAlign: TextAlign.left,),
                                                  Text(dayStr, style: TextStyle(color: const Color.fromRGBO(151, 151, 151, 1),fontSize: F.f14),textAlign: TextAlign.left)
                                                ],
                                              ),
                                            // Text(currentRepo.name, style: const TextStyle(color: Color.fromRGBO(151, 151, 151, 0.4),fontSize: 26, fontWeight: FontWeight.w600),textAlign: TextAlign.right)
                                          ],
                                        ),
                                      ),
                                      /// content
                                      if(widget.note.content.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child:Text(widget.note.content, style: TextStyle(color: const Color.fromRGBO(117, 117, 117, 1),fontSize: F.f16, fontWeight: FontWeight.w600),),
                                        ),
                                      /// tags
                                      if(tags.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Row(
                                            children: [...tags,],
                                          ),
                                        ),
                                      /// images
                                      if(imagePaths.isNotEmpty)
                                        ...imageViews,
                                      /// address
                                      // if(address != null)
                                      //   address,
                                      // Text(currentRepo.name, style: const TextStyle(color: Color.fromRGBO(151, 151, 151, 0.4),fontSize: 18, fontWeight: FontWeight.w600)),
                                      Container(
                                        padding: const EdgeInsets.only(bottom: 5),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('《${currentRepo.name}》', style: const TextStyle(color: Color.fromRGBO(151, 151, 151, 0.4),fontSize: 18, fontWeight: FontWeight.w600)),
                                            if(address != null)
                                              address,
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(top: 10,right: 10,bottom: 10),
                                width: double.infinity,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius:BorderRadius.circular(13),
                                        child:SvgPicture.asset('static/images/logo.svg',width: 26,height: 26,color: const Color.fromRGBO(117, 117, 117, 1),)
                                      ),
                                      const SizedBox(width: 10,),
                                      Text(language.app_name,style: const TextStyle(fontSize: 18, color: Color.fromRGBO(117, 117, 117, 1)),textAlign: TextAlign.center,)
                                    ],
                                  ),
                                ),
                              )
                            ],
                          )
                      ),
                    ))
                  ),
                ),
              ),
              Container(
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    bottomItem('static/images/share_save.svg',language.save_pic,() async{
                      await EasyLoading.show();
                      bool success = await RepaintBoundaryUtils.savePhoto(renderKey);
                      await EasyLoading.dismiss();
                      EasyLoading.showToast(success ? language.save_success : language.save_failed);
                    }),
                    bottomItem('static/images/share_markdown.svg',language.save_markdown,() async{ /// TODO:http://textbundle.org/
                      await EasyLoading.show();
                      String mdPath = '${Global.repoBaseDir}/${widget.note.repoKey}/${widget.note.mdKey}';
                      Share.shareFiles([mdPath]);
                      await EasyLoading.dismiss();
                    }),
                    bottomItem('static/images/share_copy.svg',language.copy_content,(){
                      Clipboard.setData(ClipboardData(text:widget.note.content));
                      EasyLoading.showToast(language.copied);
                    }),
                    bottomItem('static/images/share_more.svg',language.more_actions,() async{
                      await EasyLoading.show();
                      String tmpPath = await RepaintBoundaryUtils.captureImage(renderKey);
                      Share.shareFiles([tmpPath], mimeTypes: ['image/jpeg']);
                      await EasyLoading.dismiss();
                    }),
                  ],
                ),
              )
            ],
          ),
        )
    );
  }

  Widget bottomItem(String icon, String title, Function didClick){
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (){ didClick(); },
      child: Container(
        padding: const EdgeInsets.only(bottom: 25,top: 25),
        child: Column(
          children: [
            SvgPicture.asset(icon),
            const SizedBox(height: 10,),
            Text(title, style: const TextStyle(color: Color.fromRGBO(189, 189, 189, 1),fontSize: 14),textAlign: TextAlign.center,),
          ],
        ),
      ),
    );
  }
}

class RepaintBoundaryUtils {
  /// 截屏图片生成图片流ByteData
  static Future<String> captureImage(GlobalKey boundaryKey) async {
    RenderRepaintBoundary? boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
    double dpr = window.devicePixelRatio; // 获取当前设备的像素比
    var image = await boundary!.toImage(pixelRatio: dpr);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);// 将image转化成byte

    var filePath = "";
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    Directory applicationDir = await getTemporaryDirectory();
    bool isDirExist = await Directory(applicationDir.path).exists();
    if (!isDirExist) Directory(applicationDir.path).create();
    // 直接保存，返回的就是保存后的文件
    File saveFile = await File(applicationDir.path + "${DateTime.now().toIso8601String()}.png").writeAsBytes(pngBytes);
    filePath = saveFile.path;
    return filePath;
  }

  //申请存本地相册权限
  static Future<PermissionStatus> getPermission() async {
    if (Platform.isIOS) {
      if (await Permission.photos.status.isDenied) { await [Permission.photos,].request(); }
      return await Permission.photos.status;
    } else {
      if (await Permission.storage.status.isDenied) { await [Permission.storage,].request(); }
      return await Permission.storage.status;
    }
  }

  //保存到相册
  static Future<bool> savePhoto(GlobalKey boundaryKey) async {
    //获取保存相册权限，如果没有，则申请改权限
    PermissionStatus status = await getPermission();
    if (!status.isGranted) { return false; }

    RenderRepaintBoundary? boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
    double dpr = window.devicePixelRatio; // 获取当前设备的像素比
    var image = await boundary!.toImage(pixelRatio: dpr);
    // 将image转化成byte
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    if(byteData == null){ return false; }
    Uint8List images = byteData.buffer.asUint8List();
    if (Platform.isIOS) {
      final result = await ImageGallerySaver.saveImage(images, quality: 60, name: DateTime.now().toIso8601String());
      if(result != null){
        return true;
      }
    } else { //安卓
      final result = await ImageGallerySaver.saveImage(images, quality: 60);
      if (result != null) {
        return true;
      }
    }
    return false;
  }
}
