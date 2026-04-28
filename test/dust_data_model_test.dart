import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/data/models/dust_data.dart';

void main() {
  group('DustData.fromJson', () {
    test('정상 파싱', () {
      final json = {
        'stationName': '강남구',
        'pm25Value': '35',
        'pm10Value': '53',
        'pm25Grade': '2',
        'pm10Grade': '2',
        'dataTime': '2026-03-30 20:00',
      };
      final d = DustData.fromJson(json);
      expect(d.stationName, '강남구');
      expect(d.pm25Value, 35);
      expect(d.pm10Value, 53);
      expect(d.pm25Grade, '보통');
      expect(d.pm10Grade, '보통');
    });

    test('등급 코드 → 한글 변환', () {
      final grade = (String code) => DustData.fromJson({
            'stationName': '',
            'pm25Value': '10',
            'pm10Value': '10',
            'pm25Grade': code,
            'pm10Grade': code,
            'dataTime': '2026-03-30 20:00',
          }).pm25Grade;

      expect(grade('1'), '좋음');
      expect(grade('2'), '보통');
      expect(grade('3'), '나쁨');
      expect(grade('4'), '매우나쁨');
      expect(grade(''), '알수없음');
      expect(grade('-'), '알수없음');
    });

    test('수치 - (데이터없음) → null 처리', () {
      final json = {
        'stationName': '테스트',
        'pm25Value': '-',
        'pm10Value': '-',
        'pm25Grade': '1',
        'pm10Grade': '1',
        'dataTime': '2026-03-30 20:00',
      };
      final d = DustData.fromJson(json);
      expect(d.pm25Value, null);
      expect(d.pm10Value, null);
    });

    test('stationName 누락 → 빈 문자열 (fallback 없음)', () {
      final json = {
        'pm25Value': '10',
        'pm10Value': '20',
        'pm25Grade': '1',
        'pm10Grade': '1',
        'dataTime': '2026-03-30 20:00',
      };
      final d = DustData.fromJson(json);
      expect(d.stationName, '');
    });
  });

  // ── fallbackStationName ────────────────────────────────────

  group('DustData.fromJson — fallbackStationName', () {
    final baseJson = {
      'pm25Value': '10',
      'pm10Value': '20',
      'pm25Grade': '1',
      'pm10Grade': '1',
      'dataTime': '2026-03-30 20:00',
    };

    test('API stationName 정상 → API 값 사용 (fallback 무시)', () {
      final d = DustData.fromJson(
        {...baseJson, 'stationName': '강남구'},
        fallbackStationName: '쿼리측정소',
      );
      expect(d.stationName, '강남구');
    });

    test('API stationName null → fallback 사용', () {
      final d = DustData.fromJson(
        {...baseJson, 'stationName': null},
        fallbackStationName: '서초구',
      );
      expect(d.stationName, '서초구');
    });

    test('API stationName 빈 문자열 → fallback 사용', () {
      final d = DustData.fromJson(
        {...baseJson, 'stationName': ''},
        fallbackStationName: '종로구',
      );
      expect(d.stationName, '종로구');
    });

    test('API stationName null + fallback도 null → 빈 문자열', () {
      final d = DustData.fromJson(
        {...baseJson},
      );
      expect(d.stationName, '');
    });
  });

  group('DustData.toJson / fromCacheJson 왕복', () {
    test('직렬화 후 역직렬화하면 동일한 값', () {
      final original = DustData(
        stationName: '수원',
        pm25Value: 42,
        pm10Value: 88,
        pm25Grade: '나쁨',
        pm10Grade: '나쁨',
        dataTime: DateTime(2026, 3, 30, 20, 0),
        fetchedAt: DateTime(2026, 3, 30, 20, 5),
      );
      final json = original.toJson();
      final restored = DustData.fromCacheJson(json);

      expect(restored.stationName, original.stationName);
      expect(restored.pm25Value, original.pm25Value);
      expect(restored.pm10Value, original.pm10Value);
      expect(restored.pm25Grade, original.pm25Grade);
      expect(restored.pm10Grade, original.pm10Grade);
    });
  });

  group('DustData.isCacheValid', () {
    test('30분 전 데이터 → 유효', () {
      final d = DustData(
        stationName: '테스트',
        pm25Value: 10,
        pm10Value: 20,
        pm25Grade: '좋음',
        pm10Grade: '좋음',
        dataTime: DateTime.now(),
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(d.isCacheValid, true);
    });

    test('2시간 전 데이터 → 만료', () {
      final d = DustData(
        stationName: '테스트',
        pm25Value: 10,
        pm10Value: 20,
        pm25Grade: '좋음',
        pm10Grade: '좋음',
        dataTime: DateTime.now(),
        fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(d.isCacheValid, false);
    });
  });
}
