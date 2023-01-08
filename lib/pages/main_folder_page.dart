
import 'package:flutter/material.dart';
import 'package:treediary/repo/note_info.dart';
import 'package:treediary/widgets/viewer/folder_viewer.dart';
import 'package:provider/provider.dart';
import '../config/global_data.dart';
import '../provider/global_color.dart';
import '../provider/repo_list_model.dart';
import '../utils/event_bus.dart';

class MainFolderPage extends StatefulWidget {

  const MainFolderPage({Key? key}) : super(key: key);

  @override
  MainFolderPageState createState() {
    return MainFolderPageState();
  }
}

class MainFolderPageState extends State<MainFolderPage> with SingleTickerProviderStateMixin {

  List<NoteInfo> notes = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var currentRepo = Provider.of<RepoListModel>(context, listen:true).currentSelectedRepo;
    if(currentRepo == null){ return Container(); }
    return Scaffold(
      backgroundColor: colors.bgBodyBase_2,
      body: SafeArea(
        bottom: false,
        child: FolderViewer(path: currentRepo.fullPath)
      )
    );
  }
}