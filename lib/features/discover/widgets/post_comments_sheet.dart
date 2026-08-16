import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../models/post_model.dart';

class PostCommentsSheet extends StatefulWidget {
  final PostModel post;
  final UserProfile author;

  const PostCommentsSheet({
    super.key,
    required this.post,
    required this.author,
  });

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [
    {
      'name': 'Elena Rostova',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
      'text': 'The color grading here is out of this world! ✨',
      'time': '1h',
      'likes': 14,
      'isLiked': false,
    },
    {
      'name': 'Liam Walker',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
      'text': 'Which lens did you shoot this with? Looks super crisp 📸',
      'time': '45m',
      'likes': 6,
      'isLiked': true,
    },
    {
      'name': 'Sophia Laurent',
      'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&q=80',
      'text': 'Pure vibes!! Love the quiet aesthetic 🌿',
      'time': '12m',
      'likes': 3,
      'isLiked': false,
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _comments.add({
        'name': 'Vaibhav Jalota',
        'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80',
        'text': text.trim(),
        'time': 'Just now',
        'likes': 0,
        'isLiked': false,
      });
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const SizedBox(height: 6),

          // Comments List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = _comments[index];
                final isLiked = item['isLiked'] as bool;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(item['avatar'] as String),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: '${item['name']} ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: item['text'] as String),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                item['time'] as String,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(width: 16),
                              if ((item['likes'] as int) > 0)
                                Text(
                                  '${item['likes']} likes',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                              const SizedBox(width: 16),
                              const Text(
                                'Reply',
                                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: isLiked ? AppColors.roseDust : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          item['isLiked'] = !isLiked;
                          item['likes'] = (item['likes'] as int) + (isLiked ? -1 : 1);
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // Quick Emoji bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['❤️', '🔥', '👏', '😍', '✨', '🙌', '💯'].map((emoji) {
                return GestureDetector(
                  onTap: () => _addComment(emoji),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                );
              }).toList(),
            ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: _addComment,
                  ),
                ),
                TextButton(
                  onPressed: () => _addComment(_commentController.text),
                  child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.champagneDark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
