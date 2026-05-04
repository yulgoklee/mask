import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile_tab/widgets/notification_summary_card.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  final NotificationSetting notifSetting;

  _FakeProfileRepo({required this.notifSetting});

  @override
  Future<UserProfile> loadProfile() async => const UserProfile(
        nickname: '테스트',
        birthYear: 1990,
        gender: 'male',
        asthma: false,
        rhinitis: false,
        copd: false,
        allergy: false,
        hypertension: false,
        heartDisease: false,
        stroke: false,
        smokingStatus: SmokingStatus.never,
        activityTags: [],
        discomfortLevel: 0,
      );

  @override
  Future<void> saveProfile(UserProfile p) async {}

  @override
  Future<NotificationSetting> loadNotificationSetting() async => notifSetting;

  @override
  Future<void> saveNotificationSetting(NotificationSetting s) async {}

  @override
  Future<bool> isOnboardingCompleted() async => false;

  @override
  Future<void> completeOnboarding() async {}

  @override
  Future<void> resetOnboarding() async {}

  @override
  Future<bool> isTutorialSeen() async => false;

  @override
  Future<void> completeTutorial() async {}
}

// ── 헬퍼 ─────────────────────────────────────────────────

Widget _buildCard(NotificationSetting notifSetting) {
  final repo = _FakeProfileRepo(notifSetting: notifSetting);

  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (_, __) => const Scaffold(
          body: Center(child: NotificationSummaryCard()),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) =>
            const Scaffold(body: Text('알림 설정 화면')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  // ── 카피 룰 4 케이스 ─────────────────────────────────────

  group('카피 룰: 알림 요약 텍스트', () {
    testWidgets('케이스 1: 모든 알림 켜짐 — "매일 오전 7시 · 전날 예보 · 귀가 후 · 실시간 경보"',
        (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 7,
        eveningForecastEnabled: true,
        eveningReturnEnabled: true,
        realtimeAlertEnabled: true,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(
        find.text('매일 오전 7시 · 전날 예보 · 귀가 후 · 실시간 경보'),
        findsOneWidget,
      );
    });

    testWidgets('케이스 2: 오전 알림 + 외출 전(전날 예보) 켜짐 — "매일 오전 7시 · 전날 예보"',
        (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 7,
        eveningForecastEnabled: true,
        eveningReturnEnabled: false,
        realtimeAlertEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('매일 오전 7시 · 전날 예보'), findsOneWidget);
    });

    testWidgets('케이스 3: 귀가 후만 켜짐 — "귀가 후"', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: false,
        eveningForecastEnabled: false,
        eveningReturnEnabled: true,
        realtimeAlertEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('귀가 후'), findsOneWidget);
    });

    testWidgets('케이스 4: 모두 꺼짐 — "받고 있는 알림이 없어요"', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: false,
        eveningForecastEnabled: false,
        eveningReturnEnabled: false,
        realtimeAlertEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('받고 있는 알림이 없어요'), findsOneWidget);
    });
  });

  // ── 고정 UI 요소 ─────────────────────────────────────────

  group('고정 UI 요소', () {
    testWidgets('"🔔 내 알림" 카드 제목 항상 표시', (tester) async {
      const setting = NotificationSetting(morningAlertEnabled: true);
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('🔔 내 알림'), findsOneWidget);
    });

    testWidgets('"변경 →" 텍스트 항상 표시', (tester) async {
      const setting = NotificationSetting(morningAlertEnabled: false);
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('변경 →'), findsOneWidget);
    });
  });

  // ── 탭 동작 ──────────────────────────────────────────────

  group('탭 동작', () {
    testWidgets('카드 탭 → /notifications 이동', (tester) async {
      const setting = NotificationSetting(morningAlertEnabled: true);
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      // 카드 제목 탭 (InkWell 전체 영역)
      await tester.tap(find.text('🔔 내 알림'));
      await tester.pumpAndSettle();

      expect(find.text('알림 설정 화면'), findsOneWidget);
    });

    testWidgets('"변경 →" 탭 → /notifications 이동', (tester) async {
      const setting = NotificationSetting(morningAlertEnabled: true);
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      await tester.tap(find.text('변경 →'));
      await tester.pumpAndSettle();

      expect(find.text('알림 설정 화면'), findsOneWidget);
    });
  });

  // ── 시간 포맷 확인 ───────────────────────────────────────

  group('시간 포맷', () {
    testWidgets('오전 7시 → "매일 오전 7시"', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 7,
        eveningForecastEnabled: false,
        eveningReturnEnabled: false,
        realtimeAlertEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('매일 오전 7시'), findsOneWidget);
    });

    testWidgets('오후 6시(18) → "매일 오후 6시"', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 18,
        eveningForecastEnabled: false,
        eveningReturnEnabled: false,
        realtimeAlertEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('매일 오후 6시'), findsOneWidget);
    });
  });
}
