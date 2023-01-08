import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:extended_image/extended_image.dart';
// import 'package:chewie_example/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';

class VideoPlayer extends StatefulWidget {
  String videoPath;
  VideoPlayer({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoPlayerState();
  }
}

class _VideoPlayerState extends State<VideoPlayer> {
  TargetPlatform? _platform;
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  GlobalKey<_VideoPlayerState> slidePagekey = GlobalKey<_VideoPlayerState>();

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    // _videoPlayerController1 = VideoPlayerController.network(srcs[currPlayIndex]);
    // _videoPlayerController2 = VideoPlayerController.network(srcs[currPlayIndex]);
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
    await Future.wait([_videoPlayerController.initialize(),]);
    _createChewieController();
    setState(() {});
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
      allowedScreenSleep: false,
      // overlay:Container(
      //   width: 20,
      //   height: 20,
      //   color: Colors.red,
      // ),
      // isLive: true,
      // customControls:Container(
      //   width: 20,
      //   height: 20,
      //   color: Colors.blue,
      // ),
      // additionalOptions: (context) {
      //   return <OptionItem>[
      //     OptionItem(
      //       onTap: shareVideo,
      //       iconData: Icons.live_tv_sharp,
      //       title: 'Save To ...',
      //     ),
      //   ];
      // },
      hideControlsTimer: const Duration(seconds: 3),

      // 退出全屏后，限制屏幕不旋转
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );
  }

  Future<void> shareVideo() async {
    // 导出视频
    // _videoPlayerController.play();
    _chewieController?.enterFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( //导航栏
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset('static/images/nav_close.svg',color: Colors.white,), // fromRGBO(83, 83, 83, 1)
        ),
        backgroundColor: Colors.black,
        elevation: 0,//隐藏底部阴影分割线
        // bottom: null,
      ),
      body: SafeArea(
        child: Center(
          child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!,)
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading'),
            ],
          ),
        ),
      )
    );
  }
}