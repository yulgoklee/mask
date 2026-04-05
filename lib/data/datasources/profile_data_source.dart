import '../models/user_profile.dart';
import '../models/notification_setting.dart';

abstract class ProfileDataSource {
  Future<UserProfile> loadProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<NotificationSetting> loadNotificationSetting();
  Future<void> saveNotificationSetting(NotificationSetting setting);
  Future<bool> isOnboardingCompleted();
  Future<void> completeOnboarding();
  Future<void> resetOnboarding();
  Future<bool> isTutorialSeen();
  Future<void> completeTutorial();
}
