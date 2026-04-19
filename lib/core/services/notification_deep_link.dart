import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 탭 딥링크 페이로드
class NotifDeepLinkPayload {
  /// 알림 유형: 'risk' | 'relief' | 'scheduled'
  final String type;

  /// 연결된 notification_log row id (nullableˇ)
  final int? logId;

  const NotifDeepLinkPayload({required this.type, this.logId});

  /// Care 탭에서 Time Guide 섹션으로 스크롤해야 하는지 여부 (Phase 3)
  bool get shouldScrollToTimeGuide => type == 'relief';
}

/// 알림 탭 → Care 탭 딥링크 처리
///
/// 동작 흐름:
///   알림 탭 (foreground/background) → [setPendingPayload] 호출
///   앱 재개 (resume/launch) → MainShell 이 [consumePendingPayload] 읽고 탭 전환
///
/// SharedPreferences 기반: 앱이 종료된 상태에서 알림 탭이 들어와도
/// 앱 재시작 후 pending 값을 읽어 올바른 탭으로 이동할 수 있다.
class NotificationDeepLink {
  NotificationDeepLink._();

  // ── SharedPreferences 키 ──────────────────────────────────

  /// JSON 직렬화된 딥링크 페이로드 (Phase 2+)
  static const String prefPendingPayload = '_notif_pending_payload';

  /// 가장 최근 발송된 notification_log 의 SQLite row id (int)
  static const String prefLastLogId = '_notif_last_log_id';

  // ── 탭 인덱스 상수 ─────────────────────────────────────────
  static const int careTabIndex = 0;

  // ── 발신: 알림 핸들러에서 호출 ────────────────────────────

  /// 알림 딥링크 예약 — JSON 페이로드 방식
  ///
  /// [type] : 'risk' | 'relief' | 'scheduled'
  /// [logId]: 연결된 notification_log id (선택)
  static Future<void> setPendingPayload({
    required String type,
    int? logId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{'type': type};
    if (logId != null) map['logId'] = logId;
    await prefs.setString(prefPendingPayload, jsonEncode(map));
  }

  /// 마지막 발송 알림의 SQLite log id 저장 (background handler 연결용)
  static Future<void> setLastLogId(
      SharedPreferences prefs, int logId) async {
    await prefs.setInt(prefLastLogId, logId);
  }

  /// 마지막 발송 알림의 log id 조회
  static int? getLastLogId(SharedPreferences prefs) =>
      prefs.getInt(prefLastLogId);

  // ── 수신: MainShell에서 호출 ──────────────────────────────

  /// 대기 중인 딥링크 페이로드 소비 — 읽은 뒤 즉시 삭제 (1회성)
  static Future<NotifDeepLinkPayload?> consumePendingPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefPendingPayload);
    if (raw != null) {
      await prefs.remove(prefPendingPayload);
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return NotifDeepLinkPayload(
          type: map['type'] as String? ?? 'scheduled',
          logId: (map['logId'] as num?)?.toInt(),
        );
      } catch (_) {
        return const NotifDeepLinkPayload(type: 'scheduled');
      }
    }
    return null;
  }
}
