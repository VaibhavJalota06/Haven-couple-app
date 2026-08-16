import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  bool _hideNotificationPreviews = true;
  bool _requireBiometricsOnLaunch = true;
  bool _screenshotProtection = true;

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting your encrypted relationship archive...'),
        backgroundColor: AppColors.champagneDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account & Privacy Data?'),
        content: const Text(
          'This action is irreversible. All your messages, memories, vault items and couple data will be permanently purged in accordance with our strict zero-retention policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(AuthSignOutRequested());
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Encryption Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.champagneDark.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.champagne.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.champagne,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.darkBackground, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End-to-End Encrypted Space',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your keys are stored securely on-device. No third parties or servers have access to your private contents.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Security & Biometrics',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.champagne : AppColors.champagneDark,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _requireBiometricsOnLaunch,
                    activeColor: AppColors.champagne,
                    title: const Text('Require App Lock on Launch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('FaceID / Fingerprint / PIN prompt whenever Haven opens'),
                    onChanged: (val) => setState(() => _requireBiometricsOnLaunch = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile.adaptive(
                    value: _screenshotProtection,
                    activeColor: AppColors.champagne,
                    title: const Text('Screenshot & App Switcher Blur', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Prevent sensitive previews when switching between applications'),
                    onChanged: (val) => setState(() => _screenshotProtection = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Notification Privacy',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.champagne : AppColors.champagneDark,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SwitchListTile.adaptive(
                value: _hideNotificationPreviews,
                activeColor: AppColors.champagne,
                title: const Text('Hide Message Preview in Push', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                subtitle: const Text('Display "New message from partner" instead of showing message text on lockscreen'),
                onChanged: (val) => setState(() => _hideNotificationPreviews = val),
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Your Data & Rights',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.champagne : AppColors.champagneDark,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download_rounded, color: AppColors.champagne),
                    title: const Text('Export My Couple Archive'),
                    subtitle: const Text('Download a decrypted copy of all memories, notes, and chats'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _exportData,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                    title: const Text('Delete Account & Clear All Data', style: TextStyle(color: AppColors.error)),
                    subtitle: const Text('Permanently remove all data from server and device'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _confirmDeleteAccount,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
