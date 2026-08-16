import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../discover/repositories/discover_repository.dart';
import '../../discover/screens/user_portfolio_screen.dart';

class WatchRoomScreen extends StatefulWidget {
  final String relationshipId;
  final String partnerName;

  const WatchRoomScreen({
    super.key,
    this.relationshipId = 'demo_couple_space',
    this.partnerName = 'Maya',
  });

  @override
  State<WatchRoomScreen> createState() => _WatchRoomScreenState();
}

class _WatchRoomScreenState extends State<WatchRoomScreen> {
  bool _isPlaying = true;
  double _playbackPosition = 0.35; // 0.0 to 1.0
  Timer? _timer;
  final TextEditingController _whisperController = TextEditingController();

  late List<String> _whispers;

  final List<Map<String, dynamic>> _playlist = [
    {
      'title': 'Sunset in Amalfi Coast',
      'category': '4K Cinematic',
      'duration': '12:45',
      'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
    },
    {
      'title': 'Parisian Rain & Cozy Jazz',
      'category': 'Ambience & Music',
      'duration': '28:10',
      'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',
    },
    {
      'title': 'Northern Lights Romance',
      'category': 'Nature Odyssey',
      'duration': '15:20',
      'image': 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=800&q=80',
    },
  ];

  int _selectedVideoIndex = 0;
  final List<Widget> _floatingReactions = [];

  @override
  void initState() {
    super.initState();
    _whispers = [
      '${widget.partnerName}: This cinematography is stunning! 🌅✨',
      'You: The music in this scene is so romantic ❤️',
    ];
    _startPlaybackTimer();
  }

  void _startPlaybackTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isPlaying && mounted) {
        setState(() {
          _playbackPosition = (_playbackPosition + 0.005) % 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _whisperController.dispose();
    super.dispose();
  }

  void _emitReaction(String emoji) {
    setState(() {
      _floatingReactions.add(
        Positioned(
          bottom: 120 + (50 * (_floatingReactions.length % 3)).toDouble(),
          right: 20 + (30 * (_floatingReactions.length % 4)).toDouble(),
          child: Text(emoji, style: const TextStyle(fontSize: 36))
              .animate()
              .moveY(begin: 0, end: -180, duration: 1200.ms, curve: Curves.easeOut)
              .fadeOut(duration: 1200.ms),
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _floatingReactions.isNotEmpty) {
        setState(() => _floatingReactions.removeAt(0));
      }
    });
  }

  void _sendWhisper() {
    final text = _whisperController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _whispers.add('You: $text');
        _whisperController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentVideo = _playlist[_selectedVideoIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            final partnerProfile = DiscoverRepository.demoUsers.firstWhere(
              (u) => u.fullName.toLowerCase().contains(widget.partnerName.toLowerCase()) || u.id == 'user_maya',
              orElse: () => DiscoverRepository.demoUsers.first,
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserPortfolioScreen(user: partnerProfile),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Watch Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🟢 Synced with ${widget.partnerName}',
                      style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.champagne),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // 1. Video Player Container
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video Background Banner
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          currentVideo['image'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Dark Overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.35),
                        ),
                      ),
                      // Play/Pause Center Button
                      GestureDetector(
                        onTap: () => setState(() => _isPlaying = !_isPlaying),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                            border: Border.all(color: AppColors.champagne, width: 1.5),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 38,
                            color: AppColors.champagne,
                          ),
                        ),
                      ),
                      // Bottom Progress Scrubber
                      Positioned(
                        bottom: 8,
                        left: 14,
                        right: 14,
                        child: Row(
                          children: [
                            Text(
                              '${(_playbackPosition * 12).toInt()}:${((_playbackPosition * 60) % 60).toInt().toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  trackHeight: 3,
                                  activeTrackColor: AppColors.champagne,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: AppColors.champagne,
                                ),
                                child: Slider(
                                  value: _playbackPosition,
                                  onChanged: (val) => setState(() => _playbackPosition = val),
                                ),
                              ),
                            ),
                            Text(
                              currentVideo['duration'],
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Realtime Reaction Emitters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['❤️', '🥰', '🔥', '🍿', '✨', '🥂'].map((emoji) {
                      return GestureDetector(
                        onTap: () => _emitReaction(emoji),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2230),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Live Whispers Tray
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, color: AppColors.champagne, size: 16),
                                  SizedBox(width: 6),
                                  Text('Live Whispers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              Text('Private • ${widget.partnerName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _whispers.length,
                              itemBuilder: (ctx, i) {
                                final isMe = _whispers[i].startsWith('You:');
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Text(
                                    _whispers[i],
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                                      color: isMe ? AppColors.champagne : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Whisper Input Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2230),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TextField(
                            controller: _whisperController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Whisper to ${widget.partnerName}...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _sendWhisper(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.champagne,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        onPressed: _sendWhisper,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ..._floatingReactions,
        ],
      ),
    );
  }
}
