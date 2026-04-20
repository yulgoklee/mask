import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/care/care_tab.dart';
import '../../features/info/info_screen.dart';
import '../../features/location_setup/location_setup_screen.dart';
import '../../features/notification_setting/notification_screen.dart';
import '../../features/onboarding/analysis_loading_screen.dart';
import '../../features/onboarding/complete_screen.dart';
import '../../features/onboarding/dashboard_screen.dart';
import '../../features/onboarding/notification_time_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/permission_screen.dart';
import '../../features/onboarding/roadmap_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile_tab/profile_tab.dart';
import '../../features/report_tab/report_tab.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tutorial/tutorial_screen.dart';
import '../../widgets/main_shell.dart';

final _rootNavigatorKey  = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ── 스플래시 / 온보딩 플로우 ─────────────────────────────
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/tutorial',
      builder: (_, __) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/roadmap',
      builder: (_, __) => const RoadmapScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/analysis_loading',
      builder: (_, __) => const AnalysisLoadingScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/location_setup',
      builder: (context, state) => LocationSetupScreen(
        isOnboarding: state.extra as bool? ?? false,
      ),
    ),
    GoRoute(
      path: '/notification_time',
      builder: (_, __) => const NotificationTimeScreen(),
    ),
    GoRoute(
      path: '/permission',
      builder: (_, __) => const PermissionScreen(),
    ),
    GoRoute(
      path: '/onboarding_complete',
      builder: (_, __) => const OnboardingCompleteScreen(),
    ),

    // ── 설정 / 서브 페이지 (전체 화면, ShellRoute 밖) ─────────
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/info',
      builder: (_, __) => const InfoScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (_, __) => const ProfileScreen(),
    ),

    // ── 메인 3탭 ShellRoute ──────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/care',
          builder: (_, __) => const CareTab(),
        ),
        GoRoute(
          path: '/report',
          builder: (_, __) => const ReportTab(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileTab(),
        ),
      ],
    ),
  ],
);
