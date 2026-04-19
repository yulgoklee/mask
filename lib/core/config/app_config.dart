/// 🔑 API 키 설정 파일 (app_config.dart.example 참고)
/// 실제 키는 로컬에만 존재하며 .gitignore 처리됨
class AppConfig {
  static const String airKoreaApiKey = String.fromEnvironment(
    'AIR_KOREA_API_KEY',
    defaultValue: '',
  );

  /// Cloud Functions 베이스 URL
  /// - 비워두면 AirKorea API 직접 호출
  /// - 설정하면 CloudFunctionsDataSource 자동 사용 (프록시)
  static const String cloudFunctionsBaseUrl = String.fromEnvironment(
    'CLOUD_FUNCTIONS_BASE_URL',
    defaultValue: '',
  );
}
