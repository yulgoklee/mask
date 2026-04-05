import 'package:geolocator/geolocator.dart';

/// GPS 위치 조회 추상 인터페이스
///
/// 테스트 시 [FakeGpsService]로 교체 가능.
/// 실기기에서는 [GeolocatorGpsService]를 사용.
abstract interface class GpsService {
  /// 현재 위치 조회 (권한 확인 포함)
  Future<LocationResult> getCurrentPosition();

  /// 현재 위치 권한 상태 확인
  Future<LocationPermission> getPermissionStatus();

  /// 앱 설정 화면 열기 (권한 영구 거절 시)
  Future<bool> openAppSettings();

  /// 위치 서비스 설정 화면 열기 (GPS 꺼짐 시)
  Future<bool> openLocationSettings();
}

// ── 위치 조회 결과 ─────────────────────────────────────────

/// 위치 감지 실패 원인
enum LocationError {
  serviceDisabled,         // GPS / 위치 서비스 꺼짐
  permissionDenied,        // 권한 거절 (재요청 가능)
  permissionDeniedForever, // 권한 영구 거절 (설정 앱 이동 필요)
  timeout,                 // 타임아웃
  unknown,                 // 기타
}

/// GPS 조회 결과
class LocationResult {
  final Position? position;
  final LocationError? error;

  LocationResult._(this.position, this.error);
  factory LocationResult.success(Position p) => LocationResult._(p, null);
  factory LocationResult.failure(LocationError e) => LocationResult._(null, e);

  bool get isSuccess => position != null;
}
