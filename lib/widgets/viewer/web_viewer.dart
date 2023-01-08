import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';


class Browser extends ChromeSafariBrowser {
  @override
  void onOpened() {
    print("ChromeSafari browser opened");
  }

  @override
  void onCompletedInitialLoad() {
    print("ChromeSafari browser initial load completed");
  }

  @override
  void onClosed() {
    print("ChromeSafari browser closed");
  }

  static openUrl(String? url){
    if(url == null || url.isEmpty){
      return;
    }
    var uri = Uri.tryParse(url);
    if(uri != null) {
      var browser = Browser();
      browser.addMenuItem(ChromeSafariBrowserMenuItem(
        id: 1,
        label: 'Custom item menu 1',
        action: (url, title) {
          print('Custom item menu 1 clicked!');
        }
      ));
      browser.open( url: uri,
        options: ChromeSafariBrowserClassOptions(
          android: AndroidChromeCustomTabsOptions(
            shareState: CustomTabsShareState.SHARE_STATE_ON
          ),
          ios: IOSSafariOptions(barCollapsingEnabled: true)
        )
      );
    }
  }
}

class WebBrowser extends InAppBrowser {

  @override
  Future onBrowserCreated() async {
    print("Browser Created!");
  }

  @override
  Future onLoadStart(url) async {
    print("Started $url");
  }

  @override
  Future onLoadStop(url) async {
    print("Stopped $url");
  }

  @override
  void onLoadError(url, code, message) {
    print("Can't load $url.. Error: $message");
  }

  @override
  void onProgressChanged(progress) {
    print("Progress: $progress");
  }

  @override
  void onExit() {
    print("Browser closed!");
  }

  static open(String? url){
    if(url == null || url.isEmpty){
      return;
    }
    var uri = Uri.tryParse(url);
    var options = InAppBrowserClassOptions(
      crossPlatform: InAppBrowserOptions(
        // hidden: true,
        // hideUrlBar: true,
        hideToolbarTop:true,
        // toolbarTopBackgroundColor:Colors.red
      ),
      inAppWebViewGroupOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(javaScriptEnabled: true)
      ),
      ios: IOSInAppBrowserOptions(
          // toolbarTopTranslucent: false,
          // toolbarTopTintColor: Colors.red,
          hideToolbarBottom:true,
          // toolbarBottomBackgroundColor: Colors.red,
          // toolbarBottomTintColor,
          toolbarBottomTranslucent: false,
          // closeButtonCaption,
          // closeButtonColor,
          presentationStyle: IOSUIModalPresentationStyle.PAGE_SHEET,
          // transitionStyle: IOSUIModalTransitionStyle.COVER_VERTICAL
      ),
      android: AndroidInAppBrowserOptions(
          hideTitleBar:false,
      )
    );
    if(uri != null){
      WebBrowser().openUrlRequest(urlRequest: URLRequest(url: uri), options: options);
    }
  }

}
