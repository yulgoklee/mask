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

void main() {
  // ── 프로필 ──────────────────────────────────────────────

  group('ProfileRepository — 프로필', () {
    test('초기 상태: 기본 프로필 반환', () async {
      final repo = await _buildRepo();
      final profile = await repo.loadProfile();

      expect(profile, equals(UserProfile.defaultProfile()));
    });

    test('저장 후 불러오면 동일한 값 반환', () async {
      final repo = await _buildRepo();
      const profile = UserProfile(
        ageGroup: AgeGroup.twenties,
        hasCondition: true,
        conditionType: ConditionType.asthma,
        severity: Severity.moderate,
        isDiagnosed: true,
        activityLevel: ActivityLevel.high,
        sensitivity: SensitivityLevel.high,
      );

      await repo.saveProfile(profile);
      final loaded = await repo.loadProfile();

      expect(loaded.ageGroup, AgeGroup.twenties);
      expect(loaded.hasCondition, isTrue);
      expect(loaded.conditionType, ConditionType.asthma);
      expect(loaded.severity, Severity.moderate);
      expect(loaded.activityLevel, ActivityLevel.high);
      expect(loaded.sensitivity, SensitivityLevel.high);
    });

    test('여러 번 저장하면 최신 값으로 덮어씀', () async {
      final repo = await _buildRepo();

      await repo.saveProfile(const UserProfile(
        ageGroup: AgeGroup.teens,
        hasCondition: false,
        activityLevel: ActivityLevel.low,
      ));
      await repo.saveProfile(const UserProfile(
        ageGroup: AgeGroup.sixtyPlus,
        hasCondition: false,
        activityLevel: ActivityLevel.normal,
      ));

      final loaded = await repo.loadProfile();
      expect(loaded.ageGroup, AgeGroup.sixtyPlus);
    });
  });

  // ── 알림 설정 ────────────────────────────────────────────

  group('ProfileRepository — 알림 설정', () {
    test('초기 상태: 기본 알림 설정 반환', () async {
      final repo = await _buildRepo();
      final setting = await repo.loadNotificationSetting();

      expect(setting, equals(const NotificationSetting()));
    });

    test('알림 설정 저장 후 불러오면 동일한 값 반환', () async {
      final repo = await _buildRepo();
      const setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: 8,
        morningAlertMinute: 30,
        eveningForecastEnabled: false,
        realtimeAlertEnabled: true,
      );

      await repo.saveNotificationSetting(setting);
      final loaded = await repo.loadNotificationSetting();

      expect(loaded.morningAlertEnabled, isTrue);
      expect(loaded.morningAlertHour, 8);
      expect(loaded.morningAlertMinute, 30);
      expect(loaded.eveningForecastEnabled, isFalse);
      expect(loaded.realtimeAlertEnabled, isTrue);
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
