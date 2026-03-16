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

class _RoomDetailScreenState extends State<RoomDetailScreen> with SingleTickerProviderStateMixin {
  late Future<RoomModel> _futureRoom;
  late TabController _tabCtrl;
  bool _isEditing = false;

  // Edit controllers
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
    _futureRoom = ApiClient.fetchRoomDetail(widget.roomId);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _basePriceCtl.dispose(); _elecPriceCtl.dispose(); _waterPriceCtl.dispose();
    _areaSizeCtl.dispose(); _areaNameCtl.dispose(); _addressCtl.dispose(); _amenitiesCtl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _futureRoom = ApiClient.fetchRoomDetail(widget.roomId));
  }

  void _enterEdit(RoomModel room) {
    _basePriceCtl.text  = room.basePrice.toString();
    _elecPriceCtl.text  = room.elecPrice.toString();
    _waterPriceCtl.text = room.waterPrice.toString();
    _areaSizeCtl.text   = room.areaSize.toString();
    _areaNameCtl.text   = room.areaName;
    _addressCtl.text    = room.address;
    _amenitiesCtl.text  = room.amenities.join(', ');
    setState(() => _isEditing = true);
  }

  Future<void> _saveEdit(RoomModel room) async {
    int safeInt(String s, int fallback) {
      return int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? fallback;
    }
    final payload = {
      'roomId': room.roomId,
      'roomCode': room.roomCode,
      'basePrice': safeInt(_basePriceCtl.text, room.basePrice),
      'elecPrice': safeInt(_elecPriceCtl.text, room.elecPrice),
      'waterPrice': safeInt(_waterPriceCtl.text, room.waterPrice),
      'status': room.status.toString().split('.').last.toUpperCase(),
      'areaSize': safeInt(_areaSizeCtl.text, room.areaSize),
      'areaName': _areaNameCtl.text.trim().isEmpty ? room.areaName : _areaNameCtl.text.trim(),
      'address': _addressCtl.text.trim().isEmpty ? room.address : _addressCtl.text.trim(),
      'amenities': _amenitiesCtl.text.isEmpty ? [] : _amenitiesCtl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'images': room.images,
      'latitude': room.latitude,
      'longitude': room.longitude,
    };
    try {
      final updated = await ApiClient.updateRoom(widget.roomId, payload);
      if (!mounted) return;
      setState(() { _isEditing = false; _futureRoom = Future.value(updated); });
      _showSnack('Lưu thay đổi thành công', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi khi lưu: $e', AppColors.danger);
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    try {
      await ApiClient.updateRoomStatus(widget.roomId, newStatus);
      if (!mounted) return;
      _showSnack('Đã cập nhật trạng thái', AppColors.success);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi: $e', AppColors.danger);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  void _showStatusSheet(RoomModel room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusSheet(current: room.status, onSelect: _changeStatus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthService.isHostOrAdmin();

    return FutureBuilder<RoomModel>(
      future: _futureRoom,
      builder: (context, snapshot) {
        final room = snapshot.data;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.foreground),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              room?.roomCode ?? 'Chi tiết phòng',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground),
            ),
            actions: [
              if (canEdit && room != null) ...[
                // Đổi trạng thái
                IconButton(
                  tooltip: 'Đổi trạng thái',
                  icon: const Icon(Icons.tune_rounded, color: AppColors.foreground),
                  onPressed: () => _showStatusSheet(room),
                ),
                // Edit / Save
                IconButton(
                  tooltip: _isEditing ? 'Lưu thay đổi' : 'Chỉnh sửa',
                  icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, color: _isEditing ? AppColors.success : AppColors.foreground),
                  onPressed: () {
                    if (_isEditing) _saveEdit(room);
                    else _enterEdit(room);
                  },
                ),
                if (_isEditing)
                  IconButton(
                    tooltip: 'Huỷ',
                    icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                    onPressed: () => setState(() => _isEditing = false),
                  ),
              ],
            ],
            bottom: room != null ? TabBar(
              controller: _tabCtrl,
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
            ) : null,
          ),

          body: Builder(builder: (context) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${snapshot.error}', style: GoogleFonts.outfit(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Thử lại')),
                ]),
              );
            }
            if (room == null) return const Center(child: Text('Không có dữ liệu'));

            return TabBarView(
              controller: _tabCtrl,
              children: [
                _InfoTab(room: room, isEditing: _isEditing, areaNameCtl: _areaNameCtl, addressCtl: _addressCtl, areaSizeCtl: _areaSizeCtl),
                _PriceTab(room: room, isEditing: _isEditing, basePriceCtl: _basePriceCtl, elecPriceCtl: _elecPriceCtl, waterPriceCtl: _waterPriceCtl, amenitiesCtl: _amenitiesCtl),
                _ContractTab(room: room),
              ],
            );
          }),
        );
      },
    );
  }
}

// ─── Status Sheet ─────────────────────────────────────────────────────────────

class _StatusSheet extends StatelessWidget {
  final RoomStatus current;
  final ValueChanged<String> onSelect;
  const _StatusSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      _StatusOption(status: 'AVAILABLE',    label: 'Phòng trống',  icon: Icons.door_front_door_outlined, color: AppColors.success),
      _StatusOption(status: 'OCCUPIED',     label: 'Đang cho thuê', icon: Icons.people_rounded,           color: AppColors.danger),
      _StatusOption(status: 'MAINTENANCE',  label: 'Đang sửa chữa', icon: Icons.build_rounded,            color: AppColors.warning),
    ];

    return Container(
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Cập nhật trạng thái phòng', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground)),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final isSelected = _matchStatus(current, opt.status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: isSelected ? opt.color.withOpacity(0.08) : AppColors.muted,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () { Navigator.pop(context); onSelect(opt.status); },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: opt.color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Icon(opt.icon, color: opt.color, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(opt.label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.foreground))),
                        if (isSelected) Icon(Icons.check_circle_rounded, color: opt.color, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _matchStatus(RoomStatus s, String str) {
    return switch (s) {
      RoomStatus.available => str == 'AVAILABLE',
      RoomStatus.occupied => str == 'OCCUPIED',
      RoomStatus.maintenance => str == 'MAINTENANCE',
    };
  }
}

class _StatusOption {
  final String status, label;
  final IconData icon;
  final Color color;
  const _StatusOption({required this.status, required this.label, required this.icon, required this.color});
}

// ─── Tab 1: Thông tin ─────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final RoomModel room;
  final bool isEditing;
  final TextEditingController areaNameCtl, addressCtl, areaSizeCtl;

  const _InfoTab({
    required this.room, required this.isEditing,
    required this.areaNameCtl, required this.addressCtl, required this.areaSizeCtl,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (room.status) {
      RoomStatus.available => AppColors.success,
      RoomStatus.occupied => AppColors.danger,
      RoomStatus.maintenance => AppColors.warning,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero card ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(room.roomCode.length > 3 ? room.roomCode.substring(0, 3) : room.roomCode,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: statusColor))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(room.roomCode, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.foreground, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    StatusBadge.room(room.status),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  Text(formatVnd(room.basePrice), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: statusColor)),
                  Text('/tháng', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Info fields ────────────────────────────────────────────────────
          _SectionTitle('Thông tin cơ bản'),
          const SizedBox(height: 12),

          _DetailRow(icon: Icons.home_work_outlined, label: 'Mã phòng', value: room.roomCode),
          if (isEditing) ...[
            const SizedBox(height: 12),
            _EditField(label: 'Khu vực / Tên tòa', controller: areaNameCtl),
            const SizedBox(height: 12),
            _EditField(label: 'Địa chỉ', controller: addressCtl),
            const SizedBox(height: 12),
            _EditField(label: 'Diện tích (m²)', controller: areaSizeCtl, keyboardType: TextInputType.number),
          ] else ...[
            _DetailRow(icon: Icons.location_city_outlined, label: 'Khu vực', value: room.areaName.isNotEmpty ? room.areaName : '—'),
            _DetailRow(icon: Icons.location_on_outlined, label: 'Địa chỉ', value: room.address.isNotEmpty ? room.address : '—'),
            _DetailRow(icon: Icons.straighten_rounded, label: 'Diện tích', value: '${room.areaSize} m²'),
          ],

          if (room.latitude != 0 || room.longitude != 0) ...[
            _DetailRow(icon: Icons.map_outlined, label: 'Tọa độ', value: '${room.latitude.toStringAsFixed(4)}, ${room.longitude.toStringAsFixed(4)}'),
          ],
        ],
      ),
    );
  }
}

// ─── Tab 2: Giá & Tiện ích ────────────────────────────────────────────────────

class _PriceTab extends StatelessWidget {
  final RoomModel room;
  final bool isEditing;
  final TextEditingController basePriceCtl, elecPriceCtl, waterPriceCtl, amenitiesCtl;

  const _PriceTab({
    required this.room, required this.isEditing,
    required this.basePriceCtl, required this.elecPriceCtl,
    required this.waterPriceCtl, required this.amenitiesCtl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Giá cả'),
          const SizedBox(height: 12),

          if (isEditing) ...[
            _EditField(label: 'Giá thuê cơ bản (đ/tháng)', controller: basePriceCtl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _EditField(label: 'Giá điện (đ/kWh)', controller: elecPriceCtl, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _EditField(label: 'Giá nước (đ/m³)', controller: waterPriceCtl, keyboardType: TextInputType.number)),
            ]),
          ] else ...[
            // Price cards
            Row(children: [
              Expanded(child: _PriceCard(icon: Icons.home_rounded, label: 'Tiền phòng', value: formatVnd(room.basePrice), sub: 'mỗi tháng', color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _PriceCard(icon: Icons.bolt_rounded, label: 'Tiền điện', value: '${formatVnd(room.elecPrice)}/kWh', sub: 'mỗi kWh', color: AppColors.warning)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _PriceCard(icon: Icons.water_drop_outlined, label: 'Tiền nước', value: '${formatVnd(room.waterPrice)}/m³', sub: 'mỗi m³', color: AppColors.primary)),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ]),
          ],

          const SizedBox(height: 24),
          _SectionTitle('Tiện ích'),
          const SizedBox(height: 12),

          if (isEditing) ...[
            _EditField(label: 'Tiện ích (phân cách bằng dấu phẩy)', controller: amenitiesCtl, hint: 'WiFi, Điều hoà, Bếp từ...'),
          ] else if (room.amenities.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 10),
                Text('Chưa có thông tin tiện ích', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
              ]),
            ),
          ] else ...[
            Wrap(
              spacing: 8, runSpacing: 8,
              children: room.amenities.map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14),
                  const SizedBox(width: 5),
                  Text(a, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tab 3: Hợp đồng ─────────────────────────────────────────────────────────

class _ContractTab extends StatelessWidget {
  final RoomModel room;
  const _ContractTab({required this.room});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(36)),
              child: const Icon(Icons.description_outlined, color: AppColors.textMuted, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              room.status == RoomStatus.occupied ? 'Hợp đồng đang hiệu lực' : 'Chưa có hợp đồng',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground),
            ),
            const SizedBox(height: 8),
            Text(
              room.status == RoomStatus.occupied ? 'Xem chi tiết hợp đồng và thông tin người thuê' : 'Phòng hiện chưa có người thuê',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            if (room.status == RoomStatus.available)
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Tạo hợp đồng mới')),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets for Detail Screen ────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: 0.2)),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hint;
  const _EditField({required this.label, required this.controller, this.keyboardType, this.hint});

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
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  const _PriceCard({required this.icon, required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.foreground)),
          ),
        ],
      ),
    );
  }
}