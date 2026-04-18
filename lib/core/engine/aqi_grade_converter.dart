import 'dart:math';
import '../../data/models/aqi_record.dart';

/// 에어코리아 예보 등급 → PM2.5 수치 변환 + Spline 보간
///
/// 등급 중간값 기준 (spec 확정):
///   좋음     → 10 μg/m³
///   보통     → 25 μg/m³
///   나쁨     → 50 μg/m³
///   매우나쁨 → 85 μg/m³
class AqiGradeConverter {
  AqiGradeConverter._();

  static const _midvalues = <String, double>{
    '좋음':     10.0,
    '보통':     25.0,
    '나쁨':     50.0,
    '매우나쁨': 85.0,
  };

  /// 예보 등급 문자열 → 중간값
  static double gradeToMidvalue(String? grade) =>
      _midvalues[grade?.trim()] ?? 25.0;

  /// PM2.5 정수값 → 등급 문자열
  static String valueToGrade(int? value) {
    if (value == null) return '보통';
    if (value <= 15)  return '좋음';
    if (value <= 35)  return '보통';
    if (value <= 75)  return '나쁨';
    return '매우나쁨';
  }

  // ── Spline 보간 ────────────────────────────────────────────

  /// 현재 실측값에서 미래 예보 등급까지 Cubic Hermite Spline 보간
  ///
  /// [startValue]   : 현재 PM2.5 (실측)
  /// [targetGrade]  : 향후 예보 등급 (중간값으로 변환)
  /// [startTime]    : 현재 시점
  /// [horizonHours] : 예측 범위 (기본 3시간)
  /// [intervalMin]  : 보간 간격 (기본 30분)
  ///
  /// 반환: [(시각, PM2.5 예측값)] 리스트 — startTime 제외, 미래 점만 포함
  static List<({DateTime time, double pm25})> interpolateFuture({
    required double startValue,
    required String targetGrade,
    required DateTime startTime,
    int horizonHours = 3,
    int intervalMin = 30,
  }) {
    final target = gradeToMidvalue(targetGrade);
    final steps = (horizonHours * 60) ~/ intervalMin;
    final result = <({DateTime time, double pm25})>[];

    for (int i = 1; i <= steps; i++) {
      final t = i / steps; // 0→1 진행률
      final value = _cubicEase(startValue, target, t);
      result.add((
        time: startTime.add(Duration(minutes: i * intervalMin)),
        pm25: value.clamp(0.0, 500.0),
      ));
    }
    return result;
  }

  /// Cubic Hermite easing: 부드러운 S-curve
  /// 선형 보간보다 자연스러운 곡선 생성
  static double _cubicEase(double from, double to, double t) {
    final smoothT = t * t * (3 - 2 * t); // smoothstep
    return from + (to - from) * smoothT;
  }

  // ── 차트 데이터 통합 ────────────────────────────────────────

  /// SQLite 기록 + 미래 예측을 하나의 차트 포인트 리스트로 통합
  ///
  /// [pastRecords]  : SQLite에서 읽은 과거/현재 기록 (시간 오름차순)
  /// [targetGrade]  : 미래 예보 등급
  /// [horizonHours] : 미래 예측 범위 (기본 3시간)
  static List<ChartPoint> buildChartPoints({
    required List<AqiRecord> pastRecords,
    required String targetGrade,
    int horizonHours = 3,
  }) {
    final points = <ChartPoint>[];

    // 과거 실측 데이터
    for (final r in pastRecords) {
      points.add(ChartPoint(
        time: r.dataTime,
        pm25: r.pm25Value?.toDouble(),
        isForecast: false,
      ));
    }

    // 미래 예측 (마지막 실측값 기준 Spline 보간)
    if (pastRecords.isNotEmpty) {
      final last = pastRecords.last;
      final lastPm25 = last.pm25Value?.toDouble() ?? gradeToMidvalue(targetGrade);
      final future = interpolateFuture(
        startValue: lastPm25,
        targetGrade: targetGrade,
        startTime: last.dataTime,
        horizonHours: horizonHours,
      );
      for (final f in future) {
        points.add(ChartPoint(time: f.time, pm25: f.pm25, isForecast: true));
      }
    }

    return points;
  }
}

/// 차트용 단일 데이터 포인트
class ChartPoint {
  final DateTime time;

  /// PM2.5 값 — null이면 데이터 누락 구간 (차트에서 점선 처리)
  final double? pm25;

  /// true = 예측값 (반투명 + 점선), false = 실측값
  final bool isForecast;

  const ChartPoint({
    required this.time,
    required this.pm25,
    required this.isForecast,
  });
}
