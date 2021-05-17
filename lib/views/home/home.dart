import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:get/get.dart';
import 'package:ytdownloader/controllers/videocontroller.dart';
import 'package:ytdownloader/views/donwloader/downloader.dart';
import 'package:ytdownloader/views/downloads/downloads.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

void downloadCallback(
  String id,
  DownloadTaskStatus status,
  int progress,
) {
  final SendPort send =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  send.send([id, status, progress]);
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  VideoController _videoController = Get.find();
  static const platform = MethodChannel('app.channel.shared.data');

  @override
  void initState() {
    super.initState();
    getSharedText();
  }

  void getSharedText() async {
    var sharedData = await platform.invokeMethod('getSharedText');
    if (sharedData != null) {
      _videoController.url.text = sharedData;
      _videoController.fetchInfo(_videoController.url.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.only(top: 8.0),
        child: Scaffold(
          appBar: CustAppBar(),
          bottomNavigationBar: Obx(
            () => SnakeNavigationBar.color(
              shadowColor: Colors.deepPurpleAccent,
              elevation: 16.0,
              snakeShape: SnakeShape.circle,
              snakeViewColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey,
              currentIndex: _videoController.currentIndex.value,
              onTap: (index) {
                _videoController.pageController.animateToPage(index,
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeIn);
              },
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home_outlined,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.download_outlined,
                  ),
                  label: 'Downloads',
                ),
              ],
            ),
          ),
          body: PageView(
            onPageChanged: (index) {
              _videoController.currentIndex.value = index;
            },
            controller: _videoController.pageController,
            children: [
              DownloaderPage(videoController: _videoController),
              DownloadsPage(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state.toString());
    if (state == AppLifecycleState.resumed) {
      getSharedText();
    }
    super.didChangeAppLifecycleState(state);
  }
}
