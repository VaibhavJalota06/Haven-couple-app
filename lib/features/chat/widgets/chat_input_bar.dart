import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../models/message_model.dart';

class ChatInputBar extends StatefulWidget {
  final void Function(String text) onSendText;
  final void Function(File file, MessageType mediaType, {String? caption}) onSendMedia;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelReply;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  bool _isRecording = false;
  int _recordSeconds = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      _textController.clear();
      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      widget.onSendMedia(File(picked.path), MessageType.image);
    }
  }

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: AppColors.champagne,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildAttachOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: AppColors.roseDust,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildAttachOption(
                    icon: Icons.schedule_send_rounded,
                    label: 'Schedule',
                    color: const Color(0xFF52B788),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showScheduleDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showScheduleDialog() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply banner preview
          if (widget.replyingTo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: AppColors.champagne, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.replyingTo?.content ?? 'Attachment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: widget.onCancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],

          Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                color: isDark ? AppColors.champagne : AppColors.champagneDark,
                onPressed: _showAttachmentSheet,
              ),

              // Input field or recording status
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: _isRecording
                      ? Row(
                          children: [
                            const Icon(Icons.fiber_manual_record, color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Text('Recording 0:0$_recordSeconds'),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setState(() => _isRecording = false),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        )
                      : TextField(
                          controller: _textController,
                          onChanged: (val) => setState(() {}),
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Message Haven...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            hintStyle: TextStyle(
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 8),

              // Send or Mic button
              if (hasText)
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                    onPressed: _handleSend,
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                    color: _isRecording ? AppColors.error : AppColors.champagne,
                    size: 26,
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _isRecording = !_isRecording;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
