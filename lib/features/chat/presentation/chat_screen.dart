import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raabta/features/auth/domain/models/user_profile_model.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/chat/domain/models/conversation_model.dart';
import 'package:raabta/features/chat/domain/models/message_model.dart';
import 'package:raabta/features/chat/domain/chat_repository.dart';
import 'package:raabta/core/services/service_locator.dart';
import '../../../core/services/media_picker_service.dart';
import 'widgets/message_bubble.dart';
import 'widgets/media_picker_bottom_sheet.dart';
import 'chat_settings_screen.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  final UserProfileModel otherUser;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepository _chatRepository = ServiceLocator().chatRepository;
  final AuthRepository _authRepository = FirebaseAuthRepository();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _isSendingMedia = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authRepository.currentUser?.uid;
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId != null) {
      try {
        await _chatRepository.markMessagesAsRead(
          widget.conversation.id,
          _currentUserId!,
        );
      } catch (e) {
        // Silently handle error
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _currentUserId == null) return;

    // Clear input immediately for better UX
    _messageController.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      await _chatRepository.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _currentUserId!,
        receiverId: widget.otherUser.uid,
        content: messageText,
        messageType: MessageType.text,
      );

      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        // Restore message text if sending failed
        _messageController.text = messageText;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMediaMessage(PickedMediaFile mediaFile) async {
    if (_currentUserId == null) return;

    setState(() {
      _isSendingMedia = true;
    });

    try {
      await _chatRepository.sendMediaMessage(
        conversationId: widget.conversation.id,
        senderId: _currentUserId!,
        receiverId: widget.otherUser.uid,
        mediaFile: mediaFile,
      );

      // Scroll to bottom after sending
      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${mediaFile.type.name.toUpperCase()} sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send media: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMedia = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMediaPicker() {
    MediaPickerBottomSheet.show(
      context,
      onMediaSelected: _sendMediaMessage,
    );
  }

  void _openChatSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatSettingsScreen(
          conversation: widget.conversation,
          otherUser: widget.otherUser,
          currentUserId: _currentUserId!,
        ),
      ),
    );
  }

  void _onMessageLongPress(MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMessageOptionsSheet(message),
    );
  }

  Widget _buildMessageOptionsSheet(MessageModel message) {
    final isMyMessage = message.isSentBy(_currentUserId ?? '');

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Message Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          if (isMyMessage) ...[
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement edit functionality
                _showEditDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(context).pop();
                _deleteMessage(message);
              },
            ),
          ],
          
          ListTile(
            leading: const Icon(Icons.reply, color: Colors.green),
            title: const Text('Reply'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement reply functionality
              _replyToMessage(message);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.forward, color: Colors.orange),
            title: const Text('Forward'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement forward functionality
              _forwardMessage(message);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.copy, color: Colors.grey),
            title: const Text('Copy'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement copy functionality
              _copyMessage(message);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
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
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Active: ${widget.otherUser.activeHours}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _openChatSettings,
            icon: const Icon(Icons.more_vert),
            tooltip: 'Chat Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Loading indicator for media upload
          if (_isSendingMedia)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sending media...',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          
          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatRepository.getConversationMessages(widget.conversation.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load messages',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show latest messages at bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.isSentBy(_currentUserId ?? '');
                    final showDateSeparator = _shouldShowDateSeparator(messages, index);
                    
                    return Column(
                      children: [
                        if (showDateSeparator) _buildDateSeparator(message.timestamp),
                        MessageBubble(
                          message: message,
                          isMe: isMe,
                          otherUserName: widget.otherUser.name,
                          otherUserPhotoUrl: widget.otherUser.photoUrl,
                          onLongPress: () => _onMessageLongPress(message),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];
    
    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    
    final nextDate = DateTime(
      nextMessage.timestamp.year,
      nextMessage.timestamp.month,
      nextMessage.timestamp.day,
    );
    
    return !currentDate.isAtSameMomentAs(nextDate);
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate.isAtSameMomentAs(today)) {
      dateText = 'Today';
    } else if (messageDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Media picker button
          IconButton(
            onPressed: _isSendingMedia ? null : _showMediaPicker,
            icon: Icon(
              Icons.add,
              color: _isSendingMedia ? Colors.grey : Colors.deepPurple,
            ),
            tooltip: 'Attach media',
          ),
          
          const SizedBox(width: 8),
          
          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isSendingMedia,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Send button
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: (_isLoading || _isSendingMedia) ? null : _sendMessage,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder methods for future implementation
  void _showEditDialog(MessageModel message) {
    // TODO: Implement edit message functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit message functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteMessage(MessageModel message) {
    // TODO: Implement delete message functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delete message functionality will be implemented'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _replyToMessage(MessageModel message) {
    // TODO: Implement reply to message functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reply functionality will be implemented'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _forwardMessage(MessageModel message) {
    // TODO: Implement forward message functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Forward message functionality will be implemented'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _copyMessage(MessageModel message) {
    // TODO: Implement copy message functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copy message functionality will be implemented'),
        backgroundColor: Colors.grey,
      ),
    );
  }
}