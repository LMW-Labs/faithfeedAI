import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/marketplace_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_service.dart';
import '../../models/marketplace_item_model.dart';
import '../../theme/app_theme.dart';

class CreateMarketplaceItemScreen extends StatefulWidget {
  const CreateMarketplaceItemScreen({super.key});

  @override
  State<CreateMarketplaceItemScreen> createState() =>
      _CreateMarketplaceItemScreenState();
}

class _CreateMarketplaceItemScreenState
    extends State<CreateMarketplaceItemScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController(); // FIXED: Added missing controller

  final MarketplaceService _marketplaceService = MarketplaceService();
  MarketplaceCategory _selectedCategory = MarketplaceCategory.forSale;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  DateTime? _expiresAt;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _contactController.dispose(); // FIXED: Now properly declared above
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _marketplaceService.pickImages();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        // Limit to 8 images
        if (_selectedImages.length > 8) {
          _selectedImages = _selectedImages.sublist(0, 8);
        }
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final image = await _marketplaceService.pickImageFromCamera();
    if (image != null) {
      setState(() {
        if (_selectedImages.length < 5) {
          _selectedImages.add(image);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _pickExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.lightSurface,
              onSurface: AppTheme.lightOnSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiresAt = picked;
      });
    }
  }

  Future<void> _submitItem() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
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

      final itemId = await _marketplaceService.createMarketplaceItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.trim().isEmpty
            ? 'FREE'
            : _priceController.text.trim(),
        userName: userProfile.displayName,
        userProfileImageUrl: userProfile.profileImageUrl,
        category: _selectedCategory,
        images: _selectedImages.isEmpty ? null : _selectedImages,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        contactInfo: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        expiresAt: _expiresAt,
      );

      if (itemId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item posted successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to create marketplace item');
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
                    'New Listing',
                    style: TextStyle(color: Colors.white),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    TextButton(
                      onPressed: _isLoading ? null : _submitItem,
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
              // Images section
              const Text(
                'Photos (Optional)',
                style: TextStyle(
                  color: AppTheme.lightOnSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add photo button
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white.withValues(alpha: 0.95),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library,
                                      color: AppTheme.primaryBlue),
                                  title: const Text('Choose from gallery',
                                      style: TextStyle(color: AppTheme.lightOnSurface)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImages();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt,
                                      color: AppTheme.primaryBlue),
                                  title: const Text('Take a photo',
                                      style: TextStyle(color: AppTheme.lightOnSurface)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImageFromCamera();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.lightOnSurfaceMuted.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                color: AppTheme.primaryBlue),
                            SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: AppTheme.lightOnSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Selected images
                    ..._selectedImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final image = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(image.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextField(
                controller: _titleController,
                style: const TextStyle(color: AppTheme.lightOnSurface),
                decoration: InputDecoration(
                  labelText: 'Title *',
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
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<MarketplaceCategory>(
                initialValue: _selectedCategory,
                dropdownColor: Colors.white.withValues(alpha: 0.95),
                decoration: InputDecoration(
                  labelText: 'Category *',
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
                ),
                items: MarketplaceCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category.displayName,
                      style: const TextStyle(color: AppTheme.lightOnSurface),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextField(
                controller: _priceController,
                style: const TextStyle(color: AppTheme.lightOnSurface),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (leave empty for FREE)',
                  labelStyle: const TextStyle(
                    color: AppTheme.lightOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(color: AppTheme.lightOnSurface),
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
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                maxLength: 1000,
                style: const TextStyle(color: AppTheme.lightOnSurface),
                decoration: InputDecoration(
                  labelText: 'Description *',
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
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextField(
                controller: _locationController,
                style: const TextStyle(color: AppTheme.lightOnSurface),
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  labelStyle: const TextStyle(
                    color: AppTheme.lightOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: const Icon(Icons.location_on,
                      color: AppTheme.primaryBlue),
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
                ),
              ),
              const SizedBox(height: 16),

              // Contact Info
              TextField(
                controller: _contactController,
                style: const TextStyle(color: AppTheme.lightOnSurface),
                decoration: InputDecoration(
                  labelText: 'Contact Info (Optional)',
                  labelStyle: const TextStyle(
                    color: AppTheme.lightOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'Email or phone number',
                  hintStyle: const TextStyle(color: AppTheme.lightOnSurfaceVariant),
                  prefixIcon:
                      const Icon(Icons.contact_mail, color: AppTheme.primaryBlue),
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
                ),
              ),
              const SizedBox(height: 16),

              // Expiration date
              InkWell(
                onTap: _pickExpirationDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppTheme.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expiration Date (Optional)',
                              style: TextStyle(
                                color: AppTheme.lightOnSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _expiresAt == null
                                  ? 'No expiration'
                                  : '${_expiresAt!.month}/${_expiresAt!.day}/${_expiresAt!.year}',
                              style: const TextStyle(
                                color: AppTheme.lightOnSurface,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_expiresAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppTheme.lightOnSurfaceVariant),
                          onPressed: () {
                            setState(() {
                              _expiresAt = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              // Bottom padding to prevent content from being cut off
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}