import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/workmanager_push_scheduler.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 — 실패해도 앱은 계속 실행
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (_) {
    // Firebase 초기화 실패 시 Analytics/Crashlytics 없이 앱 실행
  }

  if (firebaseReady) {
    // Flutter 에러 → Crashlytics로 전송
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // 비동기 에러 → Crashlytics로 전송
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final prefs = await SharedPreferences.getInstance();

  if (!kIsWeb) {
    // AdMob 초기화
    await MobileAds.instance.initialize();

    // 알림 서비스 초기화
    final notifService = NotificationService();
    await notifService.initialize();

    // Android 13+ 알림 권한 요청
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // iOS 알림 권한 요청
    await notifService.requestPermission();

    // 백그라운드 작업 등록 — 실패해도 앱은 계속 실행
    try {
      final pushScheduler = WorkmanagerPushScheduler();
      await pushScheduler.initialize();
      await pushScheduler.register();
    } catch (_) {
      // 백그라운드 등록 실패 시 수동 새로고침으로 대체
    }
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
