import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/constants/dust_standards.dart';
import 'package:mask_alert/core/engine/threshold_engine.dart';
import 'package:mask_alert/core/utils/dust_calculator.dart';
import 'package:mask_alert/data/models/user_profile.dart';

// ── 헬퍼 ─────────────────────────────────────────────────

const _engine = ThresholdEngine();

double _multiplierFor(UserProfile profile) {
  final tFinal = _engine.computeTFinal(profile);
  return (35.0 / tFinal).clamp(1.0, 3.0);
}

UserProfile _profile({
  bool rhinitis = false,
  bool asthma   = false,
}) =>
    UserProfile(
      nickname: '', birthYear: 1990, gender: 'female',
      asthma:       asthma,
      rhinitis:     rhinitis,
      copd:         false,
      allergy:      false,
      hypertension: false,
      heartDisease: false,
      stroke:       false,
      smokingStatus: SmokingStatus.never,
    );

// care_providers.dart의 순수 함수들을 직접 재현해 검증
// (Riverpod 의존으로 Provider 자체 단위 테스트 분리 불가)

String _resolveRiskLevel(double pm25, double tFinal) {
  final ratio = tFinal > 0 ? pm25 / tFinal : 0.0;
  if (ratio < 0.5) return 'low';
  if (ratio < 0.7) return 'normal';
  if (ratio < 1.0) return 'warning';
  if (ratio < 1.5) return 'danger';
  return 'critical';
}

String _defaultSubCopy(RiskLevel s) => switch (s) {
  RiskLevel.low      => '공기가 맑아요.',
  RiskLevel.normal   => '오래 밖에 있을 때만 마스크 챙기세요.',
  RiskLevel.warning  => '외출 시 마스크 챙기세요.',
  RiskLevel.danger   => 'KF80 이상 마스크 권장이에요.',
  RiskLevel.critical => '가능하면 실내에서 지내세요.',
  RiskLevel.unknown  => '',
};

String _thresholdLabel(int dominantValue, double dominantTFinal) {
  final diff = dominantValue - dominantTFinal.round();
  if (diff < 0)  return '기준 이하';
  if (diff == 0) return '기준 도달';
  return '+$diffµg 초과';
}

// ── 테스트 ────────────────────────────────────────────────

void main() {
  // ── 1. sensitivity_multiplier ─────────────────────────
  group('sensitivity_multiplier = 35 / tFinal', () {
    test('일반인 (T_final=35.0) → multiplier=1.0', () {
      expect(_multiplierFor(_profile()), closeTo(1.0, 0.001));
    });

    test('비염 (T_final=29.75) → multiplier≈1.176', () {
      // W_health=rhinitis(0.15) → tFinal=35*(1-0.15)=29.75
      expect(_multiplierFor(_profile(rhinitis: true)),
          closeTo(35.0 / 29.75, 0.001));
    });

    test('천식 (T_final=28.0) → multiplier=1.25', () {
      // W_health=asthma(0.20) → tFinal=35*(1-0.20)=28.0
      expect(_multiplierFor(_profile(asthma: true)),
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
  group('_resolveRiskLevel fallback', () {
    const tFinal = 35.0;
    test('pm25=17 → low (ratio<0.5)',     () => expect(_resolveRiskLevel(17, tFinal), 'low'));
    test('pm25=25 → warning (ratio<1.0)', () => expect(_resolveRiskLevel(25, tFinal), 'warning'));
    test('pm25=40 → danger (ratio<1.5)',  () => expect(_resolveRiskLevel(40, tFinal), 'danger'));
    test('pm25=60 → critical (ratio≥1.5)',() => expect(_resolveRiskLevel(60, tFinal), 'critical'));
    test('pm25=80 → critical (ratio≥1.5)',() => expect(_resolveRiskLevel(80, tFinal), 'critical'));
  });

  // ── 3. 기본 카피 5단계 ─────────────────────────────────
  group('_defaultSubCopy 5단계', () {
    test('low     → 공기가 맑아요.',                      () => expect(_defaultSubCopy(RiskLevel.low),      '공기가 맑아요.'));
    test('normal  → 오래 밖에 있을 때만 마스크 챙기세요.', () => expect(_defaultSubCopy(RiskLevel.normal),   '오래 밖에 있을 때만 마스크 챙기세요.'));
    test('warning → 외출 시 마스크 챙기세요.',             () => expect(_defaultSubCopy(RiskLevel.warning),  '외출 시 마스크 챙기세요.'));
    test('danger  → KF80 이상 마스크 권장이에요.',         () => expect(_defaultSubCopy(RiskLevel.danger),   'KF80 이상 마스크 권장이에요.'));
    test('critical→ 가능하면 실내에서 지내세요.',           () => expect(_defaultSubCopy(RiskLevel.critical), '가능하면 실내에서 지내세요.'));
    test('카피에 \\n 없음 (단문 강제)', () {
      for (final s in RiskLevel.values) {
        expect(_defaultSubCopy(s).contains('\n'), false,
            reason: 'RiskLevel.$s 카피에 줄바꿈이 있으면 안 됩니다');
      }
    });
  });

  // ── 4. 정보 바 부가정보 삼분법 ───────────────────────────
  group('_thresholdLabel 삼분법', () {
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

  // ── 5. 정보 바 dominantGrade (DustStandards 위임) ───────
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
