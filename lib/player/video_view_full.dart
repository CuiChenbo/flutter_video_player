import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'common_videoprogress_indicator.dart';

class VideoViewFull extends StatefulWidget {
  VideoViewFull({
    required this.url, // 当前需要播放的地址
    required this.title, // 当前title
    this.playerController,
  });

  // 视频地址
  final String url;
  final String title;
  VideoPlayerController? playerController;

  @override
  State<VideoViewFull> createState() {
    return _VideoViewFullState();
  }
}

class _VideoViewFullState extends State<VideoViewFull>
    with WidgetsBindingObserver {
  // 指示video资源是否加载完成，加载完成后会获得总时长和视频长宽比等信息
  bool _videoInit = false;

  // 记录video播放进度
  Duration _position = Duration(seconds: 0);
  bool _hidePlayControl = false; //是否隐藏控制播放组件
  bool _isVideoBuffering = false;

  var ivPlay = "assets/images/ic_video_play.png";
  var ivPause = "assets/images/ic_video_pause.png";

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this); //添加观察者
    _urlChange(); // 初始进行一次url加载
    super.initState();
  }

  void _urlChange() {
    if (widget.url == '') return;
    if (widget.playerController == null) {
      widget.playerController = VideoPlayerController.network(widget.url)
        ..initialize().then((_) {
          widget.playerController!.addListener(_videoListener);
          _playControlHide();
          setState(() {
            _videoInit = true;
          });
        });
      widget.playerController!.setLooping(false); //循环播放
    }
    _playControlHide();
    widget.playerController!.addListener(_videoListener);
    widget.playerController!.setLooping(false); //循环播放
    setState(() {
      _videoInit = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RotatedBox(
        quarterTurns: 1,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: widget.url.isNotEmpty
              ? Stack(
                  children: <Widget>[
                    videoWidget(),
                    titleBar(),
                    centerVideoBuffering(),
                    centerPlayControl(),
                    bottomIndicator(),
                  ],
                )
              : Center(
                  child: Text(
                    '暂无视频信息',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }

  Widget titleBar() {
    return SafeArea(
      child: Offstage(
        offstage: _hidePlayControl,
        child: Container(
          margin: EdgeInsets.only(left: 22, right: 22),
          height: 40,
          child: Row(
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 22,
                    color: Colors.white,
                  )),
              Container(
                width: 10,
              ),
              Text(
                widget.title,
                style: TextStyle(fontSize: 18, color: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget videoWidget() {
    return GestureDetector(
        // 手势组件
        onTap: () {
          _togglePlayControl();
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: widget.playerController!.value.aspectRatio,
            child: VideoPlayer(widget.playerController!),
          ),
        ));
  }

  //缓冲中Loading
  Widget centerVideoBuffering() {
    return Center(
        child: Offstage(
      offstage: _videoInit || !_isVideoBuffering,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CupertinoActivityIndicator(),
      ),
    ));
  }

  //手势控制区域
  Widget centerPlayControl() {
    return Center(
      child: _videoInit
          ? Offstage(
              offstage: _hidePlayControl,
              child: InkWell(
                onTap: () {
                  setState(() {
                    widget.playerController!.value.isPlaying
                        ? widget.playerController!.pause()
                        : widget.playerController!.play();
                  });
                  // _playControlHide();
                },
                child: Image.asset(
                  widget.playerController!.value.isPlaying
                      ? ivPause
                      : ivPlay, // 播放按钮
                  width: 46,
                  height: 46,
                ),
              ),
            )
          : Container(),
    );
  }

  //// 底部进度条和时间的容器
  Widget bottomIndicator() {
    return Positioned(
      bottom: 10,
      left: 0,
      child: Offstage(
        offstage: !_videoInit || _hidePlayControl,
        child: Container(
          color: Colors.black12,
          width: MediaQuery.of(context).size.height,
          height: 30,
          child: _videoInit
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      // 播放时间
                      margin: EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        durationToTime(_position.inSeconds),
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: CommonVideoProgressIndicator(
                        widget.playerController!,
                        allowScrubbing: true,
                        padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                        colors: VideoProgressColors(
                          playedColor: Color(0xffB5A36A), // 已播放的颜色
                          bufferedColor:
                              Color.fromRGBO(255, 255, 255, .3), // 缓存中的颜色
                          backgroundColor:
                              Color.fromRGBO(255, 255, 255, .1), // 为缓存的颜色
                        ),
                      ),
                    ),
                    Container(
                      // 播放时间
                      margin: EdgeInsets.only(left: 8, right: 8),
                      child: Text(
                        durationToTime(
                            widget.playerController!.value.duration.inSeconds),
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                          // 全屏按钮
                          margin: EdgeInsets.only(left: 8, right: 16),
                          child: Icon(
                            Icons.fullscreen_exit,
                            size: 18,
                            color: Colors.white,
                          )),
                    ),
                  ],
                )
              : Container(
                  width: 1,
                  height: 1,
                ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(VideoViewFull oldWidget) {
    if (oldWidget.url != widget.url) {
      _urlChange();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        widget.playerController!.pause();
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        widget.playerController!.dispose();
        break;
    }
  }

  @override
  void dispose() {
    print("CommonVideoFull-dispose销毁组件");
    WidgetsBinding.instance?.removeObserver(this); //添加观察者
    if (widget.playerController != null) {
      widget.playerController!.removeListener(_videoListener);
      // widget.playerController!.dispose();
    }
    super.dispose();
  }

  void _videoListener() {
    if (widget.playerController!.value.position.inSeconds ==
        widget.playerController!.value.duration.inSeconds) {
      //播放完成后 ， 自动暂停并回到开始位置
      _videoResume();
    }
    setState(() {
      _position = widget.playerController!.value.position;
      _isVideoBuffering = widget.playerController!.value.isBuffering;
    });
  }

  void _togglePlayControl() {
    setState(() {
      _hidePlayControl = !_hidePlayControl;
    });
    _playControlHide();
  }

  Timer? _timer; // 计时器，用于延迟隐藏控件ui
  void _playControlHide() {
    //播放按钮定时隐藏
    if (_hidePlayControl) return;
    if (_timer != null) _timer!.cancel(); // 有计时器先移除计时器
    _timer = Timer(Duration(seconds: 3), () {
      // 延迟3s后隐藏
      setState(() {
        _hidePlayControl = true;
      });
    });
  }

  //将时间转为hh:mm:ss
  String durationToTime(int seconds) {
    int hour = seconds ~/ 3600;
    int minute = seconds % 3600 ~/ 60;
    int second = seconds % 60;
    return /*formatTime(hour) + ":" +*/ formatTime(minute) +
        ":" +
        formatTime(second);
  }

  //数字格式化，将 0~9 的时间转换为 00~09
  String formatTime(int timeNum) {
    return timeNum < 10 ? "0" + timeNum.toString() : timeNum.toString();
  }

  //seekToStart 重新开始
  void _videoResume() {
    if (_videoInit) {
      setState(() {
        widget.playerController!
            .seekTo(Duration(seconds: 0))
            .then((value) => widget.playerController!.pause());
      });
    }
  }
}
