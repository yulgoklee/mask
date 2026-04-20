import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/design_tokens.dart';
import 'core/services/notification_deep_link.dart';
import 'features/care/care_tab.dart';
import 'features/info/info_screen.dart';
import 'features/location_setup/location_setup_screen.dart';
import 'features/notification_setting/notification_screen.dart';
import 'features/onboarding/analysis_loading_screen.dart';
import 'features/onboarding/complete_screen.dart';
import 'features/onboarding/dashboard_screen.dart';
import 'features/onboarding/notification_time_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/permission_screen.dart';
import 'features/onboarding/roadmap_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile_tab/profile_tab.dart';
import 'features/report_tab/report_tab.dart';
import 'features/splash/splash_screen.dart';
import 'features/tutorial/tutorial_screen.dart';
import 'providers/providers.dart';

class MaskAlertApp extends ConsumerWidget {
  const MaskAlertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '마스크 알림',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en')],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: DT.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: DT.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/home':                (_) => const MainShell(),
        '/profile':             (_) => const ProfileScreen(),
        '/notifications':       (_) => const NotificationScreen(),
        '/info':                (_) => const InfoScreen(),
        '/roadmap':             (_) => const RoadmapScreen(),
        '/onboarding':          (_) => const OnboardingScreen(),
        '/tutorial':            (_) => const TutorialScreen(),
        '/location_setup':      (_) => const LocationSetupScreen(),
        '/notification_time':   (_) => const NotificationTimeScreen(),
        '/permission':          (_) => const PermissionScreen(),
        '/onboarding_complete': (_) => const OnboardingCompleteScreen(),
        '/dashboard':           (_) => const DashboardScreen(),
        '/analysis_loading':    (_) => const AnalysisLoadingScreen(),
        '/report':              (_) => const MainShell(initialIndex: 1),
      },
    );
  }
}

/// 하단 탭 네비게이션 Shell — 케어 / 리포트 / 프로필 3탭
class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  late int _selectedIndex;

  static const _screens = [
    CareTab(),
    ReportTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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
    }
  }

  Future<void> _handlePendingDeepLink() async {
    final payload = await NotificationDeepLink.consumePendingPayload();
    if (payload != null && mounted) {
      setState(() => _selectedIndex = NotificationDeepLink.careTabIndex);
      ref.read(pendingPayloadTypeProvider.notifier).state = payload.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _SpecNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

/// 스펙 정의 하단 네비게이션 바
/// - 높이: 64px + SafeArea
/// - 상단 border 1px
/// - 선택 인디케이터: 아이콘 상단 4×16px 바
/// - 탭 선택 시 아이콘 scale bounce
class _SpecNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _SpecNavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.shield_moon_outlined, selectedIcon: Icons.shield_moon, label: '케어'),
    _NavItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: '리포트'),
    _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: '프로필'),
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
          final item = _items[i];
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
                  ).animate(key: ValueKey('nav_${i}_$isSelected'), target: isSelected ? 1.0 : 0.0)
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}
