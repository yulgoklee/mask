import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/utils/dust_calculator.dart';
import 'package:mask_alert/data/models/dust_data.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/models/temporary_state.dart';
import 'package:mask_alert/data/models/today_situation.dart';

/// 기본 프로필 (일반 성인, 기저질환 없음)
UserProfile _normalProfile() => const UserProfile(
      ageGroup: AgeGroup.thirties,
      hasCondition: false,
      activityLevel: ActivityLevel.normal,
    );

/// pm25 값으로 DustData 생성
DustData _dust(int pm25) => DustData(
      stationName: '',
      pm25Value: pm25,
      pm10Value: 30,
      pm25Grade: '',
      pm10Grade: '',
      dataTime: DateTime.now(),
      fetchedAt: DateTime.now(),
    );

void main() {
  // ── Tier 1 기본 동작 ────────────────────────────────────────

  group('Tier 1 — 기본 프로필', () {
    test('PM2.5 10 (좋음) → 마스크 불필요', () {
      final result = DustCalculator.calculate(_normalProfile(), _dust(10));
      expect(result.maskRequired, isFalse);
      expect(result.maskType, isNull);
    });

    test('PM2.5 40 (나쁨) → 마스크 필요, KF80', () {
      final result = DustCalculator.calculate(_normalProfile(), _dust(40));
      expect(result.maskRequired, isTrue);
      expect(result.maskType, 'KF80');
    });

    test('PM2.5 80 (매우나쁨) → 마스크 필요, KF94', () {
      final result = DustCalculator.calculate(_normalProfile(), _dust(80));
      expect(result.maskRequired, isTrue);
      expect(result.maskType, 'KF94');
    });
  });

  // ── Tier 2: 기간 상태 ───────────────────────────────────────

  group('Tier 2 — 임신 중 (보통 16+ 이상 KF94)', () {
    final pregnancy = TemporaryState(
      type: TemporaryStateType.pregnancy,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
    );

    test('PM2.5 10 (좋음) + 임신 → 마스크 불필요', () {
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(10),
        temporaryStates: [pregnancy],
      );
      // 좋음(10)은 보통(16) 미만 → 임신 기준에도 마스크 불필요
      expect(result.maskRequired, isFalse);
    });

    test('PM2.5 20 (보통) + 임신 → 마스크 필요, KF94', () {
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(20),
        temporaryStates: [pregnancy],
      );
      expect(result.maskRequired, isTrue);
      expect(result.maskType, 'KF94');
    });

    test('personalNote에 임신 문구 포함', () {
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(20),
        temporaryStates: [pregnancy],
      );
      expect(result.personalNote, contains('임신'));
    });
  });

  group('Tier 2 — 피부 시술 후 (등급 무관, 항상 마스크 KF80)', () {
    final skinProcedure = TemporaryState(
      type: TemporaryStateType.skinProcedureRecovery,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      expiryDate: DateTime.now().add(const Duration(days: 6)),
    );

    test('PM2.5 5 (매우 좋음) + 피부시술 → 마스크 필요, KF80', () {
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(5),
        temporaryStates: [skinProcedure],
      );
      expect(result.maskRequired, isTrue);
      expect(result.maskType, 'KF80');
    });
  });

  group('Tier 2 — 면역저하/항암 (좋음부터 KF94)', () {
    final immunoSuppressed = TemporaryState(
      type: TemporaryStateType.immunoSuppressed,
      startDate: DateTime.now(),
    );

    test('PM2.5 10 (좋음) + 면역저하 → 마스크 필요, KF94', () {
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(10),
        temporaryStates: [immunoSuppressed],
      );
      expect(result.maskRequired, isTrue);
      expect(result.maskType, 'KF94');
    });
  });

  // ── Tier 3: 오늘의 상황 ─────────────────────────────────────

  group('Tier 3 — 야외 운동 (보통 16+ 이상 KF80)', () {
    final outdoorExercise = TodaySituation(
      type: TodaySituationType.outdoorExercise,
      date: DateTime.now(),
    );

    test('PM2.5 10 + 야외운동 → 마스크 불필요', () {
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(10),
        todaySituation: outdoorExercise,
      );
      expect(result.maskRequired, isFalse);
    });

    test('PM2.5 20 (보통) + 야외운동 → 마스크 필요, KF80', () {
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(20),
        todaySituation: outdoorExercise,
      );
      expect(result.maskRequired, isTrue);
      expect(result.maskType, 'KF80');
    });
  });

  // ── Tier 조합 ───────────────────────────────────────────────

  group('Tier 조합 — 더 엄격한 기준 우선', () {
    test('임신(KF94) + 야외운동(KF80) → KF94 선택', () {
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(20),
        temporaryStates: [
          TemporaryState(
            type: TemporaryStateType.pregnancy,
            startDate: DateTime.now(),
          ),
        ],
        todaySituation: TodaySituation(
          type: TodaySituationType.outdoorExercise,
          date: DateTime.now(),
        ),
      );
      expect(result.maskRequired, isTrue);
      expect(result.maskType, 'KF94');
    });

    test('만료된 기간 상태는 무시됨', () {
      final expired = TemporaryState(
        type: TemporaryStateType.pregnancy,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(20),
        temporaryStates: [expired],
      );
      // 임신 상태가 만료됐으니 보통(20)에선 일반 기준 적용 → 마스크 불필요
      expect(result.maskRequired, isFalse);
    });

    test('어제 설정한 오늘의 상황은 무시됨', () {
      final yesterday = TodaySituation(
        type: TodaySituationType.outdoorExercise,
        date: DateTime.now().subtract(const Duration(days: 1)),
      );
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(20),
        todaySituation: yesterday,
      );
      expect(result.maskRequired, isFalse);
    });
  });

  // ── heroText ─────────────────────────────────────────────────

  group('heroText — 공기 좋지만 취약 상태면 챙기세요', () {
    test('PM2.5 10 + 임신 → heroText에 챙기세요 포함', () {
      final result = DustCalculator.calculate(
        _normalProfile(),
        _dust(20),
        temporaryStates: [
          TemporaryState(
            type: TemporaryStateType.pregnancy,
            startDate: DateTime.now(),
          ),
        ],
      );
      expect(result.heroText, contains('챙기세요'));
    });
  });
}
