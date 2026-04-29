import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/engine/threshold_engine.dart';
import 'package:mask_alert/data/models/user_profile.dart';

const _engine = ThresholdEngine();

/// 테스트용 프로필 헬퍼
///
/// birthYear 기본값 1990 (2026 기준 36세 → W_age = 0.0)
UserProfile _profile({
  int birthYear          = 1990,
  String gender          = 'female',
  int respiratoryStatus  = 0,
  int sensitivityLevel   = 0,
  int outdoorMinutes     = 0,
  bool isPregnant        = false,
  bool recentSkinTreatment = false,
  DateTime? skinTreatmentDate,
}) =>
    UserProfile(
      nickname:            '',
      birthYear:           birthYear,
      gender:              gender,
      respiratoryStatus:   respiratoryStatus,
      sensitivityLevel:    sensitivityLevel,
      isPregnant:          isPregnant,
      recentSkinTreatment: recentSkinTreatment,
      skinTreatmentDate:   skinTreatmentDate,
      outdoorMinutes:      outdoorMinutes,
      activityTags:        [],
      discomfortLevel:     1,
    );

void main() {
  // ── computeWAge ────────────────────────────────────────────────

  group('computeWAge — 연령 6구간', () {
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

    test('50세 → 50_to_59 경계 → 0.03', () {
      final p = _profile(birthYear: DateTime.now().year - 50);
      expect(_engine.computeWAge(p), closeTo(0.03, 0.001));
    });

    test('59세 → 50_to_59 경계 → 0.03', () {
      final p = _profile(birthYear: DateTime.now().year - 59);
      expect(_engine.computeWAge(p), closeTo(0.03, 0.001));
    });

    test('60세 → 60_to_69 경계 → 0.06', () {
      final p = _profile(birthYear: DateTime.now().year - 60);
      expect(_engine.computeWAge(p), closeTo(0.06, 0.001));
    });

    test('69세 → 60_to_69 경계 → 0.06', () {
      final p = _profile(birthYear: DateTime.now().year - 69);
      expect(_engine.computeWAge(p), closeTo(0.06, 0.001));
    });

    test('70세 → 70_to_79 경계 → 0.10', () {
      final p = _profile(birthYear: DateTime.now().year - 70);
      expect(_engine.computeWAge(p), closeTo(0.10, 0.001));
    });

    test('79세 → 70_to_79 경계 → 0.10', () {
      final p = _profile(birthYear: DateTime.now().year - 79);
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

  // ── computeWSensitivity ────────────────────────────────────────

  group('computeWSensitivity — 민감도 3단계', () {
    test('level 0 무던 → 0.0', () {
      expect(_engine.computeWSensitivity(_profile(sensitivityLevel: 0)),
          closeTo(0.0, 0.001));
    });

    test('level 1 조금 예민 → 0.02', () {
      expect(_engine.computeWSensitivity(_profile(sensitivityLevel: 1)),
          closeTo(0.02, 0.001));
    });

    test('level 2 매우 예민 → 0.05', () {
      expect(_engine.computeWSensitivity(_profile(sensitivityLevel: 2)),
          closeTo(0.05, 0.001));
    });
  });

  // ── computeWHealth (합산) ────────────────────────────────────────

  group('computeWHealth — 합산 방식', () {
    test('건강함 → 0.0', () {
      expect(_engine.computeWHealth(_profile()), closeTo(0.0, 0.001));
    });

    test('비염만 (respiratoryStatus=1) → 0.15', () {
      expect(_engine.computeWHealth(_profile(respiratoryStatus: 1)),
          closeTo(0.15, 0.001));
    });

    test('천식만 (respiratoryStatus=2) → 0.20', () {
      expect(_engine.computeWHealth(_profile(respiratoryStatus: 2)),
          closeTo(0.20, 0.001));
    });

    test('비염+천식 (respiratoryStatus=3) → 0.35 (합산)', () {
      expect(_engine.computeWHealth(_profile(respiratoryStatus: 3)),
          closeTo(0.35, 0.001));
    });

    test('임신 (여성) → 0.20', () {
      final p = _profile(gender: 'female', isPregnant: true);
      expect(_engine.computeWHealth(p), closeTo(0.20, 0.001));
    });

    test('임신 (gender 미선택/empty) → 0.20', () {
      final p = _profile(gender: '', isPregnant: true);
      expect(_engine.computeWHealth(p), closeTo(0.20, 0.001));
    });

    test('임신 (남성) → 0.0 (gender 가드)', () {
      final p = _profile(gender: 'male', isPregnant: true);
      expect(_engine.computeWHealth(p), closeTo(0.0, 0.001));
    });

    test('피부 시술 (날짜 없음) → 0.10', () {
      final p = _profile(recentSkinTreatment: true);
      expect(_engine.computeWHealth(p), closeTo(0.10, 0.001));
    });

    test('피부 시술 (7일 이내) → 0.10', () {
      final p = _profile(
        recentSkinTreatment: true,
        skinTreatmentDate: DateTime.now().subtract(const Duration(days: 7)),
      );
      expect(_engine.computeWHealth(p), closeTo(0.10, 0.001));
    });

    test('피부 시술 (15일 경과) → 0.0 (만료)', () {
      final p = _profile(
        recentSkinTreatment: true,
        skinTreatmentDate: DateTime.now().subtract(const Duration(days: 15)),
      );
      expect(_engine.computeWHealth(p), closeTo(0.0, 0.001));
    });

    test('비염+천식+임신+시술 → 0.65 (전체 합산)', () {
      final p = _profile(
        gender: 'female',
        respiratoryStatus: 3,
        isPregnant: true,
        recentSkinTreatment: true,
      );
      expect(_engine.computeWHealth(p), closeTo(0.65, 0.001));
    });
  });

  // ── computeWLifestyle ────────────────────────────────────────────

  group('computeWLifestyle — 야외 활동', () {
    test('outdoorMinutes 0 (<1h) → 0.0', () {
      expect(_engine.computeWLifestyle(_profile(outdoorMinutes: 0)),
          closeTo(0.0, 0.001));
    });

    test('outdoorMinutes 1 (1~3h) → 0.03', () {
      expect(_engine.computeWLifestyle(_profile(outdoorMinutes: 1)),
          closeTo(0.03, 0.001));
    });

    test('outdoorMinutes 2 (3h+) → 0.07', () {
      expect(_engine.computeWLifestyle(_profile(outdoorMinutes: 2)),
          closeTo(0.07, 0.001));
    });
  });

  // ── computeTFinal — 케이스 시뮬레이션 ─────────────────────────────

  group('computeTFinal — 케이스 시뮬레이션', () {
    test('케이스 1: 평범한 사용자 (1996년생, 건강, 조금예민, 1~3h)', () {
      // W_age=0.0 (30세 → 12~49), W_health=0.0, W_sensitivity=0.02, W_lifestyle=0.03
      // raw = 35 × (1 - 0.05) = 35 × 0.95 = 33.25
      final p = _profile(
        birthYear:        1996,
        respiratoryStatus: 0,
        sensitivityLevel:  1,
        outdoorMinutes:    1,
      );
      expect(p.tFinal, closeTo(33.25, 0.01));
    });

    test('케이스 2: 위험 누적 (1962년생/64세, 비염+천식, 매우예민, 1~3h)', () {
      // W_age=0.06, W_health=0.35, W_sensitivity=0.05, W_lifestyle=0.03
      // W_total=0.49, raw = 35 × 0.51 = 17.85
      final p = _profile(
        birthYear:         1962,
        respiratoryStatus: 3,
        sensitivityLevel:  2,
        outdoorMinutes:    1,
      );
      expect(p.tFinal, closeTo(17.85, 0.01));
    });

    test('케이스 3: 극단 (1950년생/76세, 천식+임신+시술, 매우예민, 3h+) → clamp(15)', () {
      // W_age=0.10, W_health=0.50 (천식0.20+임신0.20+시술0.10), W_sensitivity=0.05, W_lifestyle=0.07
      // W_total=0.72, raw = 35 × 0.28 = 9.8 → clamp → 15.0
      final p = _profile(
        birthYear:         1950,
        gender:            'female',
        respiratoryStatus: 2,
        sensitivityLevel:  2,
        outdoorMinutes:    2,
        isPregnant:        true,
        recentSkinTreatment: true,
      );
      expect(p.tFinal, closeTo(15.0, 0.01));
    });

    test('최대 누적 (80세, 비염+천식+임신+시술, 매우예민, 3h+) → clamp(15)', () {
      // W_age=0.13, W_health=0.65, W_sensitivity=0.05, W_lifestyle=0.07
      // W_total=0.90, raw = 35 × 0.10 = 3.5 → clamp → 15.0
      final p = _profile(
        birthYear:         DateTime.now().year - 80,
        gender:            'female',
        respiratoryStatus: 3,
        sensitivityLevel:  2,
        outdoorMinutes:    2,
        isPregnant:        true,
        recentSkinTreatment: true,
      );
      expect(p.tFinal, closeTo(15.0, 0.01));
    });

    test('일반인 (건강, 무던, 야외 없음, 12~49세) → 35.0 (무가중)', () {
      final p = _profile(
        birthYear:         1990,
        respiratoryStatus: 0,
        sensitivityLevel:  0,
        outdoorMinutes:    0,
      );
      expect(p.tFinal, closeTo(35.0, 0.01));
    });
  });

  // ── clamp 동작 ────────────────────────────────────────────────

  group('clamp 동작', () {
    test('가중치 없으면 tFinal은 tBase(35)로 clamp', () {
      final p = _profile(
        birthYear:        1990,
        respiratoryStatus: 0,
        sensitivityLevel:  0,
        outdoorMinutes:    0,
      );
      expect(_engine.computeTFinal(p), closeTo(35.0, 0.01));
    });

    test('극단 가중치 시 tFinal은 tFloor(15) 이하로 내려가지 않음', () {
      final p = _profile(
        birthYear:         DateTime.now().year - 85,
        gender:            'female',
        respiratoryStatus: 3,
        sensitivityLevel:  2,
        outdoorMinutes:    2,
        isPregnant:        true,
        recentSkinTreatment: true,
      );
      expect(_engine.computeTFinal(p), greaterThanOrEqualTo(15.0));
    });
  });

  // ── PM10 비율 ─────────────────────────────────────────────────

  group('computeTFinalPm10 = computeTFinal × (80/35)', () {
    test('일반인 → tFinal=35 → PM10 임계치=80', () {
      final p = _profile();
      final tPm25 = _engine.computeTFinal(p);
      final tPm10 = _engine.computeTFinalPm10(p);
      expect(tPm10, closeTo(tPm25 * (80.0 / 35.0), 0.001));
    });

    test('임의 프로필에서도 비율 항상 80/35 유지', () {
      final profiles = [
        _profile(respiratoryStatus: 1),
        _profile(respiratoryStatus: 3, sensitivityLevel: 2),
        _profile(
          birthYear: 1960,
          gender: 'female',
          isPregnant: true,
          outdoorMinutes: 2,
        ),
      ];
      for (final p in profiles) {
        final ratio = _engine.computeTFinalPm10(p) / _engine.computeTFinal(p);
        expect(ratio, closeTo(80.0 / 35.0, 0.001));
      }
    });
  });

  // ── ThresholdBreakdown ────────────────────────────────────────

  group('ThresholdBreakdown — 4필드 구조', () {
    test('wTotal = wAge + wHealth + wSensitivity + wLifestyle', () {
      final p = _profile(
        birthYear:         1962,
        respiratoryStatus: 3,
        sensitivityLevel:  2,
        outdoorMinutes:    1,
      );
      final bd = _engine.breakdown(p);
      expect(bd.wTotal,
          closeTo(bd.wAge + bd.wHealth + bd.wSensitivity + bd.wLifestyle, 0.0001));
    });

    test('tFinalRaw = 35 × (1 - wTotal)', () {
      final p = _profile(respiratoryStatus: 1, sensitivityLevel: 1, outdoorMinutes: 1);
      final bd = _engine.breakdown(p);
      final expected = 35.0 * (1.0 - bd.wTotal);
      expect(bd.tFinalRaw, closeTo(expected, 0.0001));
    });

    test('floorApplied = true when tFinalRaw < 15', () {
      final p = _profile(
        birthYear:         DateTime.now().year - 85,
        gender:            'female',
        respiratoryStatus: 3,
        sensitivityLevel:  2,
        outdoorMinutes:    2,
        isPregnant:        true,
        recentSkinTreatment: true,
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
  });
}
