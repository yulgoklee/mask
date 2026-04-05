import '../models/user_profile.dart';
import '../models/notification_setting.dart';
import '../datasources/profile_data_source.dart';
import '../datasources/local_profile_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 개인 프로필 및 알림 설정 저장/불러오기
class ProfileRepository {
  final ProfileDataSource _dataSource;

  ProfileRepository(SharedPreferences prefs)
      : _dataSource = LocalProfileDataSource(prefs);

  ProfileRepository.fromDataSource(this._dataSource);

  // ── 프로필 ────────────────────────────────────────────

  Future<UserProfile> loadProfile() => _dataSource.loadProfile();

  Future<void> saveProfile(UserProfile profile) =>
      _dataSource.saveProfile(profile);

  // ── 알림 설정 ─────────────────────────────────────────

  Future<NotificationSetting> loadNotificationSetting() =>
      _dataSource.loadNotificationSetting();

  Future<void> saveNotificationSetting(NotificationSetting setting) =>
      _dataSource.saveNotificationSetting(setting);

  // ── 온보딩 완료 여부 ───────────────────────────────────

  Future<bool> isOnboardingCompleted() => _dataSource.isOnboardingCompleted();

  Future<void> completeOnboarding() => _dataSource.completeOnboarding();

  Future<void> resetOnboarding() => _dataSource.resetOnboarding();

  Future<bool> isTutorialSeen() => _dataSource.isTutorialSeen();

  Future<void> completeTutorial() => _dataSource.completeTutorial();
}
