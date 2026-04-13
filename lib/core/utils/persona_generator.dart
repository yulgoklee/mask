import '../../data/models/user_profile.dart';

// ── 페르소나 타입 ─────────────────────────────────────────

enum PersonaType {
  /// 기저질환 + 높은 활동/민감도 → 복합 위험군
  compound,

  /// 기저질환만 있음 (활동·체감은 낮음) → 의학적 취약형
  medicalCare,

  /// 기저질환 없음 + 야외 활동 많음 + 체감 높음
  activeAndSensitive,

  /// 기저질환 없음 + 야외 활동 많음 + 체감 낮음
  activeOutdoor,

  /// 기저질환 없음 + 활동 낮음 + 체감 높음
  sensitiveFeel,

  /// S 낮음 — 기본 관리 수준
  general,
}

// ── 페르소나 데이터 클래스 ─────────────────────────────────

class Persona {
  final PersonaType type;

  /// 페르소나 이름
  final String name;

  /// 한 줄 서브타이틀
  final String subtitle;

  /// 3~5줄 설명 (케어 언어 톤)
  final String description;

  /// 키워드 태그 리스트
  final List<String> keywords;

  /// 행동 가이드 (알림·생활 팁 2~3개)
  final List<String> actionGuides;

  /// 아이콘 이모지
  final String emoji;

  const Persona({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.keywords,
    required this.actionGuides,
    required this.emoji,
  });
}

// ── PersonaGenerator ──────────────────────────────────────

/// 사용자 프로필 → 페르소나 타입 결정 + 키워드 생성
class PersonaGenerator {
  PersonaGenerator._();

  /// 프로필로부터 페르소나 생성
  static Persona generate(UserProfile profile) {
    final type = _determineType(profile);
    return _build(type, profile);
  }

  // ── 타입 결정 로직 ─────────────────────────────────────

  static PersonaType _determineType(UserProfile profile) {
    final w1 = _w1(profile); // 기저질환
    final w2 = _w2(profile); // 야외 활동
    final w3 = _w3(profile); // 체감 민감도

    // 기저질환 있음
    if (w1 >= 0.2) {
      // 기저질환 + 활동/체감 중간 이상 → 복합 주의
      if (w2 >= 0.1 || w3 >= 0.1) return PersonaType.compound;
      return PersonaType.medicalCare;
    }

    // 기저질환 없음
    if (w2 >= 0.2 && w3 >= 0.1) return PersonaType.activeAndSensitive;
    if (w2 >= 0.2) return PersonaType.activeOutdoor;
    if (w3 >= 0.2) return PersonaType.sensitiveFeel;

    return PersonaType.general;
  }

  // ── 페르소나 빌드 ──────────────────────────────────────

  static Persona _build(PersonaType type, UserProfile profile) {
    final conditionLabel = profile.hasCondition
        ? profile.conditionType.label
        : null;

    switch (type) {
      case PersonaType.compound:
        return Persona(
          type: type,
          emoji: '⚡',
          name: '복합 주의형',
          subtitle: '건강과 생활 모두 세심한 보호가 필요해요',
          description:
              '${conditionLabel != null ? "$conditionLabel이 있으면서 " : ""}야외 활동도 활발한 편이라, '
              '미세먼지 누적 노출이 일반인보다 빠르게 쌓여요. '
              '공기가 "보통"일 때도 이미 몸이 반응하고 있을 수 있어요.',
          keywords: [
            if (conditionLabel != null) conditionLabel,
            '야외 노출 주의',
            '조기 알림 필요',
            'KF94 권장',
          ],
          actionGuides: [
            '외출 30분 전 알림을 확인하는 습관을 들여보세요.',
            'PM2.5 "보통" 수준에서도 장시간 외출엔 KF94를 착용하세요.',
            '실내 복귀 후 손·얼굴 세안을 권장해요.',
          ],
        );

      case PersonaType.medicalCare:
        return Persona(
          type: type,
          emoji: '🩺',
          name: '조용한 취약형',
          subtitle: '증상이 없어 보여도 기관지는 이미 반응 중이에요',
          description:
              '${conditionLabel != null ? "$conditionLabel 보유자로, " : ""}'
              '활동량이 많지 않아 겉으로 잘 드러나지 않지만 '
              '미세먼지 수치가 올라가면 내부적으로 먼저 영향을 받아요. '
              '자각 증상이 없어도 기준을 낮게 유지하는 게 중요해요.',
          keywords: [
            if (conditionLabel != null) conditionLabel,
            '의학적 취약',
            '자각 증상 낮음',
            '선제적 보호',
          ],
          actionGuides: [
            '아침 알림으로 하루 시작 전 공기 상태를 확인하세요.',
            '"보통" 수준이어도 장시간 외출엔 KF80 이상을 챙기세요.',
            '주치의와 미세먼지 기준을 상의해보는 것도 좋아요.',
          ],
        );

      case PersonaType.activeAndSensitive:
        return Persona(
          type: type,
          emoji: '🌬️',
          name: '활동 민감형',
          subtitle: '몸이 먼저 알아채는 당신, 외출이 잦을수록 더 중요해요',
          description:
              '야외 활동이 많으면서 공기 변화도 금방 느끼는 편이라, '
              '미세먼지에 가장 직접적으로 노출되는 타입이에요. '
              '불편함을 느낄 때는 이미 충분히 마실 후일 수 있어요.',
          keywords: [
            '야외 활동형',
            '즉각 체감',
            '누적 노출 주의',
            'KF80 상시 휴대',
          ],
          actionGuides: [
            '외출 전 앱을 꼭 확인하고, 마스크를 가방에 항상 챙겨두세요.',
            '"보통" 수준이어도 운동 전엔 체크 후 결정하세요.',
            '귀가 후 목이 칼칼하다면 수분 섭취를 늘려보세요.',
          ],
        );

      case PersonaType.activeOutdoor:
        return Persona(
          type: type,
          emoji: '🏃',
          name: '야외 활동형',
          subtitle: '건강하지만 노출 시간이 길수록 위험이 쌓여요',
          description:
              '당장 불편함은 잘 못 느끼지만, 야외 활동이 많아 '
              '미세먼지를 하루에 마시는 총량이 꽤 많아요. '
              '누적 노출이 장기적으로 기관지에 영향을 줄 수 있어요.',
          keywords: [
            '야외 활동 많음',
            '누적 노출 주의',
            '주기적 체크 권장',
          ],
          actionGuides: [
            '"나쁨" 예보 날에는 야외 운동을 실내로 대체해보세요.',
            '장시간 외출엔 KF80을 챙기는 습관을 들여보세요.',
            '주 1회 앱으로 내 누적 노출 패턴을 확인해보세요.',
          ],
        );

      case PersonaType.sensitiveFeel:
        return Persona(
          type: type,
          emoji: '🌡️',
          name: '체감 민감형',
          subtitle: '공기 변화를 누구보다 빠르게 느끼는 편이에요',
          description:
              '실내 위주 생활을 하지만 공기가 조금만 탁해져도 '
              '바로 느껴지는 예민한 타입이에요. '
              '주관적 불편함이 실제 수치 변화와 맞닿아 있는 경우가 많아요.',
          keywords: [
            '주관적 민감도 높음',
            '즉각 체감',
            '실내 공기도 주의',
          ],
          actionGuides: [
            '목이 칼칼하거나 눈이 따갑다면 앱에서 현재 수치를 확인하세요.',
            '실내에서도 공기청정기나 환기 타이밍을 신경 써보세요.',
            '"보통" 수준이어도 장시간 외출엔 마스크를 권장해요.',
          ],
        );

      case PersonaType.general:
        return Persona(
          type: type,
          emoji: '🌿',
          name: '일반 관리형',
          subtitle: '지금 수준이라면 공식 기준을 따라도 충분해요',
          description:
              '현재 건강 상태, 활동량, 체감 모두 크게 걱정할 수준은 아니에요. '
              '"나쁨" 예보 날에 마스크를 챙기는 기본 습관이면 충분해요. '
              '향후 상황이 바뀌면 언제든 재진단해보세요.',
          keywords: [
            '공식 기준 적용',
            '기본 관리',
            '상황 대응형',
          ],
          actionGuides: [
            '"나쁨" 예보 날에만 KF80을 착용하면 돼요.',
            '특별한 상태(임신·시술·감기 등)가 생기면 내 상태를 업데이트하세요.',
            '연 2회 진단을 재진행하면 변화를 반영할 수 있어요.',
          ],
        );
    }
  }

  // ── 내부 가중치 헬퍼 (SensitivityCalculator와 동일 기준) ─

  static double _w1(UserProfile p) {
    if (!p.hasCondition) return 0.0;
    return p.severity == Severity.mild ? 0.2 : 0.3;
  }

  static double _w2(UserProfile p) {
    switch (p.activityLevel) {
      case ActivityLevel.low:    return 0.0;
      case ActivityLevel.normal: return 0.1;
      case ActivityLevel.high:   return 0.2;
    }
  }

  static double _w3(UserProfile p) {
    switch (p.sensitivity) {
      case SensitivityLevel.low:    return 0.0;
      case SensitivityLevel.normal: return 0.1;
      case SensitivityLevel.high:   return 0.2;
    }
  }
}
