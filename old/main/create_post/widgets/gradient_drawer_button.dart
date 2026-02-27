import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_theme.dart';

/// A floating button that expands to reveal gradient options
/// Opens downward as a 3-column scrollable grid
class GradientDrawerButton extends StatefulWidget {
  final Gradient? selectedGradient;
  final Color? selectedColor;
  final Function(Gradient gradient, Color textColor) onGradientSelected;
  final Function(Color color, Color textColor) onColorSelected;
  final VoidCallback onClearBackground;

  const GradientDrawerButton({
    super.key,
    required this.selectedGradient,
    required this.selectedColor,
    required this.onGradientSelected,
    required this.onColorSelected,
    required this.onClearBackground,
  });

  @override
  State<GradientDrawerButton> createState() => _GradientDrawerButtonState();
}

class _GradientDrawerButtonState extends State<GradientDrawerButton> {
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;

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
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isExpanded = false;
    });
  }

  void _toggleDrawer() {
    if (_isExpanded) {
      _removeOverlay();
    } else {
      _showColorPicker();
    }
  }

  void _showColorPicker() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    setState(() {
      _isExpanded = true;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to close on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Color picker grid positioned below the button
          Positioned(
            top: offset.dy + 52, // Position below button with 8px gap
            right: 16, // Align with right edge
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                constraints: const BoxConstraints(maxHeight: 350),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Background Colors',
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // 3-column grid for all colors
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1,
                          children: [
                            // Gradients
                            ..._gradients.map((gradientData) {
                              final gradient = gradientData['gradient'] as Gradient;
                              final isSelected = widget.selectedGradient == gradient;

                              return GestureDetector(
                                onTap: () {
                                  widget.onGradientSelected(gradient, Colors.white);
                                  _removeOverlay();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: gradient,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryTeal
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
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
                                  _removeOverlay();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryTeal
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final hasBackground = widget.selectedGradient != null ||
                         (widget.selectedColor != null && widget.selectedColor != AppTheme.surface);

    return InkWell(
      onTap: _toggleDrawer,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: hasBackground
              ? (widget.selectedGradient ?? LinearGradient(
                  colors: [widget.selectedColor!, widget.selectedColor!],
                ))
              : null,
          color: hasBackground ? null : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isExpanded
                ? AppTheme.primaryTeal
                : AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: _isExpanded
              ? Icon(
                  Icons.close,
                  color: hasBackground ? Colors.white : AppTheme.primaryTeal,
                  size: 20,
                )
              : FaIcon(
                  FontAwesomeIcons.paintbrush,
                  color: hasBackground ? Colors.white : AppTheme.primaryTeal,
                  size: 18,
                ),
        ),
      ),
    );
  }
}
