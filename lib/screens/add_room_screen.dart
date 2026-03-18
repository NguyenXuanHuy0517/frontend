// lib/screens/add_room_screen.dart
// Màn hình thêm phòng mới - gọi POST /api/business/rooms

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';

class AddRoomScreen extends StatefulWidget {
  /// areaId mặc định nếu biết trước (ví dụ mở từ màn hình khu trọ)
  final int? defaultAreaId;

  const AddRoomScreen({super.key, this.defaultAreaId});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Controllers
  final _roomCodeCtl = TextEditingController();
  final _areaIdCtl = TextEditingController();
  final _basePriceCtl = TextEditingController();
  final _elecPriceCtl = TextEditingController(text: '3500');
  final _waterPriceCtl = TextEditingController(text: '15000');
  final _areaSizeCtl = TextEditingController();
  final _imagesCtl = TextEditingController();
  final _amenitiesCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.defaultAreaId != null) {
      _areaIdCtl.text = widget.defaultAreaId.toString();
    }
  }

  @override
  void dispose() {
    _roomCodeCtl.dispose();
    _areaIdCtl.dispose();
    _basePriceCtl.dispose();
    _elecPriceCtl.dispose();
    _waterPriceCtl.dispose();
    _areaSizeCtl.dispose();
    _imagesCtl.dispose();
    _amenitiesCtl.dispose();
    super.dispose();
  }

  int _parseInt(String s, int fallback) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? fallback;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final images = _imagesCtl.text.trim().isEmpty
        ? <String>[]
        : _imagesCtl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final amenities = _amenitiesCtl.text.trim().isEmpty
        ? <String>[]
        : _amenitiesCtl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final payload = {
      'areaId': _parseInt(_areaIdCtl.text, 0),
      'roomCode': _roomCodeCtl.text.trim().toUpperCase(),
      'basePrice': _parseInt(_basePriceCtl.text, 0),
      'elecPrice': _parseInt(_elecPriceCtl.text, 3500),
      'waterPrice': _parseInt(_waterPriceCtl.text, 15000),
      'areaSize': _parseInt(_areaSizeCtl.text, 0),
      'status': 'AVAILABLE',
      'images': images,
      'amenities': amenities,
    };

    try {
      final created = await ApiClient.createRoom(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm phòng ${created.roomCode} thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(created); // Trả về phòng mới để màn hình cha refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thêm phòng mới',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Lưu'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Thông tin khu trọ'),
              _Field(
                label: 'ID Khu trọ (areaId) *',
                controller: _areaIdCtl,
                keyboardType: TextInputType.number,
                hint: 'Ví dụ: 1',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Bắt buộc nhập ID khu trọ';
                  if (int.tryParse(v.trim()) == null) return 'ID phải là số nguyên';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _SectionTitle('Thông tin phòng'),
              _Field(
                label: 'Mã phòng *',
                controller: _roomCodeCtl,
                hint: 'Ví dụ: P101',
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập mã phòng' : null,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Diện tích (m²)',
                controller: _areaSizeCtl,
                keyboardType: TextInputType.number,
                hint: 'Ví dụ: 25',
              ),
              const SizedBox(height: 20),
              _SectionTitle('Giá cả'),
              _Field(
                label: 'Giá thuê cơ bản (VNĐ) *',
                controller: _basePriceCtl,
                keyboardType: TextInputType.number,
                hint: 'Ví dụ: 2000000',
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập giá thuê' : null,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Giá điện (VNĐ/kWh)',
                controller: _elecPriceCtl,
                keyboardType: TextInputType.number,
                hint: 'Mặc định: 3500',
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Giá nước (VNĐ/m³)',
                controller: _waterPriceCtl,
                keyboardType: TextInputType.number,
                hint: 'Mặc định: 15000',
              ),
              const SizedBox(height: 20),
              _SectionTitle('Tiện ích & Hình ảnh'),
              _Field(
                label: 'Tiện ích (cách nhau bởi dấu phẩy)',
                controller: _amenitiesCtl,
                hint: 'Ví dụ: WiFi, Điều hòa, Máy giặt',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'URLs Hình ảnh (cách nhau bởi dấu phẩy)',
                controller: _imagesCtl,
                hint: 'Ví dụ: https://img.com/a.jpg, https://img.com/b.jpg',
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.add_home),
                  label: Text(
                    _loading ? 'Đang lưu...' : 'Thêm phòng',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}