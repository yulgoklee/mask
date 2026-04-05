import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/dust_data.dart';
import '../../data/models/forecast_models.dart';
import '../config/app_config.dart';
import '../constants/dust_standards.dart';
import '../errors/app_exception.dart';
import 'dust_data_source.dart';

/// Cloud Functions 기반 미세먼지 데이터 소스
///
/// AirKorea API를 직접 호출하는 대신 우리 서버(Cloud Functions)를 통해
/// 프록시합니다. API 키가 앱 바이너리에 포함되지 않습니다.
///
/// AppConfig.cloudFunctionsBaseUrl 이 설정되어 있을 때 자동으로 사용됩니다.
class CloudFunctionsDataSource implements DustDataSource {
  static const String _measurementPath = "/proxyMeasurement";
  static const String _forecastPath = "/proxyForecast";
  static const String _stationsPath = "/proxyStations";

  final Dio _dio;

  CloudFunctionsDataSource()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.cloudFunctionsBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      responseHeader: false,
      responseBody: false,
      request: true,
      logPrint: (o) => debugPrint('[CloudFn] $o'),
    ));
  }

  // ── DustDataSource 구현 ───────────────────────────────────

  @override
  Future<DustData?> getDustData(String stationName) async {
    try {
      final response = await _dio.get(_measurementPath,
          queryParameters: {'stationName': stationName, 'numOfRows': '1'});
      final data = response.data;
      if (data is! Map) return null;

      final header = data['response']?['header'];
      final resultCode = header?['resultCode']?.toString();
      if (resultCode == null || resultCode != '00') return null;

      final items = data['response']?['body']?['items'] as List?;
      if (items == null || items.isEmpty) return null;

      return DustData.fromJson(items.first as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[CloudFn] getDustData 네트워크 오류: ${e.message}');
      throw const NetworkException();
    } catch (e) {
      debugPrint('[CloudFn] getDustData 파싱 오류: $e');
      throw const ParseException();
    }
  }

  @override
  Future<List<HourlyDustData>> getHourlyData(String stationName) async {
    try {
      // 1. 현재 실측값
      final response = await _dio.get(_measurementPath,
          queryParameters: {'stationName': stationName, 'numOfRows': '1'});
      final data = response.data;
      if (data is! Map) return [];
      final items = data['response']?['body']?['items'] as List?;
      if (items == null || items.isEmpty) return [];

      final map = items.first as Map<String, dynamic>;
      final measureTime = _parseDataTime(map['dataTime'] as String?);
      final current = HourlyDustData(
        time: measureTime,
        pm10: _parseInt(map['pm10Value']),
        pm25: _parseInt(map['pm25Value']),
        pm10Grade: DustStandards.getPm10Grade(_parseInt(map['pm10Value']) ?? 0),
        pm25Grade: DustStandards.getPm25Grade(_parseInt(map['pm25Value']) ?? 0),
        isForecast: false,
      );

      // 2. 주간 예보로 미래 슬롯 채우기
      final sidoName = _localSidoMap(stationName);
      final forecasts = await getWeeklyForecast(sidoName: sidoName);
      final forecastMap = {
        for (final f in forecasts)
          '${f.date.year}-${f.date.month.toString().padLeft(2, '0')}-${f.date.day.toString().padLeft(2, '0')}':
              f
      };

      final now = DateTime.now();
      final future = <HourlyDustData>[];
      for (int i = 1; future.length < 23 && i <= 48; i++) {
        final futureTime = measureTime.add(Duration(hours: i));
        if (!futureTime.isAfter(now)) continue;
        final dayKey =
            '${futureTime.year}-${futureTime.month.toString().padLeft(2, '0')}-${futureTime.day.toString().padLeft(2, '0')}';
        final forecast = forecastMap[dayKey];
        future.add(HourlyDustData(
          time: futureTime,
          pm10: null,
          pm25: null,
          pm10Grade: forecast?.pm10Grade ?? current.pm10Grade,
          pm25Grade: forecast?.pm25Grade ?? current.pm25Grade,
          isForecast: true,
        ));
      }

      return [current, ...future];
    } on DioException catch (e) {
      debugPrint('[CloudFn] getHourlyData 네트워크 오류: ${e.message}');
      throw const NetworkException();
    } catch (e) {
      debugPrint('[CloudFn] getHourlyData 오류: $e');
      return [];
    }
  }

  @override
  Future<List<HourlyDustData>> getHourlyHistory(String stationName) async {
    try {
      final response = await _dio.get(_measurementPath, queryParameters: {
        'stationName': stationName,
        'numOfRows': '24',
      });
      final data = response.data;
      if (data is! Map) return [];
      final items = data['response']?['body']?['items'] as List?;
      if (items == null) return [];

      final result = items.map((e) {
        final m = e as Map<String, dynamic>;
        final t = _parseDataTime(m['dataTime'] as String?);
        return HourlyDustData(
          time: t,
          pm10: _parseInt(m['pm10Value']),
          pm25: _parseInt(m['pm25Value']),
          pm10Grade:
              DustStandards.getPm10Grade(_parseInt(m['pm10Value']) ?? 0),
          pm25Grade:
              DustStandards.getPm25Grade(_parseInt(m['pm25Value']) ?? 0),
          isForecast: false,
        );
      }).toList();
      result.sort((a, b) => a.time.compareTo(b.time));
      return result;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<WeeklyForecastData>> getWeeklyForecast(
      {String? sidoName}) async {
    try {
      final now = DateTime.now();
      final searchBase =
          now.hour < 5 ? now.subtract(const Duration(days: 1)) : now;
      final today = DateTime(now.year, now.month, now.day);
      final dateStr =
          '${searchBase.year}-${searchBase.month.toString().padLeft(2, '0')}-${searchBase.day.toString().padLeft(2, '0')}';

      final pm10Future = _dio.get(_forecastPath, queryParameters: {
        'searchDate': dateStr,
        'informCode': 'PM10',
        'numOfRows': '20',
      });
      final pm25Future = _dio.get(_forecastPath, queryParameters: {
        'searchDate': dateStr,
        'informCode': 'PM25',
        'numOfRows': '20',
      });

      final results = await Future.wait([pm10Future, pm25Future]);
      final pm10Items =
          results[0].data['response']?['body']?['items'] as List? ?? [];
      final pm25Items =
          results[1].data['response']?['body']?['items'] as List? ?? [];

      final pm10Map = <String, ({DustGrade? grade, String dataTime})>{};
      for (final item in pm10Items) {
        final date = item['informData'] as String? ?? '';
        if (date.isEmpty) continue;
        final dataTime = item['dataTime'] as String? ?? '';
        final existing = pm10Map[date];
        if (existing == null || dataTime.compareTo(existing.dataTime) >= 0) {
          final raw = item['informGrade'] as String? ?? '';
          final grade = sidoName != null
              ? _filterBySido(raw, sidoName)
              : _firstGrade(raw);
          pm10Map[date] = (grade: grade, dataTime: dataTime);
        }
      }

      final pm25Map = <String, ({DustGrade? grade, String dataTime})>{};
      for (final item in pm25Items) {
        final date = item['informData'] as String? ?? '';
        if (date.isEmpty) continue;
        final dataTime = item['dataTime'] as String? ?? '';
        final existing = pm25Map[date];
        if (existing == null || dataTime.compareTo(existing.dataTime) >= 0) {
          final raw = item['informGrade'] as String? ?? '';
          final grade = sidoName != null
              ? _filterBySido(raw, sidoName)
              : _firstGrade(raw);
          pm25Map[date] = (grade: grade, dataTime: dataTime);
        }
      }

      final allDates = {...pm10Map.keys, ...pm25Map.keys};
      final result = allDates.map((date) {
        return WeeklyForecastData(
          date: DateTime.tryParse(date) ?? now,
          pm10Grade: pm10Map[date]?.grade,
          pm25Grade: pm25Map[date]?.grade,
        );
      }).toList();

      result.sort((a, b) => a.date.compareTo(b.date));
      return result.where((d) => !d.date.isBefore(today)).toList();
    } on DioException catch (e) {
      debugPrint('[CloudFn] getWeeklyForecast 네트워크 오류: ${e.message}');
      throw const NetworkException('예보 데이터를 불러올 수 없어요.\n잠시 후 다시 시도해 주세요.');
    } catch (e) {
      debugPrint('[CloudFn] getWeeklyForecast 오류: $e');
      return [];
    }
  }

  @override
  Future<String?> getTomorrowForecast({String? sidoName}) async {
    final forecasts = await getWeeklyForecast(sidoName: sidoName);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    final tomorrowForecast = forecasts.where((f) {
      final d = DateTime(f.date.year, f.date.month, f.date.day);
      return d == tomorrowDate;
    }).firstOrNull;

    if (tomorrowForecast == null) return null;
    final worst = DustStandards.worstGrade(
        tomorrowForecast.pm10Grade, tomorrowForecast.pm25Grade);
    if (worst == null) return null;

    return switch (worst) {
      DustGrade.good => '좋음',
      DustGrade.normal => '보통',
      DustGrade.bad => '나쁨',
      DustGrade.veryBad => '매우나쁨',
    };
  }

  @override
  Future<String?> getSidoForStation(String stationName) async {
    // 1. 로컬 매핑 우선
    final local = _localSidoMap(stationName);
    if (local != null) return local;

    // 2. 서버 API 조회
    try {
      final response = await _dio.get(_stationsPath, queryParameters: {
        'stationName': stationName,
        'numOfRows': '1',
      });
      final items =
          response.data['response']?['body']?['items'] as List?;
      if (items == null || items.isEmpty) return null;
      return items.first['sidoName'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> searchStations(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final response = await _dio.get(_stationsPath, queryParameters: {
        'stationName': keyword.trim(),
        'numOfRows': '20',
      });
      final data = response.data;
      if (data is! Map) return [];
      final items = data['response']?['body']?['items'] as List?;
      if (items == null) return [];
      return items
          .map((e) => e['stationName']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[CloudFn] searchStations 오류: $e');
      return [];
    }
  }

  // ── 내부 헬퍼 (AirKoreaService와 동일 로직) ───────────────

  static int? _parseInt(dynamic v) {
    if (v == null || v == '-') return null;
    return int.tryParse(v.toString());
  }

  static DateTime _parseDataTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return DateTime.now();
    var s = raw.trim();
    if (s.contains(' ') && !s.contains('T')) s = s.replaceFirst(' ', 'T');
    if (RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$').hasMatch(s)) {
      s = '$s:00';
    }
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  static DustGrade? _firstGrade(String informGrade) {
    if (informGrade.isEmpty) return null;
    final parts = informGrade.split(',').first.split(':');
    if (parts.length < 2) return null;
    return DustGrade.fromString(parts[1].trim());
  }

  static DustGrade? _filterBySido(String informGrade, String sidoName) {
    for (final part in informGrade.split(',')) {
      final kv = part.split(':');
      if (kv.length < 2) continue;
      if (kv[0].trim() == sidoName) return DustGrade.fromString(kv[1].trim());
    }
    return _firstGrade(informGrade);
  }

  /// 측정소명 → 시도명 로컬 매핑 (API 호출 절약)
  static String? _localSidoMap(String stationName) {
    const map = <String, String>{
      // 서울
      '강남구': '서울', '강동구': '서울', '강북구': '서울', '강서구': '서울',
      '관악구': '서울', '광진구': '서울', '구로구': '서울', '금천구': '서울',
      '노원구': '서울', '도봉구': '서울', '동대문구': '서울', '동작구': '서울',
      '마포구': '서울', '서대문구': '서울', '서초구': '서울', '성동구': '서울',
      '성북구': '서울', '송파구': '서울', '양천구': '서울', '영등포구': '서울',
      '용산구': '서울', '은평구': '서울', '종로구': '서울', '중구': '서울',
      '중랑구': '서울',
      // 경기
      '인계동': '경기', '수내동': '경기', '행신동': '경기', '수지': '경기',
      '중2동': '경기', '고잔동': '경기', '안양8동': '경기', '금곡동': '경기',
      '동탄': '경기', '비전동': '경기', '의정부동': '경기', '운정': '경기',
      '경안동': '경기', '사우동': '경기', '정왕동': '경기', '미사': '경기',
      // 인천
      '구월동': '인천', '동춘': '인천', '부평': '인천', '계산': '인천',
      '청라': '인천', '송도': '인천',
      // 부산
      '광복동': '부산', '온천동': '부산', '감천동': '부산', '화명동': '부산',
      '우동': '부산',
      // 대구
      '수창동': '대구', '이곡동': '대구', '만촌동': '대구',
      // 광주
      '서석동': '광주', '치평동': '광주', '두암동': '광주',
      '일곡동': '광주', '주월동': '광주', '노대동': '광주', '평동': '광주',
      // 대전
      '둔산동': '대전', '노은동': '대전', '문창동': '대전',
      '대성동': '대전', '읍내동': '대전', '비래동': '대전',
      // 울산
      '무거동': '울산', '삼산동': '울산', '신정동': '울산',
      '농소동': '울산', '삼남읍': '울산',
      // 세종
      '한솔동': '세종', '아름동': '세종', '조치원읍': '세종',
    };
    return map[stationName];
  }
}
