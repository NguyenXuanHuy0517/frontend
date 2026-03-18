// lib/screens/invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar — const, không rebuild
        const _InvoicesToolbar(),
        Expanded(
          child: LayoutBuilder(builder: (_, c) {
            if (c.maxWidth > 700) {
              return RepaintBoundary(child: _InvoiceTable(invoices: kInvoices));
            }
            return RepaintBoundary(child: _InvoiceCards(invoices: kInvoices));
          }),
        ),
      ],
    );
  }
}

class _InvoicesToolbar extends StatelessWidget {
  const _InvoicesToolbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Row(
        children: [
          AppButton(
            label: 'Lọc', icon: Icons.filter_list,
            bg: AppColors.muted, fg: AppColors.foreground,
            onTap: () {},
          ),
          const Spacer(),
          const AppButton(label: 'Tạo hóa đơn', icon: Icons.add),
        ],
      ),
    );
  }
}

// ─── Wide: Data Table ─────────────────────────────────────────────────────────

class _InvoiceTable extends StatelessWidget {
  final List<InvoiceModel> invoices;

  const _InvoiceTable({required this.invoices});

  static const _headers = ['MÃ HD', 'PHÒNG', 'KHÁCH THUÊ', 'SỐ TIỀN', 'HẠN NỘP', 'TRẠNG THÁI', ''];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(80),
            1: FixedColumnWidth(70),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1.5),
            4: FixedColumnWidth(100),
            5: FixedColumnWidth(150),
            6: FixedColumnWidth(50),
          },
          children: [
            // Header row — const
            TableRow(
              decoration: const BoxDecoration(color: AppColors.muted),
              children: _headers.map((h) => TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(h, style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary, letterSpacing: 0.8,
                  )),
                ),
              )).toList(),
            ),
            // Data rows — build từng row độc lập
            ...List.generate(invoices.length, (i) => _buildRow(invoices[i])),
          ],
        ),
      ),
    );
  }

  TableRow _buildRow(InvoiceModel inv) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.muted, width: 2)),
      ),
      children: [
        _cell(Text(inv.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
        _cell(Text(inv.room, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.foreground))),
        _cell(Text(inv.tenant, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        _cell(Text(formatVnd(inv.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.foreground))),
        _cell(Text(inv.due, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
        _cell(StatusBadge.invoice(inv.status)),
        _cell(const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted)),
      ],
    );
  }

  static Widget _cell(Widget child) => TableCell(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    ),
  );
}

// ─── Narrow: Card list ────────────────────────────────────────────────────────

class _InvoiceCards extends StatelessWidget {
  final List<InvoiceModel> invoices;

  const _InvoiceCards({required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Chưa có hóa đơn',
        subtitle: 'Tạo hóa đơn đầu tiên để bắt đầu',
        actionLabel: 'Tạo hóa đơn',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        // RepaintBoundary: mỗi card là paint layer độc lập
        child: RepaintBoundary(child: _InvoiceCard(invoices[i])),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel inv;

  const _InvoiceCard(this.inv);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Row(children: [
          Text(inv.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(inv.room, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.foreground)),
          const Spacer(),
          StatusBadge.invoice(inv.status),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(inv.tenant, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(formatVnd(inv.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground)),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Hạn nộp: ${inv.due}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (inv.status == InvoiceStatus.overdue)
            AppButton(label: 'Nhắc nhở', bg: AppColors.danger, onTap: () {}),
        ]),
      ]),
    );
  }
}