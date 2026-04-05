abstract class PushNotificationScheduler {
  Future<void> initialize();
  Future<void> register();
  Future<void> cancel();
}
