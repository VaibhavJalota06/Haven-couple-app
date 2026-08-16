import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/models/user_profile.dart';
import '../../chat/screens/chat_screen.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_event.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../models/connection_request_model.dart';
import '../models/post_model.dart';
import '../repositories/discover_repository.dart';
import 'fullscreen_reels_viewer.dart';
import 'story_viewer_screen.dart';


class UserPortfolioScreen extends StatefulWidget {
  final UserProfile user;

  const UserPortfolioScreen({super.key, required this.user});

  @override
  State<UserPortfolioScreen> createState() => _UserPortfolioScreenState();
}

class _UserPortfolioScreenState extends State<UserPortfolioScreen> with SingleTickerProviderStateMixin {
  final _discoverRepository = DiscoverRepository();
  late TabController _tabController;
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  StreamSubscription? _sparkSubscription;

  final List<Map<String, String>> _highlights = [
    {'title': 'Travel ✈️', 'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=300&q=80'},
    {'title': 'Moments 📸', 'image': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=300&q=80'},
    {'title': 'Vibes 🌿', 'image': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=300&q=80'},
    {'title': 'Art 🎨', 'image': 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?w=300&q=80'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPortfolio();

    // Listen for spark updates and notifications
    _sparkSubscription = _discoverRepository.sparkUpdates.listen((event) {
      if (!mounted) return;
      setState(() {});

      if (event['type'] == 'spark_accepted' &&
          event['userId'] == widget.user.id &&
          event['triggerNotification'] == true) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.roseDust, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                      children: [
                        const TextSpan(text: '🎉 '),
                        TextSpan(
                          text: widget.user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.champagne),
                        ),
                        const TextSpan(text: ' accepted your Spark! Messaging is now unlocked.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E2230),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2E344A), width: 1.2),
            ),
            duration: const Duration(milliseconds: 3200),
            dismissDirection: DismissDirection.horizontal,
            action: SnackBarAction(
              label: 'Message 💬',
              textColor: AppColors.champagne,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(targetUser: widget.user),
                  ),
                );
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sparkSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolio() async {
    final posts = await _discoverRepository.getUserPortfolio(widget.user.id);
    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  void _sendSpark() async {
    await _discoverRepository.sendSpark(widget.user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Love Spark sent to ${widget.user.fullName}! 💖 Waiting for acceptance...'),
          backgroundColor: AppColors.champagneDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _showLockedMessagingDialog(bool isPending) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.champagne.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Icons.hourglass_top_rounded : Icons.lock_outline_rounded,
                color: AppColors.champagneDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isPending ? 'Spark Pending ⏳' : 'Spark Required 🔒',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          isPending
              ? 'You sent a Spark to ${widget.user.fullName}! You will receive a notification as soon as they accept your request, and messaging will unlock automatically.'
              : 'Direct messaging and friend interactions are locked until ${widget.user.fullName} accepts your Spark request. Send a Spark first to connect!',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          if (isPending)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _discoverRepository.acceptSpark(widget.user.id, triggerNotification: true);
              },
              child: const Text('⚡ Simulate Partner Accept', style: TextStyle(color: AppColors.champagneDark, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (!isPending)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.champagne,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _sendSpark();
              },
              child: const Text('Send Spark 💕', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _showPendingSparkDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: AppColors.roseDust, size: 24),
            SizedBox(width: 10),
            Text('Spark Requested ⏳', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Your Love Spark has been sent to ${widget.user.fullName}! Once accepted, you will receive an in-app alert and direct messaging will unlock.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _discoverRepository.acceptSpark(widget.user.id, triggerNotification: true);
            },
            child: const Text('⚡ Test: Simulate Partner Acceptance', style: TextStyle(color: AppColors.champagneDark, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSetAsPartnerDialog(BuildContext context, bool isAlreadyPartner) {
    if (isAlreadyPartner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ ${widget.user.fullName} is already your Official Partner on the Us dashboard!'),
          backgroundColor: AppColors.champagneDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Set as Official Partner',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Do you want to designate ${widget.user.fullName} as your Official Partner on the "Us" sanctuary?',
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              '• Your private memories, love countdown, shared drawing canvas, and watch room on the "Us" tab will be shared exclusively with ${widget.user.fullName}.\n• You can still explore and chat with other connections on Discover anytime.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Confirm Partner 💕',
                    onPressed: () {
                      context.read<CoupleBloc>().add(SetOfficialPartnerRequested(widget.user));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('💖 ${widget.user.fullName} is now your Official Partner on the "Us" dashboard!'),
                          backgroundColor: AppColors.champagneDark,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photos = _posts.where((p) => p.mediaType == PostMediaType.photo).toList();
    final reels = _posts.where((p) => p.mediaType == PostMediaType.reel).toList();

    return BlocBuilder<CoupleBloc, CoupleState>(
      builder: (context, coupleState) {
        final currentPartnerId = (coupleState is CouplePaired) ? coupleState.relationship.partnerProfile?.id : null;
        final isOfficialPartner = currentPartnerId == widget.user.id;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.user.nickname != null ? '@${widget.user.nickname?.toLowerCase()}' : widget.user.fullName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                  color: _notificationsEnabled ? AppColors.champagne : null,
                ),
                onPressed: () {
                  setState(() => _notificationsEnabled = !_notificationsEnabled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _notificationsEnabled
                            ? 'Turned ON post & reel alerts for ${widget.user.fullName} 🔔'
                            : 'Muted notifications for ${widget.user.fullName} 🔕',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'partner') {
                    _showSetAsPartnerDialog(context, isOfficialPartner);
                  } else if (val == 'share') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile link copied!')),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'partner',
                    child: Row(
                      children: [
                        Icon(
                          isOfficialPartner ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: AppColors.champagneDark,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(isOfficialPartner ? 'Official Partner on Us ⭐' : 'Set as Official Partner 💕'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Share Profile'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

      body: _isLoading
          ? const Center(child: HavenLoadingIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Profile Header Row: Avatar on Left, Bio Info on Right (NO Follower counters!)
                          Row(
                            children: [
                              // Avatar with Instagram Story Gradient Ring
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [AppColors.champagne, AppColors.roseDust, AppColors.champagneDark],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  backgroundImage: widget.user.avatarUrl != null
                                      ? NetworkImage(widget.user.avatarUrl!)
                                      : null,
                                  child: widget.user.avatarUrl == null
                                      ? Text(
                                          widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.champagne),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Showcase Summary
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.user.fullName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(widget.user.moodEmoji ?? '✨', style: const TextStyle(fontSize: 13)),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Vibe: ${widget.user.mood ?? 'Adventurous'}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // 2. Bio & Details
                          Text(
                            widget.user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Visual Creator & Storyteller 🌿\nCapturing genuine moments, quiet coffee spots, and open roads.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '🔗 haven.app/@creator',
                            style: TextStyle(color: AppColors.champagneDark, fontSize: 13, fontWeight: FontWeight.w600),
                          ),

                          if (isOfficialPartner) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.champagneDark, AppColors.champagne],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stars_rounded, color: Colors.black, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Your Official Partner on "Us" 💕',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // 3. Instagram Action Buttons: Spark, Message, Share
                          Builder(
                            builder: (context) {
                              final sparkStatus = _discoverRepository.getSparkStatus(widget.user.id);
                              final isConnected = sparkStatus == ConnectionRequestStatus.accepted;
                              final isPending = sparkStatus == ConnectionRequestStatus.pending;

                              return Row(
                                children: [
                                  // 3.1 Spark Action Button
                                  Expanded(
                                    child: SizedBox(
                                      height: 42,
                                      child: isConnected
                                          ? ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.champagne.withOpacity(0.18),
                                                foregroundColor: isDark ? AppColors.champagne : AppColors.champagneDark,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  side: BorderSide(
                                                    color: AppColors.champagneDark.withOpacity(0.6),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                              ),
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('✨ You and ${widget.user.fullName} are connected Sparks!'),
                                                    backgroundColor: AppColors.champagneDark,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  ),
                                                );
                                              },
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.champagne),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Connected ✨',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : isPending
                                              ? ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                                                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                      side: BorderSide(color: AppColors.champagne.withOpacity(0.4)),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  ),
                                                  onPressed: _showPendingSparkDialog,
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.hourglass_top_rounded, size: 15, color: AppColors.champagne),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Requested ⏳',
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.champagne,
                                                    foregroundColor: Colors.black,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  ),
                                                  onPressed: _sendSpark,
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.favorite_rounded, size: 16, color: Colors.black),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Spark 💕',
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 3.2 Message Button (LOCKED until connected!)
                                  Expanded(
                                    child: SizedBox(
                                      height: 42,
                                      child: isConnected
                                          ? ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                                                foregroundColor: isDark ? Colors.white : Colors.black87,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => ChatScreen(targetUser: widget.user),
                                                  ),
                                                );
                                              },
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.chat_bubble_rounded, size: 16, color: AppColors.champagne),
                                                  SizedBox(width: 6),
                                                  Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                ],
                                              ),
                                            )
                                          : ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isDark ? AppColors.darkSurface.withOpacity(0.5) : Colors.grey.shade100,
                                                foregroundColor: Colors.grey.shade500,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                              ),
                                              onPressed: () => _showLockedMessagingDialog(isPending),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.lock_outline_rounded, size: 15, color: Colors.grey.shade500),
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    'Message',
                                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 3.3 Share Button
                                  Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.share_outlined, size: 18),
                                      tooltip: 'Share profile',
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Profile link copied to clipboard!'),
                                            backgroundColor: AppColors.darkSurfaceElevated,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // 3.5 Dedicated Partner Section (Instagram vs 1 Special Partner)
                          if (!isOfficialPartner)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.champagne.withOpacity(0.2),
                                    AppColors.roseDust.withOpacity(0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.champagneDark.withOpacity(0.5),
                                  width: 1.2,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => _showSetAsPartnerDialog(context, isOfficialPartner),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: AppColors.primaryGradient,
                                          ),
                                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Set as My 1 Special Partner 💕',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: isDark ? AppColors.champagne : AppColors.champagneDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Connects "Us" dashboard & Together Mode exclusively to ${widget.user.fullName}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.champagneDark),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.champagne.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.champagneDark, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: AppColors.champagneDark, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '⭐ Your Official Special Partner on "Us"',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.champagneDark),
                                        ),
                                        Text(
                                          'All Together Mode tools & "Us" sanctuary are shared exclusively with ${widget.user.fullName}.',
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 18),


                          // 4. Story Highlights Tray
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _highlights.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final hl = _highlights[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => StoryViewerScreen(
                                          user: widget.user,
                                          storyMediaUrls: [hl['image']!],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundImage: NetworkImage(hl['image']!),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        hl['title']!,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Profile Tab Bar (Grid, Reels, Tagged)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PortfolioTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: isDark ? Colors.white : Colors.black,
                        dividerColor: Colors.transparent,
                        dividerHeight: 0,
                        indicatorWeight: 1.5,
                        labelColor: isDark ? Colors.white : Colors.black,
                        unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_on_rounded)),
                          Tab(icon: Icon(Icons.video_library_rounded)),
                          Tab(icon: Icon(Icons.person_pin_outlined)),
                        ],
                      ),
                      isDark,
                    ),
                  ),


                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Photos Grid
                  _buildPhotoGrid(photos),
                  // Tab 2: Reels Grid
                  _buildReelGrid(reels),
                  // Tab 3: Tagged Grid
                  _buildPhotoGrid(photos),
                ],
              ),
            ),
        );
      },
    );
  }


  Widget _buildPhotoGrid(List<PostModel> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No photos yet', style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final post = items[index];
        return GestureDetector(
          onTap: () => _openPostDetail(post),
          child: Image.network(
            post.mediaUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade900,
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReelGrid(List<PostModel> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No reels yet', style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final post = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FullscreenReelsViewer(reels: items, initialIndex: index),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
              ),
              Positioned(
                bottom: 6,
                left: 6,
                child: Row(
                  children: const [
                    Icon(Icons.play_arrow_outlined, color: Colors.white, size: 16),
                    SizedBox(width: 2),
                    Text('Watch', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPostDetail(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          title: Text(widget.user.fullName, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.network(post.mediaUrl, fit: BoxFit.contain),
              ),
            ),
            if (post.caption != null)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: Colors.black87,
                child: Text(post.caption!, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool _isDark;

  _PortfolioTabBarDelegate(this._tabBar, this._isDark);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _isDark ? AppColors.darkBackground : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PortfolioTabBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar || _isDark != oldDelegate._isDark;
  }
}



