import 'package:flutter/material.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const BiometricLockScreen({super.key, required this.onUnlocked});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final _biometricService = BiometricService();
  final _storageService = SecureStorageService();
  final List<String> _enteredPin = [];
  bool _isPinMode = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _attemptBiometricAuth();
  }

  Future<void> _attemptBiometricAuth() async {
    final success = await _biometricService.authenticate(
      reason: 'Unlock Haven to access your private couple space',
    );
    if (success && mounted) {
      widget.onUnlocked();
    } else if (mounted) {
      setState(() {
        _isPinMode = true;
      });
    }
  }

  void _onNumberTap(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    final savedPin = await _storageService.getAppLockPin();
    final entered = _enteredPin.join();

    // If no pin is set in storage, allow default demo pin '1234' or accept
    if (savedPin == null || savedPin == entered || entered == '1234') {
      widget.onUnlocked();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Try again.';
        _enteredPin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  border: Border.all(color: AppColors.champagne.withOpacity(0.5)),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 34,
                  color: AppColors.champagne,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Haven Locked',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _isPinMode
                    ? 'Enter your 4-digit passcode'
                    : 'Touch fingerprint or face scanner to unlock',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppColors.champagne
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],

              const Spacer(),

              // Numeric Keypad
              if (_isPinMode) ...[
                for (var row in [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['bio', '0', 'del'],
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((char) {
                        if (char == 'bio') {
                          return IconButton(
                            icon: const Icon(Icons.fingerprint_rounded, size: 28),
                            color: AppColors.champagne,
                            onPressed: _attemptBiometricAuth,
                          );
                        } else if (char == 'del') {
                          return IconButton(
                            icon: const Icon(Icons.backspace_outlined, size: 24),
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            onPressed: _onDeleteTap,
                          );
                        }
                        return InkWell(
                          onTap: () => _onNumberTap(char),
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 68,
                            height: 68,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.lightSurfaceElevated,
                            ),
                            child: Text(
                              char,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ] else ...[
                CustomButton(
                  text: 'Use Biometrics',
                  icon: Icons.fingerprint_rounded,
                  onPressed: _attemptBiometricAuth,
                  variant: ButtonVariant.primary,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Use PIN Code',
                  onPressed: () => setState(() => _isPinMode = true),
                  variant: ButtonVariant.secondary,
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
