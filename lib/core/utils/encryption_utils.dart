import 'dart:convert';
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// AES-based encryption utility for end-to-end encryption
class EncryptionUtils {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  /// Encrypt plain text using AES encryption
  /// 
  /// [plainText] - The text to encrypt
  /// [key] - The encryption key (32 bytes for AES-256)
  /// Returns base64 encoded encrypted text with IV prepended
  static String encryptWithAES(String plainText, String key) {
    try {
      // Ensure key is exactly 32 bytes for AES-256
      final keyBytes = _normalizeKey(key);
      
      // Generate random IV
      final iv = _generateRandomIV();
      
      // Create encrypter
      final encrypter = Encrypter(AES(Key(keyBytes)));
      
      // Encrypt the text
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      // Combine IV and encrypted data, then encode to base64
      final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
      return base64.encode(combined);
    } catch (e) {
      throw Exception('Failed to encrypt message: $e');
    }
  }

  /// Decrypt encrypted text using AES decryption
  /// 
  /// [encryptedText] - Base64 encoded encrypted text with IV prepended
  /// [key] - The decryption key (32 bytes for AES-256)
  /// Returns the decrypted plain text
  static String decryptWithAES(String encryptedText, String key) {
    try {
      // Ensure key is exactly 32 bytes for AES-256
      final keyBytes = _normalizeKey(key);
      
      // Decode from base64
      final combined = base64.decode(encryptedText);
      
      // Extract IV and encrypted data
      if (combined.length < _ivLength) {
        throw Exception('Invalid encrypted data: too short');
      }
      
      final ivBytes = combined.sublist(0, _ivLength);
      final encryptedBytes = combined.sublist(_ivLength);
      
      // Create encrypter and IV
      final encrypter = Encrypter(AES(Key(keyBytes)));
      final iv = IV(ivBytes);
      
      // Decrypt the data
      final encrypted = Encrypted(encryptedBytes);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt message: $e');
    }
  }

  /// Generate a random encryption key
  /// Returns a base64 encoded 256-bit key
  static String generateEncryptionKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(_keyLength);
    for (int i = 0; i < _keyLength; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return base64.encode(keyBytes);
  }

  /// Generate a random IV
  static IV _generateRandomIV() {
    final random = Random.secure();
    final ivBytes = Uint8List(_ivLength);
    for (int i = 0; i < _ivLength; i++) {
      ivBytes[i] = random.nextInt(256);
    }
    return IV(ivBytes);
  }

  /// Normalize key to exactly 32 bytes for AES-256
  static Uint8List _normalizeKey(String key) {
    final keyBytes = utf8.encode(key);
    
    if (keyBytes.length == _keyLength) {
      return Uint8List.fromList(keyBytes);
    } else if (keyBytes.length > _keyLength) {
      // Truncate if too long
      return Uint8List.fromList(keyBytes.sublist(0, _keyLength));
    } else {
      // Pad with zeros if too short
      final paddedKey = Uint8List(_keyLength);
      paddedKey.setRange(0, keyBytes.length, keyBytes);
      return paddedKey;
    }
  }

  /// Derive key from password using PBKDF2
  /// 
  /// [password] - The password to derive key from
  /// [salt] - Salt for key derivation (optional, generates random if not provided)
  /// [iterations] - Number of PBKDF2 iterations (default: 10000)
  /// Returns a map with 'key' and 'salt' (both base64 encoded)
  static Map<String, String> deriveKeyFromPassword(
    String password, {
    String? salt,
    int iterations = 10000,
  }) {
    try {
      // Generate salt if not provided
      Uint8List saltBytes;
      if (salt != null) {
        saltBytes = base64.decode(salt);
      } else {
        final random = Random.secure();
        saltBytes = Uint8List(16);
        for (int i = 0; i < 16; i++) {
          saltBytes[i] = random.nextInt(256);
        }
      }

      // Derive key using PBKDF2
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac(sha256, []),
        iterations: iterations,
        bits: 256, // 32 bytes * 8 bits
      );

      final keyBytes = pbkdf2.deriveKeyFromPassword(
        password: password,
        nonce: saltBytes,
      );

      return {
        'key': base64.encode(keyBytes),
        'salt': base64.encode(saltBytes),
      };
    } catch (e) {
      throw Exception('Failed to derive key from password: $e');
    }
  }

  /// Validate if a string is a valid base64 encoded encryption key
  static bool isValidEncryptionKey(String key) {
    try {
      final decoded = base64.decode(key);
      return decoded.length == _keyLength;
    } catch (e) {
      return false;
    }
  }

  /// Validate if a string is valid encrypted data
  static bool isValidEncryptedData(String encryptedData) {
    try {
      final decoded = base64.decode(encryptedData);
      return decoded.length > _ivLength;
    } catch (e) {
      return false;
    }
  }
}

/// PBKDF2 implementation for key derivation
class Pbkdf2 {
  final Hmac macAlgorithm;
  final int iterations;
  final int bits;

  const Pbkdf2({
    required this.macAlgorithm,
    required this.iterations,
    required this.bits,
  });

  Uint8List deriveKeyFromPassword({
    required String password,
    required Uint8List nonce,
  }) {
    final passwordBytes = utf8.encode(password);
    final keyLength = (bits + 7) ~/ 8;
    final key = Uint8List(keyLength);

    final hmac = Hmac(sha256, passwordBytes);
    const macLength = 32; // SHA-256 output length
    final blockCount = (keyLength + macLength - 1) ~/ macLength;

    for (int i = 1; i <= blockCount; i++) {
      final block = _computeBlock(hmac, nonce, i);
      final blockStart = (i - 1) * macLength;
      final blockEnd = math.min(blockStart + macLength, keyLength);
      key.setRange(blockStart, blockEnd, block);
    }

    return key;
  }

  Uint8List _computeBlock(Hmac hmac, Uint8List salt, int blockIndex) {
    // Create initial input: salt + block index
    final input = Uint8List(salt.length + 4);
    input.setRange(0, salt.length, salt);
    input[salt.length] = (blockIndex >> 24) & 0xff;
    input[salt.length + 1] = (blockIndex >> 16) & 0xff;
    input[salt.length + 2] = (blockIndex >> 8) & 0xff;
    input[salt.length + 3] = blockIndex & 0xff;

    // First iteration
    var u = Uint8List.fromList(hmac.convert(input).bytes);
    var result = Uint8List.fromList(u);

    // Subsequent iterations
    for (int i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }
}