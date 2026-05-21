import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'notifications/notifications_screen.dart';
import 'cycle/cycle_screen.dart';
import 'history/history_screen.dart';

/// Controller global — bisa dipanggil dari mana saja untuk pindah tab.
/// Gunakan [MainScreenController.switchTab(index)] dari widget mana pun.
class MainScreenController {
  // ValueNotifier digunakan agar tidak ada GlobalKey duplikat.
  static final ValueNotifier<int> _tabNotifier = ValueNotifier<int>(0);

  /// Pindah ke tab tertentu. Index: 0=UTAMA, 1=NOTIFIKASI, 2=SIKLUS, 3=RIWAYAT
  static void switchTab(int index) {
    _tabNotifier.value = index;
  }
}

/// Root scaffold yang berisi bottom navigation bar 5-item:
/// UTAMA · NOTIFIKASI · [FAB +] · SIKLUS · RIWAYAT
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    NotificationsScreen(),
    CycleScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    MainScreenController._tabNotifier.addListener(_onExternalTabChange);
  }

  @override
  void dispose() {
    MainScreenController._tabNotifier.removeListener(_onExternalTabChange);
    super.dispose();
  }

  void _onExternalTabChange() {
    final idx = MainScreenController._tabNotifier.value;
    if (idx != _currentIndex) {
      setState(() => _currentIndex = idx);
    }
  }

  void _onNavTap(int index) {
    MainScreenController._tabNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _CenterFab(
        onTap: () => Navigator.pushNamed(
          context,
          '/recommendation/contextual',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ─── Center FAB ───────────────────────────────────────────────────────────────

class _CenterFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF2F6FBF),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F6FBF).withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertProvider>(
      builder: (_, alertProv, __) {
        final unread = alertProv.activeAlerts.length;

        return BottomAppBar(
          color: Colors.white,
          elevation: 12,
          shadowColor: Colors.black.withAlpha(30),
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // UTAMA
                _NavItem(
                  icon: Icons.space_dashboard_outlined,
                  activeIcon: Icons.space_dashboard,
                  label: 'UTAMA',
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                ),

                // NOTIFIKASI
                _NavItem(
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  label: 'NOTIFIKASI',
                  active: currentIndex == 1,
                  badge: unread,
                  onTap: () => onTap(1),
                ),

                // Spacer for FAB
                const SizedBox(width: 60),

                // SIKLUS
                _NavItem(
                  icon: Icons.trending_up_outlined,
                  activeIcon: Icons.trending_up,
                  label: 'SIKLUS',
                  active: currentIndex == 2,
                  onTap: () => onTap(2),
                ),

                // RIWAYAT
                _NavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: 'RIWAYAT',
                  active: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Single nav item ──────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    this.badge = 0,
    required this.onTap,
  });

  static const _activeColor = Color(0xFF2F6FBF);
  static const _inactiveColor = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final color = active ? _activeColor : _inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? activeIcon : icon, size: 24, color: color),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE24B4A),
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
