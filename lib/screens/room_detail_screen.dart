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

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<RoomModel> _futureRoom;

  // Edit controllers
  final _basePriceCtl = TextEditingController();
  final _elecPriceCtl = TextEditingController();
  final _waterPriceCtl = TextEditingController();
  final _areaSizeCtl = TextEditingController();
  final _areaNameCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _latitudeCtl = TextEditingController();
  final _longitudeCtl = TextEditingController();
  final _imagesCtl = TextEditingController(); // comma separated
  final _amenitiesCtl = TextEditingController(); // comma separated

  bool _editing = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _futureRoom = ApiClient.fetchRoomDetail(widget.roomId);
  }

  @override
  void dispose() {
    _basePriceCtl.dispose();
    _elecPriceCtl.dispose();
    _waterPriceCtl.dispose();
    _areaSizeCtl.dispose();
    _areaNameCtl.dispose();
    _addressCtl.dispose();
    _latitudeCtl.dispose();
    _longitudeCtl.dispose();
    _imagesCtl.dispose();
    _amenitiesCtl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _controllersInitialized = false;
      _futureRoom = ApiClient.fetchRoomDetail(widget.roomId);
    });
  }

  Future<void> _changeStatus(String newStatus) async {
    try {
      await ApiClient.updateRoomStatus(widget.roomId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật trạng thái: $newStatus')));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')));
    }
  }

  void _enterEdit(RoomModel room) {
    // initialize controllers with current room values
    _basePriceCtl.text = room.basePrice.toString();
    _elecPriceCtl.text = room.elecPrice.toString();
    _waterPriceCtl.text = room.waterPrice.toString();
    _areaSizeCtl.text = room.areaSize.toString();
    _areaNameCtl.text = room.areaName;
    _addressCtl.text = room.address;
    _latitudeCtl.text = room.latitude.toString();
    _longitudeCtl.text = room.longitude.toString();
    _imagesCtl.text = room.images.join(', ');
    _amenitiesCtl.text = room.amenities.join(', ');
    _controllersInitialized = true;
    setState(() => _editing = true);
  }

  Future<void> _saveChanges(RoomModel room) async {
    // build payload merging unchanged fields
    final images = _imagesCtl.text.trim().isEmpty
        ? <String>[]
        : _imagesCtl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final amenities = _amenitiesCtl.text.trim().isEmpty
        ? <String>[]
        : _amenitiesCtl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    int parseInt(String s, int fallback) {
      try {
        return int.parse(s.replaceAll(RegExp('[^0-9-]'), ''));
      } catch (_) {
        return fallback;
      }
    }
    double parseDouble(String s, double fallback) {
      try {
        return double.parse(s);
      } catch (_) {
        return fallback;
      }
    }

    final payload = {
      'roomId': room.roomId,
      'roomCode': room.roomCode,
      'basePrice': parseInt(_basePriceCtl.text, room.basePrice),
      'elecPrice': parseInt(_elecPriceCtl.text, room.elecPrice),
      'waterPrice': parseInt(_waterPriceCtl.text, room.waterPrice),
      'status': room.status.toString().split('.').last.toUpperCase(),
      'areaSize': parseInt(_areaSizeCtl.text, room.areaSize),
      'images': images,
      'amenities': amenities,
      'areaName': _areaNameCtl.text.trim().isEmpty ? room.areaName : _areaNameCtl.text.trim(),
      'address': _addressCtl.text.trim().isEmpty ? room.address : _addressCtl.text.trim(),
      'latitude': parseDouble(_latitudeCtl.text, room.latitude),
      'longitude': parseDouble(_longitudeCtl.text, room.longitude),
    };

    try {
      final updated = await ApiClient.updateRoom(widget.roomId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thay đổi thành công')));
      setState(() {
        _editing = false;
        _futureRoom = Future.value(updated);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthService.isHostOrAdmin();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết phòng'),
        actions: [
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (s) => _changeStatus(s),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'AVAILABLE', child: Text('Đánh dấu: Trống')),
                const PopupMenuItem(value: 'OCCUPIED', child: Text('Đánh dấu: Đang thuê')),
                const PopupMenuItem(value: 'MAINTENANCE', child: Text('Đánh dấu: Sửa chữa')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          if (canEdit)
            IconButton(
              icon: Icon(_editing ? Icons.save : Icons.edit),
              onPressed: () async {
                final snapshotRoom = await _futureRoom;
                if (_editing) {
                  // save
                  await _saveChanges(snapshotRoom);
                } else {
                  _enterEdit(snapshotRoom);
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<RoomModel>(
        future: _futureRoom,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi khi tải chi tiết: ${snapshot.error}'));
          }
          final room = snapshot.data;
          if (room == null) {
            return const Center(child: Text('Không có dữ liệu phòng'));
          }

          // If editing mode -> show form
          if (_editing && _controllersInitialized) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.roomCode, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  LabeledInput(label: 'Mã phòng', initialValue: room.roomCode, readOnly: true),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Khu vực', controller: _areaNameCtl, readOnly: false),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Địa chỉ', controller: _addressCtl),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Diện tích (m²)', controller: _areaSizeCtl),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Giá cơ bản', controller: _basePriceCtl),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Giá điện', controller: _elecPriceCtl),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Giá nước', controller: _waterPriceCtl),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Latitude', controller: _latitudeCtl),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Longitude', controller: _longitudeCtl),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Images (comma separated)', controller: _imagesCtl),
                  const SizedBox(height: 8),
                  LabeledInput(label: 'Amenities (comma separated)', controller: _amenitiesCtl),
                ],
              ),
            );
          }

          // Read-only view
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.roomCode, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(room.areaName, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                Text(formatVnd(room.basePrice), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 12),
                Text('Diện tích: ${room.areaSize} m²', style: GoogleFonts.outfit(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Địa chỉ: ${room.address}', style: GoogleFonts.outfit(fontSize: 14)),
                const SizedBox(height: 12),
                const SectionHeader(title: 'Tiện nghi'),
                const SizedBox(height: 8),
                if (room.amenities.isEmpty)
                  Text('Không có tiện nghi rõ ràng', style: GoogleFonts.outfit(color: AppColors.textMuted)),
                ...room.amenities.map((a) => ListTile(title: Text(a))),
              ],
            ),
          );
        },
      ),
    );
  }
}
