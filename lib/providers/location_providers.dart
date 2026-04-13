import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/location_service.dart';
import 'core_providers.dart';
import 'dust_providers.dart';

// ── 위치 감지 상태 ─────────────────────────────────────────────

class LocationDetectionState {
  /// 현재 저장된 측정소명 (null = 미설정)
  final String? station;

  /// GPS 감지 진행 중
  final bool isDetecting;

  /// 마지막 오류 메시지 (null = 오류 없음)
  final String? errorMessage;

  /// GPS 오류 시 설정 화면 이동 여부
  final bool needsSettings;

  const LocationDetectionState({
    this.station,
    this.isDetecting = false,
    this.errorMessage,
    this.needsSettings = false,
  });

  LocationDetectionState copyWith({
    String? station,
    bool? isDetecting,
    String? errorMessage,
    bool? needsSettings,
    bool clearError = false,
  }) {
    return LocationDetectionState(
      station: station ?? this.station,
      isDetecting: isDetecting ?? this.isDetecting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      needsSettings: clearError ? false : (needsSettings ?? this.needsSettings),
    );
  }
}

// ── LocationStateNotifier ──────────────────────────────────────

class LocationStateNotifier extends Notifier<LocationDetectionState> {
  @override
  LocationDetectionState build() {
    final station = ref.read(locationServiceProvider).getSavedStation();
    return LocationDetectionState(station: station);
  }

  /// GPS로 현재 위치를 감지해 측정소 자동 업데이트
  ///
  /// 성공 시 [dustDataProvider], [tomorrowForecastProvider] invalidate
  /// Returns true on success, false on failure (errorMessage 세팅됨)
  Future<bool> detectFromGps() async {
    state = state.copyWith(isDetecting: true, clearError: true);

    final result = await ref.read(dustRepositoryProvider).detectAndSaveStation();

    if (result.isSuccess) {
      state = LocationDetectionState(station: result.station);
      ref.invalidate(dustDataProvider);
      ref.invalidate(tomorrowForecastProvider);
      return true;
    }

    final (msg, needsSettings) = _errorInfo(result.error);
    state = LocationDetectionState(
      station: state.station,
      isDetecting: false,
      errorMessage: msg,
      needsSettings: needsSettings,
    );
    return false;
  }

  /// 수동 선택으로 측정소가 변경된 뒤 상태 동기화
  void onStationChanged() {
    final station = ref.read(locationServiceProvider).getSavedStation();
    state = LocationDetectionState(station: station);
  }

  /// 오류 메시지 초기화
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  (String, bool) _errorInfo(LocationError? error) {
    switch (error) {
      case LocationError.serviceDisabled:
        return ('GPS가 꺼져 있어요. 위치 서비스를 켜주세요.', true);
      case LocationError.permissionDeniedForever:
        return ('위치 권한이 거절되었어요. 설정에서 허용해주세요.', true);
      case LocationError.permissionDenied:
        return ('위치 권한을 허용해야 자동 감지가 가능해요.', false);
      case LocationError.timeout:
        return ('위치를 찾는 데 너무 오래 걸려요. 다시 시도해주세요.', false);
      default:
        return ('위치 감지에 실패했어요. 다시 시도해주세요.', false);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────

final locationStateProvider =
    NotifierProvider<LocationStateNotifier, LocationDetectionState>(
  LocationStateNotifier.new,
);
