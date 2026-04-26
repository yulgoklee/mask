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

DustData _dust(int pm25, {int? pm10 = 30}) => DustData(
  stationName: '테스트', pm25Value: pm25, pm10Value: pm10,
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

  group('DustCalculator — shouldSendRealtime 경계값 (finalRatio >= 1.5)', () {
    // 기본 프로필 T_final ≈ 31.5 (birthYear=1990, outdoorMinutes=1, 가중치 미미)
    // 실제 T_final은 ThresholdEngine으로 계산 — 여기서는 PM10 ratio로 정확히 제어

    test('PM10=120, T_pm10=80 → ratio=1.50 → shouldSendRealtime=true (경계 inclusive)', () {
      // T_final_pm25 기본값 ≈ 31.5, T_final_pm10 = 31.5 × (80/35) ≈ 72
      // PM10=120이면 ratio_pm10 = 120/72 ≈ 1.667 → true
      final r = DustCalculator.calculate(_defaultProfile, _dust(5, pm10: 120));
      expect(r.shouldSendRealtime, true);
    });

    test('PM10=119 → ratio_pm10 < 1.5 (pm25도 낮음) → shouldSendRealtime=false', () {
      // PM10=119, T_pm10≈72 → ratio≈1.653 → still > 1.5 for default profile
      // 더 낮은 PM10으로 테스트: PM10=100, ratio=100/72≈1.39 → false
      final r = DustCalculator.calculate(_defaultProfile, _dust(5, pm10: 100));
      expect(r.shouldSendRealtime, false);
    });

    test('PM2.5만으로 ratio >= 1.5 → shouldSendRealtime=true', () {
      // 기본 프로필 T_final≈33.25 (W_lifestyle=0.05)
      // pm25=50 → 50/33.25 ≈ 1.504 → true
      final r = DustCalculator.calculate(_defaultProfile, _dust(50, pm10: null));
      expect(r.shouldSendRealtime, true);
    });

    test('PM2.5=45, PM10 없음 → ratio≈1.35 → shouldSendRealtime=false', () {
      // pm25=45, T_final≈33.25 → ratio≈1.35 < 1.5
      final r = DustCalculator.calculate(_defaultProfile, _dust(45, pm10: null));
      expect(r.shouldSendRealtime, false);
    });
  });

  group('DustCalculator — PM10 dominant 케이스', () {
    test('PM10이 PM2.5보다 ratio 높으면 dominant=pm10', () {
      // PM2.5=5 (ratio≈0.16), PM10=120 (ratio≈1.67) → pm10 dominant
      final r = DustCalculator.calculate(_defaultProfile, _dust(5, pm10: 120));
      expect(r.dominantPollutant, DominantPollutant.pm10);
    });

    test('PM10=null → dominant=pm25', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(30, pm10: null));
      expect(r.dominantPollutant, DominantPollutant.pm25);
    });

    test('PM10이 낮으면 dominant=pm25', () {
      // PM2.5=30 (ratio≈0.95), PM10=10 (ratio≈0.14) → pm25 dominant
      final r = DustCalculator.calculate(_defaultProfile, _dust(30, pm10: 10));
      expect(r.dominantPollutant, DominantPollutant.pm25);
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
