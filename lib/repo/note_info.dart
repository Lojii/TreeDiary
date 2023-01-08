

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:treediary/repo/repo_action.dart';
import 'package:treediary/repo/sql_manager.dart';
import 'package:html/parser.dart' show parse;
import 'package:libgit2dart/libgit2dart.dart';
import '../config/global_data.dart';
import 'note_resource_info.dart';
import 'repo_manager.dart';

/* 保存相对路径
创建时间、更新时间、
创建者、日记路径、md路径、md内容(前一万字)、info.json路径(如果有)、版本、
image路径列表、image缩略图路径列表、video路径列表、video缩略图路径列表、
file路径列表、audio路径列表、标签列表、经纬度、link列表、网页快照文件路径、
* */

class NoteInfo {
  /// 数据库字段
  int id = -1;      // 数据库id
  String repoKey;   // repo路径，比如 pt_x (全路径不太行)
  String mdKey;     // md路径 2022/12/23-231103-123.md
  String content = '';  // md内容
  int isDiary = 0;  // 是否为日记，如果不是则为0
  // 日记特有字段
  String createTime = '';
  String author = '';   // 作者
  String version = '';  // 版本
  String source = '';  // 来源：iOS、MacOS、...


  /// 资源
  List<NoteResourceInfo> tags = [];     //
  List<NoteResourceInfo> gps = []; //
  List<NoteResourceInfo> images = [];   // 图片路径列表[assets/00_xxx.jpg]
  /// 下面的参数需要额外实现
  List<NoteResourceInfo> imagePreviews = []; // 图片路径列表[assets/00_xxx.jpg]
  List<NoteResourceInfo> videos = [];   //
  List<NoteResourceInfo> videoPreviews = []; //
  List<NoteResourceInfo> files = [];    //
  List<NoteResourceInfo> audios = [];   //
  List<NoteResourceInfo> links = [];    //
  List<NoteResourceInfo> linkSnapshots = []; //
  List<NoteResourceInfo> address = []; //

  String get latitude => gps.isNotEmpty ? gps.first.payload.split(',').first : '';
  String get longitude => gps.isNotEmpty ? gps.first.payload.split(',').last : '';


  static String tableName = 'Note';
  static Map<String, String> columns = {
    "id": "INTEGER PRIMARY KEY",
    "repoKey": "TEXT",
    "mdKey": "TEXT",
    "createTime": "TEXT",
    "author": "TEXT",
    "content": "TEXT",
    "version": "TEXT",
    "source": "TEXT",
    "isDiary": "INTEGER"
  };

  String notePageFormatTime(){
    try{
      int t = int.parse(createTime);
      DateTime date = DateTime.fromMillisecondsSinceEpoch(t);
      return '${date.year}\n${date.month}/${date.day} ${date.hour}:${date.minute}';
    }catch(e){
      return createTime;
    }
  }

  String formatTime(){
    try{
      int t = int.parse(createTime);
      DateTime date = DateTime.fromMillisecondsSinceEpoch(t);
      var dateStr = date.toString().split('.').first;
      return dateStr;
    }catch(e){
      return createTime;
    }
  }
  /// latitude: E:东经(正数) W:西经(负数)
  /// longitude: N:北纬(正数) S:南纬(负数)
  String formatGPS(){
    if(gps.isEmpty){ return ''; }
    var gpsArray = gps.first.payload.split(',');
    if(gpsArray.length != 2){ return ''; }
    String latitude = gpsArray.first;
    String longitude = gpsArray.last;
    if(latitude.isEmpty || longitude.isEmpty){ return ''; }
    String format = '';
    if(latitude.contains('-')){ // W °′
      format = format + latitude.replaceAll('-', '').replaceAll('.', '°') + 'W,';
    }else{ // E
      format = format + latitude.replaceAll('.', '°') + 'E,';
    }
    if(latitude.contains('-')){ // S
      format = format + longitude.replaceAll('-', '').replaceAll('.', '°') + 'S';
    }else{ // N
      format = format + longitude.replaceAll('.', '°') + 'N';
    }
    return format;
  }

  NoteInfo({required this.repoKey, required this.mdKey});

  static NoteInfo? fromMap(Map<String,dynamic> keyValue){
    var repoKey = keyValue['repoKey']; // baseGit/pt_xxxx
    var mdKey = keyValue['mdKey']; // 2022/xx/xx-xxxxxx-xxx.md
    if(repoKey == null || mdKey == null){ return null; }
    var note = NoteInfo(repoKey: repoKey, mdKey: mdKey);
    note.author = keyValue['author'];
    note.createTime = keyValue['createTime'];
    note.source = keyValue['source'];
    note.version = keyValue['version'];
    note.content = keyValue['content'];
    note.isDiary = keyValue['isDiary'];

    var tags = keyValue['tags'];
    if(tags != null && tags is List<NoteResourceInfo>){ note.tags = tags; }
    var gps = keyValue['gps'];
    if(gps != null && gps is List<NoteResourceInfo>){ note.gps = gps; }
    var images = keyValue['images'];
    if(images != null && images is List<NoteResourceInfo>){ note.images = images; }

    // var imagePreviews = keyValue['imagePreviews'];
    // if(imagePreviews != null && imagePreviews is List<NoteResourceInfo>){ note.imagePreviews = imagePreviews; }
    // var videos = keyValue['videos'];
    // if(videos != null && videos is List<NoteResourceInfo>){ note.videos = videos; }
    // var videoPreviews = keyValue['videoPreviews'];
    // if(videoPreviews != null && videoPreviews is List<NoteResourceInfo>){ note.videoPreviews = videoPreviews; }
    // var files = keyValue['files'];
    // if(files != null && files is List<NoteResourceInfo>){ note.files = files; }
    // var audios = keyValue['audios'];
    // if(audios != null && audios is List<NoteResourceInfo>){ note.audios = audios; }
    // var links = keyValue['links'];
    // if(links != null && links is List<NoteResourceInfo>){ note.links = links; }
    // var linkSnapshots = keyValue['linkSnapshots'];
    // if(linkSnapshots != null && linkSnapshots is List<NoteResourceInfo>){ note.linkSnapshots = linkSnapshots; }
    // var address = keyValue['address'];
    // if(address != null && address is List<NoteResourceInfo>){ note.address = address; }

    // print('keyValue.toString()');
    // print(keyValue.toString());
    return note;
  }

  static  NoteInfo? _fromContent(String content,{required String mdFile,required String repoLocalPath}){
    Map<String,dynamic> keyValue = getSpecialElement(content, repoLocalPath,mdFile.split(repoLocalPath+'/').last);
    return fromMap(keyValue);
  }
  /// 同步方法
  static NoteInfo? syncFrom({required String mdFile,required String repoLocalPath}){
    try{
      return _fromContent(File(mdFile).readAsStringSync(), mdFile: mdFile, repoLocalPath: repoLocalPath);
    }catch(e){
      debugPrint(e.toString());
      return null;
    }
  }
  /// 异步版本
  static Future<NoteInfo?> from({required String mdFile,required String repoLocalPath}) async{
    try{
      return _fromContent(await File(mdFile).readAsString(), mdFile: mdFile, repoLocalPath: repoLocalPath);
    }catch(e){
      debugPrint(e.toString());
      return null;
    }
  }
  /// 此方法会调用两次，一次是保存的时候，一次是commit的时候，需要保证数据不会重复写入
  saveToDB() async{
    if(isDiary == 0){ // 非日记，不存入数据库
      return;
    }
    if(repoKey.isNotEmpty && mdKey.isNotEmpty){
      await deleteToDB(mdKey: mdKey, repoKey: repoKey); // 防止重复添加
      var map = toMap();
      /// 保存日记
      await SQLManager.save( table:NoteInfo.tableName, values:map, uniqueKey: { "repoKey": repoKey, "mdKey": mdKey, } );
      /// 保存日记资源
      // print('saveToDB');
      // print(tags);
      // print(gps);
      // print(images);
      await NoteResourceInfo.addAll(tags);
      await NoteResourceInfo.addAll(gps);
      await NoteResourceInfo.addAll(images);
    }else{
      debugPrint('数据有误,无法存储');
    }
  }

  /// 清空日记本对应所有记录
  static Future<bool> clear(String repoKey) async{
    if(repoKey.isEmpty){ return false; }
    String deleteSQL = "DELETE FROM ${NoteInfo.tableName} WHERE repoKey = '$repoKey'";
    if (kDebugMode) { print(deleteSQL); }
    await SQLManager.rawQuery(deleteSQL);
    /// 删除该日记本对应的所有资源
    String deleteResourceSQL = "DELETE FROM ${NoteResourceInfo.tableName} WHERE repoKey = '$repoKey'";
    if (kDebugMode) { print(deleteResourceSQL); }
    await SQLManager.rawQuery(deleteResourceSQL);
    return true;
  }

  static deleteToDB({required String mdKey, required String repoKey}) async{
    if(mdKey.isEmpty || repoKey.isEmpty){ return; }
    if(mdKey.contains('*') || mdKey.contains(' ') || repoKey.contains('*') || repoKey.contains(' ')){ return; } // 防注入攻击(有必要么？)
    String deleteSQL = "DELETE FROM ${NoteInfo.tableName} WHERE repoKey = '$repoKey' AND mdKey = '$mdKey'";
    if (kDebugMode) { print(deleteSQL); }
    await SQLManager.rawQuery(deleteSQL);
    String deleteResourceSQL = "DELETE FROM ${NoteResourceInfo.tableName} WHERE repoKey = '$repoKey' AND mdKey = '$mdKey'";
    if (kDebugMode) { print(deleteResourceSQL); }
    await SQLManager.rawQuery(deleteResourceSQL);
  }

  _loadAllResource() async{
    var resourceList = await NoteResourceInfo.list(repoKey: repoKey, mdKey: mdKey);
    List<NoteResourceInfo> tagsResource = [];     //
    List<NoteResourceInfo> gpsResource = []; //
    List<NoteResourceInfo> imagesResource = [];
    for(var r in resourceList){
      if(r.type == NoteResourceType.tag){
        tagsResource.add(r);
      }else if(r.type == NoteResourceType.gps){
        gpsResource.add(r);
      }else if(r.type == NoteResourceType.image){
        imagesResource.add(r);
      }
      // ...
    }
    tags = tagsResource;
    gps = gpsResource;
    images = imagesResource;
  }

  static Future<List<NoteInfo>> loadList({
    required String repoKey,
    int pageNum = 1, int pageSize = 10,
    String? timePoint, String? searchKey, List<String>? tags,
    bool isDesc = true
  }) async{
    // https://www.sqlite.org/json1.html

    String sql = "SELECT n.* FROM ${NoteInfo.tableName} n LEFT OUTER JOIN ${NoteResourceInfo.tableName} r ON n.repoKey = r.repoKey AND n.mdKey = r.mdKey";
    var where = " WHERE n.repoKey = '$repoKey'";
    var time = '';
    var search = '';
    var searchTag = '';
    var orderBy = '';
    var limit = ' LIMIT $pageSize';
    var offset = ' OFFSET ($pageNum * $pageSize)';
    var groupStr = " GROUP BY n.repoKey, n.mdKey";
    /// 排序与时间
    if(isDesc){ // 降序
      if(timePoint != null && timePoint.isNotEmpty){ time = " AND n.createTime < '$timePoint'"; }
      orderBy = " ORDER BY n.createTime DESC, n.mdKey DESC";
    }else{ // 升序
      if(timePoint != null && timePoint.isNotEmpty){ time = " AND n.createTime > '$timePoint'"; }
      orderBy = " ORDER BY n.createTime ASC, n.mdKey ASC";
    }
    /// 文本搜索
    if(searchKey != null && searchKey.trim().isNotEmpty){ // AND
      var searchKeys = searchKey.trim().split(' ');
      var searchSQL = "";
      for(var key in searchKeys){
        if(key.isNotEmpty){
          searchSQL = searchSQL + (searchSQL.isEmpty ? '' : ' AND ') + "n.content LIKE '%$key%'";
        }
      }
      search = " AND ($searchSQL)";
    }
    /// 标签过滤
    if(tags != null){ // OR
      var tagSQL = '';
      for(var tag in tags){
        if(tag.isNotEmpty && tag.trim().isNotEmpty){
          tagSQL = tagSQL + (tagSQL.isEmpty ? '' : ' OR ') + "r.payload = '$tag'";//  AND r.type = 'tag'
        }
      }
      searchTag = tagSQL.isEmpty ? '' : " AND ( $tagSQL )";
    }
    sql = sql + where + time + search + searchTag + groupStr + orderBy + limit + offset;
    debugPrint(sql);
    var maps = await SQLManager.rawQuery(sql);
    List<NoteInfo> notes = [];
    for(var map in maps){
      var note = NoteInfo.fromMap(map);
      if(note != null) {
        await note._loadAllResource();
        notes.add(note);
      }
    }
    return notes;
  }

  Map<String, Object> toMap(){
    Map<String, Object> map = {
      "repoKey": repoKey,
      "mdKey": mdKey,
      "content": content,
      "isDiary": isDiary,

      "createTime": createTime,
      "author": author,
      "version": version,
      "source": source,
    };
    return map;
  }


  static Map<String,Object> getSpecialElement(String content, String repoKey, String mdKey) {
    // print(content);
    // print('-----------------------------------------------');
    String body = '';
    List<String> imagePaths = []; // 包括![]()里的链接
    List<String> imagePreviewPaths = [];
    List<String> videoPaths = [];
    List<String> videoPreviewPaths = [];
    List<String> tags = [];
    String latitude = '';
    String longitude = '';
    // String mapUrl = '';

    // List<String> audioPaths = [];
    // List<String> filePaths = [];
    // List<String> links = [];  // 包括[]()里的链接
    // List<String> linkSnapshots = [];

    String creator = '';
    String createTime = '';
    String source = '';
    String version = '';

    // 通过正则表达式获取数据
    var imgExp = r'!\[.*?\]\((.+?)\)';
    var tagExp = r'\[\#.*?\]\((.*?)\)';
    // var linkExp = r'\[.*?\]\((.+?)\)';
    var infoExp = r'<!--(.*?)-->'; // <!--  create:Jonrow -->
    // info
    var infoRegExp = RegExp(infoExp, multiLine: true,dotAll: true);
    var mdInfos = infoRegExp.allMatches(content).map((m) => m.group(0) ?? '').toList();
    content = content.replaceAll(infoRegExp, '');
    for(var mdInfo in mdInfos){
      var infoPs = mdInfo.split('\n');
      for(var p in infoPs){
        if(p.startsWith('creator')){ creator = p.replaceAll('creator:', ''); }
        if(p.startsWith('time')){ createTime = p.replaceAll('time:', ''); }
        if(p.startsWith('source')){ source = p.replaceAll('source:', ''); }
        if(p.startsWith('version')){ version = p.replaceAll('version:', ''); }
      }
    }
    // print('----mdInfo----');

    var imgRegExp = RegExp(imgExp, multiLine: true,);
    var mdImgs = imgRegExp.allMatches(content).map((m) => m.group(0) ?? '').toList();
    content = content.replaceAll(imgRegExp, '');
    for(var mdImg in mdImgs){
      var imgUrl = mdImg.split('(').last.split(')').first;
      imagePaths.add(imgUrl);
      imagePreviewPaths.add('');
    }
    // print('----mdImg----');

    var tagExpExp = RegExp(tagExp, multiLine: true,);
    var mdTags = tagExpExp.allMatches(content).map((m) => m.group(0) ?? '').toList();
    content = content.replaceAll(tagExpExp, '');
    for(var mdTag in mdTags){
      var tag = mdTag.split('](').first.split('[').last.replaceAll('#', '');
      tags.add(tag);
    }
    // print('----mdTags----');

    // var linkExpExp = RegExp(linkExp, multiLine: true,);
    // var mdLinks = linkExpExp.allMatches(content).map((m) => m.group(0) ?? '').toList();
    // for(var mdLink in mdLinks){
    //   var link = mdLink.split('(').last.split(')').first;
    //   links.add(link);
    //   linkSnapshots.add('');
    // }
    // print('----mdLinks----');

    // 获取html标签里的数据
    // img
    var document = parse(content);

    var imgTags = document.getElementsByTagName('img');
    for(var tag in imgTags){
      var src = tag.attributes['src'];
      if(src != null){
        imagePaths.add(src);
        imagePreviewPaths.add('');
      }
    }
    // video
    var videoTags = document.getElementsByTagName('video');
    for(var videoTag in videoTags){
      var videoInner = parse(videoTag.innerHtml);
      var poster = videoTag.attributes['poster'] ?? '';
      var sourceTags = videoInner.getElementsByTagName('source');
      for(var sourceTag in sourceTags){
        var src = sourceTag.attributes['src'];
        if(src != null) {
          videoPaths.add(src);
          videoPreviewPaths.add(poster);
        }
      }
    }
    // address
    var iframeTags = document.getElementsByTagName('iframe');
    for(var iframeTag in iframeTags){
      latitude = iframeTag.attributes['latitude'] ?? '';
      longitude = iframeTag.attributes['longitude'] ?? '';
      // mapUrl = iframeTag.attributes['src'] ?? '';
    }

    body = document.body?.text ?? '';// 移除了所有标签的文本内容
    // 移除body里的连续换行、连续逗号以及分割符------ ------ 之后的数据
    var bodyP = body.split('------ ------');
    if(bodyP.length == 2){
      body = bodyP.first;
    }
    // 移除连续换行 TODO:修改为移除首尾换行
    var noNbody = body.split('\n');
    List<String> tmpArray = [];
    for(var no in noNbody){
      if(no.isNotEmpty){
        tmpArray.add(no);
      }
    }
    body = tmpArray.join('\n');

    Map<String,Object> keyValue = {};
    keyValue['repoKey'] = repoKey;
    keyValue['mdKey'] = mdKey;
    keyValue['content'] = body;
    keyValue['isDiary'] = (creator.isNotEmpty && createTime.isNotEmpty) ? 1 : 0;// 如果是日记，则至少有作者和创建时间 TODO:添加一个type字段，用来表明具体类型

    keyValue['createTime'] = createTime;
    keyValue['author'] = creator;
    keyValue['source'] = source;
    keyValue['version'] = version;

    keyValue['tags'] = tags.map((e) => NoteResourceInfo(repoKey: repoKey, mdKey: mdKey, payload: e, type: NoteResourceType.tag)).toList();
    keyValue['gps'] = (latitude.isNotEmpty && longitude.isNotEmpty) ? [NoteResourceInfo(repoKey: repoKey, mdKey: mdKey, payload: '$latitude,$longitude', type: NoteResourceType.gps)] : [];
    keyValue['images'] = imagePaths.map((e) => NoteResourceInfo(repoKey: repoKey, mdKey: mdKey, payload: e, type: NoteResourceType.image)).toList();
    /// 下面字段还未实现
    // keyValue['imagePreviews'] = imagePreviewPaths;
    // keyValue['videos'] = videoPaths;
    // keyValue['videoPreviews'] = videoPreviewPaths;
    // keyValue['files'] = filePaths;
    // keyValue['audios'] = audioPaths;
    // keyValue['links'] = links;
    // keyValue['linkSnapshots'] = linkSnapshots;
    // keyValue['address'] = [];
    // print(keyValue);
    return keyValue;
  }

  Future<bool> delete() async{
    /*
    * 1、拼接路径
    * 2、获取md所在文件夹
    * 3、判断此文件夹是否为note文件夹
    * 3、移除md所在文件夹
    * 4、提交变更
    * 5、根据变更移除数据库里对应的条目
    * 6、返回刷新首页
    * */
    var baseRepoPath = await RepoManager.repoBasePath();
    if(baseRepoPath == null){
      return false;
    }
    var repoFullPath = baseRepoPath.path + '/' + repoKey;
    if(mdKey.split('/').length != 4){
      return false;
    }
    String mdFileName = mdKey.split('/').last;
    var noteDir = repoFullPath + '/' + mdKey.replaceAll(mdFileName, '');
    Directory dir = Directory(noteDir);
    if(await dir.exists()){
      await dir.delete(recursive: true);
    }
    final repo = Repository.open(repoFullPath); // => Repository
    var changes = RepoAction.repoStatus(repo);
    if(changes != null){
      // 暂存变更、提交更新
      RepoAction.stagingChanges(repo, changes);
      await RepoAction.commitChanges(repo: repo, msg: 'delete a record \n',repoKey: repoKey, gitCommitConfigDirectoryPath: Global.gitCommitConfigDirectoryPath);
      // 数据库更新
      SQLManager.updateDatabase(changes: changes, repoLocalPath: repoKey);
    }else{
      debugPrint('no change');
    }
    return true;
  }

}
