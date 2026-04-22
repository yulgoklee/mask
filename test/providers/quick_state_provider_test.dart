import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/temporary_state.dart';
import 'package:mask_alert/data/models/today_situation.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile_tab/models/quick_state.dart';
import 'package:mask_alert/features/profile_tab/providers/quick_state_provider.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── In-memory ProfileRepository fake ──────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  UserProfile _profile;
  _FakeProfileRepo([UserProfile? initial])
      : _profile = initial ?? UserProfile.defaultProfile();

  @override
  Future<UserProfile> loadProfile() async => _profile;

  @override
  Future<void> saveProfile(UserProfile profile) async => _profile = profile;

  // 사용되지 않는 메서드 — 기본값 반환
  @override
  Future<NotificationSetting> loadNotificationSetting() async =>
      const NotificationSetting();

  @override
  Future<void> saveNotificationSetting(NotificationSetting setting) async {}

  @override
  Future<List<TemporaryState>> loadTemporaryStates() async => [];

  @override
  Future<void> saveTemporaryStates(List<TemporaryState> states) async {}

  @override
  Future<List<TodaySituation>> loadTodaySituations() async => [];

  @override
  Future<void> saveTodaySituations(List<TodaySituation> situations) async {}

  @override
  Future<bool> isOnboardingCompleted() async => false;

  @override
  Future<void> completeOnboarding() async {}

  @override
  Future<void> resetOnboarding() async {}

  @override
  Future<bool> isTutorialSeen() async => false;

  @override
  Future<void> completeTutorial() async {}
}

// ── 기본 테스트 프로필 (sensitivityLevel=1, outdoorMinutes=1, skin=false) ──

const _baseProfile = UserProfile(
  nickname: '테스트',
  birthYear: 1990,
  gender: 'male',
  respiratoryStatus: 0,
  sensitivityLevel: 1,
  isPregnant: false,
  recentSkinTreatment: false,
  outdoorMinutes: 1,
  activityTags: [],
  discomfortLevel: 1,
);

// ── 테스트 픽스쳐 빌더 ─────────────────────────────────────

Future<(ProviderContainer, SharedPreferences)> _buildSetup({
  UserProfile? initialProfile,
  Map<String, Object> extraPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(extraPrefs));
  final prefs = await SharedPreferences.getInstance();

  final fakeRepo = _FakeProfileRepo(initialProfile ?? _baseProfile);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      profileRepositoryProvider.overrideWith((_) => fakeRepo),
    ],
  );
  addTearDown(container.dispose);

  return (container, prefs);
}

// 비동기 초기화 완료까지 대기
Future<void> _pump() => Future.delayed(const Duration(milliseconds: 5));

void main() {
  // ── 테스트 a: 감기 OFF→ON 시 백업 저장 + sensitivityLevel=2 ──

  test('a: 감기 ON — 백업 저장 후 sensitivityLevel=2', () async {
    final (container, prefs) = await _buildSetup();

    // quickStateProvider 초기화 및 profileProvider 초기화 대기
    container.read(quickStateProvider);
    container.read(profileProvider);
    await _pump();

    await container.read(quickStateProvider.notifier).toggle(QuickStateType.cold);

    expect(container.read(profileProvider).sensitivityLevel, 2);
    expect(prefs.getInt('quick_state_backup_sensitivity'), 1);
  });

  // ── 테스트 b: 감기 ON→OFF 시 원래 sensitivityLevel 복원 + 백업 삭제 ──

  test('b: 감기 OFF — sensitivityLevel 원복 + 백업 키 삭제', () async {
    // cold=true 상태에서 시작 (오늘 날짜)
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final (container, prefs) = await _buildSetup(
      // profile은 이미 sensitivityLevel=2 (cold ON 상태)
      initialProfile: _baseProfile.copyWith(sensitivityLevel: 2),
      extraPrefs: {
        'quick_state_date': today,
        'quick_state_cold': true,
        'quick_state_backup_sensitivity': 1,
      },
    );

    container.read(quickStateProvider);
    container.read(profileProvider);
    await _pump();

    // 현재 상태: cold=ON. 한 번 더 토글 → OFF
    await container.read(quickStateProvider.notifier).toggle(QuickStateType.cold);

    expect(container.read(profileProvider).sensitivityLevel, 1);
    expect(prefs.containsKey('quick_state_backup_sensitivity'), false);
  });

  // ── 테스트 c: 세 토글 동시 ON/OFF — 필드별 독립 백업·복원 ──

  test('c: 세 토글 동시 ON→OFF — 각 필드 독립 복원', () async {
    final (container, prefs) = await _buildSetup();

    container.read(quickStateProvider);
    container.read(profileProvider);
    await _pump();

    final notifier = container.read(quickStateProvider.notifier);

    // 세 토글 모두 ON
    await notifier.toggle(QuickStateType.cold);
    await notifier.toggle(QuickStateType.skinTreatment);
    await notifier.toggle(QuickStateType.outdoorActive);

    final afterOn = container.read(profileProvider);
    expect(afterOn.sensitivityLevel, 2);
    expect(afterOn.recentSkinTreatment, true);
    expect(afterOn.outdoorMinutes, 2);

    // 세 토글 모두 OFF
    await notifier.toggle(QuickStateType.cold);
    await notifier.toggle(QuickStateType.skinTreatment);
    await notifier.toggle(QuickStateType.outdoorActive);

    final afterOff = container.read(profileProvider);
    expect(afterOff.sensitivityLevel, 1);       // 원래 1
    expect(afterOff.recentSkinTreatment, false); // 원래 false
    expect(afterOff.outdoorMinutes, 1);          // 원래 1

    // 백업 키 모두 삭제됐는지 확인
    expect(prefs.containsKey('quick_state_backup_sensitivity'), false);
    expect(prefs.containsKey('quick_state_backup_skin'), false);
    expect(prefs.containsKey('quick_state_backup_outdoor'), false);
  });

  // ── 테스트 d: 이미 백업 키가 있으면 덮어쓰지 않음 ──

  test('d: 백업 키 이미 존재 시 containsKey 가드로 덮어쓰기 방지', () async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    // cold=ON, backup=0 (sensitivityLevel 0 = 무던으로 설정)
    final (container, prefs) = await _buildSetup(
      initialProfile: _baseProfile.copyWith(sensitivityLevel: 2),
      extraPrefs: {
        'quick_state_date': today,
        'quick_state_cold': true,
        'quick_state_backup_sensitivity': 0, // 원본: 무던(0)
      },
    );

    container.read(quickStateProvider);
    container.read(profileProvider);
    await _pump();

    // cold=ON → OFF → ON 순서
    final notifier = container.read(quickStateProvider.notifier);
    await notifier.toggle(QuickStateType.cold); // OFF: 복원 후 백업 삭제
    await notifier.toggle(QuickStateType.cold); // ON: 현재 프로필(=0) 백업

    // OFF 후 ON이므로 백업은 복원된 값(0)으로 다시 저장돼야 함
    expect(prefs.getInt('quick_state_backup_sensitivity'), 0);
    expect(container.read(profileProvider).sensitivityLevel, 2);
  });

  // ── 테스트 e: 일별 리셋 — cold=ON 상태에서 다음 날 앱 시작 시 프로필 복원 ──

  test('e: 하루 경과 리셋 — cold=ON이었던 프로필 sensitivityLevel 원복', () async {
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    // 어제 cold=ON이었고 sensitivityLevel=2로 설정된 상태
    final (container, prefs) = await _buildSetup(
      initialProfile: _baseProfile.copyWith(sensitivityLevel: 2),
      extraPrefs: {
        'quick_state_date': yesterday,
        'quick_state_cold': true,
        'quick_state_backup_sensitivity': 1, // 원본값 백업
        'quick_state_outdoor': false,
      },
    );

    container.read(quickStateProvider);
    container.read(profileProvider);
    // _init()의 _restoreForDailyReset() 완료 대기
    await _pump();

    // 오늘 날짜로 리셋 → cold=false
    expect(container.read(quickStateProvider).isCold, false);
    // 프로필 sensitivityLevel 원본(1)으로 복원
    expect(container.read(profileProvider).sensitivityLevel, 1);
    // 백업 키 삭제됨
    expect(prefs.containsKey('quick_state_backup_sensitivity'), false);
  });
}
