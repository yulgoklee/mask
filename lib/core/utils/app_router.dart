import 'package:flutter/material.dart';

/// 앱 전체 화면 전환 애니메이션 통일
///
/// 사용법:
///   Navigator.of(context).push(AppRouter.slideUp(TargetScreen()));
class AppRouter {
  AppRouter._();

  // ── 온보딩 플로우 — 오른쪽에서 왼쪽 슬라이드 ─────────────
  static PageRoute<T> slide<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
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
  }

  // ── 모달성 화면 — 아래서 위로 슬라이드 ──────────────────────
  static PageRoute<T> slideUp<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
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
  }

  // ── 페이드 — 스플래시→튜토리얼 등 큰 전환 ──────────────────
  static PageRoute<T> fade<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}
