# Raabta - Cross-platform Chat App

## Overview
Raabta is a professional cross-platform messaging application built with Flutter. It supports Android, iOS, Web, and Desktop platforms with a comprehensive media messaging system.

## Features Implemented

### ✅ Media Messaging System
- **Multi-format Support**: Images, Videos, Audio files, Documents (PDF, Word, Excel, etc.)
- **Cross-platform File Picking**: Works seamlessly across all platforms
- **Cloud Storage**: Files are stored securely on Firebase Storage
- **Media Previews**: In-app viewers for different media types

### ✅ Message Types
- **Text Messages**: Rich text messaging with emoji support
- **Image Messages**: High-quality image sharing with compression
- **Video Messages**: Video sharing with thumbnail previews
- **Audio Messages**: Audio file sharing with playback controls
- **Document Messages**: File sharing with type recognition and previews

### ✅ Media Viewers
- **Image Viewer**: Full-screen zoomable image viewing with hero animations
- **Video Player**: In-app video playback with custom controls
- **Audio Player**: Minimal audio player with play/pause and progress controls
- **Document Viewer**: File preview with download and share options

### ✅ Chat Features
- **Real-time Messaging**: Instant message delivery using Firestore
- **Message Status**: Sent, Delivered, Read status indicators
- **Message Management**: Long-press options for delete, reply, forward, copy
- **Date Separators**: Messages grouped by date for better readability

### ✅ Conversation Management
- **Mute/Unmute**: Control notifications per conversation
- **Block/Unblock**: Block users and manage blocked conversations
- **Clear Chat**: Remove chat history for individual users
- **Delete Conversation**: Permanently delete conversations

### ✅ UI/UX Features
- **Modern Design**: Clean, intuitive interface following Material Design
- **Responsive Layout**: Optimized for different screen sizes
- **Dark/Light Mode Ready**: Prepared for theme switching
- **Smooth Animations**: Hero animations and smooth transitions
- **Error Handling**: Comprehensive error handling with user feedback

## Technical Architecture

### Clean Architecture
```
lib/
├── core/
│   └── services/
│       ├── auth_service.dart
│       ├── storage_repository.dart
│       ├── firebase_storage_repository.dart
│       ├── media_picker_service.dart
│       └── service_locator.dart
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   └── presentation/
│   └── chat/
│       ├── domain/
│       │   ├── models/
│       │   │   ├── message_model.dart
│       │   │   └── conversation_model.dart
│       │   ├── chat_repository.dart
│       │   └── firebase_chat_repository.dart
│       └── presentation/
│           ├── widgets/
│           │   ├── media_viewer/
│           │   │   ├── image_viewer.dart
│           │   │   ├── video_player_widget.dart
│           │   │   ├── audio_player_widget.dart
│           │   │   └── document_viewer.dart
│           │   ├── message_bubble.dart
│           │   └── media_picker_bottom_sheet.dart
│           ├── chat_screen.dart
│           ├── chat_settings_screen.dart
│           └── conversations_screen.dart
```

### Key Components

#### 1. Message Model
- Supports multiple message types (text, image, video, audio, file)
- Includes metadata for media files (URL, file size, duration, etc.)
- Message status tracking (sending, sent, delivered, read, failed)
- Reply and reaction support structure

#### 2. Firebase Chat Repository
- **sendMessage()**: Text message sending
- **sendMediaMessage()**: Media file upload and messaging
- **updateMessageStatus()**: Message status updates
- **muteConversation()/unmuteConversation()**: Notification control
- **blockConversation()/unblockConversation()**: User blocking
- **clearChatForUser()**: Individual chat history clearing

#### 3. Media Picker Service
- Cross-platform file selection
- Support for images, videos, audio, and documents
- File size validation and type detection
- Web and mobile platform compatibility

#### 4. Storage Repository
- Firebase Storage integration
- Secure file upload with progress tracking
- Automatic file path generation
- File metadata management

## Media Support

### Supported File Types

#### Images
- JPEG, PNG, GIF, WebP, BMP
- Automatic compression for optimal storage
- Full-screen viewing with zoom

#### Videos
- MP4, AVI, MOV, MKV, WebM
- Thumbnail generation
- In-app playback controls

#### Audio
- MP3, WAV, AAC, M4A, OGG
- Playback controls with progress tracking
- Duration display

#### Documents
- PDF, Word documents, Excel spreadsheets
- PowerPoint presentations, Text files
- File type recognition and appropriate icons

## Cross-Platform Features

### Web Support
- File picker using browser APIs
- Responsive design for web interfaces
- Keyboard shortcuts support

### Desktop Support
- Native file dialogs
- Window management
- Platform-specific UI adaptations

### Mobile Support
- Camera integration for image/video capture
- Native file system access
- Touch-optimized interface

## Security Features

### File Upload Security
- File type validation
- File size limits per media type
- Secure Firebase Storage rules
- Encrypted file transfer

### User Privacy
- Individual message deletion
- Conversation blocking
- Mute functionality
- Clear chat history

## Performance Optimizations

### Media Handling
- Image compression and resizing
- Lazy loading for media content
- Cached network images
- Progressive file upload

### Real-time Updates
- Efficient Firestore queries
- Stream-based message updates
- Optimistic UI updates
- Connection state management

## Future Enhancements

### Planned Features
- [ ] Voice message recording
- [ ] Message encryption
- [ ] Group chat support
- [ ] Message search functionality
- [ ] File sharing with expiry
- [ ] Message reactions
- [ ] Typing indicators
- [ ] Online status
- [ ] Push notifications
- [ ] Message drafts

### Technical Improvements
- [ ] Offline message support
- [ ] Advanced caching strategies
- [ ] Performance monitoring
- [ ] Analytics integration
- [ ] Automated testing suite

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase project setup
- Platform-specific configurations

### Installation
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Firebase (follow Firebase setup guide)
4. Run the app: `flutter run`

### Firebase Configuration
1. Create a Firebase project
2. Enable Authentication, Firestore, and Storage
3. Download configuration files
4. Update Firestore security rules
5. Configure Storage rules

## Dependencies

### Core Dependencies
- `firebase_core`: Firebase initialization
- `firebase_auth`: User authentication
- `cloud_firestore`: Real-time database
- `firebase_storage`: File storage

### Media Dependencies
- `file_picker`: Cross-platform file selection
- `image_picker`: Image and video capture
- `video_player`: Video playback
- `cached_network_image`: Image caching
- `photo_view`: Image viewing

### UI Dependencies
- `flutter_chat_bubble`: Chat bubble styling
- `animations`: Smooth animations
- `intl`: Internationalization

## Contributing
Contributions are welcome! Please read the contributing guidelines and submit pull requests for any improvements.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
