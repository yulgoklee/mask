/// Diagnosis card widgets — public API barrel.
///
/// 기본정보(통합) + Q4~Q6.1 + Location 카드를 한 진입점으로 모은다.
/// 각 Q 클래스의 실제 정의는 `diagnosis_cards/` 하위 파일에 있고,
/// 본 파일은 export-only barrel이다.
library;

export 'diagnosis_cards/basic_info.dart';        // 신규 — Q1·Q2·Q3 통합
export 'diagnosis_cards/q4_respiratory.dart';
export 'diagnosis_cards/q5_cardiovascular.dart';
export 'diagnosis_cards/signal_self_check.dart';
export 'diagnosis_cards/q6_smoking.dart';
export 'diagnosis_cards/q6p1_smoking_type.dart';
export 'diagnosis_cards/q_location.dart';
