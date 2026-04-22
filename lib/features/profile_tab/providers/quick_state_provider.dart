import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/profile_providers.dart';
import '../models/quick_state.dart';

class QuickStateNotifier extends StateNotifier<QuickState> {
  final ProfileRepository _profileRepo;
  final SharedPreferences _prefs;
  final Ref _ref;

  static const _dateKey    = 'quick_state_date';
  static const _coldKey    = 'quick_state_cold';
  static const _skinKey    = 'quick_state_skin';
  static const _outdoorKey = 'quick_state_outdoor';

  // 토글 ON 시 덮어쓰기 전 원본값 백업 키
  static const _backupSensitivityKey = 'quick_state_backup_sensitivity';
  static const _backupSkinKey        = 'quick_state_backup_skin';
  static const _backupOutdoorKey     = 'quick_state_backup_outdoor';

  QuickStateNotifier(this._profileRepo, this._prefs, this._ref)
      : super(QuickState.initial()) {
    _init();
  }

  Future<void> _init() async {
    final lastDate = _prefs.getString(_dateKey);
    final today = _todayStr();

    final cold    = _prefs.getBool(_coldKey)    ?? false;
    final skin    = _prefs.getBool(_skinKey)    ?? false;
    final outdoor = _prefs.getBool(_outdoorKey) ?? false;

    if (lastDate != today) {
      // 매일 자정 감기/야외 리셋 (피부 시술 유지)
      state = QuickState(hasSkinTreatment: skin);
      _prefs.setString(_dateKey, today);
      _prefs.setBool(_coldKey, false);
      _prefs.setBool(_outdoorKey, false);
      // ON 상태였던 토글의 백업값을 프로필에 복원
      await _restoreForDailyReset(wasCold: cold, wasOutdoor: outdoor);
    } else {
      state = QuickState(isCold: cold, hasSkinTreatment: skin, isOutdoorActive: outdoor);
    }
  }

  Future<void> toggle(QuickStateType type) async {
    final prev = state;
    final next = state.toggle(type);
    state = next;
    _persist(next);
    await _applyToProfile(prev, next);
  }

  void _persist(QuickState qs) {
    _prefs.setString(_dateKey, _todayStr());
    _prefs.setBool(_coldKey, qs.isCold);
    _prefs.setBool(_skinKey, qs.hasSkinTreatment);
    _prefs.setBool(_outdoorKey, qs.isOutdoorActive);
  }

  Future<void> _applyToProfile(QuickState prev, QuickState next) async {
    final base = await _profileRepo.loadProfile();

    int  newSensitivity = base.sensitivityLevel;
    bool newSkin        = base.recentSkinTreatment;
    int  newOutdoor     = base.outdoorMinutes;

    // 감기 토글 — sensitivityLevel
    if (!prev.isCold && next.isCold) {
      if (!_prefs.containsKey(_backupSensitivityKey)) {
        await _prefs.setInt(_backupSensitivityKey, base.sensitivityLevel);
      }
      newSensitivity = 2;
    } else if (prev.isCold && !next.isCold) {
      newSensitivity = _prefs.getInt(_backupSensitivityKey) ?? base.sensitivityLevel;
      await _prefs.remove(_backupSensitivityKey);
    }

    // 피부 시술 토글 — recentSkinTreatment
    if (!prev.hasSkinTreatment && next.hasSkinTreatment) {
      if (!_prefs.containsKey(_backupSkinKey)) {
        await _prefs.setBool(_backupSkinKey, base.recentSkinTreatment);
      }
      newSkin = true;
    } else if (prev.hasSkinTreatment && !next.hasSkinTreatment) {
      newSkin = _prefs.getBool(_backupSkinKey) ?? base.recentSkinTreatment;
      await _prefs.remove(_backupSkinKey);
    }

    // 야외 활동 토글 — outdoorMinutes
    if (!prev.isOutdoorActive && next.isOutdoorActive) {
      if (!_prefs.containsKey(_backupOutdoorKey)) {
        await _prefs.setInt(_backupOutdoorKey, base.outdoorMinutes);
      }
      newOutdoor = 2;
    } else if (prev.isOutdoorActive && !next.isOutdoorActive) {
      newOutdoor = _prefs.getInt(_backupOutdoorKey) ?? base.outdoorMinutes;
      await _prefs.remove(_backupOutdoorKey);
    }

    await _ref.read(profileProvider.notifier).saveProfile(base.copyWith(
      sensitivityLevel:    newSensitivity,
      recentSkinTreatment: newSkin,
      outdoorMinutes:      newOutdoor,
    ));
  }

  /// 하루가 지나 감기/야외가 자동 리셋될 때 프로필 원복
  Future<void> _restoreForDailyReset({
    required bool wasCold,
    required bool wasOutdoor,
  }) async {
    if (!wasCold && !wasOutdoor) return;

    final base = await _profileRepo.loadProfile();
    int newSensitivity = base.sensitivityLevel;
    int newOutdoor     = base.outdoorMinutes;

    if (wasCold) {
      newSensitivity = _prefs.getInt(_backupSensitivityKey) ?? base.sensitivityLevel;
      await _prefs.remove(_backupSensitivityKey);
    }
    if (wasOutdoor) {
      newOutdoor = _prefs.getInt(_backupOutdoorKey) ?? base.outdoorMinutes;
      await _prefs.remove(_backupOutdoorKey);
    }

    await _ref.read(profileProvider.notifier).saveProfile(base.copyWith(
      sensitivityLevel: newSensitivity,
      outdoorMinutes:   newOutdoor,
    ));
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
