// lib/core/services/chatbot_service.dart
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
}

class ChatBotService {
  static final ChatBotService _instance = ChatBotService._();

  factory ChatBotService() => _instance;

  ChatBotService._();

  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void addMessage(ChatMessage message) {
    _messages.add(message);
  }

  void clearMessages() {
    _messages.clear();
  }

  /// Generate bot response based on user input
  String generateResponse(String userInput) {
    final input = userInput.toLowerCase().trim();

    // FAQ Database - Cơ sở dữ liệu câu hỏi thường gặp
    final faqs = {
      // Câu hỏi chung
      'app': 'Đây là ứng dụng Green Route - nền tảng kết nối tài xế và chủ hàng để giao hàng hiệu quả.',
      'giúp': 'Tôi có thể giúp bạn với: Hỏi về các tính năng, hướng dẫn sử dụng, hoặc kiểm tra trạng thái đơn hàng.',
      'xin chào': 'Xin chào! 👋 Tôi là chatbot hỗ trợ Green Route. Bạn cần giúp gì không?',
      'hi': 'Xin chào! 👋 Tôi là chatbot hỗ trợ Green Route. Bạn cần giúp gì không?',
      'hello': 'Xin chào! 👋 Tôi là chatbot hỗ trợ Green Route. Bạn cần giúp gì không?',

      // Câu hỏi về tài xế
      'tài xế': 'Tôi là tài xế, có thể tôi có thể giúp? Hỏi về: đăng ký, tìm đơn hàng, đấu thầu, theo dõi, lịch sử, ví tiền.',
      'đăng ký tài xế': 'Để đăng ký tài xế:\n1. Nhập số điện thoại\n2. Đặt mật khẩu\n3. Chọn tuyến đường\n4. Hoàn tất xác minh tài liệu\n5. Bắt đầu nhận đơn hàng',
      'cách đặt giá thầu': 'Để đặt giá thầu:\n1. Vào tab "Đề xuất"\n2. Chọn đơn hàng\n3. Bấm "Đặt giá"\n4. Nhập giá đề xuất\n5. Bấm "Gửi" để gửi bid',
      'tìm đơn': 'Để tìm đơn hàng:\n1. Đăng nhập tài xế\n2. Chọn tuyến đường\n3. Xem tab "Đề xuất"\n4. Chọn đơn và đặt giá\n5. Chờ chủ hàng chấp nhận',
      'thanh toán': 'Thanh toán được xử lý qua ví tiền trong app. Khi đơn hoàn thành, tiền sẽ được cộng vào ví.',
      'rút tiền': 'Bạn có thể rút tiền từ ví vào tài khoản ngân hàng. Vào tab "Ví" để xem hướng dẫn chi tiết.',

      // Câu hỏi về chủ hàng
      'chủ hàng': 'Bạn là chủ hàng? Có thể tôi giúp: đăng tìm tài xế, xem bids, theo dõi giao hàng, lịch sử, ví tiền.',
      'đăng tìm tài xế': 'Để đăng tìm tài xế:\n1. Bấm nút "Đăng tìm tài xế"\n2. Nhập thông tin chuyến hàng\n3. Đợi tài xế gửi giá\n4. Chọn tài xế phù hợp\n5. Xác nhận giao hàng',
      'xem bids': 'Để xem giá từ tài xế:\n1. Vào tab "Bids từ tài xế"\n2. Chọn bid để xem chi tiết\n3. Bấm "Chấp nhận" để chọn tài xế',
      'theo dõi giao': 'Để theo dõi giao hàng:\n1. Vào tab "Đơn hàng"\n2. Chọn đơn đang giao\n3. Bấm vào để xem vị trí tài xế trên bản đồ',

      // Câu hỏi về xác minh
      'xác minh': 'Xác minh tài liệu là bắt buộc. Bạn cần gửi: CCCD/CMND, Bằng lái (tài xế).',
      'cccd': 'Bạn cần gửi ảnh rõ ràng của CCCD/CMND (2 mặt) để xác minh tài khoản.',
      'bằng lái': 'Tài xế cần gửi ảnh Bằng lái xe để xác minh.',

      // Câu hỏi về lỗi
      'lỗi': 'Có vấn đề gì không? Xin vui lòng mô tả chi tiết để tôi giúp bạn.',
      'không hoạt động': 'Thử:\n1. Đóng app và mở lại\n2. Kiểm tra kết nối internet\n3. Cập nhật app lên phiên bản mới nhất\n4. Nếu vẫn lỗi, hãy liên hệ hỗ trợ',

      // Câu hỏi về bảo mật
      'mật khẩu': 'Mật khẩu của bạn được mã hóa an toàn. Không chia sẻ mật khẩu với ai.',
      'bảo mật': 'Green Route bảo vệ dữ liệu của bạn. Mọi giao dịch được mã hóa.',

      // Câu hỏi về liên hệ
      'liên hệ': 'Để liên hệ hỗ trợ:\n📞 Hotline: 1800-xxxx\n📧 Email: support@greenroute.com\n⏰ Giờ hỗ trợ: 8:00 - 20:00 hàng ngày',
      'hỗ trợ': 'Để liên hệ hỗ trợ:\n📞 Hotline: 1800-xxxx\n📧 Email: support@greenroute.com',
    };

    // Tìm kiếm answer dựa trên keywords
    for (final key in faqs.keys) {
      if (input.contains(key)) {
        return faqs[key] ?? '';
      }
    }

    // Nếu không tìm thấy câu trả lời
    return 'Xin lỗi, tôi chưa hiểu câu hỏi của bạn. 😊\n\nCâu hỏi phổ biến:\n• Làm sao để đăng ký?\n• Cách đặt giá thầu?\n• Làm sao theo dõi giao hàng?\n• Liên hệ hỗ trợ?\n\nHãy thử hỏi những câu hỏi trên!';
  }

  /// Get quick reply suggestions based on context
  List<String> getQuickReplies() {
    return [
      'Hướng dẫn sử dụng',
      'Làm sao đăng ký?',
      'Liên hệ hỗ trợ',
      'Xóa chat',
    ];
  }
}
