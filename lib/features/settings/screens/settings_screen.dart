import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../../privacy_center/screens/privacy_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showCurrencyPickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final currencies = CurrencyService.allCurrencies;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          height: 480,
          child: Column(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Currency & Region',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.champagne.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Auto: ${CurrencyService.flag} ${CurrencyService.code}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.champagne),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Used for date budgets, savings goals & shared finances',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (context, idx) {
                    final c = currencies[idx];
                    final isSelected = c.code == CurrencyService.code;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                      title: Text('${c.code} (${c.symbol})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(c.name, style: const TextStyle(fontSize: 12)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.champagne)
                          : null,
                      onTap: () {
                        CurrencyService.setCurrency(c);
                        Navigator.of(ctx).pop();
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Currency updated to ${c.flag} ${c.code} (${c.symbol})'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CoupleBloc, CoupleState>(
      builder: (context, coupleState) {
        final relationship = (coupleState is CouplePaired) ? coupleState.relationship : null;
        final partner = relationship?.partnerProfile;

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = (authState is Authenticated) ? authState.user : null;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Settings'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Profile Header Card
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.champagne.withOpacity(0.2),
                            child: Text(
                              (user?.displayName.isNotEmpty == true ? user!.displayName[0] : 'U'),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.champagne),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ?? 'My Profile',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Relationship Info Card
                    if (partner != null) ...[
                      Text(
                        'Couple Relationship',
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
                              leading: const Icon(Icons.favorite_rounded, color: AppColors.roseDust),
                              title: const Text('Partner'),
                              subtitle: Text(partner.displayName),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 4),
                            ListTile(
                              leading: const Icon(Icons.calendar_today_rounded, color: AppColors.champagne),
                              title: const Text('Anniversary Date'),
                              subtitle: Text(
                                relationship?.anniversaryDate != null
                                    ? relationship!.anniversaryDate!.toIso8601String().split('T').first
                                    : 'Not set',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Region & Currency
                    Text(
                      'PREFERENCES',
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
                            leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.champagne),
                            title: const Text('Region & Currency'),
                            subtitle: Text('Auto: ${CurrencyService.flag} ${CurrencyService.code} (${CurrencyService.symbol}) • ${CurrencyService.name}', style: const TextStyle(fontSize: 12)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.champagne.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${CurrencyService.flag} ${CurrencyService.code}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.champagne),
                              ),
                            ),
                            onTap: _showCurrencyPickerSheet,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Privacy & Security
                    Text(
                      'PRIVACY & CONTROLS',
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
                            leading: const Icon(Icons.security_rounded, color: AppColors.champagne),
                            title: const Text('Privacy & Security Center'),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PrivacyCenterScreen()),
                              );
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 4),
                          ListTile(
                            leading: const Icon(Icons.notifications_none_rounded, color: AppColors.roseDust),
                            title: const Text('Notification Preferences'),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Notifications active in privacy-first mode')),
                              );
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign Out Button
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.error),
                      ),
                      leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                      title: const Text(
                        'Sign Out of Haven',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        context.read<AuthBloc>().add(AuthSignOutRequested());
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
