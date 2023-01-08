
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:treediary/widgets/viewer/photo_viewer.dart';
import 'package:treediary/widgets/viewer/web_viewer.dart';
import '../../pages/file_viewer_page.dart';
import '../../provider/global_color.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_all/flutter_html_all.dart';
import 'package:dart_markdown/dart_markdown.dart' as md;
import 'package:photo_view/photo_view.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../utils/utils.dart';


/// TODO:限制浏览doc/PlantingNote/xxx 之下的文件夹
class MDViewer extends StatefulWidget {
  final String mdStr;
  final String basePath;

  const MDViewer({Key? key, required this.mdStr, required this.basePath}) : super(key: key);
  @override
  _MDViewerState createState() => _MDViewerState();
}

class _MDViewerState extends State<MDViewer> {

  String htmlStr = '';

  @override
  void initState() {
    super.initState();
    _convertMDToHtml();

    // if (Platform.isAndroid) {
    //   AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    // }
  }

  void _convertMDToHtml(){
    // print(widget.basePath);
    // print(widget.mdStr);
    var html = md.markdownToHtml(
      widget.mdStr,
      enableHeadingId: true,
      enableKbd: true,
      enableSubscript: true,
      enableSuperscript: true,
      enableHighlight: true,
      enableFootnote: true,
      enableTaskList: true,
    );
    // print('--------');
    // print(html);
    // print('--------');
    setState(() {
      htmlStr = html;
    });
  }

  String _convertRelativeToAbsolute(String basePath, String relativePath){
    List<String> pathPart = basePath.split('/');
    if(pathPart.last.isEmpty){
      pathPart.removeLast();
    }
    String relative = relativePath;
    if(relative.startsWith('./')){
      relative = relative.substring(2);
    }
    var relativePart = relative.split('../');
    if(relativePath.length > 1){
      int ddg = relativePart.length - 1;
      for(int i = 0; i < ddg; i++){
        pathPart.removeLast();
      }
      relative = relativePart.last;
    }
    var url = pathPart.join('/') + '/' + relative;
    return url;
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);

    var body = Html(
      data: htmlStr,
      customRenders: {
        // relativeSrcImageMatcher() : fileImageRender(filePath: (url) {
        //   var decodePath = url ?? '';
        //   try{
        //     decodePath = Uri.decodeComponent(decodePath);
        //   }catch(e){
        //     print('解码$url失败：$e');
        //   }
        //   return _convertRelativeToAbsolute(widget.basePath, decodePath);
        // }),//
        relativeSrcImageMatcher() : localImageRender(mapUrl: (url) {
          var decodePath = url ?? '';
          try{
            decodePath = Uri.decodeComponent(decodePath);
          }catch(e){
            print('解码$url失败：$e');
          }
          return _convertRelativeToAbsolute(widget.basePath, decodePath);
        }),//
        //
        iframeMatcher(): iframeRender(),
        svgTagMatcher(): svgTagRender(),
        svgDataUriMatcher(): svgDataImageRender(),
        svgAssetUriMatcher(): svgAssetImageRender(),
        svgNetworkSourceMatcher(): svgNetworkImageRender(),
        videoMatcher(): videoRender(),
        mathMatcher(): mathRender(),
        audioMatcher(): audioRender(),
        tableMatcher(): tableRender(),
      },
      onImageError: (Object exception, StackTrace? stackTrace){
        // print(exception);
        // print(stackTrace);
      },
      onImageTap: ( String? url, RenderContext rContext, Map<String, String> attributes, element,){
        Utils.showPhoto(context, url);
      },
      onAnchorTap: ( String? url, RenderContext rContext, Map<String, String> attributes, element,){
        // [普通链接](http://localhost/)
        // [普通链接带标题](http://localhost/ "普通链接带标题")
        // 直接链接：<https://github.com>
        // [锚点链接][anchor-id]
        // [anchor-id]: http://www.this-anchor-link.com/
        // [mailto:test.test@gmail.com](mailto:test.test@gmail.com)
        // GFM a-tail link @pandao  邮箱地址自动链接 test.test@gmail.com  www@vip.qq.com

        print('------ : onAnchorTap');
        print(url);
        print(attributes);
        print('------');
        if(url != null && url.isNotEmpty){
          if(url.contains(':')){ // 网络链接
            WebBrowser.open(url);
          }else{
            try{
              url = Uri.decodeComponent(url);
            }catch(e){
              print('解码$url失败：$e');
            }
            String absolutePath = _convertRelativeToAbsolute(widget.basePath, url!);
            if(File(absolutePath).existsSync()){
              Navigator.push(context, MaterialPageRoute(builder: (context)=> FileViewer(path: absolutePath)));
            }else{
              print('$absolutePath不存在');
            }
          }
        }
      },
      style: {
        "*": Style(
          color: colors.tintPrimary,
          fontSize: FontSize(F.f16),
          lineHeight:const LineHeight(1.5)
        ),
        "a": Style( color: Colors.lightBlue, ),
        "img": Style( color: Colors.lightBlue, ),
        "h1": Style( fontSize: const FontSize(26), ),
        "h2": Style( fontSize: const FontSize(24), ),
        "h3": Style( fontSize: const FontSize(22), ),
        "h4": Style( fontSize: const FontSize(20), ),
        "h5": Style( fontSize: const FontSize(18), ),
        "h6": Style( fontSize: const FontSize(16), ),
        "hr,tr": Style(border: Border.fromBorderSide(BorderSide(color: colors.tintSeparator, width : 0.5, style : BorderStyle.solid,)),),
        "td": Style( alignment: Alignment.topCenter, ),
        "th": Style( padding: const EdgeInsets.only(left: 5,right: 5),  backgroundColor: colors.bgOnBody_3, ),
      },
    );
    return Container(
      color: colors.bgBodyBase_2,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(bottom: 40),
          child: body,
        ),
      ),
    );
  }
}


CustomRender localImageRender({
  // Map<String, String>? headers,
  String Function(String?)? mapUrl,
  double? width,
  double? height,
  Widget Function(String?)? altWidget,
  Widget Function()? loadingWidget,
}) => CustomRender.widget(widget: (context, buildChildren) {

  final src = mapUrl?.call(_src(context.tree.element!.attributes.cast())) ?? _src(context.tree.element!.attributes.cast())!;
  Completer<Size> completer = Completer();
  Image? cacheImage;
  if (context.parser.cachedImageSizes[src] != null) {
    completer.complete(context.parser.cachedImageSizes[src]);
  } else {
    Image image = Image.file(File(src), frameBuilder: (ctx, child, frame, _) {
      if (frame == null) {
        if (!completer.isCompleted) {
          completer.completeError("error");
        }
        return child;
      } else {
        return child;
      }
    },cacheWidth: 3000,);// 尺寸过大的图片，比如6000或7000的图片，会占用巨量内存，会导致OMM
    cacheImage = image;
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
      var myImage = imageInfo.image;
      Size size = Size(myImage.width.toDouble(), myImage.height.toDouble());
      // print(size);
      // double w = size.width;
      // double h = size.height;
      // if(w > 3000){
      //   w = 3000;
      //   h = w * size.height / size.width;
      //   size = Size(w, h);
      //   // print('change to $size');
      // }
      if (!completer.isCompleted) {
        context.parser.cachedImageSizes[src] = size;
        completer.complete(size);
        image.image.resolve(const ImageConfiguration()).removeListener(listener!);
      }
    }, onError: (object, stacktrace) {
      if (!completer.isCompleted) {
        completer.completeError(object);
        image.image.resolve(const ImageConfiguration()).removeListener(listener!);
      }
    });

    image.image.resolve(const ImageConfiguration()).addListener(listener);

  }
  final attributes = context.tree.element!.attributes.cast<String, String>();
  final widget = FutureBuilder<Size>(
    future: completer.future,
    initialData: context.parser.cachedImageSizes[src],
    builder: (BuildContext buildContext, AsyncSnapshot<Size> snapshot) {
      if (snapshot.hasData) {
        return Container(
          constraints: BoxConstraints(
              maxWidth: width ?? _width(attributes) ?? snapshot.data!.width,
              maxHeight:
              (width ?? _width(attributes) ?? snapshot.data!.width) /
                  _aspectRatio(attributes, snapshot)),
          child: AspectRatio(
            aspectRatio: _aspectRatio(attributes, snapshot),
            child: cacheImage ?? Image.file(File(src),
              width: width ?? _width(attributes) ?? snapshot.data!.width,
              height: height ?? _height(attributes),
              frameBuilder: (ctx, child, frame, _) {
                if (frame == null) { return altWidget?.call(_alt(attributes)) ?? Text(_alt(attributes) ?? "", style: context.style.generateTextStyle()); }
                return child;
              },
              cacheWidth: 3000,
            )
          ),
        );
      } else if (snapshot.hasError) {
        return altWidget?.call(_alt(context.tree.element!.attributes.cast())) ?? Text(_alt(context.tree.element!.attributes.cast()) ?? "", style: context.style.generateTextStyle());
      } else {
        return loadingWidget?.call() ?? const CircularProgressIndicator();
      }
    },
  );
  return Builder(
      key: context.key,
      builder: (buildContext) {
        return GestureDetector(
          child: widget,
          onTap: () {
            // if (MultipleTapGestureDetector.of(buildContext) != null) {
            //   MultipleTapGestureDetector.of(buildContext)!.onTap?.call();
            // }
            context.parser.onImageTap?.call(
                src,
                context,
                context.tree.element!.attributes.cast(),
                context.tree.element
            );
          },
        );
      }
  );
});

CustomRenderMatcher relativeSrcImageMatcher() => (context) {
  var localName = context.tree.element?.localName?.toLowerCase() ?? '';
  if(localName != 'img'){ return false; }
  var src = context.tree.element?.attributes["src"]?.toLowerCase() ?? '';
  if(src.startsWith('http://') || src.startsWith('https://') || src.isEmpty){
    return false;
  }
  return true;
};

CustomRender fileImageRender({ String Function(String?)? filePath,  double? width,  double? height,}) => CustomRender.widget(widget: (context, buildChildren) {
  var oSrc = _src(context.tree.element!.attributes.cast()) ?? '';
  final src = filePath?.call(oSrc) ?? oSrc;
  // var img = Image(
  //   // image: Image,
  // );
  var widget = File(src).existsSync() ? Image.file(
    File(src),
    width: width ?? _width(context.tree.element!.attributes.cast()),
    height: height ?? _height(context.tree.element!.attributes.cast()),
    frameBuilder: (ctx, child, frame, _) {
      print('frameBuilder');
      if (frame == null) {
        return Text(_alt(context.tree.element!.attributes.cast()) ?? "", style: context.style.generateTextStyle());
      }
      return child;
    },
  ) : Container(
    width: 10,
    height: 10,
    color: Colors.transparent,
  );
  // var widget = FutureBuilder(builder: builder);
  return Builder(
    key: context.key,
    builder: (buildContext) {
      return GestureDetector(
        child: Container(
          padding: const EdgeInsets.only(bottom: 10),
          child: widget,
        ),
        onTap: () {
          context.parser.onImageTap?.call(src, context, context.tree.element!.attributes.cast(), context.tree.element);
        },
      );
    }
  );
});

String? _src(Map<String, String> attributes) { return attributes["src"]; }

String? _alt(Map<String, String> attributes) { return attributes["alt"]; }

double? _width(Map<String, String> attributes) {
  final widthString = attributes["width"];
  return widthString == null ? widthString as double? : double.tryParse(widthString);
}

double? _height(Map<String, String> attributes) {
  final heightString = attributes["height"];
  return heightString == null ? heightString as double? : double.tryParse(heightString);
}

double _aspectRatio(
    Map<String, String> attributes, AsyncSnapshot<Size> calculated) {
  final heightString = attributes["height"];
  final widthString = attributes["width"];
  if (heightString != null && widthString != null) {
    final height = double.tryParse(heightString);
    final width = double.tryParse(widthString);
    return height == null || width == null
        ? calculated.data!.aspectRatio
        : width / height;
  }
  return calculated.data!.aspectRatio;
}
