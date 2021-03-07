import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraHandler {
  String _appId = "f58d5e866a87498988cd3c138759bb2a";

  RtcEngine _engine;

  Future<RtcEngineEventHandler> init() async {
    _engine = await RtcEngine.create(_appId);
    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);

    // interval in ms, smoothness (sensitivity) on a scale of 10, true for local audio detection
    await _engine.enableAudioVolumeIndication(500, 3, true);

    _engine.setEventHandler(_eventHandler);

    return _eventHandler;
  }

  /// if userRole is not provided then by default it is assumed to be Audience.
  Future<void> joinClub(String channelName, String token,
      {bool isHost = false}) async {
    // leaving any club if already played.
    await leaveClub();

    if (isHost) {
      final permission = await Permission.microphone.request();

      if (permission.isGranted != true) {
        throw ErrorDescription(
            "User denied pemission for microphone, can not allow user to be a broadcaster");
      }

      await _engine.enableLocalAudio(true);
      await _engine.setClientRole(ClientRole.Broadcaster);
    } else {
      await _engine.enableLocalAudio(false);
      await _engine.setClientRole(ClientRole.Audience);
    }

    await _engine.joinChannel(token, channelName, null, 0);
  }

  Future<void> leaveClub() async {
    try {
      await _engine.leaveChannel();
    } catch (e) {
      print('error in leaving club $e');
    }
  }

  Future<void> muteSwitchClub(bool muted) async =>
      await _engine.muteAllRemoteAudioStreams(muted);

  Future<void> muteSwitchMic(bool muted) async =>
      await _engine.muteLocalAudioStream(muted);

  Future<void> dispose() async {
    await _engine?.destroy();
  }

  final _eventHandler = RtcEngineEventHandler(
    warning: (warn) {
      print('on warning: $warn');
    },
    error: (code) {
      print('onError: $code');
    },
    apiCallExecuted: (error, api, result) {
      print('on apiCallExecuted: error: $error, api: $api, result:$result');
    },
    joinChannelSuccess: (channel, uid, elapsed) {
      print('onJoinChannel: $channel, uid: $uid , time elapsed: $elapsed');
    },
    rejoinChannelSuccess: (channel, uid, elapsed) {
      print('on Re-JoinChannel: $channel, uid: $uid , time elapsed: $elapsed');
    },
    leaveChannel: (stats) {
      print('onLeaveChannel: $stats');
    },
    userJoined: (uid, elapsed) {
      print('onUserJoined, uid: $uid, time elapsed $elapsed');
    },
    clientRoleChanged: (oldRole, newRole) {
      print('clientRoleChanged from $oldRole to $newRole');
    },
    userOffline: (uid, reason) {
      print('userOffline, uid: $uid, reason: $reason');
    },
    connectionStateChanged: (state, reason) {
      print('on connectionStateChanged: state: $state, reason: $reason');
    },
    networkTypeChanged: (type) {
      print('on networkTypeChanged: $type');
    },
    connectionLost: () {
      print('connection lost with agora');
    },
    tokenPrivilegeWillExpire: (token) {
      print(
          'privelege token is about to expire in 30 seconds, please renew it. Old token : $token');
    },
    requestToken: () {
      print(
          'privelege token has expired, please generate a new token and  join the channel again');
    },

    /// use this callback to get list of speaking users.
    audioVolumeIndication: (speakers, totalVolume) {
      print(
          'on AudioVolumeIndication: speakers $speakers, totalVolume: $totalVolume');
    },

    /// use this callback to get uid of loudest speaker.
    activeSpeaker: (uid) {
      print('uid of loudest speaker: $uid');
    },

    /// use this callback to listen to change in audio of remote user.
    remoteAudioStateChanged: (uid, state, reason, elapsed) {
      print(
          'on remoteAudioStateChanged: uid: $uid, state: $state, reason: $reason, elapsed: $elapsed');
    },

    /// use this callback to listen to change audio of current user.
    localAudioStateChanged: (state, error) {
      print('on localAudioStateChanged: state: $state, error: $error');
    },

    /// This callback returns that the audio route switched to an earpiece, speakerphone, headset, or Bluetooth device
    audioRouteChanged: (routing) {
      print('audio route changed for current user: $routing');
    },

    /// use this callback to get rtc stats in every two seconds.
    rtcStats: (stats) {
      print('status of rtc engine: $stats');
    },

    /// use this callback to monitor activity of current user connected with a channel.
    localAudioStats: (stats) {
      print('local audio stats: $stats');
    },
  );
}
