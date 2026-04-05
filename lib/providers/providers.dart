import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/dust_data.dart';
import '../data/models/notification_setting.dart';
import '../data/models/user_profile.dart';
import '../data/models/forecast_models.dart';
import '../data/repositories/dust_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/datasources/profile_data_source.dart';
import '../data/datasources/local_profile_data_source.dart';
import '../core/services/air_korea_service.dart';
import '../core/services/dust_data_source.dart';
import '../core/services/location_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/dust_calculator.dart';

// ── 기반 Provider ─────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart with override');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ── Repository Providers ──────────────────────────────────

/// Local profile data source provider (typed as abstract interface)
/// Replace this override to switch implementations (e.g. Firestore)
final localProfileDataSourceProvider = Provider<ProfileDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalProfileDataSource(prefs);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dataSource = ref.watch(localProfileDataSourceProvider);
  return ProfileRepository.fromDataSource(dataSource);
});

/// Primary dust data source provider (typed as abstract interface)
/// Replace this override to switch implementations (e.g. API proxy, mock)
final dustDataSourceProvider = Provider<DustDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AirKoreaService(prefs);
});

/// Backward-compatible alias for dustDataSourceProvider
final airKoreaServiceProvider = Provider<AirKoreaService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AirKoreaService(prefs);
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocationService(prefs);
});

final dustRepositoryProvider = Provider<DustRepository>((ref) {
  return DustRepository(
    ref.watch(dustDataSourceProvider),
    ref.watch(locationServiceProvider),
  );
});

// ── 프로필 ────────────────────────────────────────────────

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

  NotificationSettingNotifier(this._repo)
      : super(const NotificationSetting()) {
    _repo.loadNotificationSetting().then((s) => state = s);
  }

  Future<void> update(NotificationSetting setting) async {
    await _repo.saveNotificationSetting(setting);
    state = setting;
  }
}

final notificationSettingProvider =
    StateNotifierProvider<NotificationSettingNotifier, NotificationSetting>(
        (ref) {
  return NotificationSettingNotifier(ref.watch(profileRepositoryProvider));
});

// ── 미세먼지 데이터 ───────────────────────────────────────

final dustDataProvider = FutureProvider<DustData?>((ref) async {
  final repo = ref.watch(dustRepositoryProvider);
  return repo.getCurrentDustData();
});

final dustCalculationProvider = Provider<DustCalculationResult?>((ref) {
  final dustAsync = ref.watch(dustDataProvider);
  final profile = ref.watch(profileProvider);

  return dustAsync.when(
    data: (dust) {
      if (dust == null) return null;
      return DustCalculator.calculate(profile, dust);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ── 내일 예보 ─────────────────────────────────────────────

final tomorrowForecastProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(dustRepositoryProvider);
  return repo.getTomorrowForecast();
});

// ── 시간별 데이터 ─────────────────────────────────────────

final hourlyDataProvider = FutureProvider.family<List<HourlyDustData>, String>(
  (ref, stationName) async {
    final repo = ref.watch(dustRepositoryProvider);
    return repo.getHourlyData(stationName);
  },
);

final hourlyHistoryProvider = FutureProvider.family<List<HourlyDustData>, String>(
  (ref, stationName) async {
    final repo = ref.watch(dustRepositoryProvider);
    return repo.getHourlyHistory(stationName);
  },
);

final weeklyForecastProvider = FutureProvider.family<List<WeeklyForecastData>, String>(
  (ref, sidoName) async {
    final repo = ref.watch(dustRepositoryProvider);
    return repo.getWeeklyForecast(sidoName: sidoName);
  },
);
