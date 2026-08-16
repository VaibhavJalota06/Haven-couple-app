import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              const Spacer(flex: 2),

              // Brand Icon & Ring Animation
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.champagne.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.champagne.withOpacity(0.25),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite_rounded,
                          color: AppColors.roseDust,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 36),

              // Brand Title & Tagline
              Text(
                'Haven',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              Text(
                'Your private digital home for two.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w400,
                    ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 18),

              // Privacy Tag Badge (Clean borderless glass pill)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated.withOpacity(0.7) : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: isDark ? AppColors.champagne : AppColors.champagneDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'End-to-End Encrypted & Private',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const Spacer(flex: 3),

              // Actions
              CustomButton(
                text: 'Create New Couple Space',
                icon: Icons.favorite_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                variant: ButtonVariant.primary,
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              CustomButton(
                text: 'Sign In to Your Space',
                icon: Icons.login_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                variant: ButtonVariant.secondary,
              ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
