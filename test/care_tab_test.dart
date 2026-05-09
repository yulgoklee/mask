import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/care/care_tab.dart';

// ── dataTimeLabel 단위 테스트 ──────────────────────────────
//
// 시안 v3 형식: "HH:mm 갱신" (24시간제 + "갱신" 접미)

void main() {
  group('dataTimeLabel (care_tab.dart)', () {
    test('자정(0시) → 00:00 갱신',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 0)), '00:00 갱신'));

    test('오전 1시 → 01:00 갱신',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 1)), '01:00 갱신'));

    test('오전 7시 30분 → 07:30 갱신',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 7, 30)), '07:30 갱신'));

    test('정오(12시) → 12:00 갱신',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 12)), '12:00 갱신'));

    test('오후 2시 5분 → 14:05 갱신',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 14, 5)), '14:05 갱신'));

    test('오후 11시(23시) → 23:00 갱신',
        () => expect(dataTimeLabel(DateTime(2024, 1, 1, 23)), '23:00 갱신'));

    test('반환값에 \\n 없음 (단문 강제)', () {
      for (var h = 0; h < 24; h++) {
        final result = dataTimeLabel(DateTime(2024, 1, 1, h));
        expect(result.contains('\n'), false,
            reason: '$h시의 반환값에 줄바꿈이 있으면 안 됩니다');
      }
    });

    test('반환값이 항상 "갱신"으로 끝남', () {
      for (var h = 0; h < 24; h++) {
        expect(dataTimeLabel(DateTime(2024, 1, 1, h)).endsWith('갱신'), true,
            reason: '$h시의 반환값이 "갱신"으로 끝나야 합니다');
      }
    });

    test('항상 5자 시각 (HH:mm) 포함', () {
      for (var h = 0; h < 24; h++) {
        for (var m in [0, 5, 30, 59]) {
          final r = dataTimeLabel(DateTime(2024, 1, 1, h, m));
          // "HH:mm 갱신" → 길이 8 (5자 시각 + 공백 + 2자)
          expect(r.length, 8, reason: '${h}:$m 형식 길이 검증');
        }
      }
    });
  });
}
