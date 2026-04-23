import '../../data/models/user_profile.dart';

// ── 페르소나 타입 ─────────────────────────────────────────

enum PersonaType {
  /// 호흡기 + (야외 OR 체감) → 세심한 케어형
  compound,

  /// 호흡기만 (야외·체감 낮음) → 섬세한 체질형
  medicalCare,

  /// 야외 활동 많음 + 체감 높음 → 활발한 감지형
  activeAndSensitive,

  /// 야외 활동 많음 + 체감 낮음 → 야외 라이프형
  activeOutdoor,

  /// 활동 낮음 + 체감 높음 → 예민한 감지형
  sensitiveFeel,

  /// 해당 없음 → 균형 유지형
  general,
}

// ── 근거 항목 ─────────────────────────────────────────────

class ReasonItem {
  final String title;
  final String description;
  const ReasonItem({required this.title, required this.description});
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

  /// 기준치 엄격화 근거 목록 (general은 빈 리스트)
  final List<ReasonItem> reasons;

  const Persona({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.keywords,
    required this.actionGuides,
    required this.emoji,
    required this.reasons,
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
    final w1 = _w1(profile); // 호흡기 상태
    final w2 = _w2(profile); // 야외 활동
    final w3 = _w3(profile); // 체감 민감도

    // 기저질환 있음
    if (w1 >= 0.15) {
      if (w2 >= 0.1 || w3 >= 0.1) return PersonaType.compound;
      return PersonaType.medicalCare;
    }

    // 기저질환 없음
    if (w2 >= 0.2 && w3 >= 0.1) return PersonaType.activeAndSensitive;
    if (w2 >= 0.2) return PersonaType.activeOutdoor;
    if (w3 >= 0.2) return PersonaType.sensitiveFeel;

    return PersonaType.general;
  }

  // ── 근거 리스트 생성 (§6.3 규칙) ──────────────────────
  // general이면 빈 리스트. 그 외에는 값이 0이 아닌 모든 조건을
  // 호흡기 → 야외 → 체감 → Tier2(임신 → 피부 시술) 순서로 포함.

  static List<ReasonItem> _buildReasons(UserProfile profile) {
    final reasons = <ReasonItem>[];

    // 호흡기
    switch (profile.respiratoryStatus) {
      case 1:
        reasons.add(const ReasonItem(
          title: '비염',
          description: '코 점막이 먼지에 민감해요. 그래서 기준을 낮췄어요.',
        ));
      case 2:
        reasons.add(const ReasonItem(
          title: '천식',
          description: '적은 농도에도 기관지가 반응해요. 그래서 기준을 낮췄어요.',
        ));
      case 3:
        reasons.add(const ReasonItem(
          title: '비염과 천식',
          description: '코와 기관지가 먼지에 이중으로 반응해요. 그래서 기준을 낮췄어요.',
        ));
    }

    // 야외 활동
    switch (profile.outdoorMinutes) {
      case 1:
        reasons.add(const ReasonItem(
          title: '하루 1~3시간 야외',
          description: '노출 시간이 있는 편이라 평균보다 조금 더 영향을 받아요.',
        ));
      case 2:
        reasons.add(const ReasonItem(
          title: '하루 3시간 이상 야외',
          description: '노출 시간이 길어서 같은 농도여도 영향이 커요.',
        ));
    }

    // 체감 민감도
    switch (profile.sensitivityLevel) {
      case 1:
        reasons.add(const ReasonItem(
          title: '조금 예민한 체질',
          description: '평소 미세먼지 변화를 느끼는 편이잖아요. 그 감각을 반영했어요.',
        ));
      case 2:
        reasons.add(const ReasonItem(
          title: '매우 예민한 체질',
          description: '수치가 낮아도 몸이 먼저 알아채잖아요. 그 감각을 반영했어요.',
        ));
    }

    // Tier 2 — 임신
    if (profile.isPregnant) {
      reasons.add(const ReasonItem(
        title: '임신 중이세요',
        description: '태아에게 미세먼지가 닿지 않도록 더 조심스럽게 설정했어요.',
      ));
    }

    // Tier 2 — 피부 시술
    if (profile.isSkinTreatmentActive) {
      reasons.add(const ReasonItem(
        title: '피부 시술 회복 중',
        description: '자극을 피해야 하는 시기잖아요. 그래서 기준을 더 낮췄어요.',
      ));
    }

    return reasons;
  }

  // ── 페르소나 빌드 ──────────────────────────────────────

  static Persona _build(PersonaType type, UserProfile profile) {
    final conditionLabel = profile.respiratoryStatus > 0
        ? _respiratoryLabel(profile.respiratoryStatus)
        : null;

    final reasons = type == PersonaType.general
        ? const <ReasonItem>[]
        : _buildReasons(profile);

    switch (type) {
      case PersonaType.compound:
        return Persona(
          type: type,
          emoji: '⚡',
          name: '세심한 케어형',
          subtitle: '건강과 일상 둘 다 챙기는 당신에게 맞춘 기준이에요',
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
          reasons: reasons,
        );

      case PersonaType.medicalCare:
        return Persona(
          type: type,
          emoji: '🩺',
          name: '섬세한 체질형',
          subtitle: '증상이 없어도 먼저 반응하는 체질을 고려했어요',
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
          reasons: reasons,
        );

      case PersonaType.activeAndSensitive:
        return Persona(
          type: type,
          emoji: '🌬️',
          name: '활발한 감지형',
          subtitle: '많이 움직이고 빨리 감지하는 당신을 위한 기준이에요',
          description:
              '야외 활동이 많으면서 공기 변화도 금방 느끼는 편이라, '
              '미세먼지에 가장 직접적으로 노출되는 타입이에요. '
              '불편함을 느낄 때는 이미 충분히 마신 후일 수 있어요.',
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
          reasons: reasons,
        );

      case PersonaType.activeOutdoor:
        return Persona(
          type: type,
          emoji: '🏃',
          name: '야외 라이프형',
          subtitle: '바깥 시간이 많은 당신에게 맞는 기준이에요',
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
          reasons: reasons,
        );

      case PersonaType.sensitiveFeel:
        return Persona(
          type: type,
          emoji: '🌡️',
          name: '예민한 감지형',
          subtitle: '공기 변화를 빨리 알아차리는 감각을 반영했어요',
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
          reasons: reasons,
        );

      case PersonaType.general:
        return Persona(
          type: type,
          emoji: '🌿',
          name: '균형 유지형',
          subtitle: '지금 상태라면 기본 기준으로 충분해요',
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
          reasons: const [],
        );
    }
  }

  // ── 내부 가중치 헬퍼 ──────────────────────────────────

  static double _w1(UserProfile p) {
    double w = 0.0;
    if (p.respiratoryStatus & 2 != 0) w += 0.30;
    if (p.respiratoryStatus & 1 != 0) w += 0.15;
    return w;
  }

  static double _w2(UserProfile p) {
    if (p.outdoorMinutes == 2) return 0.2;
    if (p.outdoorMinutes == 1) return 0.1;
    return 0.0;
  }

  static double _w3(UserProfile p) {
    if (p.sensitivityLevel == 2) return 0.2;
    if (p.sensitivityLevel == 1) return 0.1;
    return 0.0;
  }

  static String _respiratoryLabel(int status) {
    final hasRhinitis = status & 1 != 0;
    final hasAsthma   = status & 2 != 0;
    if (hasRhinitis && hasAsthma) return '비염·천식';
    if (hasAsthma)                return '천식 등 호흡기 질환';
    if (hasRhinitis)              return '비염';
    return '';
  }
}
