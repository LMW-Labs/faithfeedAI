import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:flutter/services.dart';
import '../../../models/devotional_theme.dart';
import '../../../services/ai_library_service.dart';
import '../../../services/openai_service.dart';
import '../../../theme/app_theme.dart';
import '../ai_library_screen.dart';

class DevotionalGeneratorScreen extends StatefulWidget {
  const DevotionalGeneratorScreen({super.key});

  @override
  State<DevotionalGeneratorScreen> createState() =>
      _DevotionalGeneratorScreenState();
}

class _DevotionalGeneratorScreenState extends State<DevotionalGeneratorScreen> {
  final AILibraryService _aiLibraryService = AILibraryService();
  final OpenAIService _openAI = OpenAIService();

  String? _selectedCategory;
  DevotionalTheme? _selectedTheme;
  String _searchQuery = '';
  String? _devotional;
  bool _isLoading = false;

  List<DevotionalTheme> get _filteredThemes {
    if (_searchQuery.isNotEmpty) {
      return DevotionalThemes.search(_searchQuery);
    } else if (_selectedCategory != null) {
      return DevotionalThemes.getByCategory(_selectedCategory!);
    }
    return [];
  }

  Future<void> _generateDevotional() async {
    Log.d('🔵 Generate button pressed');
    Log.d('🔵 Selected theme: ${_selectedTheme?.name}');
    Log.d('🔵 OpenAI configured: ${_openAI.isConfigured}');

    if (_selectedTheme == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a theme first'),
          backgroundColor: AppTheme.primaryCoral,
        ),
      );
      return;
    }
    if (!_openAI.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OpenAI key missing. Add OPENAI_API_KEY to .env'),
          backgroundColor: AppTheme.primaryCoral,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _devotional = null;
    });

    try {
      final devotionalText = await _openAI.chat(
        messages: [
          {
            'role': 'system',
            'content':
                'You are a warm, concise devotional writer. Craft a 3-4 paragraph devotional with a short prayer and 2 reflection prompts. Keep it biblically faithful, encouraging, and under 300 words.',
          },
          {
            'role': 'user',
            'content':
                'Theme: ${_selectedTheme!.name}\nDescription: ${_selectedTheme!.description}\nInclude 2-3 scripture references inline.',
          },
        ],
        maxTokens: 700,
        temperature: 0.45,
      );

      // Save to AI Library
      if (devotionalText.isNotEmpty) {
        await _aiLibraryService.saveDevotional(
          title: _selectedTheme!.name,
          content: devotionalText,
          theme: _selectedTheme!.name,
        );

        if (mounted) {
          setState(() {
            _devotional = devotionalText;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate devotional: $e')),
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
    return Scaffold(
      backgroundColor: AppTheme.darkBackground, // Base background for frosted theme
      appBar: AppBar(
        backgroundColor: AppTheme.surface, // Frosted theme AppBar background
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure light status bar icons
        title: const Text(
          'Devotional Generator',
          style: TextStyle(color: AppTheme.onSurface), // Readable title text color
        ),
        iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions
                  const Text(
                    'Choose a theme for your daily devotional',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.onSurface, // Readable text color
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    style: const TextStyle(color: AppTheme.onSurface), // Readable input text
                    decoration: InputDecoration(
                      labelText: 'Search themes',
                      labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant), // Readable label
                      hintText: 'Try "faith", "anxiety", "marriage"...',
                      hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.7)), // Readable hint
                      prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant), // Readable icon
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.onSurfaceVariant), // Readable icon
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _selectedTheme = null;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surface, // Consistent background
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder( // Explicitly define enabled border
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder( // Explicitly define focused border
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _selectedTheme = null;
                        if (value.isNotEmpty) {
                          _selectedCategory = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown (only show if not searching)
                  if (_searchQuery.isEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      dropdownColor: AppTheme.surface, // Consistent background
                      style: const TextStyle(color: AppTheme.onSurface), // Readable selected text
                      decoration: InputDecoration(
                        labelText: 'Select Category',
                        labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant), // Readable label
                        prefixIcon: const Icon(Icons.category, color: AppTheme.onSurfaceVariant), // Readable icon
                        filled: true,
                        fillColor: AppTheme.surface, // Consistent background
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder( // Explicitly define enabled border
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder( // Explicitly define focused border
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                        ),
                      ),
                      items: DevotionalThemes.categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category,
                                  style: const TextStyle(fontSize: 14, color: AppTheme.onSurface), // Readable option text
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _selectedTheme = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Theme Selection (show filtered list with constrained height)
                  if (_filteredThemes.isNotEmpty) ...[
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Search Results (${_filteredThemes.length})'
                          : 'Select Theme',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant, // Readable text
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: _devotional != null ? 150 : 300,
                      ),
                      child: Card(
                        color: AppTheme.surface, // Consistent background
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.1)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredThemes.length,
                          separatorBuilder: (_, __) => const Divider(color: AppTheme.onSurfaceVariant, height: 1), // Consistent divider
                          itemBuilder: (context, index) {
                            final theme = _filteredThemes[index];
                            final isSelected = _selectedTheme?.id == theme.id;

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor:
                                  AppTheme.primaryTeal.withOpacity(0.1), // Consistent selected color
                              title: Text(
                                theme.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppTheme.primaryTeal
                                      : AppTheme.onSurface, // Readable text
                                ),
                              ),
                              subtitle: Text(
                                theme.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant, // Readable text
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primaryTeal,
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedTheme = theme;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Devotional Output
                  if (_devotional != null) ...[
                    Card(
                      color: AppTheme.surface, // Consistent background
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Your Devotional',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: AppTheme.primaryTeal),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _devotional!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied to clipboard'),
                                        backgroundColor: AppTheme.primaryTeal,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(color: AppTheme.onSurfaceVariant), // Consistent divider
                            const SizedBox(height: 12),
                            Text(
                              _devotional!,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: AppTheme.onSurfaceVariant, // Readable text
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Navigate to AI Library button
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AILibraryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.library_books),
                        label: const Text('View in My Devotionals'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryTeal,
                          side: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40), // Extra bottom padding for scroll
                  ],
                ],
              ),
            ),
          ),
          // Generate Button - Fixed at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SafeArea(
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _selectedTheme != null && !_isLoading
                          ? _generateDevotional
                          : null,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isLoading
                        ? 'Generating...'
                        : _selectedTheme == null
                            ? 'Select a theme first'
                            : 'Generate Devotional',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: AppTheme.onPrimary,
                    disabledBackgroundColor: AppTheme.darkGrey.withOpacity(0.5), // Consistent disabled color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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