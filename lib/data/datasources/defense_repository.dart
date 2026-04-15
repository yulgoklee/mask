import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/defense_record.dart';

/// 방어 기록 저장소 — SharedPreferences JSON 배열 기반
///
/// 저장 구조:
///  - 키: [_key] → JSON 배열 문자열
///  - 최근 90일 데이터만 유지 ([_maxDays] 초과분 자동 삭제)
///
/// 배경 isolate 사용 예:
///  ```dart
///  final prefs = await SharedPreferences.getInstance();
///  final record = DefenseRecord.create(pm25: pm25, maskType: maskType);
///  await DefenseRepository.addRecordToPrefs(prefs, record);
///  ```
class DefenseRepository {
  static const String _key = 'defense_records';
  static const int _maxDays = 90;

  final SharedPreferences _prefs;
  const DefenseRepository(this._prefs);

  // ── 읽기 ─────────────────────────────────────────────────

  /// 저장된 전체 기록 로드 (최근 [_maxDays]일 내 기록만)
  List<DefenseRecord> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final cutoff = DateTime.now().subtract(const Duration(days: _maxDays));
      return list
          .map((e) => DefenseRecord.fromJson(e as Map<String, dynamic>))
          .where((r) => r.timestamp.isAfter(cutoff))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 최신 순
    } catch (_) {
      return [];
    }
  }

  // ── 쓰기 ─────────────────────────────────────────────────

  /// 새 기록 추가 (오래된 기록 자동 정리 포함)
  Future<void> addRecord(DefenseRecord record) async {
    await addRecordToPrefs(_prefs, record);
  }

  /// 배경 isolate에서도 사용할 수 있는 static 버전
  ///
  /// `onNotificationActionBackground` 같은 top-level 함수에서는
  /// Riverpod Provider에 접근할 수 없으므로 SharedPreferences를 직접 전달.
  static Future<void> addRecordToPrefs(
    SharedPreferences prefs,
    DefenseRecord record,
  ) async {
    final raw = prefs.getString(_key);
    List<Map<String, dynamic>> list = [];

    if (raw != null) {
      try {
        list = (jsonDecode(raw) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    list.add(record.toJson());

    // 90일 초과 기록 정리
    final cutoff = DateTime.now().subtract(const Duration(days: _maxDays));
    list = list.where((e) {
      try {
        return DateTime.parse(e['timestamp'] as String).isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();

    await prefs.setString(_key, jsonEncode(list));
  }

  // ── 집계 ─────────────────────────────────────────────────

  /// 이번 주(최근 7일) 기록
  List<DefenseRecord> thisWeek() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return loadAll().where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  /// 이번 주 방어 횟수
  int get weeklyCount => thisWeek().length;

  /// 이번 주 총 방어 질량 (μg)
  double get weeklyTotalUg =>
      thisWeek().fold(0.0, (sum, r) => sum + r.blockedMassUg);

  /// 연속 실천 일수 (오늘 포함 / 중간에 빠진 날 있으면 중단)
  int get streakDays {
    final records = loadAll();
    if (records.isEmpty) return 0;

    final today = _dateOnly(DateTime.now());
    int streak = 0;
    DateTime check = today;

    // 최대 _maxDays까지 역방향으로 확인
    for (int i = 0; i < _maxDays; i++) {
      final hasRecord = records.any((r) => _dateOnly(r.timestamp) == check);
      if (!hasRecord) break;
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── 정리 ─────────────────────────────────────────────────

  /// [_maxDays] 초과 기록 수동 정리 (일반적으로 addRecord가 자동 처리)
  Future<void> pruneOld() async {
    final records = loadAll(); // loadAll이 이미 필터링함
    await _prefs.setString(
      _key,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  /// 전체 기록 삭제 (테스트/초기화용)
  Future<void> clear() => _prefs.remove(_key);

  // ── 내부 헬퍼 ─────────────────────────────────────────────

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
