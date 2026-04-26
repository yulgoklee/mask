import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/dust_standards.dart';
import '../../../core/utils/dust_calculator.dart';
import '../../../core/utils/persona_generator.dart';
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
      final pm25       = dust?.pm25Value ?? 0;
      final pm10       = dust?.pm10Value;
      final tFinal     = profile.tFinal;
      final multiplier = (35.0 / tFinal).clamp(1.0, 3.0);
      final overRatio  = tFinal > 0
          ? double.parse((pm25 / tFinal).toStringAsFixed(1))
          : 0.0;
      final nickname   = profile.nickname.isNotEmpty ? profile.nickname : '사용자';

      // RiskLevel: dustCalculationProvider 우선 (final_ratio 기반),
      // dust null 또는 provider null 시 PM2.5 단독 fallback
      final status = calcResult?.riskLevel
          ?? _resolveRiskLevel(pm25.toDouble(), tFinal);

      // 페르소나 → 개인화 서브 카피
      final persona = PersonaGenerator.generate(profile);
      final subCopy = _buildSubCopy(status, persona);

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
        emoji:               _emoji(status),
        title:               _title(status),
        subCopy:             subCopy,
        dominantPollutant:   dominant,
        dominantValue:       dominantValue,
        dominantTFinal:      dominantTFinal,
        dominantGrade:       dominantGrade,
        pm25Value:           pm25.toDouble(),
        tFinal:              tFinal,
        sensitivityMultiplier: multiplier,
        nickname:            nickname,
        respiratoryStatus:   profile.respiratoryStatus,
        overRatio:           overRatio,
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
  if (ratio < 1.0) return RiskLevel.normal;
  if (ratio < 1.5) return RiskLevel.warning;
  if (ratio < 2.0) return RiskLevel.danger;
  return RiskLevel.critical;
}

// ── 카피 매트릭스 5단계 (§3.2) ──────────────────────────

String _emoji(RiskLevel s) => switch (s) {
  RiskLevel.low      => '😊',
  RiskLevel.normal   => '🙂',
  RiskLevel.warning  => '😷',
  RiskLevel.danger   => '😷',
  RiskLevel.critical => '🚨',
  RiskLevel.unknown  => '⏳',
};

String _title(RiskLevel s) => switch (s) {
  RiskLevel.low      => '오늘은 안전해요',
  RiskLevel.normal   => '오늘은 괜찮아요',
  RiskLevel.warning  => '마스크를 챙기세요',
  RiskLevel.danger   => '마스크 필수예요',
  RiskLevel.critical => '외출을 자제해주세요',
  RiskLevel.unknown  => '데이터를 불러오는 중',
};

String _buildSubCopy(RiskLevel status, Persona persona) {
  // warning 이상 + reasons 있을 때 → 개인화 카피
  if (status != RiskLevel.low &&
      status != RiskLevel.normal &&
      status != RiskLevel.unknown &&
      persona.reasons.isNotEmpty) {
    return _reasonToCopy(persona.reasons.first, status);
  }
  return _defaultSubCopy(status);
}

String _defaultSubCopy(RiskLevel s) => switch (s) {
  RiskLevel.low      => '편하게 외출하셔도 돼요.',
  RiskLevel.normal   => '장시간 야외라면 마스크를 챙기세요.',
  RiskLevel.warning  => '외출 시 KF80 이상 권장이에요.',
  RiskLevel.danger   => 'KF94 마스크를 착용하세요.',
  RiskLevel.critical => '가능하면 실내에서 지내세요.',
  RiskLevel.unknown  => '',
};

/// ReasonItem.title → 케어 탭 전용 개인화 카피 (§3.2)
///
/// ReasonItem.description은 프로필 탭 전용 — 여기서 직접 사용 금지.
String _reasonToCopy(ReasonItem reason, RiskLevel status) {
  final isHighRisk = status == RiskLevel.danger || status == RiskLevel.critical;
  return switch (reason.title) {
    '천식'                => isHighRisk
        ? '천식이 있으시니 KF94를 권해요.'
        : '천식이 있으시니 마스크를 꼭 챙기세요.',
    '비염'                => '비염이 있으시니 마스크가 도움돼요.',
    '비염과 천식'          => '호흡기 보호를 위해 KF94를 권해요.',
    '하루 3시간 이상 야외' => '바깥 시간이 많은 날엔 더 신경써요.',
    '하루 1~3시간 야외'   => '외출 중엔 마스크를 챙기세요.',
    '매우 예민한 체질'    => '예민한 체질이라 더 조심해요.',
    '조금 예민한 체질'    => '평소보다 조심하시는 게 좋아요.',
    '임신 중이세요'        => '태아 건강을 위해 KF94를 권해요.',
    '피부 시술 회복 중'   => '회복 중이니 외출 시 KF94를 권해요.',
    _                     => _defaultSubCopy(status),
  };
}

// ── ProtectionAreaChart Provider ──────────────────────────

final protectionChartProvider = FutureProvider<ProtectionChartData>((ref) async {
  final profile       = ref.watch(profileProvider);
  final dustAsync     = ref.watch(dustDataProvider);
  final forecastAsync = ref.watch(tomorrowForecastProvider);

  final dust          = dustAsync.valueOrNull;
  final forecastGrade = forecastAsync.valueOrNull;

  // 실측값이 없으면 noData 반환 (placeholder 애니메이션은 로딩 상태에서 처리)
  if (dust == null) return ProtectionChartData.noData();

  final currentPm25 = dust.pm25Value?.toDouble() ?? 0.0;
  final currentPm10 = dust.pm10Value;   // int? — 없으면 ratioPm10=0 처리됨
  final tFinalPm25  = profile.tFinal;

  final chartPoints = buildChartPoints(
    tFinalPm25:   tFinalPm25,
    currentPm25:  currentPm25,
    currentPm10:  currentPm10,
    forecastGrade: forecastGrade,
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
