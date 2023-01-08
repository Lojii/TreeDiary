
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/model/video_item.dart';
import 'package:treediary/pages/share_page.dart';
import 'package:provider/provider.dart';

import '../isolate/git_isolate.dart';
import '../model/gps_item.dart';
import '../provider/setting_model.dart';
import '../repo/note_info.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../repo/note_resource_info.dart';
import '../utils/event_bus.dart';
import '../widgets/common/bottom_sheet.dart';
import '../widgets/image_viewer.dart';
import '../widgets/video_player.dart';
import 'map_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:treediary/config/global_data.dart';

class NotePage extends StatefulWidget {

  final NoteInfo note;

  const NotePage({Key? key,required this.note}) : super(key: key);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> with WidgetsBindingObserver{

  List<String> imagePaths = [];
  List<VideoItem> videos = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose(){
    super.dispose();
  }

  // 图片
  previewImage(String path){
    ImageViewer.show(context: context, index: imagePaths.indexOf(path),pics: imagePaths);
  }

  Widget imageItemView(imagePath){
    return GestureDetector(
        onTap: () => previewImage(imagePath),
        child:ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Hero(
                  tag: imagePath,
                  // child: Image(image: AssetImage(imagePath),width: 108,height: 108,fit: BoxFit.cover),
                  child:Image.file(File(imagePath), width: 108,height: 108,fit: BoxFit.cover,)
                )
              ],
            )
        )
    );
  }
  // 视频
  playVideo(VideoItem video){
    Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> VideoPlayer(videoPath: video.path,)));
  }
  Widget videoItemView(VideoItem video){
    return GestureDetector(
        onTap: () => playVideo(video),
        child:ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Container(
                  color: Colors.black12,
                  child:Image.file(File(video.thumbPath!),width: 345,height: 208,fit: BoxFit.contain),
                ),
                SvgPicture.asset('static/images/video_play.svg'),
              ],
            )
        )
    );
  }
  // 位置
  getLocation() async {
    bool needMap = Provider.of<SettingModel>(context, listen:false).needMap;
    if(!needMap){
      if (kDebugMode) { print('限制地图功能'); }
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context)=>  MapPage(isEdit: false, gps: GPSItem(longitude: widget.note.longitude,latitude: widget.note.latitude),)));
  }
  Widget mapItemView(){
    LatLng? centerLatLng;
    if(widget.note.latitude.isNotEmpty && widget.note.longitude.isNotEmpty){
      centerLatLng = LatLng(double.parse(widget.note.latitude), double.parse(widget.note.longitude));
    }
    if(centerLatLng == null){
      return Container();
    }
    return Container(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
          onTap: () => { getLocation() },
          child:ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Container(
                      color: Colors.black12,
                      // width: 345,
                      height: 208,
                      child:IgnorePointer(
                        child:FlutterMap(
                          options: MapOptions(
                            center: centerLatLng,
                            interactiveFlags: InteractiveFlag.none,
                            zoom: 16,
                            maxZoom:17,
                            minZoom: 3,
                          ),
                          nonRotatedChildren: [
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  color: const Color.fromRGBO(255, 255, 255, 0.4),
                                  padding: const EdgeInsets.all(2),
                                  child: Text("© OpenStreetMap contributors", style: TextStyle(color: Colors.black87,fontSize: F.f12),),
                                )
                            )
                          ],
                          layers: [
                            TileLayerOptions(
                                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                                tileProvider: CachedTileProvider(),
                            ),
                            MarkerLayerOptions(
                              markers: [
                                Marker(
                                  width: 100.0,
                                  height: 100.0,
                                  point: centerLatLng,
                                  builder: (ctx) => Container(
                                    padding: const EdgeInsets.only(bottom: 50),
                                    child: SvgPicture.asset('static/images/map_pin.svg',height: 50,),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                  )
                ],
              )
          )
      ),
    );
  }

  List<Widget> tagItems(){
    var colors =  C.current(context);
    List<Widget> tagItems = [];
    for(NoteResourceInfo tag in widget.note.tags){
      if(tag.payload.isEmpty){ continue; }
      Widget item = Text('#${tag.payload}',style: TextStyle(color: colors.tintSecondary,fontSize: F.f14),);
      tagItems.add(item);
    }
    return tagItems;
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    if(imagePaths.isEmpty){
      var baseNotePath = Global.repoBaseDir + '/' + (widget.note.repoKey);
      String mdFileName = widget.note.mdKey.split('/').last;
      baseNotePath = '$baseNotePath/${widget.note.mdKey.replaceAll(mdFileName, '')}';
      for(NoteResourceInfo imgPath in widget.note.images){
        if(imgPath.payload.isEmpty){ continue; }
        imagePaths.add('$baseNotePath${imgPath.payload}');
      }
    }
    // if(videos.isEmpty){
    //   var baseNotePath = Global.repoBaseDir + '/' + (widget.note.repoKey ?? '');
    //   String mdFileName = widget.note.mdKey.split('/').last ?? '';
    //   baseNotePath = '$baseNotePath/${widget.note.mdKey.replaceAll(mdFileName, '')}';
    //   for(int i = 0; i < (widget.note.videos.length ?? 0); i++){
    //     String videoPath = baseNotePath + widget.note.videos![i];
    //     String previewPath = baseNotePath + widget.note.videoPreviews![i];
    //     videos.add(VideoItem(path: videoPath, thumbPath: previewPath));
    //   }
    // }
    var tags = tagItems();
    var imageViews = SizedBox(
      width: MediaQuery.of(context).size.width - 30,
      child: Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: imagePaths.map((e) => imageItemView(e)).toList(),
      ),
    );
    // var videoViews = Container(
    //   padding: const EdgeInsets.only(top: 15),
    //   width: MediaQuery.of(context).size.width - 30,
    //   child: Wrap(
    //       spacing: 10.0,
    //       runSpacing: 10.0,
    //       children: videos.map((e) => videoItemView(e)).toList(),
    //   ),
    // );
    String timeTitle = widget.note.notePageFormatTime();
    String yearStr = timeTitle.split('\n').first;
    String dayStr = timeTitle.split('\n').last;
    return Scaffold(
        appBar: AppBar( //导航栏
            titleSpacing:0,
          title: GestureDetector(
              onTap: () => {},
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(yearStr, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w600),),
                    Text(dayStr, style: TextStyle(fontSize: F.f14,color: colors.tintPrimary),),
                  ],
                )
              )
          ),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
          ),
          backgroundColor: colors.bgBody_1,
          elevation: 0.5,//隐藏底部阴影分割线
          actions: <Widget>[ //导航栏右侧菜单
            // Column(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     ClipRRect(
            //       borderRadius: BorderRadius.circular(10),
            //       child: Container(
            //         padding: const EdgeInsets.all(3),
            //         decoration: BoxDecoration(
            //           borderRadius: BorderRadius.all(Radius.circular(10)),
            //           border: Border.all(width: 1, color: Color.fromRGBO(218, 218, 218, 1)),
            //         ),
            //         child: Row(
            //           children: [
            //             ClipRRect(
            //               borderRadius: BorderRadius.circular(8),
            //               child: Container(
            //                 padding:EdgeInsets.only(left: 5,right: 5),
            //                 // color: Color.fromRGBO(218, 218, 218, 0.6),
            //                 child: SvgPicture.asset('static/images/note_show.svg'),
            //               ),
            //             ),
            //             Container(
            //               width: 10,
            //             ),
            //             ClipRRect(
            //               borderRadius: BorderRadius.circular(8),
            //               child: Container(
            //                 padding:EdgeInsets.only(left: 5,right: 5),
            //                 color: Color.fromRGBO(218, 218, 218, 0.6),
            //                 child: SvgPicture.asset('static/images/note_markdown_show.svg'),
            //               )
            //             )
            //           ],
            //         ),
            //       )
            //     ),
            //   ],
            // ),
            GestureDetector(
              onTap: () async{
                final result = await showModalFitBottomSheet(context, list: [SheetItem(title: language.share, key: 'share'),SheetItem(title: language.delete, key: 'delete')]);
                if(result == 'delete'){
                  await EasyLoading.show();
                  bool res = await widget.note.delete();
                  await EasyLoading.dismiss();
                  if(res){
                    GitIsolate.share.commit(widget.note.repoKey);
                    Bus.emit('mainPageRefresh',{'new':null, 'old':widget.note});
                  }
                  Navigator.pop(context);
                }
                if(result == 'share'){
                  Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> SharePage(note: widget.note,)));
                }
              },
              child: Container(
                // color: Colors.red,
                padding: const EdgeInsets.only(left: 10,right: 10),
                child: SvgPicture.asset('static/images/note_menu.svg',width: 26,height: 26,color: colors.tintPrimary,),
              ),
            ),

          ],
        ),
        backgroundColor: colors.bgBody_1,
        body: SafeArea(
          // top: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 15,right: 15,top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(tags.isNotEmpty)
                        Container(
                          // color: Colors.grey,
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Wrap(
                              spacing: 5.0,
                              children: [ ...tags ],
                            )
                        ),
                      if(widget.note.content.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Text(
                            widget.note.content,
                            style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),
                          ),
                        ),
                      if(imagePaths.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: imageViews,
                        ),
                      // videoViews,
                      mapItemView(),
                    ],
                  )
              )
            ],
          ),
        )
    );
  }
}
