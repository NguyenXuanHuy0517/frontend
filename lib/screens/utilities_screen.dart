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
      child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cards = [
          _UtilityCard(
            type: _UtilType.electric,
            accentColor: AppColors.warning,
            bgColor: const Color(0xFFFFFBEB),
            icon: Icons.bolt,
            title: 'Nhập chỉ số điện',
            unit: 'kWh',
            price: 3500,
            priceLabel: 'đ/kWh',
          ),
          _UtilityCard(
            type: _UtilType.water,
            accentColor: AppColors.primary,
            bgColor: const Color(0xFFEFF6FF),
            icon: Icons.water_drop_outlined,
            title: 'Nhập chỉ số nước',
            unit: 'm³',
            price: 15000,
            priceLabel: 'đ/m³',
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
          );
        }
        return Column(
          children: [cards[0], const SizedBox(height: 16), cards[1]],
        );
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
  final int price;

  const _UtilityCard({
    required this.type,
    required this.accentColor,
    required this.bgColor,
    required this.icon,
    required this.title,
    required this.unit,
    required this.price,
    required this.priceLabel,
  });

  @override
  State<_UtilityCard> createState() => _UtilityCardState();
}

class _UtilityCardState extends State<_UtilityCard> {
  final _newIndexCtrl = TextEditingController();
  String? _selectedRoom;
  bool _saved = false;

  final _occupiedRooms = kRooms.where((r) => r.status == RoomStatus.occupied).toList();

  // Simulated old indices
  int get _fakeOldIndex => widget.type == _UtilType.electric ? 1240 : 85;

  int get _usage {
    final newVal = int.tryParse(_newIndexCtrl.text) ?? 0;
    return newVal > _fakeOldIndex ? newVal - _fakeOldIndex : 0;
  }

  int get _totalCost => _usage * widget.price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: widget.accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 20),

          // Room selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHỌN PHÒNG', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: _selectedRoom,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text('Chọn phòng...', style: GoogleFonts.outfit(color: AppColors.textMuted)),
                  items: _occupiedRooms.map((r) => DropdownMenuItem(
                    value: r.id,
                    child: Text('${r.id} – ${r.tenant}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() { _selectedRoom = v; _saved = false; }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Old / New index side-by-side
          Row(
            children: [
              Expanded(child: LabeledInput(
                label: 'Chỉ số cũ (${widget.unit})',
                initialValue: _selectedRoom != null ? _fakeOldIndex.toString() : '',
                readOnly: true,
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHỈ SỐ MỚI (${widget.unit.toUpperCase()})', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _newIndexCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() { _saved = false; }),
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(hintText: 'Nhập chỉ số...'),
                  ),
                ],
              )),
            ],
          ),
          const SizedBox(height: 16),

          // Price block
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ĐƠN GIÁ', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.8)),
                    Text(
                      '${formatVnd(widget.price).replaceAll('đ', '')}${widget.priceLabel}',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
                if (_usage > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('TIÊU THỤ', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.8)),
                      Text('$_usage ${widget.unit}  →  ${formatVnd(_totalCost)}',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                onPressed: _selectedRoom == null || _newIndexCtrl.text.isEmpty ? null : () {
                  setState(() => _saved = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã lưu chỉ số ${widget.title.contains('điện') ? 'điện' : 'nước'} phòng $_selectedRoom!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: Icon(_saved ? Icons.check : Icons.save_outlined, size: 16),
                label: Text(_saved ? 'Đã lưu!' : 'Lưu chỉ số & tính tiền'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saved ? AppColors.success : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
