// lib/screens/tenants_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/api.dart';
import 'tenant_detail_screen.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  late Future<List<TenantModel>> _futureTenants;
  String _search = '';
  _TenantFilter _filter = _TenantFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
    _futureTenants = ApiClient.fetchTenants();
  });

  List<TenantModel> _apply(List<TenantModel> list) {
    var result = list;
    // Filter
    result = switch (_filter) {
      _TenantFilter.all      => result,
      _TenantFilter.active   => result.where((t) => t.hasActiveContract).toList(),
      _TenantFilter.inactive => result.where((t) => !t.isActive).toList(),
      _TenantFilter.noContract => result.where((t) => t.contractId == null).toList(),
    };
    // Search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((t) =>
      t.fullName.toLowerCase().contains(q) ||
          t.phoneNumber.contains(q) ||
          (t.roomCode?.toLowerCase().contains(q) ?? false) ||
          (t.email?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return result;
  }

  Future<void> _openAddTenant() async {
    final result = await showModalBottomSheet<TenantModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddTenantSheet(),
    );
    if (result != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TopBar(
        search: _search,
        filter: _filter,
        onSearchChanged: (v) => setState(() => _search = v),
        onFilterChanged: (v) => setState(() => _filter = v),
        onAdd: _openAddTenant,
      ),
      Expanded(
        child: FutureBuilder<List<TenantModel>>(
          future: _futureTenants,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: 'Không thể tải danh sách người thuê',
                detail: snapshot.error.toString(),
                onRetry: _load,
              );
            }
            final tenants = _apply(snapshot.data ?? []);

            if (tenants.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline,
                title: _search.isNotEmpty ? 'Không tìm thấy kết quả' : 'Chưa có người thuê',
                subtitle: _search.isNotEmpty
                    ? 'Thử tìm với từ khoá khác'
                    : 'Thêm người thuê đầu tiên cho khu trọ của bạn',
                actionLabel: _search.isEmpty ? 'Thêm người thuê' : null,
                onAction: _openAddTenant,
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: LayoutBuilder(builder: (ctx, constraints) {
                // Wide: dạng bảng; Narrow: dạng list card
                if (constraints.maxWidth > 700) {
                  return _TenantTable(tenants: tenants, onRefresh: _load);
                }
                return _TenantList(tenants: tenants, onRefresh: _load);
              }),
            );
          },
        ),
      ),
    ]);
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

enum _TenantFilter { all, active, inactive, noContract }

class _TopBar extends StatelessWidget {
  final String search;
  final _TenantFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_TenantFilter> onFilterChanged;
  final VoidCallback onAdd;

  const _TopBar({
    required this.search, required this.filter,
    required this.onSearchChanged, required this.onFilterChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Row: Search + Add button
        Row(children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
              child: TextField(
                onChanged: onSearchChanged,
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, SĐT, mã phòng...',
                  hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(label: 'Thêm người thuê', icon: Icons.person_add_alt_rounded, onTap: onAdd),
        ]),
        const SizedBox(height: 10),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _FChip(label: 'Tất cả',       value: _TenantFilter.all,        current: filter, onTap: onFilterChanged),
            const SizedBox(width: 8),
            _FChip(label: 'Đang thuê',    value: _TenantFilter.active,     current: filter, onTap: onFilterChanged),
            const SizedBox(width: 8),
            _FChip(label: 'Đã khoá',      value: _TenantFilter.inactive,   current: filter, onTap: onFilterChanged),
            const SizedBox(width: 8),
            _FChip(label: 'Chưa có HĐ',  value: _TenantFilter.noContract, current: filter, onTap: onFilterChanged),
          ]),
        ),
        const SizedBox(height: 10),
      ]),
    );
  }
}

class _FChip extends StatelessWidget {
  final String label;
  final _TenantFilter value, current;
  final ValueChanged<_TenantFilter> onTap;

  const _FChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: GoogleFonts.outfit(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

// ─── Wide Layout: Bảng ────────────────────────────────────────────────────────

class _TenantTable extends StatelessWidget {
  final List<TenantModel> tenants;
  final VoidCallback onRefresh;

  const _TenantTable({required this.tenants, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(children: [
              _th('Người thuê', flex: 3),
              _th('Liên hệ', flex: 2),
              _th('Phòng / Khu', flex: 2),
              _th('Hợp đồng', flex: 2),
              _th('Trạng thái', flex: 1),
              const SizedBox(width: 40),
            ]),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tenants.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) => _TenantTableRow(
              tenant: tenants[i],
              onTap: () => _goDetail(context, tenants[i].userId),
              onRefresh: onRefresh,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary, letterSpacing: 0.8)),
  );

  void _goDetail(BuildContext context, int id) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TenantDetailScreen(tenantId: id),
    )).then((_) => onRefresh());
  }
}

class _TenantTableRow extends StatelessWidget {
  final TenantModel tenant;
  final VoidCallback onTap, onRefresh;

  const _TenantTableRow({required this.tenant, required this.onTap, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // Avatar + name
          Expanded(flex: 3, child: Row(children: [
            _Avatar(tenant: tenant),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(tenant.fullName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground),
                  overflow: TextOverflow.ellipsis),
              if (tenant.idCardNumber != null)
                Text('CCCD: ${tenant.idCardNumber}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
          ])),
          // Liên hệ
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(tenant.phoneNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            if (tenant.email != null)
              Text(tenant.email!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
          ])),
          // Phòng
          Expanded(flex: 2, child: tenant.roomCode != null
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(tenant.roomCode!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            if (tenant.areaName != null)
              Text(tenant.areaName!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])
              : const Text('—', style: TextStyle(color: AppColors.textMuted))),
          // Hợp đồng
          Expanded(flex: 2, child: tenant.contractCode != null
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(tenant.contractCode!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            if (tenant.endDate != null)
              Text('Hết hạn: ${fmt.format(tenant.endDate!)}',
                  style: TextStyle(fontSize: 10, color: _isExpiringSoon(tenant.endDate!) ? AppColors.danger : AppColors.textMuted)),
          ])
              : const Text('Chưa có', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
          // Status badge
          Expanded(flex: 1, child: _ContractBadge(tenant: tenant)),
          // Menu
          SizedBox(width: 40, child: _TenantMenu(tenant: tenant, onRefresh: onRefresh)),
        ]),
      ),
    );
  }

  bool _isExpiringSoon(DateTime end) =>
      end.difference(DateTime.now()).inDays <= 30 && end.isAfter(DateTime.now());
}

// ─── Narrow Layout: List card ─────────────────────────────────────────────────

class _TenantList extends StatelessWidget {
  final List<TenantModel> tenants;
  final VoidCallback onRefresh;

  const _TenantList({required this.tenants, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tenants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _TenantCard(
        tenant: tenants[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TenantDetailScreen(tenantId: tenants[i].userId)),
        ).then((_) => onRefresh()),
        onRefresh: onRefresh,
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final TenantModel tenant;
  final VoidCallback onTap, onRefresh;

  const _TenantCard({required this.tenant, required this.onTap, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          _Avatar(tenant: tenant),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Text(tenant.fullName,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.foreground),
                  overflow: TextOverflow.ellipsis)),
              _ContractBadge(tenant: tenant),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(tenant.phoneNumber, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              if (tenant.roomCode != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.door_front_door_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(tenant.roomCode!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ]),
            if (tenant.actualRentPrice != null) ...[
              const SizedBox(height: 4),
              Text(
                '${NumberFormat('#,###', 'vi_VN').format(tenant.actualRentPrice)}đ/tháng',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.foreground),
              ),
            ],
          ])),
          _TenantMenu(tenant: tenant, onRefresh: onRefresh),
        ]),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final TenantModel tenant;
  const _Avatar({required this.tenant});

  static const _colors = [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[tenant.userId % _colors.length];
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: tenant.isActive ? color : AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(tenant.initials,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
    );
  }
}

class _ContractBadge extends StatelessWidget {
  final TenantModel tenant;
  const _ContractBadge({required this.tenant});

  @override
  Widget build(BuildContext context) {
    if (!tenant.isActive) {
      return _badge('Đã khoá', AppColors.border, AppColors.textMuted);
    }
    return switch (tenant.contractStatus) {
      ContractStatus.active     => _badge('Đang thuê', AppColors.successLight, AppColors.successDark),
      ContractStatus.expired    => _badge('Hết hạn',   AppColors.warningLight, AppColors.warningDark),
      ContractStatus.terminated => _badge('Đã chấm dứt', AppColors.dangerLight, AppColors.dangerDark),
      null                      => _badge('Chưa có HĐ', AppColors.muted, AppColors.textMuted),
    };
  }

  Widget _badge(String label, Color bg, Color text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: text)),
  );
}

class _TenantMenu extends StatelessWidget {
  final TenantModel tenant;
  final VoidCallback onRefresh;

  const _TenantMenu({required this.tenant, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'detail', child: Row(children: [
          const Icon(Icons.person_outline, size: 16), const SizedBox(width: 8),
          const Text('Xem chi tiết'),
        ])),
        PopupMenuItem(value: 'toggle', child: Row(children: [
          Icon(tenant.isActive ? Icons.lock_outline : Icons.lock_open_outlined, size: 16),
          const SizedBox(width: 8),
          Text(tenant.isActive ? 'Khoá tài khoản' : 'Mở tài khoản'),
        ])),
      ],
      onSelected: (v) async {
        if (v == 'detail') {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TenantDetailScreen(tenantId: tenant.userId),
          )).then((_) => onRefresh());
        } else if (v == 'toggle') {
          await _toggle(context);
        }
      },
    );
  }

  Future<void> _toggle(BuildContext context) async {
    try {
      await ApiClient.toggleTenantActive(tenant.userId);
      onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

// ─── Add Tenant Sheet ─────────────────────────────────────────────────────────

class _AddTenantSheet extends StatefulWidget {
  const _AddTenantSheet();

  @override
  State<_AddTenantSheet> createState() => _AddTenantSheetState();
}

class _AddTenantSheetState extends State<_AddTenantSheet> {
  final _fullNameCtl   = TextEditingController();
  final _phoneCtl      = TextEditingController();
  final _emailCtl      = TextEditingController();
  final _idCardCtl     = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_fullNameCtl, _phoneCtl, _emailCtl, _idCardCtl]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_fullNameCtl.text.trim().isEmpty || _phoneCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng nhập Họ tên và Số điện thoại'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final tenant = await ApiClient.createTenant({
        'fullName':    _fullNameCtl.text.trim(),
        'phoneNumber': _phoneCtl.text.trim(),
        if (_emailCtl.text.trim().isNotEmpty)  'email': _emailCtl.text.trim(),
        if (_idCardCtl.text.trim().isNotEmpty) 'idCardNumber': _idCardCtl.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(tenant);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã thêm ${tenant.fullName}. Mật khẩu mặc định: ${tenant.phoneNumber}'),
        backgroundColor: AppColors.success, duration: const Duration(seconds: 5),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Thêm người thuê mới',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground)),
        const SizedBox(height: 4),
        Text('Mật khẩu mặc định sẽ là số điện thoại',
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        LabeledInput(label: 'Họ và tên *', controller: _fullNameCtl, hint: 'Nguyễn Văn An'),
        const SizedBox(height: 12),
        LabeledInput(label: 'Số điện thoại *', controller: _phoneCtl,
            keyboardType: TextInputType.phone, hint: '0901234567'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: LabeledInput(label: 'Email', controller: _emailCtl,
              keyboardType: TextInputType.emailAddress, hint: 'example@gmail.com')),
          const SizedBox(width: 12),
          Expanded(child: LabeledInput(label: 'Số CCCD', controller: _idCardCtl,
              keyboardType: TextInputType.number, hint: '079201012345')),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.person_add_alt_rounded, size: 16),
            label: Text(_loading ? 'Đang lưu...' : 'Tạo tài khoản người thuê',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}