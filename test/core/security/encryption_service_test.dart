import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/security/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    late EncryptionService encryptionService;

    setUp(() {
      encryptionService = EncryptionService();
    });

    test('Should encrypt and decrypt plaintext string correctly with AES-256-GCM', () async {
      final key = await encryptionService.generateRandomKey();
      const originalText = 'Private Love Note: You are my world! ❤️';

      final encrypted = await encryptionService.encryptText(originalText, key);

      expect(encrypted.cipherText, isNotEmpty);
      expect(encrypted.nonce, isNotEmpty);
      expect(encrypted.authTag, isNotEmpty);
      expect(encrypted.cipherText, isNot(equals(originalText)));

      final decrypted = await encryptionService.decryptText(encrypted, key);
      expect(decrypted, equals(originalText));
    });

    test('Should fail or throw when decrypting with incorrect secret key', () async {
      final key1 = await encryptionService.generateRandomKey();
      final key2 = await encryptionService.generateRandomKey();
      const secretNote = 'Secret Vault Item Content';

      final encrypted = await encryptionService.encryptText(secretNote, key1);

      expect(
        () async => await encryptionService.decryptText(encrypted, key2),
        throwsA(anything),
      );
    });

    test('Should encrypt and decrypt raw bytes accurately', () async {
      final key = await encryptionService.generateRandomKey();
      final originalBytes = Uint8List.fromList([1, 2, 3, 4, 5, 255, 128, 64]);
      final nonce = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

      final encryptedBytes = await encryptionService.encryptBytes(originalBytes, key, nonce);
      expect(encryptedBytes, isNot(equals(originalBytes)));

      final decryptedBytes = await encryptionService.decryptBytes(encryptedBytes, key);
      expect(decryptedBytes, equals(originalBytes));
    });
  });
}
