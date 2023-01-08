import 'dart:ui';
/// describe
/// 高斯模糊效果合集
/// created by hujintao
/// created at 2019-09-12
//
import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fpdxapp/utils/screen.dart';

/// 矩形高斯模糊效果
class BlurRectWidget extends StatefulWidget {
  final Widget? child;

  /// 模糊值
  final double? sigmaX;
  final double? sigmaY;

  /// 透明度
  final double? opacity;

  /// 外边距
  final EdgeInsetsGeometry? blurMargin;

  /// 圆角
  final BorderRadius? borderRadius;

  const BlurRectWidget({
    Key? key,
    this.child,
    this.sigmaX,
    this.sigmaY,
    this.opacity,
    this.blurMargin,
    this.borderRadius,
  }) : super(key: key);

  @override
  _BlurRectWidgetState createState() => _BlurRectWidgetState();
}

class _BlurRectWidgetState extends State<BlurRectWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.blurMargin ?? EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.sigmaX ?? 10,
            sigmaY: widget.sigmaY ?? 10,
          ),
          child: Container(
            color: Colors.white10,
            child: widget.opacity != null
                ? Opacity(
              opacity: widget.opacity ?? 0,
              child: widget.child,
            )
                : widget.child,
          ),
        ),
      ),
    );
  }
}