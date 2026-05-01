import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/data/models/user_profile.dart';

void main() {
  group('UserProfile.defaultProfile', () {
    test('기본값 확인', () {
      final p = UserProfile.defaultProfile();
      expect(p.nickname, '');
      expect(p.birthYear, 1990);
      expect(p.gender, '');
      expect(p.asthma, false);
      expect(p.rhinitis, false);
      expect(p.copd, false);
      expect(p.allergy, false);
      expect(p.hypertension, false);
      expect(p.heartDisease, false);
      expect(p.stroke, false);
      expect(p.isPregnant, false);
      expect(p.smokingStatus, SmokingStatus.never);
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
        asthma: true,
        rhinitis: true,
        copd: false,
        allergy: false,
        hypertension: false,
        heartDisease: false,
        stroke: false,
        isPregnant: true,
        smokingStatus: SmokingStatus.never,
        activityTags: [ActivityTag.commute, ActivityTag.exercise],
        discomfortLevel: 0,
      );
      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);
      expect(restored.nickname, profile.nickname);
      expect(restored.birthYear, profile.birthYear);
      expect(restored.gender, profile.gender);
      expect(restored.asthma, profile.asthma);
      expect(restored.rhinitis, profile.rhinitis);
      expect(restored.isPregnant, profile.isPregnant);
      expect(restored.smokingStatus, profile.smokingStatus);
      expect(restored.activityTags, profile.activityTags);
      expect(restored.discomfortLevel, profile.discomfortLevel);
    });
  });

  group('UserProfile.copyWith', () {
    test('일부 값만 변경', () {
      final base = UserProfile.defaultProfile();
      final updated = base.copyWith(nickname: '지수', asthma: true);
      expect(updated.nickname, '지수');
      expect(updated.asthma, true);
      expect(updated.rhinitis, base.rhinitis);
    });
  });

  group('displayName', () {
    test('닉네임 있으면 "이름님"', () {
      const p = UserProfile(
        nickname: '지수', birthYear: 1990, gender: 'male',
        asthma: false, rhinitis: false, copd: false, allergy: false,
        hypertension: false, heartDisease: false, stroke: false,
        isPregnant: false, smokingStatus: SmokingStatus.never,
        activityTags: [], discomfortLevel: 1,
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
        asthma: false, rhinitis: false, copd: false, allergy: false,
        hypertension: false, heartDisease: false, stroke: false,
        isPregnant: false, smokingStatus: SmokingStatus.never,
        activityTags: [], discomfortLevel: 1,
      );
      expect(p.isVulnerableAge, true);
    });
    test('1950년생 → 취약', () {
      const p = UserProfile(
        nickname: '', birthYear: 1950, gender: 'male',
        asthma: false, rhinitis: false, copd: false, allergy: false,
        hypertension: false, heartDisease: false, stroke: false,
        isPregnant: false, smokingStatus: SmokingStatus.never,
        activityTags: [], discomfortLevel: 1,
      );
      expect(p.isVulnerableAge, true);
    });
    test('1990년생 → 취약 아님', () {
      expect(UserProfile.defaultProfile().isVulnerableAge, false);
    });
  });

  group('tFinal — ThresholdEngine v3', () {
    test('기본 프로필 (건강, 비흡연, 1990년생) → T_final=35.0', () {
      expect(UserProfile.defaultProfile().tFinal, closeTo(35.0, 0.01));
    });

    test('비염 (rhinitis=true) → W_health=0.15 → T_final=29.75', () {
      final p = UserProfile.defaultProfile().copyWith(rhinitis: true);
      expect(p.tFinal, closeTo(29.75, 0.01));
    });

    test('천식+임신 (female, 1990년생) → W_health=0.40 → T_final=21.0', () {
      const p = UserProfile(
        nickname: '', birthYear: 1990, gender: 'female',
        asthma: true, rhinitis: false, copd: false, allergy: false,
        hypertension: false, heartDisease: false, stroke: false,
        isPregnant: true, smokingStatus: SmokingStatus.never,
        activityTags: [], discomfortLevel: 0,
      );
      // W_respiratory=0.20 (asthma), W_special=0.20 (pregnancy) → W_total=0.40
      // raw = 35 × 0.60 = 21.0
      expect(p.tFinal, closeTo(21.0, 0.01));
    });

    test('극단 누적 → clamp(15)', () {
      const p = UserProfile(
        nickname: '', birthYear: 1950, gender: 'female',
        asthma: true, rhinitis: true, copd: true, allergy: true,
        hypertension: true, heartDisease: true, stroke: true,
        isPregnant: true, smokingStatus: SmokingStatus.current,
        activityTags: [], discomfortLevel: 0,
      );
      expect(p.tFinal, closeTo(15.0, 0.01));
    });
  });

  group('hasRespiratoryCondition', () {
    test('아무 조건 없음 → false', () {
      expect(UserProfile.defaultProfile().hasRespiratoryCondition, false);
    });
    test('천식 있음 → true', () {
      expect(UserProfile.defaultProfile().copyWith(asthma: true).hasRespiratoryCondition, true);
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
