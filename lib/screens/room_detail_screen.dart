// lib/screens/room_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../services/auth.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

// ─── Notifier — tránh setState trong widget lớn ───────────────────────────────
class _RoomDetailNotifier extends ChangeNotifier {
  RoomModel? room;
  bool isEditing = false;
  bool isSaving  = false;

  void setRoom(RoomModel r) { room = r; notifyListeners(); }
  void setEditing(bool v)   { isEditing = v; notifyListeners(); }
  void setSaving(bool v)    { isSaving = v; notifyListeners(); }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class RoomDetailScreen extends StatefulWidget {
  final int roomId;
  const RoomDetailScreen({required this.roomId, super.key});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late Future<RoomModel> _futureRoom;
  final _notifier = _RoomDetailNotifier();

  final _basePriceCtl  = TextEditingController();
  final _elecPriceCtl  = TextEditingController();
  final _waterPriceCtl = TextEditingController();
  final _areaSizeCtl   = TextEditingController();
  final _areaNameCtl   = TextEditingController();
  final _addressCtl    = TextEditingController();
  final _amenitiesCtl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadRoom();
  }

  void _loadRoom() {
    _futureRoom = ApiClient.fetchRoomDetail(widget.roomId);
    _futureRoom.then((r) { if (mounted) _notifier.setRoom(r); });
  }

  Future<void> _refresh() async {
    setState(() {
      _futureRoom = ApiClient.fetchRoomDetail(widget.roomId);
    });
    _futureRoom.then((r) { if (mounted) _notifier.setRoom(r); });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _notifier.dispose();
    for (final c in [_basePriceCtl, _elecPriceCtl, _waterPriceCtl, _areaSizeCtl, _areaNameCtl, _addressCtl, _amenitiesCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _enterEdit(RoomModel room) {
    _basePriceCtl.text  = room.basePrice.toString();
    _elecPriceCtl.text  = room.elecPrice.toString();
    _waterPriceCtl.text = room.waterPrice.toString();
    _areaSizeCtl.text   = room.areaSize.toString();
    _areaNameCtl.text   = room.areaName;
    _addressCtl.text    = room.address;
    _amenitiesCtl.text  = room.amenities.join(', ');
    _notifier.setEditing(true);
  }

  Future<void> _saveEdit(RoomModel room) async {
    num safeNum(String s, num fb) => num.tryParse(s.replaceAll(RegExp(r'[^\d.]'), '')) ?? fb;
    int safeInt(String s, int fb) => int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? fb;

    final amenities = _amenitiesCtl.text.trim().isEmpty
        ? room.amenities
        : _amenitiesCtl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final payload = {
      'roomId': room.roomId, 'roomCode': room.roomCode,
      'basePrice': safeNum(_basePriceCtl.text, room.basePrice),
      'elecPrice': safeNum(_elecPriceCtl.text, room.elecPrice),
      'waterPrice': safeNum(_waterPriceCtl.text, room.waterPrice),
      'status': room.statusString,
      'areaSize': safeInt(_areaSizeCtl.text, room.areaSize).toDouble(),
      'areaName': _areaNameCtl.text.trim().isEmpty ? room.areaName : _areaNameCtl.text.trim(),
      'address': _addressCtl.text.trim().isEmpty ? room.address : _addressCtl.text.trim(),
      'latitude': room.latitude, 'longitude': room.longitude,
      'images': room.images, 'amenities': amenities,
    };

    // Bước 1: async work TRƯỚC setState
    _notifier.setSaving(true);
    RoomModel? updated;
    Object? error;
    try {
      updated = await ApiClient.updateRoom(widget.roomId, payload);
    } catch (e) {
      error = e;
    }
    if (!mounted) return;
    // Bước 2: cập nhật state SAU khi async xong
    _notifier.setSaving(false);
    if (error != null) {
      _showSnack('Lỗi khi lưu: $error', AppColors.danger);
    } else {
      _notifier.isEditing = false;
      _notifier.setRoom(updated!);
      _showSnack('Lưu thay đổi thành công', AppColors.success);
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    Object? error;
    try {
      await ApiClient.updateRoomStatus(widget.roomId, newStatus);
    } catch (e) { error = e; }
    if (!mounted) return;
    if (error != null) {
      _showSnack('Lỗi: $error', AppColors.danger);
    } else {
      _showSnack('Đã cập nhật trạng thái', AppColors.success);
      _refresh();
    }
  }

  Future<void> _updateImages(RoomModel room, List<String> imgs) async {
    final payload = {
      'roomId': room.roomId, 'roomCode': room.roomCode,
      'basePrice': room.basePrice, 'elecPrice': room.elecPrice,
      'waterPrice': room.waterPrice, 'status': room.statusString,
      'areaSize': room.areaSize.toDouble(),
      'areaName': room.areaName, 'address': room.address,
      'latitude': room.latitude, 'longitude': room.longitude,
      'images': imgs, 'amenities': room.amenities,
    };
    try {
      final updated = await ApiClient.updateRoom(widget.roomId, payload);
      if (mounted) _notifier.setRoom(updated);
    } catch (_) {}
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _showStatusSheet(RoomModel room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StatusSheet(current: room.status, onSelect: _changeStatus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthService.isHostOrAdmin();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _RoomDetailAppBar(
        notifier: _notifier,
        canEdit: canEdit,
        tabCtrl: _tabCtrl,
        onStatusTap: () { if (_notifier.room != null) _showStatusSheet(_notifier.room!); },
        onEditTap: () {
          if (_notifier.room == null) return;
          if (_notifier.isEditing) _saveEdit(_notifier.room!);
          else _enterEdit(_notifier.room!);
        },
        onCancelTap: () => _notifier.setEditing(false),
      ),
      body: FutureBuilder<RoomModel>(
        future: _futureRoom,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorBody(error: snapshot.error.toString(), onRetry: _refresh);
          }
          final room = snapshot.data;
          if (room == null) return const Center(child: Text('Không có dữ liệu'));

          return TabBarView(
            controller: _tabCtrl,
            children: [
              RepaintBoundary(child: _InfoTab(room: room, notifier: _notifier, areaNameCtl: _areaNameCtl, addressCtl: _addressCtl, areaSizeCtl: _areaSizeCtl)),
              RepaintBoundary(child: _PriceTab(room: room, notifier: _notifier, basePriceCtl: _basePriceCtl, elecPriceCtl: _elecPriceCtl, waterPriceCtl: _waterPriceCtl, amenitiesCtl: _amenitiesCtl, onImagesChanged: (imgs) => _updateImages(room, imgs))),
              RepaintBoundary(child: _ContractTab(room: room)),
            ],
          );
        },
      ),
    );
  }
}

class _RoomDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final _RoomDetailNotifier notifier;
  final bool canEdit;
  final TabController tabCtrl;
  final VoidCallback onStatusTap, onEditTap, onCancelTap;

  const _RoomDetailAppBar({
    required this.notifier, required this.canEdit, required this.tabCtrl,
    required this.onStatusTap, required this.onEditTap, required this.onCancelTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: const BackButton(color: AppColors.foreground),
      title: ListenableBuilder(
        listenable: notifier,
        builder: (_, __) => Text(
          notifier.room?.roomCode ?? 'Chi tiết phòng',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground),
        ),
      ),
      actions: canEdit ? [
        ListenableBuilder(
          listenable: notifier,
          builder: (_, __) {
            if (notifier.room == null) return const SizedBox.shrink();
            return Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Đổi trạng thái', icon: const Icon(Icons.tune_rounded, color: AppColors.foreground), onPressed: onStatusTap),
              if (notifier.isSaving)
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              else
                IconButton(
                  tooltip: notifier.isEditing ? 'Lưu' : 'Chỉnh sửa',
                  icon: Icon(notifier.isEditing ? Icons.check_rounded : Icons.edit_rounded,
                      color: notifier.isEditing ? AppColors.success : AppColors.foreground),
                  onPressed: onEditTap,
                ),
              if (notifier.isEditing)
                IconButton(tooltip: 'Huỷ', icon: const Icon(Icons.close_rounded, color: AppColors.danger), onPressed: onCancelTap),
            ]);
          },
        ),
      ] : null,
      bottom: TabBar(
        controller: tabCtrl,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [Tab(text: 'Thông tin'), Tab(text: 'Giá & Tiện ích'), Tab(text: 'Hợp đồng')],
      ),
    );
  }
}

// ─── Status Sheet ────────────────────────────────────────────

class _StatusSheet extends StatelessWidget {
  final RoomStatus current;
  final ValueChanged<String> onSelect;
  const _StatusSheet({required this.current, required this.onSelect});

  static const _options = [
    _StatusOption(status: 'AVAILABLE',   label: 'Phòng trống',   subtitle: 'Phòng sẵn sàng cho thuê',        icon: Icons.door_front_door_outlined, colorVal: 0xFF10B981),
    _StatusOption(status: 'DEPOSITED',   label: 'Đã đặt cọc',   subtitle: 'Khách đã đặt cọc, chờ ký HĐ',    icon: Icons.savings_outlined,         colorVal: 0xFF8B5CF6),
    _StatusOption(status: 'RENTED',      label: 'Đang cho thuê', subtitle: 'Phòng đang có người ở',          icon: Icons.people_rounded,           colorVal: 0xFFEF4444),
    _StatusOption(status: 'MAINTENANCE', label: 'Đang sửa chữa', subtitle: 'Phòng tạm không sử dụng',        icon: Icons.build_rounded,            colorVal: 0xFFF59E0B),
  ];

  bool _isSelected(String status) => switch (current) {
    RoomStatus.available   => status == 'AVAILABLE',
    RoomStatus.deposited   => status == 'DEPOSITED',
    RoomStatus.rented      => status == 'RENTED',
    RoomStatus.maintenance => status == 'MAINTENANCE',
    // TODO: Handle this case.
    RoomStatus.occupied => throw UnimplementedError(),
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Padding(padding: EdgeInsets.only(top: 12), child: _SheetHandle())),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Cập nhật trạng thái phòng',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground)),
                const SizedBox(height: 4),
                const Text('Chọn trạng thái phù hợp với tình trạng thực tế',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 16),
              ]),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _options.length,
              itemBuilder: (context, i) {
                final opt = _options[i];
                final selected = _isSelected(opt.status);
                final color = Color(opt.colorVal);
                return Padding(
                  padding: EdgeInsets.only(bottom: i < _options.length - 1 ? 10 : 0),
                  child: _StatusOptionTile(opt: opt, color: color, selected: selected,
                      onTap: () { Navigator.pop(context); onSelect(opt.status); }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption {
  final String status, label, subtitle;
  final IconData icon;
  final int colorVal;
  const _StatusOption({required this.status, required this.label, required this.subtitle, required this.icon, required this.colorVal});
}

class _StatusOptionTile extends StatelessWidget {
  final _StatusOption opt;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusOptionTile({required this.opt, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(0.08) : AppColors.muted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: selected ? BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ) : null,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(opt.icon, color: color, size: 18),
            ),
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
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
  );
}

// ─── Error Body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
        const SizedBox(height: 12),
        Text('Lỗi: $error', style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Thử lại')),
      ]),
    ),
  );
}

// ─── Tab 1: Thông tin ─────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final RoomModel room;
  final _RoomDetailNotifier notifier;
  final TextEditingController areaNameCtl, addressCtl, areaSizeCtl;
  const _InfoTab({required this.room, required this.notifier, required this.areaNameCtl, required this.addressCtl, required this.areaSizeCtl});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusAccent(room.status);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RepaintBoundary(child: _HeroCard(room: room, statusColor: statusColor)),
        const SizedBox(height: 20),
        const _SectionTitle(title: 'Thông tin cơ bản'),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: notifier,
          builder: (_, __) => notifier.isEditing
              ? Column(mainAxisSize: MainAxisSize.min, children: [
            _EditField(label: 'Khu vực / Tên tòa', controller: areaNameCtl),
            const SizedBox(height: 12),
            _EditField(label: 'Địa chỉ', controller: addressCtl),
            const SizedBox(height: 12),
            _EditField(label: 'Diện tích (m²)', controller: areaSizeCtl, keyboardType: TextInputType.number),
          ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
            _DetailRow(icon: Icons.home_work_outlined, label: 'Mã phòng', value: room.roomCode),
            _DetailRow(icon: Icons.location_city_outlined, label: 'Khu vực', value: room.areaName.isEmpty ? '—' : room.areaName),
            _DetailRow(icon: Icons.location_on_outlined, label: 'Địa chỉ', value: room.address.isEmpty ? '—' : room.address),
            _DetailRow(icon: Icons.straighten_rounded, label: 'Diện tích', value: '${room.areaSize} m²'),
            if (room.latitude != 0 || room.longitude != 0)
              _DetailRow(icon: Icons.map_outlined, label: 'Tọa độ',
                  value: '${room.latitude.toStringAsFixed(4)}, ${room.longitude.toStringAsFixed(4)}'),
          ]),
        ),
      ]),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final RoomModel room;
  final Color statusColor;
  const _HeroCard({required this.room, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(
            room.roomCode.length > 3 ? room.roomCode.substring(0, 3) : room.roomCode,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: statusColor),
          )),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(room.roomCode,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.foreground, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          StatusBadge.room(room.status),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Text(formatVnd(room.basePrice),
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: statusColor)),
          const Text('/tháng', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }
}

// ─── Tab 2: Giá & Tiện ích ────────────────────────────────────────────────────

class _PriceTab extends StatefulWidget {
  final RoomModel room;
  final _RoomDetailNotifier notifier;
  final TextEditingController basePriceCtl, elecPriceCtl, waterPriceCtl, amenitiesCtl;
  final Future<void> Function(List<String>) onImagesChanged;
  const _PriceTab({required this.room, required this.notifier, required this.basePriceCtl, required this.elecPriceCtl, required this.waterPriceCtl, required this.amenitiesCtl, required this.onImagesChanged});
  @override
  State<_PriceTab> createState() => _PriceTabState();
}

class _PriceTabState extends State<_PriceTab> {
  // ValueNotifier thay setState — chỉ rebuild gallery
  late final ValueNotifier<List<String>> _imagesNotifier;
  final ValueNotifier<bool> _uploadingNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _imagesNotifier = ValueNotifier(List<String>.from(widget.room.images));
  }

  @override
  void dispose() {
    _imagesNotifier.dispose();
    _uploadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _addImageUrl() async {
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Thêm ảnh từ URL', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(hintText: 'https://example.com/image.jpg'),
            keyboardType: TextInputType.url),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Thêm')),
        ],
      ),
    );
    ctrl.dispose();
    if (url == null || url.isEmpty) return;
    // Cập nhật ValueNotifier — KHÔNG setState
    final updated = [..._imagesNotifier.value, url];
    _imagesNotifier.value = updated;
    _uploadingNotifier.value = true;
    await widget.onImagesChanged(updated);
    if (mounted) _uploadingNotifier.value = false;
  }

  Future<void> _removeImage(int index) async {
    final updated = [..._imagesNotifier.value]..removeAt(index);
    _imagesNotifier.value = updated;
    await widget.onImagesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle(title: 'Giá cả'),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: widget.notifier,
          builder: (_, __) => widget.notifier.isEditing
              ? _EditPriceSection(basePriceCtl: widget.basePriceCtl, elecPriceCtl: widget.elecPriceCtl, waterPriceCtl: widget.waterPriceCtl)
              : _DisplayPriceSection(room: widget.room),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Tiện ích'),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: widget.notifier,
          builder: (_, __) => widget.notifier.isEditing
              ? _EditField(label: 'Tiện ích (phân cách bằng dấu phẩy)', controller: widget.amenitiesCtl, hint: 'WiFi, Điều hoà...')
              : _AmenitiesDisplay(amenities: widget.room.amenities),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const _SectionTitle(title: 'Ảnh phòng'),
          TextButton.icon(
            onPressed: () => _showStorageTip(context),
            icon: const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
            label: const Text('Gợi ý lưu trữ',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, decoration: TextDecoration.underline)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          ),
        ]),
        const SizedBox(height: 12),
        // ValueListenableBuilder — chỉ rebuild gallery
        ValueListenableBuilder<List<String>>(
          valueListenable: _imagesNotifier,
          builder: (_, images, __) => _ImageGallery(
            images: images, onAdd: _addImageUrl,
            onDelete: _removeImage,
            onPreview: (i) => _showImagePreview(context, images, i),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _uploadingNotifier,
          builder: (_, uploading, __) => uploading
              ? const Padding(padding: EdgeInsets.only(top: 8), child: Row(children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Đang lưu ảnh...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]))
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        const _StorageTipBanner(),
      ]),
    );
  }

  void _showImagePreview(BuildContext context, List<String> images, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(children: [
          InteractiveViewer(child: Image.network(images[index], fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 64)))),
          Positioned(top: 8, right: 8,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
        ]),
      ),
    );
  }

  void _showStorageTip(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _StorageTipSheet(),
    );
  }
}

class _DisplayPriceSection extends StatelessWidget {
  final RoomModel room;
  const _DisplayPriceSection({required this.room});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Row(children: [
      Expanded(child: _PriceCard(icon: Icons.home_rounded, label: 'Tiền phòng', value: formatVnd(room.basePrice), color: AppColors.primary)),
      const SizedBox(width: 12),
      Expanded(child: _PriceCard(icon: Icons.bolt_rounded, label: 'Tiền điện', value: '${formatVnd(room.elecPrice)}/kWh', color: AppColors.warning)),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _PriceCard(icon: Icons.water_drop_outlined, label: 'Tiền nước', value: '${formatVnd(room.waterPrice)}/m³', color: AppColors.primary)),
      const Expanded(child: SizedBox()),
    ]),
  ]);
}

class _EditPriceSection extends StatelessWidget {
  final TextEditingController basePriceCtl, elecPriceCtl, waterPriceCtl;
  const _EditPriceSection({required this.basePriceCtl, required this.elecPriceCtl, required this.waterPriceCtl});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    _EditField(label: 'Giá thuê cơ bản (đ/tháng)', controller: basePriceCtl, keyboardType: TextInputType.number),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _EditField(label: 'Giá điện (đ/kWh)', controller: elecPriceCtl, keyboardType: TextInputType.number)),
      const SizedBox(width: 12),
      Expanded(child: _EditField(label: 'Giá nước (đ/m³)', controller: waterPriceCtl, keyboardType: TextInputType.number)),
    ]),
  ]);
}

class _AmenitiesDisplay extends StatelessWidget {
  final List<String> amenities;
  const _AmenitiesDisplay({required this.amenities});
  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
          SizedBox(width: 10),
          Text('Chưa có thông tin tiện ích', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8,
        children: amenities.map((a) => _AmenityChip(label: a)).toList());
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
    ]),
  );
}

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final VoidCallback onAdd;
  final Future<void> Function(int) onDelete;
  final void Function(int) onPreview;
  const _ImageGallery({required this.images, required this.onAdd, required this.onDelete, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          height: 120,
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 2)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 8),
            Text('Thêm ảnh phòng', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const Text('Nhấn để thêm URL ảnh', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.0),
      itemCount: images.length + 1,
      itemBuilder: (_, i) {
        if (i == images.length) {
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.5)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_rounded, color: AppColors.textMuted, size: 24),
                Text('Thêm ảnh', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }
        return RepaintBoundary(
          child: _ImageTile(url: images[i], onDelete: () => onDelete(i), onTap: () => onPreview(i)),
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  final VoidCallback onDelete, onTap;
  const _ImageTile({required this.url, required this.onDelete, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(fit: StackFit.expand, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 28)),
              loadingBuilder: (_, child, progress) => progress == null ? child
                  : Container(
                  decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))),
        ),
        Positioned(top: 4, right: 4,
            child: GestureDetector(onTap: onDelete,
                child: Container(width: 22, height: 22,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 13)))),
      ]),
    );
  }
}

class _StorageTipBanner extends StatelessWidget {
  const _StorageTipBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
    ),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 16),
      SizedBox(width: 8),
      Expanded(child: Text(
        'Tip: Upload ảnh lên Cloudinary/S3 → dán URL. DB chỉ lưu URL — nhanh và dễ CDN cache.',
        style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.5),
      )),
    ]),
  );
}

class _StorageTipSheet extends StatelessWidget {
  const _StorageTipSheet();
  static const _tips = [
    _TipData(icon: Icons.cloud_upload_outlined, colorVal: 0xFF3B82F6, title: 'Upload lên Cloud Storage', desc: 'Cloudinary (free 25GB), AWS S3, Supabase Storage. Upload qua presigned URL từ client.'),
    _TipData(icon: Icons.storage_rounded, colorVal: 0xFF10B981, title: 'Lưu URL vào DB (khuyên dùng)', desc: 'Cột `images` lưu comma-separated URLs. Không lưu base64/blob — tốn IO, không cache được.'),
    _TipData(icon: Icons.speed_rounded, colorVal: 0xFFF59E0B, title: 'CDN tự động tối ưu', desc: 'Cloudinary auto-resize, webp, CDN global. Đổi URL params: /w_400,q_auto/image.jpg'),
    _TipData(icon: Icons.code_rounded, colorVal: 0xFF8B5CF6, title: 'Backend endpoint đề xuất', desc: 'POST /api/business/rooms/{id}/images — multipart/form-data → upload cloud → lưu URL.'),
  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Center(child: _SheetHandle()),
          const SizedBox(height: 16),
          Text('Gợi ý lưu trữ ảnh tối ưu', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tips.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(bottom: i < _tips.length - 1 ? 12 : 0),
              child: _TipRow(data: _tips[i]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TipData {
  final IconData icon; final int colorVal; final String title, desc;
  const _TipData({required this.icon, required this.colorVal, required this.title, required this.desc});
}

class _TipRow extends StatelessWidget {
  final _TipData data;
  const _TipRow({required this.data});
  @override
  Widget build(BuildContext context) {
    final color = Color(data.colorVal);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(data.icon, color: color, size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data.title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
        const SizedBox(height: 2),
        Text(data.desc, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
      ])),
    ]);
  }
}

// ─── Tab 3: Hợp đồng ─────────────────────────────────────────────────────────

class _ContractTab extends StatelessWidget {
  final RoomModel room;
  const _ContractTab({required this.room});
  @override
  Widget build(BuildContext context) {
    final isActive = room.status == RoomStatus.rented;
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
            isActive ? 'Hợp đồng đang hiệu lực' : isDeposited ? 'Đã đặt cọc — chờ ký hợp đồng' : 'Chưa có hợp đồng',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            isActive ? 'Xem chi tiết hợp đồng và thông tin người thuê'
                : isDeposited ? 'Tiến hành ký hợp đồng chính thức'
                : 'Phòng hiện chưa có người thuê',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          if (!isActive)
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Tạo hợp đồng mới')),
        ]),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 18,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: 0.2)),
  ]);
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});
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
    Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
    const SizedBox(height: 6),
    TextFormField(controller: controller, keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
  ]);
}

class _PriceCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _PriceCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16)),
      const SizedBox(height: 10),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.foreground))),
    ]),
  );
}

// FIX: Thêm RoomStatus.occupied để switch exhaustive (đủ 5 case)
Color _statusAccent(RoomStatus s) => switch (s) {
  RoomStatus.available   => AppColors.success,
  RoomStatus.occupied    => AppColors.danger,
  RoomStatus.deposited   => const Color(0xFF8B5CF6),
  RoomStatus.rented      => AppColors.danger,
  RoomStatus.maintenance => AppColors.warning,
};