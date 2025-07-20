import 'package:flutter_test/flutter_test.dart';
import 'package:raabta/core/utils/encryption_utils.dart';
import 'package:raabta/core/services/encryption_key_manager.dart';

void main() {
  group('Encryption Tests', () {
    test('AES encryption and decryption should work correctly', () {
      // Generate a test key
      final key = EncryptionUtils.generateEncryptionKey();
      const plainText = 'Hello, this is a test message for E2EE!';

      // Encrypt the message
      final encrypted = EncryptionUtils.encryptWithAES(plainText, key);
      
      // Verify encrypted text is different from plain text
      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted.isNotEmpty, isTrue);

      // Decrypt the message
      final decrypted = EncryptionUtils.decryptWithAES(encrypted, key);
      
      // Verify decryption worked correctly
      expect(decrypted, equals(plainText));
    });

    test('Encryption with different keys should produce different results', () {
      final key1 = EncryptionUtils.generateEncryptionKey();
      final key2 = EncryptionUtils.generateEncryptionKey();
      const plainText = 'Test message';

      final encrypted1 = EncryptionUtils.encryptWithAES(plainText, key1);
      final encrypted2 = EncryptionUtils.encryptWithAES(plainText, key2);

      // Different keys should produce different encrypted results
      expect(encrypted1, isNot(equals(encrypted2)));

      // Each should decrypt correctly with their respective keys
      expect(EncryptionUtils.decryptWithAES(encrypted1, key1), equals(plainText));
      expect(EncryptionUtils.decryptWithAES(encrypted2, key2), equals(plainText));
    });

    test('Decryption with wrong key should fail', () {
      final key1 = EncryptionUtils.generateEncryptionKey();
      final key2 = EncryptionUtils.generateEncryptionKey();
      const plainText = 'Secret message';

      final encrypted = EncryptionUtils.encryptWithAES(plainText, key1);

      // Attempting to decrypt with wrong key should throw an exception
      expect(() => EncryptionUtils.decryptWithAES(encrypted, key2), throwsException);
    });

    test('Key validation should work correctly', () {
      final validKey = EncryptionUtils.generateEncryptionKey();
      const invalidKey = 'this_is_not_a_valid_key';

      expect(EncryptionUtils.isValidEncryptionKey(validKey), isTrue);
      expect(EncryptionUtils.isValidEncryptionKey(invalidKey), isFalse);
    });

    test('Encrypted data validation should work correctly', () {
      final key = EncryptionUtils.generateEncryptionKey();
      const plainText = 'Test message';
      final encrypted = EncryptionUtils.encryptWithAES(plainText, key);

      expect(EncryptionUtils.isValidEncryptedData(encrypted), isTrue);
      expect(EncryptionUtils.isValidEncryptedData('invalid_data'), isFalse);
    });

    test('EncryptionKeyManager should work correctly', () {
      final keyManager = EncryptionKeyManager();
      const conversationId = 'test_conversation_123';

      // Initially, no encryption should be enabled
      expect(keyManager.requiresEncryption(conversationId), isFalse);
      expect(keyManager.hasConversationKey(conversationId), isFalse);

      // Enable encryption
      final key = keyManager.enableEncryption(conversationId);
      
      expect(keyManager.requiresEncryption(conversationId), isTrue);
      expect(keyManager.hasConversationKey(conversationId), isTrue);
      expect(keyManager.getConversationKey(conversationId), equals(key));

      // Disable encryption
      keyManager.disableEncryption(conversationId);
      
      expect(keyManager.requiresEncryption(conversationId), isFalse);
      expect(keyManager.hasConversationKey(conversationId), isFalse);
    });

    test('Unicode and special characters should be encrypted correctly', () {
      final key = EncryptionUtils.generateEncryptionKey();
      const plainText = 'Hello 🌍! Special chars: àáâãäå æç èéêë 中文 العربية';

      final encrypted = EncryptionUtils.encryptWithAES(plainText, key);
      final decrypted = EncryptionUtils.decryptWithAES(encrypted, key);

      expect(decrypted, equals(plainText));
    });

    test('Empty and long messages should be handled correctly', () {
      final key = EncryptionUtils.generateEncryptionKey();
      
      // Test empty message
      const emptyMessage = '';
      final encryptedEmpty = EncryptionUtils.encryptWithAES(emptyMessage, key);
      final decryptedEmpty = EncryptionUtils.decryptWithAES(encryptedEmpty, key);
      expect(decryptedEmpty, equals(emptyMessage));

      // Test long message
      final longMessage = 'A' * 10000; // 10KB message
      final encryptedLong = EncryptionUtils.encryptWithAES(longMessage, key);
      final decryptedLong = EncryptionUtils.decryptWithAES(encryptedLong, key);
      expect(decryptedLong, equals(longMessage));
    });

    test('Key derivation from password should work', () {
      const password = 'mySecurePassword123!';
      
      final result1 = EncryptionUtils.deriveKeyFromPassword(password);
      final result2 = EncryptionUtils.deriveKeyFromPassword(password, salt: result1['salt']);
      
      // Same password and salt should produce same key
      expect(result1['key'], equals(result2['key']));
      
      // Different salt should produce different key
      final result3 = EncryptionUtils.deriveKeyFromPassword(password);
      expect(result1['key'], isNot(equals(result3['key'])));
    });
  });
}