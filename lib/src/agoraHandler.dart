import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraHandler {
  String _appId = "7c3800483bbc473bbf341e1d68f04a40";

  RtcEngine _engine;

  /// by default, it's set to "Audience".
  ClientRole _userRole;

  Future<void> init({String appId}) async {
    if (appId != null) {
      this._appId = appId;
    }

    this._engine = await RtcEngine.create(_appId);
    await this._engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    this._engine.setEventHandler(_eventHandler);

    this._userRole = ClientRole.Audience;
  }

  /// if userRole is not provided then by default it is assumed to be Audience.
  Future<void> joinClub(String channelName, String token,
      {ClientRole userRole}) async {
    if (userRole == null) {
      this._userRole = ClientRole.Audience;
    } else {
      this._userRole = userRole;
    }
    if (this._userRole == ClientRole.Broadcaster) {
      final permission = await Permission.microphone.request();

      if (permission.isGranted != true) {
        throw ErrorDescription(
            "User denied pemission for microphone, can not allow user to be a broadcaster");
      }

      await this._engine.enableLocalAudio(true);
    } else {
      await this._engine.enableLocalAudio(false);
    }

    await this._engine.setClientRole(this._userRole);

    if (this._userRole == ClientRole.Audience) {
      await this._engine.switchChannel(token, channelName);
    } else {
      await this._engine.joinChannel(token, channelName, null, 0);
    }
  }

  Future<void> leaveClub() async => await this._engine.leaveChannel();

  Future<void> muteSwitchClub(bool muted) async =>
      await this._engine.muteAllRemoteAudioStreams(muted);

  Future<void> muteSwitchMic(bool muted) async =>
      await this._engine.muteLocalAudioStream(muted);

  void dispose() async {
    await this._engine?.destroy();
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
