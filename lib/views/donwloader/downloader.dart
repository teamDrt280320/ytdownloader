import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ytdownloader/controllers/videocontroller.dart';

class DownloaderPage extends StatelessWidget {
  const DownloaderPage({
    Key key,
    @required VideoController videoController,
  })  : _videoController = videoController,
        super(key: key);

  final VideoController _videoController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => _videoController.fetchingData.value
              ? Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _videoController.videoInfo.value == null
                  ? Expanded(
                      child: Container(
                        child: Center(
                          child: Text(
                            'Enter the url in above area and\npress done to get results',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(
                            () => Container(
                              height: 200,
                              width: double.infinity,
                              margin: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: CachedNetworkImageProvider(
                                      _videoController.videoInfo.value.video
                                          .thumbnails.highResUrl,
                                    )),
                              ),
                            ),
                          ),
                          Obx(
                            () => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 16.0,
                              ),
                              child: Text(
                                _videoController.videoInfo.value.video.title,
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                textScaleFactor: 1.4,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              shrinkWrap: true,
                              physics: BouncingScrollPhysics(),
                              children: [
                                Text(
                                  'Audio + Video :- ',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                  ),
                                ),
                                Obx(
                                  () => ListView.builder(
                                    padding: EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: _videoController.videoInfo.value
                                        .streamInfo.muxed.length,
                                    itemBuilder: (context, index) {
                                      var streamInfo = _videoController
                                          .videoInfo.value.streamInfo.muxed
                                          .elementAt(index);
                                      return Card(
                                        child: ListTile(
                                          title: Text(
                                            streamInfo.videoQualityLabel,
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.download_outlined),
                                            onPressed: () {
                                              _videoController.downloadVideo(
                                                streamInfo.url.toString(),
                                                _videoController.videoInfo.value
                                                        .video.title +
                                                    '_' +
                                                    streamInfo
                                                        .videoQualityLabel +
                                                    '_' +
                                                    streamInfo
                                                        .videoResolution.height
                                                        .toString() +
                                                    'x' +
                                                    streamInfo
                                                        .videoResolution.width
                                                        .toString() +
                                                    '.' +
                                                    streamInfo.container.name,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Text(
                                  'Audio Only :- ',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                  ),
                                ),
                                Obx(() {
                                  _videoController
                                      .videoInfo.value.streamInfo.audioOnly
                                      .toList()
                                      .sort((a, b) =>
                                          b.bitrate.kiloBitsPerSecond.compareTo(
                                              a.bitrate.kiloBitsPerSecond));
                                  var list = _videoController
                                      .videoInfo.value.streamInfo.audioOnly
                                      .toList();
                                  return ListView.builder(
                                    padding: EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: list.length,
                                    itemBuilder: (context, index) {
                                      var streamInfo = list[index];
                                      return Card(
                                        child: ListTile(
                                          onTap: () {},
                                          title: Text(
                                            '${streamInfo.bitrate.kiloBitsPerSecond.ceil()} Kb/s ${streamInfo.container.name}',
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.download_outlined),
                                            onPressed: () {
                                              _videoController.downloadVideo(
                                                streamInfo.url.toString(),
                                                _videoController.videoInfo.value
                                                        .video.title +
                                                    streamInfo.tag.toString() +
                                                    '.' +
                                                    'mp3',
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class CustAppBar extends PreferredSize {
  final Widget child;
  final double height;
  final VideoController _videoController = Get.find();

  CustAppBar({
    this.child,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        height: kToolbarHeight,
        child: CupertinoSearchTextField(
          focusNode: _videoController.focusNode,
          itemColor: Colors.deepPurple,
          itemSize: 24,
          controller: _videoController.url,
          prefixInsets: EdgeInsets.symmetric(
            horizontal: 8.0,
          ),
          suffixIcon: Icon(
            Icons.done,
            size: 24,
            color: Colors.deepPurple,
          ),
          onSuffixTap: () {
            if (_videoController.url.text.isURL) {
              _videoController.focusNode.unfocus();
              _videoController.fetchInfo(_videoController.url.text);
            }
          },
          suffixInsets: EdgeInsets.symmetric(horizontal: 16.0),
          suffixMode: OverlayVisibilityMode.always,
          placeholder: 'Enter or Paste the url here',
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
