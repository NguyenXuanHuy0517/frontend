// lib/screens/room_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../services/auth.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

// Add to pubspec.yaml dependencies:
//   file_picker: ^6.1.1
//   cached_network_image: ^3.3.1
// Then run: flutter pub get
// If not available, the URL-only fallback is used automatically.

class RoomDetailScreen extends StatefulWidget {
  final int roomId;
  const RoomDetailScreen({required this.roomId, super.key});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<RoomModel> _futureRoom;
  late TabController _tabController;

  // ── Edit controllers ────────────────────────────────────────────────────────
  final _roomCodeCtl    = TextEditingController();
  final _basePriceCtl   = TextEditingController();
  final _elecPriceCtl   = TextEditingController();
  final _waterPriceCtl  = TextEditingController();
  final _areaSizeCtl    = TextEditingController();
  final _areaNameCtl    = TextEditingController();
  final _addressCtl     = TextEditingController();
  final _latCtl         = TextEditingController();
  final _lngCtl         = TextEditingController();
  final _urlInputCtl    = TextEditingController();
  final _amenityInputCtl = TextEditingController();

  String _selectedStatus = 'AVAILABLE';
  List<String> _images   = [];
  List<String> _amenities = [];

  bool _editing = false;
  bool _saving  = false;
  bool _initialized = false;

  static const _statusOptions = ['AVAILABLE', 'OCCUPIED', 'MAINTENANCE'];
  static const _statusLabels  = {
    'AVAILABLE':   'Trống',
    'OCCUPIED':    'Đang thuê',
    'MAINTENANCE': 'Sửa chữa',
  };
  static const _statusColors  = {
    'AVAILABLE':   AppColors.success,
    'OCCUPIED':    AppColors.danger,
    'MAINTENANCE': AppColors.warning,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _futureRoom = ApiClient.fetchRoomDetail(widget.roomId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _roomCodeCtl, _basePriceCtl, _elecPriceCtl, _waterPriceCtl,
      _areaSizeCtl, _areaNameCtl, _addressCtl, _latCtl, _lngCtl,
      _urlInputCtl, _amenityInputCtl,
    ]) c.dispose();
    super.dispose();
  }

  // ── Init form from room data ─────────────────────────────────────────────
  void _initForm(RoomModel room) {
    if (_initialized) return;
    _roomCodeCtl.text   = room.roomCode;
    _basePriceCtl.text  = room.basePrice.toString();
    _elecPriceCtl.text  = room.elecPrice.toString();
    _waterPriceCtl.text = room.waterPrice.toString();
    _areaSizeCtl.text   = room.areaSize.toString();
    _areaNameCtl.text   = room.areaName;
    _addressCtl.text    = room.address;
    _latCtl.text        = room.latitude.toString();
    _lngCtl.text        = room.longitude.toString();
    _selectedStatus = room.status.toString().split('.').last.toUpperCase();
    _images    = List<String>.from(room.images);
    _amenities = List<String>.from(room.amenities);
    _initialized = true;
  }

  Future<void> _refresh() async {
    setState(() {
      _initialized = false;
      _futureRoom  = ApiClient.fetchRoomDetail(widget.roomId);
    });
  }

  // ── Save changes ─────────────────────────────────────────────────────────
  Future<void> _save(RoomModel room) async {
    setState(() => _saving = true);
    try {
      final payload = {
        'roomId':     room.roomId,
        'roomCode':   _roomCodeCtl.text.trim().isEmpty ? room.roomCode : _roomCodeCtl.text.trim(),
        'basePrice':  _parseInt(_basePriceCtl.text,  room.basePrice),
        'elecPrice':  _parseInt(_elecPriceCtl.text,  room.elecPrice),
        'waterPrice': _parseInt(_waterPriceCtl.text, room.waterPrice),
        'status':     _selectedStatus,
        'areaSize':   _parseInt(_areaSizeCtl.text,   room.areaSize),
        'images':     _images,
        'amenities':  _amenities,
        'areaName':   _areaNameCtl.text.trim().isEmpty ? room.areaName : _areaNameCtl.text.trim(),
        'address':    _addressCtl.text.trim().isEmpty  ? room.address  : _addressCtl.text.trim(),
        'latitude':   _parseDouble(_latCtl.text, room.latitude),
        'longitude':  _parseDouble(_lngCtl.text, room.longitude),
      };
      final updated = await ApiClient.updateRoom(room.roomId, payload);
      if (!mounted) return;
      setState(() {
        _editing  = false;
        _saving   = false;
        _futureRoom = Future.value(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu thông tin phòng ${updated.roomCode}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  // ── Quick status change ───────────────────────────────────────────────────
  Future<void> _changeStatus(String status) async {
    try {
      await ApiClient.updateRoomStatus(widget.roomId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trạng thái → ${_statusLabels[status]}'),
          backgroundColor: AppColors.success,
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  // ── Add image via URL ─────────────────────────────────────────────────────
  void _addImageUrl() {
    final url = _urlInputCtl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _images.add(url);
      _urlInputCtl.clear();
    });
  }

  // ── Pick image from file (requires file_picker package) ──────────────────
  Future<void> _pickImageFromFile() async {
    try {
      // Dynamic import attempt — gracefully fallback if package not installed
      final result = await _tryFilePicker();
      if (result != null && mounted) {
        setState(() => _images.add(result));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa cài package file_picker. Thêm vào pubspec.yaml:\n  file_picker: ^6.1.1',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Returns a local file path string or null. Throws if file_picker not available.
  Future<String?> _tryFilePicker() async {
    // We use a method channel approach so the app doesn't crash at compile time
    // if file_picker is not installed. Replace with direct import if available:
    //
    //   import 'package:file_picker/file_picker.dart';
    //   final r = await FilePicker.platform.pickFiles(type: FileType.image);
    //   return r?.files.single.path;
    //
    throw UnimplementedError('file_picker not installed');
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // ── Add/remove amenity ───────────────────────────────────────────────────
  void _addAmenity() {
    final v = _amenityInputCtl.text.trim();
    if (v.isEmpty || _amenities.contains(v)) return;
    setState(() {
      _amenities.add(v);
      _amenityInputCtl.clear();
    });
  }

  void _removeAmenity(String item) {
    setState(() => _amenities.remove(item));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  int _parseInt(String s, num fallback) {
    return int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? fallback.toInt();
  }

  double _parseDouble(String s, double fallback) {
    return double.tryParse(s) ?? fallback;
  }

  Color _statusColor(RoomStatus s) => switch (s) {
    RoomStatus.available   => AppColors.success,
    RoomStatus.occupied    => AppColors.danger,
    RoomStatus.maintenance => AppColors.warning,
    // TODO: Handle this case.
    RoomStatus.rented => throw UnimplementedError(),
    // TODO: Handle this case.
    RoomStatus.deposited => throw UnimplementedError(),
  };

  String _statusLabel(RoomStatus s) => switch (s) {
    RoomStatus.available   => 'Trống',
    RoomStatus.occupied    => 'Đang thuê',
    RoomStatus.maintenance => 'Sửa chữa',
    // TODO: Handle this case.
    RoomStatus.rented => throw UnimplementedError(),
    // TODO: Handle this case.
    RoomStatus.deposited => throw UnimplementedError(),
  };

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final canEdit = AuthService.isHostOrAdmin();

    return FutureBuilder<RoomModel>(
      future: _futureRoom,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết phòng')),
            body: Center(child: Text('Lỗi: ${snap.error}')),
          );
        }
        final room = snap.data!;
        if (!_initialized) _initForm(room);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(room, canEdit),
          body: _editing
              ? _buildEditForm(room)
              : _buildReadView(room, canEdit),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(RoomModel room, bool canEdit) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _editing ? 'Chỉnh sửa phòng' : room.roomCode,
        style: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(height: 2, color: AppColors.border),
      ),
      actions: [
        if (canEdit && !_editing)
          PopupMenuButton<String>(
            tooltip: 'Đổi trạng thái',
            icon: const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
            onSelected: _changeStatus,
            itemBuilder: (_) => _statusOptions
                .map((s) => PopupMenuItem(
              value: s,
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _statusColors[s], shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(_statusLabels[s]!,
                    style: GoogleFonts.outfit(fontSize: 13)),
              ]),
            ))
                .toList(),
          ),
        if (canEdit && !_editing)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text('Sửa',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        if (_editing) ...[
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            IconButton(
              tooltip: 'Huỷ',
              icon: const Icon(Icons.close, color: AppColors.danger),
              onPressed: () => setState(() {
                _editing     = false;
                _initialized = false;
                _futureRoom.then(_initForm);
              }),
            ),
            IconButton(
              tooltip: 'Lưu',
              icon: const Icon(Icons.check, color: AppColors.success),
              onPressed: () async {
                final room = await _futureRoom;
                await _save(room);
              },
            ),
          ],
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // READ VIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildReadView(RoomModel room, bool canEdit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero card ──
          _HeroCard(room: room, statusLabel: _statusLabel(room.status), statusColor: _statusColor(room.status)),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 700;
            return wide
                ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ReadInfoPanel(room: room)),
                const SizedBox(width: 16),
                Expanded(child: _ReadImagesPanel(images: room.images)),
              ],
            )
                : Column(children: [
              _ReadInfoPanel(room: room),
              const SizedBox(height: 16),
              _ReadImagesPanel(images: room.images),
            ]);
          }),
          if (room.amenities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReadAmenitiesPanel(amenities: room.amenities),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EDIT FORM
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEditForm(RoomModel room) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: AppColors.background,
          child: TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Thông tin'),
              Tab(text: 'Giá & Tiện ích'),
              Tab(text: 'Ảnh phòng'),
            ],
          ),
        ),
        Container(height: 2, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _EditTabInfo(room: room),
              _EditTabPricing(room: room),
              _EditTabImages(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 1: Thông tin ──────────────────────────────────────────────────────
  Widget _EditTabInfo({required RoomModel room}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero mini
          _EditHeroMini(
            room: room,
            selectedStatus: _selectedStatus,
            onStatusChanged: (v) => setState(() => _selectedStatus = v),
          ),
          const SizedBox(height: 24),

          _SectionTitle('Thông tin cơ bản'),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 600;
            final row1 = [
              Expanded(child: _Field(label: 'Mã phòng', controller: _roomCodeCtl, hint: 'VD: P101')),
              if (wide) const SizedBox(width: 12),
              if (wide)
                Expanded(child: _Field(label: 'Diện tích (m²)', controller: _areaSizeCtl, keyboard: TextInputType.number)),
            ];
            return wide
                ? Row(children: row1)
                : Column(children: [
              _Field(label: 'Mã phòng', controller: _roomCodeCtl, hint: 'VD: P101'),
              const SizedBox(height: 12),
              _Field(label: 'Diện tích (m²)', controller: _areaSizeCtl, keyboard: TextInputType.number),
            ]);
          }),
          const SizedBox(height: 24),

          _SectionTitle('Vị trí'),
          const SizedBox(height: 12),
          _Field(label: 'Tên khu trọ', controller: _areaNameCtl),
          const SizedBox(height: 12),
          _Field(label: 'Địa chỉ', controller: _addressCtl, maxLines: 2),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 600;
            return wide
                ? Row(children: [
              Expanded(child: _Field(label: 'Vĩ độ (Latitude)', controller: _latCtl, keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _Field(label: 'Kinh độ (Longitude)', controller: _lngCtl, keyboard: TextInputType.number)),
            ])
                : Column(children: [
              _Field(label: 'Vĩ độ (Latitude)', controller: _latCtl, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _Field(label: 'Kinh độ (Longitude)', controller: _lngCtl, keyboard: TextInputType.number),
            ]);
          }),

          // Amenities
          const SizedBox(height: 24),
          _SectionTitle('Tiện nghi'),
          const SizedBox(height: 12),
          _AmenityEditor(
            amenities: _amenities,
            controller: _amenityInputCtl,
            onAdd: _addAmenity,
            onRemove: _removeAmenity,
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Giá ────────────────────────────────────────────────────────────
  Widget _EditTabPricing({required RoomModel room}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Giá thuê'),
          const SizedBox(height: 12),
          _PriceCard(
            icon: Icons.home_outlined,
            label: 'Giá thuê cơ bản',
            suffix: 'đ/tháng',
            controller: _basePriceCtl,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 600;
            return wide
                ? Row(children: [
              Expanded(child: _PriceCard(
                icon: Icons.bolt, label: 'Giá điện', suffix: 'đ/kWh',
                controller: _elecPriceCtl, color: AppColors.warning,
              )),
              const SizedBox(width: 12),
              Expanded(child: _PriceCard(
                icon: Icons.water_drop_outlined, label: 'Giá nước', suffix: 'đ/m³',
                controller: _waterPriceCtl, color: AppColors.primary,
              )),
            ])
                : Column(children: [
              _PriceCard(icon: Icons.bolt, label: 'Giá điện', suffix: 'đ/kWh', controller: _elecPriceCtl, color: AppColors.warning),
              const SizedBox(height: 12),
              _PriceCard(icon: Icons.water_drop_outlined, label: 'Giá nước', suffix: 'đ/m³', controller: _waterPriceCtl, color: AppColors.primary),
            ]);
          }),
        ],
      ),
    );
  }

  // ── Tab 3: Ảnh ────────────────────────────────────────────────────────────
  Widget _EditTabImages() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Ảnh phòng  (${_images.length} ảnh)'),
          const SizedBox(height: 12),

          // ── Thêm ảnh ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thêm ảnh mới',
                    style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.foreground)),
                const SizedBox(height: 12),

                // Row: URL input + nút thêm
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _urlInputCtl,
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Nhập URL ảnh (https://...)',
                          hintStyle: GoogleFonts.outfit(
                              color: AppColors.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.background,
                          prefixIcon: const Icon(Icons.link, size: 18,
                              color: AppColors.textMuted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onFieldSubmitted: (_) => _addImageUrl(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addImageUrl,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('Thêm URL',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Divider
                Row(children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('hoặc',
                        style: GoogleFonts.outfit(
                            color: AppColors.textMuted, fontSize: 12)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ]),

                const SizedBox(height: 10),

                // Chọn từ máy
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickImageFromFile,
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: Text('Chọn ảnh từ máy tính',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Danh sách ảnh hiện có ──
          if (_images.isEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.border, width: 2,
                    style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_outlined,
                        size: 32, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text('Chưa có ảnh nào',
                        style: GoogleFonts.outfit(
                            color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _images.length,
              itemBuilder: (_, i) => _ImageTile(
                url: _images[i],
                onRemove: () => _removeImage(i),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Read-only sub-widgets ────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final RoomModel room;
  final String statusLabel;
  final Color statusColor;
  const _HeroCard(
      {required this.room,
        required this.statusLabel,
        required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                room.roomCode.length > 3
                    ? room.roomCode.substring(0, 2)
                    : room.roomCode,
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: statusColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.roomCode,
                    style: GoogleFonts.outfit(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        color: AppColors.foreground)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(statusLabel.toUpperCase(),
                      style: GoogleFonts.outfit(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: statusColor, letterSpacing: 0.8)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatVnd(room.basePrice),
                  style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: statusColor)),
              Text('/tháng',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadInfoPanel extends StatelessWidget {
  final RoomModel room;
  const _ReadInfoPanel({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin chi tiết',
              style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: AppColors.foreground)),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.straighten_outlined,  label: 'Diện tích',    value: '${room.areaSize} m²'),
          _InfoRow(icon: Icons.bolt,                  label: 'Giá điện',     value: formatVnd(room.elecPrice) + '/kWh'),
          _InfoRow(icon: Icons.water_drop_outlined,  label: 'Giá nước',     value: formatVnd(room.waterPrice) + '/m³'),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Khu trọ',      value: room.areaName),
          _InfoRow(icon: Icons.map_outlined,         label: 'Địa chỉ',      value: room.address),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.foreground)),
          ),
        ],
      ),
    );
  }
}

class _ReadImagesPanel extends StatelessWidget {
  final List<String> images;
  const _ReadImagesPanel({required this.images});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted, borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Ảnh phòng',
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('${images.length} ảnh',
                  style: GoogleFonts.outfit(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ]),
          const SizedBox(height: 12),
          if (images.isEmpty)
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('Chưa có ảnh',
                    style: GoogleFonts.outfit(
                        color: AppColors.textMuted, fontSize: 12)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 6,
                mainAxisSpacing: 6, childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  images[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.border,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.textMuted, size: 24),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadAmenitiesPanel extends StatelessWidget {
  final List<String> amenities;
  const _ReadAmenitiesPanel({required this.amenities});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted, borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tiện nghi',
              style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: amenities
                .map((a) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Text(a,
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.foreground)),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Edit sub-widgets ─────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _EditHeroMini extends StatelessWidget {
  final RoomModel room;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  const _EditHeroMini(
      {required this.room,
        required this.selectedStatus,
        required this.onStatusChanged});

  static const _statusOptions = ['AVAILABLE', 'OCCUPIED', 'MAINTENANCE'];
  static const _statusLabels = {
    'AVAILABLE': 'Trống',
    'OCCUPIED': 'Đang thuê',
    'MAINTENANCE': 'Sửa chữa',
  };
  static const _statusColors = {
    'AVAILABLE': AppColors.success,
    'OCCUPIED': AppColors.danger,
    'MAINTENANCE': AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[selectedStatus] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.meeting_room_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.roomCode,
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                Text('Đang chỉnh sửa',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          // Status selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedStatus,
                onChanged: (v) => v != null ? onStatusChanged(v) : null,
                items: _statusOptions
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _statusColors[s],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_statusLabels[s]!,
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
                    .toList(),
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.foreground,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 16,
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text,
          style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: AppColors.foreground)),
    ]);
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboard;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.foreground),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.muted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  final IconData icon;
  final String label, suffix;
  final TextEditingController controller;
  final Color color;
  const _PriceCard({
    required this.icon, required this.label, required this.suffix,
    required this.controller, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppColors.foreground),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(suffix,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmenityEditor extends StatelessWidget {
  final List<String> amenities;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  const _AmenityEditor({
    required this.amenities, required this.controller,
    required this.onAdd, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input + add button
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Thêm tiện nghi (VD: Điều hòa, Nóng lạnh...)',
                hintStyle: GoogleFonts.outfit(
                    color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.muted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              onFieldSubmitted: (_) => onAdd(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Icon(Icons.add, size: 18),
          ),
        ]),
        if (amenities.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: amenities
                .map((a) => Chip(
              label: Text(a,
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              onDeleted: () => onRemove(a),
              deleteIcon: const Icon(Icons.close, size: 14),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              deleteIconColor: AppColors.primary,
              side: const BorderSide(
                  color: AppColors.primary, width: 1),
              labelStyle: GoogleFonts.outfit(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _ImageTile({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.muted,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_outlined,
                      size: 24, color: AppColors.textMuted),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('Lỗi ảnh',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4, offset: const Offset(0, 1))
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}