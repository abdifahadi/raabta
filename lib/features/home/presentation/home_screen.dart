import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/domain/models/user_profile_model.dart';
import 'package:raabta/features/auth/presentation/sign_in_screen.dart';
import 'package:raabta/features/chat/presentation/chat_conversations_screen.dart';
import 'package:raabta/features/chat/presentation/user_list_screen.dart';
import 'package:raabta/core/services/service_locator.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthRepository _authRepository = FirebaseAuthRepository();
  final UserProfileRepository _userProfileRepository = ServiceLocator().userProfileRepository;
  UserProfileModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authRepository.currentUser;
      if (user != null) {
        final userProfile = await _userProfileRepository.getUserProfile(user.uid);
        setState(() {
          _userProfile = userProfile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepository.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raabta'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserListScreen(showCallButtonsOnly: true),
                ),
              );
            },
            tooltip: 'Voice Call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserListScreen(showCallButtonsOnly: true, isVideoCall: true),
                ),
              );
            },
            tooltip: 'Video Call',
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ConversationsScreen()),
              );
            },
            tooltip: 'Messages',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authRepository.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  if (_userProfile?.photoUrl != null || (user != null && user.photoURL != null))
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(_userProfile?.photoUrl ?? user!.photoURL!),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    _userProfile?.name ?? user?.displayName ?? 'Guest',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _userProfile?.email ?? user?.email ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoCard('User Information'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
      floatingActionButton: kDebugMode ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/call-test');
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        tooltip: 'Test Call System',
        child: const Icon(Icons.bug_report),
      ) : FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ConversationsScreen()),
          );
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        tooltip: 'Open Messages',
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildInfoCard(String title) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('User ID:', _userProfile?.uid ?? 'N/A'),
            _buildInfoRow('Created At:', _formatDate(_userProfile?.createdAt)),
            _buildInfoRow('Last Sign In:', _formatDate(_userProfile?.lastSignIn)),
            if (_userProfile?.gender != null)
              _buildInfoRow('Gender:', _userProfile!.gender.displayName),
            if (_userProfile?.activeHours != null)
              _buildInfoRow('Active Hours:', _userProfile!.activeHours),
            if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty)
              _buildInfoRow('Bio:', _userProfile!.bio!),
            if (_userProfile?.religion != null && _userProfile!.religion!.isNotEmpty)
              _buildInfoRow('Religion:', _userProfile!.religion!),
            if (_userProfile?.relationshipStatus != null)
              _buildInfoRow('Relationship:', _userProfile!.relationshipStatus!.displayName),
            if (_userProfile?.dateOfBirth != null)
              _buildInfoRow('Date of Birth:', _formatDate(_userProfile!.dateOfBirth)),
            _buildInfoRow('Profile Complete:', _userProfile?.isProfileComplete == true ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
