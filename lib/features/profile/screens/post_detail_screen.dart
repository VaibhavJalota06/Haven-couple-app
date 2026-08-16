import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_profile.dart';

class PostItemData {
  final String id;
  final String imageUrl;
  final String location;
  final String caption;
  int likesCount;
  bool isLiked;
  bool isSaved;
  final DateTime createdAt;
  final List<Map<String, String>> comments;

  PostItemData({
    required this.id,
    required this.imageUrl,
    required this.location,
    required this.caption,
    required this.likesCount,
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
    required this.comments,
  });
}

class PostDetailScreen extends StatefulWidget {
  final UserProfile user;
  final List<PostItemData> posts;
  final int initialIndex;

  const PostDetailScreen({
    super.key,
    required this.user,
    required this.posts,
    this.initialIndex = 0,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final ScrollController _scrollController;
  final Set<String> _animatingHearts = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.initialIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final screenWidth = MediaQuery.of(context).size.width;
          final estimatedPostHeight = screenWidth + 140;
          _scrollController.jumpTo((widget.initialIndex * estimatedPostHeight).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ));
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerDoubleTapHeart(PostItemData post) {
    setState(() {
      if (!post.isLiked) {
        post.isLiked = true;
        post.likesCount++;
      }
      _animatingHearts.add(post.id);
    });

    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) {
        setState(() => _animatingHearts.remove(post.id));
      }
    });
  }

  void _openCommentsSheet(PostItemData post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetCommentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                const Divider(height: 1),

                // Comments List
                Expanded(
                  child: post.comments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              const Text('No comments yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              const Text('Start the conversation.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: post.comments.length,
                          itemBuilder: (context, idx) {
                            final c = post.comments[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundImage: NetworkImage(c['avatar']!),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '${c['name']} ',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(text: c['text']),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(c['time'] ?? 'Just now', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            const SizedBox(width: 16),
                                            GestureDetector(
                                              onTap: () {
                                                sheetCommentCtrl.text = '@${c['name']} ';
                                                sheetCommentCtrl.selection = TextSelection.fromPosition(
                                                  TextPosition(offset: sheetCommentCtrl.text.length),
                                                );
                                              },
                                              child: const Text('Reply', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      c['isLiked'] == 'true' ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 16,
                                      color: c['isLiked'] == 'true' ? Colors.redAccent : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setSheetState(() {
                                        c['isLiked'] = c['isLiked'] == 'true' ? 'false' : 'true';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const Divider(height: 1),

                // Bottom Input Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade50,
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            widget.user.avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: sheetCommentCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () {
                            final text = sheetCommentCtrl.text.trim();
                            if (text.isNotEmpty) {
                              setSheetState(() {
                                post.comments.add({
                                  'name': widget.user.fullName.isNotEmpty ? widget.user.fullName : 'Vaibhav',
                                  'avatar': widget.user.avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
                                  'text': text,
                                  'time': 'Just now',
                                });
                              });
                              setState(() {});
                              sheetCommentCtrl.clear();
                            }
                          },
                          child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.champagne)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sharePost(PostItemData post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ListTile(
              leading: const CircleAvatar(
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&q=80'),
              ),
              title: const Text('Send to Maya Lin ❤️', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Direct to Couple Sanctuary Chat'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sent post directly to Maya in Sanctuary Chat! 💌')),
                  );
                },
                child: const Text('Send'),
              ),
            ),
            const Divider(height: 16),
            ListTile(
              leading: const Icon(Icons.link_rounded, color: AppColors.champagne),
              title: const Text('Copy Private Link'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Private E2EE Link copied to clipboard 📋')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(PostItemData post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, size: 22),
              title: const Text('Copy Link', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard! 🔗'), duration: Duration(seconds: 2)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_rounded, size: 22),
              title: const Text('QR Code', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => Dialog(
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Post QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () => Navigator.of(dCtx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12)),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.grey.shade900),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: AppColors.champagne, shape: BoxShape.circle),
                                        child: const Icon(Icons.favorite_rounded, size: 20, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(widget.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                Text('haven.app/p/${post.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                  icon: const Icon(Icons.download_rounded, size: 18),
                                  label: const Text('Save Image'),
                                  onPressed: () {
                                    Navigator.of(dCtx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR Code image saved to gallery 📸')));
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                  icon: const Icon(Icons.share_rounded, size: 18),
                                  label: const Text('Share'),
                                  onPressed: () {
                                    Navigator.of(dCtx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing QR Code link... 💌')));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 12),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined, color: Colors.orange, size: 22),
              title: const Text('Not Interested', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Post hidden. We will tune your feed to show fewer posts like this.'),
                    action: SnackBarAction(label: 'Undo', textColor: AppColors.champagne, onPressed: () {}),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: Colors.red, size: 22),
              title: const Text('Report Post', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you. We have received your report 🛡️')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatPostDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'TODAY';
    if (diff.inDays == 1) return '1 DAY AGO';
    if (diff.inDays < 7) return '${diff.inDays} DAYS AGO';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} WEEKS AGO';
    return '${(diff.inDays / 30).floor()} MONTHS AGO';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView.separated(
        controller: _scrollController,
        itemCount: widget.posts.length,
        separatorBuilder: (_, __) => Divider(
          height: 32,
          thickness: 1,
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final post = widget.posts[index];
          final isHeartAnimating = _animatingHearts.contains(post.id);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundImage: NetworkImage(
                        widget.user.avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.nickname?.isNotEmpty == true ? widget.user.nickname! : 'vaibhav',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          if (post.location.isNotEmpty)
                            Text(
                              post.location,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, size: 20),
                      onPressed: () => _showPostOptions(post),
                    ),
                  ],
                ),
              ),

              // Square Aspect Ratio Image (Instagram Standard) with Double-Tap Heart
              GestureDetector(
                onDoubleTap: () => _triggerDoubleTapHeart(post),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.network(
                        post.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isHeartAnimating)
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 90,
                      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeOut(delay: 450.ms, duration: 250.ms),
                  ],
                ),
              ),

              // Action Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: post.isLiked ? Colors.redAccent : (isDark ? Colors.white : Colors.black),
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          post.isLiked = !post.isLiked;
                          post.likesCount += post.isLiked ? 1 : -1;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
                      onPressed: () => _openCommentsSheet(post),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, size: 21),
                      onPressed: () => _sharePost(post),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: post.isSaved ? AppColors.champagne : (isDark ? Colors.white : Colors.black),
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() => post.isSaved = !post.isSaved);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(post.isSaved ? 'Saved to Collection ✨' : 'Removed from Saved')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Likes Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '${post.likesCount} likes',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),

              const SizedBox(height: 4),

              // Caption
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: '${widget.user.nickname?.isNotEmpty == true ? widget.user.nickname! : 'vaibhav'} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // View Comments Link (Clean Instagram style)
              if (post.comments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: GestureDetector(
                    onTap: () => _openCommentsSheet(post),
                    child: Text(
                      'View all ${post.comments.length} comments',
                      style: const TextStyle(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: GestureDetector(
                    onTap: () => _openCommentsSheet(post),
                    child: const Text(
                      'Add a comment...',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  ),
                ),

              // Date
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Text(
                  _formatPostDate(post.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.4),
                ),
              ),

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
