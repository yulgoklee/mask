import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'gps_service.dart';

export 'gps_service.dart' show LocationResult, LocationError;

/// 위치 관련 서비스 파사드
///
/// 책임:
/// - GPS 위치 조회 → [GpsService]에 위임 (테스트 시 교체 가능)
/// - 측정소·위치 정보 영속 저장 → SharedPreferences
class LocationService {
  static const String _latKey = 'saved_lat';
  static const String _lngKey = 'saved_lng';

  final SharedPreferences _prefs;
  final GpsService _gps;

  LocationService(this._prefs, this._gps);

  // ── GPS 위임 메서드 ──────────────────────────────────────

  /// 현재 위치 조회 (권한 확인 포함)
  Future<LocationResult> getCurrentPosition() => _gps.getCurrentPosition();

  /// 현재 위치 권한 상태
  Future<LocationPermission> getPermissionStatus() =>
      _gps.getPermissionStatus();

  /// 앱 설정 화면 열기 (권한 영구 거절 시)
  Future<bool> openAppSettings() => _gps.openAppSettings();

  /// 위치 서비스 설정 화면 열기 (GPS 꺼짐 시)
  Future<bool> openLocationSettings() => _gps.openLocationSettings();

  // ── 저장소 메서드 ────────────────────────────────────────

  /// 저장된 측정소명 조회
  String? getSavedStation() =>
      _prefs.getString(AppConstants.prefStationName);

  /// 측정소명 저장
  Future<void> saveStation(String name) =>
      _prefs.setString(AppConstants.prefStationName, name);

  /// 마지막 위치 저장
  Future<void> saveLastPosition(double lat, double lng) async {
    await _prefs.setDouble(_latKey, lat);
    await _prefs.setDouble(_lngKey, lng);
  }

  /// 마지막 저장 위치 반환
  (double, double)? getLastPosition() {
    final lat = _prefs.getDouble(_latKey);
    final lng = _prefs.getDouble(_lngKey);
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }
}
