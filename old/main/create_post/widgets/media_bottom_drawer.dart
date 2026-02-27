import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Bottom drawer containing media, GIF, location, emoji, and tag options
class MediaBottomDrawer extends StatelessWidget {
  final VoidCallback onPhotoTap;
  final VoidCallback onVideoTap;
  final VoidCallback onGifTap;
  final VoidCallback onLocationTap;
  final VoidCallback onEmojiTap;
  final VoidCallback onTagPeopleTap;

  const MediaBottomDrawer({
    super.key,
    required this.onPhotoTap,
    required this.onVideoTap,
    required this.onGifTap,
    required this.onLocationTap,
    required this.onEmojiTap,
    required this.onTagPeopleTap,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onPhotoTap,
    required VoidCallback onVideoTap,
    required VoidCallback onGifTap,
    required VoidCallback onLocationTap,
    required VoidCallback onEmojiTap,
    required VoidCallback onTagPeopleTap,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MediaBottomDrawer(
        onPhotoTap: onPhotoTap,
        onVideoTap: onVideoTap,
        onGifTap: onGifTap,
        onLocationTap: onLocationTap,
        onEmojiTap: onEmojiTap,
        onTagPeopleTap: onTagPeopleTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Add to your post',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Grid of options
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildOption(
                  context,
                  icon: Icons.photo_library_outlined,
                  label: 'Photo',
                  color: AppTheme.primaryTeal,
                  onTap: () {
                    Navigator.pop(context);
                    onPhotoTap();
                  },
                ),
                _buildOption(
                  context,
                  icon: Icons.videocam_outlined,
                  label: 'Video',
                  color: AppTheme.primaryCoral,
                  onTap: () {
                    Navigator.pop(context);
                    onVideoTap();
                  },
                ),
                _buildOption(
                  context,
                  icon: Icons.gif_box_outlined,
                  label: 'GIF',
                  color: AppTheme.highlightYellow,
                  onTap: () {
                    Navigator.pop(context);
                    onGifTap();
                  },
                ),
                _buildOption(
                  context,
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(context);
                    onLocationTap();
                  },
                ),
                _buildOption(
                  context,
                  icon: Icons.emoji_emotions_outlined,
                  label: 'Emoji',
                  color: const Color(0xFFEC4899),
                  onTap: () {
                    Navigator.pop(context);
                    onEmojiTap();
                  },
                ),
                _buildOption(
                  context,
                  icon: Icons.person_add_outlined,
                  label: 'Tag People',
                  color: AppTheme.primaryTeal,
                  onTap: () {
                    Navigator.pop(context);
                    onTagPeopleTap();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
