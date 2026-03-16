// lib/widgets/chatbot_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> with SingleTickerProviderStateMixin {
  bool _open = false;
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  final _messages = <ChatMessage>[
    ChatMessage(isBot: true, text: 'Xin chào! Tôi là trợ lý Phòng Trọ 4.0.\nTôi có thể giúp gì cho bạn?'),
  ];

  static const _botReplies = {
    'hóa đơn': 'Bạn có thể xem hóa đơn tại mục Hóa đơn trên menu. Hóa đơn quá hạn sẽ được đánh dấu đỏ.',
    'phòng': 'Danh sách phòng hiển thị đầy đủ trạng thái: Trống 🟢, Đang thuê 🔴, Sửa chữa 🟡. Bạn muốn tìm phòng nào?',
    'điện nước': 'Để nhập chỉ số điện nước, vào mục Điện/Nước và chọn kỳ thu. Hệ thống sẽ tự tính tiền cho bạn.',
    'hợp đồng': 'Hợp đồng sắp hết hạn sẽ được cảnh báo 30 ngày trước. Bạn có thể gia hạn trực tiếp từ chi tiết phòng.',
    'báo hỏng': 'Bạn có thể báo hỏng tại mục Bảo trì. Chủ trọ sẽ nhận được thông báo ngay lập tức.',
    'thanh toán': 'Bạn có thể thanh toán hóa đơn qua chuyển khoản hoặc tại văn phòng. Mã QR sẽ có trên mỗi hóa đơn.',
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) _animCtrl.forward(); else _animCtrl.reverse();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(isBot: false, text: text));
      final key = _botReplies.keys.firstWhere(
        (k) => text.toLowerCase().contains(k),
        orElse: () => '',
      );
      _messages.add(ChatMessage(
        isBot: true,
        text: key.isNotEmpty
            ? _botReplies[key]!
            : 'Tôi chưa hiểu câu hỏi này. Bạn thử hỏi về: hóa đơn, phòng, điện nước, hợp đồng, thanh toán, báo hỏng.',
      ));
    });
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Chat Panel
        ScaleTransition(
          scale: _scaleAnim,
          alignment: Alignment.bottomRight,
          child: _open ? _buildPanel() : const SizedBox.shrink(),
        ),

        // FAB
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: _open ? AppColors.foreground : AppColors.primary,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _open ? Icons.close : Icons.chat_bubble_outline,
                color: Colors.white, size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel() {
    return Container(
      width: 300,
      height: 380,
      margin: const EdgeInsets.only(bottom: 68),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Trợ lý PT 4.0',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _toggle,
                    child: const Icon(Icons.close, color: Colors.white70, size: 16),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: Container(
                color: AppColors.muted,
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _ChatBubble(_messages[i]),
                ),
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border, width: 2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.muted,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble(this.msg);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: msg.isBot ? AppColors.primary : AppColors.foreground.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: msg.isBot ? Radius.zero : const Radius.circular(12),
                  bottomRight: msg.isBot ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: msg.isBot ? Colors.white : AppColors.foreground,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
