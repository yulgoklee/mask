import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../database/local_database.dart';
import '../../firebase_options.dart';
import '../services/air_korea_service.dart';
import '../services/aqi_polling_service.dart';
import '../services/cloud_functions_data_source.dart';
import 'notification_scheduler.dart';

/// 백그라운드 GPS 갱신 간격 (밀리초)
const _kGpsRefreshIntervalMs = 6 * 60 * 60 * 1000; // 6시간
const _kPrefLastGpsUpdate = 'bg_last_gps_update_ms';

const String _taskCheckDust = 'check_dust_task';

/// Workmanager 백그라운드 콜백 (top-level 함수 필수)
///
/// ⚠️ 백그라운드 isolate는 별도 Flutter 인스턴스 → 플러그인 사용 전
///    WidgetsFlutterBinding.ensureInitialized() 반드시 호출해야 함.
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized(); // 백그라운드 isolate 플러그인 초기화
  Workmanager().executeTask((task, inputData) async {
    if (task == _taskCheckDust) {
      await _runDustCheck();
    }
    return true;
  });
}

Future<void> _runDustCheck() async {
  // 백그라운드 isolate는 별도 인스턴스 → Firebase 재초기화 필요
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // 이미 초기화됐거나 실패해도 계속 진행
  }
  final prefs = await SharedPreferences.getInstance();

  // 1. GPS 측정소 자동 갱신 (6시간 이상 경과한 경우만)
  await _tryRefreshStation(prefs);

  // 2. AQI 폴링 → SQLite 저장 (차트 과거 데이터 축적)
  await _runAqiPolling(prefs);

  // 3. 알림 체크 (T_final 초과 판단)
  await NotificationScheduler().runCheck(prefs);
}

/// AQI 폴링 + SQLite 저장
///
/// 백그라운드 isolate에서 SQLite를 직접 초기화하여 사용.
/// 실패해도 알림 체크에 영향 없도록 try-catch로 격리.
Future<void> _runAqiPolling(SharedPreferences prefs) async {
  try {
    final db = LocalDatabase();
    final dataSource = AppConfig.cloudFunctionsBaseUrl.isNotEmpty
        ? CloudFunctionsDataSource()
        : AirKoreaService(prefs);
    final polling = AqiPollingService(airKorea: dataSource, db: db);
    await polling.runPollingCycle(prefs: prefs);
    await db.close();
  } catch (e) {
    debugPrint('[BGService] AQI 폴링 실패 (무시): $e');
  }
}

/// 백그라운드에서 GPS 기반 측정소 자동 갱신
///
/// 조건:
/// - 마지막 갱신으로부터 [_kGpsRefreshIntervalMs] 이상 경과
/// - 위치 권한이 이미 허용된 상태 (권한 요청 절대 금지)
/// - 실패해도 알림 체크에 영향 없음 (best-effort)
Future<void> _tryRefreshStation(SharedPreferences prefs) async {
  try {
    // 갱신 시간 체크
    final lastMs = prefs.getInt(_kPrefLastGpsUpdate) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastMs < _kGpsRefreshIntervalMs) {
      debugPrint('[BGService] GPS 갱신 스킵 (${((nowMs - lastMs) / 3600000).toStringAsFixed(1)}h 경과)');
      return;
    }

    // 권한 확인 — 백그라운드에서는 이미 허용된 경우만 진행
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      debugPrint('[BGService] GPS 권한 없음 → 갱신 스킵');
      return;
    }

    // 마지막 알려진 위치 우선 사용 (배터리 절약)
    Position? pos = await Geolocator.getLastKnownPosition();
    pos ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );

    final station = await AirKoreaService.findNearestStation(
        pos.latitude, pos.longitude);
    if (station == null) {
      debugPrint('[BGService] 가까운 측정소를 찾지 못했어요 (lat=${pos.latitude}, lng=${pos.longitude})');
      return;
    }

    // 측정소 + 위치 + 갱신 시각 저장
    await prefs.setString(AppConstants.prefStationName, station);
    await prefs.setDouble('saved_lat', pos.latitude);
    await prefs.setDouble('saved_lng', pos.longitude);
    await prefs.setInt(_kPrefLastGpsUpdate, nowMs);
    debugPrint('[BGService] 측정소 갱신 완료: $station');
  } catch (e) {
    // 백그라운드 GPS 갱신은 best-effort — 절대 throw하지 않음
    debugPrint('[BGService] GPS 갱신 실패 (무시): $e');
  }
}

class BackgroundService {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    // isInDebugMode: 디버그 빌드에서 Workmanager 로그 출력 활성화
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> registerPeriodicTask() async {
    if (kIsWeb) return;
    await Workmanager().registerPeriodicTask(
      _taskCheckDust,
      _taskCheckDust,
      frequency: const Duration(minutes: AppConstants.backgroundTaskIntervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// 백그라운드 로직을 즉시 1회 실행 (테스트/디버그용)
  /// 시간 윈도우 체크 없이 알림 발송 여부를 빠르게 검증할 수 있음
  static Future<void> runOnce() async {
    if (kIsWeb) return;
    await Workmanager().registerOneOffTask(
      '${_taskCheckDust}_test',
      _taskCheckDust,
      initialDelay: Duration.zero,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await Workmanager().cancelAll();
  }
}
