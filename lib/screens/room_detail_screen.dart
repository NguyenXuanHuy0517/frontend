// lib/screens/room_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../services/auth.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class RoomDetailScreen extends StatefulWidget {
  final int roomId;
  const RoomDetailScreen({required this.roomId, super.key});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<RoomModel> _future;
  bool _editing = false;
  bool _saving = false;

  // Edit controllers — chỉ cho các field có thể sửa
  final _basePriceCtl  = TextEditingController();
  final _elecPriceCtl  = TextEditingController();
  final _waterPriceCtl = TextEditingController();
  final _areaSizeCtl   = TextEditingController();
  final _amenitiesCtl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  /// Gọi API: GET /api/business/rooms/{roomId}
  void _load() => setState(() {
    _future = ApiClient.fetchRoomDetail(widget.roomId);
  });

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [_basePriceCtl, _elecPriceCtl, _waterPriceCtl, _areaSizeCtl, _amenitiesCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _enterEdit(RoomModel r) {
    _basePriceCtl.text  = r.basePrice.toString();
    _elecPriceCtl.text  = r.elecPrice.toString();
    _waterPriceCtl.text = r.waterPrice.toString();
    _areaSizeCtl.text   = r.areaSize.toStringAsFixed(0);
    _amenitiesCtl.text  = r.amenities.join(', ');
    setState(() => _editing = true);
  }

  /// Gọi API: PUT /api/business/rooms/{roomId}
  Future<void> _saveEdit(RoomModel r) async {
    setState(() => _saving = true);

    int safeInt(String s, int fb) =>
        int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? fb;
    double safeDbl(String s, double fb) =>
        double.tryParse(s.replaceAll(RegExp(r'[^\d.]'), '')) ?? fb;

    final amenities = _amenitiesCtl.text.trim().isEmpty
        ? r.amenities
        : _amenitiesCtl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final payload = {
      'roomId':    r.roomId,
      'roomCode':  r.roomCode,
      'basePrice': safeInt(_basePriceCtl.text, r.basePrice),
      'elecPrice': safeInt(_elecPriceCtl.text, r.elecPrice),
      'waterPrice': safeInt(_waterPriceCtl.text, r.waterPrice),
      'areaSize':  safeInt(_areaSizeCtl.text, r.areaSize),
      'status':    r.statusString,
      'areaName':  r.areaName ?? '',
      'address':   r.address ?? '',
      'latitude':  r.latitude ?? 0.0,
      'longitude': r.longitude ?? 0.0,
      'images':    r.images,
      'amenities': amenities,
      if (r.areaId != null) 'areaId': r.areaId,
    };

    try {
      await ApiClient.updateRoom(widget.roomId, payload);
      _load();
      if (mounted) setState(() => _editing = false);
      _snack('Lưu thành công', AppColors.success);
    } catch (e) {
      _snack('Lỗi: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Gọi API: PATCH /api/business/rooms/{roomId}/status?status=...
  Future<void> _changeStatus(String newStatus) async {
    try {
      await ApiClient.updateRoomStatus(widget.roomId, newStatus);
      _load();
      _snack('Đã cập nhật trạng thái', AppColors.success);
    } catch (e) {
      _snack('Lỗi: $e', AppColors.danger);
    }
  }

  Future<void> _updateImages(RoomModel r, List<String> imgs) async {
    final payload = {
      'roomId':    r.roomId,
      'roomCode':  r.roomCode,
      'basePrice': r.basePrice,
      'elecPrice': r.elecPrice,
      'waterPrice': r.waterPrice,
      'areaSize':  r.areaSize,
      'status':    r.statusString,
      'areaName':  r.areaName ?? '',
      'address':   r.address ?? '',
      'latitude':  r.latitude ?? 0.0,
      'longitude': r.longitude ?? 0.0,
      'images':    imgs,
      'amenities': r.amenities,
      if (r.areaId != null) 'areaId': r.areaId,
    };
    try {
      await ApiClient.updateRoom(widget.roomId, payload);
      _load();
    } catch (_) {}
  }

  void _showStatusSheet(RoomModel r) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _StatusSheet(current: r.status, onSelect: _changeStatus),
  );

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthService.isHostOrAdmin();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<RoomModel>(
        future: _future,
        builder: (context, snapshot) {
          final room = snapshot.data;
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              _buildAppBar(room, canEdit),
            ],
            body: Builder(builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text('Không tải được dữ liệu',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                    const SizedBox(height: 6),
                    Text('${snapshot.error}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Thử lại'),
                    ),
                  ]),
                );
              }
              if (room == null) return const Center(child: Text('Không có dữ liệu'));

              return TabBarView(
                controller: _tab,
                children: [
                  _InfoTab(
                    room: room,
                    editing: _editing,
                    areaSizeCtl: _areaSizeCtl,
                    onImageChanged: (imgs) => _updateImages(room, imgs),
                  ),
                  _PriceTab(
                    room: room,
                    editing: _editing,
                    basePriceCtl: _basePriceCtl,
                    elecPriceCtl: _elecPriceCtl,
                    waterPriceCtl: _waterPriceCtl,
                    amenitiesCtl: _amenitiesCtl,
                  ),
                  _ContractTab(room: room),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(RoomModel? room, bool canEdit) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: const BackButton(color: AppColors.foreground),
      title: Text(
        room?.roomCode ?? 'Chi tiết phòng',
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground),
      ),
      actions: canEdit && room != null ? [
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppColors.foreground),
          tooltip: 'Đổi trạng thái',
          onPressed: () => _showStatusSheet(room),
        ),
        if (_saving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          IconButton(
            icon: Icon(
              _editing ? Icons.check_rounded : Icons.edit_rounded,
              color: _editing ? AppColors.success : AppColors.foreground,
            ),
            tooltip: _editing ? 'Lưu' : 'Chỉnh sửa',
            onPressed: () {
              if (_editing) _saveEdit(room);
              else _enterEdit(room);
            },
          ),
        if (_editing)
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.danger),
            tooltip: 'Huỷ',
            onPressed: () => setState(() => _editing = false),
          ),
      ] : null,
      bottom: TabBar(
        controller: _tab,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'Thông tin'),
          Tab(text: 'Giá & Tiện ích'),
          Tab(text: 'Hợp đồng'),
        ],
      ),
    );
  }
}

// ─── Tab 1: Thông tin + Gallery ───────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final RoomModel room;
  final bool editing;
  final TextEditingController areaSizeCtl;
  final Future<void> Function(List<String>) onImageChanged;

  const _InfoTab({
    required this.room,
    required this.editing,
    required this.areaSizeCtl,
    required this.onImageChanged,
  });

  Color get _statusColor => switch (room.status) {
    RoomStatus.available   => AppColors.success,
    RoomStatus.occupied    => AppColors.danger,
    RoomStatus.rented      => AppColors.danger,
    RoomStatus.deposited   => const Color(0xFF8B5CF6),
    RoomStatus.maintenance => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero card
        _HeroCard(room: room, statusColor: _statusColor),
        const SizedBox(height: 20),

        // Layout 2 cột trên desktop
        LayoutBuilder(builder: (_, c) {
          final isWide = c.maxWidth > 700;

          final infoCol = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            TagLabel('Thông tin cơ bản'),
            const SizedBox(height: 12),
            if (editing)
              _EditField(label: 'Diện tích (m²)', controller: areaSizeCtl, keyboardType: TextInputType.number)
            else ...[
              _InfoRow(icon: Icons.meeting_room_outlined, label: 'Mã phòng',
                  value: room.roomCode.isEmpty ? '—' : room.roomCode),
              _InfoRow(icon: Icons.location_city_outlined, label: 'Khu vực',
                  value: (room.areaName?.isEmpty ?? true) ? '—' : room.areaName!),
              _InfoRow(icon: Icons.location_on_outlined, label: 'Địa chỉ',
                  value: (room.address?.isEmpty ?? true) ? '—' : room.address!),
              _InfoRow(icon: Icons.straighten_rounded, label: 'Diện tích',
                  value: room.areaSize > 0 ? '${room.areaSize.toStringAsFixed(0)} m²' : '—'),
              if ((room.latitude ?? 0) != 0)
                _InfoRow(icon: Icons.map_outlined, label: 'Tọa độ',
                    value: '${(room.latitude ?? 0).toStringAsFixed(4)}, ${(room.longitude ?? 0).toStringAsFixed(4)}'),
            ],
          ]);

          final galleryCol = _GallerySection(
            images: room.images,
            statusColor: _statusColor,
            onImagesChanged: onImageChanged,
          );

          if (isWide) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: infoCol),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: galleryCol),
            ]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            infoCol,
            const SizedBox(height: 24),
            galleryCol,
          ]);
        }),
      ]),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final RoomModel room;
  final Color statusColor;
  const _HeroCard({required this.room, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final initials = room.roomCode.length >= 2
        ? room.roomCode.substring(0, 2).toUpperCase()
        : (room.roomCode.isEmpty ? '?' : room.roomCode.toUpperCase());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.15), statusColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(initials,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: statusColor))),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(
            room.roomCode.isEmpty ? 'Phòng #${room.roomId}' : room.roomCode,
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900,
                color: AppColors.foreground, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          StatusBadge.room(room.status),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Text(
            formatVnd(room.basePrice),
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: statusColor),
          ),
          const Text('/tháng', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }
}

// ─── Gallery Section ──────────────────────────────────────────────────────────

class _GallerySection extends StatefulWidget {
  final List<String> images;
  final Color statusColor;
  final Future<void> Function(List<String>) onImagesChanged;
  const _GallerySection({required this.images, required this.statusColor, required this.onImagesChanged});

  @override
  State<_GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends State<_GallerySection> {
  late List<String> _images;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
  }

  @override
  void didUpdateWidget(_GallerySection old) {
    super.didUpdateWidget(old);
    if (old.images != widget.images) {
      _images = List.from(widget.images);
    }
  }

  Future<void> _addUrl() async {
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Thêm ảnh từ URL', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl, autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://example.com/room.jpg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Thêm')),
        ],
      ),
    );
    ctrl.dispose();
    if (url == null || url.isEmpty) return;
    final updated = [..._images, url];
    setState(() { _images = updated; _uploading = true; });
    await widget.onImagesChanged(updated);
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _remove(int i) async {
    final updated = [..._images]..removeAt(i);
    setState(() => _images = updated);
    await widget.onImagesChanged(updated);
  }

  void _preview(int i) => showDialog(
    context: context,
    builder: (_) => _GalleryDialog(images: _images, initialIndex: i),
  );

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        TagLabel('Ảnh phòng'),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: widget.statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('${_images.length} ảnh',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.statusColor)),
        ),
      ]),
      const SizedBox(height: 12),

      if (_images.isEmpty)
        GestureDetector(
          onTap: _addUrl,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.muted, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 32),
              const SizedBox(height: 8),
              Text('Thêm ảnh phòng',
                  style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
              const Text('Nhấn để thêm URL ảnh',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
          ),
        )
      else ...[
        // Ảnh chính
        GestureDetector(
          onTap: () => _preview(0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(fit: StackFit.expand, children: [
                Image.network(_images[0], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: AppColors.muted,
                        child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 40)),
                    loadingBuilder: (_, child, p) => p == null ? child
                        : Container(color: AppColors.muted,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))),
                Container(
                  decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                  )),
                ),
                const Positioned(bottom: 8, right: 8,
                    child: Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 18)),
                // Nút xoá ảnh đầu
                Positioned(top: 6, right: 6,
                    child: GestureDetector(onTap: () => _remove(0),
                        child: Container(width: 24, height: 24,
                            decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14)))),
              ]),
            ),
          ),
        ),

        // Thumbnail strip
        if (_images.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length + 1, // +1 cho nút thêm
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                // Nút thêm ảnh
                if (i == _images.length) {
                  return GestureDetector(
                    onTap: _addUrl,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.muted, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.add_rounded, color: AppColors.textMuted),
                    ),
                  );
                }
                return Stack(children: [
                  GestureDetector(
                    onTap: () => _preview(i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(width: 72, height: 72,
                          child: Image.network(_images[i], fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.muted,
                                  child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 20)))),
                    ),
                  ),
                  Positioned(top: 2, right: 2,
                      child: GestureDetector(onTap: () => _remove(i),
                          child: Container(width: 18, height: 18,
                              decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 11)))),
                ]);
              },
            ),
          ),
        ] else ...[
          // Chỉ có 1 ảnh → hiện nút thêm riêng
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _addUrl,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.muted, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_photo_alternate_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('Thêm ảnh', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
              ]),
            ),
          ),
        ],
      ],

      if (_uploading)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Đang lưu...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
    ]);
  }
}

// ─── Gallery Dialog (full screen preview) ────────────────────────────────────

class _GalleryDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _GalleryDialog({required this.images, required this.initialIndex});

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

class _GalleryDialogState extends State<_GalleryDialog> {
  late int _cur;
  late PageController _page;

  @override
  void initState() {
    super.initState();
    _cur  = widget.initialIndex;
    _page = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _page.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(children: [
        PageView.builder(
          controller: _page,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _cur = i),
          itemBuilder: (_, i) => InteractiveViewer(
            child: Image.network(widget.images[i], fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 64))),
          ),
        ),
        // Close
        Positioned(top: 16, right: 16,
            child: GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20)))),
        // Counter
        Positioned(top: 20, left: 0, right: 0,
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text('${_cur + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ))),
        // Dots
        Positioned(bottom: 20, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _cur ? 20 : 6, height: 6,
                  decoration: BoxDecoration(
                    color: i == _cur ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )))),
        // Prev / Next
        if (widget.images.length > 1) ...[
          Positioned(left: 8, top: 0, bottom: 0, child: Center(child: GestureDetector(
            onTap: () { if (_cur > 0) _page.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut); },
            child: Container(padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: Icon(Icons.chevron_left_rounded,
                    color: _cur > 0 ? Colors.white : Colors.white30, size: 28)),
          ))),
          Positioned(right: 8, top: 0, bottom: 0, child: Center(child: GestureDetector(
            onTap: () { if (_cur < widget.images.length - 1) _page.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut); },
            child: Container(padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: Icon(Icons.chevron_right_rounded,
                    color: _cur < widget.images.length - 1 ? Colors.white : Colors.white30, size: 28)),
          ))),
        ],
      ]),
    );
  }
}

// ─── Tab 2: Giá & Tiện ích ────────────────────────────────────────────────────

class _PriceTab extends StatelessWidget {
  final RoomModel room;
  final bool editing;
  final TextEditingController basePriceCtl, elecPriceCtl, waterPriceCtl, amenitiesCtl;

  const _PriceTab({
    required this.room, required this.editing,
    required this.basePriceCtl, required this.elecPriceCtl,
    required this.waterPriceCtl, required this.amenitiesCtl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TagLabel('Giá cả'),
        const SizedBox(height: 12),
        if (editing) ...[
          _EditField(label: 'Giá thuê (đ/tháng)', controller: basePriceCtl, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _EditField(label: 'Giá điện (đ/kWh)', controller: elecPriceCtl, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _EditField(label: 'Giá nước (đ/m³)', controller: waterPriceCtl, keyboardType: TextInputType.number)),
          ]),
        ] else
          _PriceGrid(room: room),

        const SizedBox(height: 24),
        TagLabel('Tiện ích'),
        const SizedBox(height: 12),
        if (editing)
          _EditField(
            label: 'Tiện ích (phân cách bằng dấu phẩy)',
            controller: amenitiesCtl,
            hint: 'WiFi, Điều hòa, Máy giặt...',
          )
        else
          _AmenitiesChips(amenities: room.amenities),
      ]),
    );
  }
}

class _PriceGrid extends StatelessWidget {
  final RoomModel room;
  const _PriceGrid({required this.room});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child: _PriceCard(
          icon: Icons.home_rounded, label: 'Tiền phòng',
          value: formatVnd(room.basePrice), color: AppColors.primary,
        )),
        const SizedBox(width: 12),
        Expanded(child: _PriceCard(
          icon: Icons.bolt_rounded, label: 'Tiền điện',
          value: '${formatVnd(room.elecPrice)}/kWh', color: AppColors.warning,
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _PriceCard(
          icon: Icons.water_drop_outlined, label: 'Tiền nước',
          value: '${formatVnd(room.waterPrice)}/m³', color: const Color(0xFF06B6D4),
        )),
        const Expanded(child: SizedBox()),
      ]),
    ]);
  }
}

class _PriceCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _PriceCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16)),
      const SizedBox(height: 10),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.foreground))),
    ]),
  );
}

class _AmenitiesChips extends StatelessWidget {
  final List<String> amenities;
  const _AmenitiesChips({required this.amenities});

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 16),
          SizedBox(width: 10),
          Text('Chưa có thông tin tiện ích', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8,
        children: amenities.map((a) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14),
            const SizedBox(width: 5),
            Text(a, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ]),
        )).toList());
  }
}

// ─── Tab 3: Hợp đồng ─────────────────────────────────────────────────────────

class _ContractTab extends StatelessWidget {
  final RoomModel room;
  const _ContractTab({required this.room});

  @override
  Widget build(BuildContext context) {
    final isRented    = room.status == RoomStatus.rented || room.status == RoomStatus.occupied;
    final isDeposited = room.status == RoomStatus.deposited;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(36)),
              child: const Icon(Icons.description_outlined, color: AppColors.textMuted, size: 32)),
          const SizedBox(height: 16),
          Text(
            isRented ? 'Hợp đồng đang hiệu lực'
                : isDeposited ? 'Đã đặt cọc — chờ ký hợp đồng'
                : 'Chưa có hợp đồng',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            isRented ? 'Xem chi tiết hợp đồng và thông tin người thuê'
                : isDeposited ? 'Tiến hành ký hợp đồng chính thức'
                : 'Phòng hiện chưa có người thuê',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          if (!isRented)
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Tạo hợp đồng mới'),
            ),
        ]),
      ),
    );
  }
}

// ─── Status Sheet ─────────────────────────────────────────────────────────────

class _StatusSheet extends StatelessWidget {
  final RoomStatus current;
  final ValueChanged<String> onSelect;
  const _StatusSheet({required this.current, required this.onSelect});

  static const _options = [
    (status: 'AVAILABLE',   label: 'Phòng trống',    subtitle: 'Sẵn sàng cho thuê',        icon: Icons.door_front_door_outlined, color: 0xFF10B981),
    (status: 'DEPOSITED',   label: 'Đã đặt cọc',    subtitle: 'Khách đã đặt cọc, chờ ký',  icon: Icons.savings_outlined,         color: 0xFF8B5CF6),
    (status: 'RENTED',      label: 'Đang cho thuê',  subtitle: 'Phòng đang có người ở',     icon: Icons.people_rounded,           color: 0xFFEF4444),
    (status: 'MAINTENANCE', label: 'Đang sửa chữa', subtitle: 'Phòng tạm không sử dụng',   icon: Icons.build_rounded,            color: 0xFFF59E0B),
  ];

  bool _isSelected(String s) => switch (current) {
    RoomStatus.available   => s == 'AVAILABLE',
    RoomStatus.occupied    => s == 'RENTED',
    RoomStatus.rented      => s == 'RENTED',
    RoomStatus.deposited   => s == 'DEPOSITED',
    RoomStatus.maintenance => s == 'MAINTENANCE',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Cập nhật trạng thái',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Chọn trạng thái phù hợp với thực tế',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
            ]),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final opt = _options[i];
              final color = Color(opt.color);
              final selected = _isSelected(opt.status);
              return Material(
                color: selected ? color.withValues(alpha: 0.08) : AppColors.muted,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () { Navigator.pop(context); onSelect(opt.status); },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: selected ? BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ) : null,
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: Icon(opt.icon, color: color, size: 18)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(opt.label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                        Text(opt.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ])),
                      if (selected) Icon(Icons.check_circle_rounded, color: color, size: 20),
                    ]),
                  ),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(width: 34, height: 34,
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.textSecondary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
      ])),
    ]),
  );
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hint;
  const _EditField({required this.label, required this.controller, this.keyboardType, this.hint});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
    Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
    const SizedBox(height: 6),
    TextFormField(
      controller: controller, keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    ),
  ]);
}