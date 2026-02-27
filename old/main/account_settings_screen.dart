import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:faithfeed/providers/subscription_provider.dart';
import 'package:faithfeed/widgets/premium_paywall.dart';
import 'package:faithfeed/services/push_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../utils/ui_helpers.dart';
import '../terms_of_use_screen.dart';
import '../privacy_policy_screen.dart';

/// Account Settings Screen
///
/// Manages account-level settings like privacy, notifications, security, etc.
/// Settings are organized into collapsible category sections.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  /// Update a privacy setting in the user's profile
  Future<void> _updatePrivacySetting({
    bool? showFullName,
    bool? showEmail,
    bool? showPhone,
    bool? showLocation,
    bool? showAddress,
    bool? showAge,
    bool? showBirthdate,
    bool? showGender,
    bool? showMaritalStatus,
    bool? showBaptismStatus,
    bool? showDenomination,
    bool? showChurch,
    bool? showFaithJourneyDate,
    bool? showPrayerStyle,
    bool? showReadingPlan,
    bool? showFavoriteVerses,
  }) async {
    final profileService = Provider.of<UserProfileService>(context, listen: false);
    final currentProfile = profileService.currentProfile;

    if (currentProfile == null) {
      Log.d('Cannot update privacy: no current profile');
      return;
    }

    final updatedProfile = currentProfile.copyWith(
      showFullName: showFullName,
      showEmail: showEmail,
      showPhone: showPhone,
      showLocation: showLocation,
      showAddress: showAddress,
      showAge: showAge,
      showBirthdate: showBirthdate,
      showGender: showGender,
      showMaritalStatus: showMaritalStatus,
      showBaptismStatus: showBaptismStatus,
      showDenomination: showDenomination,
      showChurch: showChurch,
      showFaithJourneyDate: showFaithJourneyDate,
      showPrayerStyle: showPrayerStyle,
      showReadingPlan: showReadingPlan,
      showFavoriteVerses: showFavoriteVerses,
    );

    final success = await profileService.updateProfile(updatedProfile);

    if (mounted) {
      if (success) {
        HapticHelper.light();
        SnackbarHelper.showSuccess(context, 'Privacy setting updated');
      } else {
        HapticHelper.medium();
        SnackbarHelper.showError(context, 'Failed to update privacy setting');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: AppTheme.onSurface)),
        backgroundColor: AppTheme.surface,
        iconTheme: const IconThemeData(color: AppTheme.onSurface),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Privacy Section
          _buildCategoryTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Control who can see your information',
            onTap: () => _openPrivacySettings(),
          ),

          // Spiritual Information Section
          _buildCategoryTile(
            icon: Icons.auto_awesome,
            title: 'Spiritual Information',
            subtitle: 'Manage faith journey visibility',
            onTap: () => _openSpiritualSettings(),
          ),

          // Notifications Section
          _buildCategoryTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage alerts and reminders',
            onTap: () => _openNotificationSettings(),
          ),

          // Security Section
          _buildCategoryTile(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Password and account security',
            onTap: () => _openSecuritySettings(authService),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.darkGrey, height: 1),
          const SizedBox(height: 16),

          // Legal Section
          _buildSectionHeader('Legal'),
          _buildSettingTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsOfUseScreen()),
            ),
          ),
          _buildSettingTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.darkGrey, height: 1),
          const SizedBox(height: 16),

          // Subscription Section
          _buildSectionHeader('Subscription'),
          _buildSettingTile(
            icon: Icons.star,
            title: 'Upgrade to Premium',
            subtitle: 'Unlock all features and unlimited access',
            onTap: () => showPremiumPaywall(
              context: context,
              featureName: 'Premium Subscription',
              featureDescription: 'Get unlimited access to all features.',
            ),
          ),
          _buildSettingTile(
            icon: Icons.restore,
            title: 'Restore Purchases',
            subtitle: 'Restore your previous purchases',
            onTap: () => _restorePurchases(),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.darkGrey, height: 1),
          const SizedBox(height: 16),

          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            textColor: Colors.red,
            onTap: () => _showDeleteAccountDialog(authService),
          ),

          const SizedBox(height: 32),

          // Version Info
          Center(
            child: Column(
              children: [
                const Text(
                  'faithfeed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryTeal,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryTeal, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppTheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor ?? AppTheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Future<void> _restorePurchases() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryTeal),
            SizedBox(height: 16),
            Text(
              'Restoring purchases...',
              style: TextStyle(color: AppTheme.onSurface),
            ),
          ],
        ),
      ),
    );

    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final success = await subscriptionProvider.restorePurchases();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          HapticHelper.light();
          SnackbarHelper.showSuccess(context, 'Purchases restored successfully!');
        } else {
          final error = subscriptionProvider.purchaseError ?? 'No previous purchases found';
          SnackbarHelper.showError(context, error);
        }
      }
    } catch (e) {
      Log.e('Restoring purchases: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        SnackbarHelper.showError(context, 'Failed to restore purchases. Please try again.');
      }
    }
  }

  // ==================== Privacy Settings ====================

  void _openPrivacySettings() {
    final profileService = Provider.of<UserProfileService>(context, listen: false);
    final profile = profileService.currentProfile;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PrivacySettingsPage(
          profile: profile,
          onUpdatePrivacy: _updatePrivacySetting,
          onShowPrivacyDialog: _showPrivacyDialog,
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    final profileService = Provider.of<UserProfileService>(context, listen: false);
    final currentProfile = profileService.currentProfile;
    final currentLevel = currentProfile?.privacyLevel ?? 'public';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Profile Visibility', style: TextStyle(color: AppTheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPrivacyOption('Public', 'Anyone can see your profile', 'public', currentLevel, dialogContext),
            _buildPrivacyOption('Community', 'Only community members can see', 'community', currentLevel, dialogContext),
            _buildPrivacyOption('Private', 'Only you can see your profile', 'private', currentLevel, dialogContext),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(String title, String subtitle, String value, String currentValue, BuildContext dialogContext) {
    final isSelected = value == currentValue;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppTheme.primaryTeal : AppTheme.onSurfaceVariant,
      ),
      title: Text(title, style: TextStyle(
        color: isSelected ? AppTheme.primaryTeal : AppTheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
      onTap: () async {
        Navigator.pop(dialogContext);
        final profileService = Provider.of<UserProfileService>(context, listen: false);
        final currentProfile = profileService.currentProfile;
        if (currentProfile != null) {
          final updatedProfile = currentProfile.copyWith(privacyLevel: value);
          final success = await profileService.updateProfile(updatedProfile);
          if (mounted) {
            if (success) {
              HapticHelper.light();
              SnackbarHelper.showSuccess(context, 'Privacy setting updated');
            } else {
              SnackbarHelper.showError(context, 'Failed to update privacy setting');
            }
          }
        }
      },
    );
  }

  // ==================== Notification Settings ====================

  void _openNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _NotificationSettingsPage(),
      ),
    );
  }

  // ==================== Spiritual Settings ====================

  void _openSpiritualSettings() {
    final profileService = Provider.of<UserProfileService>(context, listen: false);
    final profile = profileService.currentProfile;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SpiritualSettingsPage(
          profile: profile,
          onUpdatePrivacy: _updatePrivacySetting,
        ),
      ),
    );
  }

  // ==================== Security Settings ====================

  void _openSecuritySettings(AuthService authService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SecuritySettingsPage(
          authService: authService,
          onShowComingSoon: _showComingSoonDialog,
        ),
      ),
    );
  }

  // ==================== Dialogs ====================

  void _showComingSoonDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.construction, color: AppTheme.primaryTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: AppTheme.onSurface)),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.primaryTeal)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Account', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Deleting your account will:',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            SizedBox(height: 8),
            Text('• Remove all your profile information', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            Text('• Delete all your posts and comments', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            Text('• Remove your prayer requests', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            Text('• Delete your listings in FaithFinds', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            SizedBox(height: 16),
            Text(
              'Are you sure you want to proceed?',
              style: TextStyle(color: AppTheme.onSurface),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.primaryTeal)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog(authService);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(AuthService authService) {
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Confirm Deletion', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type DELETE to confirm:',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withAlpha(100)),
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppTheme.onSurface),
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.primaryTeal)),
          ),
          TextButton(
            onPressed: () async {
              if (confirmController.text.toUpperCase() == 'DELETE') {
                Navigator.pop(context);
                await _performAccountDeletion(authService);
              } else {
                SnackbarHelper.showError(context, 'Please type DELETE to confirm');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion(AuthService authService) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryTeal),
            SizedBox(height: 16),
            Text(
              'Deleting your account...',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a moment.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    try {
      final user = authService.user;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final db = FirebaseFirestore.instance;

      // Delete user profile
      await db.collection('users').doc(user.uid).delete();

      // Delete user's posts
      final postsSnapshot = await db.collection('posts').where('userId', isEqualTo: user.uid).get();
      for (final doc in postsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user's prayer requests
      final prayersSnapshot = await db.collection('prayerRequests').where('userId', isEqualTo: user.uid).get();
      for (final doc in prayersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user's marketplace items
      final marketplaceSnapshot = await db.collection('marketplaceItems').where('userId', isEqualTo: user.uid).get();
      for (final doc in marketplaceSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the Firebase Auth account
      await user.delete();

      // Sign out
      await authService.signOut();

      // Close loading dialog and navigate to login
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      Log.e('deleting account: $e');

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        String errorMessage = 'Failed to delete account. ';
        if (e.toString().contains('requires-recent-login')) {
          errorMessage += 'Please sign out, sign back in, and try again.';
        } else {
          errorMessage += 'Please try again or contact support.';
        }

        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Error', style: TextStyle(color: Colors.red)),
            content: Text(
              errorMessage,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK', style: TextStyle(color: AppTheme.primaryTeal)),
              ),
            ],
          ),
        );
      }
    }
  }
}

// ==================== Privacy Settings Page ====================

class _PrivacySettingsPage extends StatelessWidget {
  final UserProfileData? profile;
  final Future<void> Function({
    bool? showFullName,
    bool? showEmail,
    bool? showPhone,
    bool? showLocation,
    bool? showAddress,
    bool? showAge,
    bool? showBirthdate,
    bool? showGender,
    bool? showMaritalStatus,
  }) onUpdatePrivacy;
  final VoidCallback onShowPrivacyDialog;

  const _PrivacySettingsPage({
    required this.profile,
    required this.onUpdatePrivacy,
    required this.onShowPrivacyDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: AppTheme.surface,
      ),
      body: Consumer<UserProfileService>(
        builder: (context, profileService, _) {
          final currentProfile = profileService.currentProfile;

          return ListView(
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.visibility, color: AppTheme.onSurfaceVariant),
                title: const Text('Profile Visibility', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
                subtitle: Text(
                  currentProfile?.privacyLevel == 'public'
                      ? 'Public - Anyone can see your profile'
                      : currentProfile?.privacyLevel == 'private'
                          ? 'Private'
                          : 'Community Only',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
                onTap: onShowPrivacyDialog,
              ),
              const Divider(color: AppTheme.darkGrey, height: 1),
              const SizedBox(height: 8),
              _buildSectionHeader('Personal Information'),
              _buildSwitchTile(
                icon: Icons.person,
                title: 'Show Full Name',
                subtitle: 'Display your first and last name',
                value: currentProfile?.showFullName ?? true,
                onChanged: (value) => onUpdatePrivacy(showFullName: value),
              ),
              _buildSwitchTile(
                icon: Icons.email,
                title: 'Show Email',
                subtitle: 'Display your email address',
                value: currentProfile?.showEmail ?? false,
                onChanged: (value) => onUpdatePrivacy(showEmail: value),
              ),
              _buildSwitchTile(
                icon: Icons.phone,
                title: 'Show Phone',
                subtitle: 'Display your phone number',
                value: currentProfile?.showPhone ?? false,
                onChanged: (value) => onUpdatePrivacy(showPhone: value),
              ),
              _buildSwitchTile(
                icon: Icons.location_on,
                title: 'Show Location',
                subtitle: 'Display your city and state',
                value: currentProfile?.showLocation ?? true,
                onChanged: (value) => onUpdatePrivacy(showLocation: value),
              ),
              _buildSwitchTile(
                icon: Icons.home,
                title: 'Show Address',
                subtitle: 'Display your full address',
                value: currentProfile?.showAddress ?? false,
                onChanged: (value) => onUpdatePrivacy(showAddress: value),
              ),
              _buildSwitchTile(
                icon: Icons.cake,
                title: 'Show Age',
                subtitle: 'Display your age',
                value: currentProfile?.showAge ?? false,
                onChanged: (value) => onUpdatePrivacy(showAge: value),
              ),
              _buildSwitchTile(
                icon: Icons.calendar_today,
                title: 'Show Birth Date',
                subtitle: 'Display your full date of birth',
                value: currentProfile?.showBirthdate ?? false,
                onChanged: (value) => onUpdatePrivacy(showBirthdate: value),
              ),
              _buildSwitchTile(
                icon: Icons.wc,
                title: 'Show Gender',
                subtitle: 'Display your gender',
                value: currentProfile?.showGender ?? true,
                onChanged: (value) => onUpdatePrivacy(showGender: value),
              ),
              _buildSwitchTile(
                icon: Icons.favorite,
                title: 'Show Marital Status',
                subtitle: 'Display your marital status',
                value: currentProfile?.showMaritalStatus ?? false,
                onChanged: (value) => onUpdatePrivacy(showMaritalStatus: value),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryTeal,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.onSurfaceVariant),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppTheme.primaryTeal,
    );
  }
}

// ==================== Spiritual Settings Page ====================

class _SpiritualSettingsPage extends StatelessWidget {
  final UserProfileData? profile;
  final Future<void> Function({
    bool? showBaptismStatus,
    bool? showDenomination,
    bool? showChurch,
    bool? showFaithJourneyDate,
    bool? showPrayerStyle,
    bool? showReadingPlan,
    bool? showFavoriteVerses,
  }) onUpdatePrivacy;

  const _SpiritualSettingsPage({
    required this.profile,
    required this.onUpdatePrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Spiritual Information'),
        backgroundColor: AppTheme.surface,
      ),
      body: Consumer<UserProfileService>(
        builder: (context, profileService, _) {
          final currentProfile = profileService.currentProfile;

          return ListView(
            children: [
              const SizedBox(height: 8),
              _buildSectionHeader('What others can see'),
              _buildSwitchTile(
                icon: Icons.water_drop,
                title: 'Show Baptism Status',
                subtitle: 'Display whether you are baptized',
                value: currentProfile?.showBaptismStatus ?? true,
                onChanged: (value) => onUpdatePrivacy(showBaptismStatus: value),
              ),
              _buildSwitchTile(
                icon: Icons.church,
                title: 'Show Denomination',
                subtitle: 'Display your denomination',
                value: currentProfile?.showDenomination ?? true,
                onChanged: (value) => onUpdatePrivacy(showDenomination: value),
              ),
              _buildSwitchTile(
                icon: Icons.home_work,
                title: 'Show Church',
                subtitle: 'Display your church name',
                value: currentProfile?.showChurch ?? true,
                onChanged: (value) => onUpdatePrivacy(showChurch: value),
              ),
              _buildSwitchTile(
                icon: Icons.timeline,
                title: 'Show Faith Journey Date',
                subtitle: 'Display when your faith journey started',
                value: currentProfile?.showFaithJourneyDate ?? true,
                onChanged: (value) => onUpdatePrivacy(showFaithJourneyDate: value),
              ),
              _buildSwitchTile(
                icon: Icons.self_improvement,
                title: 'Show Prayer Style',
                subtitle: 'Display your prayer style',
                value: currentProfile?.showPrayerStyle ?? true,
                onChanged: (value) => onUpdatePrivacy(showPrayerStyle: value),
              ),
              _buildSwitchTile(
                icon: Icons.book,
                title: 'Show Reading Plan',
                subtitle: 'Display your current reading plan',
                value: currentProfile?.showReadingPlan ?? true,
                onChanged: (value) => onUpdatePrivacy(showReadingPlan: value),
              ),
              _buildSwitchTile(
                icon: Icons.bookmark,
                title: 'Show Favorite Verses',
                subtitle: 'Display your favorite Bible verses',
                value: currentProfile?.showFavoriteVerses ?? true,
                onChanged: (value) => onUpdatePrivacy(showFavoriteVerses: value),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryTeal,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.onSurfaceVariant),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppTheme.primaryTeal,
    );
  }
}

// ==================== Security Settings Page ====================

class _SecuritySettingsPage extends StatelessWidget {
  final AuthService authService;
  final void Function(String title, String message) onShowComingSoon;

  const _SecuritySettingsPage({
    required this.authService,
    required this.onShowComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: AppTheme.surface,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.lock, color: AppTheme.onSurfaceVariant),
            title: const Text('Change Password', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
            subtitle: const Text('Update your password', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
            onTap: () => _showChangePasswordDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.email, color: AppTheme.onSurfaceVariant),
            title: const Text('Email', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
            subtitle: Text(authService.user?.email ?? 'Not set', style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
            onTap: () => onShowComingSoon('Change Email', 'Email change functionality will be available in a future update.'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user, color: AppTheme.onSurfaceVariant),
            title: const Text('Two-Factor Authentication', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
            subtitle: const Text('Not enabled', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
            onTap: () => onShowComingSoon('Two-Factor Authentication', '2FA will be available in a future update for enhanced security.'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final email = authService.user?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email associated with this account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Change Password', style: TextStyle(color: AppTheme.onSurface)),
        content: Text(
          'We will send a password reset link to:\n\n$email\n\nCheck your email and follow the instructions to change your password.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await authService.sendPasswordResetEmail(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent to $email'),
                      backgroundColor: AppTheme.primaryTeal,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send reset email: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Email', style: TextStyle(color: AppTheme.primaryTeal)),
          ),
        ],
      ),
    );
  }
}

// ==================== Notification Settings Page ====================

class _NotificationSettingsPage extends StatefulWidget {
  const _NotificationSettingsPage();

  @override
  State<_NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<_NotificationSettingsPage> {
  final PushNotificationService _notificationService = PushNotificationService();
  bool _verseOfTheDayEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final isSubscribed = await _notificationService.isSubscribedToVerseOfTheDay();
    if (mounted) {
      setState(() {
        _verseOfTheDayEnabled = isSubscribed;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleVerseOfTheDay(bool value) async {
    setState(() => _isLoading = true);

    try {
      if (value) {
        await _notificationService.subscribeToVerseOfTheDay();
      } else {
        await _notificationService.unsubscribeFromVerseOfTheDay();
      }

      if (mounted) {
        setState(() {
          _verseOfTheDayEnabled = value;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'You will receive daily verse notifications'
                : 'Daily verse notifications disabled'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      Log.e('Toggling VOTD notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update notification settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
          : ListView(
              children: [
                const SizedBox(height: 8),
                _buildSectionHeader('Daily Notifications'),
                SwitchListTile(
                  secondary: const Icon(Icons.menu_book, color: AppTheme.primaryTeal),
                  title: const Text(
                    'Verse of the Day',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Receive a daily Bible verse notification each morning',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  value: _verseOfTheDayEnabled,
                  onChanged: _toggleVerseOfTheDay,
                  activeTrackColor: AppTheme.primaryTeal,
                ),
                const Divider(color: AppTheme.darkGrey, height: 1, indent: 16, endIndent: 16),
                const SizedBox(height: 16),

                _buildSectionHeader('Community Notifications'),
                _buildComingSoonTile(
                  icon: Icons.favorite,
                  title: 'Likes',
                  subtitle: 'When someone likes your posts or comments',
                ),
                _buildComingSoonTile(
                  icon: Icons.comment,
                  title: 'Comments',
                  subtitle: 'When someone comments on your posts',
                ),
                _buildComingSoonTile(
                  icon: Icons.person_add,
                  title: 'Friend Requests',
                  subtitle: 'When someone sends you a friend request',
                ),
                _buildComingSoonTile(
                  icon: Icons.favorite_border,
                  title: 'Prayer Support',
                  subtitle: 'When someone prays for your request',
                ),

                const SizedBox(height: 16),
                const Divider(color: AppTheme.darkGrey, height: 1),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'More notification options coming soon!',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryTeal,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildComingSoonTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'SOON',
          style: TextStyle(
            color: AppTheme.primaryTeal,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
