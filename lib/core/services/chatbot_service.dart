// lib/core/services/chatbot_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:string_similarity/string_similarity.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser; // true = user message, false = bot message
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class ChatBotService {
  static final ChatBotService _instance = ChatBotService._();

  factory ChatBotService() => _instance;

  ChatBotService._() {
    _initializeAI();
    _initializeFaqCache();
  }

  final List<ChatMessage> _messages = [];
  bool _useAI = false;
  String _apiKey = '';
  static const String _messagesKey = 'chatbot_messages_history';
  static const String _apiKeyKey = 'openai_api_key';
  static const String _openaiUrl = 'https://api.openai.com/v1/chat/completions';

  // Cache FAQ data to avoid recreating every call
  late Map<String, List<String>> _faqCache;
  late Map<String, String> _responsesCache;
  bool _faqInitialized = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get useAI => _useAI;

  void _initializeFaqCache() {
    if (_faqInitialized) return;
    _faqCache = _expandedFaqs;
    _responsesCache = _responses;
    _faqInitialized = true;
  }

  // ===== AI INITIALIZATION =====
  void _initializeAI() {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString(_apiKeyKey);
      if (apiKey != null && apiKey.isNotEmpty) {
        _apiKey = apiKey;
        _useAI = true;
        debugPrint('✅ OpenAI API initialized');
      } else {
        _useAI = false;
        debugPrint('⚠️ OpenAI API key not set, using FAQ mode');
      }
    } catch (e) {
      debugPrint('❌ Error loading API key: $e');
      _useAI = false;
    }
  }

  /// Set OpenAI API key
  Future<void> setApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyKey, apiKey);
      _apiKey = apiKey;
      _useAI = true;
      debugPrint('✅ OpenAI API key set successfully');
    } catch (e) {
      debugPrint('❌ Error setting API key: $e');
    }
  }

  // ===== EXPANDED FAQ DATABASE =====
  Map<String, List<String>> get _expandedFaqs => {
    // ===== CHÀO HỎI =====
    'greeting': [
      'xin chào', 'hi', 'hello', 'chào', 'kéo', 'halo', 'yo',
    ],

    // ===== VỀ APP =====
    'about': [
      'app', 'green route', 'giới thiệu', 'about', 'là gì'
    ],

    // ===== HELP =====
    'help': [
      'giúp', 'hỗ trợ', 'help', 'trợ giúp', 'hướng dẫn', 'làm sao', 'cách nào'
    ],

    // ===== ĐĂNG KÝ & ĐĂNG NHẬP =====
    'register': [
      'đăng ký', 'đăng kí', 'register', 'tạo tài khoản', 'tạo account'
    ],
    'login': [
      'đăng nhập', 'login', 'vào app', 'mở app'
    ],
    'password': [
      'mật khẩu', 'password', 'quên mật khẩu', 'reset password', 'đổi mật khẩu'
    ],

    // ===== DRIVER (TÀI XẾ) =====
    'driver_register': [
      'đăng ký tài xế', 'tài xế đăng ký', 'driver register', 'làm tài xế'
    ],
    'driver_bidding': [
      'đặt giá', 'đấu thầu', 'bid', 'giá thầu', 'cách đặt giá', 'bidding'
    ],
    'driver_find_order': [
      'tìm đơn', 'tìm đơn hàng', 'find order', 'đơn nào', 'có đơn nào không'
    ],
    'driver_tracking': [
      'theo dõi', 'tracking', 'bản đồ', 'vị trí', 'đến đâu rồi'
    ],
    'driver_wallet': [
      'ví tiền', 'wallet', 'thanh toán', 'rút tiền', 'số dư', 'balance'
    ],
    'driver_documents': [
      'xác minh', 'tài liệu', 'cccd', 'bằng lái', 'documents', 'verification'
    ],

    // ===== SHIPPER (CHỦ HÀNG) =====
    'shipper_register': [
      'đăng ký chủ hàng', 'shipper', 'chủ hàng đăng ký', 'register shipper'
    ],
    'shipper_create_order': [
      'đăng tìm tài xế', 'tạo đơn', 'create order', 'post order', 'gửi đơn'
    ],
    'shipper_receive_bids': [
      'bids', 'giá từ tài xế', 'receive bids', 'xem giá', 'xem bids'
    ],
    'shipper_tracking': [
      'theo dõi giao hàng', 'shipper tracking', 'track shipment'
    ],

    // ===== THANH TOÁN & TÀI CHÍNH =====
    'payment': [
      'thanh toán', 'payment', 'trả tiền', 'hoá đơn', 'invoice', 'chi phí'
    ],
    'withdrawal': [
      'rút tiền', 'withdrawal', 'lấy tiền', 'transfer', 'chuyển tiền'
    ],
    'fee': [
      'phí', 'fee', 'charge', 'mức phí', 'tính phí'
    ],

    // ===== BẢNG GIÁ & GIỚI HẠN =====
    'pricing': [
      'bảng giá', 'giá', 'pricing', 'bao nhiêu tiền'
    ],
    'limit': [
      'giới hạn', 'limit', 'tối đa', 'maximum', 'tối thiểu', 'minimum'
    ],

    // ===== VẤNĐỀ & LỖI =====
    'error': [
      'lỗi', 'error', 'sự cố', 'không hoạt động', 'bị lỗi', 'bug'
    ],
    'connection': [
      'kết nối', 'internet', 'wifi', 'connection', 'mạng', 'offline'
    ],
    'technical': [
      'kỹ thuật', 'technical', 'lỗi ứng dụng', 'crash', 'lag', 'giật'
    ],

    // ===== LIÊN HỆ & HỖ TRỢ =====
    'contact': [
      'liên hệ', 'contact', 'hotline', 'số điện thoại', 'email', 'gọi', 'call'
    ],
    'support': [
      'hỗ trợ', 'support', 'giúp đỡ', 'customer service', 'dịch vụ khách hàng'
    ],
    'complaint': [
      'khiếu nại', 'complaint', 'phàn nàn', 'tố cáo', 'báo cáo'
    ],

    // ===== CHÍNH SÁCH =====
    'policy': [
      'chính sách', 'policy', 'điều khoản', 'terms', 'quy định', 'rules'
    ],
    'security': [
      'bảo mật', 'security', 'an toàn', 'safe', 'riêng tư', 'privacy'
    ],
    'terms': [
      'điều khoản', 'terms', 'terms and conditions', 'quy tắc'
    ],

    // ===== KHÁC =====
    'clear': [
      'xóa chat', 'clear', 'xóa tin nhắn', 'làm sạch'
    ],
    'feedback': [
      'phản hồi', 'feedback', 'ý kiến', 'suggestion', 'đề xuất'
    ],
  };

  Map<String, String> get _responses => {
    'greeting': 'Xin chào! 👋 Tôi là chatbot hỗ trợ Green Route.\n\n🤖 Tôi sử dụng AI để trả lời câu hỏi của bạn một cách thông minh nhất. Nếu bạn có bất kỳ câu hỏi nào về app, hãy hỏi tôi!',

    'about': 'Green Route là nền tảng kết nối thông minh giữa tài xế và chủ hàng, giúp:\n✅ Tối ưu hóa chi phí vận chuyển\n✅ Giảm thời gian chờ đợi\n✅ Nâng cao độ tin cậy\n✅ Theo dõi giao hàng real-time\n\nChúng tôi phục vụ khắp Việt Nam 🇻🇳',

    'help': 'Tôi có thể giúp bạn với:\n\n👤 **Tài Xế:**\n• Đăng ký & xác minh tài liệu\n• Tìm & đấu thầu đơn hàng\n• Theo dõi giao hàng\n• Quản lý ví tiền\n\n📦 **Chủ Hàng:**\n• Đăng ký & xác minh\n• Tạo đơn hàng\n• Xem giá từ tài xế\n• Theo dõi giao\n\n💬 Hãy nói tôi biết bạn là ai và cần gì!',

    'register': 'Để đăng ký tài khoản Green Route:\n\n1️⃣ **Nhập số điện thoại** (10 chữ số)\n2️⃣ **Nhập OTP** (mã xác nhận gửi vào SMS)\n3️⃣ **Đặt mật khẩu** (tối thiểu 8 ký tự)\n4️⃣ **Chọn vai trò:** Tài xế hoặc Chủ hàng\n5️⃣ **Xác minh tài liệu**\n6️⃣ **Bắt đầu sử dụng!** 🎉',

    'login': 'Để đăng nhập: Nhập số điện thoại/username, mật khẩu và bấm ĐĂNG NHẬP.\n\n💡 Quên mật khẩu? Bấm "Quên mật khẩu?" để đặt lại.',

    'password': 'Để đặt lại mật khẩu:\n1️⃣ Bấm "Quên mật khẩu?" ở màn hình đăng nhập\n2️⃣ Nhập số điện thoại\n3️⃣ Nhận OTP qua SMS\n4️⃣ Nhập OTP\n5️⃣ Đặt mật khẩu mới',

    'driver_register': 'Để đăng ký tài xế cần: CCCD/CMND, Bằng lái xe, Phương tiện.\n\n📸 Upload tài liệu và chờ duyệt (24-48 giờ).',

    'driver_bidding': 'Cách đặt giá:\n1️⃣ Vào tab "Đề Xuất"\n2️⃣ Chọn đơn hàng\n3️⃣ Bấm "Đặt Giá"\n4️⃣ Nhập giá của bạn\n5️⃣ Bấm "Gửi Bid"',

    'driver_find_order': 'Cách tìm đơn:\n📍 Chọn tuyến trong tuần\n🔍 Lọc theo địa bàn, trọng lượng, giá\n⭐ Tài xế rating cao dễ được chọn',

    'driver_tracking': 'Theo dõi giao:\n🗺️ Vào đơn hàng → "Bản Đồ"\n📊 Xem vị trí, khoảng cách, thời gian\n💬 Chat trực tiếp với chủ hàng',

    'driver_wallet': 'Ví tiền:\n💰 Xem số dư, lịch sử giao dịch\n🏧 Rút tiền (tối thiểu 50k)\n⏱️ Rút thành công trong 1-2 giờ',

    'driver_documents': 'Xác minh tài liệu:\n📋 Cần CCCD/CMND, Bằng lái, Ảnh selfie\n✅ Trạng thái: Pending → Approved\n❌ Nếu bị từ chối, upload lại',

    'shipper_register': 'Đăng ký chủ hàng:\n📋 Cần CCCD/CMND, Số điện thoại\n📸 Upload 2 ảnh CCCD + ảnh selfie\n⏱️ Xác minh 24-48 giờ',

    'shipper_create_order': 'Đăng tìm tài xế:\n1️⃣ Bấm "Đăng Tìm Tài Xế"\n2️⃣ Nhập địa chỉ, loại hàng, giá\n3️⃣ Upload ảnh hàng\n4️⃣ Bấm "Đăng Đơn"\n5️⃣ Xem bids từ tài xế',

    'shipper_receive_bids': 'Chọn tài xế:\n📊 Xem danh sách bids\n⭐ Chọn tài xế có rating cao, giá hợp lý\n💼 Bấm "Chấp Nhận" để xác nhận',

    'shipper_tracking': 'Theo dõi:\n🗺️ Xem vị trí tài xế real-time\n📞 Chat hoặc gọi tài xế\n✅ Xác nhận nhận hàng',

    'payment': 'Thanh toán:\n💳 Ví trong app, Thẻ tín dụng, COD\n🔒 Mã hóa 256-bit, an toàn\n⏱️ Tài xế nhận tiền ngay',

    'withdrawal': 'Rút tiền:\n1️⃣ Ví > Rút Tiền\n2️⃣ Nhập số tiền (tối thiểu 50k)\n3️⃣ Chọn ngân hàng\n4️⃣ Xác nhận\n⏱️ 1-2 giờ',

    'fee': 'Phí:\n💸 Tài xế: 8%\n💳 Thẻ: 1-2%\n🆓 Rút tiền: Miễn phí 3 lần/tháng',

    'pricing': 'Bảng giá:\nGiá = Phí Cơ Sở + (Km × Giá/km) + (Kg × Giá/kg)\n\nVí dụ: 10km, 5kg = 20k + 20k + 25k = 65k',

    'limit': 'Giới hạn:\n📦 Trọng lượng: 0.5-30kg\n💰 Giá dự tính: tùy ý\n⏱️ Bid trong 24 giờ\n👤 Rating tài xế < 3⭐ bị hạn chế',

    'error': 'Khắc phục lỗi:\n1️⃣ Đóng app hoàn toàn\n2️⃣ Mở lại\n3️⃣ Đăng xuất & đăng nhập\n4️⃣ Cập nhật app\n5️⃣ Xóa cache\n\n📞 Vẫn lỗi? Liên hệ hỗ trợ',

    'connection': 'Vấn đề kết nối:\n🌐 Bật/Tắt WiFi\n📶 Chuyển 4G/5G\n🔧 Khởi động lại điện thoại\n💡 Đứng gần router WiFi',

    'technical': 'Sự cố kỹ thuật:\n🐛 App lag: Xóa cache, cập nhật\n💥 App crash: Cập nhật OS, gỡ cài lại\n⚠️ Lỗi giao dịch: Liên hệ hỗ trợ',

    'contact': 'Liên hệ hỗ trợ:\n📞 Hotline: 1900-XXXX (24/7)\n📧 Email: support@greenroute.vn\n💬 Chat trong app\n🌐 www.greenroute.vn',

    'support': 'Hỗ trợ:\n👨‍💼 Team 24/7\n🎯 Xử lý khiếu nại trong 24h\n💰 Hoàn tiền nếu lỗi hệ thống',

    'complaint': 'Khiếu nại:\n1️⃣ Settings > Khiếu Nại\n2️⃣ Mô tả vấn đề\n3️⃣ Upload bằng chứng\n⏱️ Xử lý 5-7 ngày\n💰 Bồi thường tối đa 100%',

    'policy': 'Chính sách:\n📜 Tuân thủ pháp luật VN\n🔄 Hủy < 1h: Hoàn 100%\n🔄 Hủy 1-2h: Hoàn 50%\n🔄 Hủy > 2h: Không hoàn',

    'security': 'Bảo mật:\n🔒 Mã hóa SSL 256-bit\n🛡️ Xác minh 2 lớp\n👤 Không chia sẻ dữ liệu',

    'terms': 'Điều khoản:\n✅ Bạn phải ≥18 tuổi\n⛔ Cấm: Lạm dụng, gian lận, bạo lực\n⚖️ Vi phạm: Cảnh báo → Khóa tài khoản',

    'clear': 'Xóa chat:\n1️⃣ Chat > ⋮ (3 chấm)\n2️⃣ "Xóa Lịch Sử Chat"\n3️⃣ Xác nhận\n⚠️ Không thể hoàn tác',

    'feedback': 'Phản hồi:\n1️⃣ Settings > Phản Hồi\n2️⃣ Chọn loại lỗi/đề xuất\n3️⃣ Mô tả chi tiết\n4️⃣ Bấm Gửi\n🎁 Phản hồi hay: +5 điểm',
  };

  void addMessage(ChatMessage message) {
    _messages.add(message);
  }

  void clearMessages() {
    _messages.clear();
  }

  // ===== SAVE & LOAD HISTORY =====
  Future<void> saveMessageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();
      await prefs.setStringList(_messagesKey, messagesJson);
      debugPrint('✅ Chat history saved (${_messages.length} messages)');
    } catch (e) {
      debugPrint('❌ Error saving chat history: $e');
    }
  }

  Future<void> loadMessageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList(_messagesKey) ?? [];
      _messages.clear();
      for (final json in messagesJson) {
        final msg = ChatMessage.fromJson(jsonDecode(json));
        _messages.add(msg);
      }
      debugPrint('✅ Chat history loaded (${_messages.length} messages)');
    } catch (e) {
      debugPrint('❌ Error loading chat history: $e');
    }
  }

  // ===== FUZZY/SIMILARITY SEARCH FOR SMARTER NLU =====
  String _findBestMatchedCategory(String input) {
    final lowerInput = input.toLowerCase().trim();
    String bestCategory = 'help';
    double highestScore = 0;

    // Quick keyword matching (fast path)
    for (final category in _faqCache.keys) {
      final keywords = _faqCache[category]!;
      for (final keyword in keywords) {
        final lowerKeyword = keyword.toLowerCase();
        
        // Exact match wins immediately
        if (lowerInput == lowerKeyword) {
          return category;
        }
        
        // Substring match is fast
        if (lowerInput.contains(lowerKeyword) || lowerKeyword.contains(lowerInput)) {
          return category;
        }
        
        // Similarity calculation (more expensive, but with early exit)
        final similarity = StringSimilarity.compareTwoStrings(lowerInput, lowerKeyword);
        if (similarity > 0.8) { // High threshold to stop early
          return category;
        }
        
        if (similarity > highestScore) {
          highestScore = similarity;
          bestCategory = category;
        }
      }
    }

    debugPrint('🔍 Fuzzy match: "$input" → "$bestCategory" (score: ${(highestScore * 100).toStringAsFixed(1)}%)');
    return bestCategory;
  }

  // ===== AI-POWERED RESPONSE GENERATION =====
  Future<String> generateResponse(String userInput) async {
    // Initialize FAQ cache if needed
    _initializeFaqCache();
    
    final lowerInput = userInput.toLowerCase();
    
    // Fast FAQ-only path for common greetings and quick replies
    final isQuickReply = ['xin chào', 'hello', 'hi', 'giúp', 'help', 'hỗ trợ', 'support'].any((q) => lowerInput.contains(q));
    
    if (isQuickReply || !_useAI || _apiKey.isEmpty) {
      return _generateFAQResponse(userInput);
    }

    // AI path only for complex questions with timeout
    try {
      final response = await _generateAIResponse(userInput)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint('⏱️ AI request timeout, fallback to FAQ');
              return _generateFAQResponse(userInput);
            },
          );
      return response;
    } catch (e) {
      debugPrint('⚠️ AI error, falling back to FAQ: $e');
      return _generateFAQResponse(userInput);
    }
  }

  /// Generate response using OpenAI API via HTTP
  Future<String> _generateAIResponse(String userInput) async {
    try {
      debugPrint('🤖 Calling OpenAI API...');
      
      final response = await http.post(
        Uri.parse(_openaiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''Bạn là chatbot hỗ trợ khách hàng của Green Route - một nền tảng kết nối tài xế và chủ hàng.
              
Hướng dẫn:
1. Trả lời bằng tiếng Việt, thân thiện và chuyên nghiệp
2. Giới hạn câu trả lời trong 200 từ
3. Sử dụng emoji phù hợp để tăng tính hấp dẫn
4. Nếu không biết, hãy nói "Xin lỗi, tôi chưa có thông tin về vấn đề này. Vui lòng liên hệ hỗ trợ."
5. Luôn gợi ý liên hệ hỗ trợ khi cần thiết''',
            },
            {
              'role': 'user',
              'content': userInput,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'] ?? '';
        debugPrint('✅ AI Response received: ${aiResponse.length} chars');
        return aiResponse;
      } else {
        debugPrint('❌ OpenAI API error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ OpenAI error: $e');
      throw Exception('AI Error: $e');
    }
  }

  /// Generate response using expanded FAQ with fuzzy matching
  String _generateFAQResponse(String userInput) {
    final category = _findBestMatchedCategory(userInput);
    final response = _responsesCache[category] ?? _responsesCache['help'];
    return response ?? 'Xin lỗi, tôi chưa hiểu. Hãy thử hỏi cách khác 😊';
  }

  /// Get quick reply suggestions
  List<String> getQuickReplies() {
    return [
      '📖 Hướng dẫn sử dụng',
      '🚗 Tài xế',
      '📦 Chủ hàng',
      '💳 Thanh toán',
      '❓ Giúp đỡ',
      '🗑️ Xóa chat',
    ];
  }
}
