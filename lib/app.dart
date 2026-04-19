import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_deep_link.dart';
import 'features/home/home_screen.dart';
import 'providers/providers.dart';
import 'features/notification_setting/notification_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/report/report_screen.dart';
import 'features/info/info_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/tutorial/tutorial_screen.dart';
import 'features/location_setup/location_setup_screen.dart';
import 'features/onboarding/notification_time_screen.dart';
import 'features/onboarding/permission_screen.dart';
import 'features/onboarding/complete_screen.dart';
import 'features/onboarding/dashboard_screen.dart';
import 'features/onboarding/analysis_loading_screen.dart';
import 'features/onboarding/roadmap_screen.dart';

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
scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (_) => const MainShell(),
        '/profile': (_) => const ProfileScreen(),
        '/notifications': (_) => const NotificationScreen(),
        '/info': (_) => const InfoScreen(),
        '/roadmap': (_) => const RoadmapScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/tutorial': (_) => const TutorialScreen(),
        '/location_setup': (_) => const LocationSetupScreen(),
        '/notification_time': (_) => const NotificationTimeScreen(),
        '/permission': (_) => const PermissionScreen(),
        '/onboarding_complete': (_) => const OnboardingCompleteScreen(),
        '/dashboard':           (_) => const DashboardScreen(),
        '/analysis_loading':    (_) => const AnalysisLoadingScreen(),
      },
    );
  }
}

/// 하단 탭 네비게이션 Shell
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  // 탭 순서: 케어(0) / 기록(1) / 프로필(2)
  static const _screens = [
    HomeScreen(),
    ReportScreen(),
    ProfileScreen(),
  ];

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
            icon: Icon(Icons.shield_moon_outlined),
            selectedIcon: Icon(Icons.shield_moon, color: AppColors.primary),
            label: '케어',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: '기록',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
