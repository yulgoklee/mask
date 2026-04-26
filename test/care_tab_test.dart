import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/care/care_tab.dart';

// ── relativeTimeLabel 단위 테스트 ─────────────────────────
//
// 검증 대상: care_tab.dart 의 relativeTimeLabel(DateTime)
//   '방금 전' / 'N분 전' / 'N시간 전' / 'N일 전'
//
// 주의: DateTime.now() 기반 계산이라 테스트 실행 시점에 따라
//   경계값에서 ±1분 오차가 생길 수 있음.
//   따라서 경계 정확값보다 내부 범위 값으로 검증.

void main() {
  group('relativeTimeLabel (care_tab.dart)', () {
    // ── '방금 전' ─────────────────────────────────────────
    test('0초 전 → 방금 전', () {
      final now = DateTime.now();
      expect(relativeTimeLabel(now), '방금 전');
    });

    test('30초 전 → 방금 전', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(relativeTimeLabel(dt), '방금 전');
    });

    test('59초 전 → 방금 전 (1분 미만)', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 59));
      expect(relativeTimeLabel(dt), '방금 전');
    });

    // ── 'N분 전' ──────────────────────────────────────────
    test('1분 전 → 1분 전', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 1));
      expect(relativeTimeLabel(dt), '1분 전');
    });

    test('30분 전 → 30분 전', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 30));
      expect(relativeTimeLabel(dt), '30분 전');
    });

    test('59분 전 → 59분 전 (1시간 미만)', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 59));
      expect(relativeTimeLabel(dt), '59분 전');
    });

    // ── 'N시간 전' ────────────────────────────────────────
    test('1시간 전 → 1시간 전', () {
      final dt = DateTime.now().subtract(const Duration(hours: 1));
      expect(relativeTimeLabel(dt), '1시간 전');
    });

    test('12시간 전 → 12시간 전', () {
      final dt = DateTime.now().subtract(const Duration(hours: 12));
      expect(relativeTimeLabel(dt), '12시간 전');
    });

    test('23시간 전 → 23시간 전 (24시간 미만)', () {
      final dt = DateTime.now().subtract(const Duration(hours: 23));
      expect(relativeTimeLabel(dt), '23시간 전');
    });

    // ── 'N일 전' ──────────────────────────────────────────
    test('1일 전 → 1일 전', () {
      final dt = DateTime.now().subtract(const Duration(days: 1));
      expect(relativeTimeLabel(dt), '1일 전');
    });

    test('3일 전 → 3일 전', () {
      final dt = DateTime.now().subtract(const Duration(days: 3));
      expect(relativeTimeLabel(dt), '3일 전');
    });

    test('7일 전 → 7일 전', () {
      final dt = DateTime.now().subtract(const Duration(days: 7));
      expect(relativeTimeLabel(dt), '7일 전');
    });

    // ── 반환값 형식 검증 ───────────────────────────────────
    test('반환값에 \\n 없음 (단문 강제)', () {
      final cases = [
        DateTime.now(),
        DateTime.now().subtract(const Duration(minutes: 5)),
        DateTime.now().subtract(const Duration(hours: 2)),
        DateTime.now().subtract(const Duration(days: 2)),
      ];
      for (final dt in cases) {
        expect(relativeTimeLabel(dt).contains('\n'), false,
            reason: '$dt 의 반환값에 줄바꿈이 있으면 안 됩니다');
      }
    });

    test('반환값이 비어있지 않음', () {
      final cases = [
        DateTime.now(),
        DateTime.now().subtract(const Duration(minutes: 10)),
        DateTime.now().subtract(const Duration(hours: 5)),
        DateTime.now().subtract(const Duration(days: 1)),
      ];
      for (final dt in cases) {
        expect(relativeTimeLabel(dt).isNotEmpty, true);
      }
    });
  });
}
