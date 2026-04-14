import '../../../core/constants/app_constants.dart';

/// 에어코리아 API 응답 미세먼지 데이터 모델
class DustData {
  final String stationName;   // 측정소명
  final int? pm25Value;       // PM2.5 (μg/m³)
  final int? pm10Value;       // PM10 (μg/m³)
  final String pm25Grade;     // PM2.5 등급 (1:좋음 2:보통 3:나쁨 4:매우나쁨)
  final String pm10Grade;     // PM10 등급
  final double? o3Value;      // 오존 (ppm)
  final String o3Grade;       // 오존 등급
  final double? no2Value;     // 이산화질소 (ppm)
  final String no2Grade;      // 이산화질소 등급
  final DateTime dataTime;    // 측정 시각
  final DateTime fetchedAt;   // 조회 시각

  const DustData({
    required this.stationName,
    this.pm25Value,
    this.pm10Value,
    required this.pm25Grade,
    required this.pm10Grade,
    this.o3Value,
    this.no2Value,
    this.o3Grade = '알수없음',
    this.no2Grade = '알수없음',
    required this.dataTime,
    required this.fetchedAt,
  });

  factory DustData.fromJson(Map<String, dynamic> json) {
    return DustData(
      stationName: json['stationName'] as String? ?? '',
      pm25Value: _parseIntOrNull(json['pm25Value']),
      pm10Value: _parseIntOrNull(json['pm10Value']),
      pm25Grade: _gradeLabel(json['pm25Grade']),
      pm10Grade: _gradeLabel(json['pm10Grade']),
      o3Value: _parseDoubleOrNull(json['o3Value']),
      o3Grade: _gradeLabel(json['o3Grade']),
      no2Value: _parseDoubleOrNull(json['no2Value']),
      no2Grade: _gradeLabel(json['no2Grade']),
      dataTime: _parseDataTime(json['dataTime'] as String?),
      fetchedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'stationName': stationName,
    'pm25Value': pm25Value,
    'pm10Value': pm10Value,
    'pm25Grade': pm25Grade,
    'pm10Grade': pm10Grade,
    'o3Value': o3Value,
    'o3Grade': o3Grade,
    'no2Value': no2Value,
    'no2Grade': no2Grade,
    'dataTime': dataTime.toIso8601String(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory DustData.fromCacheJson(Map<String, dynamic> json) {
    return DustData(
      stationName: json['stationName'] as String? ?? '',
      pm25Value: json['pm25Value'] as int?,
      pm10Value: json['pm10Value'] as int?,
      pm25Grade: json['pm25Grade'] as String? ?? '알수없음',
      pm10Grade: json['pm10Grade'] as String? ?? '알수없음',
      o3Value: (json['o3Value'] as num?)?.toDouble(),
      o3Grade: json['o3Grade'] as String? ?? '알수없음',
      no2Value: (json['no2Value'] as num?)?.toDouble(),
      no2Grade: json['no2Grade'] as String? ?? '알수없음',
      dataTime: _parseDataTime(json['dataTime'] as String?),
      fetchedAt: _parseDataTime(json['fetchedAt'] as String?),
    );
  }

  /// 캐시가 유효한지 확인
  /// 조건: 조회한 지 [AppConstants.cacheFetchMaxMinutes]분 이하
  ///      AND 측정시각(dataTime)이 [AppConstants.cacheDataMaxMinutes]분 이내
  bool get isCacheValid {
    final fetchAge = DateTime.now().difference(fetchedAt).inMinutes;
    final dataAge = DateTime.now().difference(dataTime).inMinutes;
    return fetchAge <= AppConstants.cacheFetchMaxMinutes &&
        dataAge < AppConstants.cacheDataMaxMinutes;
  }

  /// API/캐시 날짜 문자열 파싱 (형식: "2026-03-31 23:00" — 초 없음)
  /// Dart의 DateTime.tryParse는 초(ss)가 없는 HH:mm 포맷을 안정적으로
  /// 처리하지 못할 수 있으므로, ":00"을 보완하여 ISO 8601로 정규화한다.
  static DateTime _parseDataTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return DateTime.now();
    // "2026-03-31 23:00" → "2026-03-31T23:00:00"
    var s = raw.trim();
    // space → T 구분자 정규화
    if (s.contains(' ') && !s.contains('T')) {
      s = s.replaceFirst(' ', 'T');
    }
    // HH:mm만 있고 초가 없는 경우(길이 16) → :00 추가
    if (RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$').hasMatch(s)) {
      s = '$s:00';
    }
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null || value == '-') return null;
    return int.tryParse(value.toString());
  }

  static double? _parseDoubleOrNull(dynamic value) {
    if (value == null || value == '-') return null;
    return double.tryParse(value.toString());
  }

  static String _gradeLabel(dynamic gradeCode) {
    switch (gradeCode?.toString()) {
      case '1': return '좋음';
      case '2': return '보통';
      case '3': return '나쁨';
      case '4': return '매우나쁨';
      default:  return '알수없음';
    }
  }

  @override
  String toString() =>
      'DustData(station: $stationName, PM2.5: $pm25Value($pm25Grade), PM10: $pm10Value($pm10Grade), O3: $o3Value($o3Grade), NO2: $no2Value($no2Grade))';
}
