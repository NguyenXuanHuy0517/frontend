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
  bool _isGridView = true;
  late Future<List<RoomModel>> _futureRooms;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureRooms = ApiClient.fetchRoomsOverview();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _futureRooms = ApiClient.fetchRoomsOverview());
  }

  List<RoomModel> _applyFilter(List<RoomModel> rooms) {
    var result = _filter == null ? rooms : rooms.where((r) => r.status == _filter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((r) =>
      r.roomCode.toLowerCase().contains(q) ||
          r.areaName.toLowerCase().contains(q) ||
          (r.tenant?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return result;
  }

  void _showAddRoomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRoomSheet(onSuccess: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search + Actions bar ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
          ),
          child: Row(
            children: [
              // Search field — một icon duy nhất bên trái
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.foreground),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo mã phòng, khu vực...',
                            hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            // Không dùng suffixIcon trong InputDecoration để tránh dư icon
                          ),
                        ),
                      ),
                      // Nút X chỉ hiện khi đang tìm kiếm
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                          ),
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Toggle Grid/List
              _IconToggle(
                icon: _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                tooltip: _isGridView ? 'Dạng danh sách' : 'Dạng lưới',
                onTap: () => setState(() => _isGridView = !_isGridView),
              ),
              const SizedBox(width: 8),

              // Add Room button
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _showAddRoomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text('Thêm phòng', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Filter Chips ─────────────────────────────────────────────────────
        FutureBuilder<List<RoomModel>>(
          future: _futureRooms,
          builder: (context, snapshot) {
            final rooms = snapshot.data ?? [];
            return _FilterBar(
              filter: _filter,
              onFilterChanged: (f) => setState(() => _filter = f),
              allCount: rooms.length,
              availCount: rooms.where((r) => r.status == RoomStatus.available).length,
              occupCount: rooms.where((r) => r.status == RoomStatus.occupied).length,
              maintCount: rooms.where((r) => r.status == RoomStatus.maintenance).length,
            );
          },
        ),

        // ── Room Grid / List ─────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: FutureBuilder<List<RoomModel>>(
              future: _futureRooms,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _isGridView ? const _GridSkeleton() : const _ListSkeleton();
                }
                if (snapshot.hasError) {
                  return _RoomsError(detail: snapshot.error.toString(), onRetry: _refresh);
                }
                final rooms = _applyFilter(snapshot.data ?? []);
                if (rooms.isEmpty) {
                  return _EmptyState(
                    hasFilter: _filter != null || _searchQuery.isNotEmpty,
                    onClear: () => setState(() { _filter = null; _searchQuery = ''; _searchCtrl.clear(); }),
                  );
                }
                return _isGridView
                    ? _RoomGrid(rooms: rooms, onTap: _navigateToDetail)
                    : _RoomList(rooms: rooms, onTap: _navigateToDetail);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToDetail(RoomModel room) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomDetailScreen(roomId: room.roomId)));
    _refresh();
  }
}

// ─── Icon Toggle Button ───────────────────────────────────────────────────────

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconToggle({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(width: 42, height: 42, child: Icon(icon, color: AppColors.textSecondary, size: 18)),
        ),
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final RoomStatus? filter;
  final ValueChanged<RoomStatus?> onFilterChanged;
  final int allCount, availCount, occupCount, maintCount;
  const _FilterBar({required this.filter, required this.onFilterChanged, required this.allCount, required this.availCount, required this.occupCount, required this.maintCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(color: AppColors.background, border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _Chip(label: 'Tất cả',     count: allCount,   selected: filter == null,                      color: AppColors.foreground, onTap: () => onFilterChanged(null)),
            const SizedBox(width: 8),
            _Chip(label: 'Phòng trống', count: availCount, selected: filter == RoomStatus.available,       color: AppColors.success,    onTap: () => onFilterChanged(RoomStatus.available)),
            const SizedBox(width: 8),
            _Chip(label: 'Đang thuê',  count: occupCount, selected: filter == RoomStatus.occupied,        color: AppColors.danger,     onTap: () => onFilterChanged(RoomStatus.occupied)),
            const SizedBox(width: 8),
            _Chip(label: 'Sửa chữa',  count: maintCount, selected: filter == RoomStatus.maintenance,     color: AppColors.warning,    onTap: () => onFilterChanged(RoomStatus.maintenance)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.count, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: selected ? color : AppColors.muted, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: selected ? Colors.white.withOpacity(0.25) : AppColors.border, borderRadius: BorderRadius.circular(99)),
              child: Text('$count', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Room Grid ────────────────────────────────────────────────────────────────

class _RoomGrid extends StatelessWidget {
  final List<RoomModel> rooms;
  final ValueChanged<RoomModel> onTap;
  const _RoomGrid({required this.rooms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 650 ? 3 : constraints.maxWidth > 420 ? 2 : 1;
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35),
        itemCount: rooms.length,
        itemBuilder: (_, i) => _RoomCard(room: rooms[i], onTap: () => onTap(rooms[i])),
      );
    });
  }
}

class _RoomCard extends StatefulWidget {
  final RoomModel room;
  final VoidCallback onTap;
  const _RoomCard({required this.room, required this.onTap});
  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  bool _hovered = false;

  Color get _statusAccent => switch (widget.room.status) {
    RoomStatus.available => AppColors.success,
    RoomStatus.occupied => AppColors.danger,
    RoomStatus.maintenance => AppColors.warning,
  };

  Color get _bgColor => switch (widget.room.status) {
    RoomStatus.available => _hovered ? const Color(0xFFD1FAE5) : const Color(0xFFF0FDF4),
    RoomStatus.occupied => _hovered ? AppColors.muted : AppColors.surface,
    RoomStatus.maintenance => _hovered ? const Color(0xFFFEF3C7) : const Color(0xFFFFFBEB),
  };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: _hovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hovered ? _statusAccent.withOpacity(0.4) : Colors.transparent, width: 1.5),
            boxShadow: _hovered ? [BoxShadow(color: _statusAccent.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Stack(
            children: [
              Positioned(top: 0, left: 0, right: 0,
                  child: Container(height: 4, decoration: BoxDecoration(color: _statusAccent, borderRadius: const BorderRadius.vertical(top: Radius.circular(14))))),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(widget.room.roomCode, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.foreground, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                      StatusBadge.room(widget.room.status),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(child: Text(widget.room.areaName.isNotEmpty ? widget.room.areaName : '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted))),
                    ]),
                    const Spacer(),
                    if (widget.room.areaSize > 0)
                      Row(children: [
                        const Icon(Icons.straighten_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${widget.room.areaSize} m²', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                      ]),
                    if (widget.room.tenant != null) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.person_outline_rounded, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(child: Text(widget.room.tenant!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                      ]),
                    ],
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: formatVnd(widget.room.basePrice), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _statusAccent)),
                        TextSpan(text: '/tháng', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted)),
                      ])),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _hovered ? _statusAccent : AppColors.textMuted),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Room List ────────────────────────────────────────────────────────────────

class _RoomList extends StatelessWidget {
  final List<RoomModel> rooms;
  final ValueChanged<RoomModel> onTap;
  const _RoomList({required this.rooms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _RoomListItem(room: rooms[i], onTap: () => onTap(rooms[i])),
    );
  }
}

class _RoomListItem extends StatefulWidget {
  final RoomModel room;
  final VoidCallback onTap;
  const _RoomListItem({required this.room, required this.onTap});
  @override
  State<_RoomListItem> createState() => _RoomListItemState();
}

class _RoomListItemState extends State<_RoomListItem> {
  bool _hovered = false;

  Color get _statusColor => switch (widget.room.status) {
    RoomStatus.available => AppColors.success,
    RoomStatus.occupied => AppColors.danger,
    RoomStatus.maintenance => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.muted : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hovered ? _statusColor.withOpacity(0.4) : AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(width: 4, height: 48, decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(widget.room.roomCode, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.foreground)),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(widget.room.areaName.isNotEmpty ? widget.room.areaName : '—', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                  if (widget.room.areaSize > 0) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.straighten_rounded, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text('${widget.room.areaSize} m²', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ]),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                Text(formatVnd(widget.room.basePrice), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _statusColor)),
                const SizedBox(height: 4),
                StatusBadge.room(widget.room.status),
              ]),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty / Error States ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;
  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(36)), child: const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 30)),
        const SizedBox(height: 16),
        Text(hasFilter ? 'Không tìm thấy phòng phù hợp' : 'Chưa có phòng nào', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground)),
        const SizedBox(height: 8),
        Text(hasFilter ? 'Thử thay đổi bộ lọc hoặc từ khóa' : 'Thêm phòng đầu tiên để bắt đầu', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        if (hasFilter)
          OutlinedButton.icon(onPressed: onClear, icon: const Icon(Icons.filter_alt_off_rounded, size: 16), label: const Text('Xóa bộ lọc'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)))
        else
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Thêm phòng mới')),
      ]),
    ));
  }
}

class _RoomsError extends StatelessWidget {
  final String detail;
  final VoidCallback onRetry;
  const _RoomsError({required this.detail, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(32)), child: const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 28)),
        const SizedBox(height: 16),
        Text('Không thể tải danh sách phòng', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground)),
        const SizedBox(height: 8),
        Text(detail, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Thử lại')),
      ]),
    ));
  }
}

// ─── Skeleton Loaders ─────────────────────────────────────────────────────────

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 650 ? 3 : 2;
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35),
        itemCount: 8,
        itemBuilder: (_, __) => const _SkeletonCard(),
      );
    });
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16), itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const _SkeletonCard(height: 80),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final double? height;
  const _SkeletonCard({this.height});
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
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
        decoration: BoxDecoration(color: Color.lerp(AppColors.muted, AppColors.border, _anim.value), borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ─── Add Room Sheet (shared, also used from Dashboard) ───────────────────────

class AddRoomSheet extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AddRoomSheet({super.key, this.onSuccess});

  @override
  State<AddRoomSheet> createState() => _AddRoomSheetState();
}

class _AddRoomSheetState extends State<AddRoomSheet> {
  final _codeCtl   = TextEditingController();
  final _priceCtl  = TextEditingController();
  final _areaCtl   = TextEditingController();
  final _nameCtl   = TextEditingController();
  final _elecCtl   = TextEditingController(text: '3500');
  final _waterCtl  = TextEditingController(text: '15000');
  final _addressCtl = TextEditingController();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeCtl.dispose(); _priceCtl.dispose(); _areaCtl.dispose();
    _nameCtl.dispose(); _elecCtl.dispose(); _waterCtl.dispose(); _addressCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      // TODO: gọi ApiClient.createRoom(...) khi backend có endpoint POST /api/business/rooms
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm phòng ${_codeCtl.text.trim()}'), backgroundColor: AppColors.success),
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
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Thêm phòng mới', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.foreground)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 20),

              // Form
              Row(children: [
                Expanded(child: _FormField(label: 'Mã phòng *', controller: _codeCtl, hint: 'P101', validator: (v) => (v?.trim().isEmpty ?? true) ? 'Bắt buộc' : null)),
                const SizedBox(width: 12),
                Expanded(child: _FormField(label: 'Diện tích (m²)', controller: _areaCtl, hint: '25', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              _FormField(label: 'Giá thuê (đ/tháng) *', controller: _priceCtl, hint: '3000000', keyboardType: TextInputType.number, validator: (v) => (v?.trim().isEmpty ?? true) ? 'Bắt buộc' : null),
              const SizedBox(height: 12),
              _FormField(label: 'Khu vực / Tên tòa', controller: _nameCtl, hint: 'Khu A, Tòa B'),
              const SizedBox(height: 12),
              _FormField(label: 'Địa chỉ', controller: _addressCtl, hint: '123 Đường ABC, Quận 1'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _FormField(label: 'Giá điện (đ/kWh)', controller: _elecCtl, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _FormField(label: 'Giá nước (đ/m³)', controller: _waterCtl, keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(_loading ? 'Đang thêm...' : 'Thêm phòng'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  const _FormField({required this.label, required this.controller, this.hint, this.keyboardType, this.validator, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground),
          decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
        ),
      ],
    );
  }
}