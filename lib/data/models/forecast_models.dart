import '../../core/constants/dust_standards.dart';

/// 시간별 미세먼지 측정/예보 데이터
class HourlyDustData {
  final DateTime time;
  final int? pm10;
  final int? pm25;
  final DustGrade pm10Grade;
  final DustGrade pm25Grade;
  final bool isForecast; // true = 미래 예보 (실측값 없음)

  const HourlyDustData({
    required this.time,
    required this.pm10,
    required this.pm25,
    required this.pm10Grade,
    required this.pm25Grade,
    this.isForecast = false,
  });
}

/// 단기(3일) 미세먼지 예보 데이터
class WeeklyForecastData {
  final DateTime date;
  final DustGrade? pm10Grade;
  final DustGrade? pm25Grade;

  const WeeklyForecastData({
    required this.date,
    this.pm10Grade,
    this.pm25Grade,
  });
}
