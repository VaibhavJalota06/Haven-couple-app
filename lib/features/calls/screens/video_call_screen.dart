import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../together/screens/together_hub_screen.dart';
import '../services/webrtc_call_manager.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelId;
  final String partnerName;
  final bool isInitiator;
  final bool isAudioOnly;

  const VideoCallScreen({
    super.key,
    required this.channelId,
    required this.partnerName,
    required this.isInitiator,
    this.isAudioOnly = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  WebRTCCallManager? _callManager;

  bool _isMuted = false;
  bool _isVideoOff = false;
  int _callDurationSeconds = 0;
  Timer? _durationTimer;
  RTCPeerConnectionState _connectionState = RTCPeerConnectionState.RTCPeerConnectionStateNew;

  @override
  void initState() {
    super.initState();
    _initRenderersAndCall();
  }

  Future<void> _initRenderersAndCall() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _callManager = WebRTCCallManager(
      onLocalStream: (stream) {
        _localRenderer.srcObject = stream;
        setState(() {});
      },
      onRemoteStream: (stream) {
        _remoteRenderer.srcObject = stream;
        setState(() {});
      },
      onConnectionState: (state) {
        setState(() {
          _connectionState = state;
        });
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _startTimer();
        }
      },
    );

    await _callManager?.startCall(
      channelId: widget.channelId,
      isInitiator: widget.isInitiator,
      isAudioOnly: widget.isAudioOnly,
    );
  }

  void _startTimer() {
    _durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _callManager?.toggleMute(_isMuted);
    });
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
      _callManager?.toggleVideo(_isVideoOff);
    });
  }

  void _switchCamera() {
    _callManager?.switchCamera();
  }

  void _endCall() async {
    _durationTimer?.cancel();
    await _callManager?.dispose();
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callManager?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video View (Full screen) or Placeholder
            if (!widget.isAudioOnly && _remoteRenderer.srcObject != null)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF11141D),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: AppColors.champagne.withOpacity(0.2),
                        child: Text(
                          widget.partnerName.isNotEmpty ? widget.partnerName[0] : 'P',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: AppColors.champagne,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.partnerName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isConnected ? HavenDateUtils.formatDuration(_callDurationSeconds) : 'Connecting...',
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

            // Local Video Overlay (Top right preview)
            if (!widget.isAudioOnly && !_isVideoOff && _localRenderer.srcObject != null)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 110,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // Top Header: Partner name + Duration / Status
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected
                          ? HavenDateUtils.formatDuration(_callDurationSeconds)
                          : 'Calling...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom In-Call Controls
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2230).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Audio
                    _buildCallActionBtn(
                      icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      isActive: _isMuted,
                      onTap: _toggleMute,
                    ),

                    // Toggle Video
                    if (!widget.isAudioOnly)
                      _buildCallActionBtn(
                        icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                        isActive: _isVideoOff,
                        onTap: _toggleVideo,
                      ),

                    // Switch Camera
                    if (!widget.isAudioOnly)
                      _buildCallActionBtn(
                        icon: Icons.flip_camera_ios_rounded,
                        isActive: false,
                        onTap: _switchCamera,
                      ),

                    // Together Mode launcher
                    _buildCallActionBtn(
                      icon: Icons.stream_rounded,
                      isActive: false,
                      iconColor: AppColors.champagne,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TogetherHubScreen()),
                        );
                      },
                    ),

                    // Hangup
                    _buildCallActionBtn(
                      icon: Icons.call_end_rounded,
                      isActive: true,
                      bgColor: AppColors.error,
                      iconColor: Colors.white,
                      onTap: _endCall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionBtn({
    required IconData icon,
    required bool isActive,
    Color? bgColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor ?? (isActive ? Colors.white24 : Colors.white12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? (isActive ? AppColors.roseDust : Colors.white),
          size: 22,
        ),
      ),
    );
  }
}
