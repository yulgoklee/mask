import '../models/dust_data.dart';
import '../models/forecast_models.dart';
import '../../core/services/dust_data_source.dart';
import '../../core/services/air_korea_service.dart';
import '../../core/services/location_service.dart';

/// GPS 측정소 자동 감지 결과
class DetectStationResult {
  final String? station;
  final LocationError? error;

  DetectStationResult._({this.station, this.error});
  factory DetectStationResult.success(String station) =>
      DetectStationResult._(station: station);
  factory DetectStationResult.failure(LocationError error) =>
      DetectStationResult._(error: error);
  factory DetectStationResult.notFound() => DetectStationResult._();

  bool get isSuccess => station != null;
}

/// 미세먼지 데이터 접근 Repository
class DustRepository {
  final DustDataSource _dataSource;
  final LocationService _location;

  DustRepository(this._dataSource, this._location);

  /// 저장된 측정소 기준 미세먼지 조회
  /// 측정소 미설정 시 null 반환 — UI에서 위치 설정 유도
  Future<DustData?> getCurrentDustData() async {
    final station = _location.getSavedStation();
    if (station == null) return null;
    return _dataSource.getDustData(station);
  }

  /// GPS로 현재 위치 기반 측정소 자동 감지 후 저장
  Future<DetectStationResult> detectAndSaveStation() async {
    final result = await _location.getCurrentPosition();
    if (!result.isSuccess) {
      return DetectStationResult.failure(result.error!);
    }

    final pos = result.position!;
    // 좌표 → 최근접 측정소 탐색 (순수 로컬 계산, 데이터 소스와 무관)
    final station = await AirKoreaService.findNearestStation(
        pos.latitude, pos.longitude);
    if (station == null) return DetectStationResult.notFound();

    await _location.saveStation(station);
    await _location.saveLastPosition(pos.latitude, pos.longitude);
    return DetectStationResult.success(station);
  }

  /// 측정소명 직접 지정하여 조회
  Future<DustData?> getDustDataByStation(String stationName) =>
      _dataSource.getDustData(stationName);

  /// 내일 예보 조회 (현재 측정소 기준 지역 필터링)
  Future<String?> getTomorrowForecast() async {
    final station = _location.getSavedStation();
    String? sido;
    if (station != null) {
      sido = await _dataSource.getSidoForStation(station);
    }
    return _dataSource.getTomorrowForecast(sidoName: sido);
  }

  /// 시간별 데이터 조회
  Future<List<HourlyDustData>> getHourlyData(String stationName) =>
      _dataSource.getHourlyData(stationName);

  /// 시간별 과거 데이터 조회
  Future<List<HourlyDustData>> getHourlyHistory(String stationName) =>
      _dataSource.getHourlyHistory(stationName);

  /// 주간 예보 조회
  Future<List<WeeklyForecastData>> getWeeklyForecast({String? sidoName}) =>
      _dataSource.getWeeklyForecast(sidoName: sidoName);

  /// 측정소의 시도명 조회
  Future<String?> getSidoForStation(String stationName) =>
      _dataSource.getSidoForStation(stationName);

  /// 현재 저장된 측정소명
  String? get savedStation => _location.getSavedStation();

  /// 측정소 변경
  Future<void> changeStation(String stationName) =>
      _location.saveStation(stationName);
}
