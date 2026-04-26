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

  // ── AQI 폴링 ─────────────────────────────────────────────
  /// 마지막 AQI 폴링 시각 (ms, SharedPreferences)
  static const String prefLastAqiPollMs = 'aqi_last_poll_ms';

  /// AQI 폴링 쿨다운 (분) — 에어코리아 실측값은 1시간 단위 갱신
  static const int aqiPollCooldownMinutes = 50;

  // ── 알림 임계값 ───────────────────────────────────────────
  /// 급변 선제 알림 발동 기준 상승 속도 (μg/m³/h)
  /// 7.0 = 1시간 후 '보통→나쁨' 경계 돌파 예상 최소 속도
  static const double surgeRateThresholdUgPerHour = 7.0;

  // ── 알림 중복 방지 키 접두사 ─────────────────────────────
  /// 형식: prefNotifSent + '{type}_{YYYYMMDD}' (일별) 또는 '{type}_{YYYYMMDDHH}' (시간별)
  static const String prefNotifSent             = 'notif_sent_';

  // ── 안심 알림 추적 ────────────────────────────────────────
  static const String prefBelowTFinalSince      = 'notif_below_tfinal_since';
  static const String prefLastMaskRequiredAt    = 'notif_last_mask_required_at';

  // ── 방해 금지 시간 ────────────────────────────────────────
  static const String prefQuietHoursEnabled     = 'quiet_hours_enabled';
  static const String prefQuietHoursStartHour   = 'quiet_hours_start_hour';
  static const String prefQuietHoursEndHour     = 'quiet_hours_end_hour';

  // ── 위치 ──────────────────────────────────────────────────
  static const String prefSavedLat              = 'saved_lat';
  static const String prefSavedLng              = 'saved_lng';
  static const String prefLastGpsUpdateMs       = 'bg_last_gps_update_ms';

  // ── 프로필 부가 데이터 ────────────────────────────────────
  static const String prefTemporaryStates       = 'temporary_states';
  static const String prefTodaySituation        = 'today_situation';

  // ── 학습 엔진 ─────────────────────────────────────────────
  static const String prefAdaptiveSOffset       = 'adaptive_s_offset';
  static const String prefAdaptiveLastEval      = 'adaptive_last_eval';
  static const String prefAdaptiveEvalCount     = 'adaptive_eval_count';

  // ── 기타 ──────────────────────────────────────────────────
  static const String prefAnonymousUserId       = 'anonymous_user_id';

  // ── 면책 동의 ─────────────────────────────────────────────
  /// 의료 면책 동의 일시 (ISO 8601 문자열, null이면 미동의)
  static const String prefDisclaimerAgreedAt    = 'disclaimer_agreed_at';
}
