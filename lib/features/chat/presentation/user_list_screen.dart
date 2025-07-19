import 'package:flutter/material.dart';
import 'package:raabta/features/auth/domain/models/user_profile_model.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/chat/domain/chat_repository.dart';
import 'package:raabta/features/chat/presentation/chat_screen.dart';
import 'package:raabta/core/services/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserProfileRepository _userProfileRepository = ServiceLocator().userProfileRepository;
  final ChatRepository _chatRepository = ServiceLocator().chatRepository;
  final AuthRepository _authRepository = FirebaseAuthRepository();
  
  final TextEditingController _searchController = TextEditingController();
  
  List<UserProfileModel> _allUsers = [];
  List<UserProfileModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterUsers();
    });
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = _allUsers;
    } else {
      _filteredUsers = _allUsers.where((user) {
        return user.name.toLowerCase().contains(_searchQuery) ||
               user.email.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) return;

      // Get all users from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isProfileComplete', isEqualTo: true)
          .get();

      final users = snapshot.docs
          .map((doc) => UserProfileModel.fromMap(doc.data()))
          .where((user) => user.uid != currentUser.uid) // Exclude current user
          .toList();

      setState(() {
        _allUsers = users;
        _filterUsers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startConversation(UserProfileModel user) async {
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get or create conversation
      final conversation = await _chatRepository.getOrCreateConversation(
        currentUser.uid,
        user.uid,
      );

      // Navigate to chat screen
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversation: conversation,
              otherUser: user,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Conversation'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _buildUserTile(user);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No users found for "$_searchQuery"'
                : 'No users available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserProfileModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.deepPurple.withOpacity(0.1),
          backgroundImage: user.photoUrl != null 
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                )
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user.bio!,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Active: ${user.activeHours}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: Colors.deepPurple,
        ),
        onTap: () => _startConversation(user),
      ),
    );
  }
}