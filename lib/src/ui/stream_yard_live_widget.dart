import 'package:flutter/material.dart';
import 'package:streamyard_livestream/src/logic/stream_yard_web_interopt.dart';
import 'package:streamyard_livestream/src/models/stream_yard_user.dart';

class StreamYardLiveWidget extends StatelessWidget {
  final String streamId;
  final String streamTitle;
  final StreamYardUser user;
  final Color? backgroundColor;
  final TextStyle? actionBarTextStyle;

  StreamYardLiveWidget({
    super.key,
    required this.streamId,
    required this.streamTitle,
    required this.user,
    this.backgroundColor = Colors.white,
    this.actionBarTextStyle = const TextStyle(
      color: Colors.black,
      fontSize: 13,
    ),
  }) : assert(streamId.isNotEmpty, 'streamId 不能为空'),
       assert(streamTitle.isNotEmpty, 'streamTitle 不能为空');

  @override
  Widget build(BuildContext context) {
    final streamYardController = StreamYardWebInteropt.instance;

    final url = streamYardController.streamUrl(streamId);

    final appBar = AppBar(title: Text(streamTitle));

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,

      body: SafeArea(child: SizedBox()),
    );
  }
}
