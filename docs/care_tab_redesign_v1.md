# 케어 탭 리모델링 설계 문서 (v4)

> 프로필 탭 리모델링 완료 후, 케어 탭의 무드·카피·로직을 정비하는 문서.
> 이 문서와 기존 코드가 충돌하면 **질문하세요.** 추측하지 마세요.

---

## 1. 왜 리모델링하는가

### 1.1 현재 상태 진단

**무드 문제**
- 프로필 탭은 "똑똑한 친구" 톤 (공감 + 팩트)
- 케어 탭은 "데이터 분석가" 톤 ("→", "사용자님의 건강함 + 현재 PM2.5(11μg/m³)")
- 같은 앱에서 두 탭이 따로 노는 느낌

**카피 문제**
- 히어로 카드 안에 대제목·설명·숫자·행동지시 4개가 같은 무게로 있어 위계 불명
- "사용자님"은 3인칭 호칭이라 거리감 있음
- "→" 같은 기호는 개발자스러움
- 차트 제목 "12시간 예보"는 건조함
- "지난 7일 평균과 비교하기 →" 등 화살표 기호 혼용

**시각 문제**
- 카드별 모서리 반경 불일치 (20px vs 16px)
- 히어로 카드 배경이 그라디언트 → 페르소나별 색 구분 어려움
- PM10 "보통"인데도 카드 배경이 연초록 (잘못된 시각 신호)
- 차트 Y축 숫자 "66/0" 의미 불명
- 차트 범례 3개 중 "KF94 착용 시" 거의 보이지 않음 (시각 잡음)
- 단위 표기 불일치 ("µg", "μg", "ug" 혼용)
- 페이지 상단에 "케어" 타이틀 없음

**로직 문제 (가장 중요)**
- PM10이 150 이상일 때만 반영 → PM10 "나쁨"(81~150)은 완전히 무시됨
- PM2.5가 좋음이면 PM10이 나빠도 "괜찮아요"라고 하는 버그
- `sensitivity_multiplier` 공식 오류 → "7.0배 예민" 같은 비현실적 숫자 표시
  - 잘못된 공식: `((sensitivityIndex - 0.1) / 0.05).clamp(1.0, 8.0)`
  - 올바른 공식: `35.0 / profile.tFinal` (실제 약 1.0~2.33배)
- 차트 데이터가 PM2.5 단일 축 → 종합 판단 불가

### 1.2 리모델링 방향 (한 문장)

> **대시보드의 뼈대는 유지하되, 데이터 분석가 느낌을 줄이고 친근하게 정보를 전달. 적당히 거리감을 두되 앱을 찾아올 때마다 정확하게 알려준다.**

### 1.3 케어 탭의 본질

**유저가 케어 탭을 여는 순간 머릿속 질문**
- "오늘 마스크 필요해?"
- "지금 외출해도 되나?"
- "몇 시쯤 공기가 괜찮아질까?"

→ 케어 탭은 **"지금 이 순간의 판단"**을 제공하는 공간.
→ 프로필 탭이 "앱이 나를 이해한 결과"라면, 케어 탭은 그 이해를 바탕으로 한 **"오늘의 판단"**.

### 1.4 무드 정의

**프로페셔널한 친구** — 매일 만나는 건 아니지만, 만나면 정확하게 알려주는 지인.

- 친근하되 과하지 않음 ("~이잖아요" 같은 친밀 표현 제외)
- 데이터 기반이되 드러내지 않음 ("→", "±" 같은 개발자 기호 제거)
- 필수 숫자는 노출하되 본문에서 분리 (별도 정보 바로 이동)
- 결론이 1초 안에 오되 근거는 한 줄만 병기

---

## 2. 로직 개편 (설계 핵심)

### 2.1 핵심 변화

기존:
```
위험도 = PM2.5 / T_final 비율로만 판단
PM10은 150 초과일 때만 안전망
```

개선:
```
위험도 = max(PM2.5/T_final_pm25, PM10/T_final_pm10)
PM10도 상시 차등 반영
```

**표준 근거**: 환경부 CAI(통합대기환경지수), 미국 EPA AQI 모두 "각 오염물질 AQI 계산 후 MAX 값 적용" 방식. WHO 2021 가이드라인도 PM2.5/PM10 둘 다 독립 기준 제시.

### 2.2 T_final_pm10 계산

```
T_base_pm25 = 35 µg/m³ (환경부 '보통' 상한)
T_base_pm10 = 80 µg/m³ (환경부 '보통' 상한)
환산 계수: 80/35 ≈ 2.286

T_final_pm10 = T_final_pm25 × 2.286
```

**예시**:
- T_final_pm25 = 19 → T_final_pm10 = 43.4
- T_final_pm25 = 35 → T_final_pm10 = 80.0 (환경부 기본)
- T_final_pm25 = 15 (하한) → T_final_pm10 = 34.3

### 2.3 final_ratio 계산

```dart
double computeFinalRatio(
  double pm25,
  double? pm10,
  double tFinalPm25,
) {
  final ratioPm25 = pm25 / tFinalPm25;
  final tFinalPm10 = tFinalPm25 * (80.0 / 35.0);
  final ratioPm10 = pm10 != null ? pm10 / tFinalPm10 : 0.0;
  return max(ratioPm25, ratioPm10);
}
```

### 2.4 RiskLevel 판정

```
final_ratio < 0.5  → low        (좋음, 편하게 외출)
final_ratio < 1.0  → normal     (보통, 괜찮음)
final_ratio < 1.5  → warning    (나쁨, 마스크 권장)
final_ratio < 2.0  → danger     (매우 나쁨, KF94)
final_ratio ≥ 2.0  → critical   (심각, 외출 자제)
```

**`CardStatus` enum 완전 제거** (v2 결정)
- 케어 탭 전체에서 `dust_calculator.dart`의 `RiskLevel`을 직접 사용
- `care_models.dart`의 `CardStatus` (safe/caution/danger 3단계) 제거
- `resolveStatus()` 함수 제거
- 이유: 정보 풍부한 5단계 enum 유지가 원칙. 3→5단계 매핑 손실 방지.

### 2.5 알림 트리거 정책 (v2 신규)

**Realtime 알림 트리거**

```dart
// 이전
final shouldSendRealtime = ratio >= 2.0 || pm10Emergency;

// 이후
final shouldSendRealtime = finalRatio >= 1.5;
```

- `pm10Emergency` 별도 조건 **제거** — `finalRatio` 계산에 PM10이 이미 포함됨
- 기준을 `2.0`에서 `1.5` (warning 진입)로 낮춤

**야간 방해금지 예외 — 절대값 유지**

```dart
// threshold_engine.dart — 변경 없음
bool isPm25Emergency(double pm25) => pm25 >= 75.0;
bool isPm10Emergency(int? pm10Value) => pm10Value != null && pm10Value >= 150;
```

방해금지 예외는 "객관적 재난 수준"이므로 개인 T_final 무관하게 절대값 기준 유지.
민감 유저를 새벽에 PM2.5=20으로 깨우는 것을 방지.

### 2.6 마스크 타입 판정

```
final_ratio ≥ 1.5 → KF94
final_ratio ≥ 1.0 → KF80
final_ratio < 1.0 → 없음
```

Tier 2 (임신/시술) 기간 상태는 기존과 동일하게 추가 판정. 결과가 더 엄격한 타입으로 덮어씀.

### 2.7 sensitivity_multiplier 수정

```dart
// 이전 (잘못됨)
final multiplier = ((profile.sensitivityIndex - 0.1) / 0.05).clamp(1.0, 8.0);

// 이후 (올바름)
final multiplier = (35.0 / profile.tFinal).clamp(1.0, 3.0);
```

**검증**:
- T_final=35 → 1.0배 (일반인과 동일)
- T_final=19 → 1.84배
- T_final=15 → 2.33배 (최대)

### 2.8 PM10 안전망 제거

기존의 `pm10 > 150` 안전망은 `final_ratio` 로직이 이미 포함하므로 **완전 제거**.
- PM10=150 일반인 기준: 150/80 = 1.875 → danger 등급 → KF94 권고
- 이중 안전망 불필요

### 2.9 차트 데이터 축 변경

**기존**: Y축 = PM2.5 농도 (µg/m³)
**개선**: Y축 = final_ratio (무차원 비율)

- 1.0 지점에 "내 기준선" 점선
- 곡선은 PM2.5와 PM10을 종합한 final_ratio
- 유저 입장에서 "1.0 위인지 아래인지"만 확인하면 됨
- Y축 숫자 자체를 숨김 (기준선 라벨만 "내 기준" 표시)

---

## 3. 카드별 설계

### 3.1 페이지 상단

```
┌─────────────────────────────────┐
│                                 │
│  케어                           │   ← 24px SemiBold, 좌측
│  서울 용산구 · 1시간 전          │   ← 12px Medium, 측정소 + 갱신 시각
│                                 │
└─────────────────────────────────┘
```

- 현재 "케어" 타이틀 없음 문제 해결
- 측정소 이름과 갱신 시각은 타이틀 바로 아래 한 줄
- 페이지 스크롤 시 상단 고정 안 함 (자연 스크롤)

### 3.2 카드 1 — 히어로 (상태 요약)

**레이아웃**

```
┌────────────────────────────────────┐
│ 😊 오늘은 안전해요           [안전] │   ← 상단: 이모지+제목+배지
│                                    │
│ 편하게 외출하셔도 돼요.            │   ← 서브 카피 (한 줄)
│                                    │
│ ─────────────                      │   ← 얇은 구분선
│                                    │
│ PM2.5          내 기준              │   ← 라벨 (동적: PM2.5 또는 PM10)
│  11            19                  │   ← 숫자 (Bold, µg/m³)
│  좋음          기준 이하            │   ← 부가 정보
└────────────────────────────────────┘
```

**정보 바 동적 표시 규칙** (v2 결정)

정보 바의 두 열은 `final_ratio`를 결정한 오염물질에 따라 동적으로 변경:

| 상황 | 왼쪽 라벨 | 왼쪽 숫자 | 오른쪽 라벨 | 오른쪽 숫자 |
|---|---|---|---|---|
| PM2.5 ratio ≥ PM10 ratio | "PM2.5" | pm25 값 (µg/m³) | "내 기준" | tFinal_pm25 (µg/m³) |
| PM10 ratio > PM2.5 ratio | "PM10" | pm10 값 (µg/m³) | "내 기준" | tFinal_pm10 (µg/m³) |

- 왼쪽 부가 정보: 해당 오염물질의 등급 라벨 (`dominantGrade.label` 그대로 — 좋음/보통/나쁨/매우나쁨)
- 오른쪽 부가 정보 (v3 삼분법):
  - `dominantValue < dominantTFinal` → **"기준 이하"**
  - `dominantValue == dominantTFinal` → **"기준 도달"**
  - `dominantValue > dominantTFinal` → **"+${diff}µg 초과"** (diff = dominantValue − dominantTFinal, int)
- 숫자는 항상 절대 농도(µg/m³) 표시. 비율 수치는 UI에 노출하지 않음.

**카피 매트릭스**

| Status | 이모지 | 제목 | 서브 카피 (예시) |
|--|--|--|--|
| safe | 😊 | 오늘은 안전해요 | 편하게 외출하셔도 돼요. |
| normal | 🙂 | 오늘은 괜찮아요 | 장시간 야외라면 마스크를 챙기세요. |
| warning | 😷 | 마스크를 챙기세요 | 외출 시 KF80 이상 권장이에요. |
| danger | 😷 | 마스크 필수예요 | KF94 마스크를 착용하세요. |
| critical | 🚨 | 외출을 자제해주세요 | 가능하면 실내에서 지내세요. |

**개인화 서브 카피 (warning 이상 + 페르소나 근거 있을 때)**

페르소나 reasons 리스트에서 한 가지를 가져와 근거 문장 생성.
- 예: "천식이 있으시니 KF94를 권해요."
- 예: "민감한 체질이라 더 일찍 조심해요."
- 예: "하루 3시간 이상 야외 활동 중이시잖아요."

`균형 유지형` 페르소나는 근거 없이 기본 카피 사용.

**_subCopy 작성 원칙 (v3 신규)**

- `\n` 줄바꿈 **사용 금지** — 카피는 단문 한 문장으로 강제
- 디바이스 너비에 따라 자연 wrap(2줄 이하)은 허용
- 개인화 카피도 단문 한 문장 이내로 작성
- `_reasonToCopy()` 반환값에 줄바꿈 포함 금지

**시각 스펙**

- 배경색: RiskLevel 기반 Lt 색상 (v3 확정 — 기존 DT 토큰 조합)
  - low → safeLt (연초록)
  - normal → primaryLt (연파랑)
  - warning → cautionLt (연노랑)
  - danger → dangerLt (연빨강)
  - critical → dangerLt + **1px DT.danger 보더** (danger와 시각 차별화)
  - unknown → grayLt
  - orangeLt 신규 토큰 추가 금지 (DT 기존 조합으로 해결)
- 배경 그라디언트 제거 → 단일색
- Glassmorphic 제거 → 평면 Container
- 모서리: 16px 고정 (전체 카드 통일)
- 내부 padding: 24px
- 상단 row 구성: 이모지(48px) + 제목(24px SemiBold) + 배지(우측, 12px 캡슐)
- 제목과 서브 카피 사이: 12px
- 구분선: 20px 위아래 여백, 선은 현재 배경색 대비 8% 어두운 톤
- 정보 바 (숫자 2열):
  - 라벨 11px Medium 연한 색
  - 숫자 28px Bold tabular-nums
  - 부가 정보 12px Regular

**배지 매핑**

| Status | 배지 라벨 |
|--|--|
| safe | 안전 |
| normal | 보통 |
| warning | 주의 |
| danger | 나쁨 |
| critical | 심각 |

### 3.3 카드 2 — 12시간 흐름 (하이브리드 차트)

**레이아웃**

```
┌────────────────────────────────────┐
│ 앞으로 12시간                      │   ← 카드 제목
│                                    │
│ 🟢 하루 종일 편하게 지내실 수 있어요 │   ← 결론 한 줄 (강조)
│                                    │
│ ┌─────────────────────────────┐   │
│ │                             │   │
│ │   ━━━━━ [내 기준] ━━━━━     │   │   ← 점선 (1.0 지점)
│ │                             │   │
│ │  ────────                   │   │   ← 곡선 (현재~미래)
│ │  ░░░░░░░░░░                 │   │   ← 곡선 아래 음영
│ │                             │   │
│ │ 지금   낮   저녁   밤        │   │   ← X축 시간대 라벨
│ └─────────────────────────────┘   │
│                                    │
│  지난 7일 평균과 비교  ›           │   ← 링크
└────────────────────────────────────┘
```

**결론 한 줄 매트릭스 (v4 수정 — 추세 기반)**

유저가 이 한 줄만 읽어도 답을 얻도록 설계.

> **⚠️ 데이터 한계 반영**: `tomorrowForecastProvider`는 PM2.5 등급 문자열만 제공.
> 시간별 예보 데이터 없음 → 차트는 현재값 → 내일 등급 중앙값의 **cubic smoothstep 보간 곡선**.
> 따라서 "오후 3시부터 7시까지" 같은 **구체적 시각 표현은 거짓 정보 위험** → 사용 금지.
> 추세(상승/하락/전체) 기반 카피로 대체.

| `ChartVerdict` level | 조건 | 카피 |
|---|---|---|
| `safe` | `peakRatio < 1.0` (12시간 내내 기준 이하) | `🟢 하루 종일 편하게 지내실 수 있어요` |
| `partialIncreasing` | `peakRatio ≥ 1.0` + 곡선 **상승 추세** | `🟡 점차 나빠질 수 있으니 마스크를 챙기세요` |
| `partialDecreasing` | `peakRatio ≥ 1.0` + 곡선 **하락 추세** | `🟢 지금은 주의, 시간이 지나면 좋아져요` |
| `fullDay` | 모든 포인트 `finalRatio ≥ 1.0` | `🔴 오늘은 종일 마스크가 필요해요` |
| `unknown` | 포인트 부족 또는 데이터 없음 | `예보 데이터를 불러오는 중이에요` |

**추세 판단 로직**

```dart
// cubic smoothstep 보간은 단조 변화만 생성 → 양 끝 비교로 충분
bool isIncreasing = chartPoints.last.finalRatio > chartPoints.first.finalRatio;
```

- `partialIncreasing`: 적어도 하나의 포인트가 `≥ 1.0` + `isIncreasing == true`
- `partialDecreasing`: 적어도 하나의 포인트가 `≥ 1.0` + `isIncreasing == false`
- `fullDay`: **첫 포인트(`h=0`)도 포함해서** 모든 포인트 `≥ 1.0`

**`RiskWindow` 제거 (v4 결정)**

시각별 구간(`RiskWindow`) 계산은 보간 데이터의 거짓 정밀도를 유발 → 설계에서 제거.
`ChartVerdict`는 `level` + `peakRatio` + `peakHour` 만 보유. `windows` 필드 없음.

**차트 시각 스펙**

- Y축 숫자 **제거**
- Y축 대신 **기준선 (y=1.0)** 만 표시. 우측에 "내 기준" 라벨 (11px, 보라색)
- X축 라벨: "지금 / 낮 / 저녁 / 밤" (상대적 시간대)
  - 현재 시각 기준 자동 계산
  - 예: 현재 오전 11시라면 지금(11시) / 낮(오후) / 저녁 / 밤
- 곡선: 2px 실선, 색은 배경과 대비 (기본: 진파랑 계열)
- 곡선 아래 영역 음영:
  - 1.0 이하 구간: 연초록 (safeLt 20% opacity)
  - 1.0 초과 구간: 연빨강 (dangerLt 20% opacity)
- 범례 **완전 제거** (차트 자체가 직관적으로 이해되도록)
- "지금" 지점 세로 점선 유지

**링크**
- 우측 하단 "지난 7일 평균과 비교 ›" (chevron_right 아이콘 14px)
- 탭 시 기존 리포트 화면 또는 별도 비교 뷰로 이동 (기존 동작 유지)

**데이터 기반**
- 차트 포인트는 `final_ratio` 단일 값 (`ChartPoint.finalRatio`)
- `ProtectionChartData` 구조 개편 필요 (기존은 PM2.5 µg 기반)
- 그리드 행(`_HourlyRow`)의 PM2.5 수치는 `ChartPoint.rawPm25`로 표시
- 그리드 등급 라벨은 `DustStandards.getPm25Grade(rawPm25)` 위임 (하드코딩 제거)

### 3.4 카드 3 — 세부 수치

**레이아웃**

```
┌────────────────────────────────────┐
│ 세부 수치                          │
│                                    │
│ ┌──────────────┐ ┌──────────────┐ │
│ │ PM2.5  [좋음] │ │ PM10   [보통] │ │
│ │              │ │              │ │
│ │ 11 µg/m³     │ │ 29 µg/m³     │ │
│ └──────────────┘ └──────────────┘ │
│                                    │
│  세부 항목 보기 ˅                  │   ← 확장 트리거
└────────────────────────────────────┘
```

**확장 시 추가 항목**

```
  O3 (오존)    NO2 (이산화질소)
  0.03 ppm    0.02 ppm
  [좋음]       [보통]

  CO (일산화탄소)  SO2 (아황산가스)
  0.4 ppm         0.005 ppm
  [좋음]          [좋음]
```

**시각 스펙**

- 카드 전체 배경: DT.surface (중립)
- 내부 각 항목 배경: 해당 항목 등급 Lt 색상
  - 좋음 → safeLt
  - 보통 → primaryLt
  - 나쁨 → cautionLt
  - 매우나쁨 → dangerLt
- 항목 박스 모서리: 12px
- 항목 간 간격: 12px
- 상단 행: 항목명 (13px Medium) + 등급 배지 (11px 캡슐)
- 숫자: 20px Bold tabular-nums
- 단위 라벨: 12px Regular 연한 색
- 하단 "세부 항목 보기" 텍스트 + chevron_down (14px)
- 확장/접기는 기존 `pollutant_detail_card.dart` AnimatedSize 패턴 재사용

**단위 표기 통일**
- 전 화면에서 **`µg/m³`** (그리스문자 뮤, U+00B5)
- `μg`, `ug` 사용 금지

### 3.5 공통 디테일

**카드 간 간격**
- 카드 → 카드: 20px
- 카드 내부 padding: 20~24px (히어로는 24, 나머지는 20)

**카드 모서리**
- 전체 통일: 16px

**색상 시스템**
- 페르소나 탭과 동일 DT 토큰 사용
- 신규 색상 추가 금지 (프로필 탭에서 추가한 pinkLt는 사용 안 함)

**애니메이션**
- 카드 진입 fade-in: 300ms, Curves.easeOut (이미 있으면 유지)
- 차트 곡선 draw: 500ms, Curves.easeOutCubic
- 카드 3 확장/접기: 350ms, Curves.easeOutCubic

**Pull-to-Refresh**
- 상단에서 당기면 데이터 새로고침
- 기존 로직 있으면 유지, 없으면 추가

---

## 4. 시공 단계 (4단계)

### 단계 0: 로직 엔진 개편 (최우선)

UI 건드리지 않고 로직만 개편. 다른 단계의 전제.

**작업**
1. `threshold_engine.dart` 에 `computeTFinalPm10(profile)` 추가
2. `dust_calculator.dart` 의 판정 로직 `final_ratio` 기반으로 교체
3. 기존 PM10 안전망(`pm10 > 150`) 제거
4. `dust_calculator.dart` 의 `shouldSendRealtime` 기준 변경 — `finalRatio >= 1.5`
5. `care_providers.dart` 의 `sensitivity_multiplier` 공식 수정
6. `care_models.dart` 의 `CardStatus` enum 및 `resolveStatus()` 제거
7. `aqi_grade_converter.dart` 의 차트 포인트 구조 개편 — `finalRatio` 필드 추가

**테스트**
- final_ratio 계산 케이스 검증 (§6 표준 케이스 + 엣지 케이스)
- sensitivity_multiplier 수정 검증 (T_final별)
- shouldSendRealtime 기준 변경 검증 (PM10 dominant 케이스 포함)
- 기존 PM10 안전망 제거 후 동작 검증

### 단계 1: 히어로 카드 리팩터링

단계 0 완료 후 진입.

**작업**
1. `care_providers.dart` 의 `_title`, `_personalText`, `_actionGuide` 를 설계 §3.2 카피 매트릭스에 맞게 전면 재작성
2. 페르소나 reasons 연동 (warning 이상 + reasons 있을 때)
3. 히어로 카드 위젯을 단일 배경 + 평면 스타일로 재작성
4. 정보 바(숫자 2열) 컴포넌트 신규

### 단계 2: 차트 카드 리팩터링

**작업**
1. `ProtectionChartData` 구조 final_ratio 기반으로 개편
2. 결론 한 줄 생성 로직 (`_buildForecastVerdict(chartPoints)`)
3. 차트 위젯 재작성:
   - Y축 숫자 제거, 기준선 하나만
   - X축 라벨 시간대 표현으로
   - 영역 음영 1.0 기준 색 분리
   - 범례 제거
4. 링크 텍스트/아이콘 업데이트

### 단계 3: 세부 수치 카드 + 페이지 상단

**작업**
1. 항목별 개별 배경색 레이아웃으로 재작성
2. 단위 표기 `µg/m³` 통일 (전 파일 grep)
3. 페이지 상단 "케어" 타이틀 + 측정소·갱신시각 추가
4. 카드 간격/모서리 통일 확인

---

## 5. 작업 원칙

### 5.1 절대 규칙

- **각 단계는 독립적으로 빌드되고 테스트 통과해야 함.**
- **단계 0 완료 없이 단계 1~3 진행 금지.**
- **로직 변경(단계 0)이 다른 feature에 영향 주는지 반드시 조사.**
- **설계 문서에 명시되지 않은 색상/폰트/간격 조정 금지.**
- **기능 추가 금지.** 리모델링에만 집중.

### 5.2 놓치지 말 것

- 각 단계 작업 전, **영향받는 파일 목록**을 먼저 조사 후 보고
- 설계 모호 시 **질문으로 멈추기**. 추측 금지.
- 각 단계 끝에 `flutter analyze` + `flutter test` 통과 필수
- 단위 표기 `µg/m³` 일관성 확인 (µ는 U+00B5)

### 5.3 질문 타이밍

- 설계 문서와 기존 코드가 충돌할 때
- 다른 feature (프로필 탭, 리포트 탭, 알림 스케줄러 등)에 영향 예상 시
- 로직 변경이 기존 테스트를 다수 깨뜨릴 때

---

## 6. 테스트 전략

### 단계 0 테스트

**`dust_calculator_test.dart` (대폭 확장)**

케이스별 검증 (일반인 T_final=35 기준):

| PM2.5 | PM10 | 예상 final_ratio | 예상 RiskLevel |
|--|--|--|--|
| 10 | 20 | 0.29 (pm25) | low |
| 11 | 120 | 1.50 (pm10) | warning |
| 50 | 25 | 1.43 (pm25) | warning |
| 80 | 150 | 2.29 (pm25)* | critical |
| 11 | 29 | 0.36 (pm10) | low |

*max 적용: max(80/35=2.29, 150/80=1.88) = 2.29

민감 유저 T_final=19 기준:

| PM2.5 | PM10 | 예상 final_ratio | 예상 RiskLevel |
|--|--|--|--|
| 11 | 29 | 0.67 (pm10) | normal |
| 20 | 45 | 1.05 (pm25) | warning |

**`care_providers_test.dart` — sensitivity_multiplier**
- T_final=35 → 1.0
- T_final=19 → 1.84
- T_final=15 → 2.33
- clamp 검증

### 단계 1~3 테스트

- 카드별 렌더링 테스트
- RiskLevel별 카피/배경색 매핑
- 차트 결론 한 줄 생성 케이스
- 단위 표기 일관성 (grep 기반)

---

## 7. 설계 외 범위 (출시 후 고려)

**PM10 예보 데이터 한계 (v4 강화)**

에어코리아 API는 현재 다음 데이터를 제공하지 않음:
- **시간별 PM2.5/PM10 예보** — `tomorrowForecastProvider`는 PM2.5 등급 문자열만 반환
- **PM10 예보** — 전혀 없음

이로 인한 구현 한계:

| 항목 | 실제 동작 | 위험 |
|---|---|---|
| 차트 h=1~12 포인트 | 현재 PM2.5 → 내일 등급 중앙값 cubic smoothstep 보간 | 실제 농도와 다를 수 있음 |
| 예보 구간 PM10 | `ratioPm10 = 0` (미반영) | PM10 주도 오염 과소평가 |
| 시각별 verdict | 추세(상승/하락) 판단만 가능 | 구체 시각 표현 불가 |

**카피 작성 원칙 (v4 신규)**

- 차트 verdict 카피는 구체적 시각 표현 **절대 금지**: "오후 3시부터 7시까지" 형태 사용 금지
- 추세 기반 표현만 허용: "점차 나빠질 수 있으니", "시간이 지나면 좋아져요" 등
- 이유: 보간 곡선은 예보 정밀도를 가장하지 않아야 함

출시 후 고려 항목:
- 시간별 PM10 예보 API 연동 (에어코리아 개선 시)
- 오염물질 개별 기준치 커스터마이징 (현재는 PM2.5/PM10만)
- AQI 통합 지수 노출 (현재는 숨김)
- 차트 확대/줌 인터랙션

---

## 8. 변경 요약

### v1 → v2

| 항목 | v1 | v2 |
|---|---|---|
| 케어 탭 status enum | `CardStatus` (3단계: safe/caution/danger) | `RiskLevel` 직접 사용 (5단계) — CardStatus 제거 |
| `resolveStatus()` | `care_models.dart` 함수 (PM2.5 단일) | 제거 — `dustCalculationProvider`의 riskLevel 사용 |
| Realtime 알림 트리거 | `ratio >= 2.0 \|\| pm10Emergency` | `finalRatio >= 1.5` |
| 야간 방해금지 예외 | 미명시 | 절대값 유지 (`pm25 >= 75`, `pm10 >= 150`) |
| 히어로 카드 정보 바 | "대기 상태 / 내 기준" 고정 라벨 | 동적: final_ratio 결정 오염물질(PM2.5 or PM10) 기준 |
| PM10 예보 차트 처리 | 미명시 | 예보 구간 ratioPm10=0 처리 (의도적 한계) 명시 |

### v2 → v3

| 항목 | v2 | v3 |
|---|---|---|
| 히어로 카드 danger 배경색 | `cautionLt` 또는 신규 `orangeLt` (미확정) | `dangerLt` (안 B 확정) |
| 히어로 카드 critical 배경색 | `dangerLt` | `dangerLt` + **1px `DT.danger` 보더** (danger와 차별화) |
| 정보 바 오른쪽 부가정보 | 이분법 (`기준 이하` / `기준 초과`) | 삼분법 + diff (`기준 이하` / `기준 도달` / `+Nµg 초과`) |
| `_subCopy` 줄바꿈 | 미명시 (`\n` 허용 상태) | **단문 강제** (`\n` 금지, 자연 wrap만 허용) |

### v3 → v4

| 항목 | v3 | v4 |
|---|---|---|
| 차트 verdict 매트릭스 | 시각 기반 3단계: "오후 3시부터 7시까지" 등 구체 시각 표현 | 추세 기반 5단계: `safe` / `partialIncreasing` / `partialDecreasing` / `fullDay` / `unknown` |
| verdict 카피 — 부분 초과 | "🟡 오후 3시부터 7시까지 마스크를 챙기세요" | "🟡 점차 나빠질 수 있으니 마스크를 챙기세요" (상승) / "🟢 지금은 주의, 시간이 지나면 좋아져요" (하락) |
| `RiskWindow` | `ChartVerdict.windows: List<RiskWindow>` 포함 (시각별 구간) | **제거** — 보간 거짓 정밀도 위험 |
| §7 데이터 한계 | PM10 예보 없음 한 줄 명시 | 표 형식 상세 명시 + 카피 작성 원칙 추가 |
| 그리드 등급 라벨 | `_gradeFromValue` 하드코딩 | `DustStandards.getPm25Grade()` 위임 |
| 고아 파일 | `lib/data/models/protection_chart_data.dart` 방치 | 단계 2에서 삭제 |
