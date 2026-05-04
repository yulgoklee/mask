import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/notification_setting.dart';
import 'profile_data_source.dart';
import '../../core/constants/app_constants.dart';

/// SharedPreferences 기반 프로필 데이터 소스 (로컬 구현체)
/// Firestore 등 서버 구현체로 교체 가능
class LocalProfileDataSource implements ProfileDataSource {
  static const String _profileKey    = AppConstants.prefUserProfile;
  static const String _notifKey      = AppConstants.prefNotificationSetting;
  static const String _onboardedKey  = AppConstants.prefOnboardingCompleted;
  static const String _tutorialKey   = AppConstants.prefTutorialSeen;

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

  // ── 알림 설정 ─────────────────────────────────────────────

  @override
  Future<NotificationSetting> loadNotificationSetting() async {
    final raw = _prefs.getString(_notifKey);
    NotificationSetting setting;
    if (raw == null) {
      setting = const NotificationSetting();
    } else {
      try {
        setting = NotificationSetting.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        setting = const NotificationSetting();
      }
    }

    // 구버전 독립 키 → NotificationSetting JSON으로 1회 마이그레이션
    final legacyEnabled = _prefs.getBool(AppConstants.prefQuietHoursEnabled);
    if (legacyEnabled != null) {
      final migrated = setting.copyWith(
        quietHoursEnabled:   legacyEnabled,
        quietHoursStartHour: _prefs.getInt(AppConstants.prefQuietHoursStartHour) ?? 22,
        quietHoursEndHour:   _prefs.getInt(AppConstants.prefQuietHoursEndHour)   ?? 7,
      );
      await _prefs.remove(AppConstants.prefQuietHoursEnabled);
      await _prefs.remove(AppConstants.prefQuietHoursStartHour);
      await _prefs.remove(AppConstants.prefQuietHoursEndHour);
      await saveNotificationSetting(migrated);
      return migrated;
    }

    return setting;
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
