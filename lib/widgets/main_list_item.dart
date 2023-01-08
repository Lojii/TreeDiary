import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:treediary/config/global_data.dart';
import 'package:treediary/repo/note_info.dart';
import 'package:treediary/repo/note_resource_info.dart';
import 'package:treediary/widgets/video_player.dart';

import '../isolate/git_isolate.dart';
import '../pages/note_page.dart';
import '../pages/share_page.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../utils/event_bus.dart';
import 'common/bottom_sheet.dart';
import 'common/highlight_text.dart';
import 'image_viewer.dart';

/// 简单列表项
class MainListItem extends StatelessWidget {

  final NoteInfo note;
  final List<String>? highLightTexts;

  const MainListItem({Key? key,required this.note, this.highLightTexts}) : super(key: key);

  List<Widget> tagItems(BuildContext context){
    var colors =  C.current(context);
    List<Widget> tagItems = [];
    for(NoteResourceInfo tag in note.tags){
      if(tag.payload.isEmpty){ continue; }
      Widget item = Text('#${tag.payload}',style: TextStyle(color: colors.tintSecondary,fontSize: F.f14),);
      tagItems.add(item);
    }
    return tagItems;
  }

  List<Widget> imgItems(BuildContext context){
    var colors =  C.current(context);
    // 组合图片和视频到一个数组

    // 一张图片，展示大一点一张161.8*100(后期根据图片尺寸比例来)
    // 两张图片，均分宽度，但宽度不能超过200
    // 3~6， 展示9宫格
    // >6，最后一张处展示...以及全部的数量
    // 视频同理，如果为一张，则按比例展示，
    var itemCount = (note.images.length);// + (note.videos.length );
    // print(itemCount);
    if(itemCount <= 0){ return []; }

    var baseNotePath = Global.repoBaseDir + '/' + (note.repoKey);
    String mdFileName = note.mdKey.split('/').last;
    baseNotePath = '$baseNotePath/${note.mdKey.replaceAll(mdFileName, '')}';

    List<Map<String,String>> items = [];
    List<String> imagePaths = [];
    for(NoteResourceInfo imgPath in note.images){
      if(imgPath.payload.isEmpty){ continue; }
      var fullPath = '$baseNotePath${imgPath.payload}';
      items.add({'path':fullPath, 'type':'image',});
      imagePaths.add(fullPath);
    }

    // for(int i = 0; i < (note.videos.length ?? 0); i++){
    //   String videoPath = note.videos![i];
    //   String videoPreviewPath = note.videoPreviews?[i] ?? '';
    //   var fullPath = '$baseNotePath$videoPath';
    //   var fullPreviewPath = '$baseNotePath$videoPreviewPath';
    //   items.add({'path':fullPath, 'type':'video','preview':fullPreviewPath,});
    // }

    List<Widget> widgetItems = [];
    double width = 100;
    double height = 100;
    if(items.length == 1){ // 200*161.8
      width = 200;
      height = 161.8;
    }else if(items.length == 2){ // 161.8*161.8
      width = 150;
      height = 150;
    }
    for(int i = 0;i < items.length; i++){
      Map<String,String> item = items[i];
      var file = File(item['path'] ?? '');
      if(item['type'] == 'video'){
        file = File(item['preview'] ?? '');
      }
      Widget img;
      if(!file.existsSync()){
        img = Container(
          color: colors.tintPlaceholder,
          width: width,
          height: height,
        );
      }else{
        img = Container(
          color: colors.tintPlaceholder,
          child: Image.file(file,width: width,height: height,fit:BoxFit.cover),
        );
      }
      if(item['type'] == 'video'){ // 视频添加播放按钮
        img = Stack(
          children: [
            img,
            Positioned.fill(
              child: Container(
                color: const Color.fromRGBO(0, 0, 0, 0.3),
                child: Center(
                  child: SvgPicture.asset('static/images/item_play.svg',width: 26,height: 26,color: colors.solidWhite_1,),
                )
              )
            )
          ]
        );
      }
      if(i == 5 && items.length > 6){
        img =  ClipRRect(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              img,
              Positioned.fill(
                child: Container(
                  color: const Color.fromRGBO(0, 0, 0, 0.2),
                  child: BackdropFilter(
                    filter:ImageFilter.blur(sigmaX:8, sigmaY:8),
                    child: Center(
                      child: Text('+${(items.length - 5) > 1000 ? 999 : (items.length - 5)}',style: TextStyle(fontSize: F.f20,color: colors.solidWhite_1,fontWeight: FontWeight.w400),),
                    )
                  )
                )
              )
            ]
          )
        );
        img = ClipRRect(borderRadius: BorderRadius.circular(10), child:img);
        img = GestureDetector(
          onTap: (){
            Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> NotePage(note: note,)));
          },
          child: img,
        );
        widgetItems.add(img);
        break;
      }
      img = ClipRRect(borderRadius: BorderRadius.circular(10), child:img);
      if(item['type'] == 'video'){
        img = GestureDetector(
          onTap: (){
            Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> VideoPlayer(videoPath: item['path'] ?? '',)));
          },
          child:img
        );
      }else{
        img = GestureDetector(
          onTap: (){
            ImageViewer.show(context: context, index: imagePaths.indexOf(item['path'] ?? ''), pics: imagePaths);
          },
          child:img
        );
      }
      widgetItems.add(img);
    }
    // print('----------------');
    return widgetItems;
  }

  Map<String, HighlightedWord> highlightedWords(BuildContext context){
    var colors =  C.current(context);
    Map<String, HighlightedWord> words = {};
    if(highLightTexts != null && highLightTexts!.isNotEmpty){
      for(var text in highLightTexts!){
        if(text.isEmpty){ continue; }
        words[text] = HighlightedWord( textStyle: TextStyle(color: colors.tintWarming,fontSize:F.feed, height: 1.44), );
      }
    }
    return words;
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    var tags = tagItems(context);
    var imgs = imgItems(context);
    return GestureDetector(
      onTap: (){
        Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> NotePage(note: note,)));
      },
      child: Container(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
              decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.15), spreadRadius: 0, blurRadius: 10, offset: Offset(0, 5),),],),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child:Container(
                      color: colors.bgOnBody_1,
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.only(left: 10,top: 10,right: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(note.formatTime(),style: TextStyle(color: colors.tintSecondary,fontSize: F.f12),),
                                  GestureDetector(
                                    onTap: () async{
                                      final result = await showModalFitBottomSheet(context, list: [
                                        SheetItem(title: language.share, key: 'share'),
                                        SheetItem(title: language.delete, key: 'delete')
                                      ]);
                                      // SharePage
                                      // print(result);
                                      if(result == 'delete'){
                                        await EasyLoading.show();
                                        bool res = await note.delete();
                                        await EasyLoading.dismiss();
                                        if(res){
                                          GitIsolate.share.commit(note.repoKey);
                                          Bus.emit('mainPageRefresh',{'new':null, 'old':note});
                                        }
                                      }
                                      if(result == 'share'){
                                        Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> SharePage(note: note,)));
                                      }
                                    },
                                    child: SvgPicture.asset('static/images/home_item_more.svg',color: colors.tintSecondary,),
                                  )
                                ],
                              ),
                            ),
                            if(note.content.isNotEmpty)
                              Container(
                                // color: Colors.red,
                                padding: const EdgeInsets.only(left: 10,top: 5,right: 10),
                                // child: Text(note.content ?? '',style: TextStyle(color: Color.fromRGBO(117, 117, 117, 1),fontSize: 16),),
                                child: TextHighlight(
                                  text:note.content,
                                  words: highlightedWords(context),
                                  textStyle: TextStyle(color: colors.tintPrimary,fontSize: F.feed, height: 1.44),
                                  maxLines: 10,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  // softWrap: true,
                                ),
                              ),
                            Container(
                              // color: Colors.blue,
                              padding: const EdgeInsets.only(left: 10,top: 5,right: 10),
                              child: Wrap(
                                spacing: 14.0,
                                runSpacing: 14.0,
                                children: [
                                  ...imgs
                                ],
                              ),
                            ),
                            if(tags.isNotEmpty)
                              Container(
                                // color: Colors.grey,
                                  padding: const EdgeInsets.only(left: 10,top: 5,right: 10),
                                  child: Wrap(
                                    spacing: 5.0,
                                    children: [ ...tags ],
                                  )
                              ),
                            if(note.formatGPS().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.only(left: 10,top: 5,right: 10),
                                child: Text(note.formatGPS(),style: TextStyle(color: colors.tintSecondary,fontSize: F.f14),),
                              )
                          ]
                      )
                  )
              )
          )
      ),
    );
  }
}