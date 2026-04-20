import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/aqi_record.dart';
import '../../data/models/user_profile.dart';
import '../constants/app_constants.dart';
import '../database/local_database.dart';
import 'dust_data_source.dart';

/// AQI 주기적 폴링 + SQLite 저장 서비스
///
/// 책임:
/// 1. 현재 AQI 수치 조회 → aqi_records 저장 (15분 주기)
/// 2. Zero-day 시딩: DB 기록 부족 시 24시간치 과거 데이터 일괄 수집
/// 3. 측정소 Null → 5km Fallback (관심지역 → GPS 순)
class AqiPollingService {
  final DustDataSource _airKorea;
  final LocalDatabase _db;

  AqiPollingService({
    required DustDataSource airKorea,
    required LocalDatabase db,
  })  : _airKorea = airKorea,
        _db = db;

  // ── 측정소 결정 ────────────────────────────────────────────

  /// 사용할 측정소 결정 (우선순위)
  ///
  /// 1. GPS 현재 측정소 (prefs에 저장된 값)
  /// 2. 사용자 관심지역 집
  /// 3. 사용자 관심지역 회사
  String? resolveStation(SharedPreferences prefs, UserProfile? profile) {
    final gpsStation = prefs.getString(AppConstants.prefStationName);
    if (gpsStation != null && gpsStation.isNotEmpty) return gpsStation;

    final home = profile?.homeStationName ?? '';
    if (home.isNotEmpty) return home;

    final office = profile?.officeStationName ?? '';
    if (office.isNotEmpty) return office;

    return null;
  }

  // ── 단건 폴링 ──────────────────────────────────────────────

  /// 현재 AQI 수치 1건 조회 → SQLite 저장
  ///
  /// 측정소 Null 데이터 시 자동으로 5km 이내 인근 측정소 Fallback 없음
  /// (GPS Fallback은 BackgroundService._tryRefreshStation에서 처리)
  Future<bool> pollAndSave(String stationName) async {
    try {
      final dust = await _airKorea.getDustData(stationName);
      if (dust == null) {
        debugPrint('[AqiPolling] $stationName 데이터 null');
        return false;
      }

      await _db.insertAqiRecord(AqiRecord(
        stationName: stationName,
        pm25Value: dust.pm25Value,
        pm10Value: dust.pm10Value,
        pm25Grade: dust.pm25Grade,
        dataTime: dust.dataTime,
        fetchedAt: DateTime.now(),
      ));
      debugPrint('[AqiPolling] 저장 완료: $stationName '
          'PM2.5=${dust.pm25Value} @ ${dust.dataTime}');
      return true;
    } catch (e) {
      debugPrint('[AqiPolling] pollAndSave 실패: $e');
      return false;
    }
  }

  // ── Zero-day 시딩 ──────────────────────────────────────────

  /// 앱 최초 설치 시 과거 24시간 데이터 일괄 수집
  ///
  /// DB에 기록이 [minRecords]개 미만일 때만 실행
  /// AirKorea API는 최대 24시간 실측치 제공 → 차트 즉시 표시 가능
  Future<SeedResult> seedInitialData(
    String stationName, {
    int minRecords = 3,
  }) async {
    try {
      final existing =
          await _db.getRecentAqiRecords(stationName: stationName, hours: 24);
      if (existing.length >= minRecords) {
        debugPrint('[AqiPolling] 시딩 불필요 (기록 ${existing.length}개)');
        return SeedResult.skipped;
      }

      debugPrint('[AqiPolling] 시딩 시작: $stationName');
      final history = await _airKorea.getHourlyHistory(stationName);
      if (history.isEmpty) return SeedResult.failed;

      int saved = 0;
      for (final h in history) {
        if (h.pm25 == null) continue;
        await _db.insertAqiRecord(AqiRecord(
          stationName: stationName,
          pm25Value: h.pm25,
          pm10Value: h.pm10,
          pm25Grade: h.pm25Grade.label,
          dataTime: h.time,
          fetchedAt: DateTime.now(),
        ));
        saved++;
      }
      debugPrint('[AqiPolling] 시딩 완료: $saved건');
      return saved > 0 ? SeedResult.success : SeedResult.failed;
    } catch (e) {
      debugPrint('[AqiPolling] 시딩 실패: $e');
      return SeedResult.failed;
    }
  }

  // ── 폴링 + 시딩 통합 진입점 ──────────────────────────────

  static const String _prefPollTimePrefix = 'aqi_last_poll_';
  static const int _cooldownMinutes = 60;

  /// 백그라운드 태스크에서 호출하는 통합 메서드
  ///
  /// 1. 측정소당 1시간 쿨다운 — 이전 폴링으로부터 60분 미만이면 스킵
  /// 2. Zero-day면 시딩 먼저
  /// 3. 현재 수치 1건 저장
  Future<void> runPollingCycle({
    required SharedPreferences prefs,
    UserProfile? profile,
  }) async {
    final station = resolveStation(prefs, profile);
    if (station == null) {
      debugPrint('[AqiPolling] 측정소 없음 → 폴링 스킵');
      return;
    }

    final lastPollKey = '$_prefPollTimePrefix$station';
    final lastPollMs = prefs.getInt(lastPollKey) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedMin = (nowMs - lastPollMs) / 60000;

    if (elapsedMin < _cooldownMinutes) {
      debugPrint('[AqiPolling] 쿨다운 중 — 스킵 ($station, ${elapsedMin.toStringAsFixed(1)}분 경과)');
      return;
    }

    await seedInitialData(station);
    final saved = await pollAndSave(station);
    if (saved) {
      await prefs.setInt(lastPollKey, nowMs);
    }
  }
}

enum SeedResult { success, skipped, failed }
