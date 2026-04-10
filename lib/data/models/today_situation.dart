import '../../core/constants/dust_standards.dart';

/// Tier 3 — 오늘의 상황 (당일 자동 만료)
///
/// 야외 운동 예정, 몸 상태 안 좋음처럼
/// 오늘 하루만 마스크 기준을 높여야 하는 상황을 나타낸다.
class TodaySituation {
  final TodaySituationType type;

  /// 이 상황이 설정된 날짜 (앱 재시작 후 날짜가 바뀌면 자동 만료)
  final DateTime date;

  const TodaySituation({
    required this.type,
    required this.date,
  });

  // ── 활성 여부 (오늘 날짜와 같은지 확인) ─────────────────────

  bool get isActive {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // ── 마스크 판단 기준 ──────────────────────────────────────

  DustGrade get maskThresholdGrade {
    switch (type) {
      case TodaySituationType.outdoorExercise:
      case TodaySituationType.feelingUnwell:
        return DustGrade.normal; // 보통(16+)부터
    }
  }

  String get maskType {
    switch (type) {
      case TodaySituationType.outdoorExercise:
      case TodaySituationType.feelingUnwell:
        return 'KF80';
    }
  }

  String get label => type.label;

  // ── 직렬화 ───────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'date': date.toIso8601String(),
      };

  factory TodaySituation.fromJson(Map<String, dynamic> json) => TodaySituation(
        type: TodaySituationType.values[json['type'] as int],
        date: DateTime.parse(json['date'] as String),
      );
}

// ── 오늘의 상황 종류 ──────────────────────────────────────

enum TodaySituationType {
  outdoorExercise,
  feelingUnwell;

  String get label {
    switch (this) {
      case TodaySituationType.outdoorExercise:
        return '오늘 야외 운동 예정';
      case TodaySituationType.feelingUnwell:
        return '오늘 몸 상태 안 좋음';
    }
  }

  String get description {
    switch (this) {
      case TodaySituationType.outdoorExercise:
        return '호흡량 증가로 흡입량 급증 — 보통(16+) 이상 KF80';
      case TodaySituationType.feelingUnwell:
        return '면역 저하 상태 — 보통(16+) 이상 KF80';
    }
  }
}
