import '../../data/models/dust_data.dart';
import '../../data/models/forecast_models.dart';

abstract class DustDataSource {
  Future<DustData?> getDustData(String stationName);
  Future<List<HourlyDustData>> getHourlyData(String stationName);
  Future<List<HourlyDustData>> getHourlyHistory(String stationName);
  Future<List<WeeklyForecastData>> getWeeklyForecast({String? sidoName});
  Future<String?> getTomorrowForecast({String? sidoName});
  Future<String?> getSidoForStation(String stationName);
  Future<List<String>> searchStations(String keyword);
}
