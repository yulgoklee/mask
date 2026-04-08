import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../constants/app_constants.dart';
import '../../firebase_options.dart';
import 'notification_scheduler.dart';

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
    // 이미 초기화됐거나 실패해도 알림 체크는 계속 진행
  }
  final prefs = await SharedPreferences.getInstance();
  await NotificationScheduler().runCheck(prefs);
}

class BackgroundService {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    // isInDebugMode: 디버그 빌드에서 Workmanager 로그 출력 활성화
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
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
