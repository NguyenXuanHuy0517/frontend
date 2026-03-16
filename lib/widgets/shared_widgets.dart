// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: cfg.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            cfg.label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: cfg.text, letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeCfg _roomConfig(RoomStatus s) => switch (s) {
    RoomStatus.available    => _BadgeCfg('Trống',       AppColors.successLight, AppColors.successDark, AppColors.success),
    RoomStatus.occupied     => _BadgeCfg('Đang thuê',   AppColors.dangerLight,  AppColors.dangerDark,  AppColors.danger),
    RoomStatus.maintenance  => _BadgeCfg('Sửa chữa',   AppColors.warningLight, AppColors.warningDark, AppColors.warning),
  };

  _BadgeCfg _invoiceConfig(InvoiceStatus s) => switch (s) {
    InvoiceStatus.paid      => _BadgeCfg('Đã thanh toán', AppColors.success, Colors.white,           AppColors.successLight),
    InvoiceStatus.pending   => _BadgeCfg('Chờ thanh toán',AppColors.warning, Colors.white,           AppColors.warningLight),
    InvoiceStatus.overdue   => _BadgeCfg('Quá hạn',       AppColors.danger,  Colors.white,           AppColors.dangerLight),
  };
}

class _BadgeCfg {
  final String label;
  final Color bg, text, dot;
  const _BadgeCfg(this.label, this.bg, this.text, this.dot);
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final double? trend;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Giảm bớt padding một chút
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row chứa Icon và Trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Giảm nhẹ padding icon
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              if (trend != null)
                Row(
                  children: [
                    Icon(
                      trend! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white70, size: 12,
                    ),
                    Text(
                      '${trend!.abs().toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8), // Giảm khoảng cách
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              color: Colors.white70, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 0.8,
            ),
          ),

          // --- SỬA ĐỔI CHÍNH Ở ĐÂY ---
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown, // Tự động thu nhỏ font chữ nếu bị tràn ngang
                child: Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 26, // Giảm nhẹ size gốc xuống 26
                    fontWeight: FontWeight.w800, letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          // ---------------------------

          if (subtitle != null) ...[
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Tránh tràn dòng ở subtitle
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10),
            ),
          ],
        ],
      ),
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
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.bg,
    this.fg,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = bg ?? AppColors.primary;
    return Material(
      color: outline ? Colors.transparent : bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: outline
              ? BoxDecoration(
                  border: Border.all(color: bgColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: outline ? bgColor : (fg ?? Colors.white), size: 16),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: outline ? bgColor : (fg ?? Colors.white),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
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
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.readOnly = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary, letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: readOnly ? AppColors.textMuted : AppColors.foreground,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.muted,
          ),
        ),
      ],
    );
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: GoogleFonts.outfit(
                    color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Currency Formatter ───────────────────────────────────────────────────────

String formatVnd(int amount) {
  return NumberFormat('#,###', 'vi_VN').format(amount) + 'đ';
}

String formatMillions(int amount) {
  return '${(amount / 1000000).toStringAsFixed(1)}tr';
}
