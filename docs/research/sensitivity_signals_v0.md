# 잠재 민감군 신호 카탈로그 v0

작성일: 2026-05-06  
작성자: Lead Claude (1차 초안) — AI 추론 포함, **출처 검증 필수**  
검증자: yulgok (출처 URL 클릭 검증 — 며칠 내 분산)  
후속: R&D Phase 2~3 (가중치 매핑·사용자 검증) → Phase 4 (온보딩 통합)

---

## 이 문서의 목적

mask_alert가 잠재 민감군을 정확히 식별하기 위한 **신호 풀**. 30~50개 의학 근거 있는 신호를 카테고리별로 모음. 모든 신호에 출처 명시. yulgok 검증 후 Phase 2에서 가중치 매핑 → Phase 3에서 사용자 데이터로 예측력 검증 → Phase 4에서 검증 통과한 10~15개를 온보딩·자기 점검 기능에 통합.

### ⚠️ 중요 제약
- **모든 신호는 가능성 시사일 뿐, 진단 아님.** 의료법 준수.
- **출처는 yulgok이 직접 클릭 검증 후 사용.** AI hallucination 위험.
- **경고 임계값 약함**: 의학 검사 (피부단자검사, IgE, FEV1 등)에 비해 신호의 통계적 예측력은 약함. 가중치 작게 적용 권장.

---

## 자료원 일람 (yulgok 검증 대상)

| ID | 자료원 | URL |
|----|--------|-----|
| **S1** | ARIA — Allergic Rhinitis and its Impact on Asthma (JACI 2019) | https://www.jacionline.org/article/S0091-6749(19)31187-X/fulltext |
| **S2** | ATS Clinical Practice Guideline: Exercise-induced Bronchoconstriction (2013) | https://www.atsjournals.org/doi/full/10.1164/rccm.201303-0437ST |
| **S3** | WHO Global Air Quality Guidelines 2021 | https://www.who.int/publications/i/item/9789240034228 |
| **S4** | Asthma Control Test (ATS) | https://www.thoracic.org/members/assemblies/assemblies/srn/questionaires/act.php |
| **S5** | COPD Assessment Test (CAT) — MDCalc | https://www.mdcalc.com/calc/10161/copd-assessment-test-cat |
| **S6** | GOLD COPD Pocket Guide 2018 | https://goldcopd.org/wp-content/uploads/2018/02/WMS-GOLD-2018-Feb-Final-to-print-v2.pdf |
| **S7** | Chronic Bronchitis Symptoms Assessment Scale | https://www.tandfonline.com/doi/full/10.1081/COPD-57580 |
| **S8** | Framingham Risk Score (MDCalc) | https://www.mdcalc.com/calc/38/framingham-risk-score-hard-coronary-heart-disease |
| **S9** | STOP-BANG Sleep Apnea Questionnaire (Official) | http://www.stopbang.ca/osa/screening.php |
| **S10** | STOP-BANG (MDCalc) | https://www.mdcalc.com/calc/3992/stop-bang-score-obstructive-sleep-apnea |
| **S11** | Nonspecific Airway Hyperresponsiveness — Cold Air & Exercise (CHEST 1988) | https://pubmed.ncbi.nlm.nih.gov/3286138/ |
| **S12** | Cold Air at -15°C and Exercise Airway Symptoms (Eur J Appl Physiol 2022) | https://link.springer.com/article/10.1007/s00421-022-05004-3 |
| **S13** | Mechanisms of Airway Hyperresponsiveness (JACI) | https://www.jacionline.org/article/S0091-6749(06)01511-9/fulltext |
| **S14** | 알레르기 비염의 진단 (대한내과학회지) | https://www.ekjm.org/upload/kjm-85-5-452-2.pdf |
| **S15** | 대한천식알레르기학회 (KAAACI) | https://www.allergy.or.kr |
| **S16** | EIB Prevalence·Pathophysiology Review (NPJ Primary Care Respir Med 2018) | https://www.nature.com/articles/s41533-018-0098-2 |

> **검증 체크리스트** (각 URL마다):
> - [ ] URL이 진짜 열리나? (404 X)
> - [ ] 페이지 제목/저자가 우리 인용과 맞나?
> - [ ] 본문에 우리 신호 내용이 진짜 있나?
> - [ ] 권위 있는 학회·저널·기관인가?

---

## 신호 풀 (카테고리별)

### A. 호흡기 — 알레르기성 비염 (ARIA 기반) [10개]

| # | 일반인 언어 신호 | 의학 용어 | 출처 | 잠재군 강도 |
|---|----------------|----------|------|-----------|
| A1 | 콧물·코막힘·재채기·코 가려움 중 2가지 이상이 4일 이상 / 주 지속 | ARIA Persistent AR | S1, S15 | **강** |
| A2 | 위 증상이 일년에 4주 이상 (계절성·연중) | ARIA Intermittent vs Persistent | S1, S15 | **강** |
| A3 | 꽃가루·먼지·동물 털·곰팡이 같은 환경 자극 후 코 증상이 시작 | IgE-mediated allergic response | S1, S14 | **강** |
| A4 | 알레르기 검사 (피부단자검사·혈청 특이 IgE) 받은 적 있고 양성 | Confirmed AR via skin/IgE test | S1, S14 | **강** (확정에 가까움) |
| A5 | 가족 (부모·형제) 중 알레르기 비염·천식 있음 | Atopic family history | S1, S14 | 중 |
| A6 | 환절기·계절 변화 시 코 증상 심해짐 | Seasonal AR pattern | S1 | 중 |
| A7 | 콧물·코막힘으로 수면이 자주 방해 | AR-related sleep impairment | S1 | 중 |
| A8 | 코 증상 외 눈 가려움·눈물 동반 | Allergic conjunctivitis | S1 | 중 |
| A9 | 어린 시절 비염·천식 진단·치료 이력 (현재 무증상도) | Childhood respiratory atopy | S1, S14 | 중 |
| A10 | 코 막힘이 오래 지속되어 입으로 호흡 | Chronic mouth breathing | S1, S14 | 약 |

### B. 호흡기 — 천식 (ACT 기반) [7개]

| # | 일반인 언어 신호 | 의학 용어 | 출처 | 잠재군 강도 |
|---|----------------|----------|------|-----------|
| B1 | 천식 증상으로 야간·새벽 깬 적 (최근 4주) | Nocturnal asthma symptoms | S4 | **강** |
| B2 | 응급 흡입제 (벤토린·살부타몰 등) 사용 경험 | Rescue inhaler usage | S4 | **강** (확정 시사) |
| B3 | 쌕쌕거리는 호흡 소리 (wheezing) 들은 적 | Wheezing | S4 | **강** |
| B4 | 가슴 답답함·통증 (운동 외 상황) | Chest tightness/pain | S4 | 중 |
| B5 | 천식이 일상 활동·업무·운동 제한 | Activity limitation | S4 | 중 |
| B6 | 마른 기침이 오래 지속 (4주 이상) | Chronic cough | S4, S7 | 중 |
| B7 | 천식·기관지염 진단·치료 이력 | Prior asthma diagnosis | S4 | **강** (확정에 가까움) |

### C. 호흡기 — 운동 유발 기관지수축 (EIB, ATS 기반) [5개]

| # | 일반인 언어 신호 | 의학 용어 | 출처 | 잠재군 강도 |
|---|----------------|----------|------|-----------|
| C1 | 운동 시작 5~10분 후 기침·가슴 답답함·쌕쌕거림 | EIB symptoms post-exercise | S2, S16 | **강** |
| C2 | 운동 후 회복 시간 평소보다 길어짐 (호흡) | Prolonged exercise recovery | S16 | 중 |
| C3 | 찬 공기 마시며 운동 시 호흡 곤란 가중 | EIB + cold air sensitivity | S2, S11, S12 | **강** |
| C4 | 격렬한 운동·달리기 후 가래·점액 증가 | Increased mucus post-exercise | S2 | 중 |
| C5 | 천식 진단 외에 EIB 단독 진단 받은 적 | Isolated EIB diagnosis | S2 | **강** |

### D. 호흡기 — 만성 기관지염 / COPD (CAT·GOLD·CB Scale 기반) [8개]

| # | 일반인 언어 신호 | 의학 용어 | 출처 | 잠재군 강도 |
|---|----------------|----------|------|-----------|
| D1 | 거의 매일 기침이 있다 | Chronic cough | S5, S7 | 중 |
| D2 | 기침할 때 가래·점액이 동반 | Chronic productive cough | S5, S7 | **강** |
| D3 | 겨울·아침 기상 시 가래 동반 기침 (3개월 이상) | Classic chronic bronchitis definition | S7 | **강** |
| D4 | 가슴이 답답하다 (조이는 느낌) | Chest tightness (CAT Q3) | S5, S6 | 중 |
| D5 | 계단 오르기·언덕 오를 때 평소보다 숨이 참 | Dyspnea on exertion | S5, S6 | 중 |
| D6 | 평지 보통 속도 걸을 때 또래보다 빨리 숨이 참 | mMRC 2+ dyspnea | S6 | **강** |
| D7 | 흡연력 (현재·과거) + 호흡 증상 | Smoker with respiratory symptoms | S6 | **강** |
| D8 | 활동 후 회복에 시간이 길어짐 | Reduced exercise tolerance | S5 | 중 |

### E. 환경 노출 반응 — 비특이 기도 과민성 [4개]

| # | 일반인 언어 신호 | 의학 용어 | 출처 | 잠재군 강도 |
|---|----------------|----------|------|-----------|
| E1 | 찬 공기 마실 때 기침·재채기 발작 | Cold-air bronchial reactivity | S11, S12 | **강** |
| E2 | 강한 향수·매연·연기에 코·기침 반응 | Non-specific irritant reactivity | S11, S13 | 중 |
| E3 | 미세먼지 "보통"인 날도 평소보다 호흡 답답·목 칼칼 | Subclinical airway sensitivity | S3, S11 | 중 |
| E4 | 황사·꽃가루 시즌에 컨디션 떨어짐 (전반적) | Environmental sensitivity (composite) | S1, S3 | 중 |

### F. 심혈관 위험 (Framingham 기반 — 객관 측정 한계) [6개]

> **주의**: Framingham은 혈압·콜레스테롤 객관 측정이 핵심. 자가 보고로는 정확도 낮음. 신호로만 사용, 가중치 약하게.

| # | 일반인 언어 신호 | 의학 용어 | 출처 | 잠재군 강도 |
|---|----------------|----------|------|-----------|
| F1 | 고혈압 진단 받은 적 (또는 약 복용 중) | Diagnosed HTN | S8 | **강** |
| F2 | 고지혈증·콜레스테롤 약 복용 중 | Treated dyslipidemia | S8 | **강** |
| F3 | 당뇨병 (제1형·제2형) | DM | S8 | **강** |
| F4 | 가족 (부모·형제) 중 50세 이전 심혈관 사건 | Premature CVD family history | S8 | 중 |
| F5 | 활동 시 흉통·압박감 | Angina-like symptoms | S8 | **강** (즉시 의료 권고) |
| F6 | 다리 부종·심한 두근거림 자주 | Edema / Palpitations | S8 | 중 |

### G. 수면 무호흡 (STOP-BANG 기반) [4개]

> 수면 무호흡 → 만성 저산소 → 미세먼지 노출 시 영향 증폭 가능. 간접 표지.

| # | 일반인 언어 신호 | 의학 용어 | 출처 | 잠재군 강도 |
|---|----------------|----------|------|-----------|
| G1 | 큰 코골이 (옆방까지 들리는 수준) | Loud snoring | S9, S10 | 중 |
| G2 | 낮 졸림이 심함 (회의·운전 중) | Daytime sleepiness | S9, S10 | 중 |
| G3 | 자다가 숨 멈춘 적 있다고 가족 지적 | Observed apnea | S9, S10 | **강** |
| G4 | 기상 시 두통·입 마름 자주 | Morning headache / Dry mouth | S9, S10 | 약 |

### H. 일반 호흡기 (WHO 대기오염) [4개]

| # | 일반인 언어 신호 | 의학 용어 | 출처 | 잠재군 강도 |
|---|----------------|----------|------|-----------|
| H1 | 미세먼지 높은 날 평소보다 숨 참·기침 | PM-induced respiratory symptoms | S3 | 중 |
| H2 | 산불 연기·연무 시즌 명확한 컨디션 저하 | Wildfire smoke sensitivity | S3 | 중 |
| H3 | 야외 활동·운동·외근이 매일 1시간 이상 | High outdoor exposure | S3 | 약 (노출 강도 표지) |
| H4 | 미세먼지 측정값 알림으로 일상 행동 변경 경험 | Self-perceived sensitivity | S3 | 약 |

---

## 신호 풀 요약

| 카테고리 | 신호 수 | 강도 분포 |
|---------|--------|----------|
| A. 알레르기성 비염 | 10 | 강 4 / 중 5 / 약 1 |
| B. 천식 | 7 | 강 4 / 중 3 |
| C. EIB | 5 | 강 3 / 중 2 |
| D. 만성 기관지염·COPD | 8 | 강 5 / 중 3 |
| E. 비특이 기도 과민성 | 4 | 강 1 / 중 3 |
| F. 심혈관 | 6 | 강 4 / 중 2 |
| G. 수면 무호흡 | 4 | 강 1 / 중 2 / 약 1 |
| H. 일반 (WHO) | 4 | 중 2 / 약 2 |
| **합계** | **48** | **강 22 / 중 22 / 약 4** |

→ **48개 신호 풀 확보**. R&D Phase 2~3에서 사용자 데이터로 예측력 검증 → Phase 4에서 검증 통과한 10~15개로 압축.

---

## yulgok 검증 가이드

### 1단계 — 자료원 16개 URL 클릭 검증
위 §자료원 일람 표의 URL 16개 모두 클릭. 다음 확인:
- [ ] 페이지가 열리나
- [ ] 우리가 적은 자료원 이름이 페이지에 있나
- [ ] 권위 있는 학회·저널인가

검증 통과 못 한 URL → 본문에서 그 자료원 ID 박힌 신호 모두 폐기.

### 2단계 — 신호별 본문 확인 (선택, 깊은 검증)
의심 가는 신호 (특히 "강"으로 표시된 것)에 한해 자료 본문에서 해당 신호 정의 진짜 있는지 확인.

### 3단계 — yulgok 추가 의견
- 빠진 신호 있는지 (한국 특유 표현, 문화 차이)
- 너무 의학적이라 일반인에게 안 와닿는 것 있는지
- 강도 평가 동의·비동의

→ 검증 결과를 이 문서에 직접 메모로 남겨도 됨. 또는 별도 `sensitivity_signals_v0_review.md` 작성.

---

## 다음 단계 (Phase 2~3)

### Phase 2 — 신호 → W_health 가중치 매핑 (산출물: `signal_weight_mapping_v0.md`)
- 검증 통과 신호별 W_health 가중치 후보 (예: A1 → +0.05, B1 → +0.10)
- 카테고리 cap 정의 (호흡기 0.30 등 — 기존 `ThresholdConfig`)
- 1.0.x 알파에서 신호 질문 1~3개 추가 시 어느 신호 우선 도입할지

### Phase 3 — 사용자 데이터 검증 (출시 + 28~84일)
- 1.0.x 사용자에게 신호 답변 받기
- 답변 패턴 + 실제 행동 (알림 액션·재설치·리뷰 톤) 상관 분석
- 예측력 약한 신호 폐기, 강한 신호만 남김

### Phase 4 — 통합 (출시 + 84일 ~)
- 검증 통과 10~15개를 온보딩 1~3 질문으로 압축
- 별도 자기 점검 기능 (사이클 #9 or #10)

---

## 변경 이력

- 2026-05-06: v0 작성 (Lead Claude 1차 초안, 48개 신호, 16개 자료원)
- (TBD): yulgok URL 검증 결과 반영 → v0.1
- (TBD): Phase 2 매핑 시작
