import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../models/post_model.dart';
import '../repositories/discover_repository.dart';

class SharePostSheet extends StatefulWidget {
  final PostModel post;

  const SharePostSheet({super.key, required this.post});

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  final Set<String> _sentUserIds = {};

  void _sendToUser(String userId, String name) {
    setState(() {
      _sentUserIds.add(userId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post sent to $name! ✈️'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipients = [
      ...DiscoverRepository.demoUsers,
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const Text(
            'Share Post',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Search recipient bar
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              children: [
                Icon(Icons.search, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text('Search connections...', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Contacts grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: recipients.length,
              itemBuilder: (context, index) {
                final user = recipients[index];
                final isSent = _sentUserIds.contains(user.id);

                return GestureDetector(
                  onTap: () => _sendToUser(user.id, user.fullName),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                            child: user.avatarUrl == null ? Text(user.fullName[0]) : null,
                          ),
                          if (isSent)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.nickname ?? user.fullName.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSent ? 'Sent' : 'Send',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSent ? Colors.green : AppColors.champagneDark,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Quick Link & External Share Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: 'https://haven.app/p/${widget.post.id}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied https://haven.app/p/${widget.post.id} to clipboard! 📋'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.link_rounded, size: 20, color: AppColors.champagne),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tap to Copy Link',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                'haven.app/p/${widget.post.id}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Copy Button
                IconButton(
                  tooltip: 'Copy Link',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'https://haven.app/p/${widget.post.id}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied https://haven.app/p/${widget.post.id} to clipboard! 📋 Ready to paste in any app.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                // Share to external app button
                IconButton(
                  tooltip: 'Share to Other Apps',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.champagne,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'https://haven.app/p/${widget.post.id}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied! Open WhatsApp, Browser, or any app to paste & share 🚀'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
