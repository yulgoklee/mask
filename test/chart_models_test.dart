import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/care/models/care_models.dart';

// ── 헬퍼 ─────────────────────────────────────────────────

ChartPoint _pt(double hour, double ratio, {double rawPm25 = 20.0}) =>
    ChartPoint(
      hour:       hour,
      finalRatio: ratio,
      rawPm25:    rawPm25,
      isForecast: hour > 0,
    );

// ── 테스트 ────────────────────────────────────────────────

void main() {
  // ── 1. buildChartVerdict (§3.3 v4) ───────────────────
  group('buildChartVerdict (§3.3 v4)', () {
    test('포인트 0개 → unknown', () {
      expect(buildChartVerdict([]), ChartVerdict.unknown);
    });

    test('포인트 1개 → unknown (최소 2개 필요)', () {
      expect(buildChartVerdict([_pt(0, 0.5)]), ChartVerdict.unknown);
    });

    test('전체 포인트 < 1.0 → safe', () {
      final pts = [_pt(0, 0.4), _pt(6, 0.6), _pt(12, 0.8)];
      expect(buildChartVerdict(pts), ChartVerdict.safe);
    });

    test('peakRatio 정확히 0.999 → safe', () {
      final pts = [_pt(0, 0.5), _pt(12, 0.999)];
      expect(buildChartVerdict(pts), ChartVerdict.safe);
    });

    test('전체 포인트 ≥ 1.0 (h=0 포함) → fullDay', () {
      final pts = [_pt(0, 1.0), _pt(6, 1.5), _pt(12, 2.0)];
      expect(buildChartVerdict(pts), ChartVerdict.fullDay);
    });

    test('fullDay: 첫 포인트가 정확히 1.0 → fullDay', () {
      final pts = [_pt(0, 1.0), _pt(12, 1.0)];
      expect(buildChartVerdict(pts), ChartVerdict.fullDay);
    });

    test('부분 초과 + 상승 (last > first) → partialIncreasing', () {
      // 현재 안전, 나중에 기준 초과
      final pts = [_pt(0, 0.5), _pt(6, 1.2), _pt(12, 1.5)];
      expect(buildChartVerdict(pts), ChartVerdict.partialIncreasing);
    });

    test('부분 초과 + 하락 (last < first) → partialDecreasing', () {
      // 현재 기준 초과, 나중에 안전
      final pts = [_pt(0, 1.5), _pt(6, 1.2), _pt(12, 0.5)];
      expect(buildChartVerdict(pts), ChartVerdict.partialDecreasing);
    });

    test('부분 초과 + 평탄 (last == first) → partialDecreasing (상승 아님)', () {
      final pts = [_pt(0, 0.5), _pt(6, 1.5), _pt(12, 0.5)];
      // isIncreasing = false (0.5 == 0.5) → partialDecreasing
      expect(buildChartVerdict(pts), ChartVerdict.partialDecreasing);
    });

    test('h=0 < 1.0 but peak >= 1.0 + 상승 → partialIncreasing', () {
      final pts = [_pt(0, 0.8), _pt(6, 1.3), _pt(12, 1.6)];
      expect(buildChartVerdict(pts), ChartVerdict.partialIncreasing);
    });
  });

  // ── 3. buildChartPoints (§2.9 v4) ────────────────────
  group('buildChartPoints (§2.9 v4)', () {
    const tFinalPm25 = 35.0;

    test('h=0 포인트: rawPm25 = currentPm25', () {
      final pts = buildChartPoints(
        tFinalPm25:  tFinalPm25,
        currentPm25: 20.0,
      );
      expect(pts.first.rawPm25, closeTo(20.0, 0.001));
      expect(pts.first.hour,    0.0);
      expect(pts.first.isForecast, false);
    });

    test('13개 포인트 생성 (h=0~12)', () {
      final pts = buildChartPoints(
        tFinalPm25:  tFinalPm25,
        currentPm25: 15.0,
      );
      expect(pts.length, 13);
      expect(pts.last.hour, 12.0);
    });

    test('h>0 포인트: isForecast = true', () {
      final pts = buildChartPoints(
        tFinalPm25:  tFinalPm25,
        currentPm25: 15.0,
      );
      for (final p in pts.skip(1)) {
        expect(p.isForecast, true,
            reason: 'h=${p.hour} 포인트는 isForecast이어야 함');
      }
    });

    test('h=0: PM10 실측 반영 → rawPm10 != null', () {
      final pts = buildChartPoints(
        tFinalPm25:  tFinalPm25,
        currentPm25: 15.0,
        currentPm10: 60,
      );
      expect(pts.first.rawPm10, 60.0);
    });

    test('h>0: rawPm10 == null (PM10 예보 없음)', () {
      final pts = buildChartPoints(
        tFinalPm25:  tFinalPm25,
        currentPm25: 15.0,
        currentPm10: 60,
      );
      for (final p in pts.skip(1)) {
        expect(p.rawPm10, null,
            reason: 'h=${p.hour}: 예보 구간 PM10 없음');
      }
    });

    test('PM10이 dominant일 때 h=0 finalRatio > pm25만의 ratio', () {
      // PM2.5=10 (ratio=10/35≈0.286), PM10=100 (ratio=100/80=1.25) → PM10 dominant
      final pts = buildChartPoints(
        tFinalPm25:  tFinalPm25,
        currentPm25: 10.0,
        currentPm10: 100,
      );
      final expected = 100.0 / (tFinalPm25 * (80.0 / 35.0)); // ≈ 1.25
      expect(pts.first.finalRatio, closeTo(expected, 0.001));
    });

    test('PM10 없을 때 h=0: ratioPm10=0 → PM2.5만으로 계산', () {
      final pts = buildChartPoints(
        tFinalPm25:  tFinalPm25,
        currentPm25: 20.0,
      );
      final expectedRatio = 20.0 / tFinalPm25; // ≈ 0.571
      expect(pts.first.finalRatio, closeTo(expectedRatio, 0.001));
    });

    test('cubic smoothstep: h=0 → currentPm25, h=12 → forecastMid', () {
      final pts = buildChartPoints(
        tFinalPm25:   tFinalPm25,
        currentPm25:  10.0,
        forecastGrade: '나쁨', // midpoint=55
      );
      expect(pts.first.rawPm25,  closeTo(10.0, 0.001));
      expect(pts.last.rawPm25,   closeTo(55.0, 0.001));
    });

    test('forecastGrade null → midpoint=25 (보통 기본값)', () {
      final pts = buildChartPoints(
        tFinalPm25:  tFinalPm25,
        currentPm25: 10.0,
      );
      expect(pts.last.rawPm25, closeTo(25.0, 0.001));
    });

    test('finalRatio clamp: 극단적 수치도 0~10 범위', () {
      final pts = buildChartPoints(
        tFinalPm25:  tFinalPm25,
        currentPm25: 1000.0, // 비정상 수치
      );
      for (final p in pts) {
        expect(p.finalRatio, inInclusiveRange(0.0, 10.0));
      }
    });
  });

  // ── 4. gradeToMidpoint (§3.3 v4) ─────────────────────
  group('gradeToMidpoint', () {
    test('좋음 → 8.0',    () => expect(gradeToMidpoint('좋음'),    8.0));
    test('보통 → 25.0',   () => expect(gradeToMidpoint('보통'),    25.0));
    test('나쁨 → 55.0',   () => expect(gradeToMidpoint('나쁨'),    55.0));
    test('매우나쁨 → 90.0', () => expect(gradeToMidpoint('매우나쁨'), 90.0));
    test('null → 25.0 (기본값)', () => expect(gradeToMidpoint(null), 25.0));
    test('unknown → 25.0 (기본값)', () => expect(gradeToMidpoint('unknown'), 25.0));
  });

  // ── 5. ProtectionChartData.isCurrentOverThreshold ─────
  group('isCurrentOverThreshold (ratio 기반)', () {
    test('첫 포인트 ratio=0.9 → false', () {
      final data = ProtectionChartData(
        chartPoints: [_pt(0, 0.9)],
        tFinal:      35,
        filterRate:  0.94,
        verdict:     ChartVerdict.safe,
        hasForecastData: false,
        generatedAt: DateTime.now(),
      );
      expect(data.isCurrentOverThreshold, false);
    });

    test('첫 포인트 ratio=1.0 → true', () {
      final data = ProtectionChartData(
        chartPoints: [_pt(0, 1.0)],
        tFinal:      35,
        filterRate:  0.94,
        verdict:     ChartVerdict.fullDay,
        hasForecastData: false,
        generatedAt: DateTime.now(),
      );
      expect(data.isCurrentOverThreshold, true);
    });

    test('chartPoints 비어있으면 false', () {
      final data = ProtectionChartData.noData();
      expect(data.isCurrentOverThreshold, false);
    });
  });

  // ── 6. buildFlowText (§4 v1) ─────────────────────────

  // 13포인트(h=0~12) 생성: splitAt 이전/이후로 ratio 분기
  List<ChartPoint> _pts13({required int splitAt, required bool startSafe}) =>
      List.generate(13, (h) => _pt(
            h.toDouble(),
            (startSafe ? h < splitAt : h >= splitAt) ? 0.3 : 0.9,
          ));

  group('buildFlowText (§4 v1)', () {
    // ── Case 1: 전체 안전 ────────────────────────────────
    test('전체 안전 (모든 ratio < 0.7) → 12시간 동안 안전해요', () {
      final points = List.generate(13, (h) => _pt(h.toDouble(), 0.5));
      final result = buildFlowText(points, DateTime(2024, 1, 1, 9, 0));
      expect(result, '12시간 동안 안전해요');
    });

    // ── Case 2: 전체 주의 ────────────────────────────────
    test('전체 주의 (모든 ratio >= 0.7) → 오늘 종일 주의가 필요해요', () {
      final points = List.generate(13, (h) => _pt(h.toDouble(), 0.9));
      final result = buildFlowText(points, DateTime(2024, 1, 1, 9, 0));
      expect(result, '오늘 종일 주의가 필요해요');
    });

    // ── Case 3: 안전 → 주의 전환, 다른 시간대 ────────────
    // now=오전9시: h=2→오전11시(오전), h=3→낮12시(낮) — 전환 시 시간대 달라짐
    test('안전→주의 전환, 다른 시간대 → {A}까지 안전 → {B}부터 주의', () {
      // h=0~2: safe(0.3), h=3~12: warn(0.9) — i=3에서 전환
      final points = _pts13(splitAt: 3, startSafe: true);
      final result = buildFlowText(points, DateTime(2024, 1, 1, 9, 0));
      expect(result, '오전까지 안전 → 낮부터 주의');
    });

    // ── Case 4: 주의 → 안전 전환, 다른 시간대 ────────────
    // now=오전9시: 동일 기준 — i=3 전환
    test('주의→안전 전환, 다른 시간대 → {A}까지 주의 → {B}부터 안전', () {
      // h=0~2: warn(0.9), h=3~12: safe(0.3) — i=3에서 전환
      final points = _pts13(splitAt: 3, startSafe: false);
      final result = buildFlowText(points, DateTime(2024, 1, 1, 9, 0));
      expect(result, '오전까지 주의 → 낮부터 안전');
    });

    // ── Case 5: 동일 시간대 중복 fallback ────────────────
    // now=오후1시(낮): h=3→낮(16시), h=4→낮(17시) — 전환 전후 모두 "낮"
    // _nextDifferentLabel('낮'): h=4→낮(동일), h=8→저녁(다름) → '저녁'
    test('동일 시간대 중복 — nextDifferentLabel fallback → 지금은 안전, 저녁부터 주의 😷', () {
      // h=0~3: safe(0.3), h=4~12: warn(0.9) — i=4에서 전환
      final points = _pts13(splitAt: 4, startSafe: true);
      final result = buildFlowText(points, DateTime(2024, 1, 1, 13, 0));
      expect(result, '지금은 안전, 저녁부터 주의 😷');
    });
  });

  // ── 7. pollutantCopy ─────────────────────────────────
  group('pollutantCopy', () {
    test('ratio=0.3 → 여유롭게 숨 쉴 수 있어요',
        () => expect(pollutantCopy(0.3), '여유롭게 숨 쉴 수 있어요'));
    test('ratio=0.6 → 괜찮은 편이에요',
        () => expect(pollutantCopy(0.6), '괜찮은 편이에요'));
    test('ratio=0.85 → 조금 신경 써야 할 정도예요',
        () => expect(pollutantCopy(0.85), '조금 신경 써야 할 정도예요'));
    test('ratio=1.2 → 마스크가 필요해요',
        () => expect(pollutantCopy(1.2), '마스크가 필요해요'));
    test('ratio=2.0 → 꼭 마스크를 착용하세요',
        () => expect(pollutantCopy(2.0), '꼭 마스크를 착용하세요'));
  });

  // ── 8. pollutantEmoji ────────────────────────────────
  group('pollutantEmoji', () {
    test('ratio=0.3 → 😊', () => expect(pollutantEmoji(0.3), '😊'));
    test('ratio=0.6 → 🙂', () => expect(pollutantEmoji(0.6), '🙂'));
    test('ratio=0.85 → 😐', () => expect(pollutantEmoji(0.85), '😐'));
    test('ratio=1.2 → 😷', () => expect(pollutantEmoji(1.2), '😷'));
    test('ratio=2.0 → 😨', () => expect(pollutantEmoji(2.0), '😨'));
  });
}
