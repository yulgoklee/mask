import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/feedback_repository.dart';
import '../../data/models/notification_feedback.dart';
import 'sensitivity_calculator.dart';

/// 피드백 기반 민감도 자동 조정 (5단계 학습 알고리즘)
///
/// ────────────────────────────────────────────────────────────
/// 핵심 공식:
///
///   S_eff = clamp(S_base + sOffset, 0.0, 0.6)
///   T_eff = T_standard × (1 − S_eff)
///
///   sOffset 조정 규칙 (최근 [kWindowSize]건 기준):
///
///   ┌─────────────────────────────────────────────────────┐
///   │ 무시율 > 60%  → 알림 과다  → sOffset -= α (T 상향)  │
///   │ 응답률 > 70%  → 잘 챙김   → sOffset 유지           │
///   │ 응답률 30~70% → 중립      → sOffset 유지            │
///   │ 응답률 < 30%  → 무관심    → sOffset -= α            │
///   └─────────────────────────────────────────────────────┘
///
///   α (학습률) = 0.05  (한 번에 조정 최대 ±0.05)
///   sOffset 범위: −0.3 ~ +0.1  (기저 S를 넘어 너무 낮추지 않도록 하한 설정)
///
/// 설계 의도:
///  - 사용자가 알림을 자꾸 무시한다 → T_final이 올라가 덜 자주 울림
///  - 사용자가 꾸준히 챙긴다 → 현재 설정이 적절하다는 신호 → 유지
///  - 초기 데이터 부족 시 조정 보류 (kMinSamples 미만이면 적용 안 함)
/// ────────────────────────────────────────────────────────────
class AdaptiveLearner {
  AdaptiveLearner._();

  // ── 하이퍼파라미터 ──────────────────────────────────────────
  static const double kAlpha       = 0.05;   // 학습률 (한 스텝 조정량)
  static const double kOffsetMin   = -0.30;  // sOffset 최솟값 (T 최대 상향)
  static const double kOffsetMax   =  0.10;  // sOffset 최댓값 (T 소폭 하향)
  static const int    kWindowSize  = 10;     // 평가 최근 N건
  static const int    kMinSamples  = 3;      // 조정 발동 최소 샘플 수

  static const double kHighIgnoreThreshold = 0.60; // 무시율 ≥ 60% → 과다 알림
  static const double kLowAckThreshold     = 0.30; // 응답률 < 30% → 무관심

  // ── SharedPreferences 키 ───────────────────────────────────
  static const String _prefKeyOffset    = 'adaptive_s_offset';
  static const String _prefKeyLastEval  = 'adaptive_last_eval';
  static const String _prefKeyEvalCount = 'adaptive_eval_count';

  // ── 공개 API ───────────────────────────────────────────────

  /// 저장된 sOffset 반환 (없으면 0.0)
  static double loadOffset(SharedPreferences prefs) =>
      prefs.getDouble(_prefKeyOffset) ?? 0.0;

  /// S_base에 sOffset을 반영한 유효 S 값
  static double effectiveS(double sBase, SharedPreferences prefs) =>
      (sBase + loadOffset(prefs)).clamp(0.0, SensitivityCalculator.sMax);

  /// 유효 S로 계산한 최종 임계치
  static double effectiveThreshold(double sBase, SharedPreferences prefs) =>
      SensitivityCalculator.threshold(effectiveS(sBase, prefs));

  /// 피드백을 평가하고 필요 시 sOffset 갱신
  ///
  /// 스케줄러 `runCheck()` 내에서 알림 발송 전에 호출.
  /// [kMinSamples] 미만이면 조정 없이 반환.
  static Future<void> evaluate(
    SharedPreferences prefs,
    FeedbackRepository feedbackRepo,
  ) async {
    final feedbacks = feedbackRepo.loadAll().take(kWindowSize).toList();
    if (feedbacks.length < kMinSamples) return;

    final total    = feedbacks.length;
    final ignored  = feedbacks.where((f) => f.type == FeedbackType.ignored).length;
    final ackCount = feedbacks.where((f) => f.type == FeedbackType.acknowledged).length;

    final ignoreRate = ignored / total;
    final ackRate    = ackCount / total;

    final currentOffset = loadOffset(prefs);
    double newOffset = currentOffset;

    if (ignoreRate >= kHighIgnoreThreshold) {
      // 무시 과다 → 임계치 상향 (덜 민감하게)
      newOffset -= kAlpha;
      debugPrint('[AdaptiveLearner] 무시율 ${(ignoreRate * 100).toStringAsFixed(0)}% → sOffset -= $kAlpha');
    } else if (ackRate < kLowAckThreshold) {
      // 응답률 부족 → 소폭 상향
      newOffset -= kAlpha * 0.5;
      debugPrint('[AdaptiveLearner] 응답률 저조 → sOffset -= ${kAlpha * 0.5}');
    }
    // ackRate >= 0.30: 유지

    newOffset = newOffset.clamp(kOffsetMin, kOffsetMax);

    if (newOffset != currentOffset) {
      await prefs.setDouble(_prefKeyOffset, newOffset);
      debugPrint('[AdaptiveLearner] sOffset: $currentOffset → $newOffset');
    }

    // 평가 메타 기록
    await prefs.setString(_prefKeyLastEval, DateTime.now().toIso8601String());
    await prefs.setInt(
        _prefKeyEvalCount, (prefs.getInt(_prefKeyEvalCount) ?? 0) + 1);
  }

  /// 사용자가 프로필을 직접 수정했을 때 offset 초기화
  ///
  /// 온보딩 재수행 또는 민감도 설정 변경 시 호출.
  static Future<void> reset(SharedPreferences prefs) async {
    await prefs.remove(_prefKeyOffset);
    await prefs.remove(_prefKeyLastEval);
    await prefs.remove(_prefKeyEvalCount);
    debugPrint('[AdaptiveLearner] sOffset 초기화됨');
  }

  // ── 디버그용 ───────────────────────────────────────────────

  static String debugSummary(SharedPreferences prefs) {
    final offset     = loadOffset(prefs);
    final lastEval   = prefs.getString(_prefKeyLastEval) ?? '없음';
    final evalCount  = prefs.getInt(_prefKeyEvalCount) ?? 0;
    return 'sOffset=$offset  '
        'evalCount=$evalCount  '
        'lastEval=$lastEval';
  }
}
