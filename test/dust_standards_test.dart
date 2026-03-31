import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/constants/dust_standards.dart';

void main() {
  group('DustStandards - PM2.5 등급', () {
    test('0~15 → 좋음', () {
      expect(DustStandards.getPm25Grade(0), DustGrade.good);
      expect(DustStandards.getPm25Grade(15), DustGrade.good);
    });
    test('16~35 → 보통', () {
      expect(DustStandards.getPm25Grade(16), DustGrade.normal);
      expect(DustStandards.getPm25Grade(35), DustGrade.normal);
    });
    test('36~75 → 나쁨', () {
      expect(DustStandards.getPm25Grade(36), DustGrade.bad);
      expect(DustStandards.getPm25Grade(75), DustGrade.bad);
    });
    test('76 이상 → 매우나쁨', () {
      expect(DustStandards.getPm25Grade(76), DustGrade.veryBad);
      expect(DustStandards.getPm25Grade(200), DustGrade.veryBad);
    });
  });

  group('DustStandards - PM10 등급', () {
    test('0~30 → 좋음', () {
      expect(DustStandards.getPm10Grade(0), DustGrade.good);
      expect(DustStandards.getPm10Grade(30), DustGrade.good);
    });
    test('31~80 → 보통', () {
      expect(DustStandards.getPm10Grade(31), DustGrade.normal);
      expect(DustStandards.getPm10Grade(80), DustGrade.normal);
    });
    test('81~150 → 나쁨', () {
      expect(DustStandards.getPm10Grade(81), DustGrade.bad);
      expect(DustStandards.getPm10Grade(150), DustGrade.bad);
    });
    test('151 이상 → 매우나쁨', () {
      expect(DustStandards.getPm10Grade(151), DustGrade.veryBad);
    });
  });

  group('DustGrade 라벨/이모지', () {
    test('라벨', () {
      expect(DustGrade.good.label, '좋음');
      expect(DustGrade.normal.label, '보통');
      expect(DustGrade.bad.label, '나쁨');
      expect(DustGrade.veryBad.label, '매우나쁨');
    });
    test('이모지', () {
      expect(DustGrade.good.emoji, '😊');
      expect(DustGrade.normal.emoji, '🙂');
      expect(DustGrade.bad.emoji, '😷');
      expect(DustGrade.veryBad.emoji, '🚨');
    });
  });

  group('DustStandards.worstGrade', () {
    test('더 나쁜 등급 반환', () {
      expect(DustStandards.worstGrade(DustGrade.good, DustGrade.bad), DustGrade.bad);
      expect(DustStandards.worstGrade(DustGrade.veryBad, DustGrade.normal), DustGrade.veryBad);
      expect(DustStandards.worstGrade(DustGrade.normal, DustGrade.normal), DustGrade.normal);
    });
  });
}
