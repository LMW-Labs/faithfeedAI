import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../services/post_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/business_page_service.dart';
import '../../services/video_service.dart';
import '../../services/gif_service.dart';
import '../../services/friends_service.dart';
import '../../services/logger_service.dart';
import '../../models/friend_model.dart';
import 'package:video_player/video_player.dart';
// New modular widgets
import 'create_post/widgets/post_text_input.dart';
import 'create_post/widgets/floating_action_buttons.dart';
import 'create_post/widgets/persistent_media_drawer.dart';
import 'create_post/widgets/ai_content_generator_modal.dart';
import 'create_post/widgets/hashtag_button.dart';

enum PostAudience { public, community, private }

extension PostAudienceX on PostAudience {
  String get label {
    switch (this) {
      case PostAudience.public:
        return 'Public';
      case PostAudience.community:
        return 'Community';
      case PostAudience.private:
        return 'Only me';
    }
  }

  IconData get icon {
    switch (this) {
      case PostAudience.public:
        return Icons.public;
      case PostAudience.community:
        return Icons.people_alt_outlined;
      case PostAudience.private:
        return Icons.lock_outline;
    }
  }
}

class CreatePostModal extends StatefulWidget {
  final String? initialContent;
  final String? initialScriptureReference;

  const CreatePostModal({
    super.key,
    this.initialContent,
    this.initialScriptureReference,
  });

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  // Controllers
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _scriptureController = TextEditingController();

  // Services
  final VideoService _videoService = VideoService();

  // Media state
  XFile? _selectedImage;
  XFile? _selectedVideo;
  VideoPlayerController? _videoPlayerController;
  String? _gifUrl;

  // Post state
  bool _isPosting = false;

  // Styling state
  Color _backgroundColor = AppTheme.surface;
  Color _textColor = AppTheme.onSurface;
  bool _isBold = false;
  bool _isItalic = false;
  Gradient? _backgroundGradient;

  // Post metadata
  List<Map<String, dynamic>> _taggedUsers = [];
  Map<String, dynamic>? _location;
  PostAudience _audience = PostAudience.public;
  String? _selectedAlbum;
  bool _shareToStories = false;
  bool _allowComments = true;
  bool _aiLabelEnabled = false;

  // UI state
  List<String> _hashtagSuggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    if (widget.initialScriptureReference != null) {
      _scriptureController.text = widget.initialScriptureReference!;
    }

    // Listen to text changes for hashtag suggestions
    _contentController.addListener(_updateHashtagSuggestions);
  }

  @override
  void dispose() {
    _contentController.removeListener(_updateHashtagSuggestions);
    _contentController.dispose();
    _scriptureController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _updateHashtagSuggestions() {
    final suggestions = HashtagButton.getSuggestions(
      _contentController.text,
      _contentController.selection.baseOffset,
    );
    if (suggestions.length != _hashtagSuggestions.length) {
      setState(() {
        _hashtagSuggestions = suggestions;
      });
    }
  }

  void _applyHashtagSuggestion(String tag) {
    final text = _contentController.text;
    final cursorPosition = _contentController.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPosition);
    final hashIndex = beforeCursor.lastIndexOf('#');

    if (hashIndex != -1) {
      final newText = text.replaceRange(
        hashIndex + 1,
        cursorPosition,
        '$tag ',
      );

      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: hashIndex + tag.length + 2),
      );
    }
  }

  // Media picking functions
  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
        _selectedVideo = null;
        _gifUrl = null;
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (video != null) {
      final controller = VideoPlayerController.file(File(video.path));
      await controller.initialize();

      setState(() {
        _selectedVideo = video;
        _selectedImage = null;
        _gifUrl = null;
        _videoPlayerController = controller;
      });
    }
  }

  void _showGifPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GifPickerSheet(
        onGifSelected: (gifUrl) {
          setState(() {
            _gifUrl = gifUrl;
            _selectedImage = null;
            _selectedVideo = null;
            _videoPlayerController?.dispose();
            _videoPlayerController = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LocationPickerSheet(
        currentLocation: _location,
        onLocationSelected: (location) {
          setState(() {
            _location = location;
          });
          Navigator.pop(context);
        },
        onLocationCleared: () {
          setState(() {
            _location = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: 350,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            // Insert emoji at cursor position
            final text = _contentController.text;
            final selection = _contentController.selection;
            final newText = text.replaceRange(
              selection.start,
              selection.end,
              emoji.emoji,
            );
            _contentController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                offset: selection.start + emoji.emoji.length,
              ),
            );
          },
          config: Config(
            height: 350,
            emojiViewConfig: EmojiViewConfig(
              columns: 8,
              emojiSizeMax: 28,
              backgroundColor: AppTheme.surface,
            ),
            categoryViewConfig: CategoryViewConfig(
              backgroundColor: AppTheme.surface,
              indicatorColor: AppTheme.primaryTeal,
              iconColorSelected: AppTheme.primaryTeal,
              iconColor: AppTheme.onSurfaceVariant,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
            searchViewConfig: SearchViewConfig(
              backgroundColor: AppTheme.surface,
              buttonIconColor: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _showTagPeoplePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TagPeopleSheet(
        onTagSelected: (friend) {
          // Insert @mention at cursor position
          final text = _contentController.text;
          final selection = _contentController.selection;
          final mention = '@${friend.username.isNotEmpty ? friend.username : friend.displayName} ';
          final newText = text.replaceRange(
            selection.start,
            selection.end,
            mention,
          );
          _contentController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: selection.start + mention.length,
            ),
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showScripturePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text(
          'Add Scripture Reference',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        content: TextField(
          controller: _scriptureController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., John 3:16',
            prefixIcon: Icon(Icons.menu_book, color: AppTheme.primaryTeal),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAIContentGenerator() {
    AIContentGeneratorModal.show(
      context,
      initialScriptureReference: _scriptureController.text.trim(),
      onIdeaSelected: (content, scripture, aiGenerated) {
        setState(() {
          _contentController.text = content;
          if (scripture != null) {
            _scriptureController.text = scripture;
          }
          _aiLabelEnabled = aiGenerated;
        });
      },
    );
  }

  void _showAttachMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add Media',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
                ),
                title: const Text('Photo', style: TextStyle(color: AppTheme.onSurface)),
                subtitle: const Text('Choose from gallery', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCoral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.videocam, color: AppTheme.primaryCoral),
                ),
                title: const Text('Video', style: TextStyle(color: AppTheme.onSurface)),
                subtitle: const Text('Choose from gallery', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.highlightYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gif_box, color: AppTheme.highlightYellow),
                ),
                title: const Text('GIF', style: TextStyle(color: AppTheme.onSurface)),
                subtitle: const Text('Search for a GIF', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                onTap: () {
                  Navigator.pop(context);
                  _showGifPicker();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _clearBackground() {
    setState(() {
      _backgroundGradient = null;
      _backgroundColor = AppTheme.surface;
      _textColor = AppTheme.onSurface;
    });
  }

  // Extract hashtags from content
  List<String> _extractHashtags(String content) {
    final hashtagRegex = RegExp(r'#(\w+)');
    final matches = hashtagRegex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  // Create post
  Future<void> _createPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something before posting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final postService = PostService();
      final profileService = Provider.of<UserProfileService>(context, listen: false);
      final businessPageService = Provider.of<BusinessPageService>(context, listen: false);

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await profileService.uploadPostImage(_selectedImage!);
      }

      // Upload video if selected
      String? videoUrl;
      if (_selectedVideo != null) {
        videoUrl = await _videoService.uploadPostVideo(
          _selectedVideo!,
          onProgress: (progress) {
            // Progress feedback
          },
        );
      }

      // Extract hashtags
      final hashtags = _extractHashtags(content);

      // Convert gradient to serializable format
      Map<String, dynamic>? gradientData;
      if (_backgroundGradient != null && _backgroundGradient is LinearGradient) {
        final linearGradient = _backgroundGradient as LinearGradient;
        gradientData = {
          'type': 'linear',
          'colors': linearGradient.colors.map((c) => c.toARGB32()).toList(),
        };
      }

      // Create the post
      await postService.createPost(
        content: content,
        scriptureReference: _scriptureController.text.trim().isNotEmpty
            ? _scriptureController.text.trim()
            : null,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        taggedUsers: _taggedUsers.isEmpty ? null : _taggedUsers,
        location: _location,
        gifUrl: _gifUrl,
        hashtags: hashtags.isEmpty ? null : hashtags,
        businessPageService: businessPageService,
        audience: _audience.label,
        album: _selectedAlbum,
        shareToStories: _shareToStories,
        allowComments: _allowComments,
        aiGenerated: _aiLabelEnabled,
        backgroundColor: _backgroundGradient == null ? _backgroundColor.toARGB32() : null,
        textColor: _textColor.toARGB32(),
        isBold: _isBold,
        isItalic: _isItalic,
        backgroundGradient: gradientData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
        // Return true to signal successful post creation
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGradientBackground = _backgroundGradient != null ||
        (_backgroundColor != AppTheme.surface && _backgroundColor != Colors.transparent);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Reduced spacing to prevent overflow
            const SizedBox(height: 12),

            // Header
            _buildHeader(),

            // Main content area
            Expanded(
              child: Stack(
                children: [
                  // Text input area (full width)
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          children: [
                            PostTextInput(
                              controller: _contentController,
                              hasGradientBackground: hasGradientBackground,
                              backgroundGradient: _backgroundGradient,
                              backgroundColor: _backgroundColor,
                              textColor: _textColor,
                              isBold: _isBold,
                              isItalic: _isItalic,
                            ),

                            // Floating action buttons (bottom-right corner inside text input)
                            FloatingActionButtons(
                              selectedGradient: _backgroundGradient,
                              selectedColor: _backgroundColor != AppTheme.surface ? _backgroundColor : null,
                              onGradientSelected: (gradient, textColor) {
                                setState(() {
                                  _backgroundGradient = gradient;
                                  _backgroundColor = Colors.transparent;
                                  _textColor = textColor;
                                });
                              },
                              onColorSelected: (color, textColor) {
                                setState(() {
                                  _backgroundColor = color;
                                  _backgroundGradient = null;
                                  _textColor = textColor;
                                });
                              },
                              onClearBackground: _clearBackground,
                              textController: _contentController,
                              onHashtagInserted: () {
                                // Trigger UI update for hashtag suggestions
                                setState(() {
                                  _updateHashtagSuggestions();
                                });
                              },
                              onAIIdeasPressed: _showAIContentGenerator,
                              isAIActive: _aiLabelEnabled,
                              onAttachMediaPressed: _showAttachMediaPicker,
                            ),
                          ],
                        ),

                        // Hashtag suggestions
                        if (_hashtagSuggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: HashtagSuggestions(
                              suggestions: _hashtagSuggestions,
                              onSuggestionTap: _applyHashtagSuggestion,
                            ),
                          ),

                        // Media previews
                        if (_selectedImage != null || _selectedVideo != null || _gifUrl != null)
                          _buildMediaPreview(),

                        // Add space for persistent drawer
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),

                  // Persistent media drawer (always visible at bottom)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: PersistentMediaDrawer(
                      onGifTap: _showGifPicker,
                      onLocationTap: _showLocationPicker,
                      onEmojiTap: _showEmojiPicker,
                      onTagPeopleTap: _showTagPeoplePicker,
                      onScriptureTap: _showScripturePicker,
                      selectedGradient: _backgroundGradient,
                      selectedColor: _backgroundColor != AppTheme.surface ? _backgroundColor : null,
                      onGradientSelected: (gradient, textColor) {
                        setState(() {
                          _backgroundGradient = gradient;
                          _backgroundColor = Colors.transparent;
                          _textColor = textColor;
                        });
                      },
                      onColorSelected: (color, textColor) {
                        setState(() {
                          _backgroundColor = color;
                          _backgroundGradient = null;
                          _textColor = textColor;
                        });
                      },
                      onClearBackground: _clearBackground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ),

          const Spacer(),

          // Title
          const Text(
            'Create Post',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Post button
          ElevatedButton(
            onPressed: _isPosting ? null : _createPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Post'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_selectedImage!.path),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else if (_selectedVideo != null && _videoPlayerController != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              ),
            )
          else if (_gifUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _gifUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: AppTheme.surfaceElevated,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                    ),
                  );
                },
              ),
            ),

          // Remove media button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _selectedVideo = null;
                  _gifUrl = null;
                  _videoPlayerController?.dispose();
                  _videoPlayerController = null;
                });
              },
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Import HashtagSuggestions widget
class HashtagSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;

  const HashtagSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((tag) {
          return InkWell(
            onTap: () => onSuggestionTap(tag),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(
                    Icons.tag,
                    size: 16,
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#$tag',
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// GIF Picker Bottom Sheet
class _GifPickerSheet extends StatefulWidget {
  final Function(String gifUrl) onGifSelected;

  const _GifPickerSheet({required this.onGifSelected});

  @override
  State<_GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<_GifPickerSheet> {
  final GifService _gifService = GifService();
  final TextEditingController _searchController = TextEditingController();
  List<GifResult> _gifs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrendingGifs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingGifs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gifs = await _gifService.getTrendingGifs(limit: 30);
      if (mounted) {
        setState(() {
          _gifs = gifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load GIFs';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty) {
      _loadTrendingGifs();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gifs = await _gifService.searchGifs(query, limit: 30);
      if (mounted) {
        setState(() {
          _gifs = gifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search GIFs';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Choose a GIF',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search GIFs...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadTrendingGifs();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: _searchGifs,
              ),
            ),

            // Category chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _gifService.getFaithCategories().map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(category),
                      onPressed: () {
                        _searchController.text = category;
                        _searchGifs(category);
                      },
                      backgroundColor: AppTheme.surfaceElevated,
                      labelStyle: const TextStyle(color: AppTheme.onSurface),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // GIF grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: AppTheme.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text(_error!,
                                  style: const TextStyle(color: AppTheme.onSurfaceVariant)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTrendingGifs,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _gifs.isEmpty
                          ? const Center(
                              child: Text(
                                'No GIFs found',
                                style: TextStyle(color: AppTheme.onSurfaceVariant),
                              ),
                            )
                          : GridView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _gifs.length,
                              itemBuilder: (context, index) {
                                final gif = _gifs[index];
                                return GestureDetector(
                                  onTap: () => widget.onGifSelected(gif.gifUrl),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      gif.previewUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: AppTheme.surfaceElevated,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.primaryTeal,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppTheme.surfaceElevated,
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
            ),

            // Tenor attribution
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Powered by ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    'Tenor',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bottom sheet for tagging people in posts
class _TagPeopleSheet extends StatefulWidget {
  final Function(Friend) onTagSelected;

  const _TagPeopleSheet({required this.onTagSelected});

  @override
  State<_TagPeopleSheet> createState() => _TagPeopleSheetState();
}

class _TagPeopleSheetState extends State<_TagPeopleSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FriendsService _friendsService = FriendsService();
  List<Friend> _searchResults = [];
  List<Friend> _friends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _friendsService.getFriends();
      setState(() {
        _friends = friends;
        _searchResults = friends;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = _friends);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _friendsService.searchUsers(query);
      setState(() => _searchResults = results);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tag People',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Results list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            'No friends found',
                            style: TextStyle(color: AppTheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final friend = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: friend.profileImageUrl.isNotEmpty
                                    ? NetworkImage(friend.profileImageUrl)
                                    : null,
                                backgroundColor: AppTheme.primaryTeal,
                                child: friend.profileImageUrl.isEmpty
                                    ? Text(
                                        friend.displayName.isNotEmpty
                                            ? friend.displayName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                              title: Text(
                                friend.displayName,
                                style: const TextStyle(color: AppTheme.onSurface),
                              ),
                              subtitle: friend.username.isNotEmpty
                                  ? Text(
                                      '@${friend.username}',
                                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                                    )
                                  : null,
                              onTap: () => widget.onTagSelected(friend),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

/// Bottom sheet for adding location to posts
class _LocationPickerSheet extends StatefulWidget {
  final Map<String, dynamic>? currentLocation;
  final Function(Map<String, dynamic>) onLocationSelected;
  final VoidCallback onLocationCleared;

  const _LocationPickerSheet({
    this.currentLocation,
    required this.onLocationSelected,
    required this.onLocationCleared,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final TextEditingController _customLocationController = TextEditingController();
  bool _isGettingLocation = false;
  String? _errorMessage;

  // Common location suggestions
  final List<Map<String, dynamic>> _suggestions = [
    {'name': 'Church', 'icon': Icons.church},
    {'name': 'Home', 'icon': Icons.home},
    {'name': 'Bible Study', 'icon': Icons.menu_book},
    {'name': 'Youth Group', 'icon': Icons.groups},
    {'name': 'Small Group', 'icon': Icons.group},
    {'name': 'Conference', 'icon': Icons.event},
    {'name': 'Retreat', 'icon': Icons.landscape},
    {'name': 'Mission Trip', 'icon': Icons.flight},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      _customLocationController.text = widget.currentLocation!['name'] ?? '';
    }
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them in settings.';
          _isGettingLocation = false;
        });
        return;
      }

      // Check for permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied. Please allow location access.';
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission permanently denied. Please enable in app settings.';
          _isGettingLocation = false;
        });
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      Log.d('Got location: ${position.latitude}, ${position.longitude}');

      // For now, just use coordinates. In production, you'd use reverse geocoding
      final locationData = {
        'name': 'Current Location',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'displayText': '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      };

      widget.onLocationSelected(locationData);
    } catch (e) {
      Log.e('Error getting location: $e');
      setState(() {
        _errorMessage = 'Could not get your location. Please try again.';
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  void _selectCustomLocation() {
    final text = _customLocationController.text.trim();
    if (text.isEmpty) return;

    widget.onLocationSelected({
      'name': text,
      'displayText': text,
    });
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    widget.onLocationSelected({
      'name': suggestion['name'],
      'displayText': suggestion['name'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primaryTeal),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Add Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              if (widget.currentLocation != null)
                TextButton(
                  onPressed: widget.onLocationCleared,
                  child: const Text('Clear', style: TextStyle(color: AppTheme.primaryCoral)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Current location button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGettingLocation ? null : _getCurrentLocation,
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_isGettingLocation ? 'Getting location...' : 'Use Current Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryTeal,
                side: const BorderSide(color: AppTheme.primaryTeal),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.primaryCoral, fontSize: 13),
            ),
          ],

          const SizedBox(height: 16),

          // Custom location input
          TextField(
            controller: _customLocationController,
            style: const TextStyle(color: AppTheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter a location name...',
              hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
              prefixIcon: const Icon(Icons.edit_location_alt, color: AppTheme.onSurfaceVariant),
              suffixIcon: IconButton(
                onPressed: _selectCustomLocation,
                icon: const Icon(Icons.check, color: AppTheme.primaryTeal),
              ),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _selectCustomLocation(),
          ),
          const SizedBox(height: 16),

          // Quick suggestions
          const Text(
            'Quick Add',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((suggestion) {
              return ActionChip(
                avatar: Icon(
                  suggestion['icon'] as IconData,
                  size: 16,
                  color: AppTheme.primaryTeal,
                ),
                label: Text(suggestion['name'] as String),
                labelStyle: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
                backgroundColor: AppTheme.surfaceElevated,
                onPressed: () => _selectSuggestion(suggestion),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
