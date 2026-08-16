import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../calls/screens/video_call_screen.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../models/message_model.dart';
import '../../auth/models/user_profile.dart';
import '../../discover/models/connection_request_model.dart';
import '../../discover/repositories/discover_repository.dart';
import '../../discover/screens/user_portfolio_screen.dart';
import 'shared_chat_vault_screen.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile? targetUser;

  const ChatScreen({super.key, this.targetUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  MessageModel? _replyingTo;

  @override
  void initState() {
    super.initState();
    final coupleState = context.read<CoupleBloc>().state;
    final relId = (coupleState is CouplePaired) ? coupleState.relationship.id : 'demo_couple_space';
    context.read<ChatBloc>().add(ChatStreamStarted(relId));
    context.read<ChatBloc>().add(ChatMessagesMarkedAsRead(relId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CoupleBloc, CoupleState>(
      builder: (context, coupleState) {
        final relationship = (coupleState is CouplePaired) ? coupleState.relationship : null;
        final partner = relationship?.partnerProfile;

        final displayName = widget.targetUser?.fullName ?? partner?.displayName ?? 'Maya Lin';
        final avatarUrl = widget.targetUser?.avatarUrl ?? partner?.avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80';
        final isOnline = widget.targetUser != null ? true : (partner?.isOnline == true);

        final targetProfile = widget.targetUser ?? (partner != null
            ? UserProfile(
                id: partner.id,
                email: partner.email ?? 'partner@haven.app',
                fullName: partner.fullName.isNotEmpty ? partner.fullName : displayName,
                nickname: partner.displayName,
                avatarUrl: partner.avatarUrl,
                mood: partner.mood ?? 'loved',
                moodEmoji: partner.moodEmoji ?? '🥰',
                createdAt: DateTime.now(),
              )
            : DiscoverRepository.demoUsers.first);

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return Scaffold(
              appBar: AppBar(
                leadingWidth: 40,
                titleSpacing: 0,
                title: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UserPortfolioScreen(user: targetProfile),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? Text(
                                  displayName.isNotEmpty ? displayName[0] : 'P',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.champagne),
                              ],
                            ),
                            Text(
                              isOnline ? 'Active now' : 'Encrypted Space',
                              style: TextStyle(
                                fontSize: 11,
                                color: isOnline
                                    ? AppColors.success
                                    : AppColors.textTertiaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.lock_outline_rounded, color: AppColors.champagne),
                    tooltip: 'Shared Secret Vault',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SharedChatVaultScreen(
                            partnerName: displayName,
                            conversationId: relationship?.id ?? 'conv_${displayName.toLowerCase().replaceAll(' ', '_')}',
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoCallScreen(
                            channelId: relationship?.id ?? 'demo_call_channel',
                            partnerName: displayName,
                            isInitiator: true,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoCallScreen(
                            channelId: relationship?.id ?? 'demo_call_channel',
                            partnerName: displayName,
                            isInitiator: true,
                            isAudioOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is ChatLoaded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  }
                },
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const HavenLoadingIndicator(message: 'Loading conversation...');
                  }

                  final messages = (state is ChatLoaded)
                      ? state.messages
                      : <MessageModel>[
                          // Seed demo messages if freshly launched
                          MessageModel(
                            id: 'welcome_msg',
                            relationshipId: relationship?.id ?? '',
                            senderId: partner?.id ?? 'partner_id',
                            content: 'Welcome to our private haven! ❤️ Everything here is completely private.',
                            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
                          ),
                        ];

                  final pinned = messages.where((m) => m.isPinned).toList();

                  return Column(
                    children: [
                      // Pinned Message Banner
                      if (pinned.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.push_pin_rounded,
                                  color: AppColors.champagne, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  pinned.last.content ?? 'Pinned attachment',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Messages List
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final partnerId = widget.targetUser?.id ?? partner?.id ?? 'user_maya';
                            final myId = (authState is Authenticated) ? authState.user.id : 'usr_me';
                            final isCurrentUser = msg.senderId == myId ||
                                msg.senderId == 'usr_me' ||
                                msg.senderId == 'demo_user' ||
                                (msg.senderId != partnerId &&
                                    msg.senderId != 'user_maya' &&
                                    msg.senderId != 'partner_id' &&
                                    msg.senderId != 'usr_elena' &&
                                    msg.senderId != 'usr_sophia' &&
                                    msg.senderId != 'usr_liam' &&
                                    msg.senderId != 'usr_marcus');

                            return MessageBubble(
                              message: msg,
                              isSenderCurrentUser: isCurrentUser,
                              onReply: () {
                                setState(() {
                                  _replyingTo = msg;
                                });
                              },
                              onReact: (emoji) {
                                context.read<ChatBloc>().add(
                                      ChatReactionToggled(
                                        messageId: msg.id,
                                        reaction: emoji,
                                      ),
                                    );
                              },
                              onPin: () {
                                context.read<ChatBloc>().add(
                                      ChatPinToggled(
                                        messageId: msg.id,
                                        currentPinStatus: msg.isPinned,
                                      ),
                                    );
                              },
                              onStar: () {
                                context.read<ChatBloc>().add(
                                      ChatStarToggled(
                                        messageId: msg.id,
                                        currentStarStatus: msg.isStarred,
                                      ),
                                    );
                              },
                              onUnsend: () {
                                context.read<ChatBloc>().add(ChatMessageUnsent(msg.id));
                              },
                              onDelete: () {
                                context.read<ChatBloc>().add(ChatMessageDeleted(msg.id));
                              },
                            );
                          },
                        ),
                      ),

                      // Input Bar or Spark Lock Banner
                      Builder(
                        builder: (context) {
                          final isTargetUser = widget.targetUser != null;
                          final sparkStatus = isTargetUser
                              ? DiscoverRepository().getSparkStatus(widget.targetUser!.id)
                              : ConnectionRequestStatus.accepted;
                          final isSparkLocked = isTargetUser && sparkStatus != ConnectionRequestStatus.accepted;

                          if (isSparkLocked) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              child: SafeArea(
                                top: false,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.champagne.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.lock_rounded, color: AppColors.champagne, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        sparkStatus == ConnectionRequestStatus.pending
                                            ? 'Spark Pending ⏳ • Messages unlock once ${widget.targetUser!.fullName} accepts!'
                                            : 'Spark Required 🔒 • Send a Spark on profile to start chatting.',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    if (sparkStatus == ConnectionRequestStatus.pending)
                                      TextButton(
                                        onPressed: () {
                                          DiscoverRepository().acceptSpark(widget.targetUser!.id, triggerNotification: true);
                                          setState(() {});
                                        },
                                        child: const Text('⚡ Accept', style: TextStyle(color: AppColors.champagneDark, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ChatInputBar(
                            replyingTo: _replyingTo,
                            onCancelReply: () => setState(() => _replyingTo = null),
                            onSendText: (text) {
                              final relId = relationship?.id ?? 'demo_couple_space';
                              context.read<ChatBloc>().add(
                                    ChatTextMessageSent(
                                      relationshipId: relId,
                                      content: text,
                                      replyToId: _replyingTo?.id,
                                    ),
                                  );
                              setState(() => _replyingTo = null);
                              Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                            },
                            onSendMedia: (file, mediaType, {caption}) {
                              final relId = relationship?.id ?? 'demo_couple_space';
                              context.read<ChatBloc>().add(
                                    ChatMediaMessageSent(
                                      relationshipId: relId,
                                      file: file,
                                      mediaType: mediaType,
                                      caption: caption,
                                    ),
                                  );
                              Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
