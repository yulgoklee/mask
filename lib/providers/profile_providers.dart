import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/background_service.dart';
import '../core/services/notification_scheduler.dart';
import '../data/models/notification_setting.dart';
import '../data/models/user_profile.dart';
import '../data/models/temporary_state.dart';
import '../data/models/today_situation.dart';
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

// ── Tier 2 — 기간 상태 ───────────────────────────────────

class TemporaryStatesNotifier extends StateNotifier<List<TemporaryState>> {
  final ProfileRepository _repo;

  TemporaryStatesNotifier(this._repo) : super([]) {
    _repo.loadTemporaryStates().then((list) => state = list);
  }

  /// 기간 상태 추가
  Future<void> add(TemporaryState newState) async {
    // 같은 타입이 이미 있으면 교체
    final updated = [
      ...state.where((s) => s.type != newState.type),
      newState,
    ];
    await _repo.saveTemporaryStates(updated);
    state = updated;
  }

  /// 기간 상태 제거
  Future<void> remove(TemporaryStateType type) async {
    final updated = state.where((s) => s.type != type).toList();
    await _repo.saveTemporaryStates(updated);
    state = updated;
  }

  /// 만료된 상태 정리 (앱 시작 시 호출)
  Future<void> pruneExpired() async {
    final active = state.where((s) => s.isActive).toList();
    if (active.length != state.length) {
      await _repo.saveTemporaryStates(active);
      state = active;
    }
  }
}

final temporaryStatesProvider =
    StateNotifierProvider<TemporaryStatesNotifier, List<TemporaryState>>((ref) {
  return TemporaryStatesNotifier(ref.watch(profileRepositoryProvider));
});

// ── Tier 3 — 오늘의 상황 (List) ──────────────────────────

class TodaySituationNotifier extends StateNotifier<List<TodaySituation>> {
  final ProfileRepository _repo;

  TodaySituationNotifier(this._repo) : super([]) {
    _repo.loadTodaySituations().then((list) => state = list);
  }

  /// 타입 토글: 이미 활성이면 제거, 아니면 추가
  Future<void> toggle(TodaySituationType type) async {
    final alreadyActive = state.any((s) => s.isActive && s.type == type);
    List<TodaySituation> updated;
    if (alreadyActive) {
      updated = state.where((s) => s.type != type).toList();
    } else {
      updated = [
        ...state.where((s) => s.type != type),
        TodaySituation(type: type, date: DateTime.now()),
      ];
    }
    await _repo.saveTodaySituations(updated);
    state = updated;
  }

  /// 특정 타입 활성화
  Future<void> set(TodaySituationType type) async {
    final updated = [
      ...state.where((s) => s.type != type),
      TodaySituation(type: type, date: DateTime.now()),
    ];
    await _repo.saveTodaySituations(updated);
    state = updated;
  }

  /// 특정 타입 비활성화
  Future<void> remove(TodaySituationType type) async {
    final updated = state.where((s) => s.type != type).toList();
    await _repo.saveTodaySituations(updated);
    state = updated;
  }

  /// 전체 초기화
  Future<void> clearAll() async {
    await _repo.saveTodaySituations([]);
    state = [];
  }
}

final todaySituationProvider =
    StateNotifierProvider<TodaySituationNotifier, List<TodaySituation>>((ref) {
  return TodaySituationNotifier(ref.watch(profileRepositoryProvider));
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
    unawaited(_runImmediateCheck());
    BackgroundService.runOnce();
  }

  Future<void> _runImmediateCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await NotificationScheduler().runCheck(prefs);
    } catch (_) {}
  }
}

final notificationSettingProvider =
    StateNotifierProvider<NotificationSettingNotifier, NotificationSetting>(
        (ref) {
  return NotificationSettingNotifier(ref.watch(profileRepositoryProvider));
});
