import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/engine/threshold_config.dart';
import 'package:mask_alert/core/engine/threshold_engine.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/features/profile/profile_persona.dart';

// ── 공통 픽스처 빌더 ──────────────────────────────────────────

/// 기본값: 1990년생(36세), 모든 건강 항목 false, 비흡연, 닉네임 없음
UserProfile _base({
  String nickname = '',
  int birthYear = 1990,
  bool asthma = false,
  bool rhinitis = false,
  bool copd = false,
  bool allergy = false,
  bool hypertension = false,
  bool heartDisease = false,
  bool stroke = false,
  SmokingStatus smokingStatus = SmokingStatus.never,
}) {
  return UserProfile(
    nickname: nickname,
    birthYear: birthYear, // 기본 1990 → 2026년 기준 36세 → wAge = 0
    gender: '',
    asthma: asthma,
    rhinitis: rhinitis,
    copd: copd,
    allergy: allergy,
    hypertension: hypertension,
    heartDisease: heartDisease,
    stroke: stroke,
    smokingStatus: smokingStatus,
  );
}

void main() {
  // ── 페르소나 라벨 ─────────────────────────────────────────────

  group('PersonaData 페르소나 라벨 — 호흡기 민감', () {
    test('asthma=true → wRespiratory > 0 → label "호흡기 민감 그룹"', () {
      final persona = PersonaData.fromProfile(_base(asthma: true));
      expect(persona.label, '호흡기 민감 그룹');
    });

    test('asthma=true → labelDiscovery "호흡기 민감 그룹이에요"', () {
      final persona = PersonaData.fromProfile(_base(asthma: true));
      expect(persona.labelDiscovery, '호흡기 민감 그룹이에요');
    });

    test('rhinitis=true(hasRespiratoryCondition) → label "호흡기 민감 그룹"', () {
      final persona = PersonaData.fromProfile(_base(rhinitis: true));
      expect(persona.label, '호흡기 민감 그룹');
    });
  });

  group('PersonaData 페르소나 라벨 — 심혈관 주의', () {
    test('hypertension=true → wCardiovascular > 0 → label "심혈관 주의 그룹"', () {
      final persona = PersonaData.fromProfile(_base(hypertension: true));
      expect(persona.label, '심혈관 주의 그룹');
    });

    test('hypertension=true → labelDiscovery "심혈관 주의 그룹이에요"', () {
      final persona = PersonaData.fromProfile(_base(hypertension: true));
      expect(persona.labelDiscovery, '심혈관 주의 그룹이에요');
    });
  });

  group('PersonaData 페르소나 라벨 — 흡연 이력', () {
    test('smokingStatus=current → wSmoking > 0 → label "흡연 이력 그룹"', () {
      final persona = PersonaData.fromProfile(
          _base(smokingStatus: SmokingStatus.current));
      expect(persona.label, '흡연 이력 그룹');
    });

    test('smokingStatus=current → labelDiscovery "흡연 이력이 있는 그룹이에요"', () {
      final persona = PersonaData.fromProfile(
          _base(smokingStatus: SmokingStatus.current));
      expect(persona.labelDiscovery, '흡연 이력이 있는 그룹이에요');
    });

    test('smokingStatus=former → wSmoking > 0 → label "흡연 이력 그룹"', () {
      final persona = PersonaData.fromProfile(
          _base(smokingStatus: SmokingStatus.former));
      expect(persona.label, '흡연 이력 그룹');
    });
  });

  group('PersonaData 페르소나 라벨 — 연령 민감', () {
    // 1960년생 → 66세 → 60_to_69 → wAge = 0.06 > 0
    test('66세(wAge > 0), 건강 항목 없음 → label "연령 민감 그룹"', () {
      final profile = _base(birthYear: 1960); // 2026 기준 66세
      final persona = PersonaData.fromProfile(profile);
      expect(persona.label, '연령 민감 그룹');
    });

    test('66세 → labelDiscovery "연령 민감 그룹이에요"', () {
      final profile = _base(birthYear: 1960);
      final persona = PersonaData.fromProfile(profile);
      expect(persona.labelDiscovery, '연령 민감 그룹이에요');
    });
  });

  group('PersonaData 페르소나 라벨 — 일반', () {
    test('모든 항목 0, 36세 → label "일반 그룹"', () {
      final persona = PersonaData.fromProfile(_base());
      expect(persona.label, '일반 그룹');
    });

    test('모든 항목 0, 36세 → labelDiscovery "일반 그룹이에요"', () {
      final persona = PersonaData.fromProfile(_base());
      expect(persona.labelDiscovery, '일반 그룹이에요');
    });
  });

  // ── 닉네임 ───────────────────────────────────────────────────

  group('PersonaData 닉네임', () {
    test('닉네임 빈 문자열 → name == ""', () {
      final persona = PersonaData.fromProfile(_base(nickname: ''));
      expect(persona.name, '');
    });

    test('닉네임 "지수" → name == "지수"', () {
      final persona = PersonaData.fromProfile(_base(nickname: '지수'));
      expect(persona.name, '지수');
    });
  });

  // ── 5축 axes 순서 및 구조 ────────────────────────────────────

  group('PersonaData axes 순서', () {
    late PersonaData persona;
    setUpAll(() {
      persona = PersonaData.fromProfile(_base(asthma: true));
    });

    test('axes 길이 == 4', () {
      expect(persona.axes.length, 4);
    });

    test('axes[0] key == "respiratory"', () {
      expect(persona.axes[0].key, 'respiratory');
    });

    test('axes[1] key == "cardiovascular"', () {
      expect(persona.axes[1].key, 'cardiovascular');
    });

    test('axes[2] key == "smoking"', () {
      expect(persona.axes[2].key, 'smoking');
    });

    test('axes[3] key == "age"', () {
      expect(persona.axes[3].key, 'age');
    });
  });

  // ── age 축 sub ───────────────────────────────────────────────

  group('PersonaData age 축 sub', () {
    test('birthYear=1990 → age 축 sub == "${DateTime.now().year - 1990}세"', () {
      final persona = PersonaData.fromProfile(_base(birthYear: 1990));
      final ageAxis = persona.axes[3];
      final expectedAge = DateTime.now().year - 1990;
      expect(ageAxis.sub, '$expectedAge세');
    });
  });

  // ── sum == breakdown.wTotal ──────────────────────────────────

  group('PersonaData sum', () {
    test('sum == breakdown.wTotal (asthma=true)', () {
      final profile = _base(asthma: true);
      const eng = ThresholdEngine();
      final bd = eng.breakdown(profile);
      final persona = PersonaData.fromProfile(profile);
      expect(persona.sum, closeTo(bd.wTotal, 1e-9));
    });

    test('sum == breakdown.wTotal (일반 그룹)', () {
      final profile = _base();
      const eng = ThresholdEngine();
      final bd = eng.breakdown(profile);
      final persona = PersonaData.fromProfile(profile);
      expect(persona.sum, closeTo(bd.wTotal, 1e-9));
    });

    test('sum == breakdown.wTotal (흡연+심혈관 복합)', () {
      final profile = _base(
        hypertension: true,
        smokingStatus: SmokingStatus.current,
      );
      const eng = ThresholdEngine();
      final bd = eng.breakdown(profile);
      final persona = PersonaData.fromProfile(profile);
      expect(persona.sum, closeTo(bd.wTotal, 1e-9));
    });
  });

  // ── general == ThresholdConfig.defaults.tBase ────────────────

  group('PersonaData general', () {
    test('general == 35.0 (ThresholdConfig.defaults.tBase)', () {
      final persona = PersonaData.fromProfile(_base());
      expect(persona.general, ThresholdConfig.defaults.tBase);
    });
  });

  // ── isActive 검증 ────────────────────────────────────────────

  group('PersonaData axes isActive', () {
    test('asthma=true → respiratory isActive == true', () {
      final persona = PersonaData.fromProfile(_base(asthma: true));
      expect(persona.axes[0].isActive, isTrue);
    });

    test('asthma=false → respiratory isActive == false', () {
      final persona = PersonaData.fromProfile(_base());
      expect(persona.axes[0].isActive, isFalse);
    });

    test('hypertension=true → cardiovascular isActive == true', () {
      final persona = PersonaData.fromProfile(_base(hypertension: true));
      expect(persona.axes[1].isActive, isTrue);
    });

    test('SmokingStatus.current → smoking isActive == true', () {
      final persona =
          PersonaData.fromProfile(_base(smokingStatus: SmokingStatus.current));
      expect(persona.axes[2].isActive, isTrue);
    });

    test('SmokingStatus.never → smoking isActive == false', () {
      final persona = PersonaData.fromProfile(_base());
      expect(persona.axes[2].isActive, isFalse);
    });
  });
}
