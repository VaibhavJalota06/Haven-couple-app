import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class EncryptionResult {
  final String cipherText;
  final String nonce;
  final String authTag;

  EncryptionResult({
    required this.cipherText,
    required this.nonce,
    required this.authTag,
  });

  Map<String, dynamic> toJson() => {
        'cipherText': cipherText,
        'nonce': nonce,
        'authTag': authTag,
      };

  factory EncryptionResult.fromJson(Map<String, dynamic> json) =>
      EncryptionResult(
        cipherText: json['cipherText'] as String,
        nonce: json['nonce'] as String,
        authTag: json['authTag'] as String,
      );
}

class EncryptionService {
  final AesGcm _aesGcm = AesGcm.with256bits();

  /// Derives a 256-bit SecretKey from a given passphrase/secret using PBKDF2 with SHA-256
  Future<SecretKey> deriveKeyFromPassphrase(String passphrase, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  /// Generates a random 256-bit SecretKey
  Future<SecretKey> generateRandomKey() async {
    return _aesGcm.newSecretKey();
  }

  /// Encrypts plaintext string using AES-256-GCM
  Future<EncryptionResult> encryptText(String plainText, SecretKey key) async {
    final clearBytes = utf8.encode(plainText);
    final secretBox = await _aesGcm.encrypt(
      clearBytes,
      secretKey: key,
    );

    return EncryptionResult(
      cipherText: base64Encode(secretBox.cipherText),
      nonce: base64Encode(secretBox.nonce),
      authTag: base64Encode(secretBox.mac.bytes),
    );
  }

  /// Decrypts ciphertext back to plaintext string using AES-256-GCM
  Future<String> decryptText(EncryptionResult encrypted, SecretKey key) async {
    final cipherBytes = base64Decode(encrypted.cipherText);
    final nonceBytes = base64Decode(encrypted.nonce);
    final macBytes = base64Decode(encrypted.authTag);

    final secretBox = SecretBox(
      cipherBytes,
      nonce: nonceBytes,
      mac: Mac(macBytes),
    );

    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: key,
    );

    return utf8.decode(decryptedBytes);
  }

  /// Encrypts raw bytes (for photos, audio, files)
  Future<Uint8List> encryptBytes(Uint8List data, SecretKey key, List<int> nonce) async {
    final secretBox = await _aesGcm.encrypt(
      data,
      secretKey: key,
      nonce: nonce,
    );
    return Uint8List.fromList(secretBox.concatenation());
  }

  /// Decrypts raw bytes
  Future<Uint8List> decryptBytes(Uint8List concatenatedData, SecretKey key) async {
    final secretBox = SecretBox.fromConcatenation(
      concatenatedData,
      nonceLength: _aesGcm.nonceLength,
      macLength: _aesGcm.macAlgorithm.macLength,
    );
    final decrypted = await _aesGcm.decrypt(secretBox, secretKey: key);
    return Uint8List.fromList(decrypted);
  }
}
