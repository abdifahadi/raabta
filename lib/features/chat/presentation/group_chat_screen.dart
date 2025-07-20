import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raabta/features/auth/domain/models/user_profile_model.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/chat/domain/models/group_model.dart';
import 'package:raabta/features/chat/domain/models/message_model.dart';
import 'package:raabta/features/chat/domain/group_chat_repository.dart';
import 'package:raabta/core/services/service_locator.dart';
import '../../../core/services/media_picker_service.dart';
import 'widgets/message_bubble.dart';
import 'widgets/media_picker_bottom_sheet.dart';
import 'group_info_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;

  const GroupChatScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final GroupChatRepository _groupChatRepository = ServiceLocator().groupChatRepository;
  final UserProfileRepository _userProfileRepository = ServiceLocator().userProfileRepository;
  final AuthRepository _authRepository = FirebaseAuthRepository();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isSendingMedia = false;
  String? _currentUserId;
  MessageModel? _replyingTo;
  Map<String, UserProfileModel> _memberProfiles = {};
  GroupModel? _currentGroup;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authRepository.currentUser?.uid;
    _currentGroup = widget.group;
    _loadMemberProfiles();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMemberProfiles() async {
    try {
      final profiles = <String, UserProfileModel>{};
      for (final memberId in widget.group.members) {
        final profile = await _userProfileRepository.getUserProfile(memberId);
        if (profile != null) {
          profiles[memberId] = profile;
        }
      }
      setState(() {
        _memberProfiles = profiles;
      });
    } catch (e) {
      // Silently handle error
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId != null) {
      try {
        await _groupChatRepository.markGroupMessagesAsRead(
          widget.group.id,
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
    final replyingToMessage = _replyingTo;
    
    setState(() {
      _isLoading = true;
      _replyingTo = null; // Clear reply after sending
    });

    try {
      await _groupChatRepository.sendGroupMessage(
        groupId: widget.group.id,
        senderId: _currentUserId!,
        content: messageText,
        messageType: MessageType.text,
        replyToMessageId: replyingToMessage?.id,
      );

      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMediaMessage(PickedMediaFile mediaFile) async {
    if (_currentUserId == null) return;

    setState(() {
      _isSendingMedia = true;
    });

    try {
      await _groupChatRepository.sendGroupMediaMessage(
        groupId: widget.group.id,
        senderId: _currentUserId!,
        mediaFile: mediaFile,
        replyToMessageId: _replyingTo?.id,
      );

      setState(() {
        _replyingTo = null; // Clear reply after sending
      });

      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send media: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSendingMedia = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => MediaPickerBottomSheet(
        onMediaSelected: _sendMediaMessage,
      ),
    );
  }

  void _replyToMessage(MessageModel message) {
    setState(() {
      _replyingTo = message;
    });
    _textFocusNode.requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  String _getSenderName(String senderId) {
    if (senderId == _currentUserId) return 'You';
    final profile = _memberProfiles[senderId];
    return profile?.displayName ?? 'Unknown User';
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_getSenderName(_replyingTo!.senderId)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyingTo!.previewText,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearReply,
            icon: const Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMessageBubble(MessageModel message) {
    final isMe = message.senderId == _currentUserId;
    final senderName = _getSenderName(message.senderId);
    final senderProfile = _memberProfiles[message.senderId];

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Show sender info for others' messages
        if (!isMe) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: senderProfile?.photoUrl != null
                      ? NetworkImage(senderProfile!.photoUrl!)
                      : null,
                  child: senderProfile?.photoUrl == null
                      ? Text(
                          senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  senderName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Message bubble
        MessageBubble(
          message: message,
          isMe: isMe,
          onReply: () => _replyToMessage(message),
          onLongPress: () {
            HapticFeedback.lightImpact();
            // TODO: Show message options menu
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupInfoScreen(group: _currentGroup ?? widget.group),
              ),
            ).then((updatedGroup) {
              if (updatedGroup is GroupModel) {
                setState(() {
                  _currentGroup = updatedGroup;
                });
                _loadMemberProfiles(); // Reload member profiles if group changed
              }
            });
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.group.photoUrl != null
                    ? NetworkImage(widget.group.photoUrl!)
                    : null,
                child: widget.group.photoUrl == null
                    ? Icon(
                        Icons.group,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.group.members.length} members',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupInfoScreen(group: _currentGroup ?? widget.group),
                ),
              ).then((updatedGroup) {
                if (updatedGroup is GroupModel) {
                  setState(() {
                    _currentGroup = updatedGroup;
                  });
                  _loadMemberProfiles();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _groupChatRepository.getGroupMessages(widget.group.id),
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
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Trigger rebuild to retry
                          },
                          child: const Text('Retry'),
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
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildGroupMessageBubble(message);
                  },
                );
              },
            ),
          ),
          
          // Reply preview
          _buildReplyPreview(),
          
          // Sending media indicator
          if (_isSendingMedia)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sending media...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Media picker button
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _isSendingMedia ? null : _showMediaPicker,
                  ),
                  
                  // Message input field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _textFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send button
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _messageController,
                    builder: (context, value, child) {
                      final hasText = value.text.trim().isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: hasText
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          onPressed: hasText && !_isLoading && !_isSendingMedia
                              ? _sendMessage
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}