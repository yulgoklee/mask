import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/utils/dust_calculator.dart';
import 'package:mask_alert/data/models/dust_data.dart';
import 'package:mask_alert/data/models/user_profile.dart';

// 기본 프로필: birthYear=1990(30대), 아무 가중치 없음 → S=0.1, T_final≈31.5
const _defaultProfile = UserProfile(
  nickname: '', birthYear: 1990, gender: 'male',
  respiratoryStatus: 0, sensitivityLevel: 1,
  isPregnant: false, recentSkinTreatment: false,
  outdoorMinutes: 1, activityTags: [], discomfortLevel: 1,
);

// 민감한 프로필: 비염+예민 → S 올라감
const _sensitiveProfile = UserProfile(
  nickname: '', birthYear: 1990, gender: 'male',
  respiratoryStatus: 1,  // +0.15
  sensitivityLevel: 2,   // +0.10
  isPregnant: false, recentSkinTreatment: false,
  outdoorMinutes: 1, activityTags: [], discomfortLevel: 1,
);

DustData _dust(int pm25) => DustData(
  stationName: '테스트', pm25Value: pm25, pm10Value: 30,
  pm25Grade: '보통', pm10Grade: '보통',
  dataTime: DateTime.now(), fetchedAt: DateTime.now(),
);

void main() {
  group('DustCalculator — T_final 비율 기반 위험도 (기본 프로필, T_final≈31.5)', () {
    test('PM2.5=10 (ratio<0.5) → low, 마스크 불필요', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(10));
      expect(r.riskLevel, RiskLevel.low);
      expect(r.maskRequired, false);
      expect(r.maskType, isNull);
    });

    test('PM2.5=25 (ratio≈0.79) → normal', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(25));
      expect(r.riskLevel, RiskLevel.normal);
      expect(r.maskRequired, false);
    });

    test('PM2.5=38 (ratio≈1.2) → warning, KF80', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(38));
      expect(r.riskLevel, RiskLevel.warning);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF80');
    });

    test('PM2.5=55 (ratio≈1.75) → danger, KF94', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(55));
      expect(r.riskLevel, RiskLevel.danger);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF94');
    });

    test('PM2.5=80 (ratio≥2.0) → critical, shouldSendRealtime', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(80));
      expect(r.riskLevel, RiskLevel.critical);
      expect(r.maskRequired, true);
      expect(r.shouldSendRealtime, true);
    });
  });

  group('DustCalculator — 민감한 프로필 (T_final 낮아짐)', () {
    test('민감 프로필은 같은 PM2.5에서 더 높은 위험도', () {
      const pm25 = 28;
      final rDefault   = DustCalculator.calculate(_defaultProfile,   _dust(pm25));
      final rSensitive = DustCalculator.calculate(_sensitiveProfile, _dust(pm25));
      // 민감 프로필은 T_final이 낮아 ratio가 높음
      expect(rSensitive.riskLevel.index, greaterThanOrEqualTo(rDefault.riskLevel.index));
    });
  });

  group('DustCalculator — 데이터 없음', () {
    test('pm25Value null → unknown 반환', () {
      final dust = DustData(
        stationName: '테스트', pm25Value: null, pm10Value: null,
        pm25Grade: '알수없음', pm10Grade: '알수없음',
        dataTime: DateTime.now(), fetchedAt: DateTime.now(),
      );
      final r = DustCalculator.calculate(_defaultProfile, dust);
      expect(r.riskLevel, RiskLevel.unknown);
      expect(r.maskRequired, false);
    });
  });

  group('RiskLevel 라벨', () {
    test('각 단계 라벨 확인', () {
      expect(RiskLevel.low.label,      '낮음');
      expect(RiskLevel.normal.label,   '보통');
      expect(RiskLevel.warning.label,  '주의');
      expect(RiskLevel.danger.label,   '위험');
      expect(RiskLevel.critical.label, '매우위험');
      expect(RiskLevel.unknown.label,  '-');
    });
  });
}
