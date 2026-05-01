import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/utils/dust_calculator.dart';
import 'package:mask_alert/data/models/dust_data.dart';
import 'package:mask_alert/data/models/user_profile.dart';

// 기본 프로필: birthYear=1990(36세), 기저질환 없음 → T_final=35.0
const _defaultProfile = UserProfile(
  nickname: '', birthYear: 1990, gender: 'male',
  asthma: false, rhinitis: false, copd: false, allergy: false,
  hypertension: false, heartDisease: false, stroke: false,
  isPregnant: false, smokingStatus: SmokingStatus.never,
  activityTags: [], discomfortLevel: 1,
);

// 민감한 프로필: 비염 → W_health=0.15 → T_final=29.75
const _sensitiveProfile = UserProfile(
  nickname: '', birthYear: 1990, gender: 'male',
  asthma: false, rhinitis: true, copd: false, allergy: false,
  hypertension: false, heartDisease: false, stroke: false,
  isPregnant: false, smokingStatus: SmokingStatus.never,
  activityTags: [], discomfortLevel: 1,
);

DustData _dust(int pm25, {int? pm10 = 30}) => DustData(
  stationName: '테스트', pm25Value: pm25, pm10Value: pm10,
  pm25Grade: '보통', pm10Grade: '보통',
  dataTime: DateTime.now(), fetchedAt: DateTime.now(),
);

void main() {
  group('DustCalculator — T_final 비율 기반 위험도 (기본 프로필, T_final=35.0)', () {
    test('PM2.5=10 (ratio<0.5) → low, 마스크 불필요', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(10));
      expect(r.riskLevel, RiskLevel.low);
      expect(r.maskRequired, false);
      expect(r.maskType, isNull);
    });

    test('PM2.5=25 (ratio≈0.79) → warning, 마스크 불필요', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(25));
      expect(r.riskLevel, RiskLevel.warning);
      expect(r.maskRequired, false);
    });

    test('PM2.5=38 (ratio≈1.2) → danger, KF80', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(38));
      expect(r.riskLevel, RiskLevel.danger);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF80');
    });

    test('PM2.5=55 (ratio≈1.75) → critical, KF94, shouldSendRealtime', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(55));
      expect(r.riskLevel, RiskLevel.critical);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF94');
      expect(r.shouldSendRealtime, true);
    });

    test('PM2.5=80 (ratio≥2.0) → critical, shouldSendRealtime', () {
      final r = DustCalculator.calculate(_defaultProfile, _dust(80));
      expect(r.riskLevel, RiskLevel.critical);
      expect(r.maskRequired, true);
      expect(r.shouldSendRealtime, true);
    });
  });

  group('DustCalculator — 새 5단계 임계값 경계값 검증 (0.5/0.7/1.0/1.5)', () {
    // 기본 프로필 T_final≈31.5 사용 — PM10 없음(pm10=null)으로 PM2.5 단독 ratio 제어
    DustData _dustNoPm10(int pm25) => DustData(
      stationName: '테스트', pm25Value: pm25, pm10Value: null,
      pm25Grade: '보통', pm10Grade: '보통',
      dataTime: DateTime.now(), fetchedAt: DateTime.now(),
    );
    // ratio=0.49 (< 0.5) → low
    test('ratio < 0.5 → low (PM2.5=15, ratio≈0.48)', () {
      final r = DustCalculator.calculate(_defaultProfile, _dustNoPm10(15));
      expect(r.riskLevel, RiskLevel.low);
    });
    // ratio=0.65 (0.5~0.7) → normal
    test('ratio 0.5~0.7 → normal (PM2.5=20, ratio≈0.63)', () {
      final r = DustCalculator.calculate(_defaultProfile, _dustNoPm10(20));
      expect(r.riskLevel, RiskLevel.normal);
    });
    // ratio=0.85 (0.7~1.0) → warning
    test('ratio 0.7~1.0 → warning (PM2.5=27, ratio≈0.86)', () {
      final r = DustCalculator.calculate(_defaultProfile, _dustNoPm10(27));
      expect(r.riskLevel, RiskLevel.warning);
      expect(r.maskRequired, false);
    });
    // ratio=1.20 (1.0~1.5) → danger
    test('ratio 1.0~1.5 → danger (PM2.5=38, ratio≈1.21)', () {
      final r = DustCalculator.calculate(_defaultProfile, _dustNoPm10(38));
      expect(r.riskLevel, RiskLevel.danger);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF80');
    });
    // ratio=1.70 (≥ 1.5) → critical
    test('ratio >= 1.5 → critical (PM2.5=54, ratio≈1.71)', () {
      final r = DustCalculator.calculate(_defaultProfile, _dustNoPm10(54));
      expect(r.riskLevel, RiskLevel.critical);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF94');
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
    // 호흡기 프로필 사용 — PM10은 hasRespiratoryCondition=true 일 때만 계산에 반영됨

    test('PM10=120, T_pm10=80 → ratio=1.50 → shouldSendRealtime=true', () {
      // _sensitiveProfile (rhinitis:true) → PM10 계산 반영
      // PM10=120, T_pm10=80.0 → ratio=1.5 → true
      final r = DustCalculator.calculate(_sensitiveProfile, _dust(5, pm10: 120));
      expect(r.shouldSendRealtime, true);
    });

    test('PM10=100, pm25 낮음 → ratio=1.25 < 1.5 → shouldSendRealtime=false', () {
      // PM10=100, T_pm10=80 → ratio=1.25 < 1.5 → false
      final r = DustCalculator.calculate(_defaultProfile, _dust(5, pm10: 100));
      expect(r.shouldSendRealtime, false);
    });

    test('PM2.5만으로 ratio >= 1.5 → shouldSendRealtime=true', () {
      // 기본 프로필 T_final=35.0
      // pm25=53 → 53/35 ≈ 1.514 → true
      final r = DustCalculator.calculate(_defaultProfile, _dust(53, pm10: null));
      expect(r.shouldSendRealtime, true);
    });

    test('PM2.5=45, PM10 없음 → ratio≈1.29 → shouldSendRealtime=false', () {
      // pm25=45, T_final=35.0 → ratio≈1.29 < 1.5
      final r = DustCalculator.calculate(_defaultProfile, _dust(45, pm10: null));
      expect(r.shouldSendRealtime, false);
    });
  });

  group('DustCalculator — PM10 dominant 케이스', () {
    test('PM10이 PM2.5보다 ratio 높으면 dominant=pm10', () {
      // _sensitiveProfile (rhinitis:true) → PM10 계산 반영
      // PM2.5=5 (ratio≈0.17), PM10=120 (ratio≈1.50) → pm10 dominant
      final r = DustCalculator.calculate(_sensitiveProfile, _dust(5, pm10: 120));
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
