
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight_background.dart';
import 'package:flutter_svg/svg.dart';
import '../../provider/global_color.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

import '../common/rotation_widget.dart';

/// TODO:限制浏览doc/PlantingNote/xxx 之下的文件夹
class HighlightViewer extends StatefulWidget {
  final String str;
  final String path;
  final bool autoLine;

  const HighlightViewer({Key? key, required this.str, required this.path, this.autoLine = false}) : super(key: key);
  @override
  _HighlightViewerState createState() => _HighlightViewerState();
}

class _HighlightViewerState extends State<HighlightViewer> {

  String htmlStr = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);


    Map<String,TextStyle> theme = {};
    if(colors.isLight){
      a11yLightTheme.forEach((key, value) { theme[key] = value; });
    }else{
      a11yDarkTheme.forEach((key, value) { theme[key] = value; });
    }
    theme['root'] = TextStyle(backgroundColor: colors.bgBodyBase_2, color:colors.tintPrimary);
    /// 长按选择，有几率跳动，flutter的bug，https://github.com/flutter/flutter/issues/84480 等版本更新修复
    var body = HighlightBackgroundEnvironment(
      child: HighlightView(
        widget.str,
        language: widget.path.split('.').last,
        theme: theme,
        padding: const EdgeInsets.all(10),
        textStyle: TextStyle( fontSize: F.f16, ),
        progressIndicator: Center(
          child: RotationWidget(
            child: SvgPicture.asset('static/images/state_loading.svg',width: 50,height: 50,color: colors.tintPrimary,),
          )
        )
      )
    );
    return Container(
      color: colors.bgBodyBase_2,
      child: body
    );
  }
}
