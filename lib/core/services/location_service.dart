import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 위치 권한 및 현재 위치 조회 서비스
class LocationService {
  static const String _stationKey = 'saved_station_name';
  static const String _latKey = 'saved_lat';
  static const String _lngKey = 'saved_lng';

  final SharedPreferences _prefs;

  LocationService(this._prefs);

  /// 위치 권한 요청 후 현재 위치 반환 (웹/앱 공통)
  Future<Position?> getCurrentPosition() async {
    final permission = await _checkAndRequestPermission();
    if (!permission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// 권한 확인 및 요청 (웹/앱 공통)
  Future<bool> _checkAndRequestPermission() async {
    // 웹은 isLocationServiceEnabled() 미지원 → 권한 바로 체크
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// 저장된 측정소명 조회
  String? getSavedStation() => _prefs.getString(_stationKey);

  /// 측정소명 저장
  Future<void> saveStation(String name) =>
      _prefs.setString(_stationKey, name);

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

  /// 위치 권한 상태 반환
  Future<LocationPermission> getPermissionStatus() =>
      Geolocator.checkPermission();

  /// 설정 앱으로 이동 (권한 영구 거절 시)
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
