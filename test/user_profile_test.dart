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

  group('sensitivityIndex', () {
    test('아무 가중치 없어도 clamp 최솟값 0.1', () {
      expect(UserProfile.defaultProfile().sensitivityIndex, 0.1);
    });
    test('임신+피부시술+천식 → 임신 W_health=0.35 우선, S ≈ 0.40', () {
      const p = UserProfile(
        nickname: '', birthYear: 1990, gender: 'female',
        respiratoryStatus: 2, sensitivityLevel: 1,
        isPregnant: true, recentSkinTreatment: true,
        outdoorMinutes: 1, activityTags: [], discomfortLevel: 1,
      );
      expect(p.sensitivityIndex, closeTo(0.40, 0.001));
    });
    test('비염(W_health=0.20) + 야외1~3h(0.05) → S ≈ 0.25', () {
      const p = UserProfile(
        nickname: '', birthYear: 1990, gender: 'male',
        respiratoryStatus: 1, sensitivityLevel: 1,
        isPregnant: false, recentSkinTreatment: false,
        outdoorMinutes: 1, activityTags: [], discomfortLevel: 1,
      );
      expect(p.sensitivityIndex, closeTo(0.25, 0.001));
    });
  });

  group('tFinal', () {
    test('기본 프로필(W_lifestyle=0.05) → tFinal ≈ 33.25', () {
      expect(UserProfile.defaultProfile().tFinal, closeTo(33.25, 0.1));
    });
    test('임신+야외3h+(W_health=0.35,W_lifestyle=0.15) → tFinal ≈ 17.5', () {
      const p = UserProfile(
        nickname: '', birthYear: 1990, gender: 'female',
        respiratoryStatus: 2, sensitivityLevel: 2,
        isPregnant: true, recentSkinTreatment: true,
        outdoorMinutes: 2, activityTags: [], discomfortLevel: 0,
      );
      expect(p.tFinal, closeTo(17.5, 0.1));
    });
    test('tFinal = 35*(1-S) 검증', () {
      const p = UserProfile(
        nickname: '', birthYear: 1990, gender: 'male',
        respiratoryStatus: 1, sensitivityLevel: 1,
        isPregnant: false, recentSkinTreatment: false,
        outdoorMinutes: 1, activityTags: [], discomfortLevel: 1,
      );
      expect(p.tFinal, closeTo(35.0 * (1.0 - p.sensitivityIndex), 0.001));
    });
  });

  group('personaLabel', () {
    test('고위험(임신+야외3h+ → S=0.50) → 복합 고위험군', () {
      const p = UserProfile(
        nickname: '', birthYear: 1990, gender: 'female',
        respiratoryStatus: 2, sensitivityLevel: 2,
        isPregnant: true, recentSkinTreatment: false,
        outdoorMinutes: 2, activityTags: [], discomfortLevel: 1,
      );
      expect(p.personaLabel, '복합 고위험군');
    });
    test('기본 → 기본 관리형', () {
      expect(UserProfile.defaultProfile().personaLabel, '기본 관리형');
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
