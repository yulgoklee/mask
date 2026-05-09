import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/utils/dust_calculator.dart';
import 'package:mask_alert/features/report_tab/models/report_models.dart';

// ── weekReportProvider 내 핵심 로직을 순수 함수로 분리해 검증 ──
//
// Provider 자체(Riverpod + SQLite)는 통합 테스트 영역이므로,
// 핵심 비즈니스 로직(dangerHours 계산, state 결정)을 재현해 검증한다.

// ── dangerHours 계산 헬퍼 재현 ──────────────────────────────────
int _computeDangerHours({
  required List<({String dataTime, int pm25, int? pm10})> records,
  required double tFinalPm25,
}) {
  final dangerHourSet = <String>{};
  for (final r in records) {
    final dt = DateTime.tryParse(r.dataTime);
    if (dt == null) continue;
    final ratio = DustCalculator.computeHistoricalFinalRatio(
      tFinalPm25: tFinalPm25,
      pm25: r.pm25,
      pm10: r.pm10,
    );
    if (ratio >= 1.0) {
      final dayStr = '${dt.year}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
      final hourKey = '$dayStr ${dt.hour.toString().padLeft(2, '0')}';
      dangerHourSet.add(hourKey);
    }
  }
  return dangerHourSet.length;
}

// ── state 결정 로직 재현 ──────────────────────────────────────────
WeekReportState _computeState(int dangerHours, int daysWithData) {
  if (daysWithData < 3) return WeekReportState.empty;
  if (dangerHours > 0) return WeekReportState.normal;
  return WeekReportState.safe;
}

void main() {
  const tFinal = 35.0; // 일반인 임계치

  group('dangerHours = 고유 시간대 카운트 검증', () {
    test('같은 시간대 복수 레코드 → 1 카운트', () {
      final records = [
        (dataTime: '2026-05-04T14:00:00', pm25: 40, pm10: null),
        (dataTime: '2026-05-04T14:30:00', pm25: 42, pm10: null),
        // 같은 날 14시 → hourKey: '2026-05-04 14' 중복 → 1
      ];
      final hours = _computeDangerHours(records: records, tFinalPm25: tFinal);
      expect(hours, 1);
    });

    test('서로 다른 시간대 → 각각 카운트', () {
      final records = [
        (dataTime: '2026-05-04T14:00:00', pm25: 40, pm10: null),
        (dataTime: '2026-05-04T15:00:00', pm25: 38, pm10: null),
        (dataTime: '2026-05-05T14:00:00', pm25: 41, pm10: null),
        // 3개 다른 hourKey → 3
      ];
      final hours = _computeDangerHours(records: records, tFinalPm25: tFinal);
      expect(hours, 3);
    });

    test('ratio < 1.0 레코드는 제외', () {
      // tFinal=35, pm25=30 → ratio=30/35=0.857 < 1.0 → 제외
      final records = [
        (dataTime: '2026-05-04T14:00:00', pm25: 30, pm10: null),
        (dataTime: '2026-05-04T15:00:00', pm25: 40, pm10: null), // ratio=40/35=1.14 ≥ 1.0
      ];
      final hours = _computeDangerHours(records: records, tFinalPm25: tFinal);
      expect(hours, 1);
    });

    test('위험 레코드 없음 → 0', () {
      final records = [
        (dataTime: '2026-05-04T14:00:00', pm25: 20, pm10: null),
        (dataTime: '2026-05-05T10:00:00', pm25: 15, pm10: null),
      ];
      final hours = _computeDangerHours(records: records, tFinalPm25: tFinal);
      expect(hours, 0);
    });
  });

  group('state 분기 검증', () {
    test('daysWithData < 3 → empty (dangerHours 무관)', () {
      expect(_computeState(5, 2), WeekReportState.empty);
      expect(_computeState(0, 1), WeekReportState.empty);
    });

    test('daysWithData >= 3, dangerHours > 0 → normal', () {
      expect(_computeState(6, 7), WeekReportState.normal);
      expect(_computeState(1, 3), WeekReportState.normal);
    });

    test('daysWithData >= 3, dangerHours = 0 → safe', () {
      expect(_computeState(0, 7), WeekReportState.safe);
      expect(_computeState(0, 3), WeekReportState.safe);
    });
  });

  group('station null/empty → empty 처리', () {
    test('station null이면 WeekReportData.empty() 반환해야 함', () {
      // WeekReportData.empty() 팩토리가 7개 DayCalendarData 생성하는지 검증
      final data = WeekReportData.empty();
      expect(data.state, WeekReportState.empty);
      expect(data.days.length, 7);
      expect(data.dangerHours, 0);
      expect(data.pattern, isNull);
      expect(data.currentFinalRatio, 0.0);
    });

    test('WeekReportData.empty()의 weekCaption 형식 검증', () {
      final data = WeekReportData.empty();
      // "M월 N주차 · M/D ~ M/D" 형식
      expect(data.weekCaption, matches(r'\d+월 \d+주차 · \d+/\d+ ~ \d+/\d+'));
    });
  });

  group('SQLite weekday → Dart dartIdx 변환 검증', () {
    // drillReportProvider 내 변환 로직:
    // dartIdx = sqliteWeekday == 0 ? 6 : sqliteWeekday - 1
    // SQLite %w: 0=일, 1=월, 2=화, ..., 6=토
    // Dart 목표: 0=월, 1=화, ..., 5=토, 6=일
    int toDartIdx(int sqliteWeekday) =>
        sqliteWeekday == 0 ? 6 : sqliteWeekday - 1;

    test('0(일) → 6 (마지막)', () => expect(toDartIdx(0), 6));
    test('1(월) → 0 (처음)',   () => expect(toDartIdx(1), 0));
    test('2(화) → 1',         () => expect(toDartIdx(2), 1));
    test('6(토) → 5',         () => expect(toDartIdx(6), 5));
    test('3(수) → 2',         () => expect(toDartIdx(3), 2));
    test('4(목) → 3',         () => expect(toDartIdx(4), 3));
    test('5(금) → 4',         () => expect(toDartIdx(5), 4));
  });

  group('firstActiveDate 이전 데이터 제외', () {
    test('firstActiveDate 이후 레코드만 dangerHours 집계', () {
      final firstActive = DateTime(2026, 5, 5); // 화요일
      final records = [
        (dataTime: '2026-05-04T14:00:00', pm25: 40, pm10: null), // 월(firstActive 전) → 제외
        (dataTime: '2026-05-05T14:00:00', pm25: 40, pm10: null), // 화(firstActive 당일) → 포함
        (dataTime: '2026-05-06T14:00:00', pm25: 40, pm10: null), // 수 → 포함
      ];

      // firstActiveDate 이전 필터 적용 버전
      int dangerHoursFiltered = 0;
      final dangerHourSet = <String>{};
      for (final r in records) {
        final dt = DateTime.tryParse(r.dataTime);
        if (dt == null) continue;
        final dateOnly = DateTime(dt.year, dt.month, dt.day);
        if (dateOnly.isBefore(firstActive)) continue;
        final ratio = DustCalculator.computeHistoricalFinalRatio(
          tFinalPm25: tFinal,
          pm25: r.pm25,
          pm10: r.pm10,
        );
        if (ratio >= 1.0) {
          final dayStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          final hourKey = '$dayStr ${dt.hour.toString().padLeft(2, '0')}';
          dangerHourSet.add(hourKey);
        }
      }
      dangerHoursFiltered = dangerHourSet.length;

      // 월요일 제외 → 화·수 2개만
      expect(dangerHoursFiltered, 2);
    });
  });
}
