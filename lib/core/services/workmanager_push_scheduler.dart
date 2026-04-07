import 'background_service.dart';
import 'push_notification_scheduler.dart';

/// Workmanager 기반 백그라운드 푸시 스케줄러 구현체
/// FCM 등 서버 기반 구현체로 교체 가능
class WorkmanagerPushScheduler implements PushNotificationScheduler {
  @override
  Future<void> initialize() => BackgroundService.initialize();

  @override
  Future<void> register() async {
    await BackgroundService.registerPeriodicTask();
    // 앱 시작 시 즉시 1회 체크 → 설치 직후 or 알림 시간 근처에 앱 열었을 때 바로 발송
    await BackgroundService.runOnce();
  }

  @override
  Future<void> cancel() => BackgroundService.cancelAll();
}
