import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/dust_providers.dart';
import '../../../providers/profile_providers.dart';
import '../models/care_models.dart';

// ── StatusCard Provider ───────────────────────────────────

final statusCardProvider = Provider<StatusCardData>((ref) {
  final dustAsync = ref.watch(dustDataProvider);
  final profile = ref.watch(profileProvider);

  return dustAsync.when(
    data: (dust) {
      final pm25 = dust?.pm25Value?.toDouble() ?? 0;
      final tFinal = profile.tFinal;
      final status = resolveStatus(pm25, tFinal);
      final nickname = profile.nickname.isNotEmpty ? profile.nickname : '사용자';
      final multiplier = ((profile.sensitivityIndex - 0.1) / 0.05).clamp(1.0, 8.0).toDouble();
      final overRatio = tFinal > 0 ? double.parse((pm25 / tFinal).toStringAsFixed(1)) : 0.0;

      return StatusCardData(
        status: status,
        emoji: _emoji(status),
        title: _title(status),
        personalizedText: _personalText(status, nickname, pm25, tFinal, profile.respiratoryLabel, multiplier),
        actionGuide: _actionGuide(status, tFinal, pm25, overRatio),
        pm25Value: pm25,
        tFinal: tFinal,
        sensitivityMultiplier: multiplier,
        nickname: nickname,
        respiratoryStatus: profile.respiratoryStatus,
        overRatio: overRatio,
      );
    },
    loading: () => StatusCardData.placeholder(),
    error: (_, __) => StatusCardData.placeholder(),
  );
});

String _emoji(CardStatus s) => switch (s) {
  CardStatus.safe    => '😊',
  CardStatus.caution => '😷',
  CardStatus.danger  => '🚨',
};

String _title(CardStatus s) => switch (s) {
  CardStatus.safe    => '오늘은 안전해요',
  CardStatus.caution => '마스크를 챙기세요',
  CardStatus.danger  => '마스크 착용이 필요해요',
};

String _personalText(CardStatus s, String nickname, double pm25, double tFinal,
    String respLabel, double multiplier) =>
    switch (s) {
      CardStatus.safe => '$nickname님의 $respLabel + 현재 PM2.5(${pm25.toInt()}µg/m³)\n→ 현재는 안전한 수준이에요.',
      CardStatus.caution =>
          '$nickname님은 일반인보다 ${multiplier.toStringAsFixed(1)}배 예민한 상태예요.\n현재 PM2.5가 개인 기준치(${tFinal.toInt()}µg/m³)에 근접했어요.',
      CardStatus.danger =>
          '현재 PM2.5(${pm25.toInt()})가 $nickname님 기준치(${tFinal.toInt()})를\n초과했어요. 외출 시 반드시 KF94를 착용하세요.',
    };

String _actionGuide(CardStatus s, double tFinal, double pm25, double overRatio) =>
    switch (s) {
      CardStatus.safe    => '오늘은 걱정 없이 외출하셔도 좋아요.',
      CardStatus.caution => '마스크를 챙기시면 더 안전해요.',
      CardStatus.danger  => 'KF94 마스크 착용이 필요한 수준이에요.',
    };

// ── ProtectionAreaChart Provider ──────────────────────────

final protectionChartProvider = FutureProvider<ProtectionChartData>((ref) async {
  final profile = ref.watch(profileProvider);
  final dustAsync = ref.watch(dustDataProvider);
  final forecastAsync = ref.watch(tomorrowForecastProvider);

  final dust = dustAsync.valueOrNull;
  final forecastGrade = forecastAsync.valueOrNull;

  final forecastMid = gradeToMidpoint(forecastGrade);
  final currentPm25 = dust?.pm25Value?.toDouble() ?? forecastMid;

  final airSpots = buildChartPoints(
    currentPm25: currentPm25,
    forecastMid: forecastMid,
  );

  return ProtectionChartData(
    airSpots: airSpots,
    maskSpots: buildMaskSpots(airSpots, 0.94),
    tFinal: profile.tFinal,
    filterRate: 0.94,
    maskType: 'KF94',
    hasForecastData: forecastGrade != null,
    generatedAt: DateTime.now(),
  );
});

// ── PollutantDetailCard Provider ──────────────────────────

final pollutantCardProvider = Provider<PollutantCardData>((ref) {
  final dustAsync = ref.watch(dustDataProvider);
  return dustAsync.when(
    data: (dust) {
      if (dust == null) return PollutantCardData.placeholder();
      return PollutantCardData(
        pm25: dust.pm25Value?.toDouble(),
        pm10: dust.pm10Value?.toDouble(),
        pm25Grade: dust.pm25Grade,
        pm10Grade: dust.pm10Grade,
        o3: dust.o3Value?.toDouble(),
        no2: dust.no2Value?.toDouble(),
        o3Grade: dust.o3Grade,
        no2Grade: dust.no2Grade,
      );
    },
    loading: () => PollutantCardData.placeholder(),
    error: (_, __) => PollutantCardData.placeholder(),
  );
});
