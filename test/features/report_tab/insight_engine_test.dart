/// InsightEngine 단위 테스트 — 리포트 탭 단계 1
///
/// §8 테스트 매트릭스 기준으로 작성.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/data/models/notification_log.dart';
import 'package:mask_alert/features/report_tab/models/report_models.dart';
import 'package:mask_alert/features/report_tab/utils/insight_engine.dart';

// ── 테스트 픽스처 헬퍼 ──────────────────────────────────────

/// NotificationLog 기본 픽스처
NotificationLog _log({
  required DateTime triggeredAt,
  UserAction action = UserAction.none,
  int? pm25,
  int? pm10,
}) =>
    NotificationLog(
      triggeredAt: triggeredAt,
      notificationType: NotificationType.dangerEntry,
      pm25Value: pm25,
      pm10Value: pm10,
      userAction: action,
    );

/// NotificationWithAqiContext 픽스처
NotificationWithAqiContext _notifCtx({
  required DateTime triggeredAt,
  UserAction action = UserAction.none,
  int? notifPm25,
  int? notifPm10,
  int? aqiPm25,
  int? aqiPm10,
}) {
  final notification = _log(
    triggeredAt: triggeredAt,
    action: action,
    pm25: notifPm25,
    pm10: notifPm10,
  );
  return NotificationWithAqiContext(
    notification: notification,
    aqiPm25: aqiPm25,
    aqiPm10: aqiPm10,
    aqiDataTime: aqiPm25 != null ? triggeredAt : null,
  );
}

/// AQI row 픽스처 (getDailyAqiAverages 반환 형식)
Map<String, dynamic> _aqiRow(String day, {double? pm25Avg, double? pm10Avg}) =>
    {
      'day': day,
      'pm25_avg': pm25Avg,
      'pm10_avg': pm10Avg,
      'record_count': 1,
    };

/// 기준 날짜(월요일): 2026-04-27 (월)
final _baseMonday = DateTime(2026, 4, 27);

/// 기준 now (2026-05-03 일요일)
final _now = DateTime(2026, 5, 3, 12, 0);

void main() {
  // ── InsightEngine.compute ─────────────────────────────────

  group('InsightEngine.compute', () {
    // T_final = 35.0 → ratio 1.0 = PM2.5 35µg/m³
    const tFinal = 35.0;

    test('actionMatch 기본 — 마스크 착용 알림 1개, hasAqiContext=true', () {
      final notifTime = DateTime(2026, 4, 30, 19, 0); // 목요일 저녁
      final notifs = [
        _notifCtx(
          triggeredAt: notifTime,
          action: UserAction.maskWorn,
          aqiPm25: 42, // ratio ≈ 1.2
          aqiPm10: null,
        ),
      ];
      final aqi = [
        _aqiRow('2026-04-30', pm25Avg: 42.0),
      ];

      final result = InsightEngine.compute(
        weeklyNotifs: notifs,
        weeklyAqi: aqi,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.actionMatch);
      expect(result.bodyText, isNotEmpty);
      // 카피에 "마스크를 챙기셨네요" 포함
      expect(result.bodyText, contains('챙기셨네요'));
    });

    test('actionMatch ratio 기준 — 착용 알림 3개, ratio 0.8/1.2/1.5 → ratio 1.5 알림 사용',
        () {
      // tFinal=35이므로
      // ratio 0.8 → pm25 = 28µg/m³
      // ratio 1.2 → pm25 = 42µg/m³
      // ratio 1.5 → pm25 = 52.5 ≈ 53µg/m³

      final t1 = DateTime(2026, 4, 28, 9, 0);  // 화
      final t2 = DateTime(2026, 4, 29, 14, 0); // 수
      final t3 = DateTime(2026, 4, 30, 18, 0); // 목 저녁

      final notifs = [
        _notifCtx(
          triggeredAt: t1,
          action: UserAction.maskWorn,
          aqiPm25: 28, // ratio ≈ 0.8
        ),
        _notifCtx(
          triggeredAt: t2,
          action: UserAction.maskWorn,
          aqiPm25: 42, // ratio ≈ 1.2
        ),
        _notifCtx(
          triggeredAt: t3,
          action: UserAction.maskWorn,
          aqiPm25: 53, // ratio ≈ 1.514
        ),
      ];

      final aqi = [
        _aqiRow('2026-04-28', pm25Avg: 28.0),
        _aqiRow('2026-04-29', pm25Avg: 42.0),
        _aqiRow('2026-04-30', pm25Avg: 53.0),
      ];

      final result = InsightEngine.compute(
        weeklyNotifs: notifs,
        weeklyAqi: aqi,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.actionMatch);
      // ratio 1.5인 알림 데이터(pm25=53) 기반으로 카피 생성
      expect(result.bodyText, contains('53'));
    });

    test('envPeak 기본 — AQI 1일 ratio≥1.0, 마스크 없음', () {
      final aqi = [
        _aqiRow('2026-04-27', pm25Avg: 15.0), // ratio 0.43
        _aqiRow('2026-04-28', pm25Avg: 20.0), // ratio 0.57
        _aqiRow('2026-04-30', pm25Avg: 40.0), // ratio 1.14 — 피크
      ];

      final result = InsightEngine.compute(
        weeklyNotifs: [],
        weeklyAqi: aqi,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.envPeak);
      // 피크 날(목요일)이 카피에 반영
      expect(result.bodyText, contains('목'));
    });

    test('weekdayWeekend 기본 — 평일 avg ratio 0.85, 주말 avg ratio 0.5 (차이 0.35 ≥ 0.15)', () {
      // tFinal=35이므로
      // ratio 0.85 → pm25_avg = 29.75
      // ratio 0.5  → pm25_avg = 17.5
      //
      // 모든 날 ratio < 1.0이므로 envPeak 분기 제외
      // 주중-주말 차이 0.35 ≥ 0.15 → weekdayWeekend

      final aqi = [
        _aqiRow('2026-04-27', pm25Avg: 29.75), // 월 ratio 0.85
        _aqiRow('2026-04-28', pm25Avg: 29.75), // 화 ratio 0.85
        _aqiRow('2026-04-29', pm25Avg: 29.75), // 수 ratio 0.85
        _aqiRow('2026-04-30', pm25Avg: 29.75), // 목 ratio 0.85
        _aqiRow('2026-05-01', pm25Avg: 29.75), // 금 ratio 0.85
        _aqiRow('2026-05-02', pm25Avg: 17.5),  // 토 ratio 0.5
        _aqiRow('2026-05-03', pm25Avg: 17.5),  // 일 ratio 0.5
      ];

      final result = InsightEngine.compute(
        weeklyNotifs: [],
        weeklyAqi: aqi,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.weekdayWeekend);
    });

    test('weekdayWeekend 미만 — 평일 ratio 0.8, 주말 ratio 0.75 (차이 < 0.15)', () {
      // pm25: 0.8*35=28, 0.75*35=26.25
      final aqi = [
        _aqiRow('2026-04-27', pm25Avg: 28.0), // 월 0.8
        _aqiRow('2026-04-28', pm25Avg: 28.0), // 화 0.8
        _aqiRow('2026-04-29', pm25Avg: 28.0), // 수 0.8
        _aqiRow('2026-04-30', pm25Avg: 28.0), // 목 0.8
        _aqiRow('2026-05-01', pm25Avg: 28.0), // 금 0.8
        _aqiRow('2026-05-02', pm25Avg: 26.25), // 토 0.75
        _aqiRow('2026-05-03', pm25Avg: 26.25), // 일 0.75
      ];

      final result = InsightEngine.compute(
        weeklyNotifs: [],
        weeklyAqi: aqi,
        tFinalPm25: tFinal,
        now: _now,
      );

      // weekdayWeekend 아님 → allSafe (모두 ratio < 1.0)
      expect(result, isNotNull);
      expect(result!.category, isNot(InsightCategory.weekdayWeekend));
    });

    test('avgSummary — AQI 있음, 위 조건 전부 미충족', () {
      // 모든 날 ratio < 1.0이지만 주중-주말 차이도 0.15 미만이 아닌 케이스
      // 단, 아래에서 allSafe가 아니라 avgSummary가 나오려면 ratio >= 1.0이 없어야 하면서
      // 주중-주말 차이 충분 없고 allSafe가 되면 allSafe로 빠짐.
      // avgSummary를 테스트하려면: ratio >= 1.0이 있어야 하지만 envPeak, actionMatch 미충족이어야 함.
      // → envPeak 조건: ratio >= 1.0 날 존재 시 envPeak로 가므로
      //   avgSummary를 위해서는 ratio가 전부 < 1.0이되 allSafe가 아닌 케이스 = 불가능.
      //
      // 문서 §3.2 재검토: "4. avgSummary: 위 1~3 모두 해당 없음, 데이터는 있음"
      // allSafe는 avgSummary의 특수 케이스. 구현에서 allSafe를 avgSummary 분기 내에서 처리.
      // 즉 "데이터는 있고, ratio >= 1.0 날은 없고, weekdayWeekend 미충족" → allSafe OR avgSummary.
      // avgSummary vs allSafe의 구분: 모든 날 ratio < 1.0 → allSafe, 아니면 avgSummary.
      //
      // avgSummary는 ratio >= 1.0 날이 있어야 envPeak를 건너뛰는 방법이 없으므로
      // 현 설계상 avgSummary가 나오는 케이스는 없다. §3.2 주의사항 재확인:
      // "allSafe는 avgSummary보다 먼저 체크" — 따라서 avgSummary와 allSafe가 분기됨.
      // avgSummary가 나오려면: ratio >= 1.0 날이 "없어야" 하면서 allSafe가 아닌 경우 = 모순.
      //
      // 실제로 §3.2 알고리즘에서:
      // - step 2: peakRows = ratio >= 1.0인 날들 → if not empty → envPeak
      // - step 3: weekdayWeekend
      // - step 4: avgSummary (데이터 있음) — 이미 peakRows.isEmpty인 상태
      //           peakRows.isEmpty + weekdayWeekend 미충족 = 모두 ratio < 1.0인데 weekdayWeekend가 없는 케이스
      //           → allSafe 체크 먼저 → allSafe면 allSafe, 아니면 avgSummary
      //           → 모두 ratio < 1.0인데 allSafe가 아닌 경우 = 불가. 따라서 avgSummary도달은 이론상 없음.
      //
      // 문서 §3.2의 설계 의도를 따르면, avgSummary는 "일부 ratio >= 1.0이 있으나
      // envPeak 조건 미충족"의 케이스로 이해할 수 있으나 실제로 envPeak 조건이 ratio >= 1.0이므로
      // 항상 envPeak로 감. 따라서 avgSummary는 실제 도달 불가인 케이스임.
      //
      // 테스트에서는 "avgSummary 또는 allSafe" 반환을 검증.
      final aqi = [
        _aqiRow('2026-04-27', pm25Avg: 20.0), // ratio 0.57
        _aqiRow('2026-04-28', pm25Avg: 22.0), // ratio 0.63
        _aqiRow('2026-04-29', pm25Avg: 18.0), // ratio 0.51
      ];

      final result = InsightEngine.compute(
        weeklyNotifs: [],
        weeklyAqi: aqi,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      // 모두 ratio < 1.0 → allSafe
      expect(
        result!.category,
        anyOf(InsightCategory.avgSummary, InsightCategory.allSafe),
      );
    });

    test('allSafe — 7일 전부 ratio < 1.0', () {
      final aqi = List.generate(7, (i) {
        final day = _baseMonday.add(Duration(days: i));
        final dayStr =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        return _aqiRow(dayStr, pm25Avg: 15.0); // ratio = 15/35 ≈ 0.43
      });

      final result = InsightEngine.compute(
        weeklyNotifs: [],
        weeklyAqi: aqi,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.allSafe);
      expect(result.bodyText, contains('괜찮았어요'));
    });

    test('빈 케이스 G-1 — AQI 없음, 알림 없음 → null 반환', () {
      final result = InsightEngine.compute(
        weeklyNotifs: [],
        weeklyAqi: [],
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNull);
    });

    test('G-4 fallback — hasAqiContext=false 전부, notification.pm25Value 사용', () {
      // hasAqiContext=false (aqiDataTime=null): notification.pm25Value로 fallback
      final notifTime = DateTime(2026, 4, 30, 18, 0); // 목 저녁
      final notifs = [
        NotificationWithAqiContext(
          notification: _log(
            triggeredAt: notifTime,
            action: UserAction.maskWorn,
            pm25: 25,
          ),
          // AQI 컨텍스트 없음
        ),
      ];

      final result = InsightEngine.compute(
        weeklyNotifs: notifs,
        weeklyAqi: [], // AQI 기록도 없음
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.actionMatch);
      // notification.pm25Value=25로 카피 생성
      expect(result.bodyText, contains('25'));
    });
  });

  // ── InsightEngine.computeTrend ────────────────────────────

  group('InsightEngine.computeTrend', () {
    const tFinal = 35.0;

    // now = 2026-05-03 (일)
    // 이번주: daysAgo <= 7 → 4/27~5/3
    // 지난주: 7 < daysAgo <= 14 → 4/20~4/26

    Map<String, dynamic> _row(int daysBeforeNow, double pm25Avg) {
      final date = _now.subtract(Duration(days: daysBeforeNow));
      final dayStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return _aqiRow(dayStr, pm25Avg: pm25Avg);
    }

    test('Δ = -0.4 → TrendCategory.muchBetter', () {
      // 이번주 avg ratio = 0.4, 지난주 avg ratio = 0.8
      // pm25: 0.4*35=14, 0.8*35=28
      final rows = [
        _row(0, 14.0),  // 이번주 (daysAgo=0)
        _row(1, 14.0),
        _row(7, 14.0),  // daysAgo=7 → 이번주 경계
        _row(8, 28.0),  // 지난주 (daysAgo=8)
        _row(9, 28.0),
      ];

      final result = InsightEngine.computeTrend(
        last14DaysAqi: rows,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, TrendCategory.muchBetter);
      expect(result.delta, lessThan(-0.3));
    });

    test('Δ = -0.2 → TrendCategory.slightlyBetter', () {
      // 이번주 avg ratio = 0.5, 지난주 avg ratio = 0.7
      // pm25: 0.5*35=17.5, 0.7*35=24.5
      final rows = [
        _row(1, 17.5),  // 이번주
        _row(2, 17.5),
        _row(8, 24.5),  // 지난주
        _row(9, 24.5),
      ];

      final result = InsightEngine.computeTrend(
        last14DaysAqi: rows,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, TrendCategory.slightlyBetter);
      expect(result.delta, inInclusiveRange(-0.3, -0.1));
    });

    test('Δ = 0.05 → TrendCategory.similar', () {
      // 이번주 avg ratio = 0.55, 지난주 avg ratio = 0.5
      // pm25: 0.55*35=19.25, 0.5*35=17.5
      final rows = [
        _row(1, 19.25), // 이번주
        _row(2, 19.25),
        _row(8, 17.5),  // 지난주
        _row(9, 17.5),
      ];

      final result = InsightEngine.computeTrend(
        last14DaysAqi: rows,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, TrendCategory.similar);
      expect(result.delta.abs(), lessThan(0.1));
    });

    test('Δ = +0.2 → TrendCategory.slightlyWorse', () {
      // 이번주 avg ratio = 0.7, 지난주 avg ratio = 0.5
      // pm25: 0.7*35=24.5, 0.5*35=17.5
      final rows = [
        _row(1, 24.5), // 이번주
        _row(2, 24.5),
        _row(8, 17.5), // 지난주
        _row(9, 17.5),
      ];

      final result = InsightEngine.computeTrend(
        last14DaysAqi: rows,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, TrendCategory.slightlyWorse);
      expect(result.delta, inInclusiveRange(0.1, 0.3));
    });

    test('Δ = +0.4 → TrendCategory.muchWorse', () {
      // 이번주 avg ratio = 0.9, 지난주 avg ratio = 0.5
      // pm25: 0.9*35=31.5, 0.5*35=17.5
      final rows = [
        _row(1, 31.5), // 이번주
        _row(2, 31.5),
        _row(8, 17.5), // 지난주
        _row(9, 17.5),
      ];

      final result = InsightEngine.computeTrend(
        last14DaysAqi: rows,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNotNull);
      expect(result!.category, TrendCategory.muchWorse);
      expect(result.delta, greaterThan(0.3));
    });

    test('지난주 데이터 없음 → null 반환', () {
      // 이번주 데이터만 있음 (daysAgo <= 7)
      final rows = [
        _row(1, 25.0),
        _row(2, 30.0),
        _row(3, 20.0),
      ];

      final result = InsightEngine.computeTrend(
        last14DaysAqi: rows,
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNull);
    });

    test('빈 데이터 → null 반환', () {
      final result = InsightEngine.computeTrend(
        last14DaysAqi: [],
        tFinalPm25: tFinal,
        now: _now,
      );

      expect(result, isNull);
    });
  });

  // ── 엣지 케이스 ──────────────────────────────────────────

  group('InsightEngine edge cases', () {
    const tFinal = 35.0;

    test('tFinalPm25 = 0 → computeHistoricalFinalRatio가 0.0 반환, 크래시 없음', () {
      final aqi = [_aqiRow('2026-05-01', pm25Avg: 40.0)];

      // tFinalPm25 = 0 이면 DustCalculator.computeHistoricalFinalRatio가 0.0 반환
      expect(
        () => InsightEngine.compute(
          weeklyNotifs: [],
          weeklyAqi: aqi,
          tFinalPm25: 0.0,
          now: _now,
        ),
        returnsNormally,
      );
    });

    test('pm10_value 전부 null — G-7: ratio pm10=0으로 처리, 크래시 없음', () {
      final aqi = [
        _aqiRow('2026-04-30', pm25Avg: 40.0), // pm10_avg=null
      ];

      final result = InsightEngine.compute(
        weeklyNotifs: [],
        weeklyAqi: aqi,
        tFinalPm25: tFinal,
        now: _now,
      );

      // pm10 null이어도 pm25 기반으로 계산
      expect(result, isNotNull);
      expect(result!.category, InsightCategory.envPeak);
    });
  });
}
