import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../bloc/couple_bloc.dart';
import '../bloc/couple_event.dart';
import '../bloc/couple_state.dart';
import 'relationship_setup_screen.dart';

class CreateRelationshipScreen extends StatefulWidget {
  const CreateRelationshipScreen({super.key});

  @override
  State<CreateRelationshipScreen> createState() => _CreateRelationshipScreenState();
}

class _CreateRelationshipScreenState extends State<CreateRelationshipScreen> {
  @override
  void initState() {
    super.initState();
    final state = context.read<CoupleBloc>().state;
    if (state is! CoupleNotPaired || state.pendingRelationship == null) {
      context.read<CoupleBloc>().add(CreateRelationshipRequested());
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied to clipboard!'),
        backgroundColor: AppColors.champagneDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareInviteCode(String code) {
    Share.share(
      'Join our private Haven couple space! Use my invite code: $code\nDownload Haven and enter this code to connect.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<CoupleBloc, CoupleState>(
      listener: (context, state) {
        if (state is CouplePaired) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RelationshipSetupScreen(relationship: state.relationship),
            ),
          );
        } else if (state is CoupleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CoupleLoading) {
          return const Scaffold(
            body: HavenLoadingIndicator(message: 'Generating your private space code...'),
          );
        }

        final pendingRel = (state is CoupleNotPaired) ? state.pendingRelationship : null;
        final inviteCode = pendingRel?.inviteCode ?? '------';

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Invite Your Partner',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share this unique 6-digit code with your partner. Once they enter it, your private space will activate.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 36),

                  // Code Display Glass Card
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          'YOUR INVITATION CODE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: isDark ? AppColors.champagne : AppColors.champagneDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: inviteCode.split('').map((char) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.lightSurfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.champagne.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () => _copyToClipboard(inviteCode),
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Copy Code'),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? AppColors.champagne : AppColors.champagneDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: () => _shareInviteCode(inviteCode),
                              icon: const Icon(Icons.share_outlined, size: 18),
                              label: const Text('Share Link'),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? AppColors.champagne : AppColors.champagneDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Waiting status indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Waiting for partner to connect...',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  CustomButton(
                    text: 'Refresh Status',
                    onPressed: () {
                      context.read<CoupleBloc>().add(CheckCoupleStatusRequested());
                    },
                    variant: ButtonVariant.secondary,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
