import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/engine/threshold_engine.dart';
import 'package:mask_alert/data/models/user_profile.dart';

const _engine = ThresholdEngine();

/// 테스트용 프로필 헬퍼
///
/// birthYear 기본값 1990 (2026 기준 36세 → W_age = 0.0)
UserProfile _profile({
  int birthYear        = 1990,
  String gender        = 'female',
  bool asthma          = false,
  bool rhinitis        = false,
  bool copd            = false,
  bool allergy         = false,
  bool hypertension    = false,
  bool heartDisease    = false,
  bool stroke          = false,
  SmokingStatus smokingStatus = SmokingStatus.never,
}) =>
    UserProfile(
      nickname:      '',
      birthYear:     birthYear,
      gender:        gender,
      asthma:        asthma,
      rhinitis:      rhinitis,
      copd:          copd,
      allergy:       allergy,
      hypertension:  hypertension,
      heartDisease:  heartDisease,
      stroke:        stroke,
      smokingStatus: smokingStatus,
      activityTags:  [],
      discomfortLevel: 1,
    );

void main() {
  // ── computeWAge ────────────────────────────────────────────────

  group('computeWAge — 연령 구간', () {
    test('11세 → under_12 → 0.10', () {
      final p = _profile(birthYear: DateTime.now().year - 11);
      expect(_engine.computeWAge(p), closeTo(0.10, 0.001));
    });

    test('12세 → 12_to_49 경계 → 0.0', () {
      final p = _profile(birthYear: DateTime.now().year - 12);
      expect(_engine.computeWAge(p), closeTo(0.0, 0.001));
    });

    test('49세 → 12_to_49 경계 → 0.0', () {
      final p = _profile(birthYear: DateTime.now().year - 49);
      expect(_engine.computeWAge(p), closeTo(0.0, 0.001));
    });

    test('50세 → 50_to_59 경계 → 0.00 (가중치 없음)', () {
      final p = _profile(birthYear: DateTime.now().year - 50);
      expect(_engine.computeWAge(p), closeTo(0.00, 0.001));
    });

    test('60세 → 60_to_69 경계 → 0.06', () {
      final p = _profile(birthYear: DateTime.now().year - 60);
      expect(_engine.computeWAge(p), closeTo(0.06, 0.001));
    });

    test('70세 → 70_to_79 경계 → 0.10', () {
      final p = _profile(birthYear: DateTime.now().year - 70);
      expect(_engine.computeWAge(p), closeTo(0.10, 0.001));
    });

    test('80세 → 80_plus 경계 → 0.13', () {
      final p = _profile(birthYear: DateTime.now().year - 80);
      expect(_engine.computeWAge(p), closeTo(0.13, 0.001));
    });

    test('100세 → 80_plus → 0.13', () {
      final p = _profile(birthYear: DateTime.now().year - 100);
      expect(_engine.computeWAge(p), closeTo(0.13, 0.001));
    });
  });

  // ── computeWHealth — 호흡기 카테고리 ──────────────────────────

  group('computeWHealth — 호흡기 카테고리 (상한 0.30)', () {
    test('건강함 → 0.0', () {
      expect(_engine.computeWHealth(_profile()), closeTo(0.0, 0.001));
    });

    test('비염만 → 0.15', () {
      expect(_engine.computeWHealth(_profile(rhinitis: true)), closeTo(0.15, 0.001));
    });

    test('천식만 → 0.20', () {
      expect(_engine.computeWHealth(_profile(asthma: true)), closeTo(0.20, 0.001));
    });

    test('COPD만 → 0.25', () {
      expect(_engine.computeWHealth(_profile(copd: true)), closeTo(0.25, 0.001));
    });

    test('알레르기만 → 0.15', () {
      expect(_engine.computeWHealth(_profile(allergy: true)), closeTo(0.15, 0.001));
    });

    test('비염+천식 합산 → 0.35 이지만 상한 0.30 적용', () {
      expect(_engine.computeWHealth(_profile(rhinitis: true, asthma: true)),
          closeTo(0.30, 0.001));
    });

    test('COPD+천식 합산 → 0.45 이지만 상한 0.30 적용', () {
      expect(_engine.computeWHealth(_profile(copd: true, asthma: true)),
          closeTo(0.30, 0.001));
    });
  });

  // ── computeWHealth — 심혈관 카테고리 ──────────────────────────

  group('computeWHealth — 심혈관 카테고리 (상한 0.25)', () {
    test('고혈압만 → 0.15', () {
      expect(_engine.computeWHealth(_profile(hypertension: true)), closeTo(0.15, 0.001));
    });

    test('심장질환만 → 0.20', () {
      expect(_engine.computeWHealth(_profile(heartDisease: true)), closeTo(0.20, 0.001));
    });

    test('뇌졸중만 → 0.15', () {
      expect(_engine.computeWHealth(_profile(stroke: true)), closeTo(0.15, 0.001));
    });

    test('고혈압+심장+뇌졸중 합산 → 0.50 이지만 상한 0.25 적용', () {
      expect(_engine.computeWHealth(_profile(hypertension: true, heartDisease: true, stroke: true)),
          closeTo(0.25, 0.001));
    });
  });

  // ── computeWHealth — 흡연 ─────────────────────────────────────

  group('computeWHealth — 흡연 이력', () {
    test('비흡연 → 0.0', () {
      expect(_engine.computeWHealth(_profile(smokingStatus: SmokingStatus.never)),
          closeTo(0.0, 0.001));
    });

    test('현재 흡연 → 0.20', () {
      expect(_engine.computeWHealth(_profile(smokingStatus: SmokingStatus.current)),
          closeTo(0.20, 0.001));
    });

    test('과거 흡연 → 0.10', () {
      expect(_engine.computeWHealth(_profile(smokingStatus: SmokingStatus.former)),
          closeTo(0.10, 0.001));
    });
  });

  // ── computeTFinal — 케이스 시뮬레이션 ─────────────────────────────

  group('computeTFinal — 케이스 시뮬레이션', () {
    test('일반인 (1990년생, 건강, 비흡연) → T_final=35.0', () {
      final p = _profile(birthYear: 1990);
      expect(p.tFinal, closeTo(35.0, 0.01));
    });

    test('비염 (1990년생) → W_health=0.15 → T_final=29.75', () {
      final p = _profile(birthYear: 1990, rhinitis: true);
      // W_total=0.15, raw=35×0.85=29.75
      expect(p.tFinal, closeTo(29.75, 0.01));
    });

    test('60세+천식 (1964년생) → W_age=0.06+W_resp=0.20 → T_final=26.6', () {
      final p = _profile(birthYear: 1964, asthma: true);
      // W_age=0.06, W_resp=0.20, W_total=0.26, raw=35×0.74=25.9
      expect(p.tFinal, closeTo(25.9, 0.01));
    });

    test('위험 누적 (1964년생/62세, 비염+천식) → cap 0.30 적용 → T_final=20.3', () {
      final p = _profile(birthYear: 1964, rhinitis: true, asthma: true);
      // W_age=0.06, W_resp=min(0.15+0.20, 0.30)=0.30, W_total=0.36
      // raw=35×0.64=22.4
      expect(p.tFinal, closeTo(22.4, 0.01));
    });

    test('극단 누적 (1946년생/80세, 비염+천식+현재흡연) → clamp(15)', () {
      final p = _profile(
        birthYear:     1946,
        gender:        'female',
        rhinitis:      true,
        asthma:        true,
        smokingStatus: SmokingStatus.current,
      );
      // W_age=0.13, W_resp=0.30(cap), W_smoke=0.20 → W_total=0.63
      // raw=35×0.37=12.95 < 15 → clamp
      expect(p.tFinal, closeTo(15.0, 0.01));
    });
  });

  // ── clamp 동작 ────────────────────────────────────────────────

  group('clamp 동작', () {
    test('가중치 없으면 tFinal은 tBase(35)로 반환', () {
      final p = _profile(birthYear: 1990);
      expect(_engine.computeTFinal(p), closeTo(35.0, 0.01));
    });

    test('극단 가중치 시 tFinal은 tFloor(15) 이하로 내려가지 않음', () {
      final p = _profile(
        birthYear:     DateTime.now().year - 85,
        gender:        'female',
        asthma:        true,
        rhinitis:      true,
        copd:          true,
        hypertension:  true,
        heartDisease:  true,
        smokingStatus: SmokingStatus.current,
      );
      expect(_engine.computeTFinal(p), greaterThanOrEqualTo(15.0));
    });
  });

  // ── computeTFinalPm10 ─────────────────────────────────────────

  group('computeTFinalPm10 = computeTFinal × (80/35)', () {
    test('일반인 → tFinal=35 → PM10 임계치=80', () {
      final p = _profile();
      final tPm25 = _engine.computeTFinal(p);
      final tPm10 = _engine.computeTFinalPm10(p);
      expect(tPm10, closeTo(tPm25 * (80.0 / 35.0), 0.001));
    });

    test('임의 프로필에서도 비율 항상 80/35 유지', () {
      final profiles = [
        _profile(rhinitis: true),
        _profile(rhinitis: true, asthma: true),
        _profile(birthYear: 1960, gender: 'female', smokingStatus: SmokingStatus.former),
      ];
      for (final p in profiles) {
        final ratio = _engine.computeTFinalPm10(p) / _engine.computeTFinal(p);
        expect(ratio, closeTo(80.0 / 35.0, 0.001));
      }
    });
  });

  // ── ThresholdBreakdown ────────────────────────────────────────

  group('ThresholdBreakdown — 구조 검증', () {
    test('wTotal = wAge + wHealth (합산)', () {
      final p = _profile(birthYear: 1964, rhinitis: true, asthma: true);
      final bd = _engine.breakdown(p);
      expect(bd.wTotal, closeTo(bd.wAge + bd.wHealth, 0.0001));
    });

    test('tFinalRaw = 35 × (1 - wTotal)', () {
      final p = _profile(rhinitis: true);
      final bd = _engine.breakdown(p);
      final expected = 35.0 * (1.0 - bd.wTotal);
      expect(bd.tFinalRaw, closeTo(expected, 0.0001));
    });

    test('floorApplied = true when tFinalRaw < 15', () {
      final p = _profile(
        birthYear:     DateTime.now().year - 85,
        gender:        'female',
        asthma:        true,
        rhinitis:      true,
        copd:          true,
        hypertension:  true,
        heartDisease:  true,
        smokingStatus: SmokingStatus.current,
      );
      final bd = _engine.breakdown(p);
      expect(bd.floorApplied, isTrue);
      expect(bd.tFinal, closeTo(15.0, 0.001));
    });

    test('floorApplied = false when tFinalRaw >= 15', () {
      final p = _profile();
      final bd = _engine.breakdown(p);
      expect(bd.floorApplied, isFalse);
    });

    test('wHealth getter = wRespiratory + wCardiovascular + wSmoking', () {
      final p = _profile(rhinitis: true, heartDisease: true, smokingStatus: SmokingStatus.former);
      final bd = _engine.breakdown(p);
      expect(bd.wHealth,
          closeTo(bd.wRespiratory + bd.wCardiovascular + bd.wSmoking, 0.0001));
    });
  });
}
