import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils - formatTimeOnly', () {
    test('오전 7시 30분', () {
      final result = AppDateUtils.formatTimeOnly(7, 30);
      expect(result, contains('오전'));
      expect(result, contains('07'));
      expect(result, contains('30'));
    });

    test('오후 6시 0분', () {
      final result = AppDateUtils.formatTimeOnly(18, 0);
      expect(result, contains('오후'));
      expect(result, contains('06'));
      expect(result, contains('00'));
    });

    test('자정 (0시) → 오전 12시', () {
      final result = AppDateUtils.formatTimeOnly(0, 0);
      expect(result, contains('오전'));
      expect(result, contains('12'));
    });

    test('정오 (12시) → 오후 12시', () {
      final result = AppDateUtils.formatTimeOnly(12, 0);
      expect(result, contains('오후'));
      expect(result, contains('12'));
    });
  });

  group('AppDateUtils - formatDateTime', () {
    test('날짜 형식 확인', () {
      final dt = DateTime(2026, 4, 5, 9, 30);
      final result = AppDateUtils.formatDateTime(dt);
      expect(result, '2026.04.05 09:30');
    });

    test('한 자리 월/일 패딩', () {
      final dt = DateTime(2026, 1, 3, 8, 5);
      final result = AppDateUtils.formatDateTime(dt);
      expect(result, '2026.01.03 08:05');
    });
  });

  group('AppDateUtils - relativeTime', () {
    test('1분 미만 → 방금 전', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(AppDateUtils.relativeTime(dt), '방금 전');
    });

    test('30분 전', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 30));
      expect(AppDateUtils.relativeTime(dt), '30분 전');
    });

    test('2시간 전', () {
      final dt = DateTime.now().subtract(const Duration(hours: 2));
      expect(AppDateUtils.relativeTime(dt), '2시간 전');
    });

    test('3일 전', () {
      final dt = DateTime.now().subtract(const Duration(days: 3));
      expect(AppDateUtils.relativeTime(dt), '3일 전');
    });
  });
}
