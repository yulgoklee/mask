import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  if (!kIsWeb) {
    // 알림 서비스 초기화
    final notifService = NotificationService();
    await notifService.initialize();

    // Android 13+ 알림 권한 요청
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // iOS 알림 권한 요청
    await notifService.requestPermission();

    // 백그라운드 작업 등록
    await BackgroundService.initialize();
    await BackgroundService.registerPeriodicTask();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaskAlertApp(),
    ),
  );
}
