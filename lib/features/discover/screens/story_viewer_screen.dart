import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_profile.dart';

class StoryViewerScreen extends StatefulWidget {
  final UserProfile user;
  final List<String> storyMediaUrls;

  const StoryViewerScreen({
    super.key,
    required this.user,
    this.storyMediaUrls = const [
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&q=80',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&q=80',
    ],
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;
  bool _isPaused = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startStoryTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _replyController.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _progress += 0.01;
          if (_progress >= 1.0) {
            _nextStory();
          }
        });
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.storyMediaUrls.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startStoryTimer();
    } else {
      _timer?.cancel();
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startStoryTimer();
    } else {
      _startStoryTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMedia = widget.storyMediaUrls[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => setState(() => _isPaused = true),
        onLongPressEnd: (_) => setState(() => _isPaused = false),
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width * 0.35) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Story Media Background
            Image.network(
              currentMedia,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade900,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white24, size: 60),
                ),
              ),
            ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
              ),
            ),

            // 2. Progress Bars at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(
                  widget.storyMediaUrls.length,
                  (index) {
                    double value = 0.0;
                    if (index < _currentIndex) {
                      value = 1.0;
                    } else if (index == _currentIndex) {
                      value = _progress;
                    }
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 3. User Info Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 22,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.user.avatarUrl != null
                        ? NetworkImage(widget.user.avatarUrl!)
                        : null,
                    child: widget.user.avatarUrl == null
                        ? Text(widget.user.fullName[0], style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.user.fullName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  const Text('2h', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 4. Bottom Reply Bar
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 18,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white38),
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Send message...',
                                hintStyle: TextStyle(color: Colors.white60, fontSize: 14),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: AppColors.champagne, size: 20),
                            onPressed: () {
                              if (_replyController.text.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Story reply sent to ${widget.user.fullName}! 💬')),
                                );
                                _replyController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: AppColors.roseDust, size: 28),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Liked story! ❤️')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
