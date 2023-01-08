import 'package:flutter/material.dart';

class RotationWidget extends StatefulWidget {

  final Widget child;

  const RotationWidget({Key? key, required this.child}) : super(key: key);

  @override
  _RotationWidgetState createState() => _RotationWidgetState();
}

class _RotationWidgetState extends State<RotationWidget> with SingleTickerProviderStateMixin {
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
    return RotationTransition(
      turns: _animationController,
      child: widget.child,
    );
  }

}