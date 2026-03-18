// lib/screens/utilities_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(builder: (_, c) {
        const electric = _UtilityCard(
          type: _UtilType.electric,
          accentColor: AppColors.warning,
          bgColor: Color(0xFFFFFBEB),
          icon: Icons.bolt,
          title: 'Nhập chỉ số điện',
          unit: 'kWh',
          price: 3500,
          priceLabel: 'đ/kWh',
          fakeOldIndex: 1240,
        );
        const water = _UtilityCard(
          type: _UtilType.water,
          accentColor: AppColors.primary,
          bgColor: Color(0xFFEFF6FF),
          icon: Icons.water_drop_outlined,
          title: 'Nhập chỉ số nước',
          unit: 'm³',
          price: 15000,
          priceLabel: 'đ/m³',
          fakeOldIndex: 85,
        );

        if (c.maxWidth > 700) {
          return const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: RepaintBoundary(child: electric)),
            SizedBox(width: 16),
            Expanded(child: RepaintBoundary(child: water)),
          ]);
        }
        return const Column(children: [
          RepaintBoundary(child: electric),
          SizedBox(height: 16),
          RepaintBoundary(child: water),
        ]);
      }),
    );
  }
}

enum _UtilType { electric, water }

class _UtilityCard extends StatefulWidget {
  final _UtilType type;
  final Color accentColor, bgColor;
  final IconData icon;
  final String title, unit, priceLabel;
  final int price, fakeOldIndex;

  const _UtilityCard({
    required this.type, required this.accentColor, required this.bgColor,
    required this.icon, required this.title, required this.unit,
    required this.price, required this.priceLabel, required this.fakeOldIndex,
  });

  @override
  State<_UtilityCard> createState() => _UtilityCardState();
}

class _UtilityCardState extends State<_UtilityCard> {
  final _newIndexCtrl = TextEditingController();

  // ValueNotifier thay setState — chỉ rebuild phần phụ thuộc
  final _selectedRoomNotifier = ValueNotifier<String?>(null);
  final _savedNotifier        = ValueNotifier<bool>(false);
  final _usageNotifier        = ValueNotifier<int>(0);

  // Phòng đang được sử dụng (rented + deposited)
  static final _occupiedRooms = kRooms
      .where((r) => r.status == RoomStatus.rented || r.status == RoomStatus.deposited)
      .toList();

  @override
  void initState() {
    super.initState();
    _newIndexCtrl.addListener(_onIndexChanged);
  }

  void _onIndexChanged() {
    final newVal = int.tryParse(_newIndexCtrl.text) ?? 0;
    final usage  = newVal > widget.fakeOldIndex ? newVal - widget.fakeOldIndex : 0;
    if (_usageNotifier.value != usage) _usageNotifier.value = usage;
    if (_savedNotifier.value) _savedNotifier.value = false;
  }

  @override
  void dispose() {
    _newIndexCtrl.removeListener(_onIndexChanged);
    _newIndexCtrl.dispose();
    _selectedRoomNotifier.dispose();
    _savedNotifier.dispose();
    _usageNotifier.dispose();
    super.dispose();
  }

  void _save() {
    _savedNotifier.value = true;
    final room = _selectedRoomNotifier.value;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Đã lưu chỉ số ${widget.title.contains('điện') ? 'điện' : 'nước'} phòng $room!'),
      backgroundColor: AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: widget.accentColor, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header — không rebuild
        _UtilityHeader(icon: widget.icon, title: widget.title, accentColor: widget.accentColor),
        const SizedBox(height: 20),

        // Room selector — rebuild khi selected room thay đổi
        ValueListenableBuilder<String?>(
          valueListenable: _selectedRoomNotifier,
          builder: (_, selected, __) => _RoomSelector(
            selected: selected,
            rooms: _occupiedRooms,
            onChanged: (v) {
              _selectedRoomNotifier.value = v;
              _savedNotifier.value = false;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Index inputs
        Row(children: [
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: _selectedRoomNotifier,
              builder: (_, selected, __) => LabeledInput(
                label: 'Chỉ số cũ (${widget.unit})',
                initialValue: selected != null ? widget.fakeOldIndex.toString() : '',
                readOnly: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _NewIndexField(unit: widget.unit, ctrl: _newIndexCtrl)),
        ]),
        const SizedBox(height: 16),

        // Price block — rebuild khi usage thay đổi
        ValueListenableBuilder<int>(
          valueListenable: _usageNotifier,
          builder: (_, usage, __) => _PriceBlock(
            accentColor: widget.accentColor,
            price: widget.price,
            priceLabel: widget.priceLabel,
            unit: widget.unit,
            usage: usage,
            totalCost: usage * widget.price,
          ),
        ),
        const SizedBox(height: 16),

        // Save button — rebuild khi saved/selected/index thay đổi
        ValueListenableBuilder<bool>(
          valueListenable: _savedNotifier,
          builder: (_, saved, __) => ValueListenableBuilder<String?>(
            valueListenable: _selectedRoomNotifier,
            builder: (_, selected, __) => _SaveButton(
              saved: saved,
              enabled: selected != null && _newIndexCtrl.text.isNotEmpty,
              accentColor: widget.accentColor,
              onSave: _save,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Sub-widgets — tách nhỏ để tái dùng và const hóa ─────────────────────────

class _UtilityHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;

  const _UtilityHeader({required this.icon, required this.title, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 12),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
    ]);
  }
}

class _RoomSelector extends StatelessWidget {
  final String? selected;
  final List<RoomModel> rooms;
  final ValueChanged<String?> onChanged;

  const _RoomSelector({required this.selected, required this.rooms, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Text('CHỌN PHÒNG',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          underline: const SizedBox(),
          hint: const Text('Chọn phòng...', style: TextStyle(color: AppColors.textMuted)),
          items: rooms.map((r) => DropdownMenuItem(
            value: r.id,
            child: Text(r.tenant != null ? '${r.id} – ${r.tenant}' : r.id,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    ]);
  }
}

class _NewIndexField extends StatelessWidget {
  final String unit;
  final TextEditingController ctrl;

  const _NewIndexField({required this.unit, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('CHỈ SỐ MỚI (${unit.toUpperCase()})',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(hintText: 'Nhập chỉ số...'),
      ),
    ]);
  }
}

class _PriceBlock extends StatelessWidget {
  final Color accentColor;
  final int price, usage, totalCost;
  final String priceLabel, unit;

  const _PriceBlock({
    required this.accentColor, required this.price, required this.priceLabel,
    required this.unit, required this.usage, required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ĐƠN GIÁ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.8)),
          Text('${formatVnd(price).replaceAll('đ', '')}$priceLabel',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        if (usage > 0)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('TIÊU THỤ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.8)),
            Text('$usage $unit  →  ${formatVnd(totalCost)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
      ]),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saved, enabled;
  final Color accentColor;
  final VoidCallback onSave;

  const _SaveButton({required this.saved, required this.enabled, required this.accentColor, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onSave : null,
        icon: Icon(saved ? Icons.check : Icons.save_outlined, size: 16),
        label: Text(saved ? 'Đã lưu!' : 'Lưu chỉ số & tính tiền'),
        style: ElevatedButton.styleFrom(
          backgroundColor: saved ? AppColors.success : accentColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}