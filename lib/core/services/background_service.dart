import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_scheduler.dart';

const String _taskCheckDust = 'check_dust_task';

/// Workmanager 백그라운드 콜백 (top-level 함수 필수)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _taskCheckDust) {
      await _runDustCheck();
    }
    return true;
  });
}

Future<void> _runDustCheck() async {
  final prefs = await SharedPreferences.getInstance();
  await NotificationScheduler().runCheck(prefs);
}

class BackgroundService {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> registerPeriodicTask() async {
    if (kIsWeb) return;
    await Workmanager().registerPeriodicTask(
      _taskCheckDust,
      _taskCheckDust,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await Workmanager().cancelAll();
  }
}
