import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../calls/screens/video_call_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../../couple_connection/screens/couple_onboarding_screen.dart';
import '../../couple_connection/screens/create_relationship_screen.dart';
import '../../memories/screens/add_memory_screen.dart';
import '../../plans/screens/plans_hub_screen.dart';
import '../../together/screens/together_hub_screen.dart';
import '../widgets/mood_selector_modal.dart';

class UsHomeScreen extends StatelessWidget {
  const UsHomeScreen({super.key});

  void _showMoodModal(BuildContext context, String currentMood) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoodSelectorModal(currentMood: currentMood),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CoupleBloc, CoupleState>(
      builder: (context, coupleState) {
        final relationship = (coupleState is CouplePaired) ? coupleState.relationship : null;
        final partner = relationship?.partnerProfile;
        final anniversary = relationship?.anniversaryDate ?? DateTime.now();
        final daysTogether = HavenDateUtils.calculateDaysTogether(anniversary);
        final anniversaryInfo = HavenDateUtils.calculateNextAnniversary(anniversary);

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = (authState is Authenticated) ? authState.user : null;

            return Scaffold(
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 80,
                    backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          relationship?.customNickname ?? 'Us',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
                        tooltip: 'Private Couple Chat',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChatScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // Dashboard Body
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. Partner Status & Mood Header Card
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Partner Avatar with Live Status
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: isDark
                                            ? AppColors.darkSurfaceElevated
                                            : AppColors.lightSurfaceElevated,
                                        backgroundImage: partner?.avatarUrl != null
                                            ? NetworkImage(partner!.avatarUrl!)
                                            : null,
                                        child: partner?.avatarUrl == null
                                            ? Text(
                                                (partner?.displayName.isNotEmpty == true
                                                    ? partner!.displayName[0]
                                                    : (user?.displayName.isNotEmpty == true ? user!.displayName[0] : 'U')),
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.champagneDark,
                                                ),
                                              )
                                            : null,
                                      ),
                                      if (partner != null)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: partner.isOnline == true
                                                  ? AppColors.success
                                                  : Colors.grey,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark
                                                    ? AppColors.darkCard
                                                    : AppColors.lightCard,
                                                width: 2.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          partner?.displayName ?? (user?.displayName ?? 'Your Haven Space'),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          partner != null
                                              ? (partner.isOnline ? 'Active now' : 'Last active recently')
                                              : 'Invite your partner to connect ✨',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: partner?.isOnline == true
                                                ? AppColors.success
                                                : (isDark
                                                    ? AppColors.textTertiaryDark
                                                    : AppColors.textTertiaryLight),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Partner Mood Badge or Invite Button
                                  if (partner != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkSurfaceElevated
                                            : AppColors.lightSurfaceElevated,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            partner.moodEmoji ?? '🥰',
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            partner.mood ?? 'Loved',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // User's own mood trigger
                              InkWell(
                                onTap: () => _showMoodModal(context, user?.mood ?? 'loved'),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Your mood:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${user?.moodEmoji ?? '🥰'} ${user?.mood ?? 'Loved'}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Change',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.champagne
                                              : AppColors.champagneDark,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 10,
                                        color: isDark
                                            ? AppColors.champagne
                                            : AppColors.champagneDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 18),

                        // 2. Days Together Milestone Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF261D1A),
                                      const Color(0xFF1B171E),
                                    ]
                                  : [
                                      const Color(0xFFFDF6EE),
                                      const Color(0xFFFCEFEB),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: AppColors.roseDust.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    relationship != null ? 'TOGETHER FOR' : 'COUPLE SANCTUARY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: isDark
                                          ? AppColors.champagne
                                          : AppColors.champagneDark,
                                    ),
                                  ),
                                  if (relationship != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.roseDust.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${anniversaryInfo.yearsCount} Year${anniversaryInfo.yearsCount == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.warmCopper,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (relationship != null) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$daysTogether',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Days',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.celebration_outlined,
                                        size: 16, color: AppColors.roseDust),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${anniversaryInfo.daysRemaining} days until next anniversary',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const Text(
                                  'Ready to Begin',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pair with your partner to start counting your days together and sync shared milestones.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.champagne,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const CreateRelationshipScreen()),
                                          );
                                        },
                                        icon: const Icon(Icons.share_rounded, size: 16, color: Colors.black),
                                        label: const Text('Invite Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppColors.champagneDark),
                                          foregroundColor: isDark ? AppColors.champagne : AppColors.champagneDark,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const CoupleOnboardingScreen()),
                                          );
                                        },
                                        icon: const Icon(Icons.vpn_key_rounded, size: 16),
                                        label: const Text('Join Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(delay: 150.ms),

                        const SizedBox(height: 24),

                        // 3. Quick Actions Header
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Quick Actions Grid (6 items)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                          children: [
                            _buildQuickActionItem(
                              context,
                              title: 'Chat',
                              icon: Icons.chat_bubble_outline_rounded,
                              iconColor: AppColors.champagne,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ChatScreen(targetUser: partner)),
                              ),
                            ),
                            _buildQuickActionItem(
                              context,
                              title: 'Call',
                              icon: Icons.videocam_outlined,
                              iconColor: AppColors.roseDust,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => VideoCallScreen(
                                    channelId: relationship?.id ?? 'haven_call',
                                    partnerName: partner?.displayName ?? 'Partner',
                                    isInitiator: true,
                                  ),
                                ),
                              ),
                            ),
                            _buildQuickActionItem(
                              context,
                              title: 'Add Memory',
                              icon: Icons.auto_awesome_outlined,
                              iconColor: const Color(0xFFF4A261),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
                              ),
                            ),
                            _buildQuickActionItem(
                              context,
                              title: 'Plan Date',
                              icon: Icons.calendar_today_rounded,
                              iconColor: const Color(0xFF52B788),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PlansHubScreen()),
                              ),
                            ),
                            _buildQuickActionItem(
                              context,
                              title: 'Together',
                              icon: Icons.stream_rounded,
                              iconColor: const Color(0xFF457B9D),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const TogetherHubScreen()),
                              ),
                            ),
                            _buildQuickActionItem(
                              context,
                              title: 'Love Note',
                              icon: Icons.mail_outline_rounded,
                              iconColor: AppColors.warmCopper,
                              onTap: () => _showLoveNoteModal(context, partner?.displayName ?? 'Maya'),
                            ),
                          ],
                        ).animate().fadeIn(delay: 250.ms),

                        const SizedBox(height: 24),

                        // 4. Upcoming Date Card (Interactive)
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PlansHubScreen()),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppColors.champagne.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    color: AppColors.champagneDark,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Next Date: Candlelight Dinner',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Saturday, 7:30 PM • Sunset Rooftop',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 14, color: AppColors.textTertiaryDark),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 350.ms),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLoveNoteModal(BuildContext context, String partnerName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded, color: AppColors.champagne, size: 22),
                      const SizedBox(width: 8),
                      Text('Send Love Note to $partnerName', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Preset romantic inspirations
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Thinking of you 🥰',
                    'You make me smile ✨',
                    'Counting down till tonight ❤️',
                    'Best part of my life 💍',
                  ].map((phrase) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(phrase, style: const TextStyle(fontSize: 11.5)),
                      backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                      onPressed: () {
                        setModalState(() {
                          noteController.text = phrase;
                        });
                      },
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write something romantic, sweet, or intimate for $partnerName...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.champagne,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final text = noteController.text.trim();
                    if (text.isNotEmpty) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Love note delivered to $partnerName! 💌🕊️'),
                          backgroundColor: AppColors.champagneDark,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 16, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Send Love Note 💌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
