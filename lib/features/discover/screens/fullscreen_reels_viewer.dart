import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../models/post_model.dart';
import '../repositories/discover_repository.dart';
import '../widgets/post_comments_sheet.dart';
import '../widgets/post_options_sheet.dart';
import '../widgets/share_post_sheet.dart';
import 'user_portfolio_screen.dart';

class FullscreenReelsViewer extends StatefulWidget {
  final List<PostModel> reels;
  final int initialIndex;

  const FullscreenReelsViewer({
    super.key,
    required this.reels,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenReelsViewer> createState() => _FullscreenReelsViewerState();
}

class _FullscreenReelsViewerState extends State<FullscreenReelsViewer> {
  late PageController _pageController;
  final Set<String> _likedReels = {};
  final Set<String> _connectedUsers = {};
  final DiscoverRepository _discoverRepo = DiscoverRepository();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleLike(String reelId) {
    setState(() {
      if (_likedReels.contains(reelId)) {
        _likedReels.remove(reelId);
      } else {
        _likedReels.add(reelId);
      }
    });
  }

  void _sendConnect(String userId, String name) {
    setState(() {
      _connectedUsers.add(userId);
    });
    _discoverRepo.sendConnectionRequest(receiverId: userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Love Spark sent to $name! 💖'),
        backgroundColor: AppColors.champagneDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCreateReelModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Create New Reel 🎬', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.champagne.withOpacity(0.4), style: BorderStyle.solid),
              ),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video selected from gallery! 🎥')),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.video_call_rounded, size: 36, color: AppColors.champagne),
                    SizedBox(height: 8),
                    Text('Record or Upload Video', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('Up to 60s • HD Vertical Video', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: captionCtrl,
              decoration: InputDecoration(
                hintText: 'Write a caption, tags, and partner mention...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.champagne,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Share Reel to Haven', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reel uploaded and live on Haven Discover! 🎬✨')),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.reels.length,
        itemBuilder: (context, index) {
          final reel = widget.reels[index];
          final isLiked = _likedReels.contains(reel.id);
          final isConnected = _connectedUsers.contains(reel.userId);

          // Find user profile
          final user = DiscoverRepository.demoUsers.firstWhere(
            (u) => u.id == reel.userId,
            orElse: () => UserProfile(
              id: reel.userId,
              email: 'user@haven.app',
              fullName: reel.userFullName ?? 'Creator',
              avatarUrl: reel.userAvatarUrl,
              createdAt: DateTime.now(),
            ),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Media (Photo/Video Frame)
              GestureDetector(
                onDoubleTap: () => _toggleLike(reel.id),
                child: Image.network(
                  reel.mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade900,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white30, size: 48)),
                  ),
                ),
              ),

              // Gradient Overlay for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Bar (Reels header, back button & camera)
              Positioned(
                top: MediaQuery.of(context).padding.top + 6,
                left: 6,
                right: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Reels',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24),
                      onPressed: _showCreateReelModal,
                    ),
                  ],
                ),
              ),

              // Bottom Left: Creator Info, Caption & Audio track
              Positioned(
                left: 16,
                bottom: MediaQuery.of(context).padding.bottom + 20,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User info row
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => UserPortfolioScreen(user: user)),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.champagne, AppColors.roseDust],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                              child: user.avatarUrl == null
                                  ? Text(user.fullName[0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (reel.locationName != null)
                                  Text(
                                    reel.locationName!,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Love Spark Button
                          GestureDetector(
                            onTap: () => _sendConnect(user.id, user.fullName),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isConnected ? Colors.white24 : AppColors.champagne,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white38),
                              ),
                              child: Text(
                                isConnected ? 'Spark Sent' : 'Spark 💕',
                                style: TextStyle(
                                  color: isConnected ? Colors.white : Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Caption
                    if (reel.caption != null)
                      Text(
                        reel.caption!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 10),

                    // Audio Track Info with rotating music icon
                    Row(
                      children: [
                        const Icon(Icons.music_note_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Original Audio • Haven Soundscape',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                            image: user.avatarUrl != null
                                ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                                : null,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).rotate(duration: 4.seconds),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Action Bar (Heart, Comments, Share, Connect, Audio)
              Positioned(
                right: 14,
                bottom: MediaQuery.of(context).padding.bottom + 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Like Button
                    _buildActionButton(
                      icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isLiked ? AppColors.roseDust : Colors.white,
                      label: isLiked ? 'Liked' : 'Like',
                      onTap: () => _toggleLike(reel.id),
                    ),
                    const SizedBox(height: 18),

                    // Comment Button
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                      label: 'Comments',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => PostCommentsSheet(post: reel, author: user),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // Share Button
                    _buildActionButton(
                      icon: Icons.send_rounded,
                      color: Colors.white,
                      label: 'Share',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => SharePostSheet(post: reel),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // More Options
                    _buildActionButton(
                      icon: Icons.more_vert_rounded,
                      color: Colors.white,
                      label: '',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => PostOptionsSheet(
                            post: reel,
                            isBookmarked: false,
                            onBookmarkToggle: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved reel to Vault! 🔒')),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
