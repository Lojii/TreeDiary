import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/model/video_item.dart';
import 'package:treediary/provider/global_model.dart';
import 'package:treediary/widgets/store_viewer.dart';
import "package:images_picker/images_picker.dart";
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../config/purchase_manager.dart';
import '../model/gps_item.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../utils/utils.dart';
import '../widgets/edit_tags.dart';
import 'common/bottom_sheet.dart';

class BottomBar extends StatefulWidget {

  GPSItem? gps;

  Function? addImages;
  Function? addVideos;
  Function getGPS;
  Function deleteGPS;
  Function? noteListDidChange;
  Function? refreshBottomSize;
  Function? showTagSheet;
  Function? showRepoListSheet;
  List<String> didSelectImagePaths;

  BottomBar({Key? key,this.gps, this.addImages, this.addVideos, required this.getGPS, required this.deleteGPS, this.noteListDidChange,this.showTagSheet,this.refreshBottomSize, this.showRepoListSheet, required this.didSelectImagePaths}) : super(key: key);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>{

  Future<bool> _checkEnable() async{
    if(widget.didSelectImagePaths.length >= 20){
      EasyLoading.showToast('图片数量不能超过20张');
      return false;
    }
    if(widget.didSelectImagePaths.length >= 9){
      if(await LatestReceiptInfos.alreadyPurchase()){ return true; }
      if(await StoreView.show(context) ?? false){ return true; }
      return false;
    }
    return true;
  }

  Future getImages() async {
    var language = L.current(context, listen: false);
    if(!await _checkEnable()){
      return;
    }
    var maxCount = 9;
    if(await LatestReceiptInfos.alreadyPurchase()){
      maxCount = 20;
    }
    var bs = await showModalFitBottomSheet(context,list: [SheetItem(title: language.select_from_album,key: 'select_from_album'),SheetItem(title: language.taking_photos,key: 'taking_photos')]);
    if(bs == null){ return; }
    List<Media>? res;
    if(bs == 'select_from_album'){
      var pp = await Utils.getPhotosPermission();
      if(!pp.isGranted && !pp.isLimited){
        EasyLoading.showToast(language.no_permission);
        return;
      }
      EasyLoading.show();
      int count = maxCount - widget.didSelectImagePaths.length;
      res = await ImagesPicker.pick(count: count, pickType: PickType.image, language: Language.System, quality: 0.8, maxSize: 800,);
      EasyLoading.dismiss();
    }else{
      var pp = await Utils.getCameraPermission();
      if(!pp.isGranted && !pp.isLimited){
        EasyLoading.showToast(language.no_permission);
        return;
      }
      EasyLoading.show();
      res = await ImagesPicker.openCamera(pickType: PickType.image, language: Language.System, quality: 0.8, maxSize: 800,);
      EasyLoading.dismiss();
    }
    if (res != null) {
      // print(res.map((e) => e.path).toList());
      if(widget.addImages != null){
        widget.addImages!(res.map((e) => e.path).toList());
      }
    }

  }

  Future getVideos() async {
    // TODO:弹窗，拍照、相册
    var language = L.current(context, listen: false);

    var pp = await Utils.getPhotosPermission();
    if(!pp.isGranted){
      EasyLoading.showToast(language.no_permission);
      return;
    }
    EasyLoading.show();
    List<Media>? res = await ImagesPicker.pick(
        count: 99,
        pickType: PickType.video,
        language: Language.System,
        maxTime: 600 // 限制10分钟时长
    );
    if (kDebugMode) { print(res); }
    EasyLoading.dismiss();
    if (res != null) {
      // print(res.map((e) => e.path).toList());
      //
      List<VideoItem> vs = [];
      for(var v in res){
        var videoItem = VideoItem(path: v.path, thumbPath: v.thumbPath,size: v.size.toString());
        vs.add(videoItem);
      }
      if(widget.addVideos != null){
        // widget.addVideos!(res.map((e) => e.path).toList());
        widget.addVideos!(vs);
      }
    }
  }

  _deleteTag(String tag){
    var tags = Provider.of<GlobalModel>(context, listen:false).currentEditTags;
    tags.remove(tag);
    Provider.of<GlobalModel>(context, listen:false).editTagsChange(tags);
    // if(widget.refreshBottomSize != null){
    //   widget.refreshBottomSize!();
    // }
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    var tags = Provider.of<GlobalModel>(context, listen:true).currentEditTags;
    var selectRepos = Provider.of<GlobalModel>(context, listen:true).currentEditRepos;
    String showRepoStr = (selectRepos.length > 1 ? '(${selectRepos.length})' : '') + selectRepos.map((e) => e.name).toList().join(',');
    return Container(
      color: colors.bgBody_1,
      child: Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(top: 4,bottom: 4,left: 15,right: 15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...tags.map((e) => Container(
                      padding: const EdgeInsets.only(right: 10),
                      child: TagItemWidget(
                        tagStr: e,
                        onDelete: () => {_deleteTag(e)}, // 删除全局的
                        onClick: () => {if(widget.showTagSheet != null){widget.showTagSheet!()}}, // 跳转tag编辑页面
                        isSelect: true,
                      )
                  )
                  ).toList(),
                ],
              ),
            ),
          ),
          Flex(
            direction: Axis.horizontal,
            children: [
              AddressButton(gps: widget.gps, onPress: () => {widget.getGPS()}, onDelete: () => {widget.deleteGPS()}),
              // const Spacer(),
              Expanded(
                  child:GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => {if(widget.showRepoListSheet != null){widget.showRepoListSheet!()}},
                    child: Container(
                      padding: const EdgeInsets.only(top: 10,bottom: 10),
                      child: Text(showRepoStr,
                        style: TextStyle(fontSize:F.f14,color: colors.tintPrimary),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
              ),
              // const Spacer(),
              GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => {if(widget.showRepoListSheet != null){widget.showRepoListSheet!()}},
                  child: Container(
                    padding: const EdgeInsets.only(left: 5,right: 15,top: 10,bottom: 10),
                    child: SvgPicture.asset('static/images/right_arrow.svg',width: 18,height: 18,color: colors.tintSecondary),
                  )
              )
            ],
          ),
          Container(
            decoration: BoxDecoration( border: Border(top: BorderSide(color: colors.tintSeparator_2, width: 0.5))),
            padding: const EdgeInsets.only(left: 10,right: 15),
            child: Row(
              children: [
                ItemWidget(icon: SvgPicture.asset('static/images/add_image.svg',color: colors.tintPrimary,),onClick: () => {getImages()}),
                // ItemWidget(icon: SvgPicture.asset('static/images/add_video.svg'),onClick: () => {getVideos()}),
                const Spacer(),
                GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => { if(widget.showTagSheet != null){widget.showTagSheet!()} },
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                            color: colors.tintSeparator_2,
                            padding: const EdgeInsets.only(left: 8,right: 15,top: 5,bottom: 5),
                            child: Row(
                              children: [
                                SvgPicture.asset('static/images/add_tag.svg',color: colors.tintPrimary),
                                Text(language.add_tags,style: TextStyle(fontSize: F.f14,color: colors.tintPrimary,fontWeight: FontWeight.w500),)
                              ],
                            )
                        )
                    )
                )
              ],
            ),
            // width: double.infinity,
          )
        ],
      ),
    );
  }

}

class ItemWidget extends StatelessWidget {
  final SvgPicture icon;
  final VoidCallback? onClick;

  const ItemWidget({Key? key, required this.icon, this.onClick, }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.opaque,
      child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: icon
      ),
    );
  }
}

class AddressButton extends StatelessWidget {
  final GPSItem? gps;
  final VoidCallback? onPress;
  final VoidCallback? onDelete;

  const AddressButton({Key? key,  this.onPress, this.gps, this.onDelete}) : super(key: key);

  didClick(){
    if(onPress != null){
      onPress!();
    }
  }

  didDelete(){
    if(onDelete != null){
      onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    return GestureDetector(
      onTap: didClick,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Container(
          // color: Colors.red,
          margin: const EdgeInsets.only(left: 15,right: 5,bottom: 5,top: 5),
          padding: gps == null ? const EdgeInsets.fromLTRB(8, 6, 8, 6) : const EdgeInsets.fromLTRB(8, 0, 0, 0),
          decoration: BoxDecoration(
            border:  Border.all(color: colors.tintPicBorder, width: 1), // 边色与边宽度
            borderRadius: BorderRadius.circular((100.0)), // 圆角度
          ),
          child: Row(
            children: [
              SvgPicture.asset('static/images/add_address.svg',color: gps == null ? colors.tintTertiary : colors.tintPrimary,),
              Container(
                padding: const EdgeInsets.only(left: 3,right: 3),
                child: Text(gps == null ? language.add_location_information : '${gps?.latitude ?? ''},${gps?.longitude ?? ''}', style: TextStyle(color: gps == null ? colors.tintTertiary : colors.tintPrimary,fontSize: F.f12),textAlign: TextAlign.right),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: didDelete,
                child: Visibility(
                  visible: gps != null,
                  child: Container(
                    padding: const EdgeInsets.only(left: 2,top: 6,bottom: 6,right: 5),
                    child: SvgPicture.asset('static/images/item_delete.svg', color: colors.tintSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}
