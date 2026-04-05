import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/notification_setting.dart';
import 'profile_data_source.dart';

/// SharedPreferences 기반 프로필 데이터 소스 (로컬 구현체)
/// Firestore 등 서버 구현체로 교체 가능
class LocalProfileDataSource implements ProfileDataSource {
  static const String _profileKey = 'user_profile';
  static const String _notifKey = 'notification_setting';
  static const String _onboardedKey = 'onboarding_completed';
  static const String _tutorialKey = 'tutorial_seen';

  final SharedPreferences _prefs;

  LocalProfileDataSource(this._prefs);

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
