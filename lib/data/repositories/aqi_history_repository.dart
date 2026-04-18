import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/local_database.dart';
import '../../core/engine/aqi_grade_converter.dart';
import '../../core/services/aqi_polling_service.dart';

/// AQI 히스토리 Repository
///
/// Care 탭 Area Chart에 필요한 데이터를 SQLite + 예보 등급 기반으로 조립.
///
/// 차트 구성:
/// - 과거 6시간: SQLite aqi_records 실측값
/// - 미래 3시간: 에어코리아 예보 등급 → Spline 보간
///
/// 데이터 신선도:
/// - lastDataTime으로 "N분 전 업데이트됨" UI 표시 지원
class AqiHistoryRepository {
  final LocalDatabase _db;
  final AqiPollingService _polling;
  final SharedPreferences _prefs;

  AqiHistoryRepository({
    required LocalDatabase db,
    required AqiPollingService polling,
    required SharedPreferences prefs,
  })  : _db = db,
        _polling = polling,
        _prefs = prefs;

  // ── 차트 데이터 조회 ─────────────────────────────────────

  /// Area Chart용 데이터 조립
  ///
  /// [forecastGrade] : 향후 예보 등급 ('좋음'|'보통'|'나쁨'|'매우나쁨')
  /// [profile]       : 관심지역 Fallback용
  Future<AqiChartData> getChartData({
    required String forecastGrade,
    UserProfile? profile,
  }) async {
    final station = _polling.resolveStation(_prefs, profile);
    if (station == null) {
      return AqiChartData.noStation();
    }

    final records = await _db.getRecentAqiRecords(
      stationName: station,
      hours: 6,
    );

    final points = AqiGradeConverter.buildChartPoints(
      pastRecords: records,
      targetGrade: forecastGrade,
      horizonHours: 3,
    );

    final lastRecord = records.isNotEmpty ? records.last : null;

    return AqiChartData(
      stationName: station,
      points: points,
      lastDataTime: lastRecord?.dataTime,
      fetchedAt: lastRecord?.fetchedAt,
      hasEnoughData: records.length >= 2,
      currentPm25: lastRecord?.pm25Value?.toDouble(),
    );
  }

  /// 현재 측정소 이름
  String? get currentStation =>
      _prefs.getString(AppConstants.prefStationName);
}

// ── 차트 데이터 모델 ──────────────────────────────────────

/// Area Chart 전용 데이터 컨테이너
class AqiChartData {
  final String? stationName;
  final List<ChartPoint> points;

  /// 에어코리아 기준 측정 시각 (데이터 신선도 표시용)
  final DateTime? lastDataTime;

  /// 앱이 API를 조회한 시각
  final DateTime? fetchedAt;

  /// false = Zero-day, 차트 대신 "수집 중" UI 표시
  final bool hasEnoughData;

  /// 현재 PM2.5 (Hero Section 트리거 판단용)
  final double? currentPm25;

  const AqiChartData({
    required this.stationName,
    required this.points,
    this.lastDataTime,
    this.fetchedAt,
    required this.hasEnoughData,
    this.currentPm25,
  });

  factory AqiChartData.noStation() => const AqiChartData(
        stationName: null,
        points: [],
        hasEnoughData: false,
        currentPm25: null,
      );

  // ── 신선도 표시 헬퍼 ──────────────────────────────────────

  /// "오후 2:00 기준 데이터" 형태 — 에어코리아 측정 시각 기반
  String get freshnessLabel {
    if (lastDataTime == null) return '데이터 수집 중';
    final h = lastDataTime!.hour;
    final m = lastDataTime!.minute.toString().padLeft(2, '0');
    final period = h < 12 ? '오전' : '오후';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $displayH:$m 기준 데이터';
  }

  /// "방금 전" / "5분 전" / "1시간 전" 형태 — 앱 조회 시각 기반
  String get updatedAgoLabel {
    if (fetchedAt == null) return '';
    final diff = DateTime.now().difference(fetchedAt!).inMinutes;
    if (diff < 1)  return '방금 전 업데이트';
    if (diff < 60) return '$diff분 전 업데이트';
    final h = diff ~/ 60;
    return '$h시간 전 업데이트';
  }

  // ── 차트 분리 헬퍼 ───────────────────────────────────────

  /// 실측 포인트만 (Area Chart 실선 영역)
  List<ChartPoint> get measuredPoints =>
      points.where((p) => !p.isForecast).toList();

  /// 예측 포인트만 (반투명 점선 영역)
  List<ChartPoint> get forecastPoints =>
      points.where((p) => p.isForecast).toList();

  // ── 마스크 해제 시점 ──────────────────────────────────────

  /// 3h 예측 범위 내 마스크 해제 가능 여부 + 시각
  SafeTimeResult safeTimeResult(double tFinal) {
    final fp = forecastPoints;
    if (fp.isEmpty) return SafeTimeResult.noData();

    for (final p in fp) {
      if ((p.pm25 ?? double.infinity) < tFinal) {
        return SafeTimeResult.found(p.time);
      }
    }
    return SafeTimeResult.notWithin3h();
  }
}

// ── 마스크 해제 시점 결과 ─────────────────────────────────

enum _SafeTimeKind { found, notWithin3h, noData }

/// 마스크 해제 가능 시점 판단 결과
///
/// found       : 3h 내 안전 시각 존재 → "오후 6시부터 벗으셔도 됩니다"
/// notWithin3h : 3h 예측 범위 내 안전 없음 → "당분간 마스크가 필요합니다"
/// noData      : 예측 데이터 없음 → UI에서 해제 시점 표시 자체를 숨김
class SafeTimeResult {
  final _SafeTimeKind _kind;
  final DateTime? time;

  SafeTimeResult._({required _SafeTimeKind kind, this.time}) : _kind = kind;

  factory SafeTimeResult.found(DateTime t) =>
      SafeTimeResult._(kind: _SafeTimeKind.found, time: t);

  factory SafeTimeResult.notWithin3h() =>
      SafeTimeResult._(kind: _SafeTimeKind.notWithin3h);

  factory SafeTimeResult.noData() =>
      SafeTimeResult._(kind: _SafeTimeKind.noData);

  bool get isFound       => _kind == _SafeTimeKind.found;
  bool get isNotWithin3h => _kind == _SafeTimeKind.notWithin3h;
  bool get isNoData      => _kind == _SafeTimeKind.noData;

  /// Time Guide 문구 반환
  String toGuideText() {
    if (isFound && time != null) {
      final h = time!.hour;
      final m = time!.minute.toString().padLeft(2, '0');
      final period = h < 12 ? '오전' : '오후';
      final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$period $displayH:$m부터 마스크를 벗으셔도 좋습니다';
    }
    if (isNotWithin3h) return '당분간 마스크 착용을 유지해 주세요';
    return ''; // noData: UI에서 숨김
  }
}
