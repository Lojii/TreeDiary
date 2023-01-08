
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../provider/global_color.dart';

class EmptyViewer extends StatefulWidget {
  final bool isBox;

  const EmptyViewer({Key? key, this.isBox = true}) : super(key: key);
  @override
  _EmptyViewerState createState() => _EmptyViewerState();
}

class _EmptyViewerState extends State<EmptyViewer> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var height = MediaQuery.of(context).size.height - 150;
    height = height < 200 ? 200 : height;
    String svgPath = colors.isLight ? 'static/images/empty_box_light.svg' : 'static/images/empty_box_dark.svg';
    if(!widget.isBox){
      svgPath = colors.isLight ? 'static/images/empty_list_light.svg' : 'static/images/empty_list_dark.svg';
    }
    return Center(
      child: Container(
        padding: const EdgeInsets.only(left: 60,right: 60),
        height: height,
        child: SvgPicture.asset(svgPath, width: 200, height: 200,),
      ),
    );
  }
}
