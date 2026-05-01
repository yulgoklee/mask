import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/constants/dust_standards.dart';
import 'package:mask_alert/core/engine/threshold_engine.dart';
import 'package:mask_alert/core/utils/dust_calculator.dart';
import 'package:mask_alert/core/utils/persona_generator.dart';
import 'package:mask_alert/data/models/user_profile.dart';

// ── 헬퍼 ─────────────────────────────────────────────────

const _engine = ThresholdEngine();

double _multiplierFor(UserProfile profile) {
  final tFinal = _engine.computeTFinal(profile);
  return (35.0 / tFinal).clamp(1.0, 3.0);
}

UserProfile _profile({
  int respiratoryStatus = 0,
  bool isPregnant = false,
  int outdoorMinutes = 0,
  int sensitivityLevel = 0,
  bool recentSkinTreatment = false,
}) =>
    UserProfile(
      nickname: '', birthYear: 1990, gender: 'female',
      respiratoryStatus:   respiratoryStatus,
      sensitivityLevel:    sensitivityLevel,
      isPregnant:          isPregnant,
      recentSkinTreatment: recentSkinTreatment,
      outdoorMinutes:      outdoorMinutes,
      activityTags: [], discomfortLevel: 1,
    );

// care_providers.dart의 순수 함수들을 직접 재현해 검증
// (Riverpod 의존으로 Provider 자체 단위 테스트 분리 불가)

String _resolveRiskLevel(double pm25, double tFinal) {
  final ratio = tFinal > 0 ? pm25 / tFinal : 0.0;
  if (ratio < 0.5) return 'low';
  if (ratio < 1.0) return 'normal';
  if (ratio < 1.5) return 'warning';
  if (ratio < 2.0) return 'danger';
  return 'critical';
}

String _defaultSubCopy(RiskLevel s) => switch (s) {
  RiskLevel.low      => '편하게 외출하셔도 돼요.',
  RiskLevel.normal   => '장시간 야외라면 마스크를 챙기세요.',
  RiskLevel.warning  => '외출 시 KF80 이상 권장이에요.',
  RiskLevel.danger   => 'KF94 마스크를 착용하세요.',
  RiskLevel.critical => '가능하면 실내에서 지내세요.',
  RiskLevel.unknown  => '',
};

String _reasonToCopy(ReasonItem reason, RiskLevel status) {
  final isHighRisk = status == RiskLevel.danger || status == RiskLevel.critical;
  return switch (reason.title) {
    '천식'                => isHighRisk
        ? '천식이 있으시니 KF94를 권해요.'
        : '천식이 있으시니 마스크를 꼭 챙기세요.',
    '비염'                => '비염이 있으시니 마스크가 도움돼요.',
    '비염과 천식'          => '호흡기 보호를 위해 KF94를 권해요.',
    '하루 3시간 이상 야외' => '바깥 시간이 많은 날엔 더 신경써요.',
    '하루 1~3시간 야외'   => '외출 중엔 마스크를 챙기세요.',
    '매우 예민한 체질'    => '예민한 체질이라 더 조심해요.',
    '조금 예민한 체질'    => '평소보다 조심하시는 게 좋아요.',
    '임신 중이세요'        => '태아 건강을 위해 KF94를 권해요.',
    '피부 시술 회복 중'   => '회복 중이니 외출 시 KF94를 권해요.',
    _                     => _defaultSubCopy(status),
  };
}

String _thresholdLabel(int dominantValue, double dominantTFinal) {
  final diff = dominantValue - dominantTFinal.round();
  if (diff < 0)  return '기준 이하';
  if (diff == 0) return '기준 도달';
  return '+${diff}µg 초과';
}

// ── 테스트 ────────────────────────────────────────────────

void main() {
  // ── 1. sensitivity_multiplier ─────────────────────────
  group('sensitivity_multiplier = 35 / tFinal (§2.6)', () {
    // sensitivityLevel=0 기준: W_sensitivity=0, W_lifestyle=0 (outdoorMinutes=0 default)

    test('일반인 (T_final=35.0) → multiplier=1.0', () {
      expect(_multiplierFor(_profile()), closeTo(1.0, 0.001));
    });

    test('비염 (T_final=29.75) → multiplier≈1.176', () {
      // W_health=rhinitis(0.15) → tFinal=35*(1-0.15)=29.75
      expect(_multiplierFor(_profile(respiratoryStatus: 1)),
          closeTo(35.0 / 29.75, 0.001));
    });

    test('천식 (T_final=28.0) → multiplier=1.25', () {
      // W_health=asthma(0.20) → tFinal=35*(1-0.20)=28.0
      expect(_multiplierFor(_profile(respiratoryStatus: 2)),
          closeTo(35.0 / 28.0, 0.001));
    });

    test('임신 (T_final=28.0) → multiplier=1.25', () {
      // W_health=pregnancy(0.20, female only) → tFinal=28.0 — 천식과 동일, 의도된 설계
      expect(_multiplierFor(_profile(isPregnant: true)),
          closeTo(35.0 / 28.0, 0.001));
    });

    test('T_final=15 (하한) → multiplier≈2.33, clamp 미적용', () {
      const tFinal = 15.0;
      final m = (35.0 / tFinal).clamp(1.0, 3.0);
      expect(m, closeTo(35.0 / 15.0, 0.001));
      expect(m, lessThanOrEqualTo(3.0));
    });

    test('T_final=10 → clamp 상한 3.0 적용', () {
      final m = (35.0 / 10.0).clamp(1.0, 3.0);
      expect(m, closeTo(3.0, 0.001));
    });

    test('일반인 multiplier ≥ 1.0 (clamp 하한 보장)', () {
      expect(_multiplierFor(_profile()), greaterThanOrEqualTo(1.0));
    });
  });

  // ── 2. RiskLevel fallback 계산 ─────────────────────────
  group('_resolveRiskLevel fallback (§2.4)', () {
    const tFinal = 35.0;
    test('pm25=17 → low (ratio<0.5)',    () => expect(_resolveRiskLevel(17, tFinal), 'low'));
    test('pm25=25 → normal (ratio<1.0)', () => expect(_resolveRiskLevel(25, tFinal), 'normal'));
    test('pm25=40 → warning (ratio<1.5)',() => expect(_resolveRiskLevel(40, tFinal), 'warning'));
    test('pm25=60 → danger (ratio<2.0)', () => expect(_resolveRiskLevel(60, tFinal), 'danger'));
    test('pm25=80 → critical (ratio≥2.0)',()=> expect(_resolveRiskLevel(80, tFinal), 'critical'));
  });

  // ── 3. 카피 매트릭스 5단계 기본 카피 ─────────────────
  group('_defaultSubCopy 5단계 (§3.2)', () {
    test('low     → 편하게 외출하셔도 돼요.',       () => expect(_defaultSubCopy(RiskLevel.low),      '편하게 외출하셔도 돼요.'));
    test('normal  → 장시간 야외라면 마스크를 챙기세요.', () => expect(_defaultSubCopy(RiskLevel.normal),   '장시간 야외라면 마스크를 챙기세요.'));
    test('warning → 외출 시 KF80 이상 권장이에요.',  () => expect(_defaultSubCopy(RiskLevel.warning),  '외출 시 KF80 이상 권장이에요.'));
    test('danger  → KF94 마스크를 착용하세요.',     () => expect(_defaultSubCopy(RiskLevel.danger),   'KF94 마스크를 착용하세요.'));
    test('critical→ 가능하면 실내에서 지내세요.',    () => expect(_defaultSubCopy(RiskLevel.critical), '가능하면 실내에서 지내세요.'));
    test('카피에 \\n 없음 (단문 강제)',             () {
      for (final s in RiskLevel.values) {
        expect(_defaultSubCopy(s).contains('\n'), false,
            reason: 'RiskLevel.$s 카피에 줄바꿈이 있으면 안 됩니다');
      }
    });
  });

  // ── 4. 개인화 카피 _reasonToCopy ─────────────────────
  group('_reasonToCopy 개인화 카피 (§3.2)', () {
    test('천식 + warning → 마스크를 꼭 챙기세요 버전', () {
      const reason = ReasonItem(title: '천식', description: '');
      expect(_reasonToCopy(reason, RiskLevel.warning), '천식이 있으시니 마스크를 꼭 챙기세요.');
    });

    test('천식 + danger → KF94 버전', () {
      const reason = ReasonItem(title: '천식', description: '');
      expect(_reasonToCopy(reason, RiskLevel.danger), '천식이 있으시니 KF94를 권해요.');
    });

    test('비염 → 마스크가 도움돼요', () {
      const reason = ReasonItem(title: '비염', description: '');
      expect(_reasonToCopy(reason, RiskLevel.warning), '비염이 있으시니 마스크가 도움돼요.');
    });

    test('임신 중이세요 → KF94 권해요', () {
      const reason = ReasonItem(title: '임신 중이세요', description: '');
      expect(_reasonToCopy(reason, RiskLevel.danger), '태아 건강을 위해 KF94를 권해요.');
    });

    test('하루 3시간 이상 야외 → 더 신경써요', () {
      const reason = ReasonItem(title: '하루 3시간 이상 야외', description: '');
      expect(_reasonToCopy(reason, RiskLevel.warning), '바깥 시간이 많은 날엔 더 신경써요.');
    });

    test('피부 시술 회복 중 → KF94 권해요', () {
      const reason = ReasonItem(title: '피부 시술 회복 중', description: '');
      expect(_reasonToCopy(reason, RiskLevel.critical), '회복 중이니 외출 시 KF94를 권해요.');
    });

    test('균형 유지형(general) reasons가 비어있어 기본 카피 사용', () {
      final persona = PersonaGenerator.generate(_profile());
      expect(persona.type, PersonaType.general);
      expect(persona.reasons, isEmpty);
    });

    test('천식 프로필 → reasons.first.title == 천식', () {
      final persona = PersonaGenerator.generate(_profile(respiratoryStatus: 2));
      expect(persona.reasons.isNotEmpty, true);
      expect(persona.reasons.first.title, '천식');
    });

    test('개인화 카피에 \\n 없음 (단문 강제)', () {
      const titles = [
        '천식', '비염', '비염과 천식', '하루 3시간 이상 야외',
        '하루 1~3시간 야외', '매우 예민한 체질', '조금 예민한 체질',
        '임신 중이세요', '피부 시술 회복 중',
      ];
      for (final title in titles) {
        final copy = _reasonToCopy(
          ReasonItem(title: title, description: ''),
          RiskLevel.warning,
        );
        expect(copy.contains('\n'), false,
            reason: '"$title" 카피에 줄바꿈이 있으면 안 됩니다');
      }
    });
  });

  // ── 5. 정보 바 부가정보 삼분법 (§3.2 v3) ──────────────
  group('_thresholdLabel 삼분법 (§3.2 v3)', () {
    test('dominantValue < tFinal → 기준 이하', () {
      expect(_thresholdLabel(10, 19.0), '기준 이하');
    });

    test('dominantValue == tFinal (round) → 기준 도달', () {
      expect(_thresholdLabel(19, 19.0), '기준 도달');
    });

    test('dominantValue > tFinal → +Nµg 초과', () {
      expect(_thresholdLabel(30, 19.0), '+11µg 초과');
    });

    test('diff=1 경계 → +1µg 초과', () {
      expect(_thresholdLabel(36, 35.0), '+1µg 초과');
    });
  });

  // ── 6. 정보 바 dominantGrade (DustStandards 위임) ───────
  group('dominantGrade via DustStandards', () {
    test('PM2.5=10 → 좋음', () {
      expect(DustStandards.getPm25Grade(10).label, '좋음');
    });

    test('PM2.5=25 → 보통', () {
      expect(DustStandards.getPm25Grade(25).label, '보통');
    });

    test('PM10=120 → 나쁨', () {
      expect(DustStandards.getPm10Grade(120).label, '나쁨');
    });

    test('PM10=200 → 매우나쁨', () {
      expect(DustStandards.getPm10Grade(200).label, '매우나쁨');
    });
  });
}
