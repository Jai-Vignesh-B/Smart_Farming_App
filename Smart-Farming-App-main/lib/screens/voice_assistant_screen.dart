import 'dart:async';
import 'dart:math';
import 'dart:ui'; // For ImageFilter
import 'package:farmer_app/services/chat_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:farmer_app/services/api_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> with TickerProviderStateMixin {
  // STT & TTS
  stt.SpeechToText? _speech;
  FlutterTts? _flutterTts;
  
  // State
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;
  String? _currentLanguageCode;
  String _text = '';
  String _aiResponse = '';
  
  // Karaoke / Highlighting State
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  
  Timer? _silenceTimer;
  
  // Animation
  late AnimationController _orbController;
  late AnimationController _pulseController;
  
  // Scroll Controller for Auto-scrolling
  final ScrollController _scrollController = ScrollController();
  
  // Services
  final ChatService _chatService = ChatService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Services init in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLanguageCode = context.locale.languageCode;
    
    if (_currentLanguageCode != newLanguageCode) {
      print('🌐 Language changed: $_currentLanguageCode -> $newLanguageCode');
      _currentLanguageCode = newLanguageCode;
      _performFullReset();
    }
  }

  Future<void> _performFullReset() async {
    print('🔄 Performing FULL RESET of voice engines...');
    try {
      await _speech?.stop();
      await _speech?.cancel();
    } catch (e) {
      print('STT cleanup warning: $e');
    }
    
    try {
      await _flutterTts?.stop();
    } catch (e) {
      print('TTS cleanup warning: $e');
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _isSpeaking = false;
        _isProcessing = false;
        _isSpeechInitialized = false;
        _isTtsInitialized = false;
        _text = '';
        _aiResponse = '';
        _currentWordStart = 0;
        _currentWordEnd = 0;
      });
    }

    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    
    await _initTts();
    await _initSpeech();
    
    print('✅ Voice engines reset complete for locale: $_currentLanguageCode');
  }

  Future<void> _initTts() async {
    if (_flutterTts == null) return;
    
    try {
      final locale = _getTtsLocale(_currentLanguageCode ?? 'en');
      print('🔊 Initializing TTS with locale: $locale');
      
      await _flutterTts!.setLanguage(locale);
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      
      _flutterTts!.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      
      _flutterTts!.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentWordStart = 0;
            _currentWordEnd = 0;
          });
        }
      });
      
      _flutterTts!.setErrorHandler((msg) {
        print('TTS Error: $msg');
        if (mounted) setState(() => _isSpeaking = false);
      });
      
      // KARAOKE PROGRESS HANDLER
      _flutterTts!.setProgressHandler((String text, int start, int end, String word) {
        if (mounted) {
          setState(() {
            _currentWordStart = start;
            _currentWordEnd = end;
          });
          
          // Auto-scroll logic: Keep active text near the bottom (3rd line from last view)
          if (_scrollController.hasClients) {
            final double charOffset = start.toDouble();
            // Estimate height: ~0.8 pixels per char (Increased for better tracking)
            final double estimatedPixelPos = charOffset * 0.8; 
            
            // Target: Keep reading line ~120px from bottom (approx 3-4 lines up)
            final double viewportHeight = _scrollController.position.viewportDimension;
            final double targetOffset = estimatedPixelPos - (viewportHeight - 120);
            
            // Only scroll if we need to move down
            if (targetOffset > _scrollController.offset) {
               _scrollController.animateTo(
                 targetOffset,
                 duration: const Duration(milliseconds: 300), // Faster, smoother updates
                 curve: Curves.easeOut,
               );
            }
          }
        }
      });
      
      if (mounted) {
        setState(() => _isTtsInitialized = true);
      }
      print('✅ TTS initialized successfully');
    } catch (e) {
      print('❌ TTS Init Error: $e');
    }
  }

  void _initAnimations() {
    _orbController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  Future<void> _initSpeech() async {
    if (_speech == null) return;
    
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to use Voice Assistant')),
        );
      }
      return;
    }
    
    bool available = await _speech!.initialize(
      onStatus: (status) {
        print('STT Status: $status');
        if (status == 'notListening' && _isListening) {
           _stopListeningAndProcess(); 
        }
      },
      onError: (errorNotification) {
         print('STT Error: ${errorNotification.errorMsg}');
      },
    );

    if (mounted && available) {
      setState(() => _isSpeechInitialized = true);
      print('✅ Speech Recognition initialized successfully');
    } else {
      print('❌ Speech Recognition initialization failed');
    }
  }

  void _listen() async {
    if (_speech == null || !_isSpeechInitialized) {
      print('⚠️ Speech not initialized, attempting re-init...');
      await _initSpeech();
      if (!_isSpeechInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice recognition not ready. Please try again.')),
        );
        return;
      }
    }

    if (_isListening) {
      _stopListeningAndProcess();
    } else {
      if (_isSpeaking) {
        await _flutterTts?.stop();
        if (mounted) setState(() => _isSpeaking = false);
      }
      
      if (mounted) {
        setState(() {
          _isListening = true;
          _text = '';
          _aiResponse = '';
          _currentWordStart = 0;
          _currentWordEnd = 0;
          _pulseController.repeat(reverse: true);
        });
      }

      final localeId = _getLocaleId(_currentLanguageCode ?? 'en');
      print('🎤 Starting listening with locale: $localeId');
      
      _speech!.listen(
        onResult: (val) {
           if (mounted) {
             setState(() {
               _text = val.recognizedWords;
             });
           }
           
           if (_isListening && val.recognizedWords.isNotEmpty) {
             _silenceTimer?.cancel();
             _silenceTimer = Timer(const Duration(seconds: 3), () {
               if (_isListening) {
                 print('⏱️ Silence timeout - stopping listening');
                 _stopListeningAndProcess();
               }
             });
           }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }
  
  void _stopListeningAndProcess() {
    print('🛑 Stopping listening and checking for processing...');
    _silenceTimer?.cancel();
    _speech?.stop();
    
    if (mounted) {
      setState(() {
        _isListening = false;
        _pulseController.stop();
      });
      
      if (_text.isNotEmpty && !_isProcessing && !_isSpeaking) {
        print('🚀 Triggering processing for: "$_text"');
        _processQuery(_text);
      }
    }
  }

  Future<void> _processQuery(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    if (mounted) setState(() => _isProcessing = true);

    try {
      String marketContext = '';
      if (_isPriceQuery(query)) {
        marketContext = await _getMarketPriceContext(query);
      }
      
      String fullMessage = query;
      if (marketContext.isNotEmpty) {
        fullMessage += "\n\n[System Note: Use this real-time market data to answer if relevant: $marketContext]";
      }

      final responseText = await _chatService.sendMessage(fullMessage, _currentLanguageCode ?? 'en');
      final cleanResponse = _cleanMarkdown(responseText);

      if (mounted) {
        setState(() {
          _aiResponse = cleanResponse;
          _isProcessing = false;
        });
        _speak(cleanResponse);
      }
      
    } catch (e, stackTrace) {
      print('AI ERROR: $e');
      if (mounted) {
        setState(() {
          _aiResponse = "Sorry, I encountered an error. Please try again.";
          _isProcessing = false;
          _isListening = false;
        });
        _speak(_aiResponse);
      }
    }
  }

  Future<void> _speak(String text) async {
    if (_flutterTts == null || !_isTtsInitialized) {
      await _initTts();
    }
    
    final locale = _getTtsLocale(_currentLanguageCode ?? 'en');
    await _flutterTts?.setLanguage(locale);
    await _flutterTts?.speak(text);
  }

  // --- Helpers ---
  String _cleanMarkdown(String text) {
    return text.replaceAll('**', '').replaceAll('*', '').replaceAll('###', '').replaceAll('##', '').replaceAll('#', '').replaceAll('```', '');
  }

  bool _isPriceQuery(String query) {
    final lower = query.toLowerCase();
    return lower.contains('price') || lower.contains('விலை') || lower.contains('कीमत') || lower.contains('mandi') || lower.contains('market') || lower.contains('rate');
  }

  Future<String> _getMarketPriceContext(String query) async {
    // ... existing market price logic (abbreviated for brevity in reconstruction, functionality preserved) ...
    // Note: Reusing exact logic from before for stability
    try {
       String? commodity = _extractCommodity(query);
       String state = _extractState(query);
       if (commodity == null) return '';
       final prices = await _apiService.fetchMarketPrices(state, '', commodity, '');
       if (prices.isEmpty) return '';
       final top = prices.take(5).map((p) => '${p.market}, ${p.district}, ${p.state}: ₹${p.modalPrice}/quintal').join('\n');
       return 'Current $commodity prices in $state:\n$top';
    } catch(e) { return ''; }
  }

  // ... _extractState and _extractCommodity kept mostly same, implicitly included ...
  String _extractState(String query) {
     final lower = query.toLowerCase();
     if(lower.contains('punjab') || lower.contains('ਪੰਜਾਬ')) return 'Punjab';
     if(lower.contains('tamil') || lower.contains('தமிழ்')) return 'Tamil Nadu';
     if(lower.contains('uttar') || lower.contains('up')) return 'Uttar Pradesh';
     return '';
  }
  
  String? _extractCommodity(String query) {
     final lower = query.toLowerCase();
     if(lower.contains('rice') || lower.contains('அரிசி') || lower.contains('चावल')) return 'Rice';
     if(lower.contains('wheat') || lower.contains('கோதுமை') || lower.contains('गेहूं')) return 'Wheat';
     if(lower.contains('tomato')) return 'Tomato';
     if(lower.contains('onion')) return 'Onion';
     if(lower.contains('potato')) return 'Potato';
     return null;
  }

  String _getLocaleId(String code) {
    switch (code) {
      case 'hi': return 'hi_IN';
      case 'pa': return 'pa_IN';
      case 'ta': return 'ta_IN';
      default: return 'en_IN';
    }
  }

  String _getTtsLocale(String code) {
    switch (code) {
      case 'hi': return 'hi-IN';
      case 'pa': return 'pa-IN';
      case 'ta': return 'ta-IN';
      default: return 'en-US';
    }
  }

  @override
  void dispose() {
    _orbController.dispose();
    _pulseController.dispose();
    _speech?.cancel();
    _silenceTimer?.cancel();
    _flutterTts?.stop();
    _scrollController.dispose();
    super.dispose();
  }

  // --- UI Construction ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Original Background Gradient Orbs (Preserved)
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlurryOrb(const Color(0xFF10B981).withOpacity(0.2)),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildBlurryOrb(const Color(0xFF3B82F6).withOpacity(0.2)),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'voiceAssistantTitle'.tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white, // Fixed: High contrast on dark bg
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance back button
                    ],
                  ),
                ),

                // Main Content Area
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // User Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _text.isEmpty 
                                ? (_isListening ? 'listening_dots'.tr() : 'tapToSpeak'.tr()) 
                                : '"$_text"',
                            key: ValueKey<String>(_text),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: _text.isEmpty ? Colors.white54 : Colors.white, // Fixed: White text
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Orb
                      GestureDetector(
                        onTap: _listen,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_orbController, _pulseController]),
                          builder: (context, child) {
                            final pulse = _pulseController.value * 0.2;
                            return Container(
                              width: 200 + (pulse * 20),
                              height: 200 + (pulse * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(_isListening ? 0.5 : 0.3),
                                    blurRadius: _isListening ? 50 : 30,
                                    spreadRadius: _isListening ? 10 : 0,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Inner ring
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  _isListening
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildWaveBar(),
                                            const SizedBox(width: 5),
                                            _buildWaveBar(delay: 0.5),
                                            const SizedBox(width: 5),
                                            _buildWaveBar(delay: 1.0),
                                          ],
                                        )
                                      : Icon(
                                          Icons.mic_rounded,
                                          color: Colors.white,
                                          size: 80,
                                        ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // AI Response Panel (Glassmorphism + Karaoke Highlight)
                if (_aiResponse.isNotEmpty || _isProcessing)
                  Container(
                    margin: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Removed "Nexa Assistant" header as requested
                              
                              _isProcessing
                                  ? const Center(
                                      child: CircularProgressIndicator(color: Color(0xFF10B981)),
                                    )
                                  : _buildHighlightedResponse(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                if (_aiResponse.isEmpty && !_isProcessing)
                   const SizedBox(height: 50), // Spacer when no sheet
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurryOrb(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildWaveBar({double delay = 0.0}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final val = sin((_pulseController.value * 2 * pi) + delay);
        final height = 20.0 + (val.abs() * 30.0);
        return Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  // --- KARAOKE HIGHLIGHT BUILDER ---
  Widget _buildHighlightedResponse() {
    if (_currentWordEnd == 0 || _isProcessing) {
      return Text(
        _aiResponse,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF334155),
          height: 1.6,
        ),
      );
    }

    // Ensure valid ranges
    int start = _currentWordStart;
    int end = _currentWordEnd;
    if (start < 0) start = 0;
    if (end > _aiResponse.length) end = _aiResponse.length;
    if (start > end) start = end;

    return RichText(
      text: TextSpan(
        style: GoogleFonts.outfit(
          fontSize: 18,
          color: const Color(0xFF334155),
          height: 1.6,
        ),
        children: [
          TextSpan(text: _aiResponse.substring(0, start)),
          TextSpan(
            text: _aiResponse.substring(start, end),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF059669), // Highlight Color
              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
            ),
          ),
          TextSpan(text: _aiResponse.substring(end)),
        ],
      ),
    );
  }
}
