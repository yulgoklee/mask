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

UserProfile _profile({
  AgeGroup age = AgeGroup.thirties,
  bool hasCondition = false,
  ConditionType conditionType = ConditionType.none,
  Severity severity = Severity.mild,
  SensitivityLevel sensitivity = SensitivityLevel.normal,
}) =>
    UserProfile(
      ageGroup: age,
      hasCondition: hasCondition,
      conditionType: conditionType,
      severity: severity,
      activityLevel: ActivityLevel.normal,
      sensitivity: sensitivity,
    );

void main() {
  group('DustCalculator - 기본 프로필 (30대, 건강)', () {
    test('PM2.5=10 → 안전, 마스크 불필요', () {
      final r = DustCalculator.calculate(_profile(), _dust(10));
      expect(r.riskLevel, RiskLevel.low);
      expect(r.maskRequired, false);
      expect(r.maskType, null);
    });

    test('PM2.5=25 → 보통', () {
      final r = DustCalculator.calculate(_profile(), _dust(25));
      expect(r.riskLevel, RiskLevel.normal);
      expect(r.maskRequired, false);
    });

    test('PM2.5=50 → 주의, 마스크 KF80', () {
      final r = DustCalculator.calculate(_profile(), _dust(50));
      expect(r.riskLevel, RiskLevel.warning);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF80');
    });

    test('PM2.5=100 → 매우나쁨, 마스크 KF94', () {
      final r = DustCalculator.calculate(_profile(), _dust(100));
      expect(r.riskLevel, RiskLevel.critical);
      expect(r.maskRequired, true);
      expect(r.maskType, 'KF94');
    });
  });

  group('DustCalculator - 취약 연령 (60대 이상)', () {
    test('PM2.5=25(보통) → 한 단계 상향 → 주의', () {
      final r = DustCalculator.calculate(
        _profile(age: AgeGroup.sixtyPlus),
        _dust(25),
      );
      expect(r.riskLevel, RiskLevel.warning);
      expect(r.maskRequired, true);
    });

    test('PM2.5=10(좋음) → 한 단계 상향 → 보통', () {
      final r = DustCalculator.calculate(
        _profile(age: AgeGroup.sixtyPlus),
        _dust(10),
      );
      expect(r.riskLevel, RiskLevel.normal);
    });
  });

  group('DustCalculator - 기저질환 (호흡기, 경증)', () {
    test('PM2.5=25(보통) → 한 단계 상향 → 주의', () {
      final r = DustCalculator.calculate(
        _profile(hasCondition: true, conditionType: ConditionType.respiratory),
        _dust(25),
      );
      expect(r.riskLevel, RiskLevel.warning);
      expect(r.maskRequired, true);
    });

    test('PM2.5=10(좋음) → 그대로 안전', () {
      final r = DustCalculator.calculate(
        _profile(hasCondition: true, conditionType: ConditionType.respiratory),
        _dust(10),
      );
      expect(r.riskLevel, RiskLevel.low);
    });
  });

  group('DustCalculator - 민감도', () {
    test('민감도 높음: PM2.5=10(좋음) → 한 단계 상향 → 보통', () {
      final r = DustCalculator.calculate(
        _profile(sensitivity: SensitivityLevel.high),
        _dust(10),
      );
      expect(r.riskLevel, RiskLevel.normal);
    });

    test('민감도 낮음: PM2.5=50(나쁨) → 한 단계 하향 → 보통', () {
      final r = DustCalculator.calculate(
        _profile(sensitivity: SensitivityLevel.low),
        _dust(50),
      );
      expect(r.riskLevel, RiskLevel.normal);
    });
  });

  group('DustCalculator - 실시간 경보', () {
    test('PM2.5=100(매우나쁨) + 기본 프로필 → 실시간 알림 발송', () {
      final r = DustCalculator.calculate(_profile(), _dust(100));
      expect(r.shouldSendRealtime, true);
    });

    test('PM2.5=25(보통) → 실시간 알림 없음', () {
      final r = DustCalculator.calculate(_profile(), _dust(25));
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
      final r = DustCalculator.calculate(_profile(), dust);
      expect(r.riskLevel, RiskLevel.unknown);
      expect(r.maskRequired, false);
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
