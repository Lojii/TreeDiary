// import 'package:flutter/cupertino.dart';

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/isolate/git_isolate.dart';
import 'package:treediary/model/video_item.dart';
import 'package:treediary/provider/global_model.dart';
import 'package:treediary/provider/repo_list_model.dart';
import 'package:treediary/widgets/edit_repo_list.dart';
import "package:images_picker/images_picker.dart";
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import '../config/global_data.dart';
import '../model/gps_item.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/setting_model.dart';
import '../repo/sql_manager.dart';
import '../utils/event_bus.dart';
import '../utils/markdown/markdown.dart';
import '../widgets/edit_bottom_bar.dart';
import '../widgets/edit_tags.dart';
import '../widgets/image_viewer.dart';
import '../widgets/video_player.dart';
import 'map_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class EditPage extends StatefulWidget {
  const EditPage({Key? key}) : super(key: key);

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> with WidgetsBindingObserver{
  final GlobalKey _bottomBarKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  double bottomBarHeight = 130;

  //
  String mainBody = ''; // 正文
  List<String> imagePaths = []; // 图片
  List<VideoItem> videoPaths = [];  // 视频
  GPSItem? gps;  // 经度
  List<String>? noteList;   // 笔记本列表

  Key? mapKey;

  @override
  void initState() {
    // 设置初始Repo
    // Provider.of<GlobalModel>(context, listen:false).editReposChange([Provider.of<RepoListModel>(context, listen:false).currentSelectedRepo()]);
    _focusNode.addListener(() {
      updateBottomBarSize();
    });
    super.initState();
  }

  @override
  dispose(){
    // Provider.of<GlobalModel>(context, listen:false).editReposChange([]);
    // Provider.of<GlobalModel>(context, listen:false).editTagsChange([]);
    _focusNode.removeListener(() { });
    super.dispose();
  }

  updateBottomBarSize(){
    var size = _bottomBarKey.currentContext?.size;
    bottomBarHeight = size?.height ?? 130;
    // print(size?.height ?? 100);
  }

  focusAddUpdate(){
    if(_focusNode.hasFocus){
      _focusNode.unfocus();
      return;
    }
    _focusNode.requestFocus();
    updateBottomBarSize();
  }

  // 图片
  previewImage(String path){
    _focusNode.unfocus();
    ImageViewer.show(context: context, index: imagePaths.indexOf(path),pics: imagePaths);
  }
  Widget imageItemView(imagePath){
    print(imagePath);
    var imgFile = File(imagePath);
    if(imgFile.existsSync()){
      print('存在');
    }else{
      print('不存在');
    }
    // return Container(
    //   width: 108,height: 108,
    //   color: Colors.red,
    // );
    return GestureDetector(
        onTap: () => previewImage(imagePath),
      child:ClipRRect(
      borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Hero(
              tag: imagePath,
              // child: Image(image: AssetImage(imagePath),width: 108,height: 108,fit: BoxFit.cover), // iOS这样能加载到图片，但是安卓不行
              child: Image.file(File(imagePath), width: 108,height: 108,fit: BoxFit.cover,)//(image: AssetImage(imagePath),width: 108,height: 108,fit: BoxFit.cover),
            ),
            Positioned(
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => deleteImage(imagePath),
                child:Container(
                  padding: const EdgeInsets.all(5),
                  child: SvgPicture.asset('static/images/item_delete_bg.svg'),
                ),
              )
            )
          ],
        )
      )
    );
  }
  _onImageReorder(int oldIndex, int newIndex) {
    setState(() {
      String path = imagePaths.removeAt(oldIndex);
      imagePaths.insert(newIndex, path);
    });
  }
  deleteImage(String path){
    setState(() {
      imagePaths.remove(path);
    });
  }
  // 视频
  playVideo(VideoItem video){
    Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> VideoPlayer(videoPath: video.path,)));
  }
  Widget videoItemView(VideoItem video){
    // var sizeStr = int.parse(video.size ?? '0') / 1024;
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
                Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => deleteVideo(video),
                      child:Container(
                        color: const Color.fromRGBO(0, 0, 0, 0.01),
                        padding: const EdgeInsets.all(10),
                        child: SvgPicture.asset('static/images/item_delete_bg.svg'),
                      ),
                    )
                ),
                // Container(
                //   width: 50,
                //   height: 50,
                //   color: Colors.red,
                // ),
                SvgPicture.asset('static/images/video_play.svg'),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 4,bottom: 4,left: 10,right: 10),
                    color: const Color.fromRGBO(0, 0, 0, 0.3),
                    child: Text('Size:${video.sizeStr}',style: TextStyle(color: Colors.white, fontSize:F.f12),),
                  ),
                )
              ],
            )
        )
    );
  }
  _onVideoReorder(int oldIndex, int newIndex) {
    setState(() {
      var path = videoPaths.removeAt(oldIndex);
      videoPaths.insert(newIndex, path);
    });
  }
  deleteVideo(VideoItem video){
    setState(() {
      // videoPaths.remove(path);
      videoPaths.removeWhere((element) => video.path == element.path);
    });
  }
  // 位置
  getLocation() async {
    L language = L.current(context,listen: false);
    bool needMap = Provider.of<SettingModel>(context, listen:false).needMap;
    GPSItem? newGPS;
    if(gps != null){
      if(!needMap){
        // EasyLoading.showToast('获取位置信息失败！');
        if (kDebugMode) { print('限制地图功能'); }
        return;
      }
      // 跳转地图选点
      newGPS = await Navigator.push(context, MaterialPageRoute(builder: (context)=>  MapPage(isEdit: true,gps: gps,)));
    }else{
      var gg = await GPSItem.getLocation();
      if(!needMap && gg == null){
        EasyLoading.showToast(language.failed_to_get_location);
        if (kDebugMode) { print('限制地图功能'); }
        return;
      }
      newGPS = gg ?? await Navigator.push(context, MaterialPageRoute(builder: (context)=>  MapPage(isEdit: true)));
    }
    setState(() {
      gps = newGPS;
      mapKey = UniqueKey();
    });
  }
  Widget mapItemView(){
    LatLng? centerLatLng;
    if(gps != null){
      if(gps!.latitude != null && gps!.longitude != null){
        if (kDebugMode) { print('new center'); }
        centerLatLng = LatLng(double.parse(gps!.latitude!), double.parse(gps!.longitude!));
      }
    }
    if(centerLatLng == null){
      return Container();
    }
    return Container(
      padding: const EdgeInsets.only(top: 15),
      child: GestureDetector(
          onTap: () => { getLocation() },
          child:ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Container(
                    key:mapKey, // 强制重新渲染
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
                  ),
                  Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => deleteAddress(),
                        child:Container(
                          color: const Color.fromRGBO(0, 0, 0, 0.01),
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset('static/images/item_delete_bg.svg'),
                        ),
                      )
                  ),
                ],
              )
          )
      ),
    );
  }
  deleteAddress(){
    setState(() { gps = null; });
  }
  // 标签
  selectTags() async {
    await showBarModalBottomSheet(
      backgroundColor:Colors.transparent,
      context: context,
      builder: (context) => EditTags(),
    );
  }
  // 日记本
  selectRepos() async {
    await showBarModalBottomSheet(
      backgroundColor:Colors.transparent,
      context: context,
      builder: (context) => EditRepos(),
    );
  }
  // 创建
  save() async {
    await EasyLoading.show();
    var tmp = await Markdown.create( //   /// { 'tmpDir': '', 'tmpMDPath': '' }
      content: mainBody,
      imagePaths: imagePaths,
      videoPaths: videoPaths,
      tags: Provider.of<GlobalModel>(context, listen:false).currentEditTags,
      gps: gps
    );
    String tmpDir = tmp['tmpDir']!;
    String tmpMDPath = tmp['tmpMDPath']!;
    var repos = Provider.of<GlobalModel>(context, listen:false).currentEditRepos;
    for(int i = 0; i < repos.length; i++){
      var r = repos[i];
      var notePath = await Markdown.copyNote(from: tmpDir, to: r.localPath, isMove: i >= repos.length - 1);// Documents/PlantingNote/pt_20220614181654
      if(notePath != null) {
        String mdPath = tmpMDPath.split('$tmpDir/').last;
        // 1、记录到数据库
        // print('------');
        // print(tmpDir);  // /var/mobile/Containers/Data/Application/21051311-1689-4B90-8016-D7546366C376/Library/Caches/edit/1658030092988
        // print(tmpMDPath); // /var/mobile/Containers/Data/Application/21051311-1689-4B90-8016-D7546366C376/Documents/PlantingNote/pt_20220603143204
        // print(mdPath);
        // print('------');
        var repoBasePath = Global.repoBaseDir + '/' + r.localPath;
        await SQLManager.addNotes([mdPath], repoBasePath, r.localPath);
        // 2、重排git操作队列
        GitIsolate.share.commit(r.key);
        // Map<String, List<String>> changes = await r.commit();
        // await SQLManager.updateDatabase(changes:changes, repoLocalPath: r.localPath); // 更新数据库
      }
    }
    Future.delayed(const Duration(seconds: 1),(){
      Bus.emit('mainPageRefresh');
    });

    await EasyLoading.dismiss();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool needMap = Provider.of<SettingModel>(context, listen:true).needMap;
    var colors =  C.current(context);
    var language = L.current(context);
    var imageViews = SizedBox(
      width: MediaQuery.of(context).size.width - 30,
      child: ReorderableWrap(
          spacing: 10.0,
          runSpacing: 10.0,
          // padding: const EdgeInsets.all(8),
          children: imagePaths.map((e) => imageItemView(e)).toList(),
          onReorder: _onImageReorder,
          onNoReorder: (int index) {
            //this callback is optional
            debugPrint('${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:$index');
          },
          onReorderStarted: (int index) {
            //this callback is optional
            debugPrint('${DateTime.now().toString().substring(5, 22)} reorder started: index:$index');
          }
      ),
    );
    var videoViews = Container(
      padding: const EdgeInsets.only(top: 15),
      width: MediaQuery.of(context).size.width - 30,
      child: ReorderableWrap(
          spacing: 10.0,
          runSpacing: 10.0,
          // padding: const EdgeInsets.all(8),
          children: videoPaths.map((e) => videoItemView(e)).toList(),
          onReorder: _onVideoReorder,
          onNoReorder: (int index) {
            //this callback is optional
            debugPrint('${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:$index');
          },
          onReorderStarted: (int index) {
            //this callback is optional
            debugPrint('${DateTime.now().toString().substring(5, 22)} reorder started: index:$index');
          }
      ),
    );
    // 监听屏幕尺寸变化，键盘相关
    WidgetsBinding.instance.addPostFrameCallback((_) { updateBottomBarSize(); });
    // save按钮是否可用，text\image\video\address 有一个就行
    bool saveEnable = mainBody.isNotEmpty || imagePaths.isNotEmpty || videoPaths.isNotEmpty || gps != null;
    return Scaffold(
      appBar: AppBar( //导航栏
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => {_focusNode.unfocus()},
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
          )
        ),
        leading: IconButton(
          onPressed: () { Navigator.pop(context); },
          icon: SvgPicture.asset('static/images/nav_close.svg',color: colors.tintPrimary,),
        ),
        backgroundColor: colors.bgBody_1,
        elevation: 0,//隐藏底部阴影分割线
        // bottom: null,
        actions: <Widget>[ //导航栏右侧菜单
          Container(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () => { save() },
              child: Flex(
                direction: Axis.horizontal,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.only(left: 15,right: 15,top: 5,bottom: 5),
                      color: saveEnable ? colors.bgGitBlue : colors.bgBody_2,
                      child: Text(language.save,style: TextStyle(fontSize: F.f14,color: saveEnable ? colors.solidWhite_1 : colors.tintTertiary),),
                    )
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      backgroundColor: colors.bgBody_1,
      body: WillPopScope(
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(left: 15,right: 15),
                child: Column(
                  children: [
                    TextField(
                      // onTap: () => updateBottomBarSize(),
                      onChanged:(value) => { setState((){ mainBody = value; }) },
                      autofocus: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(0),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: language.write_something,
                        hintStyle:TextStyle(fontSize: F.f16, color: colors.tintPlaceholder),
                        labelStyle:TextStyle(fontSize: F.f16, color: colors.tintPrimary),
                      ),
                      focusNode: _focusNode,
                      cursorColor: colors.tintGitBlue,
                      showCursor: true,
                      maxLines: 20,
                      minLines: 5,
                      scrollPadding:EdgeInsets.only(bottom: bottomBarHeight),
                      style:TextStyle(fontSize: F.f16,color: colors.tintPrimary)
                    ),
                    Container(height: 15,),
                    imageViews,
                    videoViews,
                    if(needMap)
                      mapItemView(),
                    GestureDetector(
                      onTap: () => focusAddUpdate(),
                      child:Container(
                        height: 200,
                        color: colors.bgBody_1,
                        // child: ,
                      ),
                    ),
                  ],
                )
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child:BottomBar(
                  key: _bottomBarKey,
                  gps:gps,
                  didSelectImagePaths: imagePaths,
                  addImages: (paths) => { setState(() { imagePaths.addAll(paths); }) },
                  addVideos: (paths) => { setState(() { videoPaths.addAll(paths); }) },
                  getGPS: () => {getLocation()},
                  deleteGPS: () => {deleteAddress()},
                  showTagSheet:() => {selectTags()},
                  showRepoListSheet:() => {selectRepos()}
                ),
              )
            ],
          ),
        ),
        onWillPop: () async{
          return false;
        }
      )
    );
  }
}
