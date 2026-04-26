import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/engine/threshold_engine.dart';
import 'package:mask_alert/data/models/user_profile.dart';

const _engine = ThresholdEngine();

UserProfile _profile({
  int respiratoryStatus = 0,
  bool isPregnant = false,
  int outdoorMinutes = 0,
}) => UserProfile(
  nickname: '', birthYear: 1990, gender: 'female',
  respiratoryStatus: respiratoryStatus,
  sensitivityLevel: 1,
  isPregnant: isPregnant,
  recentSkinTreatment: false,
  outdoorMinutes: outdoorMinutes, // 0 = outdoor_under_1h → W_lifestyle=0
  activityTags: [], discomfortLevel: 1,
);

void main() {
  group('ThresholdEngine.computeTFinalPm10 = computeTFinal × (80/35)', () {
    test('일반인 (T_final=35) → PM10 임계치 = 80', () {
      final tPm25 = _engine.computeTFinal(_profile());
      final tPm10 = _engine.computeTFinalPm10(_profile());
      expect(tPm10, closeTo(tPm25 * (80.0 / 35.0), 0.001));
      expect(tPm10, closeTo(80.0, 0.1));
    });

    test('비염 (T_final=28) → PM10 임계치 ≈ 64', () {
      final tPm10 = _engine.computeTFinalPm10(_profile(respiratoryStatus: 1));
      final expected = 28.0 * (80.0 / 35.0);
      expect(tPm10, closeTo(expected, 0.01));
    });

    test('천식 (T_final≈26.25) → PM10 임계치 ≈ 60', () {
      final tPm10 = _engine.computeTFinalPm10(_profile(respiratoryStatus: 2));
      final expected = _engine.computeTFinal(_profile(respiratoryStatus: 2)) * (80.0 / 35.0);
      expect(tPm10, closeTo(expected, 0.001));
    });

    test('임신 (T_final≈22.75) → PM10 임계치 ≈ 52', () {
      final tPm10 = _engine.computeTFinalPm10(_profile(isPregnant: true));
      final expected = _engine.computeTFinal(_profile(isPregnant: true)) * (80.0 / 35.0);
      expect(tPm10, closeTo(expected, 0.001));
    });

    test('PM10 임계치는 항상 PM2.5 임계치의 80/35배', () {
      for (final p in [
        _profile(),
        _profile(respiratoryStatus: 1),
        _profile(respiratoryStatus: 2),
        _profile(isPregnant: true),
      ]) {
        final ratio = _engine.computeTFinalPm10(p) / _engine.computeTFinal(p);
        expect(ratio, closeTo(80.0 / 35.0, 0.001));
      }
    });

    test('T_floor 적용 시 PM10 임계치도 비율 유지', () {
      // 야외 3h+ + 임신 → 최대 가중치 → T_floor 가능성
      final profile = _profile(isPregnant: true, outdoorMinutes: 2);
      final tPm25 = _engine.computeTFinal(profile);
      final tPm10 = _engine.computeTFinalPm10(profile);
      expect(tPm10, closeTo(tPm25 * (80.0 / 35.0), 0.001));
    });
  });
}
