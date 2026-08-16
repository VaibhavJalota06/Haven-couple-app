import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../../couple_connection/screens/couple_onboarding_screen.dart';
import 'shared_drawing_canvas_screen.dart';
import 'truth_or_dare_game.dart';
import 'watch_room_screen.dart';
import 'would_you_rather_game.dart';

class TogetherHubScreen extends StatelessWidget {
  const TogetherHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CoupleBloc, CoupleState>(
      builder: (context, coupleState) {
        final isPaired = coupleState is CouplePaired;
        final relationship = isPaired ? coupleState.relationship : null;
        final partner = relationship?.partnerProfile;
        final partnerName = partner?.displayName ?? 'Partner';
        final relationshipId = relationship?.id ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Together Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: isPaired
                ? _buildPairedTogetherContent(
                    context,
                    isDark: isDark,
                    partnerName: partnerName,
                    relationshipId: relationshipId,
                  )
                : _buildUnpairedLockScreen(context, isDark: isDark),
          ),
        );
      },
    );
  }

  // 1. Guard Screen for Unpaired Users
  Widget _buildUnpairedLockScreen(BuildContext context, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.champagne.withOpacity(0.15),
              border: Border.all(color: AppColors.champagne, width: 2),
            ),
            child: const Icon(Icons.lock_person_rounded, color: AppColors.champagneDark, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Paired Couples Only 💕',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Together Mode is a private sanctuary for you and your partner to watch videos, draw together, and play intimate games.\n\nNo other user can ever access or enter your shared room.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Pair with Your Partner 💌',
            icon: Icons.favorite_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CoupleOnboardingScreen()),
              );
            },
            variant: ButtonVariant.primary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // 2. Full Together Content for Paired Couples
  Widget _buildPairedTogetherContent(
    BuildContext context, {
    required bool isDark,
    required String partnerName,
    required String relationshipId,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppColors.champagne.withOpacity(0.2),
                AppColors.roseDust.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.champagne.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.champagne, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SHARED WITH $partnerName'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: isDark ? AppColors.champagne : AppColors.champagneDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Play, Watch & Connect with $partnerName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Private, end-to-end synchronized sanctuary exclusively for the two of you.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 28),

        Text(
          'Couple Games',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 14),

        // Game Cards
        _buildActivityCard(
          context,
          title: 'Would You Rather?',
          description: 'Discover surprising preferences and laugh over hilarious choices.',
          icon: Icons.alt_route_rounded,
          accentColor: AppColors.champagne,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WouldYouRatherGameScreen()),
            );
          },
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 12),

        _buildActivityCard(
          context,
          title: 'Truth or Dare: Romantic Edition',
          description: 'Intimate questions and sweet challenges made exclusively for two.',
          icon: Icons.favorite_border_rounded,
          accentColor: AppColors.roseDust,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TruthOrDareGameScreen()),
            );
          },
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 28),

        Text(
          'Synchronized Media & Creative',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 14),

        _buildActivityCard(
          context,
          title: 'Watch Room',
          description: 'Watch synchronized video clips with realtime reactions and private whispers.',
          icon: Icons.movie_outlined,
          accentColor: const Color(0xFF457B9D),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WatchRoomScreen(
                  relationshipId: relationshipId,
                  partnerName: partnerName,
                ),
              ),
            );
          },
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 12),

        _buildActivityCard(
          context,
          title: 'Shared Drawing Canvas',
          description: 'Draw love doodles together in real-time on your private synchronized canvas.',
          icon: Icons.draw_outlined,
          accentColor: const Color(0xFF52B788),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SharedDrawingCanvasScreen(
                  relationshipId: relationshipId,
                  partnerName: partnerName,
                ),
              ),
            );
          },
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textTertiaryDark,
          ),
        ],
      ),
    );
  }
}
