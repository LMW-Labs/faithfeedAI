import 'package:faithfeed/screens/main/friends_list_screen.dart';
import 'package:faithfeed/screens/main/saved_verses_screen.dart';
import 'package:faithfeed/screens/main/study_verses_screen.dart';
import 'package:faithfeed/screens/main/accomplishments_screen.dart';
import 'package:faithfeed/screens/main/my_study_plans_screen.dart';
import 'package:faithfeed/screens/terms_of_use_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/marketplace_service.dart';
import 'edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileService = Provider.of<UserProfileService>(context, listen: false);
      profileService.fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fetching user info to display name/email
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = Provider.of<UserProfileService>(context);
    final currentProfile = profileService.currentProfile;
    final userEmail = currentProfile?.email ?? authService.user?.email ?? 'user@faithfeed.com';
    final displayName = currentProfile?.displayName ?? authService.user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context, currentProfile, displayName, userEmail),
              const SizedBox(height: 24),
              _buildGridView(context),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.surface),
              const SizedBox(height: 16),
              _buildPaymentSettings(context),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.surface),
              const SizedBox(height: 16),
              _buildHelpAndSupport(),
              _buildSettingsAndPrivacy(),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.surface),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                icon: Icons.lock_outline,
                text: 'Change Password',
                onTap: () {
                  // TODO: Navigate to change password screen
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.logout,
                text: 'Log Out',
                onTap: () {
                  // Show confirmation dialog before logging out
                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return AlertDialog(
                        backgroundColor: AppTheme.darkGrey,
                        title: const Text('Log Out', style: TextStyle(color: AppTheme.onSurface)),
                        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              authService.signOut();
                              Navigator.of(ctx).pop(); // Close the dialog
                              Navigator.of(context).pop(); // Close the settings screen
                            },
                            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfileData? profile, String displayName, String email) {
    return Column(
      children: [
        Center(
          child: (profile?.profileImageUrl.isNotEmpty ?? false)
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profile!.profileImageUrl,
                    cacheKey: profile.profileImageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.surface,
                      child: const Icon(Icons.person, size: 50, color: AppTheme.onSurfaceVariant),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.surface,
                      child: const Icon(Icons.person, size: 50, color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.surface,
                  child: const Icon(Icons.person, size: 50, color: AppTheme.onSurfaceVariant),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
        ),
        if (profile?.bio.isNotEmpty ?? false) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              profile!.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final profileService = Provider.of<UserProfileService>(context, listen: false);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              // Refresh profile data after returning from edit screen
              if (mounted) {
                await profileService.fetchUserProfile();
              }
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text(
              'Edit Profile',
              style: TextStyle(
                decoration: TextDecoration.underline,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryTeal,
            ),
          ),
        ] else
          TextButton.icon(
            onPressed: () async {
              final profileService = Provider.of<UserProfileService>(context, listen: false);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              // Refresh profile data after returning from edit screen
              if (mounted) {
                await profileService.fetchUserProfile();
              }
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text(
              'Edit Profile',
              style: TextStyle(
                decoration: TextDecoration.underline,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryTeal,
            ),
          ),
      ],
    );
  }

  Widget _buildGridView(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildGridItem(
          icon: Icons.person_outline,
          label: 'Profile',
          onTap: () async {
            final profileService = Provider.of<UserProfileService>(context, listen: false);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
            // Refresh profile data after returning from edit screen
            if (mounted) {
              await profileService.fetchUserProfile();
            }
          },
        ),
        _buildGridItem(
          icon: Icons.bookmark,
          label: 'Saved',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedVersesScreen(),
              ),
            );
          },
        ),
        _buildGridItem(
          icon: Icons.people_outline,
          label: 'Friends',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendsListScreen(),
              ),
            );
          },
        ),
        _buildGridItem(
          icon: Icons.school,
          label: 'Study',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudyVersesScreen(),
              ),
            );
          },
        ),
        _buildGridItem(
          icon: Icons.calendar_month,
          label: 'Study Plans',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyStudyPlansScreen(),
              ),
            );
          },
        ),
        _buildGridItem(
          icon: Icons.emoji_events,
          label: 'Achievements',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccomplishmentsScreen(),
              ),
            );
          },
        ),
        _buildGridItem(icon: Icons.event_note, label: 'Events'),
      ],
    );
  }

  Widget _buildGridItem({required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppTheme.onSurface, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpAndSupport() {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text('Help & Support', style: TextStyle(color: AppTheme.onSurface, fontSize: 16)),
        leading: const Icon(Icons.help_outline, color: AppTheme.onSurfaceVariant),
        children: <Widget>[
          _buildSubListItem('Support', () {}),
          _buildSubListItem('Report a Problem', () {}),
          _buildSubListItem('Terms & Policies', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TermsOfUseScreen(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsAndPrivacy() {
    return ListTile(
      leading: const Icon(Icons.settings_outlined, color: AppTheme.onSurfaceVariant),
      title: const Text('Settings & Privacy', style: TextStyle(color: AppTheme.onSurface, fontSize: 16)),
      onTap: () {
        // TODO: Navigate to a dedicated settings page
      },
    );
  }

  Widget _buildPaymentSettings(BuildContext context) {
    final marketplaceService = MarketplaceService();

    return FutureBuilder<Map<String, dynamic>>(
      future: marketplaceService.getSellerStatus(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasAccount = snapshot.data?['hasAccount'] ?? false;
        final canReceivePayments = snapshot.data?['canReceivePayments'] ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canReceivePayments ? AppTheme.mintGreen : AppTheme.primaryTeal,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    canReceivePayments ? Icons.check_circle : Icons.store,
                    color: canReceivePayments ? AppTheme.mintGreen : AppTheme.primaryTeal,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Seller Payment Settings',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                canReceivePayments
                    ? 'Your seller account is active! You can receive payments from marketplace sales.'
                    : hasAccount
                        ? 'Complete your Stripe setup to start receiving payments.'
                        : 'Set up Stripe to sell items and receive payments (10% platform fee).',
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (canReceivePayments)
                // Show dashboard button for active sellers
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openStripeDashboard(context, marketplaceService),
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Open Stripe Dashboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.mintGreen,
                      side: const BorderSide(color: AppTheme.mintGreen),
                    ),
                  ),
                )
              else
                // Show setup button for non-sellers
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _setupSellerAccount(context, marketplaceService),
                    icon: const Icon(Icons.account_balance),
                    label: Text(hasAccount ? 'Complete Setup' : 'Become a Seller'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setupSellerAccount(BuildContext context, MarketplaceService service) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryTeal),
      ),
    );

    try {
      final result = await service.createSellerAccount();

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (result['success'] == true && result['onboardingUrl'] != null) {
        final url = Uri.parse(result['onboardingUrl']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complete the setup in your browser, then return here.'),
                backgroundColor: AppTheme.primaryTeal,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to start seller setup.'),
              backgroundColor: AppTheme.primaryCoral,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.primaryCoral,
        ),
      );
    }
  }

  Future<void> _openStripeDashboard(BuildContext context, MarketplaceService service) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryTeal),
      ),
    );

    try {
      final dashboardUrl = await service.getSellerDashboardLink();

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (dashboardUrl != null) {
        final url = Uri.parse(dashboardUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open dashboard. Please try again.'),
              backgroundColor: AppTheme.primaryCoral,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.primaryCoral,
        ),
      );
    }
  }

  Widget _buildSubListItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 55.0),
        child: Text(title, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.onSurfaceVariant),
        title: Text(text, style: const TextStyle(color: AppTheme.onSurface)),
        onTap: onTap,
      ),
    );
  }

}