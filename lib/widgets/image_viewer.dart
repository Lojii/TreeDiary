import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:vibration/vibration.dart';
import '../provider/global_color.dart';
import '../utils/utils.dart';
import 'hero.dart';

typedef DoubleClickAnimationListener = void Function();

class MySwiperPlugin extends StatelessWidget {
  const MySwiperPlugin({Key? key,this.pics, this.index, required this.reBuild}) : super(key: key);
  final List<String>? pics;
  final int? index;
  final StreamController<int> reBuild;
  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    return StreamBuilder<int>(
      builder: (BuildContext context, AsyncSnapshot<int> data) {
        return DefaultTextStyle(
          style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),
          child: Container(
            // height: 50.0,
            width: double.infinity,
            // color: colors.bgMask,
            color: Colors.transparent,
            padding: const EdgeInsets.only(top: 15,bottom: 15),
            child: Row(
              children: <Widget>[
                Container(width: 15.0,),
                Text('${data.data! + 1}',),
                Text(' / ${pics!.length}',),
              ],
            ),
          ),
        );
      },
      initialData: index,
      stream: reBuild.stream,
    );
  }
}

class ImageViewer extends StatefulWidget {
  const ImageViewer({Key? key, this.index, this.pics,}) : super(key: key);
  final int? index;
  final List<String>? pics;
  @override
  _ImageViewerState createState() => _ImageViewerState();

  static show({required BuildContext context, int? index, List<String>? pics}){
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
          //目标页面
          return ImageViewer(index: index,pics: pics,);
        },
        //打开新的页面用时
        transitionDuration: const Duration(milliseconds: 300),
        //关半页岩用时
        reverseTransitionDuration: const Duration(milliseconds: 300),
        //过渡动画构建
        transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child,) {
          //渐变过渡动画
          return FadeTransition(
            // 透明度从 0.0-1.0
            opacity: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                //动画曲线规则，这里使用的是先快后慢
                curve: Curves.fastOutSlowIn,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }
}

class _ImageViewerState extends State<ImageViewer> with TickerProviderStateMixin {
  final StreamController<int> rebuildIndex = StreamController<int>.broadcast();
  final StreamController<bool> rebuildSwiper = StreamController<bool>.broadcast();
  final StreamController<double> rebuildDetail = StreamController<double>.broadcast();
  late AnimationController _doubleClickAnimationController;
  late AnimationController _slideEndAnimationController;
  late Animation<double> _slideEndAnimation;
  Animation<double>? _doubleClickAnimation;
  late DoubleClickAnimationListener _doubleClickAnimationListener;
  List<double> doubleTapScales = <double>[1.0, 2.0];
  GlobalKey<ExtendedImageSlidePageState> slidePagekey = GlobalKey<ExtendedImageSlidePageState>();
  int? _currentIndex = 0;
  bool _showSwiper = true;
  double _imageDetailY = 0;
  Rect? imageDRect;
  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    final Size size = MediaQuery.of(context).size;
    imageDRect = Offset.zero & size;
    Widget result = Material(
      /// if you use ExtendedImageSlidePage and slideType =SlideType.onlyImage,
      /// make sure your page is transparent background
      color: colors.bgBodyBase_2,//Colors.red,
      shadowColor: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ExtendedImageGesturePageView.builder(
            controller: ExtendedPageController( initialPage: widget.index!, pageSpacing: 50, shouldIgnorePointerWhenScrolling: false,),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            canScrollPage: (GestureDetails? gestureDetails) {
              return true;
              // return _imageDetailY >= 0;
              //return (gestureDetails?.totalScale ?? 1.0) <= 1.0;
            },
            itemBuilder: (BuildContext context, int index) {
              final String item = widget.pics![index];
              Widget image = ExtendedImage.file(
                  File(item),
              // );
              // Widget image = ExtendedImage.network(
              //   item,
                fit: BoxFit.contain,
                enableSlideOutPage: true,
                mode: ExtendedImageMode.gesture,
                // imageCacheName: 'GitImage',
                initGestureConfigHandler: (ExtendedImageState state) {
                  double? initialScale = 1.0;

                  if (state.extendedImageInfo != null) {
                    initialScale = initScale(
                        size: size,
                        initialScale: initialScale,
                        imageSize: Size(
                            state.extendedImageInfo!.image.width.toDouble(),
                            state.extendedImageInfo!.image.height
                                .toDouble()));
                  }
                  return GestureConfig(
                    inPageView: true,
                    initialScale: initialScale!,
                    maxScale: max(initialScale, 5.0),
                    animationMaxScale: max(initialScale, 5.0),
                    initialAlignment: InitialAlignment.center,
                    //you can cache gesture state even though page view page change.
                    //remember call clearGestureDetailsCache() method at the right time.(for example,this page dispose)
                    cacheGesture: false,
                  );
                },
                onDoubleTap: (ExtendedImageGestureState state) {
                  ///you can use define pointerDownPosition as you can,
                  ///default value is double tap pointer down postion.
                  final Offset? pointerDownPosition = state.pointerDownPosition;
                  final double? begin = state.gestureDetails!.totalScale;
                  double end;

                  //remove old
                  _doubleClickAnimation?.removeListener(_doubleClickAnimationListener);

                  //stop pre
                  _doubleClickAnimationController.stop();

                  //reset to use
                  _doubleClickAnimationController.reset();

                  if (begin == doubleTapScales[0]) {
                    end = doubleTapScales[1];
                  } else {
                    end = doubleTapScales[0];
                  }

                  _doubleClickAnimationListener = () {
                    //print(_animation.value);
                    state.handleDoubleTap(scale: _doubleClickAnimation!.value, doubleTapPosition: pointerDownPosition);
                  };
                  _doubleClickAnimation = _doubleClickAnimationController.drive(Tween<double>(begin: begin, end: end));
                  _doubleClickAnimation!.addListener(_doubleClickAnimationListener);
                  _doubleClickAnimationController.forward();
                },
                loadStateChanged: (ExtendedImageState state) {
                  if (state.extendedImageLoadState == LoadState.completed) {
                    return StreamBuilder<double>(
                      builder: (BuildContext context, AsyncSnapshot<double> data) {
                        return ExtendedImageGesture(
                          state,
                          canScaleImage: (_) => _imageDetailY == 0,
                          imageBuilder: (Widget image) {
                            return Stack(
                              children: <Widget>[
                                Positioned.fill(
                                  child: image,
                                  top: _imageDetailY,
                                  bottom: -_imageDetailY,
                                ),
                              ],
                            );
                          },
                        );
                      },
                      initialData: _imageDetailY,
                      stream: rebuildDetail.stream,
                    );
                  }
                  return null;
                },
              );

              // if (index < min(9, widget.pics!.length)) { // 控制hero动画，可以用来做，当前屏幕最多显示图片，如果显示在当前屏幕，则开启hero动画，如果不显示在当前页面，则可以考虑移除hero动画
                image = HeroWidget(child: image, tag: item, slideType: SlideType.onlyImage, slidePagekey: slidePagekey,);
              // }

              image = GestureDetector(
                child: image,
                onTap: () {
                  // if (_imageDetailY != 0) {
                  //   _imageDetailY = 0;
                  //   rebuildDetail.sink.add(_imageDetailY);
                  // } else {
                    slidePagekey.currentState!.popPage();
                    Navigator.pop(context);
                  // }
                },
                onLongPress: () async{
                  if(await Vibration.hasVibrator() ?? false) { Vibration.vibrate(duration:50, pattern: [40, 500,], amplitude: 255, intensities:  [255]); }
                  await Utils.showSavePhotoSheet(context, item);
                },
              );

              return image;
            },
            itemCount: widget.pics!.length,
            onPageChanged: (int index) { // 页面切换后，复原offY
              _currentIndex = index;
              rebuildIndex.add(index);
              if (_imageDetailY != 0) {
                _imageDetailY = 0;
                rebuildDetail.sink.add(_imageDetailY);
              }
              _showSwiper = true;
              rebuildSwiper.add(_showSwiper);
            },
          ),
          StreamBuilder<bool>(
            builder: (BuildContext c, AsyncSnapshot<bool> d) {
              if (d.data == null || !d.data!) {
                return Container();
              }
              return Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: MySwiperPlugin(pics:widget.pics, index:_currentIndex, reBuild:rebuildIndex),
              );
            },
            initialData: true,
            stream: rebuildSwiper.stream,
          )
        ],
      )
    );

    result = ExtendedImageSlidePage(
      key: slidePagekey,
      child: result,
      slideAxis: SlideAxis.vertical,
      slideType: SlideType.onlyImage,
    );

    return result;
  }

  @override
  void dispose() {
    rebuildIndex.close();
    rebuildSwiper.close();
    rebuildDetail.close();
    _doubleClickAnimationController.dispose();
    _slideEndAnimationController.dispose();
    clearGestureDetailsCache();
    //cancelToken?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _doubleClickAnimationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);

    _slideEndAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _slideEndAnimationController.addListener(() {
      _imageDetailY = _slideEndAnimation.value;
      if (_imageDetailY == 0) {
        _showSwiper = true;
        rebuildSwiper.add(_showSwiper);
      }
      rebuildDetail.sink.add(_imageDetailY);
    });
  }
}

double? initScale({required Size imageSize, required Size size, double? initialScale,}) {
  final double n1 = imageSize.height / imageSize.width;
  final double n2 = size.height / size.width;
  if (n1 > n2) {
    final FittedSizes fittedSizes =
    applyBoxFit(BoxFit.contain, imageSize, size);
    //final Size sourceSize = fittedSizes.source;
    final Size destinationSize = fittedSizes.destination;
    return size.width / destinationSize.width;
  } else if (n1 / n2 < 1 / 4) {
    final FittedSizes fittedSizes =
    applyBoxFit(BoxFit.contain, imageSize, size);
    //final Size sourceSize = fittedSizes.source;
    final Size destinationSize = fittedSizes.destination;
    return size.height / destinationSize.height;
  }

  return initialScale;
}