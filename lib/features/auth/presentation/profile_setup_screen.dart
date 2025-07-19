import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raabta/features/auth/domain/models/user_profile_model.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/core/services/service_locator.dart';
import 'package:raabta/features/home/presentation/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final UserProfileModel initialProfile;

  const ProfileSetupScreen({
    super.key,
    required this.initialProfile,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserProfileRepository _userProfileRepository = ServiceLocator().userProfileRepository;
  
  // Controllers for text fields
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _religionController;
  late final TextEditingController _activeHoursController;
  
  // Form state
  late Gender _selectedGender;
  RelationshipStatus? _selectedRelationshipStatus;
  DateTime? _selectedDateOfBirth;
  String? _profilePhotoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _bioController = TextEditingController(text: widget.initialProfile.bio ?? '');
    _religionController = TextEditingController(text: widget.initialProfile.religion ?? '');
    _activeHoursController = TextEditingController(text: widget.initialProfile.activeHours);
    
    _selectedGender = widget.initialProfile.gender;
    _selectedRelationshipStatus = widget.initialProfile.relationshipStatus;
    _selectedDateOfBirth = widget.initialProfile.dateOfBirth;
    _profilePhotoUrl = widget.initialProfile.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _religionController.dispose();
    _activeHoursController.dispose();
    super.dispose();
  }

  bool get _canSkip {
    return _nameController.text.isNotEmpty && _activeHoursController.text.isNotEmpty;
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile({bool markComplete = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_canSkip && markComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = widget.initialProfile.copyWith(
        name: _nameController.text.trim(),
        gender: _selectedGender,
        activeHours: _activeHoursController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        religion: _religionController.text.trim().isEmpty ? null : _religionController.text.trim(),
        relationshipStatus: _selectedRelationshipStatus,
        dateOfBirth: _selectedDateOfBirth,
        photoUrl: _profilePhotoUrl,
        isProfileComplete: markComplete,
      );

      await _userProfileRepository.saveUserProfile(updatedProfile);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildProfilePhotoSection(),
                const SizedBox(height: 32),
                _buildRequiredFieldsSection(),
                const SizedBox(height: 32),
                _buildOptionalFieldsSection(),
                const SizedBox(height: 40),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete Your Profile',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us more about yourself to get started',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profilePhotoUrl != null
                    ? NetworkImage(_profilePhotoUrl!)
                    : null,
                child: _profilePhotoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: () {
                      // TODO: Implement photo picker functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photo editing will be implemented in future updates'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 16),
        
        // Name field
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            hintText: 'Enter your full name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Gender dropdown
        DropdownButtonFormField<Gender>(
          value: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wc),
          ),
          items: Gender.values.map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(gender.displayName),
            );
          }).toList(),
          onChanged: (Gender? value) {
            if (value != null) {
              setState(() {
                _selectedGender = value;
              });
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Gender is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Active hours field
        TextFormField(
          controller: _activeHoursController,
          decoration: const InputDecoration(
            labelText: 'Active Hours *',
            hintText: 'e.g., 9 AM - 6 PM',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.access_time),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Active hours are required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOptionalFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optional Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 16),
        
        // Date of birth field
        GestureDetector(
          onTap: _selectDateOfBirth,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                hintText: _selectedDateOfBirth != null
                    ? DateFormat('MMMM dd, yyyy').format(_selectedDateOfBirth!)
                    : 'Select your date of birth',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.cake),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: _selectedDateOfBirth != null
                    ? DateFormat('MMMM dd, yyyy').format(_selectedDateOfBirth!)
                    : '',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Bio field
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell us about yourself...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit_note),
          ),
        ),
        const SizedBox(height: 16),
        
        // Religion field
        TextFormField(
          controller: _religionController,
          decoration: const InputDecoration(
            labelText: 'Religion',
            hintText: 'Your religion (optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.church),
          ),
        ),
        const SizedBox(height: 16),
        
        // Relationship status dropdown
        DropdownButtonFormField<RelationshipStatus>(
          value: _selectedRelationshipStatus,
          decoration: const InputDecoration(
            labelText: 'Relationship Status',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.favorite),
          ),
          items: RelationshipStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status.displayName),
            );
          }).toList(),
          onChanged: (RelationshipStatus? value) {
            setState(() {
              _selectedRelationshipStatus = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Continue button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _saveProfile(markComplete: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Skip button (only if required fields are filled)
        if (_canSkip)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: _isLoading ? null : () => _saveProfile(markComplete: false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.deepPurple.withOpacity(0.3)),
                ),
              ),
              child: const Text(
                'Skip for now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        
        // Help text
        const SizedBox(height: 16),
        Text(
          'Fields marked with * are required',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}