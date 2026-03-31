import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/data/models/user_profile.dart';

void main() {
  group('UserProfile.toJson / fromJson 왕복', () {
    test('직렬화 후 역직렬화 동일', () {
      const profile = UserProfile(
        ageGroup: AgeGroup.sixtyPlus,
        hasCondition: true,
        conditionType: ConditionType.respiratory,
        severity: Severity.moderate,
        isDiagnosed: true,
        activityLevel: ActivityLevel.high,
        sensitivity: SensitivityLevel.high,
      );
      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.ageGroup, profile.ageGroup);
      expect(restored.hasCondition, profile.hasCondition);
      expect(restored.conditionType, profile.conditionType);
      expect(restored.severity, profile.severity);
      expect(restored.isDiagnosed, profile.isDiagnosed);
      expect(restored.activityLevel, profile.activityLevel);
      expect(restored.sensitivity, profile.sensitivity);
    });
  });

  group('UserProfile.defaultProfile', () {
    test('기본값 확인', () {
      final p = UserProfile.defaultProfile();
      expect(p.ageGroup, AgeGroup.thirties);
      expect(p.hasCondition, false);
      expect(p.conditionType, ConditionType.none);
      expect(p.sensitivity, SensitivityLevel.normal);
    });
  });

  group('UserProfile.copyWith', () {
    test('일부 값만 변경', () {
      final base = UserProfile.defaultProfile();
      final updated = base.copyWith(
        ageGroup: AgeGroup.sixtyPlus,
        hasCondition: true,
      );
      expect(updated.ageGroup, AgeGroup.sixtyPlus);
      expect(updated.hasCondition, true);
      expect(updated.activityLevel, base.activityLevel); // 나머지는 유지
    });
  });

  group('AgeGroup.isVulnerable', () {
    test('10대/60대 이상 → 취약', () {
      expect(AgeGroup.teens.isVulnerable, true);
      expect(AgeGroup.sixtyPlus.isVulnerable, true);
    });
    test('그 외 → 취약 아님', () {
      expect(AgeGroup.twenties.isVulnerable, false);
      expect(AgeGroup.thirties.isVulnerable, false);
      expect(AgeGroup.forties.isVulnerable, false);
      expect(AgeGroup.fifties.isVulnerable, false);
    });
  });

  group('Enum 라벨', () {
    test('AgeGroup 라벨', () {
      expect(AgeGroup.teens.label, '10대');
      expect(AgeGroup.sixtyPlus.label, '60대 이상');
    });
    test('ConditionType 라벨', () {
      expect(ConditionType.none.label, '없음');
      expect(ConditionType.respiratory.label, '호흡기 질환');
      expect(ConditionType.asthma.label, '천식');
    });
    test('Severity 라벨', () {
      expect(Severity.mild.label, '경증');
      expect(Severity.moderate.label, '중등도');
      expect(Severity.severe.label, '중증');
    });
  });
}
