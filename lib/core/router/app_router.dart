import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/care/care_tab.dart';
import '../../features/info/info_screen.dart';
import '../../features/location_setup/location_setup_screen.dart';
import '../../features/notification_setting/notification_screen.dart';
import '../../features/onboarding/analysis_loading_screen.dart';
import '../../features/onboarding/complete_screen.dart';
import '../../features/onboarding/diagnosis_result_screen.dart';
import '../../features/onboarding/notification_time_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/permission_screen.dart';
import '../../features/onboarding/roadmap_screen.dart';
import '../../features/onboarding/disclaimer_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile_tab/profile_tab.dart';
import '../../features/my_body_info/my_body_info_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/report_tab/report_tab.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tutorial/tutorial_screen.dart';
import '../../widgets/main_shell.dart';

final _rootNavigatorKey  = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        final reverseTween = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0),
        ).chain(CurveTween(curve: Curves.easeInCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: SlideTransition(
            position: secondaryAnimation.drive(reverseTween),
            child: child,
          ),
        );
      },
    );

CustomTransitionPage<void> _slideUpPage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ── 스플래시 / 온보딩 플로우 ─────────────────────────────
    GoRoute(
      path: '/splash',
      pageBuilder: (_, state) => _fadePage(state, const SplashScreen()),
    ),
    GoRoute(
      path: '/disclaimer',
      pageBuilder: (_, state) => _fadePage(state, const DisclaimerScreen()),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (_, state) => _fadePage(state, const WelcomeScreen()),
    ),
    GoRoute(
      path: '/tutorial',
      pageBuilder: (_, state) => _fadePage(state, const TutorialScreen()),
    ),
    GoRoute(
      path: '/roadmap',
      pageBuilder: (_, state) => _fadePage(state, const RoadmapScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (_, state) => _slidePage(state, const OnboardingScreen()),
    ),
    GoRoute(
      path: '/analysis_loading',
      pageBuilder: (_, state) => _slidePage(state, const AnalysisLoadingScreen()),
    ),
    GoRoute(
      path: '/diagnosis_result',
      pageBuilder: (_, state) => _slidePage(state, const DiagnosisResultScreen()),
    ),
    GoRoute(
      path: '/dashboard',
      redirect: (_, __) => '/diagnosis_result',
    ),
    GoRoute(
      path: '/location_setup',
      pageBuilder: (_, state) => _slidePage(
        state,
        LocationSetupScreen(isOnboarding: state.extra as bool? ?? false),
      ),
    ),
    GoRoute(
      path: '/notification_time',
      pageBuilder: (_, state) => _slidePage(state, const NotificationTimeScreen()),
    ),
    GoRoute(
      path: '/permission',
      pageBuilder: (_, state) => _slidePage(state, const PermissionScreen()),
    ),
    GoRoute(
      path: '/onboarding_complete',
      pageBuilder: (_, state) => _slidePage(state, const OnboardingCompleteScreen()),
    ),

    // ── 설정 / 서브 페이지 (전체 화면, ShellRoute 밖) ─────────
    GoRoute(
      path: '/settings',
      pageBuilder: (_, state) => _slideUpPage(state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/my-body-info',
      pageBuilder: (_, state) => _slideUpPage(state, const MyBodyInfoScreen()),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (_, state) => _slideUpPage(state, const NotificationScreen()),
    ),
    GoRoute(
      path: '/info',
      pageBuilder: (_, state) => _slideUpPage(state, const InfoScreen()),
    ),
    GoRoute(
      path: '/profile/edit',
      redirect: (_, __) => '/my-body-info',
    ),

    // ── 메인 3탭 ShellRoute ──────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/care',
          pageBuilder: (_, state) => _fadePage(state, const CareTab()),
        ),
        GoRoute(
          path: '/report',
          pageBuilder: (_, state) => _fadePage(state, const ReportTab()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (_, state) => _fadePage(state, const ProfileTab()),
        ),
      ],
    ),
  ],
);
