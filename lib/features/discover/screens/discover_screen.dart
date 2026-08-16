import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/models/user_profile.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/screens/inbox_screen.dart';
import '../models/connection_request_model.dart';
import '../models/post_model.dart';
import '../repositories/discover_repository.dart';
import 'connection_requests_screen.dart';
import 'fullscreen_reels_viewer.dart';
import 'story_viewer_screen.dart';
import 'user_portfolio_screen.dart';
import '../widgets/post_comments_sheet.dart';
import '../widgets/post_options_sheet.dart';
import '../widgets/share_post_sheet.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _discoverRepository = DiscoverRepository();
  List<PostModel> _posts = [];
  bool _isLoading = true;
  final Set<String> _likedPostIds = {};
  final Set<String> _bookmarkedPostIds = {};
  final Set<String> _connectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final posts = await _discoverRepository.getExploreFeed();
    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  void _toggleLike(String postId) {
    setState(() {
      if (_likedPostIds.contains(postId)) {
        _likedPostIds.remove(postId);
      } else {
        _likedPostIds.add(postId);
      }
    });
  }

  void _toggleBookmark(String postId) {
    setState(() {
      if (_bookmarkedPostIds.contains(postId)) {
        _bookmarkedPostIds.remove(postId);
      } else {
        _bookmarkedPostIds.add(postId);
      }
    });
  }

  void _sendConnect(String userId, String name) {
    _discoverRepository.sendSpark(userId);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Love Spark sent to $name! 💖 Waiting for acceptance...',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E2230),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2E344A), width: 1.2),
        ),
      ),
    );
  }

  UserProfile _getUserForPost(PostModel post) {
    return DiscoverRepository.demoUsers.firstWhere(
      (u) => u.id == post.userId,
      orElse: () => UserProfile(
        id: post.userId,
        email: 'user@haven.app',
        fullName: post.userFullName ?? 'Haven Creator',
        avatarUrl: post.userAvatarUrl,
        mood: 'creative',
        moodEmoji: '✨',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Haven Explore',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Fullscreen Reels Launcher
          IconButton(
            icon: const Icon(Icons.video_library_rounded, size: 24),
            tooltip: 'Watch Reels',
            onPressed: () {
              final reels = _posts.where((p) => p.mediaType == PostMediaType.reel).toList();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullscreenReelsViewer(reels: reels.isNotEmpty ? reels : _posts),
                ),
              );
            },
          ),
          // Activity / Connection Requests (Heart)
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border_rounded, size: 24),
                tooltip: 'Activity & Requests',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConnectionRequestsScreen()),
                  );
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.roseDust,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // Direct Messages (Inbox)
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 24),
            tooltip: 'Direct Messages',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InboxScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: HavenLoadingIndicator())
          : RefreshIndicator(
              onRefresh: _loadFeed,
              color: AppColors.champagne,
              child: CustomScrollView(
                slivers: [
                  // 1. Stories Horizontal Tray (Instagram-style)
                  SliverToBoxAdapter(
                    child: _buildStoriesTray(isDark),
                  ),

                  // 2. Vertical Scrollable Feed of Posts & Reels
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = _posts[index];
                        final user = _getUserForPost(post);
                        return _buildInstagramPostCard(post, user, isDark);
                      },
                      childCount: _posts.length,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Instagram Stories Bar
  Widget _buildStoriesTray(bool isDark) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: DiscoverRepository.demoUsers.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Your Story
            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Add to Your Story', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.camera_alt_outlined, color: AppColors.champagne),
                          title: const Text('Camera'),
                          subtitle: const Text('Capture a fresh photo or reel'),
                          onTap: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening Camera... 📷')),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library_outlined, color: AppColors.roseDust),
                          title: const Text('Choose from Gallery'),
                          subtitle: const Text('Select photos or video clips'),
                          onTap: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening Gallery... 🖼️')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                        child: const Icon(Icons.person_rounded, size: 32, color: Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.champagne,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.darkBackground : Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.add, size: 14, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Your Story', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final user = DiscoverRepository.demoUsers[index - 1];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StoryViewerScreen(user: user),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.champagne, AppColors.roseDust, AppColors.champagneDark],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null ? Text(user.fullName[0]) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.nickname ?? user.fullName.split(' ').first,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Instagram Feed Post Card
  Widget _buildInstagramPostCard(PostModel post, UserProfile user, bool isDark) {
    final isLiked = _likedPostIds.contains(post.id);
    final isBookmarked = _bookmarkedPostIds.contains(post.id);
    final isConnected = _connectedUserIds.contains(user.id);
    final isReel = post.mediaType == PostMediaType.reel;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header (Avatar, Name, Location, Connect Button, Options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => UserPortfolioScreen(user: user)),
                    );
                  },
                  child: Container(
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
                      child: user.avatarUrl == null ? Text(user.fullName[0]) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => UserPortfolioScreen(user: user)),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            if (user.moodEmoji != null) ...[
                              const SizedBox(width: 4),
                              Text(user.moodEmoji!, style: const TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                        if (post.locationName != null)
                          Text(
                            post.locationName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Love Spark Button
                Builder(
                  builder: (context) {
                    final sparkStatus = _discoverRepository.getSparkStatus(user.id);
                    final isConnected = sparkStatus == ConnectionRequestStatus.accepted;
                    final isPending = sparkStatus == ConnectionRequestStatus.pending;

                    return GestureDetector(
                      onTap: () {
                        if (isConnected) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => UserPortfolioScreen(user: user)),
                          );
                        } else if (isPending) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('⏳ Spark requested for ${user.fullName}. Waiting for acceptance!'),
                              backgroundColor: AppColors.darkSurfaceElevated,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          );
                        } else {
                          _sendConnect(user.id, user.fullName);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppColors.champagne.withOpacity(0.18)
                              : isPending
                                  ? (isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200)
                                  : AppColors.champagne,
                          borderRadius: BorderRadius.circular(16),
                          border: isConnected
                              ? Border.all(color: AppColors.champagneDark, width: 1)
                              : null,
                        ),
                        child: Text(
                          isConnected
                              ? 'Connected ✨'
                              : isPending
                                  ? 'Requested ⏳'
                                  : 'Spark 💕',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isConnected
                                ? (isDark ? AppColors.champagne : AppColors.champagneDark)
                                : isPending
                                    ? (isDark ? Colors.white70 : Colors.black87)
                                    : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, size: 20),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => PostOptionsSheet(
                        post: post,
                        isBookmarked: isBookmarked,
                        onBookmarkToggle: () => _toggleBookmark(post.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 2. High-Resolution Media / Reel Card
          GestureDetector(
            onDoubleTap: () => _toggleLike(post.id),
            onTap: () {
              if (isReel) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullscreenReelsViewer(reels: [post]),
                  ),
                );
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: isReel ? 4 / 5 : 1.0,
                  child: Image.network(
                    post.mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.broken_image, color: Colors.white24, size: 48),
                    ),
                  ),
                ),
                if (isReel)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                  ),
                if (isReel)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.video_collection_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Reel', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Instagram Action Bar (Heart, Comment, Share, Bookmark)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isLiked ? AppColors.roseDust : null,
                    size: 26,
                  ),
                  onPressed: () => _toggleLike(post.id),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 24),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => PostCommentsSheet(post: post, author: user),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, size: 24),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => SharePostSheet(post: post),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isBookmarked ? AppColors.champagne : null,
                    size: 26,
                  ),
                  onPressed: () => _toggleBookmark(post.id),
                ),
              ],
            ),
          ),

          // 4. Caption & Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.caption != null)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: '${user.fullName} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: post.caption!),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => PostCommentsSheet(post: post, author: user),
                    );
                  },
                  child: Text(
                    'View all comments',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2 HOURS AGO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
