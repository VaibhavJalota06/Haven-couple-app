class AppConstants {
  static const String appName = 'Haven';
  static const String appTagline = 'Your private digital home for two';
  static const String appVersion = '1.0.0';

  // Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String chatMediaBucket = 'chat_media';
  static const String memoriesBucket = 'memories';
  static const String vaultMediaBucket = 'vault_media';

  // Realtime channel names
  static const String chatBroadcastChannel = 'couple_chat';
  static const String callSignalBroadcastChannel = 'couple_call_signals';
  static const String togetherModeChannel = 'together_mode';

  // Storage keys
  static const String secureKeyAppLockPin = 'haven_app_lock_pin';
  static const String secureKeyBiometricEnabled = 'haven_biometric_enabled';
  static const String secureKeyVaultMasterKey = 'haven_vault_master_key';
  static const String secureKeyThemeMode = 'haven_theme_mode';

  // Default timeout constants
  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration vaultAutoLockDuration = Duration(minutes: 5);
}
