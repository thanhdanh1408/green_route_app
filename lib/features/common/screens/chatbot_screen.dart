// lib/features/common/screens/chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _chatBotService = ChatBotService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    
    // Load chat history
    await _chatBotService.loadMessageHistory();
    
    setState(() {
      _messages = _chatBotService.messages.isEmpty
          ? [
              ChatMessage(
                id: const Uuid().v4(),
                text: 'Xin chào! 👋 Tôi là chatbot hỗ trợ Green Route.\n\n🤖 Tôi sử dụng AI để trả lời câu hỏi của bạn một cách thông minh nhất. Nếu bạn có bất kỳ câu hỏi nào về app, hãy hỏi tôi!',
                isUser: false,
                timestamp: DateTime.now(),
              )
            ]
          : _chatBotService.messages;
      _isLoading = false;
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);

    // Add user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });

    _textController.clear();
    _scrollToBottom();

    try {
      // Generate bot response (with AI or FAQ)
      final response = await _chatBotService.generateResponse(text);
      
      final botMessage = ChatMessage(
        id: const Uuid().v4(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(botMessage);
        _isSendingMessage = false;
      });

      // Save history
      _chatBotService.addMessage(userMessage);
      _chatBotService.addMessage(botMessage);
      await _chatBotService.saveMessageHistory();

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error generating response: $e');
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        text: '❌ Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau.\n\nLỗi: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(errorMessage);
        _isSendingMessage = false;
      });
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

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử chat?'),
        content: const Text('Bạn chắc chắn muốn xóa tất cả cuộc trò chuyện không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _chatBotService.clearMessages();
      await _initializeChat();
    }
  }

  Future<void> _setApiKey() async {
    final controller = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thiết lập OpenAI API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập OpenAI API Key để bật chế độ AI thông minh'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'sk-...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _chatBotService.setApiKey(controller.text);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ API Key đã được lưu')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Trợ lý ảo', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            _chatBotService.useAI
                ? Tooltip(
                    message: 'Sử dụng AI (OpenAI)',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '🤖 AI',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  )
                : Tooltip(
                    message: 'Sử dụng FAQ (Cần API Key)',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '📚 FAQ',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_chatBotService.useAI)
            IconButton(
              icon: const Icon(Icons.key),
              onPressed: _setApiKey,
              tooltip: 'Thiết lập API Key',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: 'Xóa lịch sử chat',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Chat messages
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có tin nhắn',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message);
                          },
                        ),
                ),

                // Typing indicator
                if (_isSendingMessage)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick replies
                if (_messages.isNotEmpty && !_isSendingMessage)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: _chatBotService.getQuickReplies().map((reply) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                            ),
                            onPressed: () => _sendMessage(reply),
                            child: Text(
                              reply,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Input area
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          enabled: !_isSendingMessage,
                          decoration: InputDecoration(
                            hintText: 'Nhập câu hỏi...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        onPressed: _isSendingMessage
                            ? null
                            : () => _sendMessage(_textController.text),
                        child: _isSendingMessage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
