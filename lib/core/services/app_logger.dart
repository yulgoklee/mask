import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void error(
    Object e,
    StackTrace st, {
    required String reason,
  }) {
    debugPrint('[AppLogger] $reason: $e\n$st');

    if (kIsWeb || kDebugMode) return;

    try {
      FirebaseCrashlytics.instance
          .recordError(e, st, fatal: false, reason: reason);
    } catch (_) {
      // Crashlytics not available — debugPrint above is sufficient
    }
  }
}
