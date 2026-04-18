import 'package:shared_preferences/shared_preferences.dart';

/// 알림 탭 → Care 탭 딥링크 처리
///
/// 동작 흐름:
///   알림 탭 (foreground/background) → [setPendingTab] 호출
///   앱 재개 (resume/launch) → MainShell 이 [consumePendingTab] 읽고 탭 전환
///
/// SharedPreferences 기반: 앱이 종료된 상태에서 알림 탭이 들어와도
/// 앱 재시작 후 pending 값을 읽어 올바른 탭으로 이동할 수 있다.
class NotificationDeepLink {
  NotificationDeepLink._();

  // ── SharedPreferences 키 ──────────────────────────────────

  /// 알림 탭으로 인해 전환해야 할 탭 인덱스 (int)
  static const String prefPendingTab = '_notif_pending_tab';

  /// 가장 최근 발송된 notification_log 의 SQLite row id (int)
  ///
  /// background handler가 "마스크 챙겼어요" 시 이 id로 UserAction을 업데이트한다.
  static const String prefLastLogId = '_notif_last_log_id';

  // ── 탭 인덱스 상수 ─────────────────────────────────────────
  static const int careTabIndex = 0;

  // ── 발신: 알림 핸들러에서 호출 ────────────────────────────

  /// Care 탭 전환 예약
  ///
  /// background top-level 함수에서도 호출 가능하도록 static 설계.
  static Future<void> setPendingCareTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefPendingTab, careTabIndex);
  }

  /// 마지막 발송 알림의 SQLite log id 저장
  static Future<void> setLastLogId(
      SharedPreferences prefs, int logId) async {
    await prefs.setInt(prefLastLogId, logId);
  }

  /// 마지막 발송 알림의 log id 조회
  static int? getLastLogId(SharedPreferences prefs) =>
      prefs.getInt(prefLastLogId);

  // ── 수신: MainShell에서 호출 ──────────────────────────────

  /// 대기 중인 탭 전환 소비 — 읽은 뒤 즉시 삭제 (1회성)
  static Future<int?> consumePendingTab() async {
    final prefs = await SharedPreferences.getInstance();
    final tab = prefs.getInt(prefPendingTab);
    if (tab != null) await prefs.remove(prefPendingTab);
    return tab;
  }
}
