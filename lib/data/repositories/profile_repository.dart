import '../models/user_profile.dart';
import '../models/notification_setting.dart';
import '../models/temporary_state.dart';
import '../models/today_situation.dart';
import '../datasources/profile_data_source.dart';
import '../datasources/local_profile_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 개인 프로필 및 알림 설정 저장/불러오기
class ProfileRepository {
  final ProfileDataSource _dataSource;

  ProfileRepository(SharedPreferences prefs)
      : _dataSource = LocalProfileDataSource(prefs);

  ProfileRepository.fromDataSource(this._dataSource);

  // ── Tier 1 — 고정 프로필 ──────────────────────────────────

  Future<UserProfile> loadProfile() => _dataSource.loadProfile();
  Future<void> saveProfile(UserProfile profile) =>
      _dataSource.saveProfile(profile);

  // ── Tier 2 — 기간 상태 ───────────────────────────────────

  Future<List<TemporaryState>> loadTemporaryStates() =>
      _dataSource.loadTemporaryStates();
  Future<void> saveTemporaryStates(List<TemporaryState> states) =>
      _dataSource.saveTemporaryStates(states);

  // ── Tier 3 — 오늘의 상황 ─────────────────────────────────

  Future<List<TodaySituation>> loadTodaySituations() =>
      _dataSource.loadTodaySituations();
  Future<void> saveTodaySituations(List<TodaySituation> situations) =>
      _dataSource.saveTodaySituations(situations);

  // ── 알림 설정 ─────────────────────────────────────────────

  Future<NotificationSetting> loadNotificationSetting() =>
      _dataSource.loadNotificationSetting();
  Future<void> saveNotificationSetting(NotificationSetting setting) =>
      _dataSource.saveNotificationSetting(setting);

  // ── 온보딩/튜토리얼 ────────────────────────────────────────

  Future<bool> isOnboardingCompleted() => _dataSource.isOnboardingCompleted();
  Future<void> completeOnboarding() => _dataSource.completeOnboarding();
  Future<void> resetOnboarding() => _dataSource.resetOnboarding();
  Future<bool> isTutorialSeen() => _dataSource.isTutorialSeen();
  Future<void> completeTutorial() => _dataSource.completeTutorial();
}
