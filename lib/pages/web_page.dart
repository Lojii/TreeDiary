
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../provider/global_color.dart';
import '../provider/global_language.dart';

class WebPage extends StatefulWidget {

  final String title;
  final String url;

  const WebPage({Key? key, this.title = '', required this.url}) : super(key: key);

  @override
  _WebPageState createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> with WidgetsBindingObserver{

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
    return Scaffold(
        appBar: AppBar( //导航栏
          titleSpacing:0,
          title: Text(widget.title, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
          leading: IconButton(
            onPressed: () { Navigator.pop(context); },
            icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
          ),
          backgroundColor: colors.bgBodyBase_1,
          elevation: 0.5,
        ),
        backgroundColor: colors.bgBodyBase_1,
        body: InAppWebView(
          initialUrlRequest:URLRequest(url: Uri.parse(widget.url))
        )
    );
  }
}
