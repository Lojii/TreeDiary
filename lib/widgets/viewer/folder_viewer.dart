
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:math';
import 'package:treediary/pages/file_browser_page.dart';
import 'package:treediary/pages/file_viewer_page.dart';

import '../../config/global_data.dart';
import '../../pages/main_page.dart';
import '../../provider/global_color.dart';
import '../../provider/global_language.dart';
import '../../provider/repo_list_model.dart';
import '../../repo/repo_manager.dart';
import '../../utils/event_bus.dart';
import '../../utils/utils.dart';
import '../common/rotation_widget.dart';

class FileEntity {
  String path;
  FileSystemEntityType type;
  String fileType;
  int size = 0;
  DateTime? modified;

  String get modifiedStr {
    var str = modified.toString();
    return str.split('.').first;
  }

  String get sizeStr => Utils.bytesConverter(size);

  String get name => path.split('/').last;

  Widget get icon {
    return SvgPicture.asset(type == FileSystemEntityType.file ? 'static/images/home_file.svg' : 'static/images/home_folder.svg');
  }

  FileEntity({required this.path, required this.type, required this.fileType, this.size = 0, this.modified});
}

/// 限制浏览doc/PlantingNote/xxx 之下的文件夹
class FolderViewer extends StatefulWidget {
  final String path;
  const FolderViewer({Key? key,  required this.path}) : super(key: key);
  @override
  _FolderViewerState createState() => _FolderViewerState();
}

class _FolderViewerState extends State<FolderViewer> {

  List<FileEntity> items = [];
  bool isLoading = true;
  String? errorMsg;

  String oldPath = '';

  @override
  void initState() {
    super.initState();
    String repoBaseDir = Global.repoBaseDir;
    L language = L.current(context,listen: false);
    if(!widget.path.contains(repoBaseDir) || widget.path == repoBaseDir || widget.path == '$repoBaseDir/'){
      setState(() {
        isLoading = false;
        errorMsg = language.cannot_access;
      });
      return;
    }
  }


  @override
  void dispose() {
    super.dispose();
  }

  void _scanFolders() async{
    // print(widget.path);
    Stream<FileSystemEntity> fileList = Directory(widget.path).list();
    var isRepoRoot = !widget.path.split(Global.repoBaseDir+'/').last.contains('/');

    List<FileEntity> allDir = [];
    List<FileEntity> allFile = [];
    await for(FileSystemEntity fileSystemEntity in fileList){
      FileSystemEntityType type = FileSystemEntity.typeSync(fileSystemEntity.path);
      if(type == FileSystemEntityType.directory && fileSystemEntity.path.endsWith('.git') && isRepoRoot){ continue; } // 过滤根目录的.git文件夹
      var stat = await fileSystemEntity.stat();
      int size = stat.size;
      DateTime modified = stat.modified;
      String fileType = '';
      if(type == FileSystemEntityType.file){
        var ss = fileSystemEntity.path.split('/').last.split('.');
        if(ss.length >= 2){ fileType = ss.last; }
      }
      var fe = FileEntity(path: fileSystemEntity.path, type: type, fileType: fileType, size: size, modified: modified);
      if(type == FileSystemEntityType.directory){
        allDir.add(fe);
      }else{
        allFile.add(fe);
      }
    }
    /// 排序
    allDir.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    allFile.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    List<FileEntity> all = [];
    all.addAll(allDir);
    all.addAll(allFile);
    setState(() {
      isLoading = false;
      items = all;
      errorMsg = null;
    });
  }

  _itemDidClick(FileEntity item){
    if(item.type == FileSystemEntityType.directory){
      Navigator.push(context, MaterialPageRoute(builder: (context)=> FileBrowser(path: item.path)));
    }else{
      Navigator.push(context, MaterialPageRoute(builder: (context)=> FileViewer(path: item.path)));
    }
  }

  Widget _fileItem(FileEntity item){
    var colors =  C.current(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: (){
          _itemDidClick(item);
        },
        child: ClipRRect(
          borderRadius:BorderRadius.circular(5),
          child: Container(
            color: colors.bgOnBody_1,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(right: 10,left: 10),
                  child: item.icon,
                ),
                Expanded(child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(item.name, style: TextStyle(color: colors.tintPrimary, fontSize: F.f16, fontWeight: FontWeight.w500),)
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.modifiedStr,style: TextStyle(color: colors.tintTertiary, fontSize: F.f14),),
                          ),
                          if(item.type == FileSystemEntityType.file)
                            Container(
                              padding: const EdgeInsets.only(top: 5,right: 10,bottom: 5),
                              child: Text(item.sizeStr,style: TextStyle(color: colors.tintTertiary, fontSize: F.f14),textAlign: TextAlign.right,),
                            )
                        ],
                      )
                    ],
                  )
                )
              ],
            ),
          )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if(oldPath != widget.path){
      oldPath = widget.path;
      _scanFolders();
    }

    var colors =  C.current(context);
    if(isLoading){
      return Center(
        child: RotationWidget(
          child: SvgPicture.asset('static/images/state_loading.svg',width: 50,height: 50,color: colors.tintPrimary,),
        ),
      );
    }
    if(errorMsg != null){
      return Center(
        child: Container(
          padding: const EdgeInsets.only(left: 30,right: 30),
          child: Text(errorMsg ?? '',style: TextStyle(color: colors.tintPrimary, fontSize: F.f16),textAlign: TextAlign.center,),
        ),
      );
    }

    return Container(
      color: colors.bgBodyBase_2,
      child: ListView(
        children: <Widget>[
          const SizedBox(height: 5,),
          ...items.map((e) => _fileItem(e)),
        ],
        padding: const EdgeInsets.only(left: 15,right: 15, bottom: 40),
      ),
    );
  }
}