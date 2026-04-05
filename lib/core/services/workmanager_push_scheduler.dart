import 'background_service.dart';
import 'push_notification_scheduler.dart';

/// Workmanager 기반 백그라운드 푸시 스케줄러 구현체
/// FCM 등 서버 기반 구현체로 교체 가능
class WorkmanagerPushScheduler implements PushNotificationScheduler {
  @override
  Future<void> initialize() => BackgroundService.initialize();

  @override
  Future<void> register() => BackgroundService.registerPeriodicTask();

  @override
  Future<void> cancel() => BackgroundService.cancelAll();
}
