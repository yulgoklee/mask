import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/dust_data.dart';
import '../data/models/forecast_models.dart';
import '../data/repositories/dust_repository.dart';
import '../core/services/air_korea_service.dart';
import '../core/services/dust_data_source.dart';
import '../core/utils/dust_calculator.dart';
import 'core_providers.dart';
import 'profile_providers.dart';

// ── 미세먼지 데이터 소스 ──────────────────────────────────

/// 미세먼지 데이터 소스 (abstract interface 타입으로 제공)
/// 서버 프록시 구현체로 교체 시 이 provider만 변경하면 됨
final dustDataSourceProvider = Provider<DustDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AirKoreaService(prefs);
});

/// Backward-compatible alias (AirKoreaService 직접 참조가 필요한 경우)
final airKoreaServiceProvider = Provider<AirKoreaService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AirKoreaService(prefs);
});

final dustRepositoryProvider = Provider<DustRepository>((ref) {
  return DustRepository(
    ref.watch(dustDataSourceProvider),
    ref.watch(locationServiceProvider),
  );
});

// ── 미세먼지 실시간 데이터 ────────────────────────────────

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

// ── 예보 데이터 ───────────────────────────────────────────

final tomorrowForecastProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(dustRepositoryProvider);
  return repo.getTomorrowForecast();
});

final hourlyDataProvider =
    FutureProvider.family<List<HourlyDustData>, String>(
  (ref, stationName) async {
    final repo = ref.watch(dustRepositoryProvider);
    return repo.getHourlyData(stationName);
  },
);

final hourlyHistoryProvider =
    FutureProvider.family<List<HourlyDustData>, String>(
  (ref, stationName) async {
    final repo = ref.watch(dustRepositoryProvider);
    return repo.getHourlyHistory(stationName);
  },
);

final weeklyForecastProvider =
    FutureProvider.family<List<WeeklyForecastData>, String>(
  (ref, sidoName) async {
    final repo = ref.watch(dustRepositoryProvider);
    return repo.getWeeklyForecast(sidoName: sidoName);
  },
);
