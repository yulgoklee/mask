import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/dust_data.dart';
import '../../data/models/forecast_models.dart';
import '../config/app_config.dart';
import '../constants/dust_standards.dart';
import '../errors/app_exception.dart';
import 'app_logger.dart';
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

      return DustData.fromJson(
        items.first as Map<String, dynamic>,
        fallbackStationName: stationName,
      );
    } on DioException catch (_) {
      throw const NetworkException();
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false, reason: 'getDustData_parse');
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
    } catch (e, st) {
      debugPrint('[CloudFn] getHourlyData 오류: $e');
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false, reason: 'getHourlyData_parse');
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
    } catch (e, st) {
      debugPrint('[CloudFn] getWeeklyForecast 오류: $e');
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false, reason: 'getWeeklyForecast_parse');
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
    final pm10 = tomorrowForecast.pm10Grade;
    final pm25 = tomorrowForecast.pm25Grade;
    if (pm10 == null && pm25 == null) return null;
    final worst = pm10 != null && pm25 != null
        ? DustStandards.worstGrade(pm10, pm25)
        : pm10 ?? pm25 ?? DustGrade.good;


    return switch (worst) {
      DustGrade.good => '좋음',
      DustGrade.normal => '보통',
      DustGrade.bad => '나쁨',
      DustGrade.veryBad => '매우나쁨',
    };
  }

  @override
  Future<String?> getTomorrowForecastPm10({String? sidoName}) async {
    final forecasts = await getWeeklyForecast(sidoName: sidoName);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    final tomorrowForecast = forecasts.where((f) {
      final d = DateTime(f.date.year, f.date.month, f.date.day);
      return d == tomorrowDate;
    }).firstOrNull;

    if (tomorrowForecast == null) return null;
    final pm10 = tomorrowForecast.pm10Grade;
    if (pm10 == null) return null;

    return switch (pm10) {
      DustGrade.good    => '좋음',
      DustGrade.normal  => '보통',
      DustGrade.bad     => '나쁨',
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
    } catch (e, st) {
      AppLogger.error(e, st, reason: 'search_stations');
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

  /// 측정소명 → 시도명 로컬 매핑 (stations.ts 와 동기화)
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
      '이의동': '경기', '처인구': '경기', '중원구': '경기', '덕양구': '경기',
      '오산': '경기', '구리': '경기', '광명': '경기', '군포': '경기',
      '의왕': '경기', '이천': '경기', '양주': '경기', '포천': '경기',
      '여주': '경기', '양평': '경기', '가평': '경기', '동두천': '경기',
      '과천': '경기', '안성': '경기', '연천': '경기',
      // 인천
      '구월동': '인천', '동춘': '인천', '부평': '인천', '계산': '인천',
      '청라': '인천', '송도': '인천', '항동': '인천', '검단': '인천',
      '강화': '인천',
      // 부산
      '광복동': '부산', '온천동': '부산', '감천동': '부산', '화명동': '부산',
      '우동': '부산', '학장동': '부산', '연산동': '부산', '대연동': '부산',
      '전포동': '부산', '장림동': '부산', '기장읍': '부산',
      // 대구
      '수창동': '대구', '이곡동': '대구', '만촌동': '대구', '검사동': '대구',
      '칠성동': '대구', '비산동': '대구', '대명동': '대구', '다사읍': '대구',
      // 광주
      '서석동': '광주', '치평동': '광주', '두암동': '광주',
      '일곡동': '광주', '주월동': '광주', '노대동': '광주', '평동': '광주',
      '월곡동': '광주', '내방동': '광주',
      // 대전
      '둔산동': '대전', '노은동': '대전', '문창동': '대전',
      '대성동': '대전', '읍내동': '대전', '비래동': '대전', '판암동': '대전',
      // 울산
      '무거동': '울산', '삼산동': '울산', '신정동': '울산',
      '농소동': '울산', '삼남읍': '울산', '언양읍': '울산',
      '성남동': '울산', '전하동': '울산',
      // 세종
      '한솔동': '세종', '아름동': '세종', '조치원읍': '세종',
      '소담동': '세종', '고운동': '세종', '도담동': '세종',
      // 강원
      '약사동': '강원', '단계동': '강원', '옥천동': '강원', '조양동': '강원',
      '천곡동': '강원', '남양동': '강원', '황지동': '강원', '영월읍': '강원',
      '정선읍': '강원', '홍천읍': '강원', '원주': '강원', '춘천': '강원',
      '강릉': '강원', '속초': '강원', '철원': '강원', '양양': '강원',
      '고성': '강원',
      // 충북
      '상당구': '충북', '흥덕구': '충북', '서원구': '충북', '청원구': '충북',
      '교현동': '충북', '의림동': '충북', '청주': '충북', '충주': '충북',
      '제천': '충북', '보은': '충북', '옥천': '충북', '영동': '충북',
      '진천': '충북', '음성': '충북', '단양': '충북', '증평': '충북',
      // 충남
      '신방동': '충남', '불당동': '충남', '신관동': '충남', '대천동': '충남',
      '모종동': '충남', '동문동': '충남', '취암동': '충남', '당진읍': '충남',
      '홍성읍': '충남', '천안': '충남', '공주': '충남', '서산': '충남',
      '아산': '충남', '논산': '충남', '당진': '충남', '태안': '충남',
      '부여': '충남', '서천': '충남', '금산': '충남',
      // 전북
      '효자동': '전북', '완산구': '전북', '덕진구': '전북', '조촌동': '전북',
      '영등동': '전북', '상동': '전북', '왕정동': '전북', '전주': '전북',
      '군산': '전북', '익산': '전북', '정읍': '전북', '남원': '전북',
      '김제': '전북', '완주': '전북', '진안': '전북', '무주': '전북',
      '고창': '전북', '부안': '전북',
      // 전남
      '산정동': '전남', '돌산읍': '전남', '문수동': '전남', '조례동': '전남',
      '덕암동': '전남', '송월동': '전남', '광양읍': '전남', '목포': '전남',
      '여수': '전남', '순천': '전남', '나주': '전남', '광양': '전남',
      '담양': '전남', '곡성': '전남', '고흥': '전남', '화순': '전남',
      '장흥': '전남', '강진': '전남', '해남': '전남', '영암': '전남',
      '무안': '전남', '영광': '전남', '완도': '전남', '진도': '전남',
      // 경북
      '대잠동': '경북', '해도동': '경북', '황성동': '경북', '응명동': '경북',
      '옥야동': '경북', '원평동': '경북', '영주동': '경북', '야사동': '경북',
      '무양동': '경북', '중방동': '경북', '포항': '경북', '경주': '경북',
      '김천': '경북', '안동': '경북', '구미': '경북', '영주': '경북',
      '영천': '경북', '상주': '경북', '경산': '경북', '칠곡': '경북',
      '예천': '경북', '봉화': '경북', '울진': '경북', '의성': '경북',
      '청송': '경북', '영양': '경북', '영덕': '경북', '청도': '경북',
      '고령': '경북', '성주': '경북',
      // 경남
      '의창구': '경남', '성산구': '경남', '회원구': '경남', '진해구': '경남',
      '망경동': '경남', '무전동': '경남', '내동': '경남', '내이동': '경남',
      '고현동': '경남', '북부동': '경남', '창원': '경남', '진주': '경남',
      '통영': '경남', '김해': '경남', '밀양': '경남', '거제': '경남',
      '양산': '경남', '사천': '경남', '의령': '경남', '함안': '경남',
      '창녕': '경남', '남해': '경남', '하동': '경남', '산청': '경남',
      '함양': '경남', '거창': '경남', '합천': '경남',
      // 제주
      '이도동': '제주', '연동': '제주', '도두동': '제주', '서귀동': '제주',
      '성산읍': '제주', '대정읍': '제주', '제주': '제주', '서귀포': '제주',
    };
    return map[stationName];
  }
}
