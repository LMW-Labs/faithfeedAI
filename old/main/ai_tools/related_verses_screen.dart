import 'package:flutter/material.dart';
import '../../../services/openai_service.dart';
import '../../../theme/app_theme.dart';

class RelatedVersesScreen extends StatefulWidget {
  const RelatedVersesScreen({super.key});

  @override
  State<RelatedVersesScreen> createState() => _RelatedVersesScreenState();
}

class _RelatedVersesScreenState extends State<RelatedVersesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _verseController = TextEditingController();
  final OpenAIService _openAI = OpenAIService();

  List<String>? _relatedVerses;
  bool _isLoading = false;

  Future<void> _findRelatedVerses() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_openAI.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenAI key missing. Add OPENAI_API_KEY to .env')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _relatedVerses = null;
    });

    try {
      final response = await _openAI.chatForJson(
        messages: [
          {
            'role': 'system',
            'content':
                'Suggest 5 Bible verses related to the provided reference. Return JSON {verses:["Book 1:1 - text"...]}',
          },
          {
            'role': 'user',
            'content': 'Find cross-references for ${_verseController.text}',
          },
        ],
        maxTokens: 600,
        temperature: 0.35,
      );
      final verses = List<String>.from(response['verses'] as List? ?? const []);
      setState(() {
        _relatedVerses = verses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load related verses: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Related Verses', style: TextStyle(color: AppTheme.lightOnSurface)),
        iconTheme: IconThemeData(color: AppTheme.lightOnSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _verseController,
                decoration: const InputDecoration(
                  labelText: 'Verse (e.g. John 3:16)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a verse';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _findRelatedVerses,
                child: const Text('Find Related Verses'),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
              if (_relatedVerses != null)
                Expanded(
                  child: ListView.builder(
                    itemCount: _relatedVerses!.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(top: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(_relatedVerses![index]),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
