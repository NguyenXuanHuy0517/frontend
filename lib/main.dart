// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/utilities_screen.dart';
import 'widgets/chatbot_widget.dart';
import 'services/api.dart';
import 'screens/room_detail_screen.dart';

void main() {
  runApp(const PhongTro40App());
}

class PhongTro40App extends StatelessWidget {
  const PhongTro40App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phòng Trọ 4.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppShell(),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final int? badge;
  const _NavItem(this.icon, this.label, {this.badge});
}

final _navItems = [
  const _NavItem(Icons.bar_chart_rounded, 'Tổng quan'),
  const _NavItem(Icons.home_rounded, 'Phòng trọ'),
  const _NavItem(Icons.receipt_long, 'Hóa đơn', badge: 2),
  const _NavItem(Icons.bolt, 'Điện/Nước'),
  const _NavItem(Icons.description_outlined, 'Hợp đồng'),
  const _NavItem(Icons.people_outline, 'Khách thuê'),
  const _NavItem(Icons.build_outlined, 'Bảo trì'),
];

// ─── App Shell ────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  Widget _buildScreen(int index) => switch (index) {
    0 => const DashboardScreen(),
    1 => const RoomsScreen(),
    2 => const InvoicesScreen(),
    3 => const UtilitiesScreen(),
    _ => _PlaceholderScreen(navItem: _navItems[index]),
  };

  @override
  Widget build(BuildContext context) {
    // Wide = Desktop/Tablet sidebar layout
    // Narrow = Mobile bottom nav layout
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 768;
      return isWide
          ? _WideLayout(
              selectedIndex: _selectedIndex,
              onNavTap: (i) => setState(() => _selectedIndex = i),
              child: _buildScreen(_selectedIndex),
            )
          : _NarrowLayout(
              selectedIndex: _selectedIndex,
              onNavTap: (i) => setState(() => _selectedIndex = i),
              child: _buildScreen(_selectedIndex),
            );
    });
  }
}

// ─── Wide Layout (Desktop / Web / Tablet) ────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavTap;
  final Widget child;

  const _WideLayout({required this.selectedIndex, required this.onNavTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: AppColors.sidebarBg,
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.sidebarBorder, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phòng Trọ 4.0',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          Text('Chủ trọ · Nguyễn Chí Công',
                              style: GoogleFonts.outfit(color: AppColors.sidebarText, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Nav items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: _navItems.asMap().entries.map((e) =>
                        _SidebarItem(
                          item: e.value,
                          selected: selectedIndex == e.key,
                          onTap: () => onNavTap(e.key),
                        )).toList(),
                    ),
                  ),
                ),

                // Bottom actions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.sidebarBorder, width: 2)),
                  ),
                  child: Column(
                    children: [
                      _SidebarAction(icon: Icons.settings_outlined, label: 'Cài đặt'),
                      _SidebarAction(icon: Icons.logout_rounded, label: 'Đăng xuất', danger: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_navItems[selectedIndex].label,
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.foreground)),
                          Text('Thứ Tư, 11 tháng 3, 2026',
                              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      const Spacer(),
                      // Search
                      Container(
                        width: 200,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.muted, borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SearchField(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _NotificationBell(),
                      const SizedBox(width: 12),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Text('CC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                      ),
                    ],
                  ),
                ),
                // Screen content
                Expanded(
                  child: Stack(
                    children: [
                      child,
                      const Positioned(bottom: 20, right: 20, child: ChatbotWidget()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Narrow Layout (Mobile) ───────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavTap;
  final Widget child;

  const _NarrowLayout({required this.selectedIndex, required this.onNavTap, required this.child});

  @override
  Widget build(BuildContext context) {
    // Show only first 4 in bottom nav
    final bottomNavItems = _navItems.take(4).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 16,
        title: Text(_navItems[selectedIndex].label,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground)),
        actions: [
          _NotificationBell(),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('CC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: AppColors.border),
        ),
      ),
      body: Stack(
        children: [
          child,
          const Positioned(bottom: 16, right: 16, child: ChatbotWidget()),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex < 4 ? selectedIndex : 0,
          onTap: onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 10),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 10),
          elevation: 0,
          items: bottomNavItems.asMap().entries.map((e) => BottomNavigationBarItem(
            icon: e.value.badge != null
                ? Badge(label: Text('${e.value.badge}'), child: Icon(e.value.icon))
                : Icon(e.value.icon),
            label: e.value.label,
          )).toList(),
        ),
      ),
    );
  }
}

// ─── Sidebar Widgets ──────────────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: selected ? Colors.white : AppColors.sidebarText, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.label,
                  style: GoogleFonts.outfit(
                    color: selected ? Colors.white : AppColors.sidebarText,
                    fontWeight: FontWeight.w600, fontSize: 13,
                  )),
            ),
            if (item.badge != null)
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.danger,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Center(
                  child: Text('${item.badge}',
                      style: TextStyle(
                        color: selected ? AppColors.primary : Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w800,
                      )),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  const _SidebarAction({required this.icon, required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: danger ? const Color(0xFFFC6868) : AppColors.sidebarText, size: 16),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.outfit(
              color: danger ? const Color(0xFFFC6868) : AppColors.sidebarText,
              fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.textSecondary),
        ),
        Positioned(
          top: 6, right: 6,
          child: Container(width: 7, height: 7,
            decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
        ),
      ],
    );
  }
}

// ─── Placeholder for unbuilt screens ─────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final _NavItem navItem;
  const _PlaceholderScreen({required this.navItem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(36)),
            child: Icon(navItem.icon, color: AppColors.textMuted, size: 30),
          ),
          const SizedBox(height: 16),
          Text('${navItem.label} — Đang phát triển',
              style: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Thêm mới'),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  @override
  __SearchFieldState createState() => __SearchFieldState();
}

class __SearchFieldState extends State<_SearchField> {
  final TextEditingController _controller = TextEditingController();

  void _onSearch() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    try {
      final result = await ApiClient.fetchRoomByCode(code);
      // Navigate to room detail screen if found
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => RoomDetailScreen(roomId: result.roomId),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy phòng với mã $code. Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onSubmitted: (_) => _onSearch(),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm theo mã phòng...',
        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        filled: false,
        suffixIcon: IconButton(
          icon: const Icon(Icons.search, color: AppColors.textMuted, size: 16),
          onPressed: _onSearch,
        ),
      ),
    );
  }
}
