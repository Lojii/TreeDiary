// 全局信息
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:treediary/provider/repo_list_model.dart';
import 'package:path_provider/path_provider.dart';

import '../../model/gps_item.dart';
import '../../repo/note_info.dart';
import '../../model/video_item.dart';
import '../../repo/repo_manager.dart';

class Markdown {

  static Future<void> copyDirectory(Directory source, Directory destination) async {

    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        var newDirectory = Directory(path.join(destination.absolute.path, path.basename(entity.path)));
        await newDirectory.create();
        await copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        await entity.copy(path.join(destination.path, path.basename(entity.path)));
      }
    }
  }

  static Future<String?> copyNote({required String from, required String to, bool isMove = false}) async {
    var baseRepoPath = await RepoManager.repoBasePath();
    if(baseRepoPath == null){
      return null;
    }
    var fromDir = Directory(from);
    var toDir = Directory(baseRepoPath.path + '/' + to);
    await copyDirectory(fromDir, toDir);
    if(isMove){ await fromDir.delete(recursive:true); }
    return toDir.path;
  }

  static submitRepo(){

  }
  // 在path路径下，生成 2022/06/11_161420_723/1654477875371.md
  // 在path路径下，生成 2022/06/11_161420_723/info.json
  //                                       /assets/01_E10ADC39_435_1034.jpg  序号_md5前8位_宽_高.格式
  //                                       /assets/01_F20F883E_32452.mp4  序号_md5前8位_时长.格式
  //                                       /assets/01_F20F883E_32452.mp4.jpg  封面图片
  //                                       /assets/01_F20F883E_32452.aac 音频.时长
  //                                       /assets/xxx.docx  附件
  //                                       /assets/01_F20F883E_32452.mp4.001  // 拆分后的文件

  /// 返回一个临时路径
  /// content: 输入的内容
  /// gps: 位置信息
  /// imagePaths: 图片列表
  /// videoPaths: 视频列表
  /// tags: 标签列表
  /// filePaths: 附件列表
  /// audioPaths: 音频列表
  /// { 'tmpDir': '', 'tmpMDPath': '' }
  static Future<Map<String, String>> create({
    String? content,
    GPSItem? gps,
    List<String>? imagePaths,
    List<VideoItem>? videoPaths,
    List<String>? tags,
    List<String>? filePaths,
    List<String>? audioPaths}) async{
    /*
      1、生成相关文件夹，如果有资源文件，则多创建一个assets文件夹
      2、创建md文件
      3、创建info.json
    */
    // 获取当前时间
    var time = DateTime.now(); // 2022-05-07 19:04:28.936352
    // 在临时文件夹里创建完整目录
    bool needAssets = (imagePaths != null && imagePaths.isNotEmpty) ||
                      (videoPaths != null && videoPaths.isNotEmpty) ||
                      (filePaths != null && filePaths.isNotEmpty) ||
                      (audioPaths != null && audioPaths.isNotEmpty);
    Directory tmpDir = await _createTmpFolder(time, needAssets);
    // 移动临时文件
    List<Map<String,String>> newImagePaths = [];
    List<Map<String,String>> newVideoPaths = [];
    List<Map<String,String>> newFilePaths = [];
    List<Map<String,String>> newAudioPaths = [];
    if(needAssets){
      if(imagePaths != null && imagePaths.isNotEmpty){
        newImagePaths = await _moveAndSplitFiles(from: imagePaths, to: '${tmpDir.path}', limit: 50*1024*1024, needRename:true);// *1024*1024
      }
      if(videoPaths != null && videoPaths.isNotEmpty){
        List<String> paths = [];
        List<String> previewPaths = [];
        for(var videoItem in videoPaths){
          paths.add(videoItem.path);
          if(videoItem.thumbPath != null){
            previewPaths.add(videoItem.thumbPath!);
          }else{
            previewPaths.add('');
          }
        }
        newVideoPaths = await _moveAndSplitFiles(from: paths, previewFrom: previewPaths, to: '${tmpDir.path}', limit: 50*1024*1024, needRename:true);
      }
      if(filePaths != null && filePaths.isNotEmpty){
        newFilePaths = await _moveAndSplitFiles(from: filePaths, to: '${tmpDir.path}', limit: 50*1024*1024, needRename:false);
      }
      if(audioPaths != null && audioPaths.isNotEmpty){
        newAudioPaths = await _moveAndSplitFiles(from: audioPaths, to: '${tmpDir.path}', limit: 50*1024*1024, needRename:false);
      }
    }
    // 创建md文件
    // mdFile.openWrite()
    var mdStr = content ?? '';
    mdStr = mdStr + '\n\n------ ------\n'; // 分割符 ------ ------
    if(tags != null && tags.isNotEmpty){
      var tagsStr = '';
      for(var tag in tags){
        var t = tag.trim();
        if(t.isEmpty){ continue; }
        if(tagsStr.isNotEmpty){ tagsStr = tagsStr + ',';}
        tagsStr = tagsStr + '[#$t](#$t)';
      }
      if(tagsStr.isNotEmpty){
        tagsStr = 'Tags:' + tagsStr;
        mdStr = mdStr + tagsStr + '\n';
      }
    }
    if(newImagePaths.isNotEmpty){
      List<String> images = newImagePaths.map((e) => e['path'] ?? '').toList();
      var imageTableHtml = '';
      if(images.length == 1){ // 1*1
        imageTableHtml = _imgTableHtml(paths: images, columnNumber: 1);
      }else if(images.length == 2 || images.length == 4){//  2*1 2*2
        imageTableHtml = _imgTableHtml(paths: images, columnNumber: 2);
      }else{ // 3*3
        imageTableHtml = _imgTableHtml(paths: images, columnNumber: 3);
      }
      mdStr = mdStr + imageTableHtml;
    }
    if(newVideoPaths.isNotEmpty){
      List<String> videos = newVideoPaths.map((e) => e['path'] ?? '').toList();
      List<String> videoPreviews = newVideoPaths.map((e) => e['previewPath'] ?? '').toList();
      var videoStr = _videoHtml(paths: videos, previewPaths: videoPreviews);
      mdStr = mdStr + videoStr + '\n';
    }
    if(newFilePaths.isNotEmpty){

    }
    if(newAudioPaths.isNotEmpty){

    }
    if(gps != null){
      var mapStr = _mapHtml(gps);
      mdStr = mdStr + mapStr + '\n';
    }
    // 写入文件属性
    /*
    <!--
    create:Jonrow
    time:2022-12-23 12:34:23
    update:2022-12-23 12:34:24
    -->
    */
    var creator = 'Jonrow';
    var timeStr = time.millisecondsSinceEpoch.toString();
    var source = Platform.operatingSystem;
    var version = '1.0.0';
    var mdInfo = '''
<!--
creator:$creator
time:$timeStr
source:$source
version:$version
-->
    ''';
    mdStr = mdStr + mdInfo + '\n';
    // 写入文件
    var mdFile = File('${tmpDir.path}/${time.millisecondsSinceEpoch.toString()}.md');
    await mdFile.writeAsString(mdStr);

    print('-----------------------');
    print('\n' + mdStr);
    print('-----------------------');

    // // 写入info.json
    // Map json = {
    //   'version' : '1.0.0',
    //   'author': 'app',
    //   'create': time.millisecondsSinceEpoch.toString()
    // };
    // JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    // String prettyprint = encoder.convert(json);
    // var infoFile = File('${tmpDir.path}/info.json');
    // await infoFile.writeAsString(prettyprint);
    // 返回目录
    // var year = time.year.toString().padLeft(4,'0');
    var timestamp = time.millisecondsSinceEpoch.toString();// 13位到微秒 1651921468936
    Directory tempDir = await getTemporaryDirectory();
    return {
      'tmpDir': '${tempDir.path}/edit/$timestamp',
      'tmpMDPath': mdFile.path
    };
    // return '${tempDir.path}/edit/$timestamp';
  }
  // 初始化临时目录，包括创建info.json文件
  static Future<Directory> _createTmpFolder(DateTime time, bool needAssets) async {
    var timestamp = time.millisecondsSinceEpoch.toString();// 13位到微秒 1651921468936
    var year = time.year.toString().padLeft(4,'0');
    var month = time.month.toString().padLeft(2,'0');
    var day = time.day.toString().padLeft(2,'0');
    var hour = time.hour.toString().padLeft(2,'0');
    var minute = time.minute.toString().padLeft(2,'0');
    var second = time.second.toString().padLeft(2,'0');
    var millisecond = time.millisecond.toString().padLeft(3,'0'); // 毫秒
    // print('${year}-${month}-${day}-${hour}-${minute}-${second}-${millisecond}');

    Directory tempDir = await getTemporaryDirectory();
    var dir = Directory('${tempDir.path}/edit/$timestamp/$year/$month/$day.$hour$minute$second.$millisecond');
    if(!await dir.exists()){await dir.create(recursive: true);}

    // var infoJsonFile = File('${dir.path}/info.json');
    // if(!await infoJsonFile.exists()){await infoJsonFile.create(recursive: true);}
    if(needAssets){
      var assetsDir = Directory('${dir.path}/assets');
      if(!await assetsDir.exists()){await assetsDir.create(recursive: true);}
    }
    var mdFile = File('${dir.path}/${timestamp}.md');
    if(!await mdFile.exists()){await mdFile.create(recursive: true);}
    // print('日记临时路径: ${dir.path}');
    print('日记临时路径: $mdFile');
    return dir;
  }
  /// 移动、分割、重命名文件
  /// 返回原路径:移动后的新相对路径
  /// from:需要移动的文件路径数组
  /// previewFrom:预览文件路径数组，与from一一对应，比如视频文件或者超大图片
  /// to:目标路径
  /// limit:限制文件大小，超过的会被分割成多个文件，单位：B
  /// needRename: 是否需要对文件进行重命名，如果是图片和视频，则重新命名，如是附件文件，则不需要重命名
  static Future<List<Map<String,String>>> _moveAndSplitFiles({required List<String> from, List<String>? previewFrom, required String to, int limit = 0, bool needRename = false}) async{
    List<Map<String,String>> res = [];
    for(int i = 0; i < from.length; i++){
      var filePath = from[i];
      var file = File(filePath);
      if(!await file.exists()){
        print('文件不存在了:' + filePath);
        continue;
      }
      var fileName = filePath.split('/').last;
      if(needRename){
        int l = 1;
        if(from.length < 10){ l = 1; }else if(from.length < 100){ l = 2; }else if(from.length < 1000){ l = 3; }else if(from.length < 10000){ l = 4; }else if(from.length < 100000){ l = 5; }
        var suffix = fileName.split('.').length >= 2 ? '.${fileName.split('.').last}' : '';
        fileName = i.toString().padLeft(l,'0') + '_' + _generateRandomString(8) + suffix; // 01_E10ADC39_435_1034.jpg
      }
      var newPath = '$to/assets/$fileName';
      // print(newPath);
      var length = await file.length();
      // print('length:'+length.toString());
      if(length <= limit || limit <= 0){
        await file.copy(newPath); // await file.rename(newPath);
      }else{ // 分割
        RandomAccessFile fh = await file.open();
        int offX = 0;
        int index = 1;
        while(offX < length){
          int residue = length - offX; // 剩余大小
          int readSize = residue >= limit ? limit : residue;
          var chunkValue = (await fh.read(readSize)).toList();
          offX = offX + readSize;
          //
          var newFilePart = File(newPath + '.' + index.toString().padLeft(3,'0'));
          if(!await newFilePart.exists()){await newFilePart.create(recursive: true);}
          await newFilePart.writeAsBytes(chunkValue);
          index ++;
        }
        await fh.close();
      }
      // res[filePath] = newPath;
      // 预览文件名是在原文件名之后添加后缀
      var previewPath = previewFrom?[i];
      String? previewFileName;
      if(previewPath != null && previewPath.isNotEmpty){
        previewFileName = previewPath.split('/').last;
        var previewSuffix = previewFileName.split('.').length >= 2 ? '.${previewFileName.split('.').last}' : '';
        previewFileName = fileName + '.preview' + previewSuffix;
        var newPreviewPath = '$to/assets/$previewFileName';
        var previewFile = File(previewPath);
        await previewFile.copy(newPreviewPath);
      }
      res.add({
        'path':'assets/$fileName',
        'previewPath':previewFileName != null ? 'assets/$previewFileName' : ''
      });
    }
    return res;
  }

  static String _generateRandomString(int length) {
    final _random = Random();
    const _availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    final randomString = List.generate(length, (index) => _availableChars[_random.nextInt(_availableChars.length)]).join();
    return randomString;
  }
  static String _imgTableHtml({required List<String> paths,  required int columnNumber}){
    int column = 0;
    var str = '';
    var tdStr = '';
    for(int i = 0; i < paths.length; i++){
      tdStr = tdStr + '<td><img src="${paths[i]}" /></td>\n';
      column ++;
      if(column == columnNumber || i >= paths.length - 1){
        str = str + '<table width="100%"><tr>\n$tdStr</tr></table>\n';
        column = 0;
        tdStr = '';
      }
    }
    return str;
  }
  static String _videoHtml({required List<String> paths,  List<String>? previewPaths}){
    String str = '';
    for(int i = 0; i < paths.length; i++){
      var p = paths[i];
      var pre = previewPaths?[i];
      str = str + '<video poster="${pre ?? ''}" controls><source src="$p"></video>\n';
    }
    return str;
  }
  static String _mapHtml(GPSItem? gps){
    if(gps == null || gps.latitude == null || gps.longitude == null){ return ''; }
    var lat = double.parse(gps.latitude!);
    var lon = double.parse(gps.longitude!);
    var mapUrl = "https://www.openstreetmap.org/export/embed.html?bbox=${lon-0.05}%2C${lat-0.05}%2C${lon+0.05}%2C${lat+0.05}&marker=$lat%2C$lon&layers=ND";
    var map = '<iframe latitude="$lat" longitude="$lon" width="100%" height="300" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="$mapUrl" style="border: 1px solid black"></iframe>\n';
    return map;
  }

}