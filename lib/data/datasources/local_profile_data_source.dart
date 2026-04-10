import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/notification_setting.dart';
import '../models/temporary_state.dart';
import '../models/today_situation.dart';
import 'profile_data_source.dart';

/// SharedPreferences 기반 프로필 데이터 소스 (로컬 구현체)
/// Firestore 등 서버 구현체로 교체 가능
class LocalProfileDataSource implements ProfileDataSource {
  static const String _profileKey       = 'user_profile';
  static const String _notifKey         = 'notification_setting';
  static const String _onboardedKey     = 'onboarding_completed';
  static const String _tutorialKey      = 'tutorial_seen';
  static const String _tempStatesKey    = 'temporary_states';
  static const String _todaySitKey      = 'today_situation';

  final SharedPreferences _prefs;

  LocalProfileDataSource(this._prefs);

  // ── Tier 1 — 고정 프로필 ──────────────────────────────────

  @override
  Future<UserProfile> loadProfile() async {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return UserProfile.defaultProfile();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile.defaultProfile();
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // ── Tier 2 — 기간 상태 ───────────────────────────────────

  @override
  Future<List<TemporaryState>> loadTemporaryStates() async {
    final raw = _prefs.getString(_tempStatesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TemporaryState.fromJson(e as Map<String, dynamic>))
          .where((s) => s.isActive) // 만료된 상태는 로드 시 자동 제거
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTemporaryStates(List<TemporaryState> states) async {
    final active = states.where((s) => s.isActive).toList();
    await _prefs.setString(
      _tempStatesKey,
      jsonEncode(active.map((s) => s.toJson()).toList()),
    );
  }

  // ── Tier 3 — 오늘의 상황 ─────────────────────────────────

  @override
  Future<List<TodaySituation>> loadTodaySituations() async {
    final raw = _prefs.getString(_todaySitKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      // 이전 버전 호환: 단일 객체로 저장된 경우
      if (decoded is Map<String, dynamic>) {
        final sit = TodaySituation.fromJson(decoded);
        return sit.isActive ? [sit] : [];
      }
      // 새 버전: 배열로 저장
      final list = decoded as List<dynamic>;
      return list
          .map((e) => TodaySituation.fromJson(e as Map<String, dynamic>))
          .where((s) => s.isActive)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTodaySituations(List<TodaySituation> situations) async {
    final active = situations.where((s) => s.isActive).toList();
    if (active.isEmpty) {
      await _prefs.remove(_todaySitKey);
    } else {
      await _prefs.setString(
        _todaySitKey,
        jsonEncode(active.map((s) => s.toJson()).toList()),
      );
    }
  }

  // ── 알림 설정 ─────────────────────────────────────────────

  @override
  Future<NotificationSetting> loadNotificationSetting() async {
    final raw = _prefs.getString(_notifKey);
    if (raw == null) return const NotificationSetting();
    try {
      return NotificationSetting.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const NotificationSetting();
    }
  }

  @override
  Future<void> saveNotificationSetting(NotificationSetting setting) async {
    await _prefs.setString(_notifKey, jsonEncode(setting.toJson()));
  }

  // ── 온보딩/튜토리얼 ────────────────────────────────────────

  @override
  Future<bool> isOnboardingCompleted() async =>
      _prefs.getBool(_onboardedKey) ?? false;

  @override
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardedKey, true);
  }

  @override
  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardedKey);
  }

  @override
  Future<bool> isTutorialSeen() async =>
      _prefs.getBool(_tutorialKey) ?? false;

  @override
  Future<void> completeTutorial() async {
    await _prefs.setBool(_tutorialKey, true);
  }
}
