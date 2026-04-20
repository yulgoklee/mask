/// 앱 전체 상수 관리
/// 하드코딩 숫자·문자열은 여기에 모아서 관리한다.
class AppConstants {
  AppConstants._();

  // ── 캐시 ─────────────────────────────────────────────────
  /// 조회 후 이 시간(분) 이하이면 캐시 유효
  static const int cacheFetchMaxMinutes = 30;

  /// 측정 시각 기준 이 시간(분) 이내여야 유효
  /// (에어코리아 API는 매시 정각 업데이트 → 70분 초과 시 새 데이터 있다고 판단)
  static const int cacheDataMaxMinutes = 70;

  // ── 알림 ─────────────────────────────────────────────────
  /// 알림 발송 허용 윈도우: 설정 시간 ±이 분(분) 이내일 때 발송
  ///
  /// 15로 설정 시 8:00 알림 → 7:45~8:15 사이 WorkManager 실행에서 발송.
  /// 즉 외출 최대 15분 전에 사전 체크가 가능해져 "출발 전 여유 알림" 효과.
  static const int notificationWindowMinutes = 15;

  /// Workmanager 백그라운드 체크 주기 (분)
  static const int backgroundTaskIntervalMinutes = 15;

  // ── SharedPreferences 키 ──────────────────────────────────
  /// 저장된 측정소 이름
  static const String prefStationName = 'saved_station_name';

  /// 사용자 프로필 JSON
  static const String prefUserProfile = 'user_profile';

  /// 알림 설정 JSON
  static const String prefNotificationSetting = 'notification_setting';

  /// 미세먼지 캐시 키 접두사 (실제 키: prefDustCache_측정소명)
  static const String prefDustCache = 'dust_cache';

  /// 온보딩 완료 여부
  static const String prefOnboardingCompleted = 'onboarding_completed';

  /// 튜토리얼 열람 여부
  static const String prefTutorialSeen = 'tutorial_seen';

  // ── 알림 임계값 ───────────────────────────────────────────
  /// 급증 경보 판단 기준 기울기 (μg/m³/h)
  /// 실사용 데이터 분석 후 조정 가능
  static const double surgeRateThreshold = 7.0;
}
