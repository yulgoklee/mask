import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/dust_data.dart';
import '../../data/models/forecast_models.dart';
import '../config/app_config.dart';
import '../constants/dust_standards.dart';

/// 에어코리아 OpenAPI 통신 서비스
/// API: https://apis.data.go.kr/B552584/ArpltnInforInqireSvc
class AirKoreaService {
  static const String _baseUrl =
      'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc';
  static const String _cacheKey = 'dust_cache';
  // app_config.dart (gitignored)에서 키를 주입 — 절대 소스에 직접 입력하지 마세요
  static const String _apiKey = AppConfig.airKoreaApiKey;

  final Dio _dio;
  final SharedPreferences _prefs;

  AirKoreaService(this._prefs)
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      responseHeader: false,
      responseBody: false,
      requestBody: false,
      request: true,
      logPrint: (o) => debugPrint('[DIO] $o'),
    ));
  }

  /// 현재 미세먼지 데이터 조회 (캐시 우선)
  Future<DustData?> getDustData(String stationName) async {
    // 1. 캐시 확인
    final cached = _getCachedData(stationName);
    if (cached != null && cached.isCacheValid) {
      return cached;
    }

    // 2. API 호출
    return await _fetchFromApi(stationName);
  }

  /// API에서 실시간 데이터 강제 조회
  Future<DustData?> _fetchFromApi(String stationName) async {
    try {
      // serviceKey의 +, = 문자가 Dio queryParameters에서 깨지므로 URL 직접 조립
      final encodedStation = Uri.encodeComponent(stationName);
      final url = '$_baseUrl/getMsrstnAcctoRltmMesureDnsty'
          '?serviceKey=$_apiKey'
          '&returnType=json&numOfRows=1&pageNo=1'
          '&stationName=$encodedStation&dataTerm=DAILY&ver=1.0';
      debugPrint('[AirKorea] 요청 URL: $url');
      final response = await _dio.get(url);

      final data = response.data;
      debugPrint('[AirKorea] 응답: $data');

      if (data is! Map) {
        debugPrint('[AirKorea] 응답이 JSON이 아님: ${data.runtimeType}');
        return null;
      }

      final header = data['response']?['header'];
      final resultCode = header?['resultCode']?.toString();
      if (resultCode != null && resultCode != '00') {
        debugPrint('[AirKorea] API 오류코드: $resultCode / ${header?['resultMsg']}');
        return null;
      }

      final items = data['response']?['body']?['items'] as List?;
      debugPrint('[AirKorea] items 개수: ${items?.length}');
      if (items == null || items.isEmpty) return null;

      final dustData = DustData.fromJson(items.first as Map<String, dynamic>);
      _saveCache(stationName, dustData);
      return dustData;
    } on DioException catch (e) {
      debugPrint('[AirKorea] DioException: ${e.type} / ${e.message}');
      final cached = _getCachedData(stationName);
      if (cached != null) return cached;
      throw Exception('API 호출 실패: ${e.message}');
    } catch (e) {
      debugPrint('[AirKorea] 알 수 없는 오류: $e');
      return null;
    }
  }

  /// 시간별 데이터 — 현재 측정값 + 24시간 예보
  /// 미래 시간은 측정 시각 기준으로 연속 생성 (DateTime.now()와 무관하게 시간 연속성 보장)
  /// DioException → rethrow (네트워크 오류는 UI에서 인지할 수 있도록)
  Future<List<HourlyDustData>> getHourlyData(String stationName) async {
    try {
      final encodedStation = Uri.encodeComponent(stationName);
      final url = '$_baseUrl/getMsrstnAcctoRltmMesureDnsty'
          '?serviceKey=$_apiKey'
          '&returnType=json&numOfRows=1&pageNo=1'
          '&stationName=$encodedStation&dataTerm=DAILY&ver=1.0';
      final response = await _dio.get(url);
      final data = response.data;
      if (data is! Map) return [];
      final items = data['response']?['body']?['items'] as List?;
      if (items == null || items.isEmpty) return [];

      final map = items.first as Map<String, dynamic>;
      // API dataTime 파싱 (형식: "2026-03-31 23:00")
      final rawTime = map['dataTime'] as String? ?? '';
      final measureTime = DateTime.tryParse(rawTime) ?? DateTime.now();

      final current = HourlyDustData(
        time: measureTime,
        pm10: _parseInt(map['pm10Value']),
        pm25: _parseInt(map['pm25Value']),
        pm10Grade: DustStandards.getPm10Grade(_parseInt(map['pm10Value']) ?? 0),
        pm25Grade: DustStandards.getPm25Grade(_parseInt(map['pm25Value']) ?? 0),
        isForecast: false,
      );

      // 단기 예보 등급 조회 (시도명 추출 후 사용)
      // 미래 슬롯의 등급을 일별 예보 기준으로 적용 (당일/내일/모레)
      final sidoName = _localSidoMap(stationName);
      final forecasts = await getWeeklyForecast(sidoName: sidoName);
      // 날짜 문자열("2026-04-01") → WeeklyForecastData 맵
      final forecastMap = {
        for (final f in forecasts)
          '${f.date.year}-${f.date.month.toString().padLeft(2,'0')}-${f.date.day.toString().padLeft(2,'0')}': f
      };

      // 미래 24시간: 측정 시각 기준으로 1시간씩 증가 (시간 연속성 보장)
      final future = List.generate(24, (i) {
        final futureTime = measureTime.add(Duration(hours: i + 1));
        final dayKey = '${futureTime.year}-${futureTime.month.toString().padLeft(2,'0')}-${futureTime.day.toString().padLeft(2,'0')}';
        final forecast = forecastMap[dayKey];
        return HourlyDustData(
          time: futureTime,
          pm10: null,
          pm25: null,
          // 해당 날짜의 예보 등급 사용, 없으면 현재 등급 유지
          pm10Grade: forecast?.pm10Grade ?? current.pm10Grade,
          pm25Grade: forecast?.pm25Grade ?? current.pm25Grade,
          isForecast: true,
        );
      });

      return [current, ...future];
    } on DioException catch (e) {
      // 네트워크 오류 → rethrow (UI가 error state 표시 가능하도록)
      debugPrint('[AirKorea] 시간별 데이터 네트워크 오류: ${e.message}');
      throw Exception('네트워크에 연결할 수 없어요.\n잠시 후 다시 시도해 주세요.');
    } catch (e) {
      // 파싱 등 기타 오류 → 빈 리스트 (조용히 실패)
      debugPrint('[AirKorea] 시간별 데이터 오류: $e');
      return [];
    }
  }

  static int? _parseInt(dynamic v) {
    if (v == null || v == '-') return null;
    return int.tryParse(v.toString());
  }

  /// 시간별 과거 데이터 (24시간) — 상세 화면용
  Future<List<HourlyDustData>> getHourlyHistory(String stationName) async {
    try {
      final encodedStation = Uri.encodeComponent(stationName);
      final url = '$_baseUrl/getMsrstnAcctoRltmMesureDnsty'
          '?serviceKey=$_apiKey'
          '&returnType=json&numOfRows=24&pageNo=1'
          '&stationName=$encodedStation&dataTerm=DAILY&ver=1.0';
      final response = await _dio.get(url);
      final data = response.data;
      if (data is! Map) return [];
      final items = data['response']?['body']?['items'] as List?;
      if (items == null) return [];
      final result = items.map((e) {
        final map = e as Map<String, dynamic>;
        final t = DateTime.tryParse(map['dataTime'] as String? ?? '') ?? DateTime.now();
        return HourlyDustData(
          time: t,
          pm10: _parseInt(map['pm10Value']),
          pm25: _parseInt(map['pm25Value']),
          pm10Grade: DustStandards.getPm10Grade(_parseInt(map['pm10Value']) ?? 0),
          pm25Grade: DustStandards.getPm25Grade(_parseInt(map['pm25Value']) ?? 0),
          isForecast: false,
        );
      }).toList();
      result.sort((a, b) => a.time.compareTo(b.time)); // 오래된 순
      return result;
    } catch (_) {
      return [];
    }
  }

  /// 단기 예보 — WeeklyForecastData 리스트 (PM10+PM25, 최대 3일)
  /// 에어코리아 API는 오늘 기준 최대 3일(오늘/내일/모레)만 제공
  /// 하루 3회 발표(05시·11시·17시) 중 가장 최신 발표를 사용
  /// ※ 자정~04시 사이는 당일 첫 발표(05시)가 없으므로 전날 날짜로 조회
  Future<List<WeeklyForecastData>> getWeeklyForecast({String? sidoName}) async {
    try {
      final now = DateTime.now();
      // 05시 이전이면 아직 당일 예보 미발표 → 전날 17시 발표 기준으로 조회
      final searchBase = now.hour < 5
          ? now.subtract(const Duration(days: 1))
          : now;
      final today = DateTime(now.year, now.month, now.day); // 오늘 날짜 (필터용)
      final dateStr =
          '${searchBase.year}-${searchBase.month.toString().padLeft(2, '0')}-${searchBase.day.toString().padLeft(2, '0')}';

      final pm10Url = '$_baseUrl/getMinuDustFrcstDspth'
          '?serviceKey=$_apiKey'
          '&returnType=json&numOfRows=20&pageNo=1'
          '&searchDate=$dateStr&informCode=PM10';
      final pm25Url = '$_baseUrl/getMinuDustFrcstDspth'
          '?serviceKey=$_apiKey'
          '&returnType=json&numOfRows=20&pageNo=1'
          '&searchDate=$dateStr&informCode=PM25';

      final pm10Resp = await _dio.get(pm10Url);
      final pm25Resp = await _dio.get(pm25Url);

      final pm10Items =
          pm10Resp.data['response']?['body']?['items'] as List? ?? [];
      final pm25Items =
          pm25Resp.data['response']?['body']?['items'] as List? ?? [];

      // date → {grade, dataTime} — 동일 날짜 중 가장 최신 발표를 사용
      final pm10Map = <String, ({DustGrade? grade, String dataTime})>{};
      for (final item in pm10Items) {
        final date = item['informData'] as String? ?? '';
        if (date.isEmpty) continue;
        final dataTime = item['dataTime'] as String? ?? '';
        final existing = pm10Map[date];
        if (existing == null || dataTime.compareTo(existing.dataTime) >= 0) {
          final raw = item['informGrade'] as String? ?? '';
          final grade = sidoName != null
              ? _filterForecastBySido(raw, sidoName)
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
              ? _filterForecastBySido(raw, sidoName)
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
      // 오늘 이전 날짜(전날 조회 시 어제 예보 포함될 수 있음)는 제외
      return result.where((d) => !d.date.isBefore(today)).toList();
    } on DioException catch (e) {
      debugPrint('[AirKorea] 단기예보 네트워크 오류: ${e.message}');
      throw Exception('예보 데이터를 불러올 수 없어요.\n잠시 후 다시 시도해 주세요.');
    } catch (e) {
      debugPrint('[AirKorea] 단기예보 오류: $e');
      return [];
    }
  }

  DustGrade? _firstGrade(String informGrade) {
    if (informGrade.isEmpty) return null;
    final parts = informGrade.split(',').first.split(':');
    if (parts.length < 2) return null;
    return DustGrade.fromString(parts[1].trim());
  }

  /// 측정소명 검색 (getMsrstnList) → 자동완성용
  Future<List<String>> searchStations(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final encodedKeyword = Uri.encodeComponent(keyword.trim());
      final url = '$_baseUrl/getMsrstnList'
          '?serviceKey=$_apiKey'
          '&returnType=json&numOfRows=20&pageNo=1'
          '&stationName=$encodedKeyword';
      final response = await _dio.get(url);
      final data = response.data;
      if (data is! Map) return [];
      final items = data['response']?['body']?['items'] as List?;
      if (items == null) return [];
      return items
          .map((e) => e['stationName']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[AirKorea] 측정소 검색 오류: $e');
      return [];
    }
  }

  /// 가장 가까운 측정소 조회 (로컬 좌표 매핑, API 불필요)
  Future<String?> getNearestStation(double lat, double lng) async {
    if (lat < 33.0 || lat > 38.7 || lng < 124.5 || lng > 132.0) {
      debugPrint('[AirKorea] 한국 외 위치: lat=$lat, lng=$lng');
      return null;
    }
    final station = _findNearestStationLocal(lat, lng);
    debugPrint('[AirKorea] 가까운 측정소: $station (lat=$lat, lng=$lng)');
    return station;
  }

  /// 주요 에어코리아 측정소 좌표 기반 최근접 탐색 (Haversine)
  static String _findNearestStationLocal(double lat, double lng) {
    const stations = [
      // 서울
      ('종로구', 37.5720, 126.9794), ('중구', 37.5637, 126.9979),
      ('용산구', 37.5326, 126.9901), ('성동구', 37.5633, 127.0366),
      ('광진구', 37.5383, 127.0822), ('동대문구', 37.5744, 127.0396),
      ('성북구', 37.5894, 127.0167), ('노원구', 37.6556, 127.0663),
      ('은평구', 37.6027, 126.9291), ('서대문구', 37.5791, 126.9368),
      ('마포구', 37.5540, 126.9098), ('강서구', 37.5520, 126.8322),
      ('구로구', 37.4954, 126.8874), ('영등포구', 37.5260, 126.8964),
      ('동작구', 37.5122, 126.9395), ('관악구', 37.4784, 126.9516),
      ('서초구', 37.4837, 127.0324), ('강남구', 37.5172, 127.0474),
      ('송파구', 37.5145, 127.1059), ('강동구', 37.5301, 127.1238),
      ('도봉구', 37.6687, 127.0471), ('강북구', 37.6397, 127.0257),
      ('중랑구', 37.6063, 127.0927), ('양천구', 37.5170, 126.8667),
      ('금천구', 37.4601, 126.9016),
      // 경기
      ('수원', 37.2636, 127.0286), ('성남', 37.4467, 127.1375),
      ('고양', 37.6582, 126.8320), ('용인', 37.2411, 127.1776),
      ('부천', 37.5036, 126.7659), ('안산', 37.3219, 126.8309),
      ('안양', 37.3942, 126.9568), ('남양주', 37.6360, 127.2165),
      ('화성', 37.1996, 126.8314), ('평택', 36.9921, 127.1127),
      ('의정부', 37.7381, 127.0337), ('파주', 37.7600, 126.7800),
      ('광주', 37.4294, 127.2553), ('김포', 37.6152, 126.7153),
      ('시흥', 37.3800, 126.8030), ('하남', 37.5392, 127.2148),
      // 인천
      ('인천', 37.4562, 126.7052), ('연수구', 37.3906, 126.6478),
      ('부평구', 37.5077, 126.7218), ('계양구', 37.5438, 126.7377),
      // 부산
      ('부산', 35.1796, 129.0756), ('해운대구', 35.1631, 129.1636),
      ('동래구', 35.2070, 129.0860), ('사하구', 35.1046, 128.9746),
      ('북구', 35.2023, 128.9965), ('강서구', 35.2135, 128.9812),
      // 대구
      ('대구', 35.8704, 128.5915), ('수성구', 35.8578, 128.6306),
      ('달서구', 35.8298, 128.5326),
      // 광주
      ('광주광역시', 35.1595, 126.8526),
      // 대전
      ('대전', 36.3504, 127.3845),
      // 울산
      ('울산', 35.5384, 129.3114),
      // 세종
      ('세종', 36.4800, 127.2890),
      // 강원
      ('춘천', 37.8813, 127.7300), ('원주', 37.3420, 127.9200),
      ('강릉', 37.7519, 128.8760),
      // 충북
      ('청주', 36.6424, 127.4890), ('충주', 36.9910, 127.9259),
      // 충남
      ('천안', 36.8151, 127.1139), ('아산', 36.7898, 127.0022),
      // 전북
      ('전주', 35.8242, 127.1479), ('익산', 35.9483, 126.9577),
      // 전남
      ('여수', 34.7604, 127.6622), ('순천', 34.9506, 127.4874),
      // 경북
      ('포항', 36.0190, 129.3435), ('경주', 35.8562, 129.2247),
      ('구미', 36.1194, 128.3444), ('안동', 36.5684, 128.7294),
      // 경남
      ('창원', 35.2280, 128.6811), ('진주', 35.1800, 128.1075),
      ('김해', 35.2284, 128.8892),
      // 제주
      ('제주', 33.4996, 126.5312), ('서귀포', 33.2541, 126.5600),
    ];

    String nearest = stations.first.$1;
    double minDist = double.infinity;

    for (final s in stations) {
      final d = _haversine(lat, lng, s.$2, s.$3);
      if (d < minDist) {
        minDist = d;
        nearest = s.$1;
      }
    }
    return nearest;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// WGS84 위경도 → 한국 TM 좌표 변환 (중부원점 기준)
  static Map<String, double> _wgs84ToTm(double latDeg, double lonDeg) {
    const double a = 6378137.0;
    const double f = 1.0 / 298.257222101;
    const double k0 = 1.0;
    const double lon0 = 127.0 * pi / 180;
    const double lat0 = 38.0 * pi / 180;
    const double fe = 200000.0;
    const double fn = 600000.0;

    final double e2 = 2 * f - f * f;
    final double ep2 = e2 / (1 - e2);

    final double lat = latDeg * pi / 180;
    final double lon = lonDeg * pi / 180;

    final double sinLat = sin(lat);
    final double cosLat = cos(lat);
    final double tanLat = tan(lat);

    final double N = a / sqrt(1 - e2 * sinLat * sinLat);
    final double T = tanLat * tanLat;
    final double C = ep2 * cosLat * cosLat;
    final double A = (lon - lon0) * cosLat;

    double mArc(double phi) {
      final double e4 = e2 * e2;
      final double e6 = e4 * e2;
      return a * (
        (1 - e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256) * phi
        - (3 * e2 / 8 + 3 * e4 / 32 + 45 * e6 / 1024) * sin(2 * phi)
        + (15 * e4 / 256 + 45 * e6 / 1024) * sin(4 * phi)
        - (35 * e6 / 3072) * sin(6 * phi)
      );
    }

    final double x = k0 * N * (
      A + (1 - T + C) * pow(A, 3) / 6
      + (5 - 18 * T + T * T + 72 * C - 58 * ep2) * pow(A, 5) / 120
    ) + fe;

    final double y = k0 * (
      mArc(lat) - mArc(lat0)
      + N * tanLat * (
        A * A / 2
        + (5 - T + 9 * C + 4 * C * C) * pow(A, 4) / 24
        + (61 - 58 * T + T * T + 600 * C - 330 * ep2) * pow(A, 6) / 720
      )
    ) + fn;

    return {'x': x, 'y': y};
  }

  /// 측정소의 시도명 조회 (로컬 매핑 우선, API fallback)
  Future<String?> getSidoForStation(String stationName) async {
    // 1. 로컬 매핑 (자치구명 → 시도)
    final local = _localSidoMap(stationName);
    if (local != null) return local;

    // 2. 캐시
    final cached = _prefs.getString('sido_$stationName');
    if (cached != null) return cached;

    // 3. API 호출
    try {
      final encodedName = Uri.encodeComponent(stationName);
      final url = '$_baseUrl/getMsrstnList'
          '?serviceKey=$_apiKey'
          '&returnType=json&numOfRows=1&pageNo=1'
          '&stationName=$encodedName';
      final response = await _dio.get(url);
      final items = response.data['response']?['body']?['items'] as List?;
      if (items == null || items.isEmpty) return null;

      final sido = items.first['sidoName'] as String?;
      if (sido != null) _prefs.setString('sido_$stationName', sido);
      return sido;
    } catch (_) {
      return null;
    }
  }

  /// 자치구·시·군 이름으로 시도 추정 (공개 static — 화면에서 직접 사용 가능)
  static String? sidoForStation(String station) => _localSidoMapStatic(station);

  static String? _localSidoMapStatic(String station) {
    const map = {
      '종로구': '서울', '중구': '서울', '용산구': '서울', '성동구': '서울',
      '광진구': '서울', '동대문구': '서울', '중랑구': '서울', '성북구': '서울',
      '강북구': '서울', '도봉구': '서울', '노원구': '서울', '은평구': '서울',
      '서대문구': '서울', '마포구': '서울', '양천구': '서울', '강서구': '서울',
      '구로구': '서울', '금천구': '서울', '영등포구': '서울', '동작구': '서울',
      '관악구': '서울', '서초구': '서울', '강남구': '서울', '송파구': '서울',
      '강동구': '서울',
      '해운대구': '부산', '수영구': '부산', '연제구': '부산', '동래구': '부산',
      '남구': '부산', '북구': '부산', '사하구': '부산', '사상구': '부산',
      '수성구': '대구', '달서구': '대구', '달성군': '대구',
      '연수구': '인천', '부평구': '인천', '계양구': '인천', '남동구': '인천',
      '수원': '경기', '성남': '경기', '고양': '경기', '용인': '경기',
      '부천': '경기', '안산': '경기', '안양': '경기', '남양주': '경기',
      '화성': '경기', '평택': '경기', '의정부': '경기', '파주': '경기',
      '춘천': '강원', '원주': '강원', '강릉': '강원',
      '청주': '충북', '충주': '충북',
      '천안': '충남', '아산': '충남',
      '전주': '전북', '익산': '전북',
      '여수': '전남', '순천': '전남',
      '포항': '경북', '경주': '경북', '구미': '경북', '안동': '경북',
      '창원': '경남', '진주': '경남', '김해': '경남',
      '제주': '제주', '서귀포': '제주',
    };
    return map[station];
  }

  /// 자치구·시·군 이름으로 시도 추정 (static 버전에 위임)
  String? _localSidoMap(String station) => _localSidoMapStatic(station);

  /// 내일 예보 조회 - 해당 시도만 필터링
  Future<String?> getTomorrowForecast({String? sidoName}) async {
    try {
      final now = DateTime.now();
      // 05시 이전이면 전날 발표 기준 조회
      final searchBase = now.hour < 5 ? now.subtract(const Duration(days: 1)) : now;
      final dateStr =
          '${searchBase.year}-${searchBase.month.toString().padLeft(2, '0')}-${searchBase.day.toString().padLeft(2, '0')}';

      final url = '$_baseUrl/getMinuDustFrcstDspth'
          '?serviceKey=$_apiKey'
          '&returnType=json&numOfRows=1&pageNo=1'
          '&searchDate=$dateStr&informCode=PM25';
      final response = await _dio.get(url);

      final items = response.data['response']?['body']?['items'] as List?;
      if (items == null || items.isEmpty) return null;

      final informGrade = items.first['informGrade'] as String?;
      if (informGrade == null) return null;
      if (sidoName == null) return informGrade;

      // grade → label 문자열로 변환하여 반환 (String? 반환 타입 유지)
      return _filterForecastBySido(informGrade, sidoName)?.label;
    } catch (_) {
      return null;
    }
  }

  /// "서울 : 나쁨,경기 : 보통,..." 에서 해당 시도 grade만 추출
  DustGrade? _filterForecastBySido(String informGrade, String sidoName) {
    final targets = _sidoToForecastRegions(sidoName);

    for (final entry in informGrade.split(',').map((e) => e.trim())) {
      final parts = entry.split(':');
      if (parts.length < 2) continue;
      final region = parts[0].trim();
      if (targets.any((t) => region.contains(t) || t.contains(region))) {
        return DustGrade.fromString(parts[1].trim());
      }
    }
    // 매핑 실패 시 첫 번째 항목의 grade 반환
    return _firstGrade(informGrade);
  }

  List<String> _sidoToForecastRegions(String sido) {
    switch (sido) {
      case '경기': return ['경기남부', '경기북부'];
      case '강원': return ['영동', '영서'];
      default:    return [sido];
    }
  }

  // ── 캐시 ──────────────────────────────────────────────

  DustData? _getCachedData(String stationName) {
    final raw = _prefs.getString('${_cacheKey}_$stationName');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return DustData.fromCacheJson(json);
    } catch (_) {
      return null;
    }
  }

  void _saveCache(String stationName, DustData data) {
    _prefs.setString(
      '${_cacheKey}_$stationName',
      jsonEncode(data.toJson()),
    );
  }

  void clearCache() {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cacheKey));
    for (final key in keys) {
      _prefs.remove(key);
    }
  }
}

// HourlyDustData, WeeklyForecastData → lib/data/models/forecast_models.dart 로 이동
