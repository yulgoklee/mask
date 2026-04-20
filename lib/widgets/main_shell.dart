import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/design_tokens.dart';
import '../core/services/background_service.dart';
import '../core/services/notification_deep_link.dart';
import '../providers/providers.dart';

/// go_router ShellRoute Shell — 케어 / 리포트 / 프로필 3탭
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({required this.child, super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  static const _tabs = ['/care', '/report', '/profile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handlePendingDeepLink();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handlePendingDeepLink();
      BackgroundService.runOnce();
    }
  }

  Future<void> _handlePendingDeepLink() async {
    final payload = await NotificationDeepLink.consumePendingPayload();
    if (payload != null && mounted) {
      context.go('/care');
      ref.read(pendingPayloadTypeProvider.notifier).state = payload.type;
    }
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/report'))  return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx      = _locationToIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _SpecNavBar(
        selectedIndex: idx,
        onTap: (i) => context.go(_tabs[i]),
      ),
    );
  }
}

class _SpecNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _SpecNavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.shield_moon_outlined, selectedIcon: Icons.shield_moon,  label: '케어'),
    _NavItem(icon: Icons.bar_chart_outlined,   selectedIcon: Icons.bar_chart,    label: '리포트'),
    _NavItem(icon: Icons.person_outline,       selectedIcon: Icons.person,       label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 64 + bottomPadding,
      decoration: const BoxDecoration(
        color: DT.white,
        border: Border(top: BorderSide(color: DT.border, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item       = _items[i];
          final isSelected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 16 : 0,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected ? DT.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    size: 24,
                    color: isSelected ? DT.primary : DT.gray,
                  )
                      .animate(
                        key: ValueKey('nav_${i}_$isSelected'),
                        target: isSelected ? 1.0 : 0.0,
                      )
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.elasticOut,
                        duration: 300.ms,
                      ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? DT.primary : DT.gray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem(
      {required this.icon, required this.selectedIcon, required this.label});
}
