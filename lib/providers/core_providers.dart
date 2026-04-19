import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/local_database.dart';
import '../core/engine/threshold_config.dart';
import '../core/engine/threshold_engine.dart';
import '../core/services/geolocator_gps_service.dart';
import '../core/services/gps_service.dart';
import '../core/services/location_service.dart';
import '../core/services/notification_service.dart';

// ── 기반 Provider ─────────────────────────────────────────

/// 알림 딥링크 페이로드 타입 — HomeScreen이 소비 후 null로 초기화
/// 'risk' | 'relief' | 'scheduled' | null
final pendingPayloadTypeProvider = StateProvider<String?>((ref) => null);

/// main.dart에서 ProviderScope override로 초기화됨
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart with override');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// GPS 서비스 (abstract interface 타입)
/// 테스트 시 FakeGpsService로 override 가능
final gpsServiceProvider = Provider<GpsService>((ref) {
  return GeolocatorGpsService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final gps = ref.watch(gpsServiceProvider);
  return LocationService(prefs, gps);
});

/// SQLite 로컬 DB — 앱 전역 싱글톤
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});

/// ThresholdEngine — 기본 설정으로 초기화 (향후 Remote Config 연동 시 교체)
final thresholdConfigProvider = Provider<ThresholdConfig>(
  (_) => ThresholdConfig.defaults,
);

final thresholdEngineProvider = Provider<ThresholdEngine>((ref) {
  final config = ref.watch(thresholdConfigProvider);
  return ThresholdEngine(config: config);
});
