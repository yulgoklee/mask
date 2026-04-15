/// 미세먼지 방어량 → 건강 비유 변환 유틸
///
/// 계산 근거:
///  - 성인 평균 흡입량: 0.5 m³/h (안정 시 ~ 가벼운 활동)
///  - KF94 차단율: 94%  /  KF80 차단율: 80%
///  - 담배 1개비 흡입 PM2.5 ≈ 12 μg (WHO/연구 평균)
///  - 서울 지하철 30분 노출 PM2.5 ≈ 8 μg (비교 지표)
class HealthCalculator {
  HealthCalculator._();

  static const double breathingRateM3PerHour = 0.5;
  static const double kf94Efficiency = 0.94;
  static const double kf80Efficiency = 0.80;

  /// 담배 1개비 기준 흡입 PM2.5 (μg)
  static const double ugPerCigarette = 12.0;

  /// 서울 지하철 30분 노출 기준 PM2.5 (μg, 비교용)
  static const double ugPerSubway30min = 8.0;

  // ── 방어량 계산 ───────────────────────────────────────────

  /// PM2.5 농도·마스크 종류·노출 시간 → 방어한 미세먼지 질량(μg)
  static double blockedMassUg({
    required int pm25,
    required String maskType,
    int exposureMinutes = 60,
  }) {
    final efficiency = maskType == 'KF94' ? kf94Efficiency : kf80Efficiency;
    return pm25 * breathingRateM3PerHour * (exposureMinutes / 60.0) * efficiency;
  }

  // ── 비유 변환 ────────────────────────────────────────────

  /// μg → 담배 개비 수 (소수 첫째 자리)
  static double toCigarettes(double massUg) => massUg / ugPerCigarette;

  /// μg → 지하철 30분 탑승 횟수 (비교 지표)
  static double toSubwayRides(double massUg) => massUg / ugPerSubway30min;

  // ── 문구 생성 ────────────────────────────────────────────

  /// 방어량을 가장 직관적인 비유 문자열로 반환
  ///
  /// 예: "담배 1.5개비 분량 방어" / "담배 0.3개비 분량 방어"
  static String primaryInsight(double massUg) {
    final cigs = toCigarettes(massUg);
    if (cigs >= 0.1) {
      return '담배 ${cigs.toStringAsFixed(1)}개비 분량을 막았어요';
    }
    return '미세먼지 ${massUg.toStringAsFixed(1)}μg를 막았어요';
  }

  /// 누적 방어량에 대한 한 줄 요약
  static String weeklyInsight(double totalMassUg, int eventCount) {
    if (eventCount == 0) return '이번 주 방어 기록이 없어요';
    final cigs = toCigarettes(totalMassUg);
    final cigText = cigs >= 1
        ? '담배 ${cigs.toStringAsFixed(1)}개비'
        : '${totalMassUg.toStringAsFixed(0)}μg의 미세먼지';
    return '$eventCount번 마스크를 써서\n$cigText 분량을 막았어요 🛡️';
  }

  /// 연속 실천 일수 응원 메시지
  static String streakMessage(int days) {
    if (days == 0) return '오늘부터 방어를 시작해보세요!';
    if (days == 1) return '첫 방어 성공! 내일도 이어가 봐요 💪';
    if (days < 7) return '$days일 연속 실천 중! 잘하고 있어요 👍';
    if (days < 30) return '$days일 연속! 훌륭한 습관이에요 🌟';
    return '$days일 연속! 건강 수호자예요 🏆';
  }

  // ── 주간 데이터 집계 헬퍼 ─────────────────────────────────

  /// 날짜별 방어량 집계 (최근 7일)
  /// 반환: [dayIndex 0=오늘, 1=어제 ...] → blockedMassUg 합계
  static List<double> dailyTotals(
    List<({DateTime timestamp, double blockedMassUg})> records, {
    int days = 7,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totals = List<double>.filled(days, 0.0);

    for (final r in records) {
      final recordDay =
          DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day);
      final diff = today.difference(recordDay).inDays;
      if (diff >= 0 && diff < days) {
        totals[diff] += r.blockedMassUg;
      }
    }
    return totals; // index 0 = 오늘, index 6 = 6일 전
  }
}
