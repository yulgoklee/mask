import 'package:fl_chart/fl_chart.dart';

// ── StatusCard 모델 ───────────────────────────────────────

enum CardStatus { safe, caution, danger }

class StatusCardData {
  final CardStatus status;
  final String emoji;
  final String title;
  final String personalizedText;
  final String actionGuide;
  final double pm25Value;
  final double tFinal;
  final double sensitivityMultiplier;
  final String nickname;
  final int respiratoryStatus;
  final double overRatio;

  const StatusCardData({
    required this.status,
    required this.emoji,
    required this.title,
    required this.personalizedText,
    required this.actionGuide,
    required this.pm25Value,
    required this.tFinal,
    required this.sensitivityMultiplier,
    required this.nickname,
    required this.respiratoryStatus,
    required this.overRatio,
  });

  factory StatusCardData.placeholder() => const StatusCardData(
    status: CardStatus.safe,
    emoji: '😊',
    title: '데이터를 불러오는 중',
    personalizedText: '',
    actionGuide: '',
    pm25Value: 0,
    tFinal: 35,
    sensitivityMultiplier: 1.0,
    nickname: '',
    respiratoryStatus: 0,
    overRatio: 0,
  );
}

CardStatus resolveStatus(double pm25, double tFinal) {
  if (pm25 <= tFinal) return CardStatus.safe;
  if (pm25 <= tFinal * 1.5) return CardStatus.caution;
  return CardStatus.danger;
}

// ── ProtectionAreaChart 모델 ──────────────────────────────

class ProtectionChartData {
  final List<FlSpot> airSpots;
  final List<FlSpot> maskSpots;
  final double tFinal;
  final double filterRate;
  final String maskType;
  final bool hasForecastData;
  final DateTime generatedAt;

  const ProtectionChartData({
    required this.airSpots,
    required this.maskSpots,
    required this.tFinal,
    required this.filterRate,
    required this.maskType,
    required this.hasForecastData,
    required this.generatedAt,
  });

  bool get isCurrentOverThreshold =>
      airSpots.isNotEmpty && airSpots.first.y > tFinal;

  factory ProtectionChartData.placeholder() => ProtectionChartData(
    airSpots: _dummySpots(),
    maskSpots: _dummySpots(scale: 0.06),
    tFinal: 35,
    filterRate: 0.94,
    maskType: 'KF94',
    hasForecastData: false,
    generatedAt: DateTime.now(),
  );

  static List<FlSpot> _dummySpots({double scale = 1.0}) =>
      List.generate(13, (h) => FlSpot(h.toDouble(), 20 * scale));
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

// ── 차트 데이터 빌더 함수 ──────────────────────────────────

List<FlSpot> buildChartPoints({
  required double currentPm25,
  required double forecastMid,
  int horizonHours = 12,
}) {
  return List.generate(horizonHours + 1, (h) {
    final t = h / horizonHours;
    final smooth = t * t * (3 - 2 * t);
    final value = currentPm25 + (forecastMid - currentPm25) * smooth;
    return FlSpot(h.toDouble(), value.clamp(0, 200));
  });
}

List<FlSpot> buildMaskSpots(List<FlSpot> airSpots, double filterRate) =>
    airSpots.map((s) => FlSpot(s.x, s.y * (1 - filterRate))).toList();

double gradeToMidpoint(String? grade) => switch (grade) {
  '좋음'    => 8,
  '보통'    => 25,
  '나쁨'    => 55,
  '매우나쁨' => 90,
  _         => 25,
};
