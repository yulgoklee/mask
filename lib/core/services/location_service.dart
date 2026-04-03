import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 위치 감지 실패 원인
enum LocationError {
  serviceDisabled,          // GPS / 위치 서비스 꺼짐
  permissionDenied,         // 권한 거절 (재요청 가능)
  permissionDeniedForever,  // 권한 영구 거절 (설정 앱 이동 필요)
  timeout,                  // 10초 타임아웃
  unknown,                  // 기타
}

/// 위치 조회 결과
class LocationResult {
  final Position? position;
  final LocationError? error;

  LocationResult._(this.position, this.error);
  factory LocationResult.success(Position p) => LocationResult._(p, null);
  factory LocationResult.failure(LocationError e) => LocationResult._(null, e);

  bool get isSuccess => position != null;
}

/// 위치 권한 및 현재 위치 조회 서비스
class LocationService {
  static const String _stationKey = 'saved_station_name';
  static const String _latKey = 'saved_lat';
  static const String _lngKey = 'saved_lng';

  final SharedPreferences _prefs;

  LocationService(this._prefs);

  /// 위치 권한 요청 후 현재 위치 반환 — 실패 시 원인 포함 LocationResult 반환
  ///
  /// 전략:
  /// 1) 권한/서비스 확인
  /// 2) getLastKnownPosition() — 캐시 위치 즉시 반환 (배터리 절약)
  /// 3) 캐시 없으면 getCurrentPosition() — medium 정확도, 30초 대기
  Future<LocationResult> getCurrentPosition() async {
    final permError = await _checkAndRequestPermission();
    if (permError != null) return LocationResult.failure(permError);

    try {
      // 1단계: 마지막 알려진 위치 (즉시 반환, 실패 없음)
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LocationResult.success(last);

      // 2단계: 실시간 위치 (medium = GPS + 네트워크, 30초 허용)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 30),
        ),
      );
      return LocationResult.success(pos);
    } on TimeoutException {
      return LocationResult.failure(LocationError.timeout);
    } catch (e) {
      // geolocator가 TimeoutException 대신 다른 예외를 던지는 경우 대비
      if (e.toString().toLowerCase().contains('timeout')) {
        return LocationResult.failure(LocationError.timeout);
      }
      return LocationResult.failure(LocationError.unknown);
    }
  }

  /// 권한 확인 및 요청 — 문제 없으면 null, 문제 있으면 LocationError 반환
  Future<LocationError?> _checkAndRequestPermission() async {
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return LocationError.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationError.permissionDenied;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationError.permissionDeniedForever;
    }

    return null;
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

  /// 앱 설정 열기 (권한 영구 거절 시)
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// 위치 서비스 설정 열기 (GPS 꺼짐 시)
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
