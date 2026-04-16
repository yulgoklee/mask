import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/data/models/user_profile.dart';

UserProfile _makeProfile({
  String nickname = '율곡',
  int birthYear = 1990,
  String gender = 'male',
  int respiratoryStatus = 0,
  int sensitivityLevel = 1,
  bool isPregnant = false,
  bool recentSkinTreatment = false,
  int outdoorMinutes = 1,
  List<String> activityTags = const [],
  int discomfortLevel = 0,
}) =>
    UserProfile(
      nickname: nickname,
      birthYear: birthYear,
      gender: gender,
      respiratoryStatus: respiratoryStatus,
      sensitivityLevel: sensitivityLevel,
      isPregnant: isPregnant,
      recentSkinTreatment: recentSkinTreatment,
      outdoorMinutes: outdoorMinutes,
      activityTags: activityTags,
      discomfortLevel: discomfortLevel,
    );

void main() {
  group('UserProfile.toJson / fromJson 왕복', () {
    test('직렬화 후 역직렬화 동일', () {
      final profile = _makeProfile(
        nickname: '건강이',
        birthYear: 1975,
        gender: 'female',
        respiratoryStatus: 2,
        sensitivityLevel: 2,
        isPregnant: true,
        recentSkinTreatment: true,
        outdoorMinutes: 2,
        activityTags: [ActivityTag.commute, ActivityTag.walk],
        discomfortLevel: 1,
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

  group('UserProfile.defaultProfile', () {
    test('기본값 확인', () {
      final p = UserProfile.defaultProfile();
      expect(p.nickname, '');
      expect(p.gender, 'male');
      expect(p.respiratoryStatus, 0);
      expect(p.sensitivityLevel, 1);
      expect(p.isPregnant, false);
      expect(p.activityTags, isEmpty);
    });
  });

  group('UserProfile.copyWith', () {
    test('일부 값만 변경', () {
      final base = UserProfile.defaultProfile();
      final updated = base.copyWith(
        nickname: '새닉네임',
        respiratoryStatus: 2,
      );
      expect(updated.nickname, '새닉네임');
      expect(updated.respiratoryStatus, 2);
      expect(updated.sensitivityLevel, base.sensitivityLevel); // 나머지 유지
    });
  });

  group('sensitivityIndex 계산', () {
    test('아무 항목 없음 → S=0.0 → clamp → 0.1', () {
      final p = _makeProfile();
      // 기본: 30대(취약아님), 호흡기정상, 보통민감, 미임신, 피부시술없음, 1~3시간, 불편안함
      // S=0.0 → clamp(0.1, 0.6) → 0.1
      expect(p.sensitivityIndex, closeTo(0.1, 0.001));
    });

    test('비염(+0.15) → S=0.15', () {
      final p = _makeProfile(respiratoryStatus: 1);
      expect(p.sensitivityIndex, closeTo(0.15, 0.001));
    });

    test('천식(+0.30) + 예민(+0.10) → S=0.40', () {
      final p = _makeProfile(respiratoryStatus: 2, sensitivityLevel: 2);
      expect(p.sensitivityIndex, closeTo(0.40, 0.001));
    });

    test('임신 여성(+0.30) + 비염(+0.15) → S=0.45', () {
      final p = _makeProfile(
          gender: 'female', isPregnant: true, respiratoryStatus: 1);
      expect(p.sensitivityIndex, closeTo(0.45, 0.001));
    });

    test('모든 항목 최대 → clamp → 0.6', () {
      // 고령(+0.1) + 천식(+0.3) + 예민(+0.1) + 임신(+0.3) + 피부(+0.25) + 3시간+(+0.1)
      // = 1.15 → clamp → 0.6
      final p = _makeProfile(
        birthYear: DateTime.now().year - 75, // 75세
        gender: 'female',
        respiratoryStatus: 2,
        sensitivityLevel: 2,
        isPregnant: true,
        recentSkinTreatment: true,
        outdoorMinutes: 2,
      );
      expect(p.sensitivityIndex, closeTo(0.6, 0.001));
    });

    test('매우 답답함(-0.10) 적용', () {
      // 비염(+0.15) + 매우답답(-0.10) = 0.05 → clamp → 0.1
      final p = _makeProfile(respiratoryStatus: 1, discomfortLevel: 2);
      expect(p.sensitivityIndex, closeTo(0.1, 0.001));
    });
  });

  group('tFinal 계산', () {
    test('S=0.1 → T_final=31.5', () {
      final p = _makeProfile(); // S=0.1
      expect(p.tFinal, closeTo(31.5, 0.1));
    });

    test('S=0.6 → T_final=14.0', () {
      final p = _makeProfile(
        birthYear: DateTime.now().year - 75,
        gender: 'female',
        respiratoryStatus: 2,
        sensitivityLevel: 2,
        isPregnant: true,
        recentSkinTreatment: true,
        outdoorMinutes: 2,
      );
      expect(p.tFinal, closeTo(14.0, 0.1));
    });
  });

  group('isVulnerableAge', () {
    test('10세 이하 → 취약', () {
      final p = _makeProfile(birthYear: DateTime.now().year - 8);
      expect(p.isVulnerableAge, true);
    });

    test('70세 이상 → 취약', () {
      final p = _makeProfile(birthYear: DateTime.now().year - 72);
      expect(p.isVulnerableAge, true);
    });

    test('30세 → 취약 아님', () {
      final p = _makeProfile(birthYear: DateTime.now().year - 30);
      expect(p.isVulnerableAge, false);
    });
  });

  group('displayName', () {
    test('닉네임 있을 때 → "율곡님"', () {
      expect(_makeProfile(nickname: '율곡').displayName, '율곡님');
    });

    test('닉네임 빈 문자열 → "님"', () {
      expect(_makeProfile(nickname: '').displayName, '님');
    });
  });

  group('ActivityTag', () {
    test('라벨 확인', () {
      expect(ActivityTag.label(ActivityTag.commute), '출퇴근');
      expect(ActivityTag.label(ActivityTag.walk), '산책');
      expect(ActivityTag.label(ActivityTag.exercise), '야외 운동');
    });
  });
}
