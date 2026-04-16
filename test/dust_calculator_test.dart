import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/utils/dust_calculator.dart';
import 'package:mask_alert/data/models/dust_data.dart';
import 'package:mask_alert/data/models/user_profile.dart';

DustData _dust(int pm25, {int pm10 = 30}) => DustData(
      stationName: '테스트',
      pm25Value: pm25,
      pm10Value: pm10,
      pm25Grade: '보통',
      pm10Grade: '보통',
      dataTime: DateTime.now(),
      fetchedAt: DateTime.now(),
    );

/// 기본 프로필: S=0.1(min) → T_final=31.5
UserProfile get _defaultProfile => UserProfile.defaultProfile();

/// 고민감 프로필: 비염(+0.15) + 예민(+0.10) + 임신여성(+0.30) → S=0.55 → T_final≈15.75
UserProfile get _sensitiveProfile => UserProfile(
      nickname: '테스트',
      birthYear: 1990,
      gender: 'female',
      respiratoryStatus: 1,  // 비염
      sensitivityLevel: 2,   // 예민
      isPregnant: true,       // +0.30
      recentSkinTreatment: false,
      outdoorMinutes: 1,
      activityTags: const [],
      discomfortLevel: 0,
    );

void main() {
  group('DustCalculator - 기본 프로필 (T_final=31.5)', () {
    // T_final=31.5 기준
    // ratio<0.5 → low (pm25 < 15.75)
    // 0.5~1.0   → normal (15.75 ~ 31.5)
    // 1.0~1.5   → warning (31.5 ~ 47.25)
    // 1.5~2.0   → danger  (47.25 ~ 63.0)
    // ≥2.0      → critical (≥63.0)

    test('PM2.5=10 → 안전(low), 마스크 불필요', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(10));
      expect(r.riskLevel, RiskLevel.low);
      expect(r.maskRequired, false);
      expect(r.maskType, null);
    });

    test('PM2.5=20 → 보통(normal)', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(20));
      expect(r.riskLevel, RiskLevel.normal);
      expect(r.maskRequired, false);
    });

    test('PM2.5=35 → 주의(warning), 마스크 KF80', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(35));
      expect(r.riskLevel, RiskLevel.warning);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF80');
    });

    test('PM2.5=50 → 나쁨(danger), 마스크 KF94', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(50));
      expect(r.riskLevel, RiskLevel.danger);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF94');
    });

    test('PM2.5=70 → 매우나쁨(critical), 마스크 KF94', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(70));
      expect(r.riskLevel, RiskLevel.critical);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF94');
    });
  });

  group('DustCalculator - 고민감 프로필 (T_final≈15.75)', () {
    // S=0.55 → T_final = 35×0.45 = 15.75
    // ratio<0.5 → low (pm25 < 7.875)
    // 0.5~1.0   → normal (< 15.75)
    // 1.0~1.5   → warning (15.75 ~ 23.6)

    test('PM2.5=10 → 보통(normal)', () {
      final r = DustCalculator.calculate(_sensitiveProfile, _dust(10));
      expect(r.riskLevel, RiskLevel.normal);
    });

    test('PM2.5=20 → 주의(warning)', () {
      final r = DustCalculator.calculate(_sensitiveProfile, _dust(20));
      expect(r.riskLevel, RiskLevel.warning);
      expect(r.maskRequired, true);
    });
  });

  group('DustCalculator - 실시간 경보', () {
    test('T_final의 2배 이상 → shouldSendRealtime=true', () {
      // 기본 T_final=31.5, 2배=63.0
      final r = DustCalculator.calculate(_defaultProfile, _dust(65));
      expect(r.shouldSendRealtime, true);
    });

    test('T_final의 2배 미만 → shouldSendRealtime=false', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(20));
      expect(r.shouldSendRealtime, false);
    });
  });

  group('DustCalculator - 데이터 없음', () {
    test('pm25Value null → unknown 반환', () {
      final dust = DustData(
        stationName: '테스트',
        pm25Value: null,
        pm10Value: null,
        pm25Grade: '알수없음',
        pm10Grade: '알수없음',
        dataTime: DateTime.now(),
        fetchedAt: DateTime.now(),
      );
      final r = DustCalculator.calculate(_defaultProfile, dust);
      expect(r.riskLevel, RiskLevel.unknown);
      expect(r.maskRequired, false);
    });
  });

  group('DustCalculationResult - tFinal 포함 여부', () {
    test('결과에 tFinal 값이 포함됨', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(20));
      expect(r.tFinal, closeTo(31.5, 0.5));
    });
  });

  group('RiskLevel 라벨', () {
    test('각 단계 라벨 확인', () {
      expect(RiskLevel.low.label, '안전');
      expect(RiskLevel.normal.label, '보통');
      expect(RiskLevel.warning.label, '주의');
      expect(RiskLevel.danger.label, '나쁨');
      expect(RiskLevel.critical.label, '매우나쁨');
      expect(RiskLevel.unknown.label, '알수없음');
    });
  });
}
