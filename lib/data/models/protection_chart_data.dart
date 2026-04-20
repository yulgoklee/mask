import 'package:fl_chart/fl_chart.dart';
import '../../core/engine/aqi_grade_converter.dart';

class ProtectionChartData {
  final List<FlSpot> airSpots;
  final List<FlSpot> maskSpots;
  final double tFinal;
  final double filterRate;
  final String maskType;
  final double? currentPm25;
  final bool hasForecastData;
  final DateTime generatedAt;

  const ProtectionChartData({
    required this.airSpots,
    required this.maskSpots,
    required this.tFinal,
    required this.filterRate,
    required this.maskType,
    this.currentPm25,
    required this.hasForecastData,
    required this.generatedAt,
  });

  bool get isCurrentOverThreshold =>
      airSpots.isNotEmpty && airSpots.first.y > tFinal;

  factory ProtectionChartData.placeholder() {
    final dummyRaw = AqiGradeConverter.buildFutureSpots(
      currentPm25: 20,
      forecastGrade: '보통',
      horizonHours: 12,
    );
    final airSpots  = dummyRaw.map((s) => FlSpot(s.x, s.y)).toList();
    final maskSpots = AqiGradeConverter
        .buildMaskSpotsFromFuture(dummyRaw, 0.94)
        .map((s) => FlSpot(s.x, s.y))
        .toList();
    return ProtectionChartData(
      airSpots: airSpots,
      maskSpots: maskSpots,
      tFinal: 35,
      filterRate: 0.94,
      maskType: 'KF94',
      hasForecastData: false,
      generatedAt: DateTime.now(),
    );
  }

  factory ProtectionChartData.noStation() => ProtectionChartData(
        airSpots: [],
        maskSpots: [],
        tFinal: 35,
        filterRate: 0.94,
        maskType: 'KF94',
        hasForecastData: false,
        generatedAt: DateTime.now(),
      );
}
