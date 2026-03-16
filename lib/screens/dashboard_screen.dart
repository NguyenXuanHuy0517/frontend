// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/api.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RoomModel>>(
      future: ApiClient.fetchRoomsOverview(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi khi tải dữ liệu dashboard: ${snapshot.error}'));
        }
        final rooms = snapshot.data ?? [];
        final occupied    = rooms.where((r) => r.status == RoomStatus.occupied).length;
        final available   = rooms.where((r) => r.status == RoomStatus.available).length;
        final maintenance = rooms.where((r) => r.status == RoomStatus.maintenance).length;
        final totalRooms  = rooms.length;
        final overdue     = kInvoices.where((i) => i.status == InvoiceStatus.overdue).toList();
        final revenue     = rooms
            .where((r) => r.status == RoomStatus.occupied)
            .fold(0, (s, r) => s + r.rent);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stat Grid ───────────────────────────────────────────────────────
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final cards = [
                  StatCard(
                    icon: Icons.receipt_long,
                    label: 'Doanh thu tháng',
                    value: formatMillions(revenue),
                     subtitle: 'So với T6: +8.2%',
                    color: AppColors.primary,
                    trend: 8.2,
                  ),
                  StatCard(
                    icon: Icons.home,
                    label: 'Phòng đang thuê',
                    value: '$occupied/$totalRooms',
                    subtitle: '${(occupied / (totalRooms == 0 ? 1 : totalRooms) * 100).round()}% lấp đầy',
                    color: AppColors.danger,
                    trend: 2.1,
                  ),
                  StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Phòng trống',
                    value: '$available',
                    subtitle: 'Sẵn sàng cho thuê',
                    color: AppColors.success,
                  ),
                  StatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Hóa đơn quá hạn',
                    value: '${overdue.length}',
                    subtitle: 'Cần thu ngay',
                    color: AppColors.warning,
                  ),
                ];
                if (isWide) {
                  // Provide a bounded height for the row so children with Expanded
                  // inside (StatCard contains an Expanded) can be laid out.
                  return SizedBox(
                    height: 120, // fixed height to contain stat cards comfortably
                    child: Row(
                      children: cards
                          .map((c) => Expanded(child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: c,
                              )))
                          .toList(),
                    ),
                  );
                }
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1, // Adjusted to prevent overflow
                  children: cards,
                );
              }),

              const SizedBox(height: 28),

              // ── Occupancy Bar ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: 'Tình trạng phòng'),
                    const SizedBox(height: 16),
                    _OccupancyBar('Đang thuê',  occupied,    totalRooms, AppColors.danger),
                    const SizedBox(height: 10),
                    _OccupancyBar('Phòng trống', available,   totalRooms, AppColors.success),
                    const SizedBox(height: 10),
                    _OccupancyBar('Sửa chữa',   maintenance, totalRooms, AppColors.warning),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Recent Invoices ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SectionHeader(title: 'Hóa đơn gần đây', actionLabel: 'Xem tất cả'),
                    const SizedBox(height: 12),
                    ...kInvoices.take(4).map((inv) => _InvoicePreviewRow(inv)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Overdue Alert ────────────────────────────────────────────────────
              if (overdue.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: AppColors.danger, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Cảnh báo quan trọng',
                            style: GoogleFonts.outfit(
                              color: AppColors.dangerDark,
                              fontWeight: FontWeight.w800, fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...overdue.map((inv) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Phòng ${inv.room} – ${inv.tenant} chưa thanh toán (hạn ${inv.due})',
                                style: GoogleFonts.outfit(
                                  color: AppColors.dangerDark, fontSize: 12, fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              label: 'Nhắc nhở',
                              bg: AppColors.danger,
                              onTap: () {},
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OccupancyBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _OccupancyBar(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.foreground)),
            Text('$count phòng', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.foreground)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _InvoicePreviewRow extends StatelessWidget {
  final InvoiceModel inv;
  const _InvoicePreviewRow(this.inv);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${inv.room} · ${inv.tenant.split(' ').last}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.foreground),
                ),
                Text(
                  'Hạn: ${inv.due}',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMillions(inv.amount),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.foreground),
              ),
              const SizedBox(height: 3),
              StatusBadge.invoice(inv.status),
            ],
          ),
        ],
      ),
    );
  }
}
