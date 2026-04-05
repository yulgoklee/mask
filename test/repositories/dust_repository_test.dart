import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/core/constants/app_constants.dart';
import 'package:mask_alert/core/services/dust_data_source.dart';
import 'package:mask_alert/core/services/gps_service.dart';
import 'package:mask_alert/core/services/geolocator_gps_service.dart';
import 'package:mask_alert/core/services/location_service.dart';
import 'package:mask_alert/data/models/dust_data.dart';
import 'package:mask_alert/data/models/forecast_models.dart';
import 'package:mask_alert/data/repositories/dust_repository.dart';

// ── Mocks ─────────────────────────────────────────────────

class MockDustDataSource extends Mock implements DustDataSource {}
class MockGpsService extends Mock implements GpsService {}

// ── 헬퍼 ─────────────────────────────────────────────────

DustData _fakeDust({String station = '종로구', int pm25 = 20}) => DustData(
      stationName: station,
      pm25Value: pm25,
      pm10Value: 40,
      pm25Grade: '보통',
      pm10Grade: '보통',
      dataTime: DateTime.now().subtract(const Duration(minutes: 5)),
      fetchedAt: DateTime.now(),
    );

/// SharedPreferences 인메모리 초기화 헬퍼
Future<SharedPreferences> _mockPrefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  late MockDustDataSource mockSource;
  late MockGpsService mockGps;

  setUp(() {
    mockSource = MockDustDataSource();
    mockGps = MockGpsService();
  });

  // ── 저장된 측정소 없을 때 ─────────────────────────────────

  group('getCurrentDustData — 측정소 미설정', () {
    test('저장된 측정소 없으면 null 반환', () async {
      final prefs = await _mockPrefs(); // 아무 값 없음
      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      final result = await repo.getCurrentDustData();

      expect(result, isNull);
      verifyNever(() => mockSource.getDustData(any()));
    });
  });

  // ── 저장된 측정소 있을 때 ─────────────────────────────────

  group('getCurrentDustData — 측정소 설정됨', () {
    test('저장된 측정소명으로 API 호출 후 데이터 반환', () async {
      final prefs = await _mockPrefs({
        AppConstants.prefStationName: '종로구',
      });
      when(() => mockSource.getDustData('종로구'))
          .thenAnswer((_) async => _fakeDust());

      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      final result = await repo.getCurrentDustData();

      expect(result, isNotNull);
      expect(result!.stationName, '종로구');
      verify(() => mockSource.getDustData('종로구')).called(1);
    });

    test('API가 null 반환하면 null 반환', () async {
      final prefs = await _mockPrefs({
        AppConstants.prefStationName: '서초구',
      });
      when(() => mockSource.getDustData('서초구'))
          .thenAnswer((_) async => null);

      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      final result = await repo.getCurrentDustData();
      expect(result, isNull);
    });
  });

  // ── savedStation getter ───────────────────────────────────

  group('savedStation', () {
    test('측정소 저장 후 savedStation으로 조회 가능', () async {
      final prefs = await _mockPrefs({
        AppConstants.prefStationName: '강남구',
      });
      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      expect(repo.savedStation, '강남구');
    });

    test('측정소 미설정 시 savedStation은 null', () async {
      final prefs = await _mockPrefs();
      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      expect(repo.savedStation, isNull);
    });
  });

  // ── changeStation ─────────────────────────────────────────

  group('changeStation', () {
    test('측정소 변경 후 즉시 반영', () async {
      final prefs = await _mockPrefs();
      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      await repo.changeStation('마포구');

      expect(repo.savedStation, '마포구');
    });
  });

  // ── detectAndSaveStation ──────────────────────────────────

  group('detectAndSaveStation — GPS 실패', () {
    test('권한 거절 시 failure 반환', () async {
      when(() => mockGps.getCurrentPosition()).thenAnswer(
        (_) async => LocationResult.failure(LocationError.permissionDenied),
      );

      final prefs = await _mockPrefs();
      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      final result = await repo.detectAndSaveStation();

      expect(result.isSuccess, isFalse);
      expect(result.error, LocationError.permissionDenied);
    });

    test('GPS 꺼짐 시 serviceDisabled 반환', () async {
      when(() => mockGps.getCurrentPosition()).thenAnswer(
        (_) async => LocationResult.failure(LocationError.serviceDisabled),
      );

      final prefs = await _mockPrefs();
      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      final result = await repo.detectAndSaveStation();

      expect(result.error, LocationError.serviceDisabled);
    });
  });

  // ── getTomorrowForecast ───────────────────────────────────

  group('getTomorrowForecast', () {
    test('측정소 미설정 시 sido 없이 예보 조회', () async {
      when(() => mockSource.getTomorrowForecast(sidoName: any(named: 'sidoName')))
          .thenAnswer((_) async => '보통');

      final prefs = await _mockPrefs();
      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      final result = await repo.getTomorrowForecast();
      expect(result, '보통');
    });

    test('측정소 설정 시 sido 기반 예보 조회', () async {
      when(() => mockSource.getSidoForStation('강남구'))
          .thenAnswer((_) async => '서울');
      when(() => mockSource.getTomorrowForecast(sidoName: '서울'))
          .thenAnswer((_) async => '나쁨');

      final prefs = await _mockPrefs({
        AppConstants.prefStationName: '강남구',
      });
      final location = LocationService(prefs, mockGps);
      final repo = DustRepository(mockSource, location);

      final result = await repo.getTomorrowForecast();
      expect(result, '나쁨');
    });
  });
}
