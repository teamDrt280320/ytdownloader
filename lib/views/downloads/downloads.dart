import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ytdownloader/controllers/videocontroller.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DownloadsPage extends StatelessWidget {
  final VideoController controller = Get.find();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<TaskInfo>>(
        valueListenable: controller.downloadsBox.listenable(),
        builder: (context, snapshot, _) {
          return snapshot.isEmpty
              ? NoDownloadsText()
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: snapshot.length,
                    itemBuilder: (context, index) {
                      var downloadTask = snapshot.getAt(index);
                      var failed = downloadTask.status ==
                              DownloadTaskStatus.failed.value ||
                          downloadTask.status ==
                              DownloadTaskStatus.undefined.value ||
                          downloadTask.status ==
                              DownloadTaskStatus.canceled.value;
                      return failed
                          ? SizedBox.shrink()
                          : DownloadListTile(taskInfo: downloadTask);
                    },
                  ),
                );
        });
  }
}

class NoDownloadsText extends StatelessWidget {
  const NoDownloadsText({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No Downloads\nPlease Go back and download something',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.deepPurple,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class DownloadListTile extends StatelessWidget {
  final VideoController controller = Get.find();

  DownloadListTile({
    Key key,
    this.taskInfo,
  }) : super(key: key);
  final TaskInfo taskInfo;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 8),
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          height: kToolbarHeight * 2,
          decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.delete_outline_outlined,
                size: 36,
                color: Colors.red,
              ),
              Icon(
                Icons.delete_outline_outlined,
                size: 36,
                color: Colors.red,
              ),
            ],
          ),
        ),
        Dismissible(
          onDismissed: (direcion) async {
            await controller.downloadsBox.deleteAt(controller
                .downloadsBox.values
                .toList()
                .indexWhere((element) => element.taskId == taskInfo.taskId));
            FlutterDownloader.remove(taskId: taskInfo.taskId);
          },
          key: ValueKey(taskInfo.taskId),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            height: kToolbarHeight * 2,
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 3),
                    blurRadius: 10,
                    color: Colors.grey.shade200,
                  )
                ],
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 80,
                  child: taskInfo.status == DownloadTaskStatus.complete.value
                      ? FutureBuilder<Uint8List>(
                          future: VideoThumbnail.thumbnailData(
                              video: taskInfo.link,
                              maxWidth: 80,
                              maxHeight: (kToolbarHeight * 2).toInt(),
                              quality: 60),
                          builder: (context, snapshot) => snapshot.hasData &&
                                  !snapshot.hasError
                              ? ClipRRect(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10)),
                                  child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image:
                                                  MemoryImage(snapshot.data)))))
                              : Center(child: Icon(Icons.play_arrow_outlined)),
                        )
                      : Center(
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  value: taskInfo.progress.toDouble() / 100,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.deepPurple),
                                  backgroundColor:
                                      Colors.deepPurple.withOpacity(0.2),
                                ),
                              ),
                              Align(
                                  alignment: Alignment.center,
                                  child:
                                      Text(taskInfo.progress.toString() + '%'))
                            ],
                          ),
                        ),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      taskInfo.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          .copyWith(fontSize: 16),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                            onPressed: () {
                              if (taskInfo.status ==
                                  DownloadTaskStatus.complete.value) {
                                FlutterDownloader.open(taskId: taskInfo.taskId);
                              } else if (taskInfo.status ==
                                  DownloadTaskStatus.running.value) {
                                FlutterDownloader.pause(
                                    taskId: taskInfo.taskId);
                              } else if (taskInfo.status ==
                                  DownloadTaskStatus.paused.value) {
                                FlutterDownloader.resume(
                                    taskId: taskInfo.taskId);
                              }
                            },
                            icon: Icon(taskInfo.status ==
                                        DownloadTaskStatus.complete.value ||
                                    taskInfo.status ==
                                        DownloadTaskStatus.paused.value
                                ? Icons.play_arrow
                                : Icons.pause)),
                        IconButton(
                          onPressed: () async {
                            if (taskInfo.status ==
                                DownloadTaskStatus.complete.value) {
                              await controller.downloadsBox.deleteAt(controller
                                  .downloadsBox.values
                                  .toList()
                                  .indexWhere((element) =>
                                      element.taskId == taskInfo.taskId));
                              await FlutterDownloader.remove(
                                  taskId: taskInfo.taskId);
                            } else {
                              FlutterDownloader.cancel(taskId: taskInfo.taskId)
                                  .whenComplete(() async {
                                await controller.downloadsBox.deleteAt(
                                    controller.downloadsBox.values
                                        .toList()
                                        .indexWhere((element) =>
                                            element.taskId == taskInfo.taskId));
                              });
                            }
                          },
                          icon: Icon(
                            taskInfo.status == DownloadTaskStatus.complete.value
                                ? Icons.delete_outline_outlined
                                : Icons.stop,
                          ),
                        ),
                        IconButton(
                            onPressed: () {}, icon: Icon(Icons.edit_outlined))
                      ],
                    ),
                  ],
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
