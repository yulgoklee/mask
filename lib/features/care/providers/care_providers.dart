import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/dust_standards.dart';
import '../../../core/utils/dust_calculator.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/dust_providers.dart';
import '../../../providers/profile_providers.dart';
import '../models/care_models.dart';

// ── StatusCard Provider ───────────────────────────────────

final statusCardProvider = Provider<StatusCardData>((ref) {
  final dustAsync  = ref.watch(dustDataProvider);
  final calcResult = ref.watch(dustCalculationProvider);
  final profile    = ref.watch(profileProvider);
  final isLoading  = dustAsync.isLoading;

  if (isLoading) return StatusCardData.placeholder();

  return dustAsync.when(
    data: (dust) {
      final pm25        = dust?.pm25Value ?? 0;
      final pm10        = dust?.pm10Value;
      final tFinal      = profile.tFinal;
      final tFinalPm10  = tFinal * (80.0 / 35.0);
      final multiplier  = (35.0 / tFinal).clamp(1.0, 3.0);
      final pm10ForCalc = pm10; // E-9: 모든 사용자 PM10 반영 (환경부 공식 max 결합)
      final ratioPm25   = tFinal > 0 ? pm25 / tFinal : 0.0;
      final ratioPm10   = (pm10ForCalc != null && tFinalPm10 > 0) ? pm10ForCalc / tFinalPm10 : 0.0;
      final finalRatio  = ratioPm25 > ratioPm10 ? ratioPm25 : ratioPm10;
      final nickname    = profile.nickname.isNotEmpty ? profile.nickname : '사용자';

      // RiskLevel: dustCalculationProvider 우선 (final_ratio 기반),
      // dust null 또는 provider null 시 PM2.5 단독 fallback
      final status = calcResult?.riskLevel
          ?? _resolveRiskLevel(pm25.toDouble(), tFinal);

      // 개인 프로필 기반 서브 카피
      final subCopy = _buildSubCopy(status, profile);

      // 정보 바: DominantPollutant 기반 동적 데이터
      final dominant = calcResult?.dominantPollutant ?? DominantPollutant.pm25;

      final int    dominantValue;
      final double dominantTFinal;
      final DustGrade dominantGrade;

      if (dominant == DominantPollutant.pm10 && pm10 != null) {
        dominantValue  = pm10;
        dominantTFinal = tFinal * (80.0 / 35.0);
        dominantGrade  = DustStandards.getPm10Grade(pm10);
      } else {
        dominantValue  = pm25;
        dominantTFinal = tFinal;
        dominantGrade  = DustStandards.getPm25Grade(pm25);
      }

      return StatusCardData(
        status:              status,
        emoji:               _emoji3(finalRatio),
        title:               _title3(finalRatio, tFinal),
        subCopy:             subCopy,
        dominantPollutant:   dominant,
        dominantValue:       dominantValue,
        dominantTFinal:      dominantTFinal,
        dominantGrade:       dominantGrade,
        pm25Value:           pm25.toDouble(),
        pm10Value:           pm10?.toDouble(),
        tFinal:              tFinal,
        finalRatio:          finalRatio,
        sensitivityMultiplier: multiplier,
        nickname:            nickname,
        hasRespiratoryCondition: profile.hasRespiratoryCondition,
      );
    },
    loading: () => StatusCardData.placeholder(),
    error:   (_, __) => StatusCardData.placeholder(),
  );
});

// ── RiskLevel fallback ────────────────────────────────────

// dustCalculationProvider null 시 PM2.5 단독 ratio 사용 (§2.4 임시 fallback)
RiskLevel _resolveRiskLevel(double pm25, double tFinal) {
  final ratio = tFinal > 0 ? pm25 / tFinal : 0.0;
  if (ratio < 0.5) return RiskLevel.low;
  if (ratio < 0.7) return RiskLevel.normal;
  if (ratio < 1.0) return RiskLevel.warning;
  if (ratio < 1.5) return RiskLevel.danger;
  return RiskLevel.critical;
}

// ── E-7: finalRatio 기반 3단계 매핑 ─────────────────────

/// finalRatio → 3단계 이모지 (☺/😷/😨)
String _emoji3(double ratio) {
  if (ratio < 1.0) return '☺️';
  if (ratio < 1.5) return '😷';
  return '😨';
}

/// finalRatio + tFinal → 마스크 답 텍스트
/// tFinal >= 30 → KF80, < 30 → KF94 (E-7 스펙)
String _title3(double ratio, double tFinal) {
  if (ratio < 1.0) return '지금은 OK';
  if (ratio < 1.5) return '마스크 필요 (${tFinal >= 30 ? "KF80" : "KF94"})';
  return '마스크 꼭 (${tFinal >= 30 ? "KF80" : "KF94"})';
}

// ── 카피 매트릭스 (RiskLevel 기반 — subCopy용으로만 유지) ──

String _buildSubCopy(RiskLevel status, UserProfile profile) {
  if (status != RiskLevel.low &&
      status != RiskLevel.normal &&
      status != RiskLevel.unknown) {
    return _personalizedSubCopy(status, profile);
  }
  return _defaultSubCopy(status);
}

String _defaultSubCopy(RiskLevel s) => switch (s) {
  RiskLevel.low      => '공기가 맑아요.',
  RiskLevel.normal   => '오래 밖에 있을 때만 마스크 챙기세요.',
  RiskLevel.warning  => '외출 시 마스크 챙기세요.',
  RiskLevel.danger   => 'KF80 이상 마스크 권장이에요.',
  RiskLevel.critical => '가능하면 실내에서 지내세요.',
  RiskLevel.unknown  => '',
};

String _personalizedSubCopy(RiskLevel status, UserProfile profile) {
  final isHighRisk = status == RiskLevel.danger || status == RiskLevel.critical;
  if (profile.asthma && profile.rhinitis) return '호흡기 보호를 위해 KF94를 권해요.';
  if (profile.asthma) return isHighRisk ? '천식이 있으시니 KF94를 권해요.' : '천식이 있으시니 마스크를 꼭 챙기세요.';
  if (profile.copd)   return isHighRisk ? 'COPD가 있으시니 KF94를 권해요.' : 'COPD가 있으시니 마스크를 꼭 챙기세요.';
  if (profile.rhinitis) return '비염이 있으시니 마스크가 도움돼요.';
  if (profile.allergy)  return '알레르기가 있으시니 마스크를 챙기세요.';
  if (profile.heartDisease) return isHighRisk ? '심장 질환이 있으시니 KF94를 권해요.' : '심장 질환이 있으시니 마스크를 챙기세요.';
  if (profile.stroke)       return '뇌졸중 이력이 있으시니 마스크를 챙기세요.';
  if (profile.hypertension) return '고혈압이 있으시니 마스크를 챙기세요.';
  if (profile.isPregnant)   return '태아 건강을 위해 KF94를 권해요.';
  if (profile.smokingStatus == SmokingStatus.current) return '흡연 중이시니 마스크를 꼭 챙기세요.';
  return _defaultSubCopy(status);
}

// ── ProtectionAreaChart Provider ──────────────────────────

final protectionChartProvider = FutureProvider<ProtectionChartData>((ref) async {
  final profile           = ref.watch(profileProvider);
  final dustAsync         = ref.watch(dustDataProvider);
  final forecastAsync     = ref.watch(tomorrowForecastProvider);
  final forecastPm10Async = ref.watch(tomorrowForecastPm10Provider);

  final dust             = dustAsync.valueOrNull;
  final forecastGrade    = forecastAsync.valueOrNull;
  final forecastGradePm10 = forecastPm10Async.valueOrNull;

  // 실측값이 없으면 noData 반환 (placeholder 애니메이션은 로딩 상태에서 처리)
  if (dust == null) return ProtectionChartData.noData();

  final currentPm25 = dust.pm25Value?.toDouble() ?? 0.0;
  final currentPm10 = dust.pm10Value;
  final tFinalPm25  = profile.tFinal;

  final chartPoints = buildChartPoints(
    tFinalPm25:      tFinalPm25,
    currentPm25:     currentPm25,
    currentPm10:     currentPm10,
    forecastGrade:   forecastGrade,
    forecastGradePm10: forecastGradePm10,
  );

  final verdict = buildChartVerdict(chartPoints);

  return ProtectionChartData(
    chartPoints:     chartPoints,
    tFinal:          tFinalPm25,
    filterRate:      0.94,
    verdict:         verdict,
    hasForecastData: forecastGrade != null,
    generatedAt:     DateTime.now(),
  );
});

// ── PollutantDetailCard Provider ──────────────────────────

final pollutantCardProvider = Provider<PollutantCardData>((ref) {
  final dustAsync = ref.watch(dustDataProvider);
  return dustAsync.when(
    data: (dust) {
      if (dust == null) return PollutantCardData.placeholder();
      return PollutantCardData(
        pm25:     dust.pm25Value?.toDouble(),
        pm10:     dust.pm10Value?.toDouble(),
        pm25Grade: dust.pm25Grade,
        pm10Grade: dust.pm10Grade,
        o3:       dust.o3Value?.toDouble(),
        no2:      dust.no2Value?.toDouble(),
        o3Grade:  dust.o3Grade,
        no2Grade: dust.no2Grade,
        co:       dust.coValue,
        so2:      dust.so2Value,
        coGrade:  dust.coGrade,
        so2Grade: dust.so2Grade,
      );
    },
    loading: () => PollutantCardData.placeholder(),
    error:   (_, __) => PollutantCardData.placeholder(),
  );
});
