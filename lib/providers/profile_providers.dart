import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/background_service.dart';
import '../data/models/notification_setting.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/profile_repository.dart';
import '../data/datasources/profile_data_source.dart';
import '../data/datasources/local_profile_data_source.dart';
import 'core_providers.dart';

// ── 프로필 데이터 소스 ────────────────────────────────────

/// 로컬 프로필 데이터 소스 (abstract interface 타입으로 제공)
/// Firestore 등 서버 구현체로 교체 시 이 provider만 변경하면 됨
final localProfileDataSourceProvider = Provider<ProfileDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalProfileDataSource(prefs);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dataSource = ref.watch(localProfileDataSourceProvider);
  return ProfileRepository.fromDataSource(dataSource);
});

// ── 프로필 상태 ──────────────────────────────────────────

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

// ── 알림 설정 상태 ────────────────────────────────────────

class NotificationSettingNotifier extends StateNotifier<NotificationSetting> {
  final ProfileRepository _repo;

  NotificationSettingNotifier(this._repo) : super(const NotificationSetting()) {
    _repo.loadNotificationSetting().then((s) => state = s);
  }

  Future<void> update(NotificationSetting setting) async {
    await _repo.saveNotificationSetting(setting);
    state = setting;
    // 알림 시간 변경 즉시 1회 체크 → 변경된 시간이 현재와 가까우면 바로 발송
    BackgroundService.runOnce();
  }
}

final notificationSettingProvider =
    StateNotifierProvider<NotificationSettingNotifier, NotificationSetting>(
        (ref) {
  return NotificationSettingNotifier(ref.watch(profileRepositoryProvider));
});
