import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/utils/persona_generator.dart';
import 'package:mask_alert/data/models/user_profile.dart';

// 테스트용 프로필 생성 헬퍼 — 명시하지 않은 필드는 neutral 기본값
UserProfile _p({
  int respiratory = 0,
  int outdoor = 0,
  int sensitivity = 0,
  bool pregnant = false,
  bool skinTreatment = false,
}) =>
    UserProfile(
      nickname: 'test',
      birthYear: 1990,
      gender: 'male',
      respiratoryStatus: respiratory,
      sensitivityLevel: sensitivity,
      isPregnant: pregnant,
      recentSkinTreatment: skinTreatment,
      skinTreatmentDate: skinTreatment ? null : null,
      outdoorMinutes: outdoor,
      activityTags: const [],
      discomfortLevel: 0,
    );

void main() {
  // ── a. 6개 페르소나 분류 ───────────────────────────────────

  group('페르소나 분류', () {
    test('세심한 케어형 — 천식 + 야외 활동(w2>=0.1)', () {
      final p = PersonaGenerator.generate(_p(respiratory: 2, outdoor: 2));
      expect(p.type, PersonaType.compound);
      expect(p.name, '세심한 케어형');
    });

    test('세심한 케어형 — 비염 + 체감(w3>=0.1)', () {
      final p = PersonaGenerator.generate(_p(respiratory: 1, sensitivity: 1));
      expect(p.type, PersonaType.compound);
    });

    test('섬세한 체질형 — 천식만 (야외·체감 없음)', () {
      final p = PersonaGenerator.generate(_p(respiratory: 2));
      expect(p.type, PersonaType.medicalCare);
      expect(p.name, '섬세한 체질형');
    });

    test('섬세한 체질형 — 비염만', () {
      final p = PersonaGenerator.generate(_p(respiratory: 1));
      expect(p.type, PersonaType.medicalCare);
    });

    test('활발한 감지형 — 야외3h+ + 체감(sensitivityLevel>=1)', () {
      final p = PersonaGenerator.generate(_p(outdoor: 2, sensitivity: 1));
      expect(p.type, PersonaType.activeAndSensitive);
      expect(p.name, '활발한 감지형');
    });

    test('야외 라이프형 — 야외3h+ + 체감 없음', () {
      final p = PersonaGenerator.generate(_p(outdoor: 2));
      expect(p.type, PersonaType.activeOutdoor);
      expect(p.name, '야외 라이프형');
    });

    test('예민한 감지형 — 체감 매우예민(sensitivityLevel=2)만', () {
      final p = PersonaGenerator.generate(_p(sensitivity: 2));
      expect(p.type, PersonaType.sensitiveFeel);
      expect(p.name, '예민한 감지형');
    });

    test('균형 유지형 — 모든 조건 0', () {
      final p = PersonaGenerator.generate(_p());
      expect(p.type, PersonaType.general);
      expect(p.name, '균형 유지형');
    });

    test('균형 유지형 — sensitivityLevel=1 단독 (임계값 미달)', () {
      // sensitivityLevel=1 단독이면 w3=0.1 < 0.2 → general
      final p = PersonaGenerator.generate(_p(sensitivity: 1));
      expect(p.type, PersonaType.general);
    });

    test('균형 유지형 — outdoorMinutes=1 단독 (임계값 미달)', () {
      // outdoorMinutes=1 단독이면 w2=0.1 < 0.2 → general
      final p = PersonaGenerator.generate(_p(outdoor: 1));
      expect(p.type, PersonaType.general);
    });
  });

  // ── b. reasons 개수 ────────────────────────────────────────

  group('reasons 개수', () {
    test('천식+야외3h+매우예민 → 세심한 케어형 + reasons 3개', () {
      final p = PersonaGenerator.generate(
          _p(respiratory: 2, outdoor: 2, sensitivity: 2));
      expect(p.type, PersonaType.compound);
      expect(p.reasons.length, 3);
    });

    test('천식만 → 섬세한 체질형 + reasons 1개', () {
      final p = PersonaGenerator.generate(_p(respiratory: 2));
      expect(p.type, PersonaType.medicalCare);
      expect(p.reasons.length, 1);
    });

    test('야외3h+매우예민 → 활발한 감지형 + reasons 2개', () {
      final p = PersonaGenerator.generate(_p(outdoor: 2, sensitivity: 2));
      expect(p.type, PersonaType.activeAndSensitive);
      expect(p.reasons.length, 2);
    });

    test('모든 조건 0 → 균형 유지형 + reasons 0개', () {
      final p = PersonaGenerator.generate(_p());
      expect(p.type, PersonaType.general);
      expect(p.reasons.length, 0);
    });

    test('천식+야외3h+매우예민+임신 → reasons 4개', () {
      final p = PersonaGenerator.generate(
          _p(respiratory: 2, outdoor: 2, sensitivity: 2, pregnant: true));
      expect(p.reasons.length, 4);
    });

    test('천식+야외3h+매우예민+임신+시술 → reasons 5개', () {
      final p = PersonaGenerator.generate(_p(
          respiratory: 2,
          outdoor: 2,
          sensitivity: 2,
          pregnant: true,
          skinTreatment: true));
      expect(p.reasons.length, 5);
    });
  });

  // ── c. general은 항상 빈 리스트 ───────────────────────────

  group('general reasons 빈 리스트', () {
    test('모든 조건 0 → reasons 빈 리스트', () {
      final p = PersonaGenerator.generate(_p());
      expect(p.reasons, isEmpty);
    });

    test('sensitivityLevel=1 단독 (general) → reasons 빈 리스트', () {
      final p = PersonaGenerator.generate(_p(sensitivity: 1));
      expect(p.type, PersonaType.general);
      expect(p.reasons, isEmpty);
    });
  });

  // ── d. reasons 순서 (호흡기→야외→체감→임신→시술) ──────────

  group('reasons 순서', () {
    test('천식+야외3h+매우예민 → [호흡기, 야외, 체감] 순서', () {
      final p = PersonaGenerator.generate(
          _p(respiratory: 2, outdoor: 2, sensitivity: 2));
      expect(p.reasons[0].title, '천식');
      expect(p.reasons[1].title, '하루 3시간 이상 야외');
      expect(p.reasons[2].title, '매우 예민한 체질');
    });

    test('천식+야외3h+매우예민+임신+시술 → [호흡기,야외,체감,임신,시술] 순서', () {
      final p = PersonaGenerator.generate(_p(
          respiratory: 2,
          outdoor: 2,
          sensitivity: 2,
          pregnant: true,
          skinTreatment: true));
      expect(p.reasons[0].title, '천식');
      expect(p.reasons[1].title, '하루 3시간 이상 야외');
      expect(p.reasons[2].title, '매우 예민한 체질');
      expect(p.reasons[3].title, '임신 중이세요');
      expect(p.reasons[4].title, '피부 시술 회복 중');
    });
  });

  // ── e. 문구 §6.4 정확 일치 ────────────────────────────────

  group('§6.4 문구 정확 일치', () {
    // 호흡기
    test('비염 title·description', () {
      final p = PersonaGenerator.generate(_p(respiratory: 1));
      final r = p.reasons.first;
      expect(r.title, '비염');
      expect(r.description, '코 점막이 먼지에 민감해요. 그래서 기준을 낮췄어요.');
    });

    test('천식 title·description', () {
      final p = PersonaGenerator.generate(_p(respiratory: 2));
      final r = p.reasons.first;
      expect(r.title, '천식');
      expect(r.description, '적은 농도에도 기관지가 반응해요. 그래서 기준을 낮췄어요.');
    });

    test('비염과 천식 title·description (respiratoryStatus=3)', () {
      final p = PersonaGenerator.generate(_p(respiratory: 3));
      final r = p.reasons.first;
      expect(r.title, '비염과 천식');
      expect(r.description, '코와 기관지가 먼지에 이중으로 반응해요. 그래서 기준을 낮췄어요.');
    });

    // 야외
    test('하루 1~3시간 야외 title·description', () {
      // outdoor=1 + respiratory=1 → compound (0이 아닌 조건에 포함)
      final p = PersonaGenerator.generate(_p(respiratory: 1, outdoor: 1));
      final r = p.reasons.firstWhere((r) => r.title.contains('1~3시간'));
      expect(r.title, '하루 1~3시간 야외');
      expect(r.description, '노출 시간이 있는 편이라 평균보다 조금 더 영향을 받아요.');
    });

    test('하루 3시간 이상 야외 title·description', () {
      final p = PersonaGenerator.generate(_p(outdoor: 2, sensitivity: 2));
      final r = p.reasons.firstWhere((r) => r.title.contains('3시간 이상'));
      expect(r.title, '하루 3시간 이상 야외');
      expect(r.description, '노출 시간이 길어서 같은 농도여도 영향이 커요.');
    });

    // 체감
    test('조금 예민한 체질 title·description', () {
      // sensitivity=1 + outdoor=2 → activeAndSensitive
      final p = PersonaGenerator.generate(_p(outdoor: 2, sensitivity: 1));
      final r = p.reasons.firstWhere((r) => r.title.contains('조금'));
      expect(r.title, '조금 예민한 체질');
      expect(r.description, '평소 미세먼지 변화를 느끼는 편이잖아요. 그 감각을 반영했어요.');
    });

    test('매우 예민한 체질 title·description', () {
      final p = PersonaGenerator.generate(_p(outdoor: 2, sensitivity: 2));
      final r = p.reasons.firstWhere((r) => r.title.contains('매우'));
      expect(r.title, '매우 예민한 체질');
      expect(r.description, '수치가 낮아도 몸이 먼저 알아채잖아요. 그 감각을 반영했어요.');
    });

    // Tier 2
    test('임신 중이세요 title·description', () {
      final p = PersonaGenerator.generate(
          _p(respiratory: 2, outdoor: 2, sensitivity: 2, pregnant: true));
      final r = p.reasons.firstWhere((r) => r.title == '임신 중이세요');
      expect(r.title, '임신 중이세요');
      expect(r.description, '태아에게 미세먼지가 닿지 않도록 더 조심스럽게 설정했어요.');
    });

    test('피부 시술 회복 중 title·description', () {
      final p = PersonaGenerator.generate(
          _p(respiratory: 2, outdoor: 2, sensitivity: 2, skinTreatment: true));
      final r = p.reasons.firstWhere((r) => r.title == '피부 시술 회복 중');
      expect(r.title, '피부 시술 회복 중');
      expect(r.description, '자극을 피해야 하는 시기잖아요. 그래서 기준을 더 낮췄어요.');
    });
  });

  // ── enum 기반 이모지 매핑 확인 ─────────────────────────────

  group('enum 기반 이모지 매핑', () {
    test('각 PersonaType에 고유 이모지 할당', () {
      final emojis = PersonaType.values.map((type) {
        late UserProfile profile;
        switch (type) {
          case PersonaType.compound:
            profile = _p(respiratory: 2, outdoor: 2);
          case PersonaType.medicalCare:
            profile = _p(respiratory: 2);
          case PersonaType.activeAndSensitive:
            profile = _p(outdoor: 2, sensitivity: 1);
          case PersonaType.activeOutdoor:
            profile = _p(outdoor: 2);
          case PersonaType.sensitiveFeel:
            profile = _p(sensitivity: 2);
          case PersonaType.general:
            profile = _p();
        }
        return PersonaGenerator.generate(profile).emoji;
      }).toList();

      // 이모지 6개가 전부 다름
      expect(emojis.toSet().length, 6);
    });

    test('compound → ⚡ 이모지', () {
      final p = PersonaGenerator.generate(_p(respiratory: 2, outdoor: 2));
      expect(p.emoji, '⚡');
    });

    test('general → 🌿 이모지', () {
      final p = PersonaGenerator.generate(_p());
      expect(p.emoji, '🌿');
    });
  });

  // ── 서브타이틀 §6.2 확인 ─────────────────────────────────

  group('§6.2 서브타이틀', () {
    test('세심한 케어형 서브타이틀', () {
      final p = PersonaGenerator.generate(_p(respiratory: 2, outdoor: 2));
      expect(p.subtitle, '건강과 일상 둘 다 챙기는 당신에게 맞춘 기준이에요');
    });

    test('섬세한 체질형 서브타이틀', () {
      final p = PersonaGenerator.generate(_p(respiratory: 2));
      expect(p.subtitle, '증상이 없어도 먼저 반응하는 체질을 고려했어요');
    });

    test('활발한 감지형 서브타이틀', () {
      final p = PersonaGenerator.generate(_p(outdoor: 2, sensitivity: 1));
      expect(p.subtitle, '많이 움직이고 빨리 감지하는 당신을 위한 기준이에요');
    });

    test('야외 라이프형 서브타이틀', () {
      final p = PersonaGenerator.generate(_p(outdoor: 2));
      expect(p.subtitle, '바깥 시간이 많은 당신에게 맞는 기준이에요');
    });

    test('예민한 감지형 서브타이틀', () {
      final p = PersonaGenerator.generate(_p(sensitivity: 2));
      expect(p.subtitle, '공기 변화를 빨리 알아차리는 감각을 반영했어요');
    });

    test('균형 유지형 서브타이틀', () {
      final p = PersonaGenerator.generate(_p());
      expect(p.subtitle, '지금 상태라면 기본 기준으로 충분해요');
    });
  });
}
