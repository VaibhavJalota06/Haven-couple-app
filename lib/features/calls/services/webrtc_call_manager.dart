import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';

typedef StreamCallback = void Function(MediaStream stream);
typedef ConnectionStateCallback = void Function(RTCPeerConnectionState state);

class WebRTCCallManager {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RealtimeChannel? _signalingChannel;

  final StreamCallback onLocalStream;
  final StreamCallback onRemoteStream;
  final ConnectionStateCallback onConnectionState;

  WebRTCCallManager({
    required this.onLocalStream,
    required this.onRemoteStream,
    required this.onConnectionState,
  });

  // ICE Server configuration with Google STUN
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Initialize local media devices (Camera + Microphone)
  Future<void> initializeMedia({bool isAudioOnly = false}) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isAudioOnly
          ? false
          : {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            },
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    if (_localStream != null) {
      onLocalStream(_localStream!);
    }
  }

  /// Start WebRTC peer connection and subscribe to Supabase Realtime signaling
  Future<void> startCall({
    required String channelId,
    required bool isInitiator,
    bool isAudioOnly = false,
  }) async {
    await initializeMedia(isAudioOnly: isAudioOnly);

    _peerConnection = await createPeerConnection(_iceServers);

    // Add local tracks to peer connection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // Handle remote track
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        onRemoteStream(_remoteStream!);
      }
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      onConnectionState(state);
    };

    // Supabase Realtime Signaling Channel
    _signalingChannel = SupabaseService.getBroadcastChannel('${AppConstants.callSignalBroadcastChannel}_$channelId');

    // Handle ICE Candidates
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _signalingChannel?.sendBroadcastMessage(
        event: 'ice-candidate',
        payload: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    // Subscribe to signaling events
    _signalingChannel?.onBroadcast(
      event: 'offer',
      callback: (payload) async {
        if (!isInitiator) {
          final sdp = payload['sdp'] as String;
          await _peerConnection?.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
          final answer = await _peerConnection?.createAnswer();
          if (answer != null) {
            await _peerConnection?.setLocalDescription(answer);
            _signalingChannel?.sendBroadcastMessage(
              event: 'answer',
              payload: {'sdp': answer.sdp},
            );
          }
        }
      },
    );

    _signalingChannel?.onBroadcast(
      event: 'answer',
      callback: (payload) async {
        if (isInitiator) {
          final sdp = payload['sdp'] as String;
          await _peerConnection?.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
        }
      },
    );

    _signalingChannel?.onBroadcast(
      event: 'ice-candidate',
      callback: (payload) async {
        final candidate = RTCIceCandidate(
          payload['candidate'] as String?,
          payload['sdpMid'] as String?,
          payload['sdpMLineIndex'] as int?,
        );
        await _peerConnection?.addCandidate(candidate);
      },
    );

    _signalingChannel?.subscribe();

    // If caller, generate and broadcast offer
    if (isInitiator) {
      final offer = await _peerConnection?.createOffer();
      if (offer != null) {
        await _peerConnection?.setLocalDescription(offer);
        _signalingChannel?.sendBroadcastMessage(
          event: 'offer',
          payload: {'sdp': offer.sdp},
        );
      }
    }
  }

  /// Toggle audio mute
  void toggleMute(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  /// Toggle camera video stream
  void toggleVideo(bool isVideoOff) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !isVideoOff;
    });
  }

  /// Switch front/back camera
  Future<void> switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }

  /// Clean up and dispose all media tracks and connections
  Future<void> dispose() async {
    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      await _peerConnection?.close();
      await _peerConnection?.dispose();
      await _signalingChannel?.unsubscribe();
    } catch (_) {}
  }
}
