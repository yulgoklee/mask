import 'package:uuid/uuid.dart';

/// 마스크 착용 방어 기록 — "챙겼어요 ✓" 액션 탭 시 생성
///
/// SharedPreferences에 JSON 배열로 저장.
/// 최근 90일 데이터만 유지 (DefenseRepository에서 관리).
class DefenseRecord {
  final String id;
  final DateTime timestamp;

  /// 알림 발송 시점의 PM2.5 (μg/m³)
  final int pm25;

  /// 사용한 마스크 종류 ('KF80' | 'KF94')
  final String maskType;

  /// 실제 방어한 미세먼지 질량 (μg)
  final double blockedMassUg;

  const DefenseRecord({
    required this.id,
    required this.timestamp,
    required this.pm25,
    required this.maskType,
    required this.blockedMassUg,
  });

  /// 새 기록 생성 — HealthCalculator로 blockedMassUg 자동 계산
  factory DefenseRecord.create({
    required int pm25,
    required String maskType,
    int exposureMinutes = 60,
  }) {
    final mass = _calcBlockedMass(pm25, maskType, exposureMinutes);
    return DefenseRecord(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      pm25: pm25,
      maskType: maskType,
      blockedMassUg: mass,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'pm25': pm25,
        'maskType': maskType,
        'blockedMassUg': blockedMassUg,
      };

  factory DefenseRecord.fromJson(Map<String, dynamic> json) => DefenseRecord(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        pm25: json['pm25'] as int,
        maskType: json['maskType'] as String,
        blockedMassUg: (json['blockedMassUg'] as num).toDouble(),
      );

  // ── 내부 계산 (DefenseRepository·HealthCalculator 순환 방지용) ──

  static const double _breathingRateM3PerHour = 0.5;

  static double _calcBlockedMass(int pm25, String maskType, int minutes) {
    final efficiency = maskType == 'KF94' ? 0.94 : 0.80;
    return pm25 * _breathingRateM3PerHour * (minutes / 60.0) * efficiency;
  }
}
