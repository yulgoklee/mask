import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/care/care_tab.dart';

// ── dataTimeLabel 단위 테스트 ──────────────────────────────
//
// 검증 대상: care_tab.dart 의 dataTimeLabel(DateTime)
//   E-1: "오전/오후 X시 기준" 12시간제 형식으로 반환.

void main() {
  group('dataTimeLabel (care_tab.dart)', () {
    // ── E-1: 12시간제 표기 ─────────────────────────────────
    test('자정(0시) → 오전 12시 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 0)), '오전 12시 기준'));

    test('오전 1시 → 오전 1시 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 1)), '오전 1시 기준'));

    test('오전 7시 → 오전 7시 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 7)), '오전 7시 기준'));

    test('정오(12시) → 오후 12시 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 12)), '오후 12시 기준'));

    test('오후 1시(13시) → 오후 1시 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 13)), '오후 1시 기준'));

    test('오후 11시(23시) → 오후 11시 기준',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 23)), '오후 11시 기준'));

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

    test('오전/오후 구분 — 오전(0~11시), 오후(12~23시)', () {
      for (var h = 0; h < 12; h++) {
        expect(dataTimeLabel(DateTime(2024, 1, 1, h)).startsWith('오전'), true,
            reason: '$h시는 오전이어야 합니다');
      }
      for (var h = 12; h < 24; h++) {
        expect(dataTimeLabel(DateTime(2024, 1, 1, h)).startsWith('오후'), true,
            reason: '$h시는 오후이어야 합니다');
      }
    });
  });
}
