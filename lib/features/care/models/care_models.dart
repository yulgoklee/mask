import '../../../core/constants/dust_standards.dart';
import '../../../core/utils/dust_calculator.dart';

// ── StatusCard 모델 ───────────────────────────────────────
// CardStatus enum 제거 — RiskLevel 직접 사용 (§2.4 v2 결정)

class StatusCardData {
  final RiskLevel status;
  final String emoji;
  final String title;

  /// 서브 카피 — 단문 강제 (§3.2 v3: \n 금지, 자연 wrap만 허용)
  final String subCopy;

  // ── 정보 바 데이터 (§3.2 v2) ──────────────────────────
  /// final_ratio를 결정한 오염물질 (PM2.5 or PM10)
  final DominantPollutant dominantPollutant;

  /// 지배 오염물질의 절대 농도 (µg/m³, int)
  final int dominantValue;

  /// 지배 오염물질의 개인화 임계치 (µg/m³)
  final double dominantTFinal;

  /// 지배 오염물질의 등급 라벨
  final DustGrade dominantGrade;

  // ── 참조용 수치 ───────────────────────────────────────
  final double pm25Value;
  final double? pm10Value;
  final double tFinal;

  /// max(pm25/T_pm25, pm10/T_pm10) — 정보 바 X% 메시지용
  final double finalRatio;

  /// sensitivity_multiplier — 위젯 표시 안 함, 하위 호환 유지
  final double sensitivityMultiplier;
  final String nickname;
  final int respiratoryStatus;

  const StatusCardData({
    required this.status,
    required this.emoji,
    required this.title,
    required this.subCopy,
    required this.dominantPollutant,
    required this.dominantValue,
    required this.dominantTFinal,
    required this.dominantGrade,
    required this.pm25Value,
    required this.pm10Value,
    required this.tFinal,
    required this.finalRatio,
    required this.sensitivityMultiplier,
    required this.nickname,
    required this.respiratoryStatus,
  });

  factory StatusCardData.placeholder() => const StatusCardData(
    status:              RiskLevel.unknown,
    emoji:               '⏳',
    title:               '데이터를 불러오는 중',
    subCopy:             '',
    dominantPollutant:   DominantPollutant.pm25,
    dominantValue:       0,
    dominantTFinal:      35.0,
    dominantGrade:       DustGrade.good,
    pm25Value:           0,
    pm10Value:           null,
    tFinal:              35,
    finalRatio:          0,
    sensitivityMultiplier: 1.0,
    nickname:            '',
    respiratoryStatus:   0,
  );
}

// ── ChartPoint ────────────────────────────────────────────

/// 차트 단일 포인트 — final_ratio 기반 (§2.9 v4)
///
/// 곡선(본체)은 finalRatio만 사용.
/// rawPm25 / rawPm10 은 그리드·툴팁 표시용 (µg/m³).
class ChartPoint {
  final double hour;        // 0.0 ~ 12.0
  final double finalRatio;  // max(pm25/T_pm25, pm10/T_pm10)
  final double rawPm25;     // µg/m³ — 그리드/툴팁 표시용
  final double? rawPm10;    // µg/m³ — 예보 구간에서 null
  final bool isForecast;    // h > 0 → 보간 데이터

  const ChartPoint({
    required this.hour,
    required this.finalRatio,
    required this.rawPm25,
    this.rawPm10,
    required this.isForecast,
  });
}

// ── ChartVerdict ──────────────────────────────────────────

/// 12시간 예보 결론 (추세 기반 — §3.3 v4)
///
/// RiskWindow 없음 — 보간 데이터의 거짓 정밀도 방지 (§3.3 v4 결정).
/// 추세 판단: isIncreasing = points.last.finalRatio > points.first.finalRatio
/// cubic smoothstep 보간은 단조 변화만 생성 → 양 끝점 비교로 충분.
enum ChartVerdict {
  safe,              // peakRatio < 1.0 — 12시간 내내 기준 이하
  partialIncreasing, // 부분 초과 + 상승 추세
  partialDecreasing, // 부분 초과 + 하락 추세
  fullDay,           // 모든 포인트 finalRatio ≥ 1.0 (h=0 포함)
  unknown,           // 포인트 부족 또는 데이터 없음
}

// ── ProtectionChartData ───────────────────────────────────

class ProtectionChartData {
  /// final_ratio 기반 차트 포인트 (13개, h=0~12)
  final List<ChartPoint> chartPoints;

  /// 개인화 임계치 (µg/m³) — "내 기준 Xµg" 라벨 표시용
  final double tFinal;

  /// KF94=0.94 — 마스크 곡선 계산: finalRatio × (1 − filterRate)
  final double filterRate;

  /// 12시간 요약 결론 (추세 기반)
  final ChartVerdict verdict;

  final bool hasForecastData;
  final DateTime generatedAt;

  const ProtectionChartData({
    required this.chartPoints,
    required this.tFinal,
    required this.filterRate,
    required this.verdict,
    required this.hasForecastData,
    required this.generatedAt,
  });

  /// 현재 시점(h=0)이 기준 초과인지 (곡선·영역 색상 분기)
  bool get isCurrentOverThreshold =>
      chartPoints.isNotEmpty && chartPoints.first.finalRatio >= 1.0;

  factory ProtectionChartData.placeholder() => ProtectionChartData(
    chartPoints: List.generate(13, (h) => ChartPoint(
      hour:       h.toDouble(),
      finalRatio: 0.6,
      rawPm25:    21.0,
      isForecast: h > 0,
    )),
    tFinal:          35,
    filterRate:      0.94,
    verdict:         ChartVerdict.unknown,
    hasForecastData: false,
    generatedAt:     DateTime.now(),
  );

  factory ProtectionChartData.noData() => ProtectionChartData(
    chartPoints:     [],
    tFinal:          35,
    filterRate:      0.94,
    verdict:         ChartVerdict.unknown,
    hasForecastData: false,
    generatedAt:     DateTime.now(),
  );
}

// ── PollutantDetailCard 모델 ──────────────────────────────

class PollutantCardData {
  final double? pm25;
  final double? pm10;
  final String pm25Grade;
  final String pm10Grade;
  final double? o3;
  final double? no2;
  final double? co;
  final double? so2;
  final String? o3Grade;
  final String? no2Grade;
  final String? coGrade;
  final String? so2Grade;

  const PollutantCardData({
    required this.pm25,
    required this.pm10,
    required this.pm25Grade,
    required this.pm10Grade,
    this.o3,
    this.no2,
    this.co,
    this.so2,
    this.o3Grade,
    this.no2Grade,
    this.coGrade,
    this.so2Grade,
  });

  bool get hasExtendedData =>
      o3 != null || no2 != null || co != null || so2 != null;

  factory PollutantCardData.placeholder() => const PollutantCardData(
    pm25: 0,
    pm10: 0,
    pm25Grade: '보통',
    pm10Grade: '보통',
  );
}

// ── ChartPoint 빌더 (§2.9 v4) ────────────────────────────

/// PM2.5 등급 문자열 → 보간 중앙값 (µg/m³)
///
/// tomorrowForecastProvider가 반환하는 등급 문자열을 수치로 변환.
double gradeToMidpoint(String? grade) => switch (grade) {
  '좋음'    => 8.0,
  '보통'    => 25.0,
  '나쁨'    => 55.0,
  '매우나쁨' => 90.0,
  _         => 25.0,
};

/// 12시간 추세 기반 ChartVerdict 판정 (§3.3 v4)
///
/// 판정 우선순위:
///   1. 포인트 없음 / 부족 → unknown
///   2. 모든 포인트 finalRatio ≥ 1.0 (h=0 포함) → fullDay
///   3. peakRatio < 1.0 → safe
///   4. 상승 추세 (last > first) → partialIncreasing
///   5. 하락·평탄 추세 → partialDecreasing
///
/// 추세 판단 근거: cubic smoothstep 보간은 단조 변화만 생성 →
///   양 끝점 비교(points.last.finalRatio vs points.first.finalRatio)로 충분.
/// RiskWindow 없음 — 보간 거짓 정밀도 방지 (§3.3 v4 결정).
ChartVerdict buildChartVerdict(List<ChartPoint> points) {
  if (points.length < 2) return ChartVerdict.unknown;

  final first     = points.first.finalRatio;
  final last      = points.last.finalRatio;
  final peakRatio = points.map((p) => p.finalRatio).reduce((a, b) => a > b ? a : b);

  // 전체 초과: 첫 포인트(h=0)도 기준 이상
  if (points.every((p) => p.finalRatio >= 1.0)) return ChartVerdict.fullDay;

  // 피크 미달: 12시간 내내 안전
  if (peakRatio < 1.0) return ChartVerdict.safe;

  // 부분 초과 → 추세로 구분
  final isIncreasing = last > first;
  return isIncreasing
      ? ChartVerdict.partialIncreasing
      : ChartVerdict.partialDecreasing;
}

/// final_ratio 기반 ChartPoint 리스트 생성 (13개, h=0~12)
///
/// - h=0 (현재): 실측 pm25/pm10 사용
/// - h=1~12 (보간): cubic smoothstep, PM10 미반영 (ratioPm10=0)
///   → tomorrowForecastProvider가 PM2.5 등급만 제공하기 때문 (§7 v4 명시)
///
/// [tFinalPm25] : 개인화 PM2.5 임계치 (µg/m³)
/// [currentPm25]: 현재 PM2.5 실측값 (µg/m³)
/// [currentPm10]: 현재 PM10 실측값 (nullable — 없으면 ratioPm10=0)
/// [forecastGrade]: 내일 PM2.5 등급 문자열 (nullable)
List<ChartPoint> buildChartPoints({
  required double tFinalPm25,
  required double currentPm25,
  int? currentPm10,
  String? forecastGrade,
  int horizonHours = 12,
}) {
  final tFinalPm10   = tFinalPm25 * (80.0 / 35.0);
  final forecastMid  = gradeToMidpoint(forecastGrade);

  return List.generate(horizonHours + 1, (h) {
    final t      = h / horizonHours;
    final smooth = t * t * (3 - 2 * t); // cubic smoothstep

    final interpPm25   = currentPm25 + (forecastMid - currentPm25) * smooth;
    final ratioPm25    = interpPm25 / tFinalPm25;

    // 예보 구간에서는 PM10 데이터 없음 → ratioPm10 = 0
    final rawPm10    = h == 0 ? currentPm10?.toDouble() : null;
    final ratioPm10  = (h == 0 && currentPm10 != null)
        ? currentPm10 / tFinalPm10
        : 0.0;

    final finalRatio = ratioPm25 > ratioPm10 ? ratioPm25 : ratioPm10;

    return ChartPoint(
      hour:       h.toDouble(),
      finalRatio: finalRatio.clamp(0.0, 10.0),
      rawPm25:    interpPm25.clamp(0.0, 500.0),
      rawPm10:    rawPm10,
      isForecast: h > 0,
    );
  });
}

// ── 시간대 라벨 / 흐름 텍스트 (§4 v1) ────────────────────

/// h번째 시간의 시간대 라벨 반환 (h=0 → '지금')
String hourLabel(int h, DateTime now) {
  if (h == 0) return '지금';
  final hr = now.add(Duration(hours: h)).hour;
  if (hr < 5)  return '새벽';
  if (hr < 12) return '오전';
  if (hr < 18) return '낮';
  if (hr < 22) return '저녁';
  return '밤';
}

/// baseLabel과 다른 첫 번째 시간대 라벨 반환 (h=4 → h=8 → h=12 순서)
/// 12시간 내 다른 시간대 없으면 null
String? _nextDifferentLabel(String baseLabel, DateTime now) {
  for (final h in [4, 8, 12]) {
    final label = hourLabel(h, now);
    if (label != baseLabel) return label;
  }
  return null;
}

/// 오염물질 ratio → 5단계 카피 (ALL 위험도에서 표시)
String pollutantCopy(double ratio) {
  if (ratio < 0.5) return '여유롭게 숨 쉴 수 있어요';
  if (ratio < 0.7) return '괜찮은 편이에요';
  if (ratio < 1.0) return '조금 신경 써야 할 정도예요';
  if (ratio < 1.5) return '마스크가 필요해요';
  return '꼭 마스크를 착용하세요';
}

/// 오염물질 ratio → 5단계 표정 (ALL 위험도에서 표시)
String pollutantEmoji(double ratio) {
  if (ratio < 0.5) return '😊';
  if (ratio < 0.7) return '🙂';
  if (ratio < 1.0) return '😐';
  if (ratio < 1.5) return '😷';
  return '😨';
}

// ── 시간대 라벨 / 흐름 텍스트 (§4 v1) ────────────────────

/// 12시간 예보 흐름 텍스트 생성 (헤더 서브카피)
///
/// 패턴:
///   전체 안전 → "12시간 동안 안전해요"
///   전체 주의 → "오늘 종일 주의가 필요해요"
///   전환 (동일 시간대) → "지금은 안전, {다음 다른 시간대}부터 주의 😷"
///   전환 (다른 시간대) → "{A}까지 안전 → {B}부터 주의"
String buildFlowText(List<ChartPoint> points, DateTime now) {
  if (points.isEmpty) return '예보 데이터를 불러오는 중이에요';

  const kThreshold = 0.7;
  final allSafe = points.every((p) => p.finalRatio < kThreshold);
  final allWarn = points.every((p) => p.finalRatio >= kThreshold);

  if (allSafe) return '12시간 동안 안전해요';
  if (allWarn) return '오늘 종일 주의가 필요해요';

  for (int i = 1; i < points.length; i++) {
    final prev = points[i - 1].finalRatio;
    final curr = points[i].finalRatio;

    if (prev < kThreshold && curr >= kThreshold) {
      final before = hourLabel(i - 1, now);
      final after  = hourLabel(i, now);
      if (i == 1) return '$after부터 주의가 필요해요';
      if (before == after) {
        final next = _nextDifferentLabel(after, now);
        return next != null
            ? '지금은 안전, $next부터 주의 😷'
            : '오늘 종일 주의가 필요해요';
      }
      return '$before까지 안전 → $after부터 주의';
    }

    if (prev >= kThreshold && curr < kThreshold) {
      final before = hourLabel(i - 1, now);
      final after  = hourLabel(i, now);
      if (i == 1) return '$after부터 나아질 거예요';
      if (before == after) {
        final next = _nextDifferentLabel(after, now);
        return next != null
            ? '지금은 주의, $next부터 안전'
            : '12시간 동안 안전해요';
      }
      return '$before까지 주의 → $after부터 안전';
    }
  }

  return '12시간 동안 안전해요';
}
