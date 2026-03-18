// lib/screens/tenant_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/api.dart';
import 'room_detail_screen.dart';

class TenantDetailScreen extends StatefulWidget {
  final int tenantId;
  const TenantDetailScreen({required this.tenantId, super.key});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<TenantModel> _future;
  bool _editing = false;
  bool _saving = false;

  final _fullNameCtl  = TextEditingController();
  final _emailCtl     = TextEditingController();
  final _idCardCtl    = TextEditingController();

  // FIX: Lưu giá trị gốc để so sánh khi save — tránh gửi email cũ gây Duplicate entry
  String? _originalFullName;
  String? _originalEmail;
  String? _originalIdCard;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  void _load() => setState(() {
    _future = ApiClient.fetchTenantDetail(widget.tenantId);
  });

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [_fullNameCtl, _emailCtl, _idCardCtl]) c.dispose();
    super.dispose();
  }

  void _enterEdit(TenantModel t) {
    _fullNameCtl.text = t.fullName;
    _emailCtl.text    = t.email ?? '';
    _idCardCtl.text   = t.idCardNumber ?? '';
    // Lưu giá trị gốc để so sánh
    _originalFullName = t.fullName;
    _originalEmail    = t.email;
    _originalIdCard   = t.idCardNumber;
    setState(() => _editing = true);
  }

  Future<void> _saveEdit() async {
    setState(() => _saving = true);
    try {
      // FIX: Chỉ gửi field nào thực sự thay đổi so với giá trị gốc
      // Tránh gửi email cũ gây lỗi Duplicate entry constraint
      final newFullName = _fullNameCtl.text.trim();
      final newEmail    = _emailCtl.text.trim().isEmpty ? null : _emailCtl.text.trim();
      final newIdCard   = _idCardCtl.text.trim().isEmpty ? null : _idCardCtl.text.trim();

      final payload = <String, dynamic>{};
      if (newFullName != _originalFullName) payload['fullName'] = newFullName;
      if (newEmail    != _originalEmail)    payload['email']    = newEmail;
      if (newIdCard   != _originalIdCard)   payload['idCardNumber'] = newIdCard;

      // Không có gì thay đổi thì không cần gọi API
      if (payload.isEmpty) {
        if (mounted) setState(() => _editing = false);
        _snack('Không có thay đổi nào', AppColors.primary);
        return;
      }

      await ApiClient.updateTenant(widget.tenantId, payload);
      _load();
      if (mounted) setState(() { _editing = false; });
      _snack('Đã cập nhật thông tin', AppColors.success);
    } catch (e) {
      _snack('Lỗi: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActive(TenantModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.isActive ? 'Khoá tài khoản?' : 'Mở tài khoản?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text(t.isActive
            ? 'Người thuê sẽ không thể đăng nhập cho đến khi được mở lại.'
            : 'Người thuê sẽ có thể đăng nhập trở lại.',
            style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: t.isActive ? AppColors.danger : AppColors.success),
            child: Text(t.isActive ? 'Khoá' : 'Mở khoá'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.toggleTenantActive(widget.tenantId);
      _load();
      _snack(t.isActive ? 'Đã khoá tài khoản' : 'Đã mở tài khoản',
          t.isActive ? AppColors.warning : AppColors.success);
    } catch (e) {
      _snack('Lỗi: $e', AppColors.danger);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<TenantModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: 'Không thể tải thông tin người thuê',
              detail: snapshot.error.toString(),
              onRetry: _load,
            );
          }
          final tenant = snapshot.data!;
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              _buildAppBar(tenant),
              _buildProfileHeader(tenant),
            ],
            body: TabBarView(
              controller: _tab,
              children: [
                _InfoTab(tenant: tenant, editing: _editing,
                    fullNameCtl: _fullNameCtl, emailCtl: _emailCtl, idCardCtl: _idCardCtl),
                _ContractTab(tenant: tenant, onRoomTap: (id) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RoomDetailScreen(roomId: id),
                  ));
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(TenantModel tenant) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: const BackButton(color: AppColors.foreground),
      title: Text(tenant.fullName,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground)),
      actions: [
        if (_saving)
          const Padding(padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_editing) ...[
          IconButton(icon: const Icon(Icons.check_rounded, color: AppColors.success), onPressed: _saveEdit, tooltip: 'Lưu'),
          IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.danger),
              onPressed: () => setState(() => _editing = false), tooltip: 'Huỷ'),
        ] else ...[
          IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.foreground),
              onPressed: () => _enterEdit(tenant), tooltip: 'Chỉnh sửa'),
          IconButton(
            icon: Icon(tenant.isActive ? Icons.lock_outline : Icons.lock_open_outlined,
                color: tenant.isActive ? AppColors.warning : AppColors.success),
            onPressed: () => _toggleActive(tenant),
            tooltip: tenant.isActive ? 'Khoá tài khoản' : 'Mở tài khoản',
          ),
        ],
        const SizedBox(width: 4),
      ],
      bottom: TabBar(
        controller: _tab,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [Tab(text: 'Thông tin'), Tab(text: 'Hợp đồng & Phòng')],
      ),
    );
  }

  Widget _buildProfileHeader(TenantModel tenant) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        color: AppColors.background,
        child: Row(children: [
          // Avatar lớn
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: tenant.isActive ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(tenant.initials,
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Text(tenant.fullName,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.foreground))),
              if (!tenant.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Đã khoá',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.danger)),
                ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(tenant.phoneNumber, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted)),
              if (tenant.roomCode != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.door_front_door_outlined, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Phòng ${tenant.roomCode}',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ]),
          ])),
        ]),
      ),
    );
  }
}

// ─── Tab 1: Thông tin ─────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final TenantModel tenant;
  final bool editing;
  final TextEditingController fullNameCtl, emailCtl, idCardCtl;

  const _InfoTab({
    required this.tenant, required this.editing,
    required this.fullNameCtl, required this.emailCtl, required this.idCardCtl,
  });

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Chỉnh sửa thông tin'),
          const SizedBox(height: 16),
          LabeledInput(label: 'Họ và tên', controller: fullNameCtl),
          const SizedBox(height: 12),
          LabeledInput(label: 'Email', controller: emailCtl, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          LabeledInput(label: 'Số CCCD/CMND', controller: idCardCtl, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.muted, borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text('Số điện thoại và mật khẩu không thể chỉnh sửa tại đây.',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted))),
            ]),
          ),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Thông tin cá nhân'),
        const SizedBox(height: 12),
        _DetailCard(children: [
          _Row(icon: Icons.person_outline, label: 'Họ và tên', value: tenant.fullName),
          _Row(icon: Icons.phone_outlined, label: 'Số điện thoại', value: tenant.phoneNumber),
          _Row(icon: Icons.email_outlined, label: 'Email', value: tenant.email ?? '—'),
          _Row(icon: Icons.badge_outlined, label: 'Số CCCD/CMND', value: tenant.idCardNumber ?? '—'),
        ]),
        const SizedBox(height: 24),
        _sectionTitle('Tài khoản'),
        const SizedBox(height: 12),
        _DetailCard(children: [
          _Row(icon: Icons.verified_user_outlined, label: 'Trạng thái',
              value: tenant.isActive ? 'Đang hoạt động' : 'Đã bị khoá',
              valueColor: tenant.isActive ? AppColors.success : AppColors.danger),
          _Row(icon: Icons.lock_outline, label: 'Mật khẩu', value: '••••••••'),
        ]),
      ]),
    );
  }

  Widget _sectionTitle(String t) => TagLabel(t);
}

// ─── Tab 2: Hợp đồng & Phòng ──────────────────────────────────────────────────

class _ContractTab extends StatelessWidget {
  final TenantModel tenant;
  final ValueChanged<int> onRoomTap;

  const _ContractTab({required this.tenant, required this.onRoomTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    if (tenant.contractId == null) {
      return const EmptyState(
        icon: Icons.description_outlined,
        title: 'Chưa có hợp đồng',
        subtitle: 'Người thuê này chưa được gán hợp đồng nào',
      );
    }

    // Màu trạng thái hợp đồng
    final (statusColor, statusBg) = switch (tenant.contractStatus) {
      ContractStatus.active     => (AppColors.successDark, AppColors.successLight),
      ContractStatus.expired    => (AppColors.warningDark, AppColors.warningLight),
      ContractStatus.terminated => (AppColors.dangerDark, AppColors.dangerLight),
      null                      => (AppColors.textMuted, AppColors.muted),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Phòng đang thuê ──
        if (tenant.roomId != null) ...[
          const TagLabel('Phòng đang thuê'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => onRoomTap(tenant.roomId!),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.door_front_door_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Phòng ${tenant.roomCode}',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  if (tenant.areaName != null)
                    Text(tenant.areaName!, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                ])),
                const Icon(Icons.chevron_right, color: AppColors.primary),
              ]),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Hợp đồng ──
        const TagLabel('Thông tin hợp đồng'),
        const SizedBox(height: 12),
        _DetailCard(children: [
          _Row(icon: Icons.description_outlined, label: 'Mã hợp đồng', value: tenant.contractCode ?? '—'),
          _Row(
            icon: Icons.circle, label: 'Trạng thái',
            value: tenant.contractStatusLabel,
            valueColor: statusColor, valueBg: statusBg,
          ),
          if (tenant.startDate != null)
            _Row(icon: Icons.calendar_today_outlined, label: 'Ngày bắt đầu', value: fmt.format(tenant.startDate!)),
          if (tenant.endDate != null)
            _Row(
              icon: Icons.event_outlined, label: 'Ngày kết thúc',
              value: fmt.format(tenant.endDate!),
              valueColor: _isExpiringSoon(tenant.endDate!) ? AppColors.danger : null,
            ),
          if (tenant.actualRentPrice != null)
            _Row(
              icon: Icons.payments_outlined, label: 'Giá thuê thực tế',
              value: '${NumberFormat('#,###', 'vi_VN').format(tenant.actualRentPrice)}đ/tháng',
              valueColor: AppColors.primary,
            ),
        ]),

        // Cảnh báo sắp hết hạn
        if (tenant.endDate != null && _isExpiringSoon(tenant.endDate!)) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Hợp đồng còn ${tenant.endDate!.difference(DateTime.now()).inDays} ngày nữa hết hạn. Liên hệ người thuê để gia hạn.',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.warningDark),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  bool _isExpiringSoon(DateTime end) =>
      end.isAfter(DateTime.now()) && end.difference(DateTime.now()).inDays <= 30;
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(children.length, (i) => Column(mainAxisSize: MainAxisSize.min, children: [
          children[i],
          if (i < children.length - 1) const Divider(height: 1, color: AppColors.border),
        ])),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  final Color? valueBg;

  const _Row({
    required this.icon, required this.label, required this.value,
    this.valueColor, this.valueBg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        const Spacer(),
        valueBg != null
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: valueBg, borderRadius: BorderRadius.circular(6)),
          child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.foreground)),
        )
            : Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.foreground),
            textAlign: TextAlign.right),
      ]),
    );
  }
}