import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/profile_providers.dart';
import '../models/quick_state.dart';

class QuickStateNotifier extends StateNotifier<QuickState> {
  final ProfileRepository _profileRepo;
  final SharedPreferences _prefs;
  final Ref _ref;

  static const _dateKey = 'quick_state_date';
  static const _coldKey = 'quick_state_cold';
  static const _skinKey = 'quick_state_skin';
  static const _outdoorKey = 'quick_state_outdoor';

  QuickStateNotifier(this._profileRepo, this._prefs, this._ref)
      : super(QuickState.initial()) {
    _init();
  }

  void _init() {
    final lastDate = _prefs.getString(_dateKey);
    final today = _todayStr();

    final cold = _prefs.getBool(_coldKey) ?? false;
    final skin = _prefs.getBool(_skinKey) ?? false;
    final outdoor = _prefs.getBool(_outdoorKey) ?? false;

    if (lastDate != today) {
      // 매일 자정 감기/야외 리셋 (피부 시술 유지)
      state = QuickState(hasSkinTreatment: skin);
      _prefs.setString(_dateKey, today);
      _prefs.setBool(_coldKey, false);
      _prefs.setBool(_outdoorKey, false);
    } else {
      state = QuickState(isCold: cold, hasSkinTreatment: skin, isOutdoorActive: outdoor);
    }
  }

  Future<void> toggle(QuickStateType type) async {
    final next = state.toggle(type);
    state = next;
    _persist(next);
    await _applyToProfile(next);
  }

  void _persist(QuickState qs) {
    _prefs.setString(_dateKey, _todayStr());
    _prefs.setBool(_coldKey, qs.isCold);
    _prefs.setBool(_skinKey, qs.hasSkinTreatment);
    _prefs.setBool(_outdoorKey, qs.isOutdoorActive);
  }

  Future<void> _applyToProfile(QuickState qs) async {
    final base = await _profileRepo.loadProfile();
    final updated = base.copyWith(
      sensitivityLevel: qs.isCold ? 2 : base.sensitivityLevel,
      recentSkinTreatment: qs.hasSkinTreatment ? true : base.recentSkinTreatment,
      outdoorMinutes: qs.isOutdoorActive ? 2 : base.outdoorMinutes,
    );
    _ref.read(profileProvider.notifier).update(updated);
  }

  String _todayStr() => DateTime.now().toIso8601String().substring(0, 10);
}

final quickStateProvider =
    StateNotifierProvider<QuickStateNotifier, QuickState>((ref) {
  return QuickStateNotifier(
    ref.watch(profileRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
    ref,
  );
});
