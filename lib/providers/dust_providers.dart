import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/dust_data.dart';
import '../data/models/forecast_models.dart';
import '../data/repositories/aqi_history_repository.dart';
import '../data/repositories/dust_repository.dart';
import '../core/config/app_config.dart';
import '../core/services/air_korea_service.dart';
import '../core/services/aqi_polling_service.dart';
import '../core/services/cloud_functions_data_source.dart';
import '../core/services/dust_data_source.dart';
import '../core/utils/dust_calculator.dart';
import 'core_providers.dart';
import 'profile_providers.dart';

// ── 미세먼지 데이터 소스 ──────────────────────────────────

/// 미세먼지 데이터 소스 (abstract interface 타입으로 제공)
///
/// 우선순위:
/// 1. AppConfig.cloudFunctionsBaseUrl 설정 시 → CloudFunctionsDataSource (서버 프록시)
/// 2. 미설정 시 → AirKoreaService (직접 호출, 개발/폴백용)
final dustDataSourceProvider = Provider<DustDataSource>((ref) {
  if (AppConfig.cloudFunctionsBaseUrl.isNotEmpty) {
    return CloudFunctionsDataSource();
  }
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

// ── AQI 히스토리 (차트용) ────────────────────────────────

final aqiPollingServiceProvider = Provider<AqiPollingService>((ref) {
  return AqiPollingService(
    airKorea: ref.watch(airKoreaServiceProvider),
    db: ref.watch(localDatabaseProvider),
  );
});

final aqiHistoryRepositoryProvider = Provider<AqiHistoryRepository>((ref) {
  return AqiHistoryRepository(
    db: ref.watch(localDatabaseProvider),
    polling: ref.watch(aqiPollingServiceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// Care 탭 차트 데이터 — forecastGrade는 현재 예보 등급 (기본 '보통')
final aqiChartDataProvider = FutureProvider.family<AqiChartData, String>(
  (ref, forecastGrade) async {
    final repo = ref.watch(aqiHistoryRepositoryProvider);
    final profile = ref.watch(profileProvider);
    return repo.getChartData(
      forecastGrade: forecastGrade,
      profile: profile,
    );
  },
);

// ── 미세먼지 실시간 데이터 ────────────────────────────────

final dustDataProvider = FutureProvider<DustData?>((ref) async {
  final repo = ref.watch(dustRepositoryProvider);
  return repo.getCurrentDustData();
});

final dustCalculationProvider = Provider<DustCalculationResult?>((ref) {
  final dustAsync = ref.watch(dustDataProvider);
  final profile = ref.watch(profileProvider);
  final temporaryStates = ref.watch(temporaryStatesProvider);
  final todaySituations = ref.watch(todaySituationProvider);

  return dustAsync.when(
    data: (dust) {
      if (dust == null) return null;
      return DustCalculator.calculate(
        profile,
        dust,
        temporaryStates: temporaryStates,
        todaySituations: todaySituations,
      );
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
