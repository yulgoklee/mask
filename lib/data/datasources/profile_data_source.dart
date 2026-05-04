import '../models/user_profile.dart';
import '../models/notification_setting.dart';

abstract class ProfileDataSource {
  // ── 고정 프로필 ──────────────────────────────────────────
  Future<UserProfile> loadProfile();
  Future<void> saveProfile(UserProfile profile);

  // ── 알림 설정 ─────────────────────────────────────────────
  Future<NotificationSetting> loadNotificationSetting();
  Future<void> saveNotificationSetting(NotificationSetting setting);

  // ── 온보딩/튜토리얼 ────────────────────────────────────────
  Future<bool> isOnboardingCompleted();
  Future<void> completeOnboarding();
  Future<void> resetOnboarding();
  Future<bool> isTutorialSeen();
  Future<void> completeTutorial();
}
