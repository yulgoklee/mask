import '../models/user_profile.dart';
import '../models/notification_setting.dart';
import '../models/temporary_state.dart';
import '../models/today_situation.dart';

abstract class ProfileDataSource {
  // ── Tier 1 — 고정 프로필 ──────────────────────────────────
  Future<UserProfile> loadProfile();
  Future<void> saveProfile(UserProfile profile);

  // ── Tier 2 — 기간 상태 ───────────────────────────────────
  Future<List<TemporaryState>> loadTemporaryStates();
  Future<void> saveTemporaryStates(List<TemporaryState> states);

  // ── Tier 3 — 오늘의 상황 ─────────────────────────────────
  Future<List<TodaySituation>> loadTodaySituations();
  Future<void> saveTodaySituations(List<TodaySituation> situations);

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
