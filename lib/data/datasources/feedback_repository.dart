import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/app_logger.dart';
import '../models/notification_feedback.dart';

/// 알림 피드백 기록 저장소
///
/// 학습 알고리즘([AdaptiveLearner])이 소비하는 원시 데이터를 담당한다.
/// 최근 30일 기록만 유지 (학습에 필요한 최소 기간).
///
/// 모든 쓰기 메서드는 배경 isolate에서 호출 가능한 static 버전을 함께 제공한다.
class FeedbackRepository {
  static const String _key    = 'notification_feedbacks';
  static const int    _maxDays = 30;

  /// 배경 핸들러에서도 접근 가능하도록 public 노출
  static const String pendingKey = '_pending_notif_id';

  /// 알림 발송 후 이 시간(시간)이 지나도 응답 없으면 ignored 처리
  static const int kIgnoreWindowHours = 2;

  final SharedPreferences _prefs;
  const FeedbackRepository(this._prefs);

  // ── 읽기 ──────────────────────────────────────────────────

  /// 저장된 전체 피드백 로드 (최근 [_maxDays]일, 최신 순)
  List<NotificationFeedback> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: _maxDays));
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) =>
              NotificationFeedback.fromJson(e as Map<String, dynamic>))
          .where((f) => f.timestamp.isAfter(cutoff))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  // ── 펜딩 알림 추적 ─────────────────────────────────────────

  /// 알림 발송 시 호출 — 응답 대기 상태로 등록
  ///
  /// 형식: '{notifId}|{timestamp}|{pm25}'
  Future<void> markPending(String notifId, DateTime ts, int pm25) async {
    await _prefs.setString(
        pendingKey, '$notifId|${ts.toIso8601String()}|$pm25');
  }

  /// 펜딩 알림 데이터 파싱 — null이면 대기 중인 알림 없음
  ({String notifId, DateTime timestamp, int pm25})? loadPending() {
    final raw = _prefs.getString(pendingKey);
    if (raw == null) return null;
    try {
      final parts = raw.split('|');
      if (parts.length < 3) return null;
      return (
        notifId: parts[0],
        timestamp: DateTime.parse(parts[1]),
        pm25: int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPending() => _prefs.remove(pendingKey);

  // ── 쓰기 ──────────────────────────────────────────────────

  /// 피드백 추가 (일반 컨텍스트)
  Future<void> addFeedback(NotificationFeedback feedback) =>
      _addFeedbackToPrefs(_prefs, feedback);

  /// 배경 isolate에서도 사용 가능한 static 버전
  static Future<void> addFeedbackToPrefs(
    SharedPreferences prefs,
    NotificationFeedback feedback,
  ) => _addFeedbackToPrefs(prefs, feedback);

  static Future<void> _addFeedbackToPrefs(
    SharedPreferences prefs,
    NotificationFeedback feedback,
  ) async {
    final raw = prefs.getString(_key);
    List<Map<String, dynamic>> list = [];
    if (raw != null) {
      try {
        list = (jsonDecode(raw) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      } catch (e, st) {
        AppLogger.error(e, st, reason: 'feedback_prefs_parse');
      }
    }

    list.add(feedback.toJson());

    // 30일 초과 정리
    final cutoff =
        DateTime.now().subtract(const Duration(days: _maxDays));
    list = list.where((e) {
      try {
        return DateTime.parse(e['timestamp'] as String).isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();

    await prefs.setString(_key, jsonEncode(list));

    // 펜딩 해제
    await prefs.remove(pendingKey);
  }

  // ── 무응답 처리 (스케줄러 실행 시 호출) ────────────────────

  /// 펜딩 알림 중 [kIgnoreWindowHours]시간 경과 시 ignored 처리
  ///
  /// 스케줄러 `runCheck()` 진입부에서 호출.
  /// 응답이 있었으면 addFeedback이 이미 pendingKey를 지웠으므로 null 반환.
  Future<void> resolveIgnoredIfAny() async {
    final pending = loadPending();
    if (pending == null) return;

    final elapsed = DateTime.now().difference(pending.timestamp);
    if (elapsed.inHours < kIgnoreWindowHours) return;

    await addFeedback(NotificationFeedback(
      notifId: pending.notifId,
      timestamp: pending.timestamp,
      pm25: pending.pm25,
      type: FeedbackType.ignored,
    ));
    // clearPending은 addFeedback 내부에서 처리
  }

  // ── 통계 헬퍼 ─────────────────────────────────────────────

  /// 최근 [n]건 기준 응답률 (acknowledged / total)
  double acknowledgeRate({int n = 10}) {
    final recent = loadAll().take(n).toList();
    if (recent.isEmpty) return 1.0; // 데이터 없으면 기본 유지
    final ackCount =
        recent.where((f) => f.type == FeedbackType.acknowledged).length;
    return ackCount / recent.length;
  }

  /// 최근 [n]건 기준 무시율 (ignored / total)
  double ignoreRate({int n = 10}) {
    final recent = loadAll().take(n).toList();
    if (recent.isEmpty) return 0.0;
    final ignoredCount =
        recent.where((f) => f.type == FeedbackType.ignored).length;
    return ignoredCount / recent.length;
  }
}
