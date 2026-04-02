import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Flutter 에러 → Crashlytics로 전송
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // 비동기 에러 → Crashlytics로 전송
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
