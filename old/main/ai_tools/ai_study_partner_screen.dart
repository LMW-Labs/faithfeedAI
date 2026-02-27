import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:faithfeed/services/premium_gate_service.dart';
import 'package:faithfeed/services/user_profile_service.dart';
import 'package:faithfeed/widgets/premium_badge.dart';
import 'package:faithfeed/widgets/premium_paywall.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';
import '../../../services/google_cloud_tts_service.dart';
import '../../../services/openai_tts_service.dart';
import '../../../services/openai_service.dart';
import '../create_post_modal.dart';

// Models
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<VerseSource>? sources;
  final bool isCrisis;
  final bool isRefusal;
  final bool isError;
  final String messageId;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.isCrisis = false,
    this.isRefusal = false,
    this.isError = false,
    String? messageId,
  }) : messageId = messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
}

class VerseSource {
  final String reference;
  final String text;
  final double similarity;

  VerseSource({
    required this.reference,
    required this.text,
    required this.similarity,
  });

  factory VerseSource.fromMap(Map<String, dynamic> map) {
    return VerseSource(
      reference: map['reference'] as String,
      text: map['text'] as String,
      similarity: (map['similarity'] as num).toDouble(),
    );
  }
}

class AIStudyPartnerScreen extends StatefulWidget {
  const AIStudyPartnerScreen({super.key});

  @override
  State<AIStudyPartnerScreen> createState() => _AIStudyPartnerScreenState();
}

class _AIStudyPartnerScreenState extends State<AIStudyPartnerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GoogleCloudTTSService _googleTts = GoogleCloudTTSService();
  final OpenAITTSService _openAiTts = OpenAITTSService();
  final OpenAIService _openAI = OpenAIService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isLoading = false;
  bool _isTTSInitialized = false;
  String? _currentlyPlayingMessageId;
  List<Map> _availableVoices = [];
  Map? _selectedVoice;
  bool _isListening = false;
  bool _isSpeechAvailable = false;
  bool _isMuted = false; // Start unmuted for immediate voice interaction
  bool _showKeyboard = false; // Track if user wants to type instead of speak
  bool _hasSpokenGreeting = false; // Track if we've spoken the initial greeting
  String? _speechError; // Track speech recognition errors for user feedback

  // Voice engine preference: 'openai' (natural) or 'google' (legacy)
  String _voiceEngine = 'openai';

  @override
  void initState() {
    super.initState();

    // Initialize pulse animation for mic button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_isListening) {
          _pulseController.forward();
        }
      }
    });

    // Add welcome message (not auto-played - user can choose to listen)
    _messages.add(ChatMessage(
      text: "Welcome to your AI Study Partner! I'm here to help you explore biblical concepts and theology from an academic perspective.\n\nI can help you:\n- Understand theological concepts\n- Explore what the Bible says about specific topics\n- Learn about different theological perspectives\n- Study scripture passages\n\nRemember: I'm an educational tool, not a pastor or counselor. Let's dive into God's Word together!",
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Set up OpenAI TTS callbacks - simple state management, no auto-restart
    _openAiTts.onComplete = () {
      if (!mounted) return;
      Log.d('TTS onComplete callback fired');
      setState(() {
        _currentlyPlayingMessageId = null;
      });
    };

    // Set up interruption handling
    _openAiTts.onInterrupted = () {
      if (!mounted) return;
      Log.d('TTS onInterrupted callback fired');
      setState(() {
        _currentlyPlayingMessageId = null;
      });
    };

    // Set up Google TTS callbacks as fallback
    _googleTts.onComplete = () {
      if (!mounted) return;
      Log.d('Google TTS onComplete callback fired');
      setState(() {
        _currentlyPlayingMessageId = null;
      });
    };

    // Initialize speech recognition
    _initSpeech();

    // Initialize TTS
    _initializeTTS();

    // Load saved voice preference
    _loadVoicePreference();
  }

  Future<void> _initSpeech() async {
    try {
      _isSpeechAvailable = await _speechToText.initialize(
        onError: (error) {
          Log.d('Speech error: ${error.errorMsg} (permanent: ${error.permanent})');
          if (mounted) {
            setState(() {
              _isListening = false;
              _speechError = error.errorMsg;
            });

            // Show error to user if it's a significant error
            if (error.permanent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Microphone error: ${error.errorMsg}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        onStatus: (status) {
          Log.d('Speech status: $status');
          // Sync our state with actual speech recognition state
          if (mounted) {
            final isActuallyListening = status == 'listening';
            if (_isListening != isActuallyListening) {
              setState(() => _isListening = isActuallyListening);
            }
          }
        },
      );
    } catch (e) {
      Log.e('Speech initialization failed: $e');
      _isSpeechAvailable = false;
      _speechError = e.toString();
    }

    Log.d('Speech available: $_isSpeechAvailable');
    if (mounted) {
      setState(() {});
    }

    // Speak greeting when TTS is ready
    if (_isSpeechAvailable && !_isMuted && mounted && !_hasSpokenGreeting) {
      _speakGreeting();
    }
  }

  /// Speak the initial greeting when screen opens
  Future<void> _speakGreeting() async {
    if (_hasSpokenGreeting || _isMuted) return;

    _hasSpokenGreeting = true;

    // Wait for TTS to initialize
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted || !_isTTSInitialized) return;

    const greeting = "Hello! I'm your AI Study Partner. Tap the microphone when you're ready to ask me about the Bible.";

    setState(() {
      _currentlyPlayingMessageId = _messages.first.messageId;
    });

    await _speak(greeting);
  }

  /// Initialize TTS (OpenAI with Google Cloud fallback)
  Future<void> _initializeTTS() async {
    try {
      Log.d('Initializing OpenAI TTS...');

      // Check if OpenAI TTS is configured
      if (_openAiTts.isConfigured) {
        Log.d('OpenAI TTS configured - using natural voices');
        _voiceEngine = 'openai';

        // Convert OpenAI voices to Map format for compatibility
        final voices = OpenAITTSService.availableVoices.map((v) => {
          'name': v.id,
          'locale': 'en-US',
          'gender': v.gender,
          'description': v.description,
          'displayName': v.name,
        }).toList();

        setState(() {
          _isTTSInitialized = true;
          _availableVoices = voices;
          if (voices.isNotEmpty) {
            _selectedVoice = voices[4]; // Nova (friendly female)
          }
        });

        Log.d('OpenAI TTS initialized with ${voices.length} voices');
        return;
      }

      // Fallback to Google Cloud TTS
      Log.d('OpenAI not configured, falling back to Google Cloud TTS...');
      _voiceEngine = 'google';

      // Load available voices from Google Cloud
      final voices = await _googleTts.getAvailableVoices();
      Log.d('Loaded ${voices.length} Google Cloud voices');

      setState(() {
        _isTTSInitialized = true;
        _availableVoices = voices;
        if (voices.isNotEmpty) {
          _selectedVoice = voices.first;
        }
      });

      Log.d(' TTS initialized successfully with ${voices.length} voices');
    } catch (e, stackTrace) {
      Log.d(' Error initializing TTS: $e');
      Log.d(' Stack trace: $stackTrace');
      // TTS will be disabled but app will still work
    }
  }

  /// Map Google Cloud TTS voice names to friendly millennial names
  String _getFriendlyVoiceName(String technicalName, String gender) {
    // Popular millennial baby names mapping
    // Using top names from 1981-1996 millennial generation
    final maleVoices = {
      'en-US-Neural2-A': 'Liam',
      'en-US-Neural2-D': 'Noah',
      'en-US-Neural2-I': 'Ethan',
      'en-US-Neural2-J': 'Mason',
      'en-US-Wavenet-A': 'Liam',
      'en-US-Wavenet-B': 'Noah',
      'en-US-Wavenet-D': 'Ethan',
      'en-US-Wavenet-I': 'Mason',
      'en-US-Standard-A': 'Liam',
      'en-US-Standard-B': 'Noah',
      'en-US-Standard-D': 'Ethan',
      'en-US-Standard-I': 'Mason',
    };

    final femaleVoices = {
      'en-US-Neural2-C': 'Emma',
      'en-US-Neural2-E': 'Olivia',
      'en-US-Neural2-F': 'Sophia',
      'en-US-Neural2-G': 'Ava',
      'en-US-Neural2-H': 'Isabella',
      'en-US-Wavenet-C': 'Emma',
      'en-US-Wavenet-E': 'Olivia',
      'en-US-Wavenet-F': 'Sophia',
      'en-US-Wavenet-G': 'Ava',
      'en-US-Wavenet-H': 'Isabella',
      'en-US-Standard-C': 'Emma',
      'en-US-Standard-E': 'Olivia',
      'en-US-Standard-F': 'Sophia',
      'en-US-Standard-G': 'Ava',
      'en-US-Standard-H': 'Isabella',
    };

    // Check gender and return appropriate friendly name
    if (gender.toLowerCase() == 'male') {
      return maleVoices[technicalName] ?? technicalName;
    } else {
      return femaleVoices[technicalName] ?? technicalName;
    }
  }

  /// Load saved voice preference from SharedPreferences
  Future<void> _loadVoicePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoiceName = prefs.getString('ai_study_partner_voice');
      final savedEngine = prefs.getString('ai_study_partner_voice_engine') ?? 'openai';

      _voiceEngine = savedEngine;

      if (savedVoiceName != null && _availableVoices.isNotEmpty) {
        // Find the saved voice in available voices
        final savedVoice = _availableVoices.firstWhere(
          (voice) => voice['name'] == savedVoiceName,
          orElse: () => _availableVoices.first,
        );

        setState(() {
          _selectedVoice = savedVoice;
        });

        // Set voice on appropriate engine
        if (_voiceEngine == 'openai') {
          _openAiTts.setVoice(savedVoiceName);
        } else {
          _googleTts.setVoice(savedVoice);
        }

        Log.d('Loaded saved voice: $savedVoiceName (engine: $_voiceEngine)');
      }
    } catch (e) {
      Log.d('Error loading voice preference: $e');
    }
  }

  /// Save voice preference to SharedPreferences
  Future<void> _saveVoicePreference(Map voice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_study_partner_voice', voice['name']);
      await prefs.setString('ai_study_partner_voice_engine', _voiceEngine);
      Log.d('Saved voice preference: ${voice['name']} (engine: $_voiceEngine)');
    } catch (e) {
      Log.d('Error saving voice preference: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _openAiTts.dispose();
    _googleTts.dispose();
    _speechToText.stop();
    super.dispose();
  }

  /// Speak text using the selected voice engine
  Future<void> _speak(String text) async {
    Log.d('_speak called with engine: $_voiceEngine, openAI configured: ${_openAiTts.isConfigured}');

    // Stop listening while speaking to avoid interference
    if (_isListening) {
      await _stopListening();
    }

    if (_voiceEngine == 'openai' && _openAiTts.isConfigured) {
      Log.d('_speak: Using OpenAI TTS');
      await _openAiTts.speak(text);
    } else {
      Log.d('_speak: Using Google TTS');
      await _googleTts.speak(text);
    }
  }

  /// Stop any TTS playback
  Future<void> _stopTTS() async {
    await _openAiTts.stop();
    await _googleTts.stop();
  }

  /// Get current speaking rate based on voice engine
  double get _currentSpeakingRate {
    if (_voiceEngine == 'openai') {
      return _openAiTts.speed;
    } else {
      return _googleTts.speakingRate;
    }
  }

  /// Set speaking rate on the appropriate engine
  void _setSpeakingRate(double rate) {
    if (_voiceEngine == 'openai') {
      _openAiTts.setSpeed(rate);
    } else {
      _googleTts.setSpeakingRate(rate);
    }
  }

  /// Get current pitch (only available for Google TTS)
  double get _currentPitch {
    return _googleTts.pitch;
  }

  /// Set pitch (only available for Google TTS)
  void _setPitch(double pitch) {
    _googleTts.setPitch(pitch);
  }

  /// Set voice on the appropriate engine
  void _setVoice(Map voice) {
    if (_voiceEngine == 'openai') {
      _openAiTts.setVoice(voice['name'] as String);
    } else {
      _googleTts.setVoice(voice);
    }
  }

  Future<void> _startListening({bool withHaptic = false}) async {
    // Clear any previous error
    _speechError = null;

    if (!_isSpeechAvailable || _isLoading) {
      Log.d('Cannot start listening: available=$_isSpeechAvailable, loading=$_isLoading');
      if (withHaptic && mounted) {
        // Still give feedback but show why it's not working
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLoading ? 'Please wait for response...' : 'Microphone not available'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Haptic feedback when manually triggered - strong click feel
    if (withHaptic) {
      HapticFeedback.heavyImpact();
      // Double tap for stronger click sensation
      Future.delayed(const Duration(milliseconds: 50), () {
        HapticFeedback.selectionClick();
      });
    }

    // Stop any TTS playback when starting to listen
    if (_currentlyPlayingMessageId != null) {
      await _stopTTS();
      setState(() {
        _currentlyPlayingMessageId = null;
      });
    }

    // Always stop any previous listening session first
    if (_speechToText.isListening) {
      await _speechToText.stop();
      // Small delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Double-check we can start
    if (!_isSpeechAvailable || _isLoading || !mounted) return;

    // Set listening state optimistically and start pulse animation
    setState(() => _isListening = true);
    _pulseController.forward();

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) return;
          Log.d('Speech result: "${result.recognizedWords}" (final: ${result.finalResult})');
          setState(() {
            _messageController.text = result.recognizedWords;
          });

          // If user paused speaking and result is final, send the message
          if (result.finalResult && _messageController.text.isNotEmpty) {
            Log.d('Final result received, sending message');
            _sendMessage();
          }
        },
        listenMode: stt.ListenMode.confirmation,
        listenFor: const Duration(seconds: 30), // Timeout after 30 seconds
        pauseFor: const Duration(seconds: 3), // Pause detection
      );

      // Small delay then verify we're actually listening
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_speechToText.isListening && mounted) {
        Log.d('Speech listen failed to start after call');
        setState(() {
          _isListening = false;
          _speechError = 'Failed to start listening';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start microphone. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Log.e('Speech listen error: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
          _speechError = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _stopListening({bool withHaptic = false}) async {
    // Haptic feedback when manually triggered - click feel
    if (withHaptic) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 50), () {
        HapticFeedback.selectionClick();
      });
    }

    // Stop pulse animation
    _pulseController.stop();
    _pulseController.reset();

    // Always try to stop, even if _isListening is false
    // The speech recognition might be in a different state
    try {
      await _speechToText.stop();
    } catch (e) {
      Log.d('Error stopping speech: $e');
    }
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted && _isListening) {
        _stopListening();
      }
    });
  }

  Future<void> _toggleTTS(ChatMessage message) async {
    if (_currentlyPlayingMessageId == message.messageId) {
      // Stop if already playing this message
      await _stopTTS();
      setState(() {
        _currentlyPlayingMessageId = null;
      });
    } else {
      // Stop any current playback and start new
      await _stopTTS();
      setState(() {
        _currentlyPlayingMessageId = message.messageId;
      });
      await _speak(message.text);
    }
  }

  Future<void> _shareMessage(ChatMessage message) async {
    // Show options: Share to Feed or Share External
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Share Study Partner Response',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface, // Readable text
                    ),
              ),
            ),
            const Divider(color: AppTheme.onSurfaceVariant), // Consistent divider
            ListTile(
              leading: const Icon(Icons.feed, color: AppTheme.primaryTeal),
              title: const Text('Share to Feed', style: TextStyle(color: AppTheme.onSurface)), // Readable text
              subtitle: const Text('Post this response to your FaithFeed', style: TextStyle(color: AppTheme.onSurfaceVariant)), // Readable text
              onTap: () {
                Navigator.pop(context);
                _shareToFeed(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppTheme.lightBlue),
              title: const Text('Share Externally', style: TextStyle(color: AppTheme.onSurface)), // Readable text
              subtitle: const Text('Share via messaging apps, email, etc.', style: TextStyle(color: AppTheme.onSurfaceVariant)), // Readable text
              onTap: () {
                Navigator.pop(context);
                _shareExternal(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.onSurfaceVariant),
              title: const Text('Copy to Clipboard', style: TextStyle(color: AppTheme.onSurface)), // Readable text
              subtitle: const Text('Copy the response text', style: TextStyle(color: AppTheme.onSurfaceVariant)), // Readable text
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(message);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToFeed(ChatMessage message) async {
    // Format the message for posting
    String postContent = message.text;

    // Add scripture references if available
    if (message.sources != null && message.sources!.isNotEmpty) {
      postContent += '\n\n Referenced Scriptures:\n';
      for (var source in message.sources!) {
        postContent += '- ${source.reference}\n';
      }
    }

    postContent += '\n\n From AI Study Partner';

    // Open create post modal with pre-filled content
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CreatePostModal(initialContent: postContent),
      );
    }
  }

  Future<void> _shareExternal(ChatMessage message) async {
    // Format the message for external sharing
    String shareText = message.text;

    // Add scripture references if available
    if (message.sources != null && message.sources!.isNotEmpty) {
      shareText += '\n\n Referenced Scriptures:\n';
      for (var source in message.sources!) {
        shareText += '- ${source.reference}\n';
      }
    }

    shareText += '\n\nShared from FaithFeed - AI Study Partner';

    // Share using platform share sheet
    await Share.share(shareText);
  }

  Future<void> _copyToClipboard(ChatMessage message) async {
    // Format the message
    String copyText = message.text;

    // Add scripture references if available
    if (message.sources != null && message.sources!.isNotEmpty) {
      copyText += '\n\n Referenced Scriptures:\n';
      for (var source in message.sources!) {
        copyText += '- ${source.reference}\n';
      }
    }

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: copyText));

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
          backgroundColor: AppTheme.mintGreen,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    // Check premium gate for chat messages
    final gateService = Provider.of<PremiumGateService>(context, listen: false);
    final gateResult = await gateService.canAccess(PremiumGateService.studyPartnerChat);

    if (!gateResult.allowed) {
      if (mounted) {
        showPremiumPaywall(
          context: context,
          featureName: 'AI Study Partner',
          featureDescription: 'Get unlimited conversations with your AI-powered Bible study companion.',
          featureIcon: Icons.school,
        );
      }
      return;
    }

    // Consume the use
    await gateService.consumeUse(PremiumGateService.studyPartnerChat);

    // Stop any TTS playback
    await _stopTTS();
    setState(() {
      _currentlyPlayingMessageId = null;
    });

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

      _messageController.clear();
      _scrollToBottom();

      try {
        // Prepare conversation history (last 6 messages for context)
      final conversationHistory = _messages
          .where((m) => m.text != _messages.first.text) // Exclude welcome message
          .skip(_messages.length > 7 ? _messages.length - 7 : 0)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      if (!_openAI.isConfigured) {
        throw Exception('OpenAI key missing. Add OPENAI_API_KEY to .env');
      }

      final historyText = conversationHistory
          .map((m) => '${m['role']}: ${m['content']}')
          .join('\n');

      final data = await _openAI.chatForJson(
        messages: [
          {
            'role': 'system',
            'content':
                'You are FaithFeed AI Study Partner. Respond with JSON: {"response": "your answer here", "sources": [{"reference": "Book Chapter:Verse", "text": "verse text", "similarity": 0.9}], "isCrisis": false, "isRefusal": false}. Keep responses pastoral and concise. Include 1-2 relevant Bible verse sources.',
          },
          {
            'role': 'user',
            'content':
                'Conversation so far:\n$historyText\nUser: $messageText',
          },
        ],
        maxTokens: 1200,
        temperature: 0.45,
      );

      final response = data['response']?.toString() ?? 'I am here to help with your Bible study.';
      final sources = data['sources'] as List<dynamic>?;
      final isCrisis = data['isCrisis'] as bool? ?? false;
      final isRefusal = data['isRefusal'] as bool? ?? false;

      // Add AI response
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        sources: sources
            ?.map((s) => VerseSource.fromMap(Map<String, dynamic>.from(s)))
            .toList(),
        isCrisis: isCrisis,
        isRefusal: isRefusal,
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });

      _scrollToBottom();

      // Auto-play TTS for AI responses (if not muted)
      if (!_isMuted) {
        setState(() {
          _currentlyPlayingMessageId = aiMessage.messageId;
        });
        Log.d('Starting TTS for AI response');
        await _speak(aiMessage.text);
      }
      // User must tap mic to speak again - no auto-restart

    } catch (e) {
      Log.e('Error in _sendMessage: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: "I apologize, but I encountered an error processing your request. Please try again.\n\nError: ${e.toString()}",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
        _speechError = e.toString();
      });
      _scrollToBottom();

      // Show error snackbar for better feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Re-enable the mic button for retry
                setState(() {
                  _speechError = null;
                });
              },
            ),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground, // Set Scaffold background for consistency
        appBar: AppBar(
          backgroundColor: AppTheme.surface, // Frosted theme AppBar background
          title: const Text(
            'AI Study',
            style: TextStyle(color: AppTheme.onSurface), // Readable title text color
          ),
          iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
          systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure light status bar icons
          actions: [
            // Mute/unmute TTS
            IconButton(
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, size: 22),
              onPressed: _toggleMute,
              tooltip: _isMuted ? 'Unmute AI voice' : 'Mute AI voice',
              color: _isMuted ? Colors.red : AppTheme.onSurface, // Consistent icon color
            ),
            // Voice settings
            if (_isTTSInitialized)
              IconButton(
                icon: const Icon(Icons.record_voice_over, size: 22),
                onPressed: () => _showVoiceSettingsDialog(context),
                tooltip: 'Voice Settings',
                color: AppTheme.onSurface, // Consistent icon color
              ),
            // Info
            IconButton(
              icon: const Icon(Icons.info_outline, size: 22),
              onPressed: () => _showTechnicalInfoDialog(context),
              tooltip: 'About',
              color: AppTheme.onSurface, // Consistent icon color
            ),
            // New conversation
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _stopTTS();
                await _stopListening();
                setState(() {
                  _currentlyPlayingMessageId = null;
                  _hasSpokenGreeting = false;
                  _messages.clear();
                  _messages.add(ChatMessage(
                    text:
                        "Welcome back! Starting a fresh conversation. How can I help you study the Bible today?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ));
                });
                // Speak greeting again
                _speakGreeting();
              },
              tooltip: 'New Conversation',
              color: AppTheme.onSurface, // Consistent icon color
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryTeal.withOpacity(0.1),
                    AppTheme.accentPurple.withOpacity(0.1),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryTeal.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip, size: 16, color: AppTheme.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stateless & Private: No conversation history is stored',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant, // Readable text
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showTechnicalInfoDialog(context),
                    child: const Text(
                      'Learn More',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryTeal), // Readable text
                    ),
                  ),
                ],
              ),
            ),
            // Usage limit indicator for free users
            Consumer<PremiumGateService>(
              builder: (context, gateService, _) {
                if (gateService.isPremium) {
                  return const SizedBox.shrink();
                }
                return FutureBuilder<GateCheckResult>(
                  future: gateService.canAccess(PremiumGateService.studyPartnerChat),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final result = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: UsageLimitIndicator(
                        remaining: result.remainingUses ?? 0,
                        total: result.maxUses ?? 5,
                        label: '${result.remainingUses ?? 0}/${result.maxUses ?? 5} free messages',
                      ),
                    );
                  },
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Studying scripture...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant, // Readable text
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _showKeyboard ? _buildKeyboardInput() : _buildVoiceInput(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the voice input UI with mic button (compact)
  Widget _buildVoiceInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show transcribed text if listening
        if (_isListening && _messageController.text.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
            ),
            child: Text(
              _messageController.text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.onSurface, // Readable text
              ),
            ),
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Keyboard icon (switch to typing)
            IconButton(
              onPressed: () {
                setState(() {
                  _showKeyboard = true;
                });
              },
              icon: const Icon(Icons.keyboard, size: 24),
              color: AppTheme.onSurfaceVariant, // Consistent icon color
              tooltip: 'Type instead',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),

            const SizedBox(width: 16),

            // Mic button with pulse animation when listening
            GestureDetector(
              onTap: () async {
                // Always provide haptic feedback on tap
                HapticFeedback.heavyImpact();
                Log.d('Mic button tapped - isLoading: $_isLoading, isSpeechAvailable: $_isSpeechAvailable, isListening: $_isListening');

                if (_isLoading) {
                  Log.d('Mic blocked: Still loading');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please wait for response...'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (!_isSpeechAvailable) {
                  Log.d('Speech not available, attempting to initialize...');
                  // Try to reinitialize speech
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Initializing microphone...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  await _initSpeech();
                  if (!_isSpeechAvailable && mounted) {
                    Log.d('Speech initialization failed');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Microphone not available. Please check permissions and try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
                if (_isListening) {
                  Log.d('Stopping listening...');
                  // Already listening - stop and send if there's text
                  _stopListening(withHaptic: true);
                  if (_messageController.text.isNotEmpty) {
                    _sendMessage();
                  }
                } else {
                  Log.d('Starting listening...');
                  // Not listening - start
                  _startListening(withHaptic: true);
                }
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final scale = _isListening ? _pulseAnimation.value : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isListening ? 64 : 56,
                      height: _isListening ? 64 : 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isListening
                            ? const LinearGradient(
                                colors: [Colors.red, Colors.redAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : !_isSpeechAvailable
                                ? LinearGradient(
                                    colors: [Colors.grey.shade600, Colors.grey.shade500],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [AppTheme.primaryTeal, AppTheme.lightBlue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                        boxShadow: [
                          BoxShadow(
                            color: _isListening
                                ? Colors.red.withOpacity(0.4 + (_pulseAnimation.value - 1.0) * 2)
                                : !_isSpeechAvailable
                                    ? Colors.grey.withOpacity(0.2)
                                    : AppTheme.primaryTeal.withOpacity(0.4),
                            blurRadius: _isListening ? 16 + (_pulseAnimation.value - 1.0) * 20 : 8,
                            spreadRadius: _isListening ? 2 + (_pulseAnimation.value - 1.0) * 4 : 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: _isListening ? 32 : 28,
                        color: !_isSpeechAvailable ? Colors.grey.shade300 : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 16),

            // Done speaking button (send)
            IconButton(
              onPressed: (_isLoading || _messageController.text.isEmpty) ? null : () {
                _stopListening();
                _sendMessage();
              },
              icon: Icon(
                Icons.send,
                size: 24,
                color: _messageController.text.isNotEmpty
                    ? AppTheme.primaryTeal
                    : AppTheme.onSurfaceVariant.withOpacity(0.5), // Consistent icon color
              ),
              tooltip: 'Send message',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Status text
        Text(
          _isListening
              ? 'Listening... Tap to stop'
              : _isSpeechAvailable
                  ? 'Tap mic to speak'
                  : 'Voice not available',
          style: TextStyle(
            fontSize: 11,
            color: _isListening ? AppTheme.primaryTeal : AppTheme.onSurfaceVariant, // Readable text
            fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Build the keyboard text input UI (compact)
  Widget _buildKeyboardInput() {
    return Row(
      children: [
        // Back to voice button
        IconButton(
          onPressed: () {
            setState(() {
              _showKeyboard = false;
            });
          },
          icon: const Icon(Icons.mic, size: 22),
          color: AppTheme.primaryTeal, // Consistent icon color
          tooltip: 'Use voice instead',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),

        const SizedBox(width: 6),

        // Text input
        Expanded(
          child: TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Ask about biblical concepts...',
              hintStyle: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant), // Readable hint
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: AppTheme.primaryTeal,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
              filled: true,
              fillColor: AppTheme.surface, // Consistent background
            ),
            style: const TextStyle(fontSize: 14, color: AppTheme.onSurface), // Readable input text
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _sendMessage(),
            autofocus: true,
          ),
        ),

        const SizedBox(width: 6),

        // Send button
        SizedBox(
          width: 36,
          height: 36,
          child: FloatingActionButton(
            onPressed: _isLoading ? null : _sendMessage,
            backgroundColor: _isLoading ? AppTheme.onSurfaceVariant : AppTheme.primaryTeal,
            mini: true,
            elevation: 2,
            child: const Icon(Icons.send, size: 18),
          ),
        ),
      ],
    );
  }

  /// Build the user's avatar from their profile image
  Widget _buildUserAvatar() {
    final userProfileService = Provider.of<UserProfileService>(context, listen: false);
    final avatarUrl = userProfileService.currentProfile?.profileImageUrl;
    final hasImage = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryTeal,
        border: Border.all(
          color: AppTheme.primaryTeal,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isPlaying = _currentlyPlayingMessageId == message.messageId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/studypartner.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), // Ensure SVG is visible
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppTheme.primaryTeal
                        : message.isCrisis
                            ? Colors.red.withOpacity(0.1)
                            : message.isRefusal
                                ? const Color(0xFF5D4037).withOpacity(0.15) // Deep brown for better contrast
                                : AppTheme.surface, // Consistent message bubble background
                    borderRadius: BorderRadius.circular(16),
                    border: message.isCrisis || message.isRefusal
                        ? Border.all(
                            color: message.isCrisis ? Colors.red : const Color(0xFF795548), // Brown for scope limitation
                            width: 2,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isCrisis) ...[
                        Row(
                          children: [
                            const Icon(Icons.emergency, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Crisis Resources',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.red, // Consistent color
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (message.isRefusal) ...[
                        Row(
                          children: [
                            const Icon(Icons.info, color: Color(0xFF795548), size: 20), // Brown for better contrast
                            const SizedBox(width: 8),
                            Text(
                              'Scope Limitation',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: const Color(0xFF5D4037), // Deep brown for readability
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : AppTheme.onSurface, // Readable text
                          height: 1.4,
                        ),
                      ),

                      // TTS and Share Buttons for AI messages
                      if (!message.isUser) ...[
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            // Use darker colors for scope limitation messages
                            final buttonTextColor = message.isRefusal
                                ? const Color(0xFF5D4037) // Deep brown for scope limitation
                                : AppTheme.onSurfaceVariant;
                            final buttonBorderColor = message.isRefusal
                                ? const Color(0xFF795548).withOpacity(0.5)
                                : AppTheme.onSurfaceVariant.withOpacity(0.3);
                            final buttonBgColor = message.isRefusal
                                ? const Color(0xFF5D4037).withOpacity(0.1)
                                : AppTheme.darkBackground.withOpacity(0.3);

                            return Row(
                              children: [
                                // TTS Button
                                InkWell(
                                  onTap: () => _toggleTTS(message),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isPlaying
                                          ? AppTheme.primaryTeal.withOpacity(0.2)
                                          : buttonBgColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isPlaying ? AppTheme.primaryTeal : buttonBorderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPlaying ? Icons.stop : Icons.volume_up,
                                          size: 16,
                                          color: isPlaying ? AppTheme.primaryTeal : buttonTextColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isPlaying ? 'Stop' : 'Listen',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isPlaying ? AppTheme.primaryTeal : buttonTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Share Button
                                InkWell(
                                  onTap: () => _shareMessage(message),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: buttonBgColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: buttonBorderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.share,
                                          size: 16,
                                          color: buttonTextColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Share',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: buttonTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],

                      if (message.sources != null && message.sources!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(color: message.isRefusal ? const Color(0xFF795548).withOpacity(0.3) : AppTheme.onSurfaceVariant), // Consistent divider
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.book,
                              size: 16,
                              color: message.isRefusal ? const Color(0xFF5D4037) : AppTheme.primaryTeal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Referenced Scriptures:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: message.isRefusal ? const Color(0xFF5D4037) : AppTheme.primaryTeal, // Readable text
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...message.sources!.map((source) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: message.isRefusal
                                      ? const Color(0xFF5D4037).withOpacity(0.08)
                                      : AppTheme.surface, // Consistent background
                                  borderRadius: BorderRadius.circular(8),
                                  border: message.isRefusal
                                      ? Border.all(color: const Color(0xFF795548).withOpacity(0.3))
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      source.reference,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: message.isRefusal ? const Color(0xFF5D4037) : AppTheme.primaryTeal, // Readable text
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      source.text,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: message.isRefusal ? const Color(0xFF4E342E) : AppTheme.onSurfaceVariant, // Readable text
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant, // Readable text
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showTechnicalInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface, // Consistent dialog background
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.aiGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.security, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'The Responsible Study Partner',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface, // Readable title
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.onSurface, // Readable icon
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryTeal.withOpacity(0.1),
                          AppTheme.accentPurple.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryTeal.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.summarize, color: AppTheme.primaryTeal),
                            const SizedBox(width: 12),
                            Text(
                              'Core Safety Features',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface, // Readable title
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTalkingPoint(
                          context,
                          'RAG (Retrieval-Augmented Generation)',
                          'All AI answers are grounded in retrieved Bible verses with citations.',
                        ),
                        const SizedBox(height: 12),
                        _buildTalkingPoint(
                          context,
                          'Stateless & Private',
                          'No conversation history is stored on servers.',
                        ),
                        const SizedBox(height: 12),
                        _buildTalkingPoint(
                          context,
                          'Crisis Detection',
                          'Auto-detects location and provides appropriate local crisis hotlines (988 in US, 116 123 in UK, etc.).',
                        ),
                        const SizedBox(height: 12),
                        _buildTalkingPoint(
                          context,
                          'Scope Limitation',
                          'Academic study only - refuses personal advice and redirects to theological concepts.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppTheme.onPrimary, // Readable button text
                      ),
                      child: const Text('Got It!'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTalkingPoint(BuildContext context, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.primaryTeal,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface, // Readable text
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant, // Readable text
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showVoiceSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface, // Consistent dialog background
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.aiGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.record_voice_over, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice Settings',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface, // Readable title
                              ),
                            ),
                            if (_voiceEngine == 'openai')
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.mintGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.mintGreen),
                                ),
                                child: const Text(
                                  'Powered by OpenAI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.mintGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.onSurface, // Readable icon
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Current Voice Info
                  if (_selectedVoice != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryTeal.withOpacity(0.1),
                            AppTheme.accentPurple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryTeal.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.primaryTeal, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Current Voice',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTeal, // Readable text
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedVoice!['displayName'] ?? _selectedVoice!['name'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface, // Readable text
                            ),
                          ),
                          Text(
                            _selectedVoice!['description'] ?? '${_selectedVoice!['locale']} - ${_selectedVoice!['gender']}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSurfaceVariant, // Readable text
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Voice Selection
                  Text(
                    'Select Voice',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface, // Readable title
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Voice List
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableVoices.length,
                      itemBuilder: (context, index) {
                        final voice = _availableVoices[index];
                        final voiceName = voice['name'] as String? ?? '';
                        final gender = voice['gender'] as String? ?? '';
                        final description = voice['description'] as String? ?? '';
                        final displayName = voice['displayName'] as String? ?? voiceName;
                        final isSelected = voiceName == _selectedVoice?['name'];

                        // Determine voice type based on engine
                        final isOpenAI = _voiceEngine == 'openai';
                        final isNeural = voiceName.contains('Neural2');
                        final isWavenet = voiceName.contains('Wavenet');

                        // Use display name for OpenAI, friendly name for Google
                        final friendlyName = isOpenAI ? displayName : _getFriendlyVoiceName(voiceName, gender);

                        return Card(
                          color: isSelected
                            ? AppTheme.primaryTeal.withOpacity(0.2)
                            : AppTheme.surface, // Consistent background
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Row(
                              children: [
                                // Gender icon
                                Icon(
                                  gender.toLowerCase() == 'male'
                                    ? Icons.face
                                    : gender.toLowerCase() == 'female'
                                      ? Icons.face_3
                                      : Icons.record_voice_over,
                                  color: isSelected ? AppTheme.primaryTeal : AppTheme.onSurfaceVariant, // Consistent icon color
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                // Voice info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friendlyName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? AppTheme.primaryTeal : AppTheme.onSurface, // Readable text
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isOpenAI
                                          ? description
                                          : '${gender.toUpperCase()} - ${isNeural ? "Neural" : isWavenet ? "Wavenet" : "Standard"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected
                                            ? AppTheme.primaryTeal.withOpacity(0.8)
                                            : AppTheme.onSurfaceVariant, // Readable text
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Preview button
                                IconButton(
                                  icon: const Icon(Icons.play_arrow, size: 22),
                                  onPressed: () async {
                                    Log.d('Voice preview: Starting for ${voice['name']}');
                                    await _stopListening();
                                    await Future.delayed(const Duration(milliseconds: 200));
                                    _setVoice(voice);
                                    await _speak('Hello, this is a preview of this voice.');
                                  },
                                  tooltip: 'Preview',
                                  color: AppTheme.onSurfaceVariant, // Consistent icon color
                                ),
                                // Select button
                                SizedBox(
                                  width: 70,
                                  height: 32,
                                  child: isSelected
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryTeal.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppTheme.primaryTeal),
                                        ),
                                        child: const Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check, color: AppTheme.primaryTeal, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                'Active',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryTeal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : OutlinedButton(
                                        onPressed: () {
                                          _setVoice(voice);
                                          setState(() {
                                            _selectedVoice = voice;
                                          });
                                          _saveVoicePreference(voice);
                                          Navigator.pop(context);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Voice changed to $friendlyName'),
                                                duration: const Duration(seconds: 2),
                                                backgroundColor: AppTheme.primaryTeal,
                                              ),
                                            );
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          side: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.5)), // Consistent border color
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          foregroundColor: AppTheme.primaryTeal, // Readable text color
                                        ),
                                        child: const Text(
                                          'Select',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Speed and Pitch Controls
                  Text(
                    'Speed',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface, // Readable text
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('Slow', style: TextStyle(color: _currentSpeakingRate == 0.75 ? Colors.white : AppTheme.onSurface)), // Readable text
                        selected: _currentSpeakingRate == 0.75,
                        backgroundColor: AppTheme.surface,
                        selectedColor: AppTheme.primaryTeal,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            _setSpeakingRate(0.75);
                            setState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('Normal', style: TextStyle(color: _currentSpeakingRate == 1.0 ? Colors.white : AppTheme.onSurface)), // Readable text
                        selected: _currentSpeakingRate == 1.0,
                        backgroundColor: AppTheme.surface,
                        selectedColor: AppTheme.primaryTeal,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            _setSpeakingRate(1.0);
                            setState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('Fast', style: TextStyle(color: _currentSpeakingRate == 1.25 ? Colors.white : AppTheme.onSurface)), // Readable text
                        selected: _currentSpeakingRate == 1.25,
                        backgroundColor: AppTheme.surface,
                        selectedColor: AppTheme.primaryTeal,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            _setSpeakingRate(1.25);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Pitch controls only shown for Google TTS (OpenAI doesn't support pitch)
                  if (_voiceEngine == 'google') ...[
                    Text(
                      'Pitch',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface, // Readable text
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text('Low', style: TextStyle(color: _currentPitch == -5.0 ? Colors.white : AppTheme.onSurface)), // Readable text
                          selected: _currentPitch == -5.0,
                          backgroundColor: AppTheme.surface,
                          selectedColor: AppTheme.primaryTeal,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              _setPitch(-5.0);
                              setState(() {});
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text('Normal', style: TextStyle(color: _currentPitch == 0.0 ? Colors.white : AppTheme.onSurface)), // Readable text
                          selected: _currentPitch == 0.0,
                          backgroundColor: AppTheme.surface,
                          selectedColor: AppTheme.primaryTeal,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              _setPitch(0.0);
                              setState(() {});
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text('High', style: TextStyle(color: _currentPitch == 5.0 ? Colors.white : AppTheme.onSurface)), // Readable text
                          selected: _currentPitch == 5.0,
                          backgroundColor: AppTheme.surface,
                          selectedColor: AppTheme.primaryTeal,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              _setPitch(5.0);
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppTheme.onPrimary, // Readable text
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}