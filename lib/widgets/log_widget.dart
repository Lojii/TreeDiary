
import 'package:flutter/material.dart';

import '../provider/global_color.dart';

@immutable
class LogWidget extends StatefulWidget {

  List<String> logs = [];

  // addLogs(List<String> list){
  //   logs.addAll(list);
  // }

  LogWidget({Key? key,  required this.logs}) : super(key: key);

  @override
  _LogWidgetState createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  final ScrollController _controller = ScrollController();


  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {

    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1000.0,
        child: ListView(
          controller: _controller,
          children: <Widget>[
            ..._fetchLogWidgets(),
          ],
          padding: const EdgeInsets.only(left: 15,right: 15,bottom: 10),
        ),
      ),
    );
  }

  List<Widget> _fetchLogWidgets() {
    var colors =  C.current(context);
    List<Widget> texts = [];
    for (var msg in widget.logs) {
      texts.add(Text(msg, style: TextStyle(color: colors.tintPrimary,fontSize: F.f14),));
    }
    return texts;
  }

}