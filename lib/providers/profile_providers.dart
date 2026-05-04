import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/app_logger.dart';
import '../core/services/background_service.dart';
import '../core/services/notification_scheduler.dart';
import '../data/models/notification_setting.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/profile_repository.dart';
import '../data/datasources/profile_data_source.dart';
import '../data/datasources/local_profile_data_source.dart';
import 'core_providers.dart';

// ── 프로필 데이터 소스 ────────────────────────────────────

final localProfileDataSourceProvider = Provider<ProfileDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalProfileDataSource(prefs);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dataSource = ref.watch(localProfileDataSourceProvider);
  return ProfileRepository.fromDataSource(dataSource);
});

// ── Tier 1 — 고정 프로필 ──────────────────────────────────

class ProfileNotifier extends StateNotifier<UserProfile> {
  final ProfileRepository _repo;

  ProfileNotifier(this._repo) : super(UserProfile.defaultProfile()) {
    _repo.loadProfile().then((p) => state = p);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _repo.saveProfile(profile);
    state = profile;
  }

  void update(UserProfile profile) => saveProfile(profile);
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider));
});

// ── 알림 설정 ─────────────────────────────────────────────

class NotificationSettingNotifier extends StateNotifier<NotificationSetting> {
  final ProfileRepository _repo;

  NotificationSettingNotifier(this._repo) : super(const NotificationSetting()) {
    _repo.loadNotificationSetting().then((s) => state = s);
  }

  Future<void> update(NotificationSetting setting) async {
    await _repo.saveNotificationSetting(setting);
    state = setting;
    // 온보딩 완료된 사용자에게만 즉시 백그라운드 체크 실행
    // (온보딩 중 알림 시간 저장 시 불필요한 조기 실행 방지)
    if (await _repo.isOnboardingCompleted()) {
      unawaited(_runImmediateCheck());
      BackgroundService.runOnce();
    }
  }

  Future<void> _runImmediateCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await NotificationScheduler().runCheck(prefs);
    } catch (e, st) {
      AppLogger.error(e, st, reason: 'profile_save_reschedule');
    }
  }
}

final notificationSettingProvider =
    StateNotifierProvider<NotificationSettingNotifier, NotificationSetting>(
        (ref) {
  return NotificationSettingNotifier(ref.watch(profileRepositoryProvider));
});
