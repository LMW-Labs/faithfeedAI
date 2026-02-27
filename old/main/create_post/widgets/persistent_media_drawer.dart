import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_theme.dart';

/// Persistent bottom drawer that's always visible
/// User can drag up to reveal full media options
class PersistentMediaDrawer extends StatefulWidget {
  final VoidCallback onGifTap;
  final VoidCallback onLocationTap;
  final VoidCallback onEmojiTap;
  final VoidCallback onTagPeopleTap;
  final VoidCallback onScriptureTap;
  final Gradient? selectedGradient;
  final Color? selectedColor;
  final Function(Gradient gradient, Color textColor) onGradientSelected;
  final Function(Color color, Color textColor) onColorSelected;
  final VoidCallback onClearBackground;

  const PersistentMediaDrawer({
    super.key,
    required this.onGifTap,
    required this.onLocationTap,
    required this.onEmojiTap,
    required this.onTagPeopleTap,
    required this.onScriptureTap,
    required this.selectedGradient,
    required this.selectedColor,
    required this.onGradientSelected,
    required this.onColorSelected,
    required this.onClearBackground,
  });

  @override
  State<PersistentMediaDrawer> createState() => _PersistentMediaDrawerState();
}

class _PersistentMediaDrawerState extends State<PersistentMediaDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Drawer can be collapsed (showing icon bar) or expanded (showing full grid)
  bool _isExpanded = false;

  // Height when collapsed (just showing icon bar) - made more compact
  static const double _collapsedHeight = 85.0;

  // Height when expanded (showing full grid) - tall enough to show all options
  static const double _expandedHeight = 500.0;

  // Available gradients
  final List<Map<String, dynamic>> _gradients = [
    {'name': 'Blue', 'gradient': AppTheme.primaryGradient},
    {'name': 'Sunset', 'gradient': AppTheme.aiGradient},
    {'name': 'Purple', 'gradient': AppTheme.purpleHazeGradient},
    {'name': 'Mint', 'gradient': AppTheme.mintFreshGradient},
    {'name': 'Ocean', 'gradient': AppTheme.oceanBreezeGradient},
    {'name': 'Rose', 'gradient': AppTheme.roseGoldGradient},
    {'name': 'Northern', 'gradient': AppTheme.northernLightsGradient},
    {'name': 'Cherry', 'gradient': AppTheme.cherryBlossomGradient},
    {'name': 'Deep Ocean', 'gradient': AppTheme.deepOceanGradient},
    {'name': 'Fire', 'gradient': AppTheme.fireGlowGradient},
    {'name': 'Lavender', 'gradient': AppTheme.lavenderMistGradient},
    {'name': 'Peachy', 'gradient': AppTheme.peachyKeenGradient},
    {'name': 'Sky', 'gradient': AppTheme.skyBlueGradient},
    {'name': 'Forest', 'gradient': AppTheme.forestGreenGradient},
    {'name': 'Berry', 'gradient': AppTheme.berryBlastGradient},
  ];

  // Solid colors
  final List<Map<String, dynamic>> _solidColors = [
    {'name': 'Teal', 'color': AppTheme.primaryTeal},
    {'name': 'Coral', 'color': AppTheme.primaryCoral},
    {'name': 'Yellow', 'color': AppTheme.highlightYellow},
    {'name': 'Peach', 'color': AppTheme.softPeach},
    {'name': 'Purple', 'color': const Color(0xFF8B5CF6)},
    {'name': 'Pink', 'color': const Color(0xFFEC4899)},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: _collapsedHeight,
      end: _expandedHeight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: _animation.value,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Column(
              children: [
                // Drag handle area - made more compact
                GestureDetector(
                  onTap: _toggleDrawer,
                  onVerticalDragUpdate: (details) {
                    // Drag down to collapse, drag up to expand
                    if (details.primaryDelta! > 5 && _isExpanded) {
                      _toggleDrawer();
                    } else if (details.primaryDelta! < -5 && !_isExpanded) {
                      _toggleDrawer();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Chevron icon - smaller
                        FaIcon(
                          _isExpanded ? FontAwesomeIcons.squareCaretDown : FontAwesomeIcons.squareCaretUp,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                // Content area
                Expanded(
                  child: _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Collapsed view - horizontal scrolling gradient bar + icon bar
  Widget _buildCollapsedContent() {
    final hasBackground = widget.selectedGradient != null ||
        (widget.selectedColor != null && widget.selectedColor != AppTheme.surface);

    return Column(
      children: [
        // Horizontal gradient picker
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Clear button (shown when background is selected)
              if (hasBackground) ...[
                GestureDetector(
                  onTap: widget.onClearBackground,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.format_color_reset,
                        color: AppTheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
              // Gradients
              ..._gradients.map((gradientData) {
                final gradient = gradientData['gradient'] as Gradient;
                final isSelected = widget.selectedGradient == gradient;

                return GestureDetector(
                  onTap: () => widget.onGradientSelected(gradient, Colors.white),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        : null,
                  ),
                );
              }),
              // Solid colors
              ..._solidColors.map((colorData) {
                final color = colorData['color'] as Color;
                final isSelected = widget.selectedColor == color &&
                    widget.selectedGradient == null;

                return GestureDetector(
                  onTap: () {
                    final textColor = color == AppTheme.highlightYellow ||
                            color == AppTheme.softPeach
                        ? Colors.black
                        : Colors.white;
                    widget.onColorSelected(color, textColor);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Icons.check,
                              color: color == AppTheme.highlightYellow ||
                                      color == AppTheme.softPeach
                                  ? Colors.black
                                  : Colors.white,
                              size: 18,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Icon bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickIcon(
                icon: FontAwesomeIcons.bookBible,
                label: 'Scripture',
                color: AppTheme.primaryBlue,
                onTap: widget.onScriptureTap,
                isFontAwesome: true,
              ),
              _buildQuickIcon(
                icon: FontAwesomeIcons.locationDot,
                label: 'Location',
                color: AppTheme.primaryBlue,
                onTap: widget.onLocationTap,
                isFontAwesome: true,
              ),
              _buildQuickIcon(
                icon: FontAwesomeIcons.fileImage,
                label: 'GIF',
                color: AppTheme.primaryBlue,
                onTap: widget.onGifTap,
                isFontAwesome: true,
              ),
              _buildQuickIcon(
                icon: FontAwesomeIcons.userPlus,
                label: 'Tag',
                color: AppTheme.primaryBlue,
                onTap: widget.onTagPeopleTap,
                isFontAwesome: true,
              ),
              _buildQuickIcon(
                icon: FontAwesomeIcons.faceSmile,
                label: 'Emoji',
                color: AppTheme.primaryBlue,
                onTap: widget.onEmojiTap,
                isFontAwesome: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Expanded view - full-width stacked buttons
  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          const Text(
            'Add to your post',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Scripture at top
                  _buildFullWidthOption(
                    icon: FontAwesomeIcons.bookBible,
                    label: 'Add Scripture Reference',
                    color: AppTheme.primaryBlue,
                    onTap: widget.onScriptureTap,
                    isFontAwesome: true,
                  ),
                  const SizedBox(height: 8),
                  _buildFullWidthOption(
                    icon: FontAwesomeIcons.fileImage,
                    label: 'Add GIF',
                    color: AppTheme.primaryBlue,
                    onTap: widget.onGifTap,
                    isFontAwesome: true,
                  ),
                  const SizedBox(height: 8),
                  _buildFullWidthOption(
                    icon: FontAwesomeIcons.locationDot,
                    label: 'Add Location',
                    color: AppTheme.primaryBlue,
                    onTap: widget.onLocationTap,
                    isFontAwesome: true,
                  ),
                  const SizedBox(height: 8),
                  _buildFullWidthOption(
                    icon: FontAwesomeIcons.faceSmile,
                    label: 'Add Emoji',
                    color: AppTheme.primaryBlue,
                    onTap: widget.onEmojiTap,
                    isFontAwesome: true,
                  ),
                  const SizedBox(height: 8),
                  _buildFullWidthOption(
                    icon: FontAwesomeIcons.userPlus,
                    label: 'Tag People',
                    color: AppTheme.primaryBlue,
                    onTap: widget.onTagPeopleTap,
                    isFontAwesome: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFontAwesome = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isFontAwesome
                ? FaIcon(icon, color: color, size: 24)
                : Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthOption({
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFontAwesome = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            isFontAwesome
                ? FaIcon(icon, color: color, size: 24)
                : Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
