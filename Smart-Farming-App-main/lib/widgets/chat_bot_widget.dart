import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class ChatBotWidget extends StatefulWidget {
  const ChatBotWidget({super.key});

  @override
  State<ChatBotWidget> createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends State<ChatBotWidget> {
  bool _isOpen = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale.languageCode;
    
    // Reset chat when language changes
    if (_lastLocale != null && _lastLocale != currentLocale) {
      // Language changed - reset everything
      setState(() {
        _chatService = ChatService(); // Create new chat session
        _messages = [
          {
            "text": tr('welcomeMessage'),
            "isUser": false,
          }
        ];
      });
    } else if (_messages.isEmpty) {
      // Initial load
      setState(() {
        _messages = [
          {
            "text": tr('welcomeMessage'),
            "isUser": false,
          }
        ];
      });
    }
    
    _lastLocale = currentLocale;
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text;
    setState(() {
      _messages.add({"text": userMessage, "isUser": true});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        userMessage, 
        context.locale.languageCode,
      );
      setState(() {
        _messages.add({"text": response, "isUser": false});
      });
    } catch (e) {
      setState(() {
        _messages.add({"text": "Error: $e", "isUser": false});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Positioned.fill(
      child: Stack(
        children: [
          if (_isOpen)
            GestureDetector(
              onTap: _toggleChat,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          Positioned(
            bottom: 90 + bottomPadding,
            right: 20,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isOpen)
                    Container(
                      width: 300,
                      height: 400,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                        // Messages
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length + (_isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length) {
                                  return const Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        width: 24, 
                                        height: 24, 
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF15803D))
                                      ),
                                    ),
                                  );
                                }
                                
                                final msg = _messages[index];
                                final isUser = msg["isUser"] as bool;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isUser) ...[
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF15803D),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(LucideIcons.bot, color: Colors.white, size: 16),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isUser ? const Color(0xFF15803D) : (isDark ? const Color(0xFF334155) : Colors.white),
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(16),
                                              topRight: const Radius.circular(16),
                                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                                              bottomRight: Radius.circular(isUser ? 4 : 16),
                                            ),
                                            boxShadow: [
                                              if (!isUser)
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.05),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                            ],
                                          ),
                                          child: isUser 
                                            ? Text(
                                                msg["text"], 
                                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                              )
                                            : MarkdownBody(
                                                data: msg["text"],
                                                styleSheet: MarkdownStyleSheet(
                                                  p: TextStyle(color: isDark ? Colors.white : const Color(0xFF334155), fontSize: 13),
                                                ),
                                              ),
                                        ),
                                      ),
                                      if (isUser) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(LucideIcons.user, color: isDark ? Colors.white70 : Colors.grey, size: 16),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Input
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: Border(top: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLines: 1,
                                  textInputAction: TextInputAction.send,
                                  textCapitalization: TextCapitalization.none,
                                  keyboardType: TextInputType.text,
                                  autocorrect: true,
                                  enableSuggestions: true,
                                  decoration: InputDecoration(
                                    hintText: "askAnything".tr(),
                                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    isDense: true,
                                  ),
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _isLoading ? null : _sendMessage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF15803D),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isLoading 
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(LucideIcons.send, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Floating Button
                  FloatingActionButton(
                    onPressed: _toggleChat,
                    backgroundColor: const Color(0xFF15803D),
                    child: Icon(_isOpen ? LucideIcons.chevronDown : LucideIcons.messageCircle, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
