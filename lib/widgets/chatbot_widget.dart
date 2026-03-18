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

class _ChatbotWidgetState extends State<ChatbotWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  // ValueNotifier thay setState — tránh rebuild toàn widget khi chỉ toggle panel
  final _openNotifier     = ValueNotifier<bool>(false);
  final _messagesNotifier = ValueNotifier<List<ChatMessage>>([
    ChatMessage(isBot: true, text: 'Xin chào! Tôi là trợ lý Phòng Trọ 4.0.\nTôi có thể giúp gì cho bạn?'),
  ]);

  final _ctrl      = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _botReplies = <String, String>{
    'hóa đơn':   'Bạn có thể xem hóa đơn tại mục Hóa đơn. Hóa đơn quá hạn sẽ được đánh dấu đỏ.',
    'phòng':     'Danh sách phòng hiển thị đầy đủ trạng thái: Trống 🟢, Đang thuê 🔴, Sửa chữa 🟡.',
    'điện nước': 'Vào mục Điện/Nước, chọn kỳ thu. Hệ thống sẽ tự tính tiền cho bạn.',
    'hợp đồng':  'Hợp đồng sắp hết hạn sẽ được cảnh báo 30 ngày trước.',
    'báo hỏng':  'Bạn có thể báo hỏng tại mục Bảo trì.',
    'thanh toán':'Thanh toán qua chuyển khoản hoặc tại văn phòng. Mã QR có trên mỗi hóa đơn.',
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
    _openNotifier.dispose();
    _messagesNotifier.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !_openNotifier.value;
    _openNotifier.value = next;
    if (next) _animCtrl.forward(); else _animCtrl.reverse();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final reply = _botReplies.entries
        .firstWhere((e) => text.toLowerCase().contains(e.key), orElse: () => const MapEntry('', ''))
        .value;

    // Cập nhật list immutably — ValueNotifier trigger rebuild chỉ cho ListView
    _messagesNotifier.value = [
      ..._messagesNotifier.value,
      ChatMessage(isBot: false, text: text),
      ChatMessage(
        isBot: true,
        text: reply.isNotEmpty ? reply : 'Tôi chưa hiểu. Thử hỏi: hóa đơn, phòng, điện nước, hợp đồng, thanh toán, báo hỏng.',
      ),
    ];

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
        // Panel — ScaleTransition + ValueListenableBuilder (rebuild chỉ khi open)
        ValueListenableBuilder<bool>(
          valueListenable: _openNotifier,
          builder: (_, open, __) => ScaleTransition(
            scale: _scaleAnim,
            alignment: Alignment.bottomRight,
            child: open
                ? _ChatPanel(
              scrollCtrl: _scrollCtrl,
              messagesNotifier: _messagesNotifier,
              ctrl: _ctrl,
              onSend: _send,
              onClose: _toggle,
            )
                : const SizedBox.shrink(),
          ),
        ),

        // FAB — rebuild chỉ khi open state thay đổi
        Positioned(
          bottom: 0, right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: _openNotifier,
            builder: (_, open, __) => _ChatFab(open: open, onTap: _toggle),
          ),
        ),
      ],
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _ChatFab extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;

  const _ChatFab({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54, height: 54,
        decoration: BoxDecoration(
          color: open ? AppColors.foreground : AppColors.primary,
          borderRadius: BorderRadius.circular(27),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Icon(open ? Icons.close : Icons.chat_bubble_outline, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─── Chat Panel ───────────────────────────────────────────────────────────────

class _ChatPanel extends StatelessWidget {
  final ScrollController scrollCtrl;
  final ValueNotifier<List<ChatMessage>> messagesNotifier;
  final TextEditingController ctrl;
  final VoidCallback onSend, onClose;

  const _ChatPanel({
    required this.scrollCtrl, required this.messagesNotifier,
    required this.ctrl, required this.onSend, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 380,
      margin: const EdgeInsets.only(bottom: 68),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(children: [
          // Header — const
          const _ChatHeader(),
          // Messages — ValueListenableBuilder rebuild chỉ phần này
          Expanded(
            child: ColoredBox(
              color: AppColors.muted,
              child: ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: messagesNotifier,
                builder: (_, messages, __) => ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  // itemBuilder lazy — chỉ build bubble đang visible
                  itemBuilder: (_, i) => RepaintBoundary(child: _ChatBubble(messages[i])),
                ),
              ),
            ),
          ),
          // Input
          _ChatInput(ctrl: ctrl, onSend: onSend),
        ]),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(children: [
        const Icon(Icons.support_agent, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('Trợ lý PT 4.0',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        const Spacer(),
        // Close button handled by parent
      ]),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;

  const _ChatInput({required this.ctrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            onSubmitted: (_) => onSend(),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Nhập câu hỏi...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true, fillColor: AppColors.muted,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSend,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
          ),
        ),
      ]),
    );
  }
}

// ─── Chat Bubble ──────────────────────────────────────────────────────────────

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
              child: Text(msg.text,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, height: 1.5,
                    color: msg.isBot ? Colors.white : AppColors.foreground,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}