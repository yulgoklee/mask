import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/report_tab/models/report_models.dart';
import 'package:mask_alert/features/report_tab/providers/report_providers.dart';
import 'package:mask_alert/features/report_tab/report_drill_screen.dart';
import 'package:mask_alert/providers/dust_providers.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake ProfileRepository ────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  final UserProfile _profile;

  _FakeProfileRepo({UserProfile? profile})
      : _profile = profile ?? UserProfile.defaultProfile();

  @override
  Future<UserProfile> loadProfile() async => _profile;
  @override
  Future<void> saveProfile(UserProfile p) async {}
  @override
  Future<NotificationSetting> loadNotificationSetting() async =>
      const NotificationSetting();
  @override
  Future<void> saveNotificationSetting(NotificationSetting s) async {}
  @override
  Future<bool> isOnboardingCompleted() async => true;
  @override
  Future<void> completeOnboarding() async {}
  @override
  Future<void> resetOnboarding() async {}
  @override
  Future<bool> isTutorialSeen() async => true;
  @override
  Future<void> completeTutorial() async {}
}

// ── 테스트용 DrillReportData 헬퍼 ─────────────────────────────

DrillReportData _makeDrillData({required List<DrillDayRow> dayRows}) {
  return DrillReportData(
    heatmap: DrillHeatmapData(
      grid: List.generate(7, (_) => List<double?>.filled(24, null)),
      weekdayLabels: const ['월', '화', '수', '목', '금', '토', '일'],
    ),
    dayRows: dayRows,
    weekCaption: '5월 1주차 · 5/4 ~ 5/10',
  );
}

// ── 테스트 위젯 빌더 ──────────────────────────────────────────

Widget _buildDrillScreen(DrillReportData drillData) {
  final router = GoRouter(
    initialLocation: '/report/details',
    routes: [
      GoRoute(
        path: '/report/details',
        builder: (_, __) => const ReportDrillScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWith((_) => _FakeProfileRepo()),
      drillReportProvider.overrideWith((ref) async => drillData),
      weekReportProvider.overrideWith((ref) async => WeekReportData(
        weekCaption: '5월 1주차 · 5/4 ~ 5/10',
        state: WeekReportState.normal,
        dangerHours: 3,
        days: List.generate(7, (i) => DayCalendarData(
          date: DateTime(2026, 5, 4).add(Duration(days: i)),
          weekdayLabel: ['월', '화', '수', '목', '금', '토', '일'][i],
          peakRatio: 0.6,
          hasData: true,
        )),
        pattern: null,
        updatedTimeLabel: '14:02 갱신',
        currentFinalRatio: 0.8,
      )),
      dustDataProvider.overrideWith((ref) async => null),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── 테스트 ─────────────────────────────────────────────────────

void main() {
  group('ReportDrillScreen _DayRow 위젯 검증 (K-2)', () {
    testWidgets('peakPm25 = 52 → "52㎍" 텍스트 표시', (tester) async {
      final data = _makeDrillData(dayRows: [
        const DrillDayRow(
          dateLabel:         '월 · 5/4',
          hoursRange:        '14~17시',
          peakPm25:          52,
          peakRatio:         1.34,
          dangerRecordCount: 3,
        ),
      ]);

      await tester.pumpWidget(_buildDrillScreen(data));
      await tester.pumpAndSettle();

      // 우측 + 서브텍스트 모두 "52㎍" 포함
      expect(find.textContaining('52㎍'), findsWidgets);
    });

    testWidgets('ratio 숫자(1.34)가 단독 Text로 노출되지 않음', (tester) async {
      final data = _makeDrillData(dayRows: [
        const DrillDayRow(
          dateLabel:         '월 · 5/4',
          hoursRange:        '14~17시',
          peakPm25:          52,
          peakRatio:         1.34,
          dangerRecordCount: 3,
        ),
      ]);

      await tester.pumpWidget(_buildDrillScreen(data));
      await tester.pumpAndSettle();

      // ratio 숫자가 단독 Text로 렌더링되지 않아야 한다
      expect(find.text('1.34'), findsNothing);
    });

    testWidgets('peakPm25 = null → "—" 표시', (tester) async {
      final data = _makeDrillData(dayRows: [
        const DrillDayRow(
          dateLabel:         '화 · 5/5',
          hoursRange:        '—',
          peakPm25:          null,
          peakRatio:         0.5,
          dangerRecordCount: 0,
        ),
      ]);

      await tester.pumpWidget(_buildDrillScreen(data));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
    });

    testWidgets('dayRows 비어있으면 "일별 상세" 섹션 숨김', (tester) async {
      final data = _makeDrillData(dayRows: []);

      await tester.pumpWidget(_buildDrillScreen(data));
      await tester.pumpAndSettle();

      expect(find.text('일별 상세'), findsNothing);
    });
  });
}
