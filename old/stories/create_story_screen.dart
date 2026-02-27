import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../theme/app_theme.dart';
import '../../services/story_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final StoryService _storyService = StoryService();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  XFile? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isUploading = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _showMediaSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
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
                'Create Reflection',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryTeal),
                title: const Text('Take Photo', style: TextStyle(color: AppTheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: AppTheme.primaryCoral),
                title: const Text('Record Video', style: TextStyle(color: AppTheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryTeal),
                title: const Text('Choose Photo from Gallery', style: TextStyle(color: AppTheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: AppTheme.primaryCoral),
                title: const Text('Choose Video from Gallery', style: TextStyle(color: AppTheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        _videoController?.dispose();
        setState(() {
          _selectedImage = image;
          _selectedVideo = null;
          _videoController = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60), // Limit to 60 seconds
      );

      if (video != null) {
        _videoController?.dispose();
        final controller = VideoPlayerController.file(File(video.path));
        await controller.initialize();
        controller.setLooping(true);
        controller.play();

        setState(() {
          _selectedVideo = video;
          _selectedImage = null;
          _videoController = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createStory() async {
    if (_selectedImage == null && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image or video first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _storyService.createStory(
        imageFile: _selectedImage,
        videoFile: _selectedVideo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reflection created successfully!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create reflection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _clearSelection() {
    _videoController?.dispose();
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
      _videoController = null;
    });
  }

  bool get _hasSelection => _selectedImage != null || _selectedVideo != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Create Reflection'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                  ),
                ),
              ),
            )
          else if (_hasSelection)
            TextButton(
              onPressed: _createStory,
              child: const Text(
                'Share',
                style: TextStyle(color: AppTheme.primaryTeal, fontSize: 16),
              ),
            ),
        ],
      ),
      body: !_hasSelection
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 80,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create a reflection to share with\nyour faith community',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showMediaSourceDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add Photo or Video'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Media preview
                Center(
                  child: _selectedVideo != null && _videoController != null
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : _selectedImage != null
                          ? Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.contain,
                            )
                          : const SizedBox.shrink(),
                ),

                // Video indicator
                if (_selectedVideo != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Video',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Remove button
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.black54,
                    onPressed: _clearSelection,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),

                // Helper text
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Reflection will be visible for 24 hours',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
