import 'dart:io'; // Required for File class
import 'dart:ui' show ImageFilter; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for FilteringTextInputFormatter and SystemUiOverlayStyle
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_service.dart';

// UserProfileData is now accessible via user_profile_service.dart

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Profile controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneNumberController; // Declared
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _aboutMeController;
  late TextEditingController _testimonyController;
  late TextEditingController _denominationController;
  late TextEditingController _locationController;
  late TextEditingController _churchController;
  bool _showPhone = false; // Declared

  // Spiritual controllers
  late TextEditingController _prayerStyleController;
  late TextEditingController _currentReadingPlanController;
  late TextEditingController _favoriteVersesController;
  bool _baptized = false;
  DateTime? _faithJourneyStart;

  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _aboutMeController = TextEditingController();
    _testimonyController = TextEditingController();
    _denominationController = TextEditingController();
    _locationController = TextEditingController();
    _churchController = TextEditingController();
    _prayerStyleController = TextEditingController();
    _currentReadingPlanController = TextEditingController();
    _favoriteVersesController = TextEditingController();
    _phoneNumberController = TextEditingController(); // Initialized
    _showPhone = false; // Initialized
    _faithJourneyStart = null;

    // Load current profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    final profileService =
        Provider.of<UserProfileService>(context, listen: false);
    await profileService.fetchUserProfile();

    final profile = profileService.currentProfile;
    if (profile != null) {
      setState(() {
        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;
        _displayNameController.text = profile.displayName;
        _bioController.text = profile.bio;
        _aboutMeController.text = profile.aboutMe ?? '';
        _testimonyController.text = profile.testimony ?? '';
        _denominationController.text = profile.denomination;
        _locationController.text = profile.location;
        _churchController.text = profile.church;
        _phoneNumberController.text = profile.phoneNumber ?? ''; // Populate phone number
        _showPhone = profile.showPhone; // Correctly get from profile.showPhone
        _baptized = profile.baptized;
        _prayerStyleController.text = profile.prayerStyle;
        _currentReadingPlanController.text = profile.currentReadingPlan;
        _favoriteVersesController.text = profile.favoriteVerses.join(', ');
        if (profile.faithJourneyStart != null) {
          _faithJourneyStart = DateTime.tryParse(profile.faithJourneyStart!);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _aboutMeController.dispose();
    _testimonyController.dispose();
    _denominationController.dispose();
    _locationController.dispose();
    _churchController.dispose();
    _prayerStyleController.dispose();
    _currentReadingPlanController.dispose();
    _favoriteVersesController.dispose();
    _phoneNumberController.dispose(); // Disposed
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final profileService =
        Provider.of<UserProfileService>(context, listen: false);

    XFile? image;
    if (source == ImageSource.gallery) {
      image = await profileService.pickImageFromGallery();
    } else {
      image = await profileService.pickImageFromCamera();
    }

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Profile Picture',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppTheme.primaryTeal),
                title: const Text('Gallery',
                    style: TextStyle(color: AppTheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppTheme.primaryTeal),
                title: const Text('Camera',
                    style: TextStyle(color: AppTheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null ||
                  (Provider.of<UserProfileService>(context)
                          .currentProfile
                          ?.profileImageUrl
                          .isNotEmpty ??
                      false))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                    final profileService =
                        Provider.of<UserProfileService>(context, listen: false);
                    profileService.deleteProfilePicture();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final profileService =
        Provider.of<UserProfileService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Upload image if selected
      String? imageUrl = profileService.currentProfile?.profileImageUrl ?? '';
      debugPrint('🔍 [SAVE] Initial imageUrl from currentProfile: $imageUrl');
      debugPrint('🔍 [SAVE] _selectedImage is null: ${_selectedImage == null}');

      if (_selectedImage != null) {
        debugPrint('🔍 [SAVE] Uploading new image from: ${_selectedImage!.path}');
        final uploadedUrl =
            await profileService.uploadProfilePicture(_selectedImage!);
        debugPrint('🔍 [SAVE] uploadProfilePicture returned: $uploadedUrl');
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          debugPrint('🔍 [SAVE] Updated imageUrl to: $imageUrl');
        } else {
          debugPrint('🔍 [SAVE] WARNING: uploadProfilePicture returned null!');
        }
      }

      debugPrint('🔍 [SAVE] Final imageUrl for profile update: $imageUrl');

      // Parse favorite verses from comma-separated string
      final favoriteVersesList = _favoriteVersesController.text
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();

      // Get current profile or create with defaults
      final currentProfile = profileService.currentProfile;

      // Create updated profile data
      final updatedProfile = UserProfileData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: currentProfile?.username,
        displayName: _displayNameController.text.trim(),
        email: authService.user?.email ?? '',
        profileImageUrl: imageUrl,
        bio: _bioController.text.trim(),
        aboutMe: _aboutMeController.text.trim().isNotEmpty
            ? _aboutMeController.text.trim()
            : null,
        testimony: _testimonyController.text.trim().isNotEmpty
            ? _testimonyController.text.trim()
            : null,
        denomination: _denominationController.text.trim(),
        city: currentProfile?.city ?? '',
        state: currentProfile?.state ?? '',
        address: currentProfile?.address,
        zipCode: currentProfile?.zipCode,
        location: _locationController.text.trim(),
        church: _churchController.text.trim(),
        baptized: _baptized,
        faithJourneyStart: _faithJourneyStart?.toIso8601String(),
        favoriteVerses: favoriteVersesList,
        prayerStyle: _prayerStyleController.text.trim(),
        currentReadingPlan: _currentReadingPlanController.text.trim(),
        notificationsEnabled: currentProfile?.notificationsEnabled ?? true,
        prayerReminders: currentProfile?.prayerReminders ?? 'daily',
        privacyLevel: currentProfile?.privacyLevel ?? 'community',
        phoneNumber: _phoneNumberController.text.trim(),
        showPhone: _showPhone,
      );

      // Update profile
      final success = await profileService.updateProfile(updatedProfile);

      if (mounted) {
        if (success) {
          // Force a fresh fetch to ensure UI updates
          await profileService.fetchUserProfile();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppTheme.primaryTeal,
            ),
          );
          Navigator.pop(context);
        } else {
          final errorMessage =
              profileService.lastErrorMessage ?? 'Failed to update profile'; // Corrected variable
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileService = Provider.of<UserProfileService>(context);
    final currentProfile = profileService.currentProfile;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: AppTheme.onSurface)),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.onSurface),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          if (_isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(color: AppTheme.primaryTeal, fontSize: 16),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryTeal,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Spiritual'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(currentProfile),
            _buildSpiritualTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(UserProfileData? currentProfile) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: 20.0 + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        children: [
          // Profile Picture
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.surface,
                  backgroundImage: _selectedImage != null
                      ? FileImage(File(_selectedImage!.path)) as ImageProvider
                      : (currentProfile?.profileImageUrl.isNotEmpty ?? false)
                          ? NetworkImage(currentProfile!.profileImageUrl)
                              as ImageProvider
                          : null,
                  child: (_selectedImage == null &&
                          (currentProfile?.profileImageUrl.isEmpty ?? true))
                      ? const Icon(Icons.person,
                          size: 60, color: AppTheme.onSurfaceVariant)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // First Name
          _buildTextField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Last Name
          _buildTextField(
            controller: _lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Display Name
          _buildTextField(
            controller: _displayNameController,
            label: 'Display Name',
            icon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your display name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Bio/Headline (short one-liner)
          _buildTextField(
            controller: _bioController,
            label: 'Headline',
            icon: Icons.short_text,
            maxLines: 1,
            maxLength: 50,
            hint: 'A short headline about yourself (50 characters max)...',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your headline appears below your username on your profile',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About Me (longer description)
          _buildTextField(
            controller: _aboutMeController,
            label: 'About Me (Optional)',
            icon: Icons.description_outlined,
            maxLines: 5,
            maxLength: 500,
            hint: 'Tell us more about yourself, your interests, hobbies, ministry work, etc. (500 characters max)...',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'This detailed description helps others get to know you better',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phone Number
          _buildTextField(
            controller: _phoneNumberController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            hint: 'Enter your phone number',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          // Phone Number Visibility
          _buildFrostedContainer(
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, color: AppTheme.primaryTeal),
                const SizedBox(width: 12),
                const Text(
                  'Show Phone Number',
                  style: TextStyle(color: AppTheme.onSurface, fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showPhone,
                  onChanged: (value) {
                    setState(() {
                      _showPhone = value;
                    });
                  },
                  activeTrackColor: AppTheme.primaryTeal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Testimony
          _buildTextField(
            controller: _testimonyController,
            label: 'My Testimony (Optional)',
            icon: Icons.auto_stories,
            maxLines: 5,
            maxLength: 500,
            hint: 'Share your faith journey and testimony (500 characters max)...',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your testimony will be accessible to others via a button on your profile',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Denomination
          _buildTextField(
            controller: _denominationController,
            label: 'Denomination',
            icon: Icons.church_outlined,
            hint: 'e.g., Baptist, Catholic, Non-denominational',
          ),
          const SizedBox(height: 16),

          // Location
          _buildTextField(
            controller: _locationController,
            label: 'Location',
            icon: Icons.location_on_outlined,
            hint: 'City, State',
          ),
          const SizedBox(height: 16),

          // Church
          _buildTextField(
            controller: _churchController,
            label: 'Church',
            icon: Icons.home_outlined,
            hint: 'Your home church',
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritualTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: 20.0 + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baptized
          _buildFrostedContainer(
            child: Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    color: AppTheme.primaryTeal),
                const SizedBox(width: 12),
                const Text(
                  'Baptized',
                  style: TextStyle(color: AppTheme.onSurface, fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _baptized,
                  onChanged: (value) {
                    setState(() {
                      _baptized = value;
                    });
                  },
                  activeTrackColor: AppTheme.primaryTeal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Faith Journey Start
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _faithJourneyStart ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primaryTeal,
                        surface: AppTheme.surface,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() {
                  _faithJourneyStart = date;
                });
              }
            },
            child: _buildFrostedContainer(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppTheme.primaryTeal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Faith Journey Start',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _faithJourneyStart != null
                              ? '${_faithJourneyStart!.month}/${_faithJourneyStart!.day}/${_faithJourneyStart!.year}'
                              : 'Not set',
                          style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined,
                      color: AppTheme.onSurfaceVariant, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Prayer Style Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label above the dropdown
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: const [
                    Icon(Icons.favorite_outline, color: AppTheme.primaryTeal, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Prayer Style',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _prayerStyleController.text.isEmpty ? null : _prayerStyleController.text,
                  decoration: InputDecoration(
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                    ),
                  ),
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: AppTheme.onSurface),
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.onSurfaceVariant),
                  hint: const Text('Select your prayer style', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  items: const [
                    DropdownMenuItem(value: 'Contemplative', child: Text('Contemplative', style: TextStyle(color: AppTheme.onSurface))),
                    DropdownMenuItem(value: 'Intercessory', child: Text('Intercessory', style: TextStyle(color: AppTheme.onSurface))),
                    DropdownMenuItem(value: 'Thanksgiving', child: Text('Thanksgiving', style: TextStyle(color: AppTheme.onSurface))),
                    DropdownMenuItem(value: 'Petitionary', child: Text('Petitionary', style: TextStyle(color: AppTheme.onSurface))),
                    DropdownMenuItem(value: 'Liturgical', child: Text('Liturgical', style: TextStyle(color: AppTheme.onSurface))),
                    DropdownMenuItem(value: 'Charismatic', child: Text('Charismatic', style: TextStyle(color: AppTheme.onSurface))),
                    DropdownMenuItem(value: 'Meditative', child: Text('Meditative', style: TextStyle(color: AppTheme.onSurface))),
                    DropdownMenuItem(value: 'Conversational', child: Text('Conversational', style: TextStyle(color: AppTheme.onSurface))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _prayerStyleController.text = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current Reading Plan
          _buildTextField(
            controller: _currentReadingPlanController,
            label: 'Current Reading Plan',
            icon: Icons.menu_book_outlined,
            hint: 'e.g., One Year Bible, Chronological',
          ),
          const SizedBox(height: 16),

          // Favorite Verses
          _buildTextField(
            controller: _favoriteVersesController,
            label: 'Favorite Verses',
            icon: Icons.bookmark_outline,
            hint: 'Separate with commas (e.g., John 3:16, Psalm 23:1)',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    TextInputType? keyboardType, // Added
    List<TextInputFormatter>? inputFormatters, // Added
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the input
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryTeal, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Dark surface input field with light text
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: AppTheme.onSurface, fontSize: 16),
            maxLines: maxLines,
            maxLength: maxLength,
            validator: validator,
            keyboardType: keyboardType, // Used
            inputFormatters: inputFormatters, // Used
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
              counterStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}