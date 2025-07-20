import '../utils/encryption_utils.dart';

/// Manages encryption keys for conversations
/// Currently uses in-memory storage, but can be extended to use secure storage
class EncryptionKeyManager {
  static final EncryptionKeyManager _instance = EncryptionKeyManager._internal();
  factory EncryptionKeyManager() => _instance;
  EncryptionKeyManager._internal();

  // In-memory storage of encryption keys by conversation ID
  final Map<String, String> _conversationKeys = {};

  /// Get encryption key for a conversation
  /// Returns null if no key exists for the conversation
  String? getConversationKey(String conversationId) {
    return _conversationKeys[conversationId];
  }

  /// Set encryption key for a conversation
  void setConversationKey(String conversationId, String key) {
    if (!EncryptionUtils.isValidEncryptionKey(key)) {
      throw ArgumentError('Invalid encryption key provided');
    }
    _conversationKeys[conversationId] = key;
  }

  /// Generate and set a new encryption key for a conversation
  /// Returns the generated key
  String generateAndSetConversationKey(String conversationId) {
    final key = EncryptionUtils.generateEncryptionKey();
    _conversationKeys[conversationId] = key;
    return key;
  }

  /// Check if a conversation has an encryption key
  bool hasConversationKey(String conversationId) {
    return _conversationKeys.containsKey(conversationId);
  }

  /// Remove encryption key for a conversation
  void removeConversationKey(String conversationId) {
    _conversationKeys.remove(conversationId);
  }

  /// Check if a conversation requires encryption
  /// For now, this is based on whether a key exists
  /// In the future, this could be based on conversation settings
  bool requiresEncryption(String conversationId) {
    return hasConversationKey(conversationId);
  }

  /// Enable encryption for a conversation
  /// Generates a new key if one doesn't exist
  String enableEncryption(String conversationId) {
    if (hasConversationKey(conversationId)) {
      return _conversationKeys[conversationId]!;
    }
    return generateAndSetConversationKey(conversationId);
  }

  /// Disable encryption for a conversation
  void disableEncryption(String conversationId) {
    removeConversationKey(conversationId);
  }

  /// Get all conversations that have encryption enabled
  List<String> getEncryptedConversations() {
    return _conversationKeys.keys.toList();
  }

  /// Clear all encryption keys (useful for logout)
  void clearAllKeys() {
    _conversationKeys.clear();
  }

  /// Export encryption keys (for backup purposes)
  /// WARNING: This should only be used with proper security measures
  Map<String, String> exportKeys() {
    return Map<String, String>.from(_conversationKeys);
  }

  /// Import encryption keys (for restore purposes)
  /// WARNING: This should only be used with proper security measures
  void importKeys(Map<String, String> keys) {
    for (final entry in keys.entries) {
      if (EncryptionUtils.isValidEncryptionKey(entry.value)) {
        _conversationKeys[entry.key] = entry.value;
      }
    }
  }

  /// Get statistics about encryption usage
  Map<String, dynamic> getEncryptionStats() {
    return {
      'totalEncryptedConversations': _conversationKeys.length,
      'conversationIds': _conversationKeys.keys.toList(),
    };
  }
}