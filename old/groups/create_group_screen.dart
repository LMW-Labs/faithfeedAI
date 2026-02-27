import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final GroupService _groupService = GroupService();

  String _selectedCategory = 'Prayer Group';
  bool _isPublic = true;
  bool _requiresApproval = false;
  int? _maxMembers = 50;
  bool _noMemberLimit = false;
  final _maxMembersController = TextEditingController(text: '50');
  bool _isLoading = false;

  // Images
  XFile? _bannerImage;
  XFile? _profileImage;

  // Rules
  final List<TextEditingController> _rulesControllers = [TextEditingController()];

  // Meeting Schedule
  bool _hasSchedule = false;
  String _selectedDay = 'Sunday';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  bool _isRecurring = true;

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMembersController.dispose();
    for (final controller in _rulesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic>? meetingSchedule;
    if (_hasSchedule) {
      meetingSchedule = {
        'day': _selectedDay,
        'time': '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'recurring': _isRecurring,
      };
    }

    // Collect non-empty rules
    final rules = _rulesControllers
        .map((c) => c.text.trim())
        .where((r) => r.isNotEmpty)
        .toList();

    final groupId = await _groupService.createGroup(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      isPublic: _isPublic,
      requiresApproval: _requiresApproval,
      maxMembers: _noMemberLimit ? 999999 : (_maxMembers ?? 50),
      meetingSchedule: meetingSchedule,
      rules: rules,
    );

    if (!mounted) return;

    if (groupId != null) {
      // Upload images if selected
      if (_bannerImage != null) {
        await _groupService.uploadGroupBannerImage(groupId, _bannerImage!);
      }
      if (_profileImage != null) {
        await _groupService.uploadGroupProfilePicture(groupId, _profileImage!);
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created successfully!'),
          backgroundColor: AppTheme.mintGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create group'),
          backgroundColor: AppTheme.primaryCoral,
        ),
      );
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: Text(
            'Create New Group',
            style: TextStyle(color: AppTheme.lightOnSurface),
          ),
          iconTheme: IconThemeData(color: AppTheme.lightOnSurface),
        ),
        body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group Name
            _buildSectionTitle('Group Details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Group Name',
                labelStyle: const TextStyle(color: AppTheme.lightOnSurface, fontWeight: FontWeight.w500),
                floatingLabelStyle: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'e.g., Tuesday Night Bible Study',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                prefixIcon: const Icon(Icons.groups, color: AppTheme.primaryTeal),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: const TextStyle(color: AppTheme.lightOnSurface, fontWeight: FontWeight.w500),
                floatingLabelStyle: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Tell people what this group is about...',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                ),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Group Images
            _buildSectionTitle('Group Images (Optional)'),
            const SizedBox(height: 12),

            // Banner Image Picker
            GestureDetector(
              onTap: () async {
                final image = await _groupService.pickImageFromGallery();
                if (image != null) {
                  setState(() => _bannerImage = image);
                }
              },
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  image: _bannerImage != null
                      ? DecorationImage(
                          image: FileImage(File(_bannerImage!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _bannerImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: AppTheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text('Add Banner Image', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _bannerImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Profile Image Picker
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final image = await _groupService.pickImageFromGallery();
                    if (image != null) {
                      setState(() => _profileImage = image);
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                      image: _profileImage != null
                          ? DecorationImage(
                              image: FileImage(File(_profileImage!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImage == null
                        ? Icon(Icons.camera_alt, color: AppTheme.onSurfaceVariant)
                        : Stack(
                            children: [
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _profileImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Group Icon', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 24),

            // Category
            _buildSectionTitle('Category'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.onSurfaceVariant.withValues(alpha:0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: AppTheme.onSurface, fontSize: 16),
                  items: GroupService.categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category, style: const TextStyle(color: AppTheme.onSurface)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Settings
            _buildSectionTitle('Settings'),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Public Group',
              subtitle: 'Anyone can find and join this group',
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Require Approval',
              subtitle: 'Admin must approve new members',
              value: _requiresApproval,
              onChanged: (value) => setState(() => _requiresApproval = value),
            ),
            const SizedBox(height: 16),

            // Max Members
            Text(
              'Maximum Members',
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // No limit checkbox
                Checkbox(
                  value: _noMemberLimit,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (value) {
                    setState(() {
                      _noMemberLimit = value ?? false;
                      if (_noMemberLimit) {
                        _maxMembers = null;
                        _maxMembersController.clear();
                      } else {
                        _maxMembers = 50;
                        _maxMembersController.text = '50';
                      }
                    });
                  },
                ),
                const Text(
                  'No limit',
                  style: TextStyle(color: AppTheme.onSurface, fontSize: 14),
                ),
                const SizedBox(width: 24),
                // Integer input
                Expanded(
                  child: TextFormField(
                    controller: _maxMembersController,
                    enabled: !_noMemberLimit,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: _noMemberLimit ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Max members',
                      labelStyle: const TextStyle(color: AppTheme.lightOnSurface, fontWeight: FontWeight.w500),
                      floatingLabelStyle: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: 'e.g., 50',
                      hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                      filled: true,
                      fillColor: _noMemberLimit ? AppTheme.surface.withValues(alpha: 0.5) : AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() => _maxMembers = parsed);
                      }
                    },
                    validator: (value) {
                      if (_noMemberLimit) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a number';
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed < 2) {
                        return 'Min 2 members';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Group Rules
            _buildSectionTitle('Group Rules (Optional)'),
            const SizedBox(height: 12),
            ..._buildRulesInputs(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _rulesControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add, color: AppTheme.primaryTeal),
              label: const Text('Add Rule', style: TextStyle(color: AppTheme.primaryTeal)),
            ),
            const SizedBox(height: 24),

            // Meeting Schedule
            _buildSectionTitle('Meeting Schedule (Optional)'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Set Regular Meeting Time', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
              subtitle: const Text('Schedule recurring video sessions', style: TextStyle(color: AppTheme.onSurfaceVariant)),
              value: _hasSchedule,
              activeColor: AppTheme.primaryTeal,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _hasSchedule = value),
            ),

            if (_hasSchedule) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.onSurfaceVariant.withValues(alpha:0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDay,
                          isExpanded: true,
                          dropdownColor: AppTheme.surface,
                          style: const TextStyle(color: AppTheme.onSurface, fontSize: 16),
                          items: _weekDays.map((day) {
                            return DropdownMenuItem(
                              value: day,
                              child: Text(day, style: const TextStyle(color: AppTheme.onSurface)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedDay = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.onSurfaceVariant.withValues(alpha:0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, color: AppTheme.primaryTeal),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Recurring Weekly', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
                value: _isRecurring,
                activeColor: AppTheme.primaryTeal,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _isRecurring = value),
              ),
            ],

            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Group',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            // Bottom safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.lightOnSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.onSurfaceVariant.withValues(alpha:0.3)),
      ),
      child: SwitchListTile(
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
        activeColor: AppTheme.primaryTeal,
        onChanged: onChanged,
      ),
    );
  }

  List<Widget> _buildRulesInputs() {
    return _rulesControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Rule ${index + 1}',
                  labelStyle: const TextStyle(color: AppTheme.lightOnSurface, fontWeight: FontWeight.w500),
                  floatingLabelStyle: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'e.g., Be respectful',
                  hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                  ),
                ),
              ),
            ),
            if (_rulesControllers.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryCoral),
                onPressed: () {
                  setState(() {
                    _rulesControllers[index].dispose();
                    _rulesControllers.removeAt(index);
                  });
                },
              ),
          ],
        ),
      );
    }).toList();
  }
}
