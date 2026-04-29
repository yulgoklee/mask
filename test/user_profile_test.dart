import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/data/models/user_profile.dart';

void main() {
  group('UserProfile.defaultProfile', () {
    test('기본값 확인', () {
      final p = UserProfile.defaultProfile();
      expect(p.nickname, '');
      expect(p.birthYear, 1990);
      expect(p.gender, '');
      expect(p.respiratoryStatus, 0);
      expect(p.sensitivityLevel, 1);
      expect(p.isPregnant, false);
      expect(p.recentSkinTreatment, false);
      expect(p.outdoorMinutes, 1);
      expect(p.activityTags, isEmpty);
      expect(p.discomfortLevel, 1);
    });
  });

  group('UserProfile.toJson / fromJson 왕복', () {
    test('직렬화 후 역직렬화 동일', () {
      const profile = UserProfile(
        nickname: '지수',
        birthYear: 1988,
        gender: 'female',
        respiratoryStatus: 2,
        sensitivityLevel: 2,
        isPregnant: true,
        recentSkinTreatment: false,
        outdoorMinutes: 2,
        activityTags: [ActivityTag.commute, ActivityTag.exercise],
        discomfortLevel: 0,
      );
      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);
      expect(restored.nickname, profile.nickname);
      expect(restored.birthYear, profile.birthYear);
      expect(restored.gender, profile.gender);
      expect(restored.respiratoryStatus, profile.respiratoryStatus);
      expect(restored.sensitivityLevel, profile.sensitivityLevel);
      expect(restored.isPregnant, profile.isPregnant);
      expect(restored.recentSkinTreatment, profile.recentSkinTreatment);
      expect(restored.outdoorMinutes, profile.outdoorMinutes);
      expect(restored.activityTags, profile.activityTags);
      expect(restored.discomfortLevel, profile.discomfortLevel);
    });
  });

  group('UserProfile.copyWith', () {
    test('일부 값만 변경', () {
      final base = UserProfile.defaultProfile();
      final updated = base.copyWith(nickname: '지수', respiratoryStatus: 2);
      expect(updated.nickname, '지수');
      expect(updated.respiratoryStatus, 2);
      expect(updated.sensitivityLevel, base.sensitivityLevel);
    });
  });

  group('displayName', () {
    test('닉네임 있으면 "이름님"', () {
      const p = UserProfile(
        nickname: '지수', birthYear: 1990, gender: 'male',
        respiratoryStatus: 0, sensitivityLevel: 1,
        isPregnant: false, recentSkinTreatment: false,
        outdoorMinutes: 1, activityTags: [], discomfortLevel: 1,
      );
      expect(p.displayName, '지수님');
    });
    test('닉네임 없으면 빈 문자열', () {
      expect(UserProfile.defaultProfile().displayName, '');
    });
  });

  group('isVulnerableAge', () {
    test('2015년생 → 취약', () {
      const p = UserProfile(
        nickname: '', birthYear: 2015, gender: 'male',
        respiratoryStatus: 0, sensitivityLevel: 1,
        isPregnant: false, recentSkinTreatment: false,
        outdoorMinutes: 1, activityTags: [], discomfortLevel: 1,
      );
      expect(p.isVulnerableAge, true);
    });
    test('1950년생 → 취약', () {
      const p = UserProfile(
        nickname: '', birthYear: 1950, gender: 'male',
        respiratoryStatus: 0, sensitivityLevel: 1,
        isPregnant: false, recentSkinTreatment: false,
        outdoorMinutes: 1, activityTags: [], discomfortLevel: 1,
      );
      expect(p.isVulnerableAge, true);
    });
    test('1990년생 → 취약 아님', () {
      expect(UserProfile.defaultProfile().isVulnerableAge, false);
    });
  });

  group('tFinal — ThresholdEngine v2', () {
    test('기본 프로필(level=1, outdoorMinutes=1) → W_total=0.05 → 33.25', () {
      // W_age=0.0, W_health=0.0, W_sensitivity=0.02, W_lifestyle=0.03
      expect(UserProfile.defaultProfile().tFinal, closeTo(33.25, 0.01));
    });

    test('천식+임신+시술+매우예민+3h+(1990년생) → clamp(15)', () {
      // W_age=0.0, W_health=asthma(0.20)+pregnancy(0.20)+skin(0.10)=0.50
      // W_sensitivity=0.05, W_lifestyle=0.07 → W_total=0.62
      // raw=35×0.38=13.3 → clamp → 15.0
      const p = UserProfile(
        nickname: '', birthYear: 1990, gender: 'female',
        respiratoryStatus: 2, sensitivityLevel: 2,
        isPregnant: true, recentSkinTreatment: true,
        outdoorMinutes: 2, activityTags: [], discomfortLevel: 0,
      );
      expect(p.tFinal, closeTo(15.0, 0.01));
    });

    test('비염+조금예민+1~3h(1990년생) → W_total=0.20 → 28.0', () {
      // W_age=0.0, W_health=rhinitis(0.15), W_sensitivity=0.02, W_lifestyle=0.03
      const p = UserProfile(
        nickname: '', birthYear: 1990, gender: 'male',
        respiratoryStatus: 1, sensitivityLevel: 1,
        isPregnant: false, recentSkinTreatment: false,
        outdoorMinutes: 1, activityTags: [], discomfortLevel: 1,
      );
      expect(p.tFinal, closeTo(28.0, 0.001));
    });
  });

  group('ActivityTag 상수', () {
    test('값 확인', () {
      expect(ActivityTag.commute,  'commute');
      expect(ActivityTag.walk,     'walk');
      expect(ActivityTag.exercise, 'exercise');
      expect(ActivityTag.delivery, 'delivery');
      expect(ActivityTag.childcare,'childcare');
    });
  });
}
