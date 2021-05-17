import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:ytdownloader/modals/videoinfo.dart';
import 'package:ytdownloader/views/views.dart';
part 'videocontroller.g.dart';

class VideoController extends GetxController {
  var yt = YoutubeExplode();
  var pageController = PageController();
  Rxn<VideoInfo> videoInfo = Rxn<VideoInfo>();
  var url = TextEditingController();
  var image = ''.obs;
  var dio = Dio();
  var fetchingData = false.obs;
  var focusNode = FocusNode();
  var cancelToken = CancelToken();
  var currentIndex = 0.obs;
  var downloadTasks = RxList<TaskInfo>();
  ReceivePort _port = ReceivePort();
  Box<TaskInfo> downloadsBox;

  fetchInfo(String url) async {
    if (url.isEmpty) return;
    url = url.replaceAll('be.com/shorts', '.be');
    fetchingData.value = true;
    var videoInfoTemp = VideoInfo();
    videoInfoTemp.streamInfo = await yt.videos.streamsClient.getManifest(url);
    videoInfoTemp.video = await yt.videos.get(url);
    videoInfo.value = videoInfoTemp;
    fetchingData.value = false;
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    print(isSuccess);
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen(
      (dynamic data) {
        String id = data[0];
        DownloadTaskStatus status = data[1];
        int progress = data[2];
        if (downloadsBox != null) {
          if (status == DownloadTaskStatus.complete) {
            Get.snackbar(
              'Download Completed',
              'File Downloaded Successfully',
              snackPosition: SnackPosition.TOP,
            );
          }
          final index = downloadsBox.values.toList().indexWhere(
                (task) => task.taskId == id,
              );
          if (index != -1) {
            var item = downloadsBox.getAt(index);
            item.status = status.value;
            item.progress = progress;
            item.taskId = id;
            downloadsBox.putAt(index, item);
          } else {
            loadDownloadingTask(id);
          }
        }
      },
    );
  }

  loadAllTasks() async {
    // for (var item in await FlutterDownloader.loadTasks()) {
    //   downloadsBox.add(new TaskInfo(
    //     name: item.filename,
    //     link: item.url,
    //     progress: item.progress,
    //     status: item.status.value,
    //     taskId: item.taskId,
    //   ));
    // }
  }
  Future<List<DownloadTask>> getTaskInfo(String taskId) async {
    return await FlutterDownloader.loadTasksWithRawQuery(
            query: 'SELECT * FROM task WHERE task_id=\'$taskId\'')
        .then((value) => value);
  }

  loadDownloadingTask(String taskId) async {
    var list = await FlutterDownloader.loadTasksWithRawQuery(
      query: 'SELECT * FROM task WHERE task_id=\'$taskId\'',
    );
    if (list != null)
      for (var item in list) {
        final index = downloadsBox.values.toList().indexWhere(
              (task) => task.taskId == item.taskId,
            );
        if (index == -1)
          await downloadsBox.add(
            new TaskInfo(
              name: item.filename,
              link: item.url,
              progress: item.progress,
              status: item.status.value,
              taskId: item.taskId,
            ),
          );
      }
  }

  downloadVideo(String url, String filename) async {
    if (await Permission.storage.request().isGranted) {
      if (await File((await getExternalStorageDirectories(
                      type: StorageDirectory.downloads))
                  .first
                  .path +
              Platform.pathSeparator +
              filename)
          .exists()) {
        Get.snackbar(
          'Already Exists',
          'Video you are trying to download already exists!',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      if (kIsWeb) {
        html.AnchorElement anchorElement = new html.AnchorElement(href: url);
        anchorElement.download = url;
        anchorElement.click();
      } else {
        await FlutterDownloader.enqueue(
          url: url,
          savedDir: (await getExternalStorageDirectories(
                  type: StorageDirectory.downloads))
              .first
              .path,
          fileName: filename,
        );
        Get.snackbar(
          'Started Downloaded',
          'File $filename has started to downloaded',
          snackPosition: SnackPosition.TOP,
        );
      }
    }
  }

  @override
  Future<void> onInit() async {
    downloadsBox = await Hive.openBox<TaskInfo>('downloads');
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    loadAllTasks();
    super.onInit();
  }
}

@HiveType(typeId: 0)
class TaskInfo {
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String link;
  @HiveField(3)
  String taskId;
  @HiveField(4)
  int progress = 0;
  @HiveField(5)
  int status;
  TaskInfo({
    this.name,
    this.link,
    this.taskId,
    this.progress,
    this.status,
  });
}

// class _ItemHolder {
//   final String name;
//   final TaskInfo task;

//   _ItemHolder({this.name, this.task});
// }

class DownloadTaskStatuss {
  final int _value;

  const DownloadTaskStatuss(int value) : _value = value;

  int get value => _value;

  static DownloadTaskStatuss from(int value) => DownloadTaskStatuss(value);

  static const undefined = const DownloadTaskStatuss(0);
  static const enqueued = const DownloadTaskStatuss(1);
  static const running = const DownloadTaskStatuss(2);
  static const complete = const DownloadTaskStatuss(3);
  static const failed = const DownloadTaskStatuss(4);
  static const canceled = const DownloadTaskStatuss(5);
  static const paused = const DownloadTaskStatuss(6);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is DownloadTaskStatuss && o._value == _value;
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'DownloadTaskStatus($_value)';
}
