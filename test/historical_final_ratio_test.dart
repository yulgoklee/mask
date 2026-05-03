import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/utils/dust_calculator.dart';

void main() {
  group('DustCalculator.computeHistoricalFinalRatio', () {
    // T_final=35.0 기준 (T_pm10 = 35 × 80/35 = 80.0)
    const tFinal = 35.0;

    test('정상 — PM2.5만 있을 때 pm25/tFinal 반환', () {
      // pm25=35 → ratio=1.0, pm10=null → 0.0 → max=1.0
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: tFinal,
        pm25: 35,
        pm10: null,
      );
      expect(ratio, closeTo(1.0, 1e-6));
    });

    test('정상 — PM10이 지배적일 때 pm10 비율이 max', () {
      // pm25=10 → ratio=10/35≈0.286
      // pm10=100 → ratio=100/80=1.25 → max=1.25
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: tFinal,
        pm25: 10,
        pm10: 100,
      );
      expect(ratio, closeTo(100.0 / 80.0, 1e-6));
    });

    test('정상 — PM2.5가 지배적일 때 pm25 비율이 max', () {
      // pm25=70 → ratio=70/35=2.0
      // pm10=50 → ratio=50/80=0.625 → max=2.0
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: tFinal,
        pm25: 70,
        pm10: 50,
      );
      expect(ratio, closeTo(2.0, 1e-6));
    });

    test('null pm25 — 0으로 처리 → pm10만으로 계산', () {
      // pm25=null → 0 → ratio=0.0
      // pm10=80 → ratio=80/80=1.0 → max=1.0
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: tFinal,
        pm25: null,
        pm10: 80,
      );
      expect(ratio, closeTo(1.0, 1e-6));
    });

    test('null pm25 + null pm10 — 0.0 반환', () {
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: tFinal,
        pm25: null,
        pm10: null,
      );
      expect(ratio, 0.0);
    });

    test('pm25=0 — 0.0 반환 (pm10=null)', () {
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: tFinal,
        pm25: 0,
        pm10: null,
      );
      expect(ratio, 0.0);
    });

    test('tFinalPm25=0 — divide-by-zero 방지, 0.0 반환', () {
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: 0.0,
        pm25: 50,
        pm10: 80,
      );
      expect(ratio, 0.0);
    });

    test('tFinalPm25 음수 — 0.0 반환', () {
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: -5.0,
        pm25: 50,
        pm10: 80,
      );
      expect(ratio, 0.0);
    });

    test('정밀화 — T_final=29.75 (비염 프로필) 기준 검증', () {
      // T_final=29.75, pm25=30 → ratio≈1.008
      // T_pm10=29.75×(80/35)≈68.0, pm10=50 → ratio≈0.735 → max≈1.008
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: 29.75,
        pm25: 30,
        pm10: 50,
      );
      final expected = 30.0 / 29.75;
      expect(ratio, closeTo(expected, 1e-4));
    });
  });
}
