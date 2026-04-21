import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';
import '../engine/threshold_config.dart';

/// Firebase Remote Config에서 ThresholdConfig를 로드하는 서비스
///
/// Remote Config 키: 'threshold_config' (JSON 문자열)
/// 값이 없거나 파싱 실패 시 ThresholdConfig.defaults로 폴백.
///
/// Remote Config 콘솔 설정 방법:
///   키: threshold_config
///   값: ThresholdConfig.defaults.toJson()을 JSON 문자열로 입력
class RemoteConfigService {
  static const String _keyThresholdConfig = 'threshold_config';
  static const Duration _fetchTimeout     = Duration(seconds: 10);
  static const Duration _cacheExpiry      = Duration(hours: 12);

  /// Remote Config에서 ThresholdConfig 로드
  ///
  /// 실패 시 defaults 반환 — 앱 동작에 영향 없음
  static Future<ThresholdConfig> loadThresholdConfig() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: _fetchTimeout,
        minimumFetchInterval: _cacheExpiry,
      ));

      await rc.setDefaults({
        _keyThresholdConfig: '',
      });

      await rc.fetchAndActivate();

      final raw = rc.getString(_keyThresholdConfig);
      if (raw.isEmpty) {
        debugPrint('[RemoteConfig] threshold_config 미설정 → defaults 사용');
        return ThresholdConfig.defaults;
      }

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final config = ThresholdConfig.fromJson(json);
      debugPrint('[RemoteConfig] ThresholdConfig 로드 완료: tBase=${config.tBase}');
      return config;
    } catch (e, st) {
      AppLogger.error(e, st, reason: 'remote_config_parse');
      return ThresholdConfig.defaults;
    }
  }
}
