// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/api.dart';

// ─── Status Badge ─────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final RoomStatus? roomStatus;
  final InvoiceStatus? invoiceStatus;

  const StatusBadge.room(this.roomStatus, {super.key}) : invoiceStatus = null;
  const StatusBadge.invoice(this.invoiceStatus, {super.key}) : roomStatus = null;

  @override
  Widget build(BuildContext context) {
    final cfg = roomStatus != null
        ? _roomConfig(roomStatus!)
        : _invoiceConfig(invoiceStatus!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: cfg.dot, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(cfg.label.toUpperCase(),
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: cfg.text, letterSpacing: 0.8)),
      ]),
    );
  }

  // FIX: Exhaustive switch — đủ tất cả 5 giá trị enum
  _BadgeCfg _roomConfig(RoomStatus s) => switch (s) {
    RoomStatus.available   => _BadgeCfg('Trống',     AppColors.successLight, AppColors.successDark, AppColors.success),
    RoomStatus.occupied    => _BadgeCfg('Đang thuê', AppColors.dangerLight,  AppColors.dangerDark,  AppColors.danger),
    RoomStatus.rented      => _BadgeCfg('Đang thuê', AppColors.dangerLight,  AppColors.dangerDark,  AppColors.danger),
    RoomStatus.deposited   => _BadgeCfg('Đặt cọc',  const Color(0xFFEDE9FE), const Color(0xFF4C1D95), const Color(0xFF7C3AED)),
    RoomStatus.maintenance => _BadgeCfg('Sửa chữa', AppColors.warningLight, AppColors.warningDark, AppColors.warning),
  };

  _BadgeCfg _invoiceConfig(InvoiceStatus s) => switch (s) {
    InvoiceStatus.paid    => _BadgeCfg('Đã thanh toán',  AppColors.success, Colors.white, AppColors.successLight),
    InvoiceStatus.pending => _BadgeCfg('Chờ thanh toán', AppColors.warning, Colors.white, AppColors.warningLight),
    InvoiceStatus.overdue => _BadgeCfg('Quá hạn',        AppColors.danger,  Colors.white, AppColors.dangerLight),
  };
}

class _BadgeCfg {
  final String label;
  final Color bg, text, dot;
  const _BadgeCfg(this.label, this.bg, this.text, this.dot);
}

// ─── Global helper — dùng bởi dashboard_screen ────────────────────────────────

/// Trả về màu accent theo trạng thái phòng.
/// Exhaustive switch — đủ tất cả 5 case.
Color statusAccentColor(RoomStatus s) => switch (s) {
  RoomStatus.available   => AppColors.success,
  RoomStatus.occupied    => AppColors.danger,
  RoomStatus.rented      => AppColors.danger,
  RoomStatus.deposited   => const Color(0xFF8B5CF6),
  RoomStatus.maintenance => AppColors.warning,
};

// ─── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? subtitle;
  final Color color;
  final double? trend;

  const StatCard({
    super.key,
    required this.icon, required this.label, required this.value,
    this.subtitle, required this.color, this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          if (trend != null)
            Row(children: [
              Icon(trend! >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white70, size: 12),
              Text('${trend!.abs().toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
        ]),
        const SizedBox(height: 8),
        Text(label.toUpperCase(),
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ),
          ),
        ),
        if (subtitle != null)
          Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10)),
      ]),
    );
  }
}

// ─── App Button ───────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? bg;
  final Color? fg;
  final bool outline;

  const AppButton({
    super.key, required this.label, this.onTap,
    this.icon, this.bg, this.fg, this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = bg ?? AppColors.primary;
    return Material(
      color: outline ? Colors.transparent : bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8), onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: outline
              ? BoxDecoration(border: Border.all(color: bgColor, width: 2), borderRadius: BorderRadius.circular(8))
              : null,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, color: outline ? bgColor : (fg ?? Colors.white), size: 16),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: GoogleFonts.outfit(
                    color: outline ? bgColor : (fg ?? Colors.white),
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}

// ─── Labeled Input ────────────────────────────────────────────────────────────

class LabeledInput extends StatelessWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final bool readOnly;
  final TextInputType? keyboardType;

  const LabeledInput({
    super.key, required this.label, this.hint, this.initialValue,
    this.controller, this.readOnly = false, this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
            color: readOnly ? AppColors.textMuted : AppColors.foreground),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
          filled: true, fillColor: AppColors.muted,
        ),
      ),
    ]);
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (actionLabel != null)
        GestureDetector(
          onTap: onAction,
          child: Row(children: [
            Text(actionLabel!, style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
          ]),
        ),
    ]);
  }
}

// ─── Tag Label ────────────────────────────────────────────────────────────────

class TagLabel extends StatelessWidget {
  final String title;
  const TagLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 18,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: 0.2)),
    ]);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key, required this.icon, required this.title, required this.subtitle,
    this.actionLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(36)),
            child: Icon(icon, color: AppColors.textMuted, size: 30)),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          AppButton(label: actionLabel!, onTap: onAction),
        ],
      ]),
    );
  }
}

// ─── Error State — dùng bởi dashboard_screen ──────────────────────────────────

class ErrorState extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.detail, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 32),
          ),
          const SizedBox(height: 16),
          Text(message,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground),
              textAlign: TextAlign.center),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(detail!, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            AppButton(label: 'Thử lại', icon: Icons.refresh_rounded, onTap: onRetry),
          ],
        ]),
      ),
    );
  }
}

// ─── Skeleton Box — dùng bởi dashboard_screen._DashboardSkeleton ─────────────

class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, this.width, required this.height, this.radius = 8});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

// ─── Add Room Sheet — dùng bởi dashboard_screen._QuickActionsCard ─────────────

class AddRoomSheet extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AddRoomSheet({super.key, this.onSuccess});

  @override
  State<AddRoomSheet> createState() => _AddRoomSheetState();
}

class _AddRoomSheetState extends State<AddRoomSheet> {
  final _roomCodeCtl   = TextEditingController();
  final _areaIdCtl     = TextEditingController();
  final _basePriceCtl  = TextEditingController();
  final _elecPriceCtl  = TextEditingController(text: '3500');
  final _waterPriceCtl = TextEditingController(text: '15000');
  final _areaSizeCtl   = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_roomCodeCtl, _areaIdCtl, _basePriceCtl, _elecPriceCtl, _waterPriceCtl, _areaSizeCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  int _parseInt(String s, int fb) => int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? fb;

  Future<void> _submit() async {
    if (_roomCodeCtl.text.trim().isEmpty || _areaIdCtl.text.trim().isEmpty || _basePriceCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ: Mã phòng, ID khu, Giá thuê'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiClient.createRoom({
        'areaId':     _parseInt(_areaIdCtl.text, 0),
        'roomCode':   _roomCodeCtl.text.trim().toUpperCase(),
        'basePrice':  _parseInt(_basePriceCtl.text, 0),
        'elecPrice':  _parseInt(_elecPriceCtl.text, 3500),
        'waterPrice': _parseInt(_waterPriceCtl.text, 15000),
        'areaSize':   _parseInt(_areaSizeCtl.text, 0),
        'status':     'AVAILABLE',
        'images': <String>[], 'amenities': <String>[],
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm phòng ${_roomCodeCtl.text.trim().toUpperCase()}!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Thêm phòng mới', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground)),
        const SizedBox(height: 16),
        // Row: Mã phòng + ID khu
        Row(children: [
          Expanded(child: LabeledInput(label: 'Mã phòng *', controller: _roomCodeCtl, hint: 'VD: P101')),
          const SizedBox(width: 12),
          Expanded(child: LabeledInput(label: 'ID khu trọ *', controller: _areaIdCtl, keyboardType: TextInputType.number, hint: 'VD: 1')),
        ]),
        const SizedBox(height: 12),
        // Row: Giá thuê + Diện tích
        Row(children: [
          Expanded(child: LabeledInput(label: 'Giá thuê (VNĐ) *', controller: _basePriceCtl, keyboardType: TextInputType.number, hint: '2000000')),
          const SizedBox(width: 12),
          Expanded(child: LabeledInput(label: 'Diện tích (m²)', controller: _areaSizeCtl, keyboardType: TextInputType.number, hint: '25')),
        ]),
        const SizedBox(height: 12),
        // Row: Giá điện + Giá nước
        Row(children: [
          Expanded(child: LabeledInput(label: 'Giá điện /kWh', controller: _elecPriceCtl, keyboardType: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: LabeledInput(label: 'Giá nước /m³', controller: _waterPriceCtl, keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_home_rounded, size: 16),
            label: Text(_loading ? 'Đang lưu...' : 'Thêm phòng',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// ─── Currency Formatter ───────────────────────────────────────────────────────

String formatVnd(int amount) => NumberFormat('#,###', 'vi_VN').format(amount) + 'đ';

String formatMillions(int amount) => '${(amount / 1000000).toStringAsFixed(1)}tr';