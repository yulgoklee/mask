import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/location_service.dart';
import '../core/services/notification_service.dart';

// ── 기반 Provider ─────────────────────────────────────────

/// main.dart에서 ProviderScope override로 초기화됨
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart with override');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocationService(prefs);
});
