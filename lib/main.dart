import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // P4: AdMob 비활성화
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/database/local_database.dart';
import 'core/services/air_korea_service.dart';
import 'core/services/aqi_polling_service.dart';
import 'core/services/cloud_functions_data_source.dart';
import 'core/services/notification_deep_link.dart';
import 'core/services/notification_service.dart';
import 'core/services/workmanager_push_scheduler.dart';
import 'data/models/notification_log.dart';
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
    // TODO(단계2 테스트 전용): 디버그 빌드에서도 Crashlytics 수집 활성화 — 단계3 전에 제거
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

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
    // AdMob 초기화 — P4: 비활성화
    // await MobileAds.instance.initialize();

    // 알림 서비스 초기화
    final notifService = NotificationService();
    await notifService.initialize();

    // 킬드 상태에서 알림 탭으로 앱이 실행된 경우 딥링크 처리
    try {
      final launchDetails = await notifService.getAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final response = launchDetails!.notificationResponse;
        if (response != null && response.actionId == null) {
          final db = LocalDatabase();
          final log = await db.getLatestNoneLog();
          if (log?.id != null) {
            await db.updateUserAction(log!.id!, UserAction.appOpened);
            final dlType = log.notificationType == NotificationType.safeEntry
                ? 'relief'
                : log.notificationType == NotificationType.dangerEntry
                    ? 'risk'
                    : 'scheduled';
            await NotificationDeepLink.setPendingPayload(type: dlType, logId: log.id);
          } else {
            await NotificationDeepLink.setPendingPayload(type: 'scheduled');
          }
          await db.close();
        }
      }
    } catch (_) {}

    // 알림 권한 요청 — 온보딩 완료된 기존 사용자만
    // 신규 사용자는 permission_screen.dart에서 맥락과 함께 요청
    final onboardingDone = prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;
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
      if (firebaseReady) {
        FirebaseCrashlytics.instance.recordError(e, st,
            fatal: false, reason: 'background_scheduler_register_failed');
      }
    }

    // Zero-day 시딩: 온보딩 완료 사용자의 첫 실행 시 과거 24h 데이터 수집
    if (onboardingDone) {
      _seedAqiDataIfNeeded(prefs);
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

/// Zero-day AQI 시딩 — 비동기 fire-and-forget (앱 시작 블록 없음)
void _seedAqiDataIfNeeded(SharedPreferences prefs) {
  Future.microtask(() async {
    try {
      final db = LocalDatabase();
      final dataSource = AppConfig.cloudFunctionsBaseUrl.isNotEmpty
          ? CloudFunctionsDataSource()
          : AirKoreaService(prefs);
      final polling = AqiPollingService(airKorea: dataSource, db: db);
      await polling.runPollingCycle(prefs: prefs);
      await db.close();
    } catch (_) {
      // 시딩 실패해도 앱 실행에 영향 없음
    }
  });
}

/// 익명 사용자 ID 조회 또는 생성 (앱 삭제 전까지 유지)
String _getOrCreateUserId(SharedPreferences prefs) {
  const key = AppConstants.prefAnonymousUserId;
  final existing = prefs.getString(key);
  if (existing != null) return existing;
  final newId = const Uuid().v4();
  prefs.setString(key, newId);
  return newId;
}
