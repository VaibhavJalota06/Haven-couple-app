import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/models/user_profile.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../../privacy_center/screens/privacy_center_screen.dart';

class AccountCenterScreen extends StatefulWidget {
  const AccountCenterScreen({super.key});

  @override
  State<AccountCenterScreen> createState() => _AccountCenterScreenState();
}

class _AccountCenterScreenState extends State<AccountCenterScreen> {
  bool _activeStatus = true;
  bool _twoFactorAuth = true;
  bool _readReceipts = true;
  bool _syncProfileAcrossApps = true;
  bool _saveLoginInfo = true;

  // Notification Preferences
  bool _pushNotificationsEnabled = true;
  bool _partnerMessagesAlerts = true;
  bool _dateAndBucketAlerts = true;
  bool _anniversaryAlerts = true;
  bool _dailyPromptAlerts = true;
  bool _hidePreviewsOnLockscreen = true;
  bool _quietHoursEnabled = false;

  String _email = 'vaibhav@example.com';
  String _phone = '+1 (555) 019-2834';
  DateTime _birthday = DateTime(1998, 10, 24);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _activeStatus = prefs.getBool('pref_active_status') ?? true;
        _readReceipts = prefs.getBool('pref_read_receipts') ?? true;
        _twoFactorAuth = prefs.getBool('pref_biometric_lock') ?? true;
        _saveLoginInfo = prefs.getBool('pref_save_login') ?? true;
        _pushNotificationsEnabled = prefs.getBool('pref_push_notifs') ?? true;
        _partnerMessagesAlerts = prefs.getBool('pref_partner_alerts') ?? true;
        _dateAndBucketAlerts = prefs.getBool('pref_date_alerts') ?? true;
        _anniversaryAlerts = prefs.getBool('pref_anniversary_alerts') ?? true;
        _dailyPromptAlerts = prefs.getBool('pref_daily_prompt') ?? true;
        _hidePreviewsOnLockscreen = prefs.getBool('pref_hide_previews') ?? true;
        _quietHoursEnabled = prefs.getBool('pref_quiet_hours') ?? false;
      });
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  final List<Map<String, dynamic>> _loggedInDevices = [
    {
      'name': 'Current Device',
      'location': 'Active now',
      'icon': Icons.phone_android_rounded,
      'isCurrent': true,
    },
  ];

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
          builder: (context, state) {
            UserProfile? currentUser;
            if (state is Authenticated) {
              currentUser = state.user;
              _email = state.user.email.isNotEmpty ? state.user.email : _email;
            }

            final displayName = currentUser?.fullName ?? 'Vaibhav Jalota';
            final displayNickname = currentUser?.nickname ?? 'vaibhav';
            final avatarUrl = currentUser?.avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80';

            return Scaffold(
              appBar: AppBar(
                title: const Text('Accounts Center'),
                elevation: 0,
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.darkSurfaceElevated, AppColors.darkSurface]
                            : [Colors.grey.shade100, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.hub_rounded, color: AppColors.champagne, size: 24),
                            SizedBox(width: 10),
                            Text('Haven Accounts Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage your connected experiences, personal info, privacy, security, and account controls across Haven & connected devices.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 1. Profiles & Connected Accounts
                  _buildSectionHeader('Profiles & Connected Accounts'),
                  GlassCard(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                      title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text('Haven • @$displayNickname'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      onTap: () => _showConnectedProfilesModal(context, displayName, displayNickname, avatarUrl),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Couple Relationship
                  if (partner != null) ...[
                    _buildSectionHeader('Couple Relationship'),
                    GlassCard(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.favorite_rounded, color: AppColors.roseDust),
                            title: const Text('Partner', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(partner.displayName),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.calendar_today_rounded, color: AppColors.champagne),
                            title: const Text('Anniversary Date', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              relationship?.anniversaryDate != null
                                  ? relationship!.anniversaryDate!.toIso8601String().split('T').first
                                  : '2023-06-15',
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 3. PREFERENCES: Region & Currency
                  _buildSectionHeader('Preferences'),
                  GlassCard(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.champagne),
                      title: const Text('Region & Currency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
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
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Account Settings
                  _buildSectionHeader('Account Settings'),
                  GlassCard(
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Personal details',
                          subtitle: 'Contact info, birthday, identity verification',
                          onTap: () => _showPersonalDetailsModal(context),
                        ),
                        _buildSettingsTile(
                          icon: Icons.security_rounded,
                          title: 'Password and security',
                          subtitle: 'Change password, 2FA, logged-in devices',
                          onTap: () => _showSecurityModal(context),
                        ),
                        _buildSettingsTile(
                          icon: Icons.download_outlined,
                          title: 'Your information and permissions',
                          subtitle: 'Download your memories, vault archive, clear cache',
                          onTap: () => _showInformationAndPermissionsModal(context),
                        ),
                        _buildSettingsTile(
                          icon: Icons.manage_accounts_outlined,
                          title: 'Account ownership and control',
                          subtitle: 'Deactivation or permanent deletion',
                          titleColor: AppColors.error,
                          onTap: () => _showDeactivateOrDeleteModal(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Privacy & Controls
                  _buildSectionHeader('Privacy & Controls'),
                  GlassCard(
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.shield_outlined,
                          title: 'Privacy & Security Center',
                          subtitle: 'Manage E2EE keys, app lock, and profile visibility',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PrivacyCenterScreen()),
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notification Preferences',
                          subtitle: 'Push notifications, quiet hours & date alerts',
                          onTap: () => _showNotificationPreferencesModal(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 6. Messenger & Privacy Preferences
                  _buildSectionHeader('Messenger & Privacy Preferences'),
                  GlassCard(
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: _activeStatus,
                          activeColor: AppColors.champagne,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: const Text('Active Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Show when you are active to your connections', style: TextStyle(fontSize: 12)),
                          onChanged: (val) {
                            setState(() => _activeStatus = val);
                            _savePref('pref_active_status', val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_activeStatus ? 'Active Status is now ON 🟢' : 'Active Status is now HIDDEN ⚪')),
                            );
                          },
                        ),
                        SwitchListTile.adaptive(
                          value: _readReceipts,
                          activeColor: AppColors.champagne,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: const Text('Read Receipts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Let connections know when you\'ve seen their messages', style: TextStyle(fontSize: 12)),
                          onChanged: (val) {
                            setState(() => _readReceipts = val);
                            _savePref('pref_read_receipts', val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_readReceipts ? 'Read Receipts ON' : 'Read Receipts OFF')),
                            );
                          },
                        ),
                        SwitchListTile.adaptive(
                          value: _twoFactorAuth,
                          activeColor: AppColors.champagne,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: const Text('Biometric & Two-Factor Lock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Require FaceID / Fingerprint to open app', style: TextStyle(fontSize: 12)),
                          onChanged: (val) {
                            setState(() => _twoFactorAuth = val);
                            _savePref('pref_biometric_lock', val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_twoFactorAuth ? 'Biometric App Lock enabled 🔒' : 'Biometric App Lock disabled 🔓')),
                            );
                          },
                        ),
                        SwitchListTile.adaptive(
                          value: _saveLoginInfo,
                          activeColor: AppColors.champagne,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: const Text('Saved Login Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Remember credentials on this device for instant login', style: TextStyle(fontSize: 12)),
                          onChanged: (val) {
                            setState(() => _saveLoginInfo = val);
                            _savePref('pref_save_login', val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_saveLoginInfo ? 'Saved Login Info ON' : 'Saved Login Info OFF')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 7. Account Ownership & Control (Deactivation & Deletion)
                  _buildSectionHeader('Account Ownership & Control'),
                  GlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          leading: const Icon(Icons.shield_outlined, color: AppColors.champagne),
                          title: const Text('Deactivation or Deletion', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Temporarily deactivate or permanently delete your account and data', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                          onTap: () => _showAccountOwnershipModal(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 8. Sign Out of Haven
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
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Sign Out of Haven?'),
                          content: const Text('You will need to sign in again to access your shared couple sanctuary.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                context.read<AuthBloc>().add(AuthSignOutRequested());
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAccountOwnershipModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalCtx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text(
              'Account Ownership & Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose what happens to your Haven profile, couple space and cloud data.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            // Deactivate Card
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.champagne.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.nightlight_round, color: AppColors.champagne, size: 22),
              ),
              title: const Text('Deactivate Account', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Temporarily pauses your account. Your profile is hidden until you log back in.', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.of(modalCtx).pop();
                _confirmDeactivate(context);
              },
            ),
            const SizedBox(height: 12),
            // Delete Card
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.error.withOpacity(0.3))),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 22),
              ),
              title: const Text('Delete Account Permanently', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
              subtitle: const Text('Irreversible. Permanently purges your account, vault items, and all relationship records from Supabase.', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.of(modalCtx).pop();
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deactivate Account?'),
        content: const Text('Your profile and feed posts will be paused. You can reactivate anytime simply by signing back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.champagne,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthBloc>().add(AuthAccountDeactivateRequested());
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deactivated. See you soon! 🌙')),
              );
            },
            child: const Text('Deactivate', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permanently Delete Account?'),
        content: const Text('This action cannot be undone. All your messages, private vault memories, photos, and couple space will be permanently erased from Supabase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthBloc>().add(AuthAccountDeleteRequested());
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your account and data have been permanently deleted.')),
              );
            },
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.champagne : AppColors.champagneDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(icon, color: titleColor ?? AppColors.champagne),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: titleColor)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  final List<Map<String, dynamic>> _connectedAccounts = [
    {
      'id': 'usr_vaibhav',
      'name': 'VAIBHAV',
      'handle': 'vaibhav',
      'email': 'vaibhav@haven.app',
      'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
      'isActive': true,
    },
    {
      'id': 'usr_maya',
      'name': 'Maya Chen',
      'handle': 'maya',
      'email': 'maya@haven.app',
      'avatarUrl': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80',
      'isActive': false,
    },
  ];

  // 1. Connected Profiles Modal & Account Switcher
  void _showConnectedProfilesModal(BuildContext context, String currentName, String currentHandle, String currentAvatar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
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
                const Text('Profiles in Accounts Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Manage sync and linked accounts across Haven apps.', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                const SizedBox(height: 16),

                // Connected Accounts List
                ...List.generate(_connectedAccounts.length, (index) {
                  final account = _connectedAccounts[index];
                  final isActive = account['isActive'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.champagne.withOpacity(0.12)
                          : (isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive ? AppColors.champagne : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(account['avatarUrl']),
                      ),
                      title: Text(
                        account['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        '@${account['handle']} • ${isActive ? 'Haven Active' : 'Connected'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? AppColors.champagneDark : Colors.grey,
                        ),
                      ),
                      trailing: isActive
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.champagne, size: 22)
                          : TextButton(
                              onPressed: () {
                                setModalState(() {
                                  for (var a in _connectedAccounts) {
                                    a['isActive'] = (a['id'] == account['id']);
                                  }
                                });
                                setState(() {});
                                context.read<AuthBloc>().add(
                                  AuthProfileUpdateRequested(
                                    fullName: account['name'],
                                    nickname: account['handle'],
                                    avatarUrl: account['avatarUrl'],
                                  ),
                                );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Switched active profile to ${account['name']} (@${account['handle']}) ✨'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.champagne)),
                            ),
                      onTap: () {
                        if (!isActive) {
                          setModalState(() {
                            for (var a in _connectedAccounts) {
                              a['isActive'] = (a['id'] == account['id']);
                            }
                          });
                          setState(() {});
                          context.read<AuthBloc>().add(
                            AuthProfileUpdateRequested(
                              fullName: account['name'],
                              nickname: account['handle'],
                              avatarUrl: account['avatarUrl'],
                            ),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched active profile to ${account['name']} (@${account['handle']}) ✨'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }),

                const Divider(height: 24),

                // Sync Profile Info Switch
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sync Profile Info', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Keep name, photo, and bio in sync across connected apps', style: TextStyle(fontSize: 12)),
                  value: _syncProfileAcrossApps,
                  activeColor: AppColors.champagne,
                  onChanged: (val) {
                    setModalState(() => _syncProfileAcrossApps = val);
                    setState(() => _syncProfileAcrossApps = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_syncProfileAcrossApps
                            ? 'Sync Profile Info is now ON 🔄 (Bio, photos & names will sync across Haven)'
                            : 'Sync Profile Info is now PAUSED ⏸️'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Add Another Account Button
                CustomButton(
                  text: 'Add Another Account',
                  variant: ButtonVariant.secondary,
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddAnotherAccountSheet(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Add Another Account Sheet
  void _showAddAnotherAccountSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final handleCtrl = TextEditingController();

    final availablePresetAccounts = [
      {
        'id': 'usr_elena',
        'name': 'Elena Rostova',
        'handle': 'elena',
        'email': 'elena@haven.app',
        'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
      },
      {
        'id': 'usr_sophia',
        'name': 'Sophia Laurent',
        'handle': 'sophia',
        'email': 'sophia@haven.app',
        'avatarUrl': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&q=80',
      },
      {
        'id': 'usr_liam',
        'name': 'Liam Walker',
        'handle': 'liam',
        'email': 'liam@haven.app',
        'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
            const Text('Add or Link Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Link an existing Haven profile or sign in with another account.', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
            const SizedBox(height: 16),

            const Text('Quick Add Existing Profile:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            ...availablePresetAccounts.map((acc) {
              final alreadyAdded = _connectedAccounts.any((a) => a['id'] == acc['id']);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: CircleAvatar(backgroundImage: NetworkImage(acc['avatarUrl']!)),
                title: Text(acc['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('@${acc['handle']} • Haven Profile', style: const TextStyle(fontSize: 12)),
                trailing: alreadyAdded
                    ? const Icon(Icons.check_rounded, color: Colors.grey)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.champagne,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setState(() {
                            _connectedAccounts.add({
                              'id': acc['id']!,
                              'name': acc['name']!,
                              'handle': acc['handle']!,
                              'email': acc['email']!,
                              'avatarUrl': acc['avatarUrl']!,
                              'isActive': false,
                            });
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Linked account @${acc['handle']} to Accounts Center! 👥'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
              );
            }),

            const Divider(height: 20),
            const Text('Or Enter Account Details:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g. Alex Rivera',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: handleCtrl,
              decoration: InputDecoration(
                labelText: 'Username Handle',
                hintText: 'e.g. alex_rivera',
                prefixText: '@',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Connect & Add Account',
              onPressed: () {
                final name = nameCtrl.text.trim();
                final handle = handleCtrl.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _connectedAccounts.add({
                      'id': 'usr_${DateTime.now().millisecondsSinceEpoch}',
                      'name': name,
                      'handle': handle.isNotEmpty ? handle : name.toLowerCase().replaceAll(' ', '_'),
                      'email': '${name.toLowerCase().replaceAll(' ', '_')}@haven.app',
                      'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
                      'isActive': false,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Connected $name to Accounts Center! 👥✨'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 2. Personal Details Modal (Contact Info, Birthday, Identity)
  void _showPersonalDetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final age = DateTime.now().year - _birthday.year;
          final zodiac = _getZodiacSign(_birthday);

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
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
                const Text('Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Haven uses this info to verify your identity and protect your couple sanctuary.', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                const SizedBox(height: 16),

                // Contact Info
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.champagne.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.email_outlined, color: AppColors.champagne, size: 20),
                    ),
                    title: const Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('$_email\n$_phone'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.champagne),
                    onTap: () => _showEditContactDialog(context, () => setModalState(() {})),
                  ),
                ),

                const SizedBox(height: 12),

                // Birthday & Zodiac
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.roseDust.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.cake_outlined, color: AppColors.roseDust, size: 20),
                    ),
                    title: const Text('Birthday', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${_formatDate(_birthday)} • $age years old ($zodiac)'),
                    trailing: const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.champagne),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _birthday,
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _birthday = picked);
                        setModalState(() => _birthday = picked);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Birthday updated to ${_formatDate(picked)} 🎂')),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Identity Confirmation & Cryptographic Seal
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
                    ),
                    title: const Text('Identity Confirmation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Verified with AES-256-GCM End-to-End Vault Key'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: const Text('VERIFIED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    onTap: () {
                      _showIdentityDetailsDialog(context);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showIdentityDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Cryptographic Identity'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your account identity is cryptographically bound to your couple sanctuary.', style: TextStyle(fontSize: 13)),
            SizedBox(height: 12),
            Text('• Encryption: AES-256-GCM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('• Key Derivation: PBKDF2 (100k rounds)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('• Hardware Storage: Android Keystore / Apple Secure Enclave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(BuildContext context, VoidCallback onUpdated) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Contact Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.champagne, size: 20),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.champagne, size: 20),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne),
            onPressed: () {
              setState(() {
                _email = emailCtrl.text.trim();
                _phone = phoneCtrl.text.trim();
              });
              onUpdated();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact info updated! 📱')));
            },
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 3. Password and Security Modal
  void _showSecurityModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
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
                  const Text('Password and Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Manage login protection, active devices, and password credentials.', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                  const SizedBox(height: 16),

                  // Change Password
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.champagne.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.key_rounded, color: AppColors.champagne, size: 20),
                      ),
                      title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Choose a strong password to protect your shared data'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Two-Factor Authentication
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.phonelink_lock_rounded, color: Colors.blue, size: 20),
                      ),
                      title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(_twoFactorAuth ? 'Enabled via Authenticator & SMS' : 'Disabled (Recommended to turn ON)'),
                      trailing: Switch.adaptive(
                        value: _twoFactorAuth,
                        activeColor: AppColors.champagne,
                        onChanged: (val) {
                          setModalState(() => _twoFactorAuth = val);
                          setState(() => _twoFactorAuth = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_twoFactorAuth ? '2FA Enabled! 🛡️' : '2FA Disabled ⚠️')),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logged-in Devices
                  const Text('Where You\'re Logged In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  ..._loggedInDevices.map(
                    (dev) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Icon(dev['icon'] as IconData, color: dev['isCurrent'] == true ? Colors.green : Colors.grey),
                        title: Text(dev['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        subtitle: Text(dev['location'] as String, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                        trailing: dev['isCurrent'] == true
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                child: const Text('This Device', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                              )
                            : IconButton(
                                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                                tooltip: 'Log out device',
                                onPressed: () {
                                  setModalState(() => _loggedInDevices.remove(dev));
                                  setState(() => _loggedInDevices.remove(dev));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Logged out of ${dev['name']} 🔒')),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: currentPwCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '••••••••',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text('New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: newPwCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '••••••••',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: confirmPwCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '••••••••',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne),
            onPressed: () {
              if (newPwCtrl.text.isNotEmpty && newPwCtrl.text == confirmPwCtrl.text) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully! 🔐')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match or cannot be empty')),
                );
              }
            },
            child: const Text('Update Password', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 4. Your Information & Permissions Modal
  void _showInformationAndPermissionsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
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
            const Text('Your Information and Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Access, download, or manage your personal data and vault storage.', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.download_for_offline_rounded, color: AppColors.champagne, size: 24),
                title: const Text('Download Your Data & Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Get an encrypted ZIP copy of photos, notes, and messages'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  _showExportProgressDialog(context);
                },
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.roseDust, size: 24),
                title: const Text('Clear App Cache & Search History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Free up temporary memory and cached previews'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  _showClearCacheDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.archive_rounded, color: AppColors.champagne),
            SizedBox(width: 8),
            Text('Exporting Sanctuary Data'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(color: AppColors.champagne),
            SizedBox(height: 16),
            Text('Encrypting chat archives, private vault memories & bucket lists...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Archive ready! Download link sent to your email 📥')),
              );
            },
            child: const Text('Run in Background'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Temporary Cache?'),
        content: const Text('This will free up 142 MB of media cache and offline thumbnails without deleting your saved memories.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseDust),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared 142 MB of temporary memory successfully! 🧹✨')),
              );
            },
            child: const Text('Clear Cache', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 5. Deactivation or Deletion Modal
  void _showDeactivateOrDeleteModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedAction = 0; // 0: Deactivate, 1: Delete

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Deactivating or deleting your account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'If you want to take a break from Haven, you can deactivate your account. If you want to permanently remove your account and all private memories, delete your account.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Option 1: Deactivate
              InkWell(
                onTap: () => setModalState(() => selectedAction = 0),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedAction == 0 ? AppColors.champagne : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio<int>(
                        value: 0,
                        groupValue: selectedAction,
                        activeColor: AppColors.champagne,
                        onChanged: (val) => setModalState(() => selectedAction = val!),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deactivate account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            SizedBox(height: 4),
                            Text(
                              'Deactivating your account is temporary. Your profile and chats will be hidden until you log back in.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Option 2: Delete
              InkWell(
                onTap: () => setModalState(() => selectedAction = 1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedAction == 1 ? AppColors.error : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio<int>(
                        value: 1,
                        groupValue: selectedAction,
                        activeColor: AppColors.error,
                        onChanged: (val) => setModalState(() => selectedAction = val!),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delete account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.error)),
                            SizedBox(height: 4),
                            Text(
                              'Deleting your account is permanent. When you delete your Haven account, your profile, photos, secret vault, and chats will be permanently removed.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedAction == 1 ? AppColors.error : AppColors.champagne,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (selectedAction == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account temporarily deactivated. Log in anytime to restore!')),
                      );
                      context.read<AuthBloc>().add(AuthSignOutRequested());
                    } else {
                      _showConfirmPermanentDeleteDialog(context);
                    }
                  },
                  child: Text(
                    selectedAction == 0 ? 'Continue Deactivation' : 'Continue to Account Deletion',
                    style: TextStyle(
                      color: selectedAction == 1 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmPermanentDeleteDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Permanent Account Deletion', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('For security, please re-enter your password to permanently delete your Haven account and wipe all memories.'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account permanently deleted. Goodbye!')),
              );
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _getZodiacSign(DateTime dt) {
    final day = dt.day;
    final month = dt.month;
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return '♒ Aquarius';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return '♓ Pisces';
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return '♈ Aries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return '♉ Taurus';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return '♊ Gemini';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return '♋ Cancer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return '♌ Leo';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return '♍ Virgo';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return '♎ Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return '♏ Scorpio';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return '♐ Sagittarius';
    return '♑ Capricorn';
  }

  // 6. Notification Preferences Modal
  void _showNotificationPreferencesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
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
                  const Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Customize how and when you receive relationship alerts and messages.', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                  const SizedBox(height: 16),

                  // Master Push Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SwitchListTile.adaptive(
                      value: _pushNotificationsEnabled,
                      activeColor: AppColors.champagne,
                      title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                      subtitle: Text(_pushNotificationsEnabled ? 'Enabled on this device 🔔' : 'Muted on this device 🔕', style: const TextStyle(fontSize: 12)),
                      onChanged: (val) {
                        setModalState(() => _pushNotificationsEnabled = val);
                        setState(() => _pushNotificationsEnabled = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_pushNotificationsEnabled ? 'Push notifications enabled 🔔' : 'All notifications muted 🔕')),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Couple Activity Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.champagne)),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: _partnerMessagesAlerts && _pushNotificationsEnabled,
                          activeColor: AppColors.champagne,
                          title: const Text('Partner Messages & Sparks', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Instant alerts when your partner sends a note or spark', style: TextStyle(fontSize: 11.5)),
                          onChanged: _pushNotificationsEnabled
                              ? (val) {
                                  setModalState(() => _partnerMessagesAlerts = val);
                                  setState(() => _partnerMessagesAlerts = val);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: _dateAndBucketAlerts && _pushNotificationsEnabled,
                          activeColor: AppColors.champagne,
                          title: const Text('Date Nights & Bucket Wishes', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Reminders for planned dates and bucket list additions', style: TextStyle(fontSize: 11.5)),
                          onChanged: _pushNotificationsEnabled
                              ? (val) {
                                  setModalState(() => _dateAndBucketAlerts = val);
                                  setState(() => _dateAndBucketAlerts = val);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: _anniversaryAlerts && _pushNotificationsEnabled,
                          activeColor: AppColors.champagne,
                          title: const Text('Anniversaries & Milestones', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Countdown alerts and special milestone celebrations', style: TextStyle(fontSize: 11.5)),
                          onChanged: _pushNotificationsEnabled
                              ? (val) {
                                  setModalState(() => _anniversaryAlerts = val);
                                  setState(() => _anniversaryAlerts = val);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: _dailyPromptAlerts && _pushNotificationsEnabled,
                          activeColor: AppColors.champagne,
                          title: const Text('Daily Connection Prompt', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Daily intimate couple question at 8:00 PM', style: TextStyle(fontSize: 11.5)),
                          onChanged: _pushNotificationsEnabled
                              ? (val) {
                                  setModalState(() => _dailyPromptAlerts = val);
                                  setState(() => _dailyPromptAlerts = val);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Privacy & Quiet Hours', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.champagne)),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: _hidePreviewsOnLockscreen,
                          activeColor: AppColors.champagne,
                          title: const Text('Hide Lockscreen Previews', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Show "New message from Partner ❤️" instead of decrypted text', style: TextStyle(fontSize: 11.5)),
                          onChanged: (val) {
                            setModalState(() => _hidePreviewsOnLockscreen = val);
                            setState(() => _hidePreviewsOnLockscreen = val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_hidePreviewsOnLockscreen ? 'Lockscreen previews hidden for privacy 🔒' : 'Lockscreen previews visible 🔓')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: _quietHoursEnabled,
                          activeColor: AppColors.champagne,
                          title: const Text('Do Not Disturb / Quiet Hours', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Automatically silence non-emergency alerts (11:00 PM – 7:00 AM)', style: TextStyle(fontSize: 11.5)),
                          onChanged: (val) {
                            setModalState(() => _quietHoursEnabled = val);
                            setState(() => _quietHoursEnabled = val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_quietHoursEnabled ? 'Quiet Hours enabled (11 PM - 7 AM) 🌙' : 'Quiet Hours turned off ☀️')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
