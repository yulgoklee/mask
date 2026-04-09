import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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

  final prefs = await SharedPreferences.getInstance();

  if (firebaseReady) {
    // Flutter 에러 → Crashlytics로 전송
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // 비동기 에러 → Crashlytics로 전송
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // 익명 사용자 ID 설정 — 크래시 리포트 추적용
    final userId = _getOrCreateUserId(prefs);
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    await FirebaseAnalytics.instance.setUserId(id: userId);
  }

  if (!kIsWeb) {
    // AdMob 초기화
    await MobileAds.instance.initialize();

    // 알림 서비스 초기화
    final notifService = NotificationService();
    await notifService.initialize();

    // 알림 권한 요청 — 온보딩 완료된 기존 사용자만
    // 신규 사용자는 permission_screen.dart에서 맥락과 함께 요청
    final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
    if (onboardingDone) {
      final notifStatus = await Permission.notification.status;
      if (notifStatus.isDenied) {
        final result = await Permission.notification.request();
        if (result.isPermanentlyDenied && firebaseReady) {
          FirebaseCrashlytics.instance.log('notification_permission_permanently_denied');
        }
      }
      await notifService.requestPermission();
    }

    // 백그라운드 작업 등록 — 실패해도 앱은 계속 실행
    try {
      final pushScheduler = WorkmanagerPushScheduler();
      await pushScheduler.initialize();
      await pushScheduler.register();
    } catch (e, st) {
      // 백그라운드 등록 실패 → Crashlytics 기록
      if (firebaseReady) {
        FirebaseCrashlytics.instance.recordError(e, st,
            fatal: false, reason: 'background_scheduler_register_failed');
      }
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

/// 익명 사용자 ID 조회 또는 생성 (앱 삭제 전까지 유지)
String _getOrCreateUserId(SharedPreferences prefs) {
  const key = 'anonymous_user_id';
  final existing = prefs.getString(key);
  if (existing != null) return existing;
  final newId = const Uuid().v4();
  prefs.setString(key, newId);
  return newId;
}
