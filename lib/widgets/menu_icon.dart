import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/widgets/common/rotation_widget.dart';
import 'package:provider/provider.dart';

import '../provider/global_color.dart';
import '../provider/task_model.dart';

enum MenuIconType {
  normal,
  busy,
  // error,
}


class MenuIcon extends StatefulWidget {

  // MenuIconType state;
  double width;

  MenuIcon({Key? key, this.width = 26}) : super(key: key);

  @override
  _MenuIconState createState() => _MenuIconState();
}

class _MenuIconState extends State<MenuIcon> with SingleTickerProviderStateMixin {
  //动画控制器
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    Future.delayed(Duration.zero, (){ _animationController.repeat(); });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var isBusy = Provider.of<TaskModel>(context, listen:true).isBusy();
    Widget container;
    if(!isBusy){
      container = SvgPicture.asset('static/images/menu.svg', width: widget.width, height: widget.width,color: colors.tintPrimary,);
    }else{
      container = Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset('static/images/menu_busy.svg', width: widget.width, height: widget.width,color: colors.tintPrimary,),
          Align(
            alignment: Alignment.center,
            child: RotationWidget(
              child: SvgPicture.asset('static/images/menu_busy_in.svg', width: widget.width * 12 / 26, height: widget.width * 12 / 26,color: colors.tintPrimary),  // 12 * 12
            ),
          ),
        ],
      );
    }
    return container;
  }

}