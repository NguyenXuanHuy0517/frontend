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

  Future<void> _refresh() async {
    setState(() => _futureRooms = ApiClient.fetchRoomsOverview());
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
            return _ErrorState(
              message: 'Không thể tải dữ liệu dashboard',
              detail: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final rooms = snapshot.data ?? [];
          final occupied = rooms.where((r) => r.status == RoomStatus.occupied).length;
          final available = rooms.where((r) => r.status == RoomStatus.available).length;
          final maintenance = rooms.where((r) => r.status == RoomStatus.maintenance).length;
          final totalRooms = rooms.length;
          final overdue = kInvoices.where((i) => i.status == InvoiceStatus.overdue).toList();
          final revenue = rooms.where((r) => r.status == RoomStatus.occupied).fold(0, (s, r) => s + r.rent);
          final occupancyRate = totalRooms == 0 ? 0.0 : occupied / totalRooms;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatGrid(revenue: revenue, occupied: occupied, totalRooms: totalRooms, available: available, overdueCount: overdue.length),
                const SizedBox(height: 24),
                LayoutBuilder(builder: (ctx, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _OccupancyCard(occupied: occupied, available: available, maintenance: maintenance, totalRooms: totalRooms, occupancyRate: occupancyRate)),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _QuickActionsCard(onRoomAdded: _refresh)),
                      ],
                    );
                  }
                  return Column(children: [
                    _OccupancyCard(occupied: occupied, available: available, maintenance: maintenance, totalRooms: totalRooms, occupancyRate: occupancyRate),
                    const SizedBox(height: 16),
                    _QuickActionsCard(onRoomAdded: _refresh),
                  ]);
                }),
                const SizedBox(height: 24),
                _RecentInvoicesCard(invoices: kInvoices.take(5).toList()),
                if (overdue.isNotEmpty) ...[const SizedBox(height: 16), _OverdueAlert(overdue: overdue)],
                if (rooms.isNotEmpty) ...[const SizedBox(height: 16), _RoomsStatusSummary(rooms: rooms)],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Stat Grid ─────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  final int revenue, occupied, totalRooms, available, overdueCount;
  const _StatGrid({required this.revenue, required this.occupied, required this.totalRooms, required this.available, required this.overdueCount});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData(icon: Icons.account_balance_wallet_rounded, label: 'Doanh thu tháng', value: formatMillions(revenue), subtitle: '+8.2% so T6', color: AppColors.primary, trend: 8.2),
      _StatData(icon: Icons.meeting_room_rounded, label: 'Đang cho thuê', value: '$occupied/$totalRooms', subtitle: '${totalRooms == 0 ? 0 : (occupied / totalRooms * 100).round()}% lấp đầy', color: const Color(0xFF8B5CF6), trend: 2.1),
      _StatData(icon: Icons.door_front_door_outlined, label: 'Phòng trống', value: '$available', subtitle: 'Sẵn sàng cho thuê', color: AppColors.success),
      _StatData(icon: Icons.receipt_long_rounded, label: 'Hóa đơn quá hạn', value: '$overdueCount', subtitle: overdueCount > 0 ? 'Cần xử lý ngay' : 'Không có', color: overdueCount > 0 ? AppColors.danger : AppColors.textSecondary),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      if (isWide) {
        // IntrinsicHeight để các card tự co theo nội dung, không dùng fixed height tránh overflow
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards.asMap().entries.map((e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: e.key < cards.length - 1 ? 12 : 0),
                child: _StatCard(data: e.value),
              ),
            )).toList(),
          ),
        );
      }
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
        children: cards.map((d) => _StatCard(data: d)).toList(),
      );
    });
  }
}

class _StatData {
  final IconData icon;
  final String label, value, subtitle;
  final Color color;
  final double? trend;
  const _StatData({required this.icon, required this.label, required this.value, required this.subtitle, required this.color, this.trend});
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,   // ← key fix: không dùng Expanded bên trong
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withAlpha((0.2 * 255).round()), borderRadius: BorderRadius.circular(8)),
                child: Icon(data.icon, color: Colors.white, size: 14),
              ),
              if (data.trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withAlpha((0.2 * 255).round()), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(data.trend! >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text('${data.trend!.abs().toStringAsFixed(1)}%', style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(data.value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 2),
          Text(data.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 1),
          Text(data.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Occupancy Card ───────────────────────────────────────────────────────────

class _OccupancyCard extends StatelessWidget {
  final int occupied, available, maintenance, totalRooms;
  final double occupancyRate;
  const _OccupancyCard({required this.occupied, required this.available, required this.maintenance, required this.totalRooms, required this.occupancyRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tình trạng phòng', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.foreground)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withAlpha((0.1 * 255).round()), borderRadius: BorderRadius.circular(20)),
                child: Text('$totalRooms phòng', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 80, height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(value: 1.0, strokeWidth: 10, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(Colors.transparent)),
                    CircularProgressIndicator(value: occupancyRate, strokeWidth: 10, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.danger)),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${(occupancyRate * 100).round()}%', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.foreground)),
                      Text('Lấp đầy', style: GoogleFonts.outfit(fontSize: 9, color: AppColors.textMuted)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                _OccupancyRow(label: 'Đang thuê', count: occupied, total: totalRooms, color: AppColors.danger),
                const SizedBox(height: 10),
                _OccupancyRow(label: 'Phòng trống', count: available, total: totalRooms, color: AppColors.success),
                const SizedBox(height: 10),
                _OccupancyRow(label: 'Sửa chữa', count: maintenance, total: totalRooms, color: AppColors.warning),
              ])),
            ],
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            ]),
            Text('$count', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.foreground)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: pct, minHeight: 5, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(color)),
        ),
      ],
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onRoomAdded;
  const _QuickActionsCard({required this.onRoomAdded});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(icon: Icons.add_home_rounded,       label: 'Thêm phòng',    color: AppColors.primary,          onTap: () => _showAddRoom(context)),
      _ActionData(icon: Icons.receipt_long_rounded,   label: 'Tạo hóa đơn',  color: const Color(0xFF8B5CF6),    onTap: () {}),
      _ActionData(icon: Icons.bolt_rounded,           label: 'Nhập điện nước',color: AppColors.warning,          onTap: () {}),
      _ActionData(icon: Icons.person_add_alt_rounded, label: 'Thêm khách',   color: AppColors.success,          onTap: () {}),
      _ActionData(icon: Icons.build_rounded,          label: 'Báo bảo trì',  color: AppColors.danger,           onTap: () {}),
      _ActionData(icon: Icons.description_rounded,   label: 'Tạo hợp đồng', color: const Color(0xFF06B6D4),    onTap: () {}),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Thao tác nhanh', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.foreground)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.0,
            children: actions.map((a) => _QuickBtn(data: a)).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddRoom(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRoomSheet(onSuccess: onRoomAdded),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionData({required this.icon, required this.label, required this.color, required this.onTap});
}

class _QuickBtn extends StatelessWidget {
  final _ActionData data;
  const _QuickBtn({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: data.color.withAlpha((0.1 * 255).round()),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, color: data.color, size: 22),
              const SizedBox(height: 5),
              Text(data.label, textAlign: TextAlign.center, maxLines: 2,
                  style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w700, color: data.color, height: 1.2)),
            ],
          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hóa đơn gần đây', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.foreground)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  label: Text('Xem tất cả', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (invoices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 36),
                const SizedBox(height: 8),
                Text('Chưa có hóa đơn nào', style: GoogleFonts.outfit(color: AppColors.textMuted)),
              ]),
            )
          else
            ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (_, i) => _InvoiceRow(invoices[i]),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final InvoiceModel inv;
  const _InvoiceRow(this.inv);

  Color _statusColor(InvoiceStatus s) => switch (s) {
    InvoiceStatus.paid => AppColors.success,
    InvoiceStatus.pending => AppColors.warning,
    InvoiceStatus.overdue => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: _statusColor(inv.status).withAlpha((0.12 * 255).round()), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(inv.room, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: _statusColor(inv.status)))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
            children: [
              Text(inv.tenant, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
              Text('Hạn: ${inv.due}', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            Text(formatVnd(inv.amount), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.foreground)),
            const SizedBox(height: 3),
            StatusBadge.invoice(inv.status),
          ]),
        ],
      ),
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
        color: AppColors.dangerLight, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withAlpha((0.3 * 255).round()), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Hóa đơn quá hạn', style: GoogleFonts.outfit(color: AppColors.dangerDark, fontWeight: FontWeight.w800, fontSize: 14)),
              Text('${overdue.length} hóa đơn cần thu ngay', style: GoogleFonts.outfit(color: AppColors.danger, fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 12),
          ...overdue.map((inv) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text('Phòng ${inv.room} · ${inv.tenant} · Hạn ${inv.due}',
                  style: GoogleFonts.outfit(color: AppColors.dangerDark, fontSize: 12, fontWeight: FontWeight.w500))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                  child: Text('Nhắc nhở', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          )),
        ],
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
    final recent = rooms.take(6).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phòng mới cập nhật', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.foreground)),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                label: Text('Tất cả', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: recent.map((r) => _RoomChip(r)).toList()),
        ],
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  final RoomModel room;
  const _RoomChip(this.room);
  Color get _color => switch (room.status) {
    RoomStatus.available => AppColors.success,
    RoomStatus.occupied => AppColors.danger,
    RoomStatus.maintenance => AppColors.warning,
  };
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: _color.withAlpha((0.1 * 255).round()), borderRadius: BorderRadius.circular(8), border: Border.all(color: _color.withAlpha((0.3 * 255).round()), width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(room.roomCode, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: _color)),
      ]),
    );
  }
}

// ─── Skeletons & Error ────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: List.generate(4, (i) => Expanded(child: Padding(padding: EdgeInsets.only(right: i < 3 ? 12 : 0), child: const _SkeletonBox(height: 110, borderRadius: 14)))))),
        const SizedBox(height: 24),
        const _SkeletonBox(height: 180, borderRadius: 14),
        const SizedBox(height: 16),
        const _SkeletonBox(height: 200, borderRadius: 14),
        const SizedBox(height: 16),
        const _SkeletonBox(height: 160, borderRadius: 14),
      ]),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double? height;
  final double borderRadius;
  const _SkeletonBox({this.height, this.borderRadius = 8});
  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}
class _SkeletonBoxState extends State<_SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(color: Color.lerp(AppColors.muted, AppColors.border, _anim.value), borderRadius: BorderRadius.circular(widget.borderRadius)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message, detail;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.detail, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(32)), child: const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 28)),
        const SizedBox(height: 16),
        Text(message, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground)),
        const SizedBox(height: 8),
        Text(detail, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Thử lại')),
      ]),
    ));
  }
}