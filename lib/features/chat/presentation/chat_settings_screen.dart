import 'package:flutter/material.dart';
import '../domain/models/conversation_model.dart';
import '../domain/chat_repository.dart';
import '../../auth/domain/models/user_profile_model.dart';
import '../../../core/services/service_locator.dart';

class ChatSettingsScreen extends StatefulWidget {
  final ConversationModel conversation;
  final UserProfileModel otherUser;
  final String currentUserId;

  const ChatSettingsScreen({
    super.key,
    required this.conversation,
    required this.otherUser,
    required this.currentUserId,
  });

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final ChatRepository _chatRepository = ServiceLocator().chatRepository;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isMuted = widget.conversation.isMutedBy(widget.currentUserId);
    final isBlocked = widget.conversation.isBlockedBy(widget.currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info section
            _buildUserInfoSection(),
            
            const SizedBox(height: 24),
            
            // Chat settings section
            _buildSectionHeader('Chat Settings'),
            const SizedBox(height: 16),
            
            _buildSettingsTile(
              icon: isMuted ? Icons.notifications_off : Icons.notifications,
              title: isMuted ? 'Unmute Conversation' : 'Mute Conversation',
              subtitle: isMuted 
                  ? 'You will receive notifications for new messages'
                  : 'You won\'t receive notifications for new messages',
              onTap: () => _toggleMute(isMuted),
              iconColor: isMuted ? Colors.orange : Colors.blue,
            ),
            
            const Divider(),
            
            _buildSettingsTile(
              icon: isBlocked ? Icons.block : Icons.block,
              title: isBlocked ? 'Unblock User' : 'Block User',
              subtitle: isBlocked 
                  ? 'You will be able to receive messages from this user'
                  : 'You won\'t receive messages from this user',
              onTap: () => _toggleBlock(isBlocked),
              iconColor: Colors.red,
            ),
            
            const Divider(),
            
            _buildEncryptionTile(),
            
            const Divider(),
            
            _buildSettingsTile(
              icon: Icons.clear_all,
              title: 'Clear Chat History',
              subtitle: 'Delete all messages from this conversation for you',
              onTap: _showClearChatDialog,
              iconColor: Colors.orange,
            ),
            
            const SizedBox(height: 24),
            
            // Conversation info section
            _buildSectionHeader('Conversation Info'),
            const SizedBox(height: 16),
            
            _buildInfoTile(
              icon: Icons.people,
              title: 'Participants',
              value: '${widget.conversation.participants.length}',
            ),
            
            const Divider(),
            
            _buildInfoTile(
              icon: Icons.schedule,
              title: 'Created',
              value: _formatDate(widget.conversation.createdAt),
            ),
            
            const Divider(),
            
            _buildInfoTile(
              icon: Icons.update,
              title: 'Last Updated',
              value: _formatDate(widget.conversation.updatedAt),
            ),
            
            const SizedBox(height: 24),
            
            // Danger zone
            _buildSectionHeader('Danger Zone'),
            const SizedBox(height: 16),
            
            _buildSettingsTile(
              icon: Icons.delete_forever,
              title: 'Delete Conversation',
              subtitle: 'Permanently delete this conversation for all participants',
              onTap: _showDeleteConversationDialog,
              iconColor: Colors.red,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple.withOpacity(0.1),
            backgroundImage: widget.otherUser.photoUrl != null
                ? NetworkImage(widget.otherUser.photoUrl!)
                : null,
            child: widget.otherUser.photoUrl == null
                ? Text(
                    widget.otherUser.name.isNotEmpty
                        ? widget.otherUser.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.otherUser.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active: ${widget.otherUser.activeHours}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      onTap: _isLoading ? null : onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey[600],
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEncryptionTile() {
    final isEncrypted = _chatRepository.isEncryptionEnabled(widget.conversation.id);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isEncrypted ? Colors.green : Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isEncrypted ? Icons.lock : Icons.lock_open,
          color: isEncrypted ? Colors.green : Colors.grey,
          size: 24,
        ),
      ),
      title: Text(
        isEncrypted ? 'End-to-End Encryption Enabled' : 'Enable End-to-End Encryption',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        isEncrypted 
            ? 'Your messages are secured with end-to-end encryption'
            : 'Secure your messages with end-to-end encryption',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: isEncrypted,
        onChanged: _isLoading ? null : _toggleEncryption,
        activeColor: Colors.green,
      ),
      onTap: _isLoading ? null : () => _toggleEncryption(!isEncrypted),
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _toggleMute(bool currentlyMuted) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (currentlyMuted) {
        await _chatRepository.unmuteConversation(
          widget.conversation.id,
          widget.currentUserId,
        );
        _showSnackBar('Conversation unmuted', Colors.green);
      } else {
        await _chatRepository.muteConversation(
          widget.conversation.id,
          widget.currentUserId,
        );
        _showSnackBar('Conversation muted', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Failed to update mute settings: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBlock(bool currentlyBlocked) async {
    final confirm = await _showConfirmDialog(
      title: currentlyBlocked ? 'Unblock User' : 'Block User',
      message: currentlyBlocked
          ? 'Are you sure you want to unblock ${widget.otherUser.name}? You will be able to receive messages from them.'
          : 'Are you sure you want to block ${widget.otherUser.name}? You won\'t receive messages from them.',
      confirmText: currentlyBlocked ? 'Unblock' : 'Block',
    );

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (currentlyBlocked) {
        await _chatRepository.unblockConversation(
          widget.conversation.id,
          widget.currentUserId,
        );
        _showSnackBar('User unblocked', Colors.green);
      } else {
        await _chatRepository.blockConversation(
          widget.conversation.id,
          widget.currentUserId,
        );
        _showSnackBar('User blocked', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to update block settings: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleEncryption(bool enable) async {
    if (enable) {
      final confirm = await _showConfirmDialog(
        title: 'Enable End-to-End Encryption',
        message: 'This will enable end-to-end encryption for this conversation. '
                'All future messages will be encrypted. '
                'Make sure the other person also has encryption enabled to read your messages.',
        confirmText: 'Enable',
      );

      if (!confirm) return;
    } else {
      final confirm = await _showConfirmDialog(
        title: 'Disable End-to-End Encryption',
        message: 'This will disable end-to-end encryption for this conversation. '
                'Future messages will not be encrypted.',
        confirmText: 'Disable',
      );

      if (!confirm) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (enable) {
        final encryptionKey = await _chatRepository.enableEncryption(widget.conversation.id);
        _showSnackBar('End-to-end encryption enabled', Colors.green);
        
        // Show the encryption key to the user (in a real app, this would be handled more securely)
        if (mounted) {
          _showEncryptionKeyDialog(encryptionKey);
        }
      } else {
        await _chatRepository.disableEncryption(widget.conversation.id);
        _showSnackBar('End-to-end encryption disabled', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Failed to update encryption settings: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showClearChatDialog() async {
    final confirm = await _showConfirmDialog(
      title: 'Clear Chat History',
      message: 'Are you sure you want to clear all messages in this conversation? This action cannot be undone.',
      confirmText: 'Clear',
    );

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _chatRepository.clearChatForUser(
        widget.conversation.id,
        widget.currentUserId,
      );
      _showSnackBar('Chat history cleared', Colors.green);
      if (mounted) {
        Navigator.of(context).pop(); // Go back to chat screen
      }
    } catch (e) {
      _showSnackBar('Failed to clear chat history: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDeleteConversationDialog() async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Conversation',
      message: 'Are you sure you want to permanently delete this conversation? This will delete all messages for all participants and cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _chatRepository.deleteConversation(widget.conversation.id);
      _showSnackBar('Conversation deleted', Colors.green);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst); // Go back to conversations list
      }
    } catch (e) {
      _showSnackBar('Failed to delete conversation: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _showEncryptionKeyDialog(String encryptionKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.green),
              SizedBox(width: 8),
              Text('Encryption Key Generated'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A unique encryption key has been generated for this conversation. '
                'In a production app, this would be securely shared with the other participant.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Encryption Key:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  encryptionKey,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Note: This is a demo implementation. In production, keys would be exchanged securely using proper key exchange protocols.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}