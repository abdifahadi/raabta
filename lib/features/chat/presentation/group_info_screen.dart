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

class GroupInfoScreen extends StatefulWidget {
  final GroupModel group;

  const GroupInfoScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final GroupChatRepository _groupChatRepository = ServiceLocator().groupChatRepository;
  final UserProfileRepository _userProfileRepository = ServiceLocator().userProfileRepository;
  final AuthRepository _authRepository = FirebaseAuthRepository();
  final MediaPickerService _mediaPickerService = ServiceLocator().mediaPickerService;
  final StorageRepository _storageRepository = ServiceLocator().storageRepository;
  
  final TextEditingController _groupNameController = TextEditingController();
  
  GroupModel? _currentGroup;
  Map<String, UserProfileModel> _memberProfiles = {};
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _currentUserId;
  bool _isEditing = false;
  PickedMediaFile? _newGroupPhoto;
  Uint8List? _newGroupPhotoBytes;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authRepository.currentUser?.uid;
    _currentGroup = widget.group;
    _groupNameController.text = widget.group.name;
    _loadMemberProfiles();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberProfiles() async {
    setState(() {
      _isLoading = true;
    });

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load member profiles: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickNewGroupPhoto() async {
    try {
      final mediaFile = await _mediaPickerService.pickSingleMedia(
        source: MediaSource.gallery,
        type: MediaType.image,
      );

      if (mediaFile != null) {
        setState(() {
          _newGroupPhoto = mediaFile;
          _newGroupPhotoBytes = mediaFile.bytes;
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

  Future<void> _saveGroupChanges() async {
    if (_currentGroup == null || _currentUserId == null) return;

    final newName = _groupNameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    // Check if user is admin
    if (!_currentGroup!.isAdmin(_currentUserId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can edit group info')),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      String? newPhotoUrl = _currentGroup!.photoUrl;
      
      // Upload new photo if selected
      if (_newGroupPhoto != null && _newGroupPhotoBytes != null) {
        final photoPath = 'groups/${_currentGroup!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        newPhotoUrl = await _storageRepository.uploadBytes(
          path: photoPath,
          bytes: _newGroupPhotoBytes!,
          fileName: 'group_photo.jpg',
          mimeType: 'image/jpeg',
        );
      }

      // Update group info
      final updatedGroup = _currentGroup!.updateInfo(
        name: newName,
        photoUrl: newPhotoUrl,
      );

      final savedGroup = await _groupChatRepository.updateGroup(updatedGroup);

      setState(() {
        _currentGroup = savedGroup;
        _isEditing = false;
        _newGroupPhoto = null;
        _newGroupPhotoBytes = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group info updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update group: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _removeMember(String memberId) async {
    if (_currentGroup == null || _currentUserId == null) return;

    // Check if user is admin
    if (!_currentGroup!.isAdmin(_currentUserId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can remove members')),
      );
      return;
    }

    // Confirm removal
    final memberName = _memberProfiles[memberId]?.displayName ?? 'Unknown User';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $memberName from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final updatedGroup = await _groupChatRepository.removeMember(_currentGroup!.id, memberId);
      setState(() {
        _currentGroup = updatedGroup;
        _memberProfiles.remove(memberId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$memberName removed from group')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _makeAdmin(String memberId) async {
    if (_currentGroup == null || _currentUserId == null) return;

    // Check if user is admin
    if (!_currentGroup!.isAdmin(_currentUserId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can promote members')),
      );
      return;
    }

    try {
      final updatedGroup = await _groupChatRepository.addAdmin(_currentGroup!.id, memberId);
      setState(() {
        _currentGroup = updatedGroup;
      });

      final memberName = _memberProfiles[memberId]?.displayName ?? 'Unknown User';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$memberName is now an admin')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to make admin: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeAdmin(String memberId) async {
    if (_currentGroup == null || _currentUserId == null) return;

    // Check if user is admin
    if (!_currentGroup!.isAdmin(_currentUserId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can remove admin privileges')),
      );
      return;
    }

    try {
      final updatedGroup = await _groupChatRepository.removeAdmin(_currentGroup!.id, memberId);
      setState(() {
        _currentGroup = updatedGroup;
      });

      final memberName = _memberProfiles[memberId]?.displayName ?? 'Unknown User';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$memberName is no longer an admin')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove admin: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    if (_currentGroup == null || _currentUserId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _groupChatRepository.leaveGroup(_currentGroup!.id, _currentUserId!);
      
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You left the group')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave group: ${e.toString()}')),
        );
      }
    }
  }

  void _showMemberOptions(String memberId) {
    if (_currentGroup == null || _currentUserId == null || memberId == _currentUserId) return;

    final memberName = _memberProfiles[memberId]?.displayName ?? 'Unknown User';
    final isAdmin = _currentGroup!.isAdmin(memberId);
    final canManageMembers = _currentGroup!.isAdmin(_currentUserId!);

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: _memberProfiles[memberId]?.photoUrl != null
                  ? NetworkImage(_memberProfiles[memberId]!.photoUrl!)
                  : null,
              child: _memberProfiles[memberId]?.photoUrl == null
                  ? Text(
                      memberName.isNotEmpty ? memberName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(memberName),
            subtitle: Text(isAdmin ? 'Admin' : 'Member'),
          ),
          const Divider(),
          if (canManageMembers) ...[
            if (!isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Make Admin'),
                onTap: () {
                  Navigator.pop(context);
                  _makeAdmin(memberId);
                },
              )
            else if (_currentGroup!.adminIds.length > 1)
              ListTile(
                leading: const Icon(Icons.remove_moderator),
                title: const Text('Remove Admin'),
                onTap: () {
                  Navigator.pop(context);
                  _removeAdmin(memberId);
                },
              ),
            ListTile(
              leading: Icon(
                Icons.remove_circle,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Remove from Group',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeMember(memberId);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showAddMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Members'),
        content: const Text('Add members functionality is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGroup == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isCurrentUserAdmin = _currentUserId != null && _currentGroup!.isAdmin(_currentUserId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: [
          if (isCurrentUserAdmin && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing) ...[
            if (_isUpdating)
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
                onPressed: _saveGroupChanges,
                child: const Text('Save'),
              ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Photo and Name
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickNewGroupPhoto : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _newGroupPhotoBytes != null
                                    ? MemoryImage(_newGroupPhotoBytes!) as ImageProvider
                                    : (_currentGroup!.photoUrl != null
                                        ? NetworkImage(_currentGroup!.photoUrl!) as ImageProvider
                                        : null),
                                child: (_newGroupPhotoBytes == null && _currentGroup!.photoUrl == null)
                                    ? Icon(
                                        Icons.group,
                                        size: 60,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      )
                                    : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isEditing)
                          TextField(
                            controller: _groupNameController,
                            decoration: const InputDecoration(
                              labelText: 'Group Name',
                              border: OutlineInputBorder(),
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            _currentGroup!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Created ${_formatDate(_currentGroup!.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Members (${_currentGroup!.members.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrentUserAdmin)
                        IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () {
                            // Navigate to add members screen
                            _showAddMembersDialog();
                          },
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Members List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentGroup!.members.length,
                    itemBuilder: (context, index) {
                      final memberId = _currentGroup!.members[index];
                      final profile = _memberProfiles[memberId];
                      final isAdmin = _currentGroup!.isAdmin(memberId);
                      final isCurrentUser = memberId == _currentUserId;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profile?.photoUrl != null
                              ? NetworkImage(profile!.photoUrl!)
                              : null,
                          child: profile?.photoUrl == null
                              ? Text(
                                  profile?.displayName.isNotEmpty == true
                                      ? profile!.displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(
                          isCurrentUser 
                              ? 'You' 
                              : (profile?.displayName ?? 'Unknown User'),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (profile?.email != null) Text(profile!.email),
                            if (isAdmin)
                              Text(
                                'Admin',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: !isCurrentUser && isCurrentUserAdmin
                            ? IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showMemberOptions(memberId),
                              )
                            : null,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Group Actions
                  if (_currentUserId != null && _currentGroup!.isMember(_currentUserId!)) ...[
                    ListTile(
                      leading: Icon(
                        Icons.exit_to_app,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Leave Group',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: _leaveGroup,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
}