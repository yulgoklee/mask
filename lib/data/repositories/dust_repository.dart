import '../models/dust_data.dart';
import '../../core/services/air_korea_service.dart';
import '../../core/services/location_service.dart';

/// 미세먼지 데이터 접근 Repository
class DustRepository {
  final AirKoreaService _airKorea;
  final LocationService _location;

  DustRepository(this._airKorea, this._location);

  /// 미세먼지 데이터 조회 (저장된 측정소 기준, 없으면 기본값)
  Future<DustData?> getCurrentDustData() async {
    final station = _location.getSavedStation() ?? '강남구';
    return _airKorea.getDustData(station);
  }

  /// GPS로 현재 위치 기반 측정소 자동 감지 후 저장
  Future<String?> detectAndSaveStation() async {
    final position = await _location.getCurrentPosition();
    if (position == null) return null;
    final station = await _airKorea.getNearestStation(
      position.latitude,
      position.longitude,
    );
    if (station != null) {
      await _location.saveStation(station);
      await _location.saveLastPosition(position.latitude, position.longitude);
    }
    return station;
  }

  /// 측정소명 직접 지정하여 조회
  Future<DustData?> getDustDataByStation(String stationName) =>
      _airKorea.getDustData(stationName);

  /// 내일 예보 조회 (현재 측정소 기준 지역 필터링)
  Future<String?> getTomorrowForecast() async {
    final station = _location.getSavedStation();
    String? sido;
    if (station != null) {
      sido = await _airKorea.getSidoForStation(station);
    }
    return _airKorea.getTomorrowForecast(sidoName: sido);
  }

  /// 현재 저장된 측정소명
  String? get savedStation => _location.getSavedStation();

  /// 측정소 변경
  Future<void> changeStation(String stationName) =>
      _location.saveStation(stationName);
}
