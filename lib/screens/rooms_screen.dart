// lib/screens/rooms_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/api.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  RoomStatus? _filter;
  late Future<List<RoomModel>> _futureRooms;

  @override
  void initState() {
    super.initState();
    _futureRooms = ApiClient.fetchRoomsOverview();
  }

  List<RoomModel> _applyFilter(List<RoomModel> rooms) =>
      _filter == null ? rooms : rooms.where((r) => r.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filter Bar ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // We'll show placeholders until data loads
                      _FilterChip(label: 'Tất cả', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Trống', selected: _filter == RoomStatus.available, onTap: () => setState(() => _filter = RoomStatus.available)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Đang thuê', selected: _filter == RoomStatus.occupied, onTap: () => setState(() => _filter = RoomStatus.occupied)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Sửa chữa', selected: _filter == RoomStatus.maintenance, onTap: () => setState(() => _filter = RoomStatus.maintenance)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AppButton(label: 'Thêm phòng', icon: Icons.add, onTap: () {}),
            ],
          ),
        ),

        // ── Room Grid ────────────────────────────────────────────────────────
        Expanded(
          child: FutureBuilder<List<RoomModel>>(
            future: _futureRooms,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi khi tải phòng: ${snapshot.error}'));
              }
              final rooms = _applyFilter(snapshot.data ?? []);

              return LayoutBuilder(builder: (context, constraints) {
                final cols = constraints.maxWidth > 900 ? 4
                           : constraints.maxWidth > 600 ? 3
                           : constraints.maxWidth > 400 ? 2
                           : 1;
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => RoomDetailScreen(roomId: rooms[i].roomId),
                      ));
                      // Refresh rooms when returning from detail (in case status changed)
                      setState(() {
                        _futureRooms = ApiClient.fetchRoomsOverview();
                      });
                    },
                    child: _RoomCard(rooms[i]),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatefulWidget {
  final RoomModel room;
  const _RoomCard(this.room);
  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  bool _hovered = false;

  Color get _bgColor => switch (widget.room.status) {
    RoomStatus.available    => _hovered ? const Color(0xFFD1FAE5) : const Color(0xFFF0FDF4),
    RoomStatus.occupied     => _hovered ? AppColors.muted         : AppColors.surface,
    RoomStatus.maintenance  => _hovered ? const Color(0xFFFEF3C7) : const Color(0xFFFFFBEB),
  };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: _hovered
            ? (Matrix4.identity()..scale(1.02, 1.02, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? AppColors.border : Colors.transparent, width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.room.id,
                  style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.foreground, letterSpacing: -0.5,
                  ),
                ),
                StatusBadge.room(widget.room.status),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Text(
                  '${widget.room.area} · Tầng ${widget.room.floor}',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const Spacer(),
            if (widget.room.tenant != null)
              Text(
                widget.room.tenant!,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground),
                overflow: TextOverflow.ellipsis,
              ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatVnd(widget.room.rent),
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  TextSpan(
                    text: '/tháng',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
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
