import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Vault Master Key Management
  Future<void> saveVaultMasterKey(String key) async {
    await write(AppConstants.secureKeyVaultMasterKey, key);
  }

  Future<String?> getVaultMasterKey() async {
    return await read(AppConstants.secureKeyVaultMasterKey);
  }

  // App Lock PIN Management
  Future<void> saveAppLockPin(String pin) async {
    await write(AppConstants.secureKeyAppLockPin, pin);
  }

  Future<String?> getAppLockPin() async {
    return await read(AppConstants.secureKeyAppLockPin);
  }

  Future<bool> hasAppLockPin() async {
    final pin = await getAppLockPin();
    return pin != null && pin.isNotEmpty;
  }
}
