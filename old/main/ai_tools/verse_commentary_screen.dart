import 'package:flutter/material.dart';
import '../../../widgets/ai_commentary_card.dart';
import '../../../theme/app_theme.dart';

class VerseCommentaryScreen extends StatefulWidget {
  const VerseCommentaryScreen({super.key});

  @override
  State<VerseCommentaryScreen> createState() => _VerseCommentaryScreenState();
}

class _VerseCommentaryScreenState extends State<VerseCommentaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookController = TextEditingController();
  final _chapterController = TextEditingController();
  final _verseController = TextEditingController();

  String? _verseText;
  String? _bookName;
  int? _chapterNumber;
  int? _verseNumber;

  void _generateCommentary() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _bookName = _bookController.text;
        _chapterNumber = int.tryParse(_chapterController.text);
        _verseNumber = int.tryParse(_verseController.text);
        // TODO: Get the verse text from the bible service
        _verseText = 'For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Verse Commentary', style: TextStyle(color: AppTheme.lightOnSurface)),
        iconTheme: IconThemeData(color: AppTheme.lightOnSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _bookController,
                decoration: const InputDecoration(
                  labelText: 'Book',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a book';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _chapterController,
                decoration: const InputDecoration(
                  labelText: 'Chapter',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a chapter';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _verseController,
                decoration: const InputDecoration(
                  labelText: 'Verse',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a verse';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _generateCommentary,
                child: const Text('Generate Commentary'),
              ),
              if (_verseText != null)
                AICommentaryCard(
                  verseText: _verseText!,
                  bookName: _bookName!,
                  chapterNumber: _chapterNumber!,
                  verseNumber: _verseNumber!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
