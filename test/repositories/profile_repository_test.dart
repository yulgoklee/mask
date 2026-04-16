import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/datasources/local_profile_data_source.dart';
import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';

/// SharedPreferences 인메모리 초기화 헬퍼
Future<ProfileRepository> _buildRepo([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return ProfileRepository.fromDataSource(LocalProfileDataSource(prefs));
}

UserProfile _sampleProfile({
  String nickname = '율곡',
  int birthYear = 1990,
  String gender = 'female',
  int respiratoryStatus = 2,
  int sensitivityLevel = 2,
  bool isPregnant = false,
  int outdoorMinutes = 2,
}) =>
    UserProfile(
      nickname: nickname,
      birthYear: birthYear,
      gender: gender,
      respiratoryStatus: respiratoryStatus,
      sensitivityLevel: sensitivityLevel,
      isPregnant: isPregnant,
      recentSkinTreatment: false,
      outdoorMinutes: outdoorMinutes,
      activityTags: const [ActivityTag.commute],
      discomfortLevel: 0,
    );

void main() {
  // ── 프로필 ──────────────────────────────────────────────

  group('ProfileRepository — 프로필', () {
    test('초기 상태: 기본 프로필 반환', () async {
      final repo = await _buildRepo();
      final profile = await repo.loadProfile();
      expect(profile.nickname, UserProfile.defaultProfile().nickname);
      expect(profile.gender, UserProfile.defaultProfile().gender);
    });

    test('저장 후 불러오면 동일한 값 반환', () async {
      final repo = await _buildRepo();
      final profile = _sampleProfile();

      await repo.saveProfile(profile);
      final loaded = await repo.loadProfile();

      expect(loaded.nickname, profile.nickname);
      expect(loaded.birthYear, profile.birthYear);
      expect(loaded.gender, profile.gender);
      expect(loaded.respiratoryStatus, profile.respiratoryStatus);
      expect(loaded.sensitivityLevel, profile.sensitivityLevel);
      expect(loaded.outdoorMinutes, profile.outdoorMinutes);
      expect(loaded.activityTags, profile.activityTags);
    });

    test('여러 번 저장하면 최신 값으로 덮어씀', () async {
      final repo = await _buildRepo();

      await repo.saveProfile(_sampleProfile(nickname: '처음'));
      await repo.saveProfile(_sampleProfile(nickname: '나중'));

      final loaded = await repo.loadProfile();
      expect(loaded.nickname, '나중');
    });
  });

  // ── 알림 설정 ────────────────────────────────────────────

  group('ProfileRepository — 알림 설정', () {
    test('초기 상태: 기본 알림 설정 반환', () async {
      final repo = await _buildRepo();
      final setting = await repo.loadNotificationSetting();
      expect(setting.morningAlertEnabled,
          const NotificationSetting().morningAlertEnabled);
      expect(setting.notificationVoice, NotificationVoice.friendly);
    });

    test('알림 설정 저장 후 불러오면 동일한 값 반환', () async {
      final repo = await _buildRepo();
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 8,
        morningAlertMinute: 30,
        eveningForecastEnabled: false,
        realtimeAlertEnabled: true,
        notificationVoice: NotificationVoice.analytical,
      );

      await repo.saveNotificationSetting(setting);
      final loaded = await repo.loadNotificationSetting();

      expect(loaded.morningAlertEnabled, isTrue);
      expect(loaded.morningAlertHour, 8);
      expect(loaded.morningAlertMinute, 30);
      expect(loaded.eveningForecastEnabled, isFalse);
      expect(loaded.realtimeAlertEnabled, isTrue);
      expect(loaded.notificationVoice, NotificationVoice.analytical);
    });
  });

  // ── 온보딩 ──────────────────────────────────────────────

  group('ProfileRepository — 온보딩', () {
    test('초기 상태: isOnboardingCompleted = false', () async {
      final repo = await _buildRepo();
      expect(await repo.isOnboardingCompleted(), isFalse);
    });

    test('completeOnboarding 후 isOnboardingCompleted = true', () async {
      final repo = await _buildRepo();
      await repo.completeOnboarding();
      expect(await repo.isOnboardingCompleted(), isTrue);
    });

    test('resetOnboarding 후 isOnboardingCompleted = false', () async {
      final repo = await _buildRepo();
      await repo.completeOnboarding();
      await repo.resetOnboarding();
      expect(await repo.isOnboardingCompleted(), isFalse);
    });
  });

  // ── 튜토리얼 ─────────────────────────────────────────────

  group('ProfileRepository — 튜토리얼', () {
    test('초기 상태: isTutorialSeen = false', () async {
      final repo = await _buildRepo();
      expect(await repo.isTutorialSeen(), isFalse);
    });

    test('completeTutorial 후 isTutorialSeen = true', () async {
      final repo = await _buildRepo();
      await repo.completeTutorial();
      expect(await repo.isTutorialSeen(), isTrue);
    });
  });
}
