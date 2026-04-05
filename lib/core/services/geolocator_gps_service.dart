import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'gps_service.dart';

/// Geolocator 기반 GPS 서비스 구현체
class GeolocatorGpsService implements GpsService {
  @override
  Future<LocationResult> getCurrentPosition() async {
    final permError = await _checkAndRequestPermission();
    if (permError != null) return LocationResult.failure(permError);

    try {
      // 1단계: 마지막 알려진 위치 (즉시 반환, 배터리 절약)
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
      if (e.toString().toLowerCase().contains('timeout')) {
        return LocationResult.failure(LocationError.timeout);
      }
      return LocationResult.failure(LocationError.unknown);
    }
  }

  @override
  Future<LocationPermission> getPermissionStatus() =>
      Geolocator.checkPermission();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// 권한 확인 및 요청
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
}
