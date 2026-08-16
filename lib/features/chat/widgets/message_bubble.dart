import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSenderCurrentUser;
  final VoidCallback? onReply;
  final void Function(String reaction)? onReact;
  final VoidCallback? onPin;
  final VoidCallback? onStar;
  final VoidCallback? onUnsend;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSenderCurrentUser,
    this.onReply,
    this.onReact,
    this.onPin,
    this.onStar,
    this.onUnsend,
    this.onDelete,
  });

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Emoji Reaction Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '🥰', '😂', '🔥', '✨', '🥺'].map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onReact?.call(emoji);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),

              // Action list
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: AppColors.champagne),
                title: const Text('Reply', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onReply?.call();
                },
              ),
              if (message.content != null && message.content!.isNotEmpty && !message.isDeleted)
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text('Copy Text', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.content!));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard 📋'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: Icon(
                  message.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: AppColors.champagne,
                ),
                title: Text(message.isPinned ? 'Unpin Message' : 'Pin to Chat', style: const TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onPin?.call();
                },
              ),
              ListTile(
                leading: Icon(
                  message.isStarred ? Icons.star_border_rounded : Icons.star_rounded,
                  color: const Color(0xFFF4A261),
                ),
                title: Text(message.isStarred ? 'Unstar' : 'Star Message', style: const TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onStar?.call();
                },
              ),
              if (isSenderCurrentUser) ...[
                ListTile(
                  leading: const Icon(Icons.undo_rounded, color: AppColors.error),
                  title: const Text('Unsend Message', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Remove this message for everyone', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showUnsendConfirmation(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showUnsendConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Unsend Message?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Unsending will permanently remove the message for everyone in this chat.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              HapticFeedback.heavyImpact();
              onUnsend?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message unsent ✨'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Unsend', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('h:mm a').format(message.createdAt);

    return Align(
      alignment: isSenderCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          child: Column(
            crossAxisAlignment:
                isSenderCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Main Bubble Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSenderCurrentUser
                      ? AppColors.primaryGradient
                      : null,
                  color: isSenderCurrentUser
                      ? null
                      : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isSenderCurrentUser ? 18 : 4),
                    bottomRight: Radius.circular(isSenderCurrentUser ? 4 : 18),
                  ),
                  border: isSenderCurrentUser
                      ? null
                      : Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reply preview if present
                    if (message.replyToMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isSenderCurrentUser ? Colors.white : AppColors.champagne,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          message.replyToMessage?.content ?? 'Attachment',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSenderCurrentUser ? Colors.white70 : AppColors.textSecondaryDark,
                          ),
                        ),
                      ),
                    ],

                    // Media rendering
                    if (message.mediaType == MessageType.image && message.mediaUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message.mediaUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 180,
                              color: Colors.black12,
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Voice Note Player
                    if (message.mediaType == MessageType.voice) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_filled_rounded,
                            size: 32,
                            color: isSenderCurrentUser ? Colors.white : AppColors.champagne,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: isSenderCurrentUser ? Colors.white24 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message.mediaDurationSeconds != null
                                ? '${message.mediaDurationSeconds}s'
                                : '0:05',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSenderCurrentUser ? Colors.white70 : AppColors.textTertiaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Text Content
                    if (message.content != null && message.content!.isNotEmpty) ...[
                      Text(
                        message.isDeleted ? 'This message was deleted' : message.content!,
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                          color: isSenderCurrentUser
                              ? (isDark ? AppColors.darkBackground : Colors.white)
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Time & Receipt Status (Single/Double Checkmarks)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (message.isPinned) ...[
                          Icon(
                            Icons.push_pin_rounded,
                            size: 11,
                            color: isSenderCurrentUser ? Colors.white70 : AppColors.champagne,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSenderCurrentUser
                                ? (isDark ? AppColors.darkBackground.withOpacity(0.7) : Colors.white70)
                                : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                          ),
                        ),
                        if (isSenderCurrentUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: isDark ? AppColors.darkBackground : Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Reactions Bar Pill
              if (message.reactions.isNotEmpty) ...[
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      message.reactions.map((r) => r.reaction).toSet().join(' '),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
