/// 시간별 AQI 기록 — SQLite aqi_records 테이블과 1:1 대응
class AqiRecord {
  final int? id;
  final String stationName;
  final int? pm25Value;
  final int? pm10Value;
  final String? pm25Grade;
  final DateTime dataTime;   // 측정소 기준 측정 시각
  final DateTime fetchedAt;  // 앱이 API를 조회한 시각

  const AqiRecord({
    this.id,
    required this.stationName,
    this.pm25Value,
    this.pm10Value,
    this.pm25Grade,
    required this.dataTime,
    required this.fetchedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'station_name': stationName,
        'pm25_value': pm25Value,
        'pm10_value': pm10Value,
        'pm25_grade': pm25Grade,
        'data_time': dataTime.toIso8601String(),
        'fetched_at': fetchedAt.toIso8601String(),
      };

  factory AqiRecord.fromMap(Map<String, dynamic> m) => AqiRecord(
        id: m['id'] as int?,
        stationName: m['station_name'] as String,
        pm25Value: m['pm25_value'] as int?,
        pm10Value: m['pm10_value'] as int?,
        pm25Grade: m['pm25_grade'] as String?,
        dataTime: DateTime.parse(m['data_time'] as String),
        fetchedAt: DateTime.parse(m['fetched_at'] as String),
      );
}
