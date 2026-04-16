import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'features/home/home_screen.dart';
import 'features/notification_setting/notification_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/roadmap_screen.dart';
import 'features/onboarding/dashboard_screen.dart';
import 'features/onboarding/notification_custom_screen.dart';
import 'features/onboarding/permission_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/info/info_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/location_setup/location_setup_screen.dart';

class MaskAlertApp extends ConsumerWidget {
  const MaskAlertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '마스크 알람이',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        // ── 홈 (앱 완료 후) ─────────────────────────────────
        '/home':    (_) => const MainShell(),
        '/profile': (_) => const ProfileScreen(),
        '/notifications': (_) => const NotificationScreen(),
        '/info':    (_) => const InfoScreen(),

        // ── 온보딩 여정 (Phase 1 → 2 → 3 → 4) ─────────────
        '/roadmap':              (_) => const RoadmapScreen(),
        '/onboarding':           (_) => const OnboardingScreen(),
        '/dashboard':            (_) => const DashboardScreen(),
        '/notification_custom':  (_) => const NotificationCustomScreen(),

        // ── 온보딩 후 공통 ──────────────────────────────────
        '/location_setup': (_) => const LocationSetupScreen(),
        '/permission':     (_) => const PermissionScreen(),
      },
    );
  }
}

// ── 하단 탭 네비게이션 Shell ─────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _screens = [
    HomeScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon:
                Icon(Icons.notifications, color: AppColors.primary),
            label: '알림 설정',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}
