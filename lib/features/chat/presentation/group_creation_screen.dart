import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:raabta/features/auth/domain/models/user_profile_model.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/chat/domain/models/group_model.dart';
import 'package:raabta/features/chat/domain/group_chat_repository.dart';
import 'package:raabta/core/services/service_locator.dart';
import 'package:raabta/core/services/media_picker_service.dart';
import 'package:raabta/core/services/storage_repository.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final GroupChatRepository _groupChatRepository = ServiceLocator().groupChatRepository;
  final UserProfileRepository _userProfileRepository = ServiceLocator().userProfileRepository;
  final AuthRepository _authRepository = FirebaseAuthRepository();
  final MediaPickerService _mediaPickerService = ServiceLocator().mediaPickerService;
  final StorageRepository _storageRepository = ServiceLocator().storageRepository;
  
  final TextEditingController _groupNameController = TextEditingController();
  final FocusNode _groupNameFocusNode = FocusNode();
  
  List<UserProfileModel> _availableUsers = [];
  final List<UserProfileModel> _selectedMembers = [];
  bool _isLoading = false;
  bool _isCreatingGroup = false;
  PickedMediaFile? _selectedGroupPhoto;
  Uint8List? _groupPhotoBytes;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authRepository.currentUser?.uid;
    _loadAvailableUsers();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableUsers() async {
    if (_currentUserId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userProfileRepository.getAllUsers();
      setState(() {
        _availableUsers = users.where((user) => user.uid != _currentUserId).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickGroupPhoto() async {
    try {
      final mediaFile = await _mediaPickerService.pickSingleMedia(
        source: MediaSource.gallery,
        type: MediaType.image,
      );

      if (mediaFile != null) {
        setState(() {
          _selectedGroupPhoto = mediaFile;
          _groupPhotoBytes = mediaFile.bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleMemberSelection(UserProfileModel user) {
    setState(() {
      if (_selectedMembers.contains(user)) {
        _selectedMembers.remove(user);
      } else {
        _selectedMembers.add(user);
      }
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    if (_currentUserId == null) return;

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      String? photoUrl;
      
      // Upload group photo if selected
      if (_selectedGroupPhoto != null && _groupPhotoBytes != null) {
        final photoPath = 'groups/${DateTime.now().millisecondsSinceEpoch}_group_photo.jpg';
        photoUrl = await _storageRepository.uploadBytes(
          path: photoPath,
          bytes: _groupPhotoBytes!,
          fileName: 'group_photo.jpg',
          mimeType: 'image/jpeg',
        );
      }

      // Create group model
      final group = GroupModel.create(
        name: groupName,
        creatorId: _currentUserId!,
        photoUrl: photoUrl,
        members: _selectedMembers.map((user) => user.uid).toList(),
      );

      // Create group in repository
      await _groupChatRepository.createGroup(group);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
        Navigator.pop(context, group);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isCreatingGroup = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          if (_isCreatingGroup)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              child: const Text(
                'Create',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Group Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Group Photo
                      GestureDetector(
                        onTap: _pickGroupPhoto,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: _groupPhotoBytes != null
                              ? ClipOval(
                                  child: Image.memory(
                                    _groupPhotoBytes!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add group photo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Group Name Input
                      TextField(
                        controller: _groupNameController,
                        focusNode: _groupNameFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Group Name',
                          hintText: 'Enter group name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.group),
                        ),
                        maxLength: 50,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
                // Selected Members Section
                if (_selectedMembers.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Members (${_selectedMembers.length})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedMembers.length,
                            itemBuilder: (context, index) {
                              final member = _selectedMembers[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _toggleMemberSelection(member),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: member.photoUrl != null
                                                ? NetworkImage(member.photoUrl!)
                                                : null,
                                            child: member.photoUrl == null
                                                ? Text(
                                                    member.displayName.isNotEmpty
                                                        ? member.displayName[0].toUpperCase()
                                                        : 'U',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.error,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        member.displayName.length > 8
                                            ? '${member.displayName.substring(0, 8)}...'
                                            : member.displayName,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Available Users Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Select Members',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _availableUsers.length,
                          itemBuilder: (context, index) {
                            final user = _availableUsers[index];
                            final isSelected = _selectedMembers.contains(user);
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? Text(
                                        user.displayName.isNotEmpty
                                            ? user.displayName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                user.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(user.email),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleMemberSelection(user),
                              ),
                              onTap: () => _toggleMemberSelection(user),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}