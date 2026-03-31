import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/notification_setting.dart';

/// 개인 프로필 및 알림 설정 저장/불러오기
class ProfileRepository {
  static const String _profileKey = 'user_profile';
  static const String _notifKey = 'notification_setting';
  static const String _onboardedKey = 'onboarding_completed';
  static const String _tutorialKey = 'tutorial_seen';

  final SharedPreferences _prefs;

  ProfileRepository(this._prefs);

  // ── 프로필 ────────────────────────────────────────────

  UserProfile loadProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return UserProfile.defaultProfile();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile.defaultProfile();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // ── 알림 설정 ─────────────────────────────────────────

  NotificationSetting loadNotificationSetting() {
    final raw = _prefs.getString(_notifKey);
    if (raw == null) return const NotificationSetting();
    try {
      return NotificationSetting.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const NotificationSetting();
    }
  }

  Future<void> saveNotificationSetting(NotificationSetting setting) async {
    await _prefs.setString(_notifKey, jsonEncode(setting.toJson()));
  }

  // ── 온보딩 완료 여부 ───────────────────────────────────

  bool isOnboardingCompleted() => _prefs.getBool(_onboardedKey) ?? false;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardedKey, true);
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardedKey);
  }

  bool isTutorialSeen() => _prefs.getBool(_tutorialKey) ?? false;
  Future<void> completeTutorial() => _prefs.setBool(_tutorialKey, true);
}
