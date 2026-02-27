import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/bible_data.dart';
import '../../../theme/app_theme.dart';
import '../../admin/embeddings_admin_screen.dart';

class StudyTab extends StatefulWidget {
  const StudyTab({super.key});

  @override
  State<StudyTab> createState() => _StudyTabState();
}

// 1. Add 'TickerProviderStateMixin' to handle the TabBar animation
class _StudyTabState extends State<StudyTab> with TickerProviderStateMixin {
  // Controller for the TabBar
  TabController? _tabController;

  // --- State Variables for "Search" Tab ---
  Book _selectedBook = bibleBooks.first;
  final TextEditingController _chapterController = TextEditingController(
      text: '1');
  final TextEditingController _verseController = TextEditingController(
      text: '1');
  String _displayedVerseText = 'Select a book, chapter, and verse to study.';
  String _displayedVerseReference = 'Welcome';

  // State for AI Panel
  bool _showAIPanel = false;
  final TextEditingController _aiPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 2. Initialize the TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _chapterController.dispose();
    _verseController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // If we get past the check, the rest of the code can safely assume
    // _tabController is not null by using the '!' operator.
    return Scaffold(
      backgroundColor: AppTheme.background,
      // 3. Use an AppBar to hold the title and the TabBar
      appBar: AppBar(
        title: _buildHeader(),
        toolbarHeight: 120,
        // Give space for the header text
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          // Admin button for embeddings
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmbeddingsAdminScreen(),
                ),
              );
            },
            tooltip: 'Embeddings Admin',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryCoral,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          indicatorColor: AppTheme.primaryCoral,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Verse Finder'),
            Tab(icon: Icon(Icons.menu_book), text: 'Reader'),
          ],
        ),
      ),
      // 4. Use TabBarView to display the content for the selected tab
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildVerseFinderTab(), // The UI you have now
                _buildReaderTab(), // The new flowing reader UI
              ],
            ),
            if (_showAIPanel) _buildAIPanel(),
          ],
        ),
      ),
    );
  }

  // --- Header (used in AppBar) ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bible Study',
          style: Theme
              .of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Explore scriptures and generate insights.',
          style: Theme
              .of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
            color: AppTheme.onSurface.withValues(alpha:0.5),
          ),
        ),
      ],
    );
  }

  // --- Tab 1: Verse Finder (Your current UI) ---
  Widget _buildVerseFinderTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildSelectorRow(),
          const SizedBox(height: 24),
          _buildFetchButton(),
          const SizedBox(height: 24),
          _buildVerseDisplayCard(),
        ],
      ),
    );
  }

  // --- Tab 2: Reader (The new UI) ---
  Widget _buildReaderTab() {
    // This is a placeholder. In a real app, you'd fetch and display a whole chapter.
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 30, // Example: 30 verses
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}',
                style: TextStyle(
                    color: AppTheme.onSurface.withAlpha(75),
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'In the beginning God created the heavens and the earth. Now the earth was formless and empty, darkness was over the surface of the deep. (Placeholder text for verse ${index +
                      1})',
                  style: const TextStyle(fontSize: 16, height: 2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Widgets for Verse Finder Tab ---
  Widget _buildSelectorRow() {
    // ... (This method and all its children are the same as before)
    return Column(
      children: [
        _bookDropdown(),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _buildTextField('Chapter', _chapterController)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Verse', _verseController)),
          ],
        ),
      ],
    );
  }

  // (All other methods like _bookDropdown, _buildTextField, _fetchVerse, etc., remain here unchanged)
  // ... PASTE ALL YOUR OTHER HELPER METHODS HERE ...
  // --- For brevity, I am omitting the other helper methods you already have. ---
  // --- Please make sure they are included below this line. ---
  Widget _bookDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.onSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryCoral.withValues(alpha:0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Book>(
          value: _selectedBook,
          isExpanded: true,
          dropdownColor: AppTheme.onSurfaceVariant,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.onSurfaceVariant),
          items: bibleBooks.map((Book book) {
            return DropdownMenuItem<Book>(
              value: book,
              child: Text(
                book.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (Book? newBook) {
            if (newBook != null) {
              setState(() {
                _selectedBook = newBook;
                _chapterController.text = '1';
                _verseController.text = '1';
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: AppTheme.onSurface.withAlpha(125)),
        filled: true,
        fillColor: AppTheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryCoral, width: 2),
        ),
      ),
    );
  }

  Widget _buildFetchButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.search),
      label: const Text('Find Verse'),
      style: ElevatedButton.styleFrom(
        foregroundColor: AppTheme.onPrimary,
        backgroundColor: AppTheme.primaryCoral,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _fetchVerse,
    );
  }

  Widget _buildVerseDisplayCard() {
    return Card(
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryCoral.withValues(alpha:0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _displayedVerseReference != 'Welcome'
            ? () =>
            _showEnhancedVerseActionSheet(
              _displayedVerseReference,
              _displayedVerseText,
            )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayedVerseReference,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primaryCoral,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _displayedVerseText,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fetchVerse() {
    FocusScope.of(context).unfocus();

    final bookName = _selectedBook.name;
    final chapter = _chapterController.text;
    final verse = _verseController.text;

    setState(() {
      _displayedVerseReference = '$bookName $chapter:$verse';
      _displayedVerseText =
      'And God said, "Let there be light," and there was light. God saw that the light was good, and he separated the light from the darkness. (This is placeholder text from a simulated API call for ${_selectedBook
          .code}.$chapter.$verse)';
    });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        backgroundColor: AppTheme.primaryCoral,
      ),
    );
  }

  void _showEnhancedVerseActionSheet(String verseReference, String verseText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verseReference, style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge),
                const SizedBox(height: 8),
                Text(
                  verseText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium,
                ),
                const Divider(height: 32),
                _buildEnhancedActionItem(
                  icon: Icons.content_copy,
                  iconColor: AppTheme.primaryTeal,
                  title: 'Copy Verse',
                  subtitle: 'Copy verse text to clipboard',
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: '$verseReference: $verseText'));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Verse copied to clipboard')),
                    );
                  },
                ),
                _buildEnhancedActionItem(
                  icon: Icons.palette_outlined,
                  iconColor: AppTheme.accentPurple,
                  title: 'Create Image with AI',
                  subtitle: 'Beautiful verse graphics',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _showAIPanel = true);
                  },
                ),
                _buildEnhancedActionItem(
                  icon: Icons.dynamic_feed,
                  iconColor: AppTheme.primaryCoral,
                  title: 'Share to Feed',
                  subtitle: 'Share with your community',
                  onTap: () {
                    _showComingSoon('Share to Feed');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ListTile _buildEnhancedActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAIPanel() {
    return Container(
      color: Colors.black.withValues(alpha:0.7),
      child: Center(
        child: Container(
          width: MediaQuery
              .of(context)
              .size
              .width * 0.9,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Generate Image with AI',
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 20),
              Text(
                'AI will create an image based on "$_displayedVerseReference". Add an optional prompt for more specific results.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _aiPromptController,
                decoration: const InputDecoration(
                  labelText: 'Optional prompt (e.g., "in a watercolor style")',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _showAIPanel = false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      _showComingSoon('AI Image Generation');
                      setState(() => _showAIPanel = false);
                    },
                    child: const Text('Generate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}