// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/api.dart';
import 'rooms_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<RoomModel>> _futureRooms;

  @override
  void initState() {
    super.initState();
    _futureRooms = ApiClient.fetchRoomsOverview();
  }

  Future<void> _refresh() {
    // Create the future first, then set it into state synchronously
    final f = ApiClient.fetchRoomsOverview();
    setState(() {
      _futureRooms = f;
    });
    // Return a Future<void> that completes when the fetch completes
    return f.then((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: FutureBuilder<List<RoomModel>>(
        future: _futureRooms,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DashboardSkeleton();
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: 'Không thể tải dữ liệu dashboard',
              detail: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final rooms = snapshot.data ?? const [];
          return RepaintBoundary(
            child: _DashboardContent(rooms: rooms, onRefresh: _refresh),
          );
        },
      ),
    );
  }
}

// ─── Content tách riêng để RepaintBoundary + không rebuild khi future reload ──

class _DashboardContent extends StatelessWidget {
  final List<RoomModel> rooms;
  final VoidCallback onRefresh;

  const _DashboardContent({required this.rooms, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // Tính toán 1 lần — không tính lại khi child rebuild
    final rented      = rooms.where((r) => r.status == RoomStatus.rented).length;
    final deposited   = rooms.where((r) => r.status == RoomStatus.deposited).length;
    final available   = rooms.where((r) => r.status == RoomStatus.available).length;
    final maintenance = rooms.where((r) => r.status == RoomStatus.maintenance).length;
    final total       = rooms.length;
    final occupied    = rented + deposited;
    final revenue     = rooms
        .where((r) => r.status == RoomStatus.rented || r.status == RoomStatus.deposited)
        .fold(0, (s, r) => s + r.rent);
    final overdue  = kInvoices.where((i) => i.status == InvoiceStatus.overdue).toList();
    final occRate  = total == 0 ? 0.0 : occupied / total;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            // SliverList thay ListView — cho phép lazy render trong scroll
            delegate: SliverChildListDelegate.fixed([
              RepaintBoundary(child: _StatGrid(revenue: revenue, occupied: occupied, total: total, available: available, overdueCount: overdue.length)),
              const SizedBox(height: 24),
              RepaintBoundary(child: _OccupancyAndActions(
                rented: rented, deposited: deposited, available: available,
                maintenance: maintenance, total: total, occRate: occRate,
                onRoomAdded: onRefresh,
              )),
              const SizedBox(height: 24),
              RepaintBoundary(child: _RecentInvoicesCard(invoices: kInvoices.take(5).toList())),
              if (overdue.isNotEmpty) ...[
                const SizedBox(height: 16),
                RepaintBoundary(child: _OverdueAlert(overdue: overdue)),
              ],
              if (rooms.isNotEmpty) ...[
                const SizedBox(height: 16),
                RepaintBoundary(child: _RoomsStatusSummary(rooms: rooms.take(6).toList())),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Stat Grid ────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  final int revenue, occupied, total, available, overdueCount;

  const _StatGrid({
    required this.revenue, required this.occupied, required this.total,
    required this.available, required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    // Tính toán label ngoài build để tránh string interpolation mỗi frame
    final fillPct = total == 0 ? 0 : (occupied / total * 100).round();

    return LayoutBuilder(builder: (_, c) {
      final isWide = c.maxWidth > 600;
      final cards = <Widget>[
        _StatCard(icon: Icons.account_balance_wallet_rounded, label: 'Doanh thu tháng', value: formatMillions(revenue), subtitle: '+8.2% so T6', color: AppColors.primary, trend: 8.2),
        _StatCard(icon: Icons.meeting_room_rounded, label: 'Đang sử dụng', value: '$occupied/$total', subtitle: '$fillPct% lấp đầy', color: const Color(0xFF8B5CF6), trend: 2.1),
        _StatCard(icon: Icons.door_front_door_outlined, label: 'Phòng trống', value: '$available', subtitle: 'Sẵn sàng cho thuê', color: AppColors.success),
        _StatCard(icon: Icons.receipt_long_rounded, label: 'Hóa đơn quá hạn', value: '$overdueCount', subtitle: overdueCount > 0 ? 'Cần xử lý ngay' : 'Không có', color: overdueCount > 0 ? AppColors.danger : AppColors.textSecondary),
      ];

      if (isWide) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(cards.length, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
                child: cards[i],
              ),
            )),
          ),
        );
      }
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
        children: cards,
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, subtitle;
  final Color color;
  final double? trend;

  const _StatCard({
    required this.icon, required this.label, required this.value,
    required this.subtitle, required this.color, this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          if (trend != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(trend! >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 10),
                const SizedBox(width: 2),
                Text('${trend!.abs().toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        ),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 1),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ]),
    );
  }
}

// ─── Occupancy + Quick Actions row ───────────────────────────────────────────

class _OccupancyAndActions extends StatelessWidget {
  final int rented, deposited, available, maintenance, total;
  final double occRate;
  final VoidCallback onRoomAdded;

  const _OccupancyAndActions({
    required this.rented, required this.deposited, required this.available,
    required this.maintenance, required this.total, required this.occRate,
    required this.onRoomAdded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      if (c.maxWidth > 800) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: _OccupancyCard(rented: rented, deposited: deposited, available: available, maintenance: maintenance, total: total, occRate: occRate)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _QuickActionsCard(onRoomAdded: onRoomAdded)),
        ]);
      }
      return Column(children: [
        _OccupancyCard(rented: rented, deposited: deposited, available: available, maintenance: maintenance, total: total, occRate: occRate),
        const SizedBox(height: 16),
        _QuickActionsCard(onRoomAdded: onRoomAdded),
      ]);
    });
  }
}

// ─── Occupancy Card ───────────────────────────────────────────────────────────

class _OccupancyCard extends StatelessWidget {
  final int rented, deposited, available, maintenance, total;
  final double occRate;

  const _OccupancyCard({
    required this.rented, required this.deposited, required this.available,
    required this.maintenance, required this.total, required this.occRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Tình trạng phòng', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.foreground)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('$total phòng', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Circular progress — RepaintBoundary vì nó animate
          RepaintBoundary(
            child: SizedBox(width: 80, height: 80, child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: occRate, strokeWidth: 10,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.danger),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${(occRate * 100).round()}%',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.foreground)),
                  const Text('Lấp đầy', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ]),
              ],
            )),
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
            _OccupancyRow(label: 'Đang thuê',   count: rented,      total: total, color: AppColors.danger),
            const SizedBox(height: 8),
            _OccupancyRow(label: 'Đặt cọc',     count: deposited,   total: total, color: const Color(0xFF8B5CF6)),
            const SizedBox(height: 8),
            _OccupancyRow(label: 'Phòng trống', count: available,   total: total, color: AppColors.success),
            const SizedBox(height: 8),
            _OccupancyRow(label: 'Sửa chữa',   count: maintenance, total: total, color: AppColors.warning),
          ])),
        ]),
      ]),
    );
  }
}

class _OccupancyRow extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;

  const _OccupancyRow({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground)),
        ]),
        Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.foreground)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: pct, minHeight: 5,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onRoomAdded;

  const _QuickActionsCard({required this.onRoomAdded});

  // Static list — khởi tạo 1 lần
  static const _actionDefs = <(IconData, String, Color)>[
    (Icons.add_home_rounded,       'Thêm phòng',     AppColors.primary),
    (Icons.receipt_long_rounded,   'Tạo hóa đơn',   Color(0xFF8B5CF6)),
    (Icons.bolt_rounded,           'Nhập điện nước', AppColors.warning),
    (Icons.person_add_alt_rounded, 'Thêm khách',    AppColors.success),
    (Icons.build_rounded,          'Báo bảo trì',   AppColors.danger),
    (Icons.description_rounded,   'Tạo hợp đồng',  Color(0xFF06B6D4)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Thao tác nhanh', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.foreground)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.0),
          itemCount: _actionDefs.length,
          itemBuilder: (ctx, i) {
            final (icon, label, color) = _actionDefs[i];
            return _QuickBtn(
              icon: icon, label: label, color: color,
              onTap: i == 0 ? () => _showAddRoom(ctx) : () {},
            );
          },
        ),
      ]),
    );
  }

  void _showAddRoom(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => AddRoomSheet(onSuccess: onRoomAdded),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10), onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, maxLines: 2,
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color, height: 1.2)),
          ]),
        ),
      ),
    );
  }
}

// ─── Recent Invoices ──────────────────────────────────────────────────────────

class _RecentInvoicesCard extends StatelessWidget {
  final List<InvoiceModel> invoices;

  const _RecentInvoicesCard({required this.invoices});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(14)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Hóa đơn gần đây', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.foreground)),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              label: const Text('Xem tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        if (invoices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: EmptyState(icon: Icons.receipt_long_outlined, title: 'Chưa có hóa đơn', subtitle: ''),
          )
        else
        // ListView.builder: lazy render — không build tất cả rows cùng lúc
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invoices.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (_, i) => RepaintBoundary(child: _InvoiceRow(invoices[i])),
          ),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final InvoiceModel inv;

  const _InvoiceRow(this.inv);

  static Color _statusColor(InvoiceStatus s) => switch (s) {
    InvoiceStatus.paid    => AppColors.success,
    InvoiceStatus.pending => AppColors.warning,
    InvoiceStatus.overdue => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(inv.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(inv.room,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(inv.tenant, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
          Text('Hạn: ${inv.due}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Text(formatVnd(inv.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.foreground)),
          const SizedBox(height: 3),
          StatusBadge.invoice(inv.status),
        ]),
      ]),
    );
  }
}

// ─── Overdue Alert ────────────────────────────────────────────────────────────

class _OverdueAlert extends StatelessWidget {
  final List<InvoiceModel> overdue;

  const _OverdueAlert({required this.overdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.3), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Hóa đơn quá hạn', style: TextStyle(color: AppColors.dangerDark, fontWeight: FontWeight.w800, fontSize: 14)),
            Text('${overdue.length} hóa đơn cần thu ngay',
                style: const TextStyle(color: AppColors.danger, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 12),
        // ListView.builder thay map
        ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: overdue.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text('Phòng ${overdue[i].room} · ${overdue[i].tenant} · Hạn ${overdue[i].due}',
                  style: const TextStyle(color: AppColors.dangerDark, fontSize: 12, fontWeight: FontWeight.w500))),
              const SizedBox(width: 8),
              _RemindButton(inv: overdue[i]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _RemindButton extends StatelessWidget {
  final InvoiceModel inv;
  const _RemindButton({required this.inv});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
        child: const Text('Nhắc nhở', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Rooms Status Summary ─────────────────────────────────────────────────────

class _RoomsStatusSummary extends StatelessWidget {
  final List<RoomModel> rooms;

  const _RoomsStatusSummary({required this.rooms});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Phòng mới cập nhật', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.foreground)),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
            label: const Text('Tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: List.generate(rooms.length, (i) => _RoomChip(rooms[i])),
        ),
      ]),
    );
  }
}

class _RoomChip extends StatelessWidget {
  final RoomModel room;

  const _RoomChip(this.room);

  @override
  Widget build(BuildContext context) {
    final color = statusAccentColor(room.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(room.roomCode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: List.generate(4, (i) =>
              Expanded(child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                child: const SkeletonBox(height: 110, radius: 14),
              )),
          )),
        ),
        const SizedBox(height: 24),
        const SkeletonBox(height: 180, radius: 14),
        const SizedBox(height: 16),
        const SkeletonBox(height: 200, radius: 14),
        const SizedBox(height: 16),
        const SkeletonBox(height: 160, radius: 14),
      ]),
    );
  }
}