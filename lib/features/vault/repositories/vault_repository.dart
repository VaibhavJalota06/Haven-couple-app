import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/security/secure_storage_service.dart';
import '../models/vault_item_model.dart';

class VaultRepository {
  final SupabaseClient _client;
  final EncryptionService _encryptionService;
  final SecureStorageService _storageService;
  final _uuid = const Uuid();

  VaultRepository({
    SupabaseClient? client,
    EncryptionService? encryptionService,
    SecureStorageService? storageService,
  })  : _client = client ?? SupabaseService.client,
        _encryptionService = encryptionService ?? EncryptionService(),
        _storageService = storageService ?? SecureStorageService();

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Get or derive Master SecretKey from secure storage
  Future<SecretKey> _getVaultKey() async {
    var keyBase64 = await _storageService.getVaultMasterKey();
    if (keyBase64 == null) {
      final key = await _encryptionService.generateRandomKey();
      final keyBytes = await key.extractBytes();
      keyBase64 = base64Encode(keyBytes);
      await _storageService.saveVaultMasterKey(keyBase64);
      return key;
    }
    final bytes = base64Decode(keyBase64);
    return SecretKey(bytes);
  }

  /// Fetch all encrypted vault items for relationship
  Future<List<VaultItemModel>> getVaultItems(String relationshipId) async {
    try {
      final data = await _client
          .from('vault_items')
          .select()
          .eq('relationship_id', relationshipId)
          .order('created_at', ascending: false);

      return (data as List).map((json) => VaultItemModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create and encrypt a new vault item (note or photo description)
  Future<VaultItemModel> createEncryptedVaultItem({
    required String relationshipId,
    required String title,
    required String rawContent,
    required VaultItemType itemType,
    String? mediaUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final key = await _getVaultKey();
    final encrypted = await _encryptionService.encryptText(rawContent, key);

    final payload = {
      'id': _uuid.v4(),
      'relationship_id': relationshipId,
      'owner_id': userId,
      'item_type': itemType.name,
      'title': title,
      'encrypted_payload': encrypted.cipherText,
      'iv': encrypted.nonce,
      'auth_tag': encrypted.authTag,
      'media_url': mediaUrl,
      'created_at': DateTime.now().toIso8601String(),
    };

    final result = await _client.from('vault_items').insert(payload).select().single();
    return VaultItemModel.fromJson(result);
  }

  /// Decrypt a vault item payload
  Future<String> decryptVaultPayload(VaultItemModel item) async {
    try {
      final key = await _getVaultKey();
      final encryptedResult = EncryptionResult(
        cipherText: item.encryptedPayload,
        nonce: item.iv,
        authTag: item.authTag,
      );
      return await _encryptionService.decryptText(encryptedResult, key);
    } catch (e) {
      return 'Encrypted content (Decryption key mismatch)';
    }
  }

  /// Delete a vault item
  Future<void> deleteVaultItem(String itemId) async {
    await _client.from('vault_items').delete().eq('id', itemId);
  }
}
