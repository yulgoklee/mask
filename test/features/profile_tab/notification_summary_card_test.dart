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
  // ── 알림 항목 표시 케이스 ────────────────────────────────

  group('알림 항목 표시: 활성 항목만 줄 단위 노출', () {
    testWidgets('케이스 1: 모든 알림 켜짐 — 항목별 행 표시', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 7,
        eveningForecastEnabled: true,
        eveningReturnEnabled: true,
        realtimeAlertEnabled: true,
        quietHoursEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('외출 전 알림'), findsOneWidget);
      expect(find.text('전날 예보 알림'), findsOneWidget);
      expect(find.text('귀가 후 알림'), findsOneWidget);
      expect(find.text('실시간 경보'), findsOneWidget);
    });

    testWidgets('케이스 2: 오전 알림 + 전날 예보만 켜짐', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 7,
        eveningForecastEnabled: true,
        eveningReturnEnabled: false,
        realtimeAlertEnabled: false,
        quietHoursEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('외출 전 알림'), findsOneWidget);
      expect(find.text('전날 예보 알림'), findsOneWidget);
      expect(find.text('귀가 후 알림'), findsNothing);
    });

    testWidgets('케이스 3: 귀가 후만 켜짐 — "귀가 후 알림" 행 표시', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: false,
        eveningForecastEnabled: false,
        eveningReturnEnabled: true,
        realtimeAlertEnabled: false,
        quietHoursEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('귀가 후 알림'), findsOneWidget);
      expect(find.text('외출 전 알림'), findsNothing);
    });

    testWidgets('케이스 4: 모두 꺼짐 — "받고 있는 알림이 없어요" 표시', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: false,
        eveningForecastEnabled: false,
        eveningReturnEnabled: false,
        realtimeAlertEnabled: false,
        quietHoursEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('받고 있는 알림이 없어요'), findsOneWidget);
    });
  });

  // ── 방해금지 표시 ─────────────────────────────────────────

  group('방해금지 표시', () {
    testWidgets('방해금지 켜짐 — "방해금지" 행 표시', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        quietHoursEnabled: true,
        quietHoursStartHour: 22,
        quietHoursEndHour: 6,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('방해금지'), findsOneWidget);
      expect(find.text('22:00 ~ 06:00'), findsOneWidget);
    });

    testWidgets('방해금지 꺼짐 — "방해금지" 행 미표시', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        quietHoursEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('방해금지'), findsNothing);
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
    testWidgets('오전 7시 → "오전 7시" 표시', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 7,
        morningAlertMinute: 0,
        eveningForecastEnabled: false,
        eveningReturnEnabled: false,
        realtimeAlertEnabled: false,
        quietHoursEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('오전 7시'), findsOneWidget);
    });

    testWidgets('오후 6시(18) → "오후 6시" 표시', (tester) async {
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 18,
        morningAlertMinute: 0,
        eveningForecastEnabled: false,
        eveningReturnEnabled: false,
        realtimeAlertEnabled: false,
        quietHoursEnabled: false,
      );
      await tester.pumpWidget(_buildCard(setting));
      await tester.pumpAndSettle();

      expect(find.text('오후 6시'), findsOneWidget);
    });
  });
}
