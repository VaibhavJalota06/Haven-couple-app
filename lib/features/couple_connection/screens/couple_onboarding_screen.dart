import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import 'create_relationship_screen.dart';
import 'join_relationship_screen.dart';

class CoupleOnboardingScreen extends StatelessWidget {
  const CoupleOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Connecting Hearts / Rings Graphic
              Center(
                child: SizedBox(
                  width: 140,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 15,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                            border: Border.all(color: AppColors.champagne, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.champagne.withOpacity(0.2),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.person_rounded, color: AppColors.champagne, size: 30),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 15,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                            border: Border.all(color: AppColors.roseDust, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.roseDust.withOpacity(0.2),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.favorite_rounded, color: AppColors.roseDust, size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 500.ms),

              const SizedBox(height: 36),

              Text(
                'Connect With Your Partner',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              Text(
                'Haven is made exclusively for two. One of you generates a secure link or code, and the other joins.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
              ).animate().fadeIn(delay: 300.ms),

              const Spacer(),

              CustomButton(
                text: 'Create a Couple Space',
                icon: Icons.add_circle_outline_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateRelationshipScreen()),
                  );
                },
                variant: ButtonVariant.primary,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 14),

              CustomButton(
                text: 'Join Partner With Invite Code',
                icon: Icons.key_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JoinRelationshipScreen()),
                  );
                },
                variant: ButtonVariant.secondary,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
