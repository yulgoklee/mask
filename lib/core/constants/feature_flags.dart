/// 기능 토글 플래그 (1.1.0+)
///
/// 정책: 코드는 작성하되 출시 결정은 별개. Phase 3 사용자 검증 통과 후 ON.
/// Remote Config로 override 가능 (firebase_remote_config 통해 런타임 조정).
class FeatureFlags {
  /// 잠재 신호 자가 점검 페이지 (B 작업 1.1.0)
  ///
  /// ON 시 온보딩 Q5 심혈관 다음에 "선택 자가 점검" 페이지 노출.
  /// 4개 신호 (A1·B1·C1·D3) 체크리스트 + "건너뛰기" 버튼.
  /// W_health 가중치에 영향 (이중 카운팅 방지 룰 R1 적용).
  ///
  /// 기본 OFF. Phase 3 검증 후 1.1.0에서 ON 결정.
  static const bool kEnableSignalSelfCheck = false;
}
