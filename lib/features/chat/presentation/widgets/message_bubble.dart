import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../domain/models/message_model.dart';
import 'media_viewer/image_viewer.dart';
import 'media_viewer/video_player_widget.dart';
import 'media_viewer/audio_player_widget.dart';
import 'media_viewer/document_viewer.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? otherUserName;
  final String? otherUserPhotoUrl;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.onLongPress,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: _getPadding(),
                decoration: BoxDecoration(
                  color: isMe ? Colors.deepPurple : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMessageContent(context),
                    if (message.content.isNotEmpty && message.messageType != MessageType.text)
                      const SizedBox(height: 8),
                    if (message.content.isNotEmpty && message.messageType != MessageType.text)
                      _buildCaption(),
                    const SizedBox(height: 4),
                    _buildTimestamp(),
                  ],
                ),
              ),
            ),
          ),
          
          if (isMe) const SizedBox(width: 44), // Space for avatar on other side
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.deepPurple.withOpacity(0.1),
      backgroundImage: otherUserPhotoUrl != null
          ? NetworkImage(otherUserPhotoUrl!)
          : null,
      child: otherUserPhotoUrl == null
          ? Text(
              otherUserName?.isNotEmpty == true
                  ? otherUserName![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          : null,
    );
  }

  EdgeInsets _getPadding() {
    switch (message.messageType) {
      case MessageType.text:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case MessageType.image:
      case MessageType.video:
        return const EdgeInsets.all(4);
      case MessageType.audio:
      case MessageType.file:
        return const EdgeInsets.all(12);
    }
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.messageType) {
      case MessageType.text:
        return _buildTextContent();
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.video:
        return _buildVideoContent(context);
      case MessageType.audio:
        return _buildAudioContent();
      case MessageType.file:
        return _buildFileContent();
    }
  }

  Widget _buildTextContent() {
    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (message.mediaUrl == null) {
      return _buildErrorContent('Image not available');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => _openImageViewer(context),
        child: Hero(
          tag: 'image_${message.id}',
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                size: 48,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    if (message.mediaUrl == null) {
      return _buildErrorContent('Video not available');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => _openVideoViewer(context),
        child: Container(
          width: 200,
          height: 200,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail (if available)
              if (message.thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: message.thumbnailUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              
              // Play button overlay
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioContent() {
    if (message.mediaUrl == null) {
      return _buildErrorContent('Audio not available');
    }

    return AudioPlayerWidget(
      audioUrl: message.mediaUrl!,
      fileName: message.fileName,
      duration: message.duration,
    );
  }

  Widget _buildFileContent() {
    if (message.mediaUrl == null) {
      return _buildErrorContent('File not available');
    }

    return DocumentViewer(
      documentUrl: message.mediaUrl!,
      fileName: message.fileName ?? 'Document',
      mimeType: message.mimeType,
      fileSize: message.fileSize,
    );
  }

  Widget _buildErrorContent(String errorText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    if (message.content.isEmpty) return const SizedBox.shrink();
    
    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTimestamp() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(message.timestamp),
          style: TextStyle(
            color: isMe ? Colors.white70 : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            _getStatusIcon(),
            size: 16,
            color: isMe ? Colors.white70 : Colors.grey[600],
          ),
        ],
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  void _openImageViewer(BuildContext context) {
    ImageViewer.show(
      context,
      imageUrl: message.mediaUrl!,
      heroTag: 'image_${message.id}',
      fileName: message.fileName,
    );
  }

  void _openVideoViewer(BuildContext context) {
    VideoPlayerWidget.showFullscreen(
      context,
      videoUrl: message.mediaUrl!,
      fileName: message.fileName,
    );
  }
}