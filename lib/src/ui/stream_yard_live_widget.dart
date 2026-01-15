import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:streamyard_livestream/src/logic/stream_yard_web_interopt.dart';
import 'package:streamyard_livestream/src/models/stream_yard_live_state.dart';
import 'package:streamyard_livestream/src/models/stream_yard_user.dart';

class StreamYardLiveWidget extends StatefulWidget {
  final String streamId;
  final String streamTitle;
  final StreamYardUser user;
  final AppBar? actionBar;
  final Color? backgroundColor;
  final TextStyle? actionBarTextStyle;

  StreamYardLiveWidget({
    super.key,
    required this.streamId,
    required this.streamTitle,
    required this.user,
    this.actionBar,
    this.backgroundColor = Colors.white,
    this.actionBarTextStyle = const TextStyle(
      color: Colors.black,
      fontSize: 13,
    ),
  }) : assert(streamId.isNotEmpty, 'streamId 不能为空'),
       assert(streamTitle.isNotEmpty, 'streamTitle 不能为空');

  @override
  State<StreamYardLiveWidget> createState() => _StreamYardLiveWidgetState();
}

class _StreamYardLiveWidgetState extends State<StreamYardLiveWidget> {
  late InAppWebViewController webViewController;
  late PullToRefreshController pullToRefreshController;

  final streamYardController = StreamYardWebInteropt.instance;

  StreamYardLiveState liveState = StreamYardLiveState.idle;

  bool isLoading = true;
  double progress = 0;

  String status = 'Initializing...';
  String errorMessage = '';

  final List<String> jsLogs = [];

  void updateLiveState(StreamYardLiveState state, [String message = '']) {
    setState(() {
      liveState = state;
      if (message.isNotEmpty) {
        status = message;
      }
      switch (state) {
        case StreamYardLiveState.idle:
          status = '空闲';
          break;
        case StreamYardLiveState.active:
          status = '活跃 - 已加入聊天';
          break;
        case StreamYardLiveState.paused:
          status = '已暂停';
          break;
        case StreamYardLiveState.stopped:
          status = '已停止';
          break;
        case StreamYardLiveState.error:
          status = '错误：$errorMessage';
          break;
        case StreamYardLiveState.unknown:
          status = '未知状态';
          break;
      }
    });
  }

  Future<void> reloadPage() async {
    updateLiveState(StreamYardLiveState.idle, '正在重新加载...');
    await webViewController.reload();

    pullToRefreshController.endRefreshing();
  }

  Future<void> goBack() async {
    if (await webViewController.canGoBack()) {
      await webViewController.goBack();
    }
  }

  Future<void> goForward() async {
    if (await webViewController.canGoForward()) {
      await webViewController.goForward();
    }
  }

  Color getStateColor(StreamYardLiveState state) {
    switch (state) {
      case StreamYardLiveState.idle:
        return Colors.grey;
      case StreamYardLiveState.active:
        return Colors.green;
      case StreamYardLiveState.paused:
        return Colors.orange;
      case StreamYardLiveState.stopped:
        return Colors.red;
      case StreamYardLiveState.error:
        return Colors.red;
      case StreamYardLiveState.unknown:
        return Colors.purple;
    }
  }

  IconData getStateIcon(StreamYardLiveState state) {
    switch (state) {
      case StreamYardLiveState.idle:
        return Icons.pause;
      case StreamYardLiveState.active:
        return Icons.play_arrow;
      case StreamYardLiveState.paused:
        return Icons.pause;
      case StreamYardLiveState.stopped:
        return Icons.stop;
      case StreamYardLiveState.error:
        return Icons.error;
      case StreamYardLiveState.unknown:
        return Icons.help;
    }
  }

  Future<void> injectAutoJoinScript() async {
    try {
      await webViewController.evaluateJavascript(
        source: streamYardController.autoJoinStream(user: widget.user),
      );

      updateLiveState(StreamYardLiveState.active, '自动加入脚本已注入');
    } catch (e) {
      updateLiveState(StreamYardLiveState.error, '脚本注入失败: $e');
    }
  }

  Future<void> manualJoinChat() async {
    updateLiveState(StreamYardLiveState.active, 'Manually joining chat...');

    final script = '''
      if (window.streamYardAutoJoin) {
        window.streamYardAutoJoin();
      } else {
        window.flutter_inappwebview.callHandler('logMessage', 'Auto-join function not available');
      }
    ''';

    try {
      await webViewController.evaluateJavascript(source: script);
    } catch (e) {
      updateLiveState(StreamYardLiveState.error, 'Manual join failed: $e');
    }
  }

  Future<void> updateChatName() async {
    final script =
        '''
      if (window.streamYardConfig) {
        window.streamYardConfig.firstName = '${widget.user.firstName}';
        window.streamYardConfig.lastName = '${widget.user.lastName}';
        window.flutter_inappwebview.callHandler('logMessage', 'Name updated to ${widget.user.firstName} ${widget.user.lastName}');
      }
    ''';

    try {
      await webViewController.evaluateJavascript(source: script);
      addLog('Name updated: ${widget.user.firstName} ${widget.user.lastName}');
    } catch (e) {
      addLog('Failed to update name: $e');
    }
  }

  void addLog(String message) {
    setState(() {
      jsLogs.insert(0, '${DateTime.now()} $message');
      if (jsLogs.length > 50) {
        jsLogs.removeLast();
      }
    });
  }

  void clearLogs() => setState(() => jsLogs.clear());

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      onRefresh: reloadPage,
    );

    updateLiveState(StreamYardLiveState.idle, '准备加载');
  }

  @override
  void dispose() {
    pullToRefreshController.endRefreshing();
    pullToRefreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = streamYardController.streamUrl(widget.streamId);

    final appbar = (widget.actionBar == null)
        ? AppBar(
            title: Text(widget.streamTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: reloadPage,
              ),
            ],
          )
        : widget.actionBar;

    return Scaffold(
      appBar: appbar,
      backgroundColor: widget.backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: getStateColor(liveState),
              minHeight: 2,
            ),

            // WebView
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(url)),
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) {
                  webViewController = controller;

                  controller.addJavaScriptHandler(
                    handlerName: 'logMessage',
                    callback: (args) {
                      final message = args.first as String;
                      addLog(message);
                    },
                  );

                  controller.addJavaScriptHandler(
                    handlerName: 'updateState',
                    callback: (args) {
                      final data = args.first as Map;
                      final state = data['state'] as String;
                      final message = data['message'] as String;

                      StreamYardLiveState newState;
                      switch (state) {
                        case 'active':
                          newState = StreamYardLiveState.active;
                          break;
                        case 'idle':
                          newState = StreamYardLiveState.idle;
                          break;
                        case 'error':
                          newState = StreamYardLiveState.error;
                          setState(() => errorMessage = message);
                          break;
                        default:
                          newState = StreamYardLiveState.unknown;
                      }

                      updateLiveState(newState, message);
                    },
                  );
                },
                onLoadStart: (controller, url) {
                  isLoading = true;
                  updateLiveState(StreamYardLiveState.idle, 'Loading...');
                },
                onLoadStop: (controller, url) async {
                  setState(() => isLoading = false);

                  pullToRefreshController.endRefreshing();

                  await injectAutoJoinScript();
                },
                onProgressChanged: (controller, p) {
                  setState(() => progress = p / 100.0);
                },
                onLoadError: (controller, url, code, message) {
                  setState(() {
                    errorMessage = '$code: $message';
                    updateLiveState(StreamYardLiveState.error, 'Load error');
                  });
                },
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  allowContentAccess: true,
                  allowsAirPlayForMediaPlayback: true,
                  cacheEnabled: true,
                  databaseEnabled: true,
                  allowBackgroundAudioPlaying: true,
                  displayZoomControls: false,
                  hardwareAcceleration: true,
                  allowsPictureInPictureMediaPlayback: true,
                  iframeAllowFullscreen: true,
                  useHybridComposition: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  supportZoom: false,
                  transparentBackground: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
