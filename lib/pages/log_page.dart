// import 'package:flutter/cupertino.dart';

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/model/video_item.dart';
import 'package:treediary/pages/setting_userinfo_page.dart';
import 'package:provider/provider.dart';

import '../model/gps_item.dart';
import '../repo/note_info.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/task_model.dart';
import '../widgets/image_viewer.dart';
import '../widgets/log_widget.dart';
import '../widgets/video_player.dart';
import 'map_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:treediary/config/global_data.dart';

class LogPage extends StatefulWidget {

  String repoKey;
  String gitUrl;

  LogPage({Key? key, required this.repoKey, required this.gitUrl}) : super(key: key);

  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with WidgetsBindingObserver{

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    var syncTask = Provider.of<TaskModel>(context, listen:true).repoTask[widget.repoKey]?[widget.gitUrl];
    var logs = syncTask?.logs ?? [];
    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(language.logs, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
          ),
          backgroundColor: colors.bgBody_1,
          elevation: 0.5,
          actions: const <Widget>[
            /// log copy
          ],
        ),
        backgroundColor: colors.bgBody_1,
        body: SafeArea(
            child: LogWidget(logs: logs,)
        )
    );
  }
}
