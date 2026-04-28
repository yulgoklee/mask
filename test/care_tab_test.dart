import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/care/care_tab.dart';

// ── dataTimeLabel 단위 테스트 ──────────────────────────────
//
// 검증 대상: care_tab.dart 의 dataTimeLabel(DateTime)
//   에어코리아 측정 시각(정시)을 "HH:00 기준" 형식으로 반환.

void main() {
  group('dataTimeLabel (care_tab.dart)', () {
    // ── 시간대별 24시간제 표기 ──────────────────────────────
    test('자정(0시) → 00:00 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 0)), '00:00 기준'));

    test('오전 1시 → 01:00 기준 (한 자리 시간 0-패딩)',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 1)), '01:00 기준'));

    test('오전 7시 → 07:00 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 7)), '07:00 기준'));

    test('정오(12시) → 12:00 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 12)), '12:00 기준'));

    test('오후 1시 → 13:00 기준 (24시간제)',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 13)), '13:00 기준'));

    test('오후 11시 → 23:00 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 23)), '23:00 기준'));

    // ── 반환값 형식 검증 ────────────────────────────────────
    test('반환값에 \\n 없음 (단문 강제)', () {
      for (var h = 0; h < 24; h++) {
        final result = dataTimeLabel(DateTime(2024, 1, 1, h));
        expect(result.contains('\n'), false,
            reason: '$h시의 반환값에 줄바꿈이 있으면 안 됩니다');
      }
    });

    test('반환값이 항상 "기준"으로 끝남', () {
      for (var h = 0; h < 24; h++) {
        expect(dataTimeLabel(DateTime(2024, 1, 1, h)).endsWith('기준'), true,
            reason: '$h시의 반환값이 "기준"으로 끝나야 합니다');
      }
    });

    test('HH 부분이 항상 두 자리', () {
      for (var h = 0; h < 10; h++) {
        final result = dataTimeLabel(DateTime(2024, 1, 1, h));
        expect(result.startsWith('0'), true,
            reason: '$h시는 0-패딩되어야 합니다: $result');
      }
    });
  });
}
