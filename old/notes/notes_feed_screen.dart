import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemUiOverlayStyle
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/verse_note_model.dart';
import '../../services/auth_service.dart';
import '../../services/text_to_speech_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/verse_notes_service.dart';
import '../../theme/app_theme.dart';
import '../main/create_post_modal.dart';

class NotesFeedScreen extends StatefulWidget {
  const NotesFeedScreen({super.key});

  @override
  State<NotesFeedScreen> createState() => _NotesFeedScreenState();
}

class _NotesFeedScreenState extends State<NotesFeedScreen> {
  final DateFormat _dateFormat = DateFormat.yMMMMd().add_jm();
  late TextToSpeechService _ttsService;
  String? _playingNoteId;

  @override
  void initState() {
    super.initState();
    _ttsService = TextToSpeechService();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _speakNote(VerseNote note) async {
    setState(() => _playingNoteId = note.id);
    await _ttsService.speak(note.note);
    if (mounted) {
      setState(() => _playingNoteId = null);
    }
  }

  Future<void> _shareNote(VerseNote note) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface, // Consistent background for modal
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.ios_share, color: AppTheme.primaryTeal), // Consistent icon color
                title: const Text('Share externally', style: TextStyle(color: AppTheme.onSurface)), // Readable text
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    '${note.note}\n— ${note.verseReference}',
                    subject: 'FaithFeed Note on ${note.verseReference}',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.public, color: AppTheme.primaryTeal), // Consistent icon color
                title: const Text('Share to FaithFeed', style: TextStyle(color: AppTheme.onSurface)), // Readable text
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CreatePostModal(
                      initialContent:
                          '${note.note}\n\n${note.verseReference}\n${note.verseText}',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadNote(VerseNote note) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final safeReference =
          note.verseReference.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
      final file = File('${directory.path}/${safeReference}_${note.id}.txt');
      await file.writeAsString(note.exportText());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved note to ${file.path}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save note. Please try again.'),
        ),
      );
    }
  }

  Future<void> _printNote(VerseNote note) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Main verse reference - prominently displayed
            pw.Text(
              note.verseReference,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal700,
              ),
            ),
            pw.SizedBox(height: 4),
            // Translation info if available
            if (note.translation != null && note.translation!.isNotEmpty)
              pw.Text(
                '(${note.translation})',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            pw.SizedBox(height: 12),
            // Verse text in quotes
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                '"${note.verseText}"',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            // Notes section header
            pw.Text(
              'My Notes',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            // User's notes
            pw.Text(
              note.note,
              style: const pw.TextStyle(fontSize: 14, lineSpacing: 1.5),
            ),
            // Related verses section
            if (note.relatedVerses.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),
              pw.Text(
                'Related Verses',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              ...note.relatedVerses.map(
                (related) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '• ',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              related.reference,
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal700,
                              ),
                            ),
                            if (related.text != null && related.text!.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 4),
                                child: pw.Text(
                                  related.text!,
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Footer with date
            pw.Spacer(),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),
            pw.Text(
              'Created: ${DateFormat('MMMM d, yyyy').format(note.createdAt)}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Future<void> _addRelatedVerse(
    VerseNote note,
    VerseNotesService service,
  ) async {
    final result = await showDialog<RelatedVerse>(
      context: context,
      builder: (context) => _VersePickerDialog(),
    );

    if (result != null) {
      await service.addRelatedVerse(noteId: note.id, relatedVerse: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Related verse added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final notesService = Provider.of<VerseNotesService>(context, listen: false);
    final profileService = Provider.of<UserProfileService>(context);
    final profile = profileService.currentProfile;
    final profileImage = profile?.profileImageUrl ?? '';
    final rawName = profile?.displayName ?? '';
    final displayName = rawName.trim().isNotEmpty ? rawName : 'You';
    final userId = authService.user?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground, // Consistent dark background
        appBar: AppBar(
          backgroundColor: AppTheme.surface, // Frosted theme AppBar background
          elevation: 0,
          title: const Text(
            'My Notes',
            style: TextStyle(color: AppTheme.onSurface), // Readable title text color
          ),
          iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
          systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure light status bar icons
        ),
        body: const Center(
          child: Text(
            'Please sign in to view your notes.',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground, // Consistent dark background
      appBar: AppBar(
        backgroundColor: AppTheme.surface, // Frosted theme AppBar background
        elevation: 0,
        title: const Text(
          'My Notes',
          style: TextStyle(color: AppTheme.onSurface), // Readable title text color
        ),
        iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure light status bar icons
        actions: [
          if (_playingNoteId != null)
            IconButton(
              tooltip: 'Stop audio',
              onPressed: () {
                _ttsService.stop();
                setState(() => _playingNoteId = null);
              },
              icon: Icon(Icons.stop_circle_outlined, color: AppTheme.onSurface), // Readable icon color
            ),
        ],
      ),
      body: StreamBuilder<List<VerseNote>>(
        stream: notesService.notesStream(userId: userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load notes: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            );
          }

          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No notes yet.\nUse the “Note” action in any verse to capture your reflections.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                color: AppTheme.surface, // Consistent background
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage:
                                profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                            child: profileImage.isEmpty
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName.substring(0, 1).toUpperCase()
                                        : 'F',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface, // Readable text
                                  ),
                                ),
                                Text(
                                  _dateFormat.format(note.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.onSurfaceVariant, // Readable text
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Listen to note',
                            onPressed: () => _speakNote(note),
                            icon: Icon(
                              _playingNoteId == note.id
                                  ? Icons.volume_up
                                  : Icons.volume_up_outlined,
                              color: AppTheme.onSurface, // Readable icon color
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        note.verseReference,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.verseText,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant, // Readable text
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        note.note,
                        style: const TextStyle(fontSize: 15, color: AppTheme.onSurface), // Readable text
                      ),
                      if (note.relatedVerses.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Related Verses',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface, // Readable text
                          ),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: note.relatedVerses
                              .map(
                                (related) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '${related.reference}${related.text != null ? ': ${related.text}' : ''}',
                                    style: const TextStyle(
                                      color: AppTheme.onSurfaceVariant, // Readable text
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _shareNote(note),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryTeal,
                              side: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.5)), // Consistent border color
                            ),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Share'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _addRelatedVerse(note, notesService),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryTeal,
                              side: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.5)), // Consistent border color
                            ),
                            icon: const Icon(Icons.add_link),
                            label: const Text('Add Verses'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _downloadNote(note),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryTeal,
                              side: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.5)), // Consistent border color
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _printNote(note),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryTeal,
                              side: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.5)), // Consistent border color
                            ),
                            icon: const Icon(Icons.print),
                            label: const Text('Print'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _VersePickerDialog extends StatefulWidget {
  @override
  State<_VersePickerDialog> createState() => _VersePickerDialogState();
}

class _VersePickerDialogState extends State<_VersePickerDialog> {
  // Book data with chapter counts
  static const List<_BookData> _bibleBooks = [
    _BookData('Genesis', 50), _BookData('Exodus', 40), _BookData('Leviticus', 27),
    _BookData('Numbers', 36), _BookData('Deuteronomy', 34), _BookData('Joshua', 24),
    _BookData('Judges', 21), _BookData('Ruth', 4), _BookData('1 Samuel', 31),
    _BookData('2 Samuel', 24), _BookData('1 Kings', 22), _BookData('2 Kings', 25),
    _BookData('1 Chronicles', 29), _BookData('2 Chronicles', 36), _BookData('Ezra', 10),
    _BookData('Nehemiah', 13), _BookData('Esther', 10), _BookData('Job', 42),
    _BookData('Psalms', 150), _BookData('Proverbs', 31), _BookData('Ecclesiastes', 12),
    _BookData('Song of Solomon', 8), _BookData('Isaiah', 66), _BookData('Jeremiah', 52),
    _BookData('Lamentations', 5), _BookData('Ezekiel', 48), _BookData('Daniel', 12),
    _BookData('Hosea', 14), _BookData('Joel', 3), _BookData('Amos', 9),
    _BookData('Obadiah', 1), _BookData('Jonah', 4), _BookData('Micah', 7),
    _BookData('Nahum', 3), _BookData('Habakkuk', 3), _BookData('Zephaniah', 3),
    _BookData('Haggai', 2), _BookData('Zechariah', 14), _BookData('Malachi', 4),
    _BookData('Matthew', 28), _BookData('Mark', 16), _BookData('Luke', 24),
    _BookData('John', 21), _BookData('Acts', 28), _BookData('Romans', 16),
    _BookData('1 Corinthians', 16), _BookData('2 Corinthians', 13), _BookData('Galatians', 6),
    _BookData('Ephesians', 6), _BookData('Philippians', 4), _BookData('Colossians', 4),
    _BookData('1 Thessalonians', 5), _BookData('2 Thessalonians', 3), _BookData('1 Timothy', 6),
    _BookData('2 Timothy', 4), _BookData('Titus', 3), _BookData('Philemon', 1),
    _BookData('Hebrews', 13), _BookData('James', 5), _BookData('1 Peter', 5),
    _BookData('2 Peter', 3), _BookData('1 John', 5), _BookData('2 John', 1),
    _BookData('3 John', 1), _BookData('Jude', 1), _BookData('Revelation', 22),
  ];

  _BookData? selectedBook;
  int? selectedChapter;
  int? selectedVerse;
  int? endVerse;
  final textController = TextEditingController();

  int get _maxChapters => selectedBook?.chapters ?? 0;

  String get reference {
    if (selectedBook == null) return '';
    if (selectedChapter == null) return selectedBook!.name;
    if (selectedVerse == null) return '${selectedBook!.name} $selectedChapter';
    if (endVerse != null && endVerse! > selectedVerse!) {
      return '${selectedBook!.name} $selectedChapter:$selectedVerse-$endVerse';
    }
    return '${selectedBook!.name} $selectedChapter:$selectedVerse';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface, // Consistent dialog background
      title: const Text(
        'Add Related Verse',
        style: TextStyle(color: AppTheme.onSurface), // Readable title
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book selector dropdown
            const Text(
              'Book',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.onSurface), // Readable label
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<_BookData>(
              value: selectedBook,
              decoration: InputDecoration(
                hintText: 'Select book',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.7)), // Readable hint
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              isExpanded: true,
              dropdownColor: AppTheme.surface, // Consistent dropdown background
              style: const TextStyle(color: AppTheme.onSurface), // Readable selected value
              iconEnabledColor: AppTheme.onSurfaceVariant, // Readable icon
              items: _bibleBooks
                  .map((book) => DropdownMenuItem(value: book, child: Text(book.name, style: const TextStyle(color: AppTheme.onSurface)))) // Readable item text
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedBook = value;
                  selectedChapter = null;
                  selectedVerse = null;
                  endVerse = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Chapter dropdown
            const Text(
              'Chapter',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.onSurface), // Readable label
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: selectedChapter,
              decoration: InputDecoration(
                hintText: selectedBook == null ? 'Select book first' : 'Select chapter',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.7)), // Readable hint
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              isExpanded: true,
              dropdownColor: AppTheme.surface, // Consistent dropdown background
              style: const TextStyle(color: AppTheme.onSurface), // Readable selected value
              iconEnabledColor: AppTheme.onSurfaceVariant, // Readable icon
              items: selectedBook == null
                  ? []
                  : List.generate(_maxChapters, (i) => i + 1)
                      .map((ch) => DropdownMenuItem(value: ch, child: Text('Chapter $ch', style: const TextStyle(color: AppTheme.onSurface)))) // Readable item text
                      .toList(),
              onChanged: selectedBook == null
                  ? null
                  : (value) {
                      setState(() {
                        selectedChapter = value;
                        selectedVerse = null;
                        endVerse = null;
                      });
                    },
            ),
            const SizedBox(height: 16),

            // Verse selectors in a row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Verse',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.onSurface), // Readable label
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedVerse,
                        decoration: InputDecoration(
                          hintText: selectedChapter == null ? '-' : 'Verse',
                          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.7)), // Readable hint
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        isExpanded: true,
                        dropdownColor: AppTheme.surface, // Consistent dropdown background
                        style: const TextStyle(color: AppTheme.onSurface), // Readable selected value
                        iconEnabledColor: AppTheme.onSurfaceVariant, // Readable icon
                        items: selectedChapter == null
                            ? []
                            : List.generate(176, (i) => i + 1) // Max verse count (Psalm 119)
                                .map((v) => DropdownMenuItem(value: v, child: Text('$v', style: const TextStyle(color: AppTheme.onSurface)))) // Readable item text
                                .toList(),
                        onChanged: selectedChapter == null
                            ? null
                            : (value) {
                                setState(() {
                                  selectedVerse = value;
                                  if (endVerse != null && value != null && endVerse! < value) {
                                    endVerse = null;
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Verse',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.onSurface), // Readable label
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        value: endVerse,
                        decoration: InputDecoration(
                          hintText: selectedVerse == null ? '-' : 'Optional',
                          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.7)), // Readable hint
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        isExpanded: true,
                        dropdownColor: AppTheme.surface, // Consistent dropdown background
                        style: const TextStyle(color: AppTheme.onSurface), // Readable selected value
                        iconEnabledColor: AppTheme.onSurfaceVariant, // Readable icon
                        items: selectedVerse == null
                            ? []
                            : [
                                const DropdownMenuItem<int?>(value: null, child: Text('Single verse', style: TextStyle(color: AppTheme.onSurface))), // Readable item text
                                ...List.generate(176 - selectedVerse!, (i) => selectedVerse! + i + 1)
                                    .map((v) => DropdownMenuItem<int?>(value: v, child: Text('$v', style: const TextStyle(color: AppTheme.onSurface)))) // Readable item text
                              ],
                        onChanged: selectedVerse == null
                            ? null
                            : (value) {
                                setState(() {
                                  endVerse = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reference preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_border, size: 18, color: AppTheme.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reference.isEmpty ? 'Reference will appear here' : reference,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: reference.isEmpty ? AppTheme.onSurfaceVariant : AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Verse text (optional)
            const Text(
              'Verse Text (optional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.onSurface), // Readable label
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(color: AppTheme.onSurface), // Readable input text
              decoration: InputDecoration(
                hintText: 'Paste the verse text here...',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.7)), // Readable hint
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.onSurface)), // Readable button text
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryTeal,
            foregroundColor: AppTheme.onPrimary, // Readable button text
          ),
          onPressed: reference.isEmpty
              ? null
              : () {
                  Navigator.pop(
                    context,
                    RelatedVerse(
                      reference: reference,
                      text: textController.text.trim().isEmpty
                          ? null
                          : textController.text.trim(),
                    ),
                  );
                },
          child: const Text('Add Verse'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}

class _BookData {
  final String name;
  final int chapters;
  const _BookData(this.name, this.chapters);
}