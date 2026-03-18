// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/utilities_screen.dart';
import 'widgets/chatbot_widget.dart';
import 'screens/tenants_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Keyboard desync fix cho Windows desktop (alt-tab bug)
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    ServicesBinding.instance.keyboard.addHandler(_keyboardDesyncGuard);
  }
  runApp(const PhongTro40App());
}

bool _keyboardDesyncGuard(KeyEvent _) => false;

// ─── App ──────────────────────────────────────────────────────────────────────

class PhongTro40App extends StatelessWidget {
  const PhongTro40App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phòng Trọ 4.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _KeyboardLifecycleWrapper(child: AppShell()),
    );
  }
}

// ─── Keyboard lifecycle wrapper (Windows alt-tab fix) ────────────────────────

class _KeyboardLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const _KeyboardLifecycleWrapper({required this.child});

  @override
  State<_KeyboardLifecycleWrapper> createState() => _KeyboardLifecycleWrapperState();
}

class _KeyboardLifecycleWrapperState extends State<_KeyboardLifecycleWrapper>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _clearPressedKeys();
  }

  void _clearPressedKeys() {
    try {
      final pressed = Set<PhysicalKeyboardKey>.from(HardwareKeyboard.instance.physicalKeysPressed);
      for (final key in pressed) {
        HardwareKeyboard.instance.handleKeyEvent(
          KeyUpEvent(physicalKey: key, logicalKey: LogicalKeyboardKey.escape, timeStamp: Duration.zero),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─── Nav items (const — khởi tạo 1 lần) ─────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final int? badge;
  const _NavItem(this.icon, this.label, {this.badge});
}

const _navItems = <_NavItem>[
  _NavItem(Icons.bar_chart_rounded,    'Tổng quan'),
  _NavItem(Icons.home_rounded,         'Phòng trọ'),
  _NavItem(Icons.receipt_long,         'Hóa đơn',    badge: 2),
  _NavItem(Icons.bolt,                 'Điện/Nước'),
  _NavItem(Icons.description_outlined, 'Hợp đồng'),
  _NavItem(Icons.people_outline,       'Khách thuê'),
  _NavItem(Icons.build_outlined,       'Bảo trì'),
];

// ─── App Shell ────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Cache screens — tránh recreate mỗi lần switch tab
  static final _screens = <int, Widget>{};

  Widget _getScreen(int index) {
    return _screens.putIfAbsent(index, () => switch (index) {
      0 => const DashboardScreen(),
      1 => const RoomsScreen(),
      2 => const InvoicesScreen(),
      3 => const UtilitiesScreen(),
      5 => const TenantsScreen(),
      _ => _PlaceholderScreen(navItem: _navItems[index]),
    });
  }

  void _onNavTap(int i) {
    if (i != _selectedIndex) setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return constraints.maxWidth >= 768
          ? _WideLayout(selectedIndex: _selectedIndex, onNavTap: _onNavTap, child: _getScreen(_selectedIndex))
          : _NarrowLayout(selectedIndex: _selectedIndex, onNavTap: _onNavTap, child: _getScreen(_selectedIndex));
    });
  }
}

// ─── Wide Layout ──────────────────────────────────────────────────────────────

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
          // Sidebar: RepaintBoundary — chỉ repaint khi selectedIndex đổi
          RepaintBoundary(
            child: _Sidebar(selectedIndex: selectedIndex, onNavTap: onNavTap),
          ),
          Expanded(
            child: Column(
              children: [
                // TopBar: RepaintBoundary + const internals
                RepaintBoundary(
                  child: _TopBar(title: _navItems[selectedIndex].label),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // RepaintBoundary cho content — tránh repaint lan ra sidebar/topbar
                      RepaintBoundary(child: child),
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

// ─── Narrow Layout ────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavTap;
  final Widget child;

  const _NarrowLayout({required this.selectedIndex, required this.onNavTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 16,
        title: Text(_navItems[selectedIndex].label,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground)),
        actions: const [
          _NotificationBell(),
          SizedBox(width: 8),
          Padding(padding: EdgeInsets.only(right: 16), child: _AvatarBadge()),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: ColoredBox(color: AppColors.border, child: SizedBox(height: 2, width: double.infinity)),
        ),
      ),
      body: Stack(
        children: [
          RepaintBoundary(child: child),
          const Positioned(bottom: 16, right: 16, child: ChatbotWidget()),
        ],
      ),
      bottomNavigationBar: RepaintBoundary(
        child: _BottomNav(selectedIndex: selectedIndex, onTap: onNavTap),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = <_NavItem>[
      _NavItem(Icons.bar_chart_rounded, 'Tổng quan'),
      _NavItem(Icons.home_rounded,      'Phòng trọ'),
      _NavItem(Icons.receipt_long,      'Hóa đơn', badge: 2),
      _NavItem(Icons.bolt,              'Điện/Nước'),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex < 4 ? selectedIndex : 0,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 10),
        elevation: 0,
        items: List.generate(items.length, (i) {
          final item = items[i];
          return BottomNavigationBarItem(
            icon: item.badge != null
                ? Badge(label: Text('${item.badge}'), child: Icon(item.icon))
                : Icon(item.icon),
            label: item.label,
          );
        }),
      ),
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  const _Sidebar({required this.selectedIndex, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: ColoredBox(
        color: AppColors.sidebarBg,
        child: Column(
          children: [
            const _SidebarLogo(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                // ListView.builder: lazy render, không build tất cả nav items cùng lúc
                child: ListView.builder(
                  itemCount: _navItems.length,
                  itemBuilder: (_, i) => _SidebarItem(
                    item: _navItems[i],
                    selected: selectedIndex == i,
                    onTap: () => onNavTap(i),
                  ),
                ),
              ),
            ),
            const _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Phòng Trọ 4.0',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            Text('Chủ trọ · Nguyễn Chí Công',
                style: GoogleFonts.outfit(color: AppColors.sidebarText, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.sidebarBorder, width: 2)),
      ),
      child: const Column(
        children: [
          _SidebarAction(icon: Icons.settings_outlined, label: 'Cài đặt'),
          _SidebarAction(icon: Icons.logout_rounded,    label: 'Đăng xuất', danger: true),
        ],
      ),
    );
  }
}

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
        child: Row(children: [
          Icon(item.icon, color: selected ? Colors.white : AppColors.sidebarText, size: 17),
          const SizedBox(width: 10),
          Expanded(child: Text(item.label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.sidebarText,
                fontWeight: FontWeight.w600, fontSize: 13,
              ))),
          if (item.badge != null)
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.danger,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Center(child: Text('${item.badge}',
                  style: TextStyle(
                    color: selected ? AppColors.primary : Colors.white,
                    fontSize: 10, fontWeight: FontWeight.w800,
                  ))),
            ),
        ]),
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
    final color = danger ? const Color(0xFFFC6868) : AppColors.sidebarText;
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ─── TopBar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Row(
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.foreground)),
            const Text('Thứ Tư, 11 tháng 3, 2026',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
          const Spacer(),
          const _NotificationBell(),
          const SizedBox(width: 12),
          const _AvatarBadge(),
        ],
      ),
    );
  }
}

// ─── Micro widgets — const, tái dùng ─────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

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

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
      child: const Center(child: Text('CC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
    );
  }
}

// ─── Placeholder ──────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final _NavItem navItem;
  const _PlaceholderScreen({required this.navItem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(36)),
          child: Icon(navItem.icon, color: AppColors.textMuted, size: 30),
        ),
        const SizedBox(height: 16),
        Text('${navItem.label} — Đang phát triển',
            style: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 16), label: const Text('Thêm mới')),
      ]),
    );
  }
}