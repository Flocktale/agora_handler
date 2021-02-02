import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraHandler {
  String _appId = "7c3800483bbc473bbf341e1d68f04a40";

  RtcEngine _engine;

  Future<void> init({String appId}) async {
    if (appId != null) {
      _appId = appId;
    }

    _engine = await RtcEngine.create(_appId);
    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    _engine.setEventHandler(_eventHandler);
  }

  /// if userRole is not provided then by default it is assumed to be Audience.
  Future<void> joinClub(String channelName, String token,
      {bool isHost = false}) async {
    if (isHost) {
      final permission = await Permission.microphone.request();

      if (permission.isGranted != true) {
        throw ErrorDescription(
            "User denied pemission for microphone, can not allow user to be a broadcaster");
      }

      await _engine.enableLocalAudio(true);

      await _engine.setClientRole(ClientRole.Broadcaster);
      await _engine.joinChannel(token, channelName, null, 0);
    } else {
      await _engine.enableLocalAudio(false);

      await _engine.setClientRole(ClientRole.Audience);

      await _engine.switchChannel(token, channelName);
    }
  }

  Future<void> leaveClub() async => await _engine.leaveChannel();

  Future<void> muteSwitchClub(bool muted) async =>
      await _engine.muteAllRemoteAudioStreams(muted);

  Future<void> muteSwitchMic(bool muted) async =>
      await _engine.muteLocalAudioStream(muted);

  Future<void> dispose() async {
    await _engine?.destroy();
  }

  final _eventHandler = RtcEngineEventHandler(
    error: (code) {
      print('onError: $code');
    },
    joinChannelSuccess: (channel, uid, elapsed) {
      print('onJoinChannel: $channel, uid: $uid , time elapsed: $elapsed');
    },
    leaveChannel: (stats) {
      print('onLeaveChannel: $stats');
    },
    userJoined: (uid, elapsed) {
      print('onUserJoined, uid: $uid, time elapsed $elapsed');
    },
    userOffline: (uid, reason) {
      print('userOffline, uid: $uid, reason: $reason');
    },
    clientRoleChanged: (oldRole, newRole) {
      print('clientRoleChanged from $oldRole to $newRole');
    },
  );
}
