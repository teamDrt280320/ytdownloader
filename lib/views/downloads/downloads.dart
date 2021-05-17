import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:ytdownloader/controllers/videocontroller.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DownloadsPage extends StatefulWidget {
  @override
  _DownloadsPageState createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final VideoController controller = Get.find();
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: ValueListenableBuilder<Box<TaskInfo>>(
            valueListenable: controller.downloadsBox.listenable(),
            builder: (context, snapshot, _) {
              return snapshot.isEmpty
                  ? Text(
                      'No Downloads\nGo back and download something',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : ListView.builder(
                      physics: BouncingScrollPhysics(),
                      itemCount: snapshot.length,
                      itemBuilder: (context, index) {
                        var downloadTask = snapshot.getAt(index);
                        return downloadTask.status ==
                                    DownloadTaskStatus.failed.value ||
                                downloadTask.status ==
                                    DownloadTaskStatus.undefined.value ||
                                downloadTask.status ==
                                    DownloadTaskStatus.canceled.value
                            ? SizedBox.shrink()
                            : Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal: 4.0,
                                ),
                                child: Card(
                                  child: ListTile(
                                    onTap: () {
                                      if (downloadTask.status ==
                                          DownloadTaskStatus.complete.value) {
                                        FlutterDownloader.open(
                                            taskId: downloadTask.taskId);
                                      } else {
                                        Get.snackbar(
                                          'Let the Download Finish',
                                          'Let the download finish first',
                                        );
                                      }
                                    },
                                    isThreeLine: downloadTask.progress < 100,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 16.0,
                                    ),
                                    title: Text(
                                      downloadTask.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Visibility(
                                      visible: downloadTask.progress < 100,
                                      maintainSize: false,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16.0,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: (downloadTask.progress / 100)
                                              .toDouble(),
                                        ),
                                      ),
                                    ),
                                    leading:
                                        Text(downloadTask.progress.toString()),
                                    trailing: IconButton(
                                      icon: Icon(
                                        downloadTask.status ==
                                                DownloadTaskStatus.running.value
                                            ? Icons.pause
                                            : downloadTask.status ==
                                                    DownloadTaskStatus
                                                        .paused.value
                                                ? Icons.play_arrow_outlined
                                                : downloadTask.status ==
                                                        DownloadTaskStatus
                                                            .complete.value
                                                    ? Icons.delete
                                                    : downloadTask.status ==
                                                            DownloadTaskStatus
                                                                .failed.value
                                                        ? Icons.refresh
                                                        : downloadTask.status ==
                                                                DownloadTaskStatus
                                                                    .enqueued
                                                                    .value
                                                            ? Icons.queue
                                                            : Icons.error,
                                      ),
                                      onPressed: () async {
                                        if (downloadTask.status ==
                                            DownloadTaskStatus.running.value) {
                                          FlutterDownloader.pause(
                                              taskId: downloadTask.taskId);
                                        } else if (downloadTask.status ==
                                            DownloadTaskStatus.paused.value) {
                                          var newTaskId =
                                              await FlutterDownloader.resume(
                                            taskId: downloadTask.taskId,
                                          );
                                          if (newTaskId != null) {
                                            downloadTask.taskId = newTaskId;
                                            controller.downloadsBox
                                                .putAt(index, downloadTask);
                                          } else {
                                            var newTaskId =
                                                await FlutterDownloader.retry(
                                              taskId: downloadTask.taskId,
                                            );
                                            if (newTaskId != null) {
                                              downloadTask.taskId = newTaskId;
                                              controller.downloadsBox
                                                  .putAt(index, downloadTask);
                                            } else {
                                              await FlutterDownloader.remove(
                                                taskId: downloadTask.taskId,
                                                shouldDeleteContent: true,
                                              );
                                              controller.downloadsBox
                                                  .deleteAt(index);
                                            }
                                          }
                                        } else if (downloadTask.status ==
                                            DownloadTaskStatus.failed.value) {
                                          var newTaskId =
                                              await FlutterDownloader.retry(
                                            taskId: downloadTask.taskId,
                                          );
                                          downloadTask.taskId = newTaskId;
                                          controller.downloadsBox
                                              .putAt(index, downloadTask);
                                        } else if (downloadTask.status ==
                                            DownloadTaskStatus.complete.value) {
                                          Get.dialog(AlertDialog(
                                            title: Text('Are you Sure?'),
                                            content: Text(
                                              'Are your sure you want to delete this file?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () async {
                                                  Get.back();
                                                },
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  Get.back();
                                                  await FlutterDownloader
                                                      .remove(
                                                    taskId: downloadTask.taskId,
                                                    shouldDeleteContent: true,
                                                  );
                                                  controller.downloadsBox
                                                      .deleteAt(index);
                                                },
                                                child: Text('Yes'),
                                              ),
                                            ],
                                          ));
                                        }
                                        // print(downloadTask.savedDir);
                                        // FlutterDownloader.open(
                                        //     taskId: downloadTask.taskId);
                                      },
                                    ),
                                  ),
                                ),
                              );
                      },
                    );
            }),
      ),
    );
  }
}
