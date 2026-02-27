import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/prayer_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class CreatePrayerRequestScreen extends StatefulWidget {
  const CreatePrayerRequestScreen({super.key});

  @override
  State<CreatePrayerRequestScreen> createState() =>
      _CreatePrayerRequestScreenState();
}

class _CreatePrayerRequestScreenState extends State<CreatePrayerRequestScreen> {
  final TextEditingController _requestController = TextEditingController();
  final PrayerService _prayerService = PrayerService();
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_requestController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your prayer request'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get user profile data
      final authService = Provider.of<AuthService>(context, listen: false);
      final userProfileService = UserProfileService(authService: authService);
      final userProfile = await userProfileService.getUserProfile(currentUser.uid);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final requestId = await _prayerService.createPrayerRequest(
        request: _requestController.text.trim(),
        userName: userProfile.displayName,
        userProfileImageUrl: userProfile.profileImageUrl,
        isAnonymous: _isAnonymous,
      );

      if (requestId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prayer request posted successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to create prayer request');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
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
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.lightBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.9),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                  title: const Text(
                    'New Prayer Request',
                    style: TextStyle(color: Colors.white),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    TextButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Post',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Share your prayer request with the community',
                        style: TextStyle(
                          color: AppTheme.lightOnSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Request text field
              TextField(
                controller: _requestController,
                maxLines: 8,
                maxLength: 500,
                style: const TextStyle(
                  color: AppTheme.lightOnSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Share your prayer request... (e.g., "Please pray for my family during this difficult time")',
                  hintStyle: const TextStyle(
                    color: AppTheme.lightOnSurfaceVariant,
                    fontSize: 14,
                  ),
                  labelText: 'Prayer Request *',
                  labelStyle: const TextStyle(
                    color: AppTheme.lightOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                  counterStyle: const TextStyle(
                    color: AppTheme.lightOnSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Anonymous toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Post anonymously',
                    style: TextStyle(
                      color: AppTheme.lightOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Your name will be hidden as "Anonymous"',
                    style: TextStyle(
                      color: AppTheme.lightOnSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymous = value;
                    });
                  },
                  activeColor: AppTheme.primaryBlue,
                  activeTrackColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Guidelines
              const Text(
                'Community Guidelines',
                style: TextStyle(
                  color: AppTheme.lightOnSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildGuideline('Be respectful and compassionate'),
              _buildGuideline('Keep requests appropriate for all ages'),
              _buildGuideline('Respect others\' privacy and confidentiality'),
              _buildGuideline('Focus on genuine prayer needs'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppTheme.successGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.lightOnSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}