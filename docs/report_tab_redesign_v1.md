# 리포트 탭 설계 문서 (v1)

> 이번 사이클 첫 번째 새 설계. 차터 §7 합의안과 yulgok·Lead 결정 사항을 그대로 구현하기 위한 내부 스펙.
> 이 문서와 기존 코드가 충돌하면 **질문하세요.** 추측하지 마세요.

---

## 1. 왜 새로 설계하는가

### 1.1 현재 상태 진단

**구조 문제**

현재 `report_tab.dart`는 4개 카드 + 1개 탭 선택기로 구성되어 있다:

- `PeriodSelector` — 오늘 / 3일 / 7일 기간 전환 탭
- `ReportSummaryCard` — 위험일·마스크일·방어율 3개 수치 + 요약 문장
- `DailyBarChartCard` — PM2.5 막대 차트 (Y축에 절대 농도값)
- `MaskCalendarCard` — 마스크 착용 여부를 날짜 셀로 보여주는 캘린더
- `HighlightCard` — 기간 내 가장 나쁜 날 하이라이트

이 구조는 "지난 기간의 수치를 보는 대시보드"처럼 생겼다. 수치를 보여주되 해석이 없다.

**합의안과의 충돌**

| 항목 | 현재 코드 | 합의안 |
|---|---|---|
| 기간 선택 | 오늘/3일/7일 토글 있음 | 7일 고정 (yulgok Q1 결정) |
| 시각화 형태 | 막대 차트 + 캘린더 2개 | 원(Circle) 7개 가로 배열 1개로 대체 |
| 인사이트 | HighlightCard가 "가장 나쁜 날" 단일 사실만 표시 | 4겹(시간·데이터·개인 기준·행동) 인사이트 카드 |
| 추세 | 없음 | 지난주 대비 한 줄 |
| 방어율 % | ReportSummaryCard에 "방어율 XX%" 표시됨 | 차터 §7.5 점수·% 금지 → 삭제 |
| 개인 기준 해석 | 없음 | final_ratio 기반 개인 기준 대비 해석이 핵심 |

**기존 인프라 미활용**

Phase 3에서 완성된 `getNotificationsWithAqiContext()` 와 `computeHistoricalFinalRatio()` 가 `report_tab.dart` 어디에도 사용되지 않고 있다. 현재 코드는 PM2.5 절대 농도만 사용하고 개인 기준(T_final) 해석이 전혀 없다.

### 1.2 설계 방향 (한 문장)

> **"7일을 한눈에 보여주고, 내 기준으로 해석한 한 단락 인사이트를 건네고, 지난주 대비 한 줄로 마무리하는 간결한 회고 공간."**

### 1.3 리포트 탭의 본질

**유저가 리포트 탭을 여는 순간 머릿속 질문**
- "이번 주 공기 어땠지?"
- "내가 마스크 잘 챙겼나?"
- "지난주보다 좋아졌나?"

케어 탭이 "지금 이 순간의 판단"이라면, 리포트 탭은 **"한 주를 한눈에 보고, 내가 잘 살았다는 걸 확인하면서 동시에 뭔가 얻어가는 곳."** (차터 §7.1)

수치를 보여주는 게 목적이 아니라, 사용자가 "보길 잘했다"는 시간 가치를 느끼는 게 목적이다.

### 1.4 타겟 이해

**메인 타겟**: 호흡기·심혈관 질환자, 매일 미세먼지를 신경 쓰는 사람.
- 필요: 자기 위로·관리 증거. "내가 신경 쓰고 잘 챙기고 있다"는 확인.
- 톤: 행동을 인정받고 싶음. 하지만 직접 칭찬은 유아스럽게 느껴짐.

**서브 타겟**: 일반인, 가끔 챙기는 사람.
- 필요: 가벼운 호기심·안심. "별거 없었구나 / 아 그 날 좀 나빴구나."
- 톤: 부담 없이 훑고 나갈 수 있어야.

**공통 동기**: "잘 살고 있다는 확인" + "보길 잘했다는 시간 가치."

### 1.5 무드 = 외유내강

**표면(외유)**: "프로페셔널한 친구"가 건네는 이번 주 한 단락 리뷰.
- 데이터 분석가 톤 없음. 수치는 안에 숨기고 번역해서 꺼낸다.
- 못 챙긴 날을 부각하거나 평가하지 않는다.

**안(내강)**: 7일간의 AQI 기록 + 알림 로그 + 개인 T_final 기반의 정밀 계산.
- `computeHistoricalFinalRatio()` 와 `getNotificationsWithAqiContext()` 가 모두 돌아가고 있다.
- 사용자 눈에는 자연스러운 한 단락으로만 보인다.

---

## 2. 데이터 기반 (Phase 3 완료된 인프라)

### 2.1 사용 가능한 쿼리·헬퍼·모델

**DB v4 (완료)**

- `aqi_records` 테이블: `pm25_value`, `pm10_value`, `data_time`, `station_name`. 14일 보존.
- `notification_logs` 테이블: `pm25_value`, `pm10_value` (v4에서 추가), `t_final`, `user_action`, `triggered_at`.

**핵심 쿼리**

| 메서드 | 반환 | 용도 | 상태 |
|---|---|---|---|
| `db.getNotificationsWithAqiContext({start, end, stationName})` | `List<NotificationWithAqiContext>` | 인사이트 엔진 입력 | ✅ 완료 (Phase 3) |
| `db.getDailyAqiAverages({stationName, days})` | `List<Map>` (pm25_avg, pm10_avg, day) | 한 주의 그림 final_ratio 계산 | 단계 1에서 추가 |
| `db.getLogsGroupedByDate({days})` | `Map<String, List<NotificationLog>>` | 날짜별 마스크 행동 여부 | 단계 1에서 추가 |

**헬퍼 함수 (완료)**

```dart
// lib/core/utils/dust_calculator.dart
static double computeHistoricalFinalRatio({
  required double tFinalPm25,
  required int? pm25,
  required int? pm10,
})
```

- PM2.5 / T_final_pm25 와 PM10 / T_final_pm10 을 계산 후 max 반환.
- divide-by-zero 가드 있음 (tFinalPm25 <= 0 이면 0.0 반환).
- T_final_pm10 = tFinalPm25 × (80.0 / 35.0) (케어 탭 v4 §2.2와 동일 공식).

**모델 (완료)**

```dart
// lib/features/report_tab/models/report_models.dart
class NotificationWithAqiContext {
  final NotificationLog notification;
  final int? aqiPm25;
  final int? aqiPm10;
  final DateTime? aqiDataTime;
  bool get hasAqiContext => aqiDataTime != null;
}
```

### 2.2 final_ratio 계산 정책

리포트 탭에서 historical final_ratio를 계산할 때 **현재 프로필의 T_final 동결**을 적용한다.

- 과거 데이터에 그 당시 T_final이 무엇이었는지 별도로 저장하지 않는다.
- `notification_logs.t_final` 컬럼이 있긴 하지만, 알림 발송이 없던 날(AQI 기록만 있는 날)에는 null이다.
- 따라서 AQI 기록 기반 final_ratio 계산은 일관되게 현재 `profile.tFinal` 적용.
- 인사이트 카드 문구에서 "내 기준"이라 표현할 때도 현재 기준값을 명시하면 된다.

### 2.3 주간 데이터 범위

- **7일 고정**: 어제까지 6일 + 오늘. 항상 7칸 채워짐 (yulgok Q1 결정).
- 오늘 데이터가 없으면 해당 날 final_ratio = null → 누락 처리.
- 지난주(비교용): 7일 전~14일 전 구간. `getDailyAqiAverages(days: 14)` 로 가져와서 날짜 기준 분리.

---

## 3. 인사이트 엔진

### 3.1 카테고리 매트릭스

매주 1개만 선정. 아래 우선순위 순서로 평가.

| 우선순위 | 카테고리 | 선정 조건 | InsightCategory 값 |
|---|---|---|---|
| 1 | 행동 매칭 | 마스크 챙긴 알림 1개 이상 존재 | `actionMatch` |
| 2 | 환경 피크 | final_ratio 1.0배 초과 날 존재 | `envPeak` |
| 3 | 주중-주말 차이 | 평균 final_ratio 차이 ≥ 0.15 | `weekdayWeekend` |
| 4 | 평균 요약 | 위 1~3 모두 해당 없음, 데이터는 있음 | `avgSummary` |
| 5 | 모두 안전 | 전 기간 final_ratio < 1.0 | `allSafe` |
| 6 | 데이터 없음 | AQI 기록도 알림 로그도 없음 | InsightData null → InsightCard에서 placeholder 카피 (v1.1 변경 — 사용자 검수 후 reverse) |

> **주중-주말 기준**: 월~금 평균 final_ratio와 토~일 평균 final_ratio 의 절대값 차이 ≥ 0.15.
> ratio 0.15는 T_final=35 기준 약 5.25µg/m³ 차이에 해당한다.

### 3.2 선정 알고리즘 + 우선순위

```
입력:
  weeklyNotifs: List<NotificationWithAqiContext>  // 7일 알림 + AQI 컨텍스트
  weeklyAqi: List<DailyAqiRow>                    // 7일 일별 AQI 평균
  tFinalPm25: double                               // 현재 프로필 T_final

1. 마스크 챙긴 알림 필터:
   maskedNotifs = weeklyNotifs
     .where((n) => n.notification.userAction == UserAction.maskWorn)

   if (maskedNotifs.isNotEmpty):
     → peak 선정: maskedNotifs 중 computeHistoricalFinalRatio 가장 높은 1개
     → category = actionMatch

2. 1.0 초과 시간대:
   peakRows = weeklyAqi.where((r) =>
     computeHistoricalFinalRatio(tFinalPm25, pm25Avg, pm10Avg) >= 1.0)

   if (peakRows.isNotEmpty):
     → peak 선정: 그 중 ratio 가장 높은 1일
     → category = envPeak

3. 주중-주말 차이:
   weekday = weeklyAqi.where(date.weekday <= 5).avgRatio
   weekend = weeklyAqi.where(date.weekday >= 6).avgRatio

   if ((weekday - weekend).abs() >= 0.15 && 토~일 데이터 >= 1일):
     → category = weekdayWeekend

4. 평균 요약:
   if (weeklyAqi.isNotEmpty):
     → category = avgSummary

5. 모두 안전:
   if (weeklyAqi.every(ratio < 1.0)):
     → category = allSafe

6. 데이터 없음:
   → null 반환 → 슬롯 숨김
```

> **주의**: allSafe는 avgSummary보다 먼저 체크해야 한다. avgSummary 조건(데이터 있음)은 allSafe 조건도 포함하므로, 우선순위가 allSafe < avgSummary 로 설계됐지만 구현에서는 allSafe를 avgSummary 분기 내부에서 처리하거나 별도 선결 체크로 처리한다.

### 3.3 카피 템플릿 — 카테고리별 4겹

인사이트 카드 본문은 4겹 정보를 자연어로 엮는다:
1. **시간** — 회상 트리거 (요일 + 오전/오후 대략)
2. **데이터** — 측정 사실 (PM 수치)
3. **개인 기준 해석** — "당신 기준({tFinal}µg/m³)으로는"
4. **행동 인정** — 마스크 착용 여부 사실 진술

**[1] actionMatch — 행동 매칭**

카피 예시:
```
"수요일 저녁, PM2.5가 {pm25}µg/m³까지 올랐어요.
당신 기준({tFinal}µg/m³)으로는 나쁨 수준이었는데,
그 때 마스크를 챙기셨네요."
```

변수:
- `{weekday}` — 월/화/수/목/금/토/일
- `{timeOfDay}` — 아침/오전/점심/오후/저녁/밤 (6시간 단위)
- `{pm25}` — AQI 컨텍스트의 pm25 값 (µg/m³)
- `{tFinal}` — 현재 profile.tFinal (µg/m³)

hasAqiContext=false 일 때 fallback: `notification.pm25Value` / `notification.pm10Value` 사용.

**[2] envPeak — 환경 피크**

카피 예시 (마스크 기록 없음):
```
"{weekday}에 공기가 가장 안 좋았어요.
PM2.5 일평균 {pm25}µg/m³으로,
당신 기준({tFinal}µg/m³)을 넘었어요."
```

카피 예시 (마스크 기록 있음):
```
"...넘었어요. 그 날 마스크를 챙기셨네요."
```

**[3] weekdayWeekend — 주중-주말 차이**

카피 예시 (평일 > 주말):
```
"이번 주는 주말보다 평일 공기가 안 좋았어요.
당신 기준으로 주중은 보통 이상, 주말은 괜찮은 수준이었어요."
```

카피 예시 (주말 > 평일):
```
"이번 주는 평일보다 주말 공기가 더 안 좋았어요."
```

**[4] avgSummary — 평균 요약**

카피 예시:
```
"이번 주 평균은 당신 기준으로 보통 수준이었어요.
크게 나쁘지 않은 한 주였어요."
```

**[5] allSafe — 모두 안전**

카피 예시:
```
"이번 한 주는 내내 괜찮았어요.
당신 기준으로도 무리 없이 지낼 수 있는 공기였어요."
```

### 3.4 빈 케이스 처리 (G-2 케이스 7가지)

| 케이스 | 조건 | 처리 |
|---|---|---|
| G-1 | AQI 기록 없음, 알림 로그 없음 | InsightEngine.compute → null 반환. InsightCard에서 placeholder 카피 표시 (카드 박스 보임, 미주 없음). 카피: "기록이 모이는 중이에요. 한 주가 채워지면 여기에 발견을 적어둘게요." |
| G-2 | AQI 기록 있음, 알림 로그 없음 | envPeak / avgSummary / allSafe 중 선정 |
| G-3 | AQI 기록 없음, 알림 로그 있음 | notification.pm25Value / pm10Value 사용 |
| G-4 | 알림 있으나 hasAqiContext=false 전부 | notification 컬럼값으로 fallback |
| G-5 | 앱 설치 7일 이내 | 있는 날짜로만 계산. 누락일은 skip |
| G-6 | 토~일 데이터 없음 | weekdayWeekend 후보 제외, 다음 카테고리로 |
| G-7 | pm10_value 전부 null | computeHistoricalFinalRatio 에서 ratioPm10=0 자동 처리 |

---

## 4. 카드별 설계

### 4.1 페이지 상단

```
┌─────────────────────────────────┐
│                                 │
│  리포트                          │   ← 24px Bold, 좌측, DT.text
│  서울 용산구 · 최근 7일           │   ← 12px Medium, DT.gray
│                                 │
└─────────────────────────────────┘
```

- "리포트" 타이틀 — 기존 코드에 이미 있음. 유지.
- 부제목 라인: `{stationName} · 최근 7일` — 기간이 항상 7일이므로 고정 문구.
- 측정소 이름 없으면 부제목 라인 숨김.
- `PeriodSelector` 완전 제거 — 기간 7일 고정에 따라 불필요.

### 4.2 카드 1 — 한 주의 그림 (WeeklyOverviewCard)

**레이아웃**

```
┌────────────────────────────────────┐
│  한 주의 그림                       │   ← 카드 제목 (15px SemiBold)
│                                    │
│  ○  ○  ○  ○  ○  ○  ●            │   ← 7개 원 (● = 오늘 dot 강조)
│                                    │
│  월  화  수  목  금  토  일        │   ← 요일 라벨 (11px Medium)
└────────────────────────────────────┘
```

**원(Circle) 스펙**

- 직경: 32px
- 배치: 7개 가로 등간격 (`Row` + `Expanded`)
- 요일 라벨: 원 아래 11px Medium, DT.gray

**색상 — final_ratio 기반 RiskLevel 매핑 (케어 탭 v4 §2.4와 일치)**

| final_ratio | RiskLevel | 원 배경색 | 비고 |
|---|---|---|---|
| < 0.5 | low | DT.safeLt | |
| < 1.0 | normal | DT.primaryLt | |
| < 1.5 | warning | DT.cautionLt | |
| < 2.0 | danger | DT.dangerLt | |
| ≥ 2.0 | critical | DT.dangerLt + 1px DT.danger 보더 | |
| null (누락) | — | DT.grayLt + 점선 보더 | 라벨 "-" |

**마스크 행동 표시**

- 마스크 착용 기록이 있는 날: 원 외곽에 2px 링.
- **링 색상: DT.text (#111827)** — Claude Design 결정. 5가지 연한 배경에서 또렷이 보이고, primary(#2563EB)는 오늘 dot과 의미 충돌.
- 마스크 기록 없는 날: 링 없음.

**오늘 강조**

- **dot only** — Claude Design 결정. 원 안에 작은 점(4px circle, DT.primary).
- 요일 라벨은 강조 ✕ (gray 그대로). dot + 라벨 강조 동시 적용은 과함.

**데이터 누락 날**

- AQI 기록이 없는 날 → DT.grayLt 원 + 점선 보더. 요일 라벨 그대로, 원 내부 표시 없음.

**final_ratio 계산 (이 카드용)**

일평균값으로 계산한다. 시간별 피크보다 낮게 계산될 수 있으나 의도적이다 — "하루를 대표하는 색"에는 피크보다 평균이 더 적합하다.

```dart
final ratio = DustCalculator.computeHistoricalFinalRatio(
  tFinalPm25: profile.tFinal,
  pm25: row['pm25_avg']?.toInt(),
  pm10: row['pm10_avg']?.toInt(),
);
```

### 4.3 카드 2 — 인사이트 카드 (InsightCard)

**레이아웃**

```
┌────────────────────────────────────┐
│  이번 주의 발견                     │   ← 카드 제목 (15px SemiBold)
│                                    │
│  {인사이트 카피 — 3~4줄}            │   ← 15px Regular, DT.text, height: 1.6
│                                    │
│                                    │   ← 구분선 없음 (Claude Design 결정 — 폰트 크기 차이로 충분)
│  PM2.5 {xx}µg/m³ · 5월 1일 (수)   │   ← 12px, DT.gray (미주)
└────────────────────────────────────┘
```

**표시 규칙**

- 데이터 있음 + 카테고리 결정됨 → 표시.
- 데이터 없음 (G-1, InsightData null) → **카드 박스는 표시, 본문은 placeholder 카피, 미주 없음**.
  - placeholder 본문: "기록이 모이는 중이에요. 한 주가 채워지면 여기에 발견을 적어둘게요."
  - v1.1 변경 — Lead 결정 5번(슬롯 숨김) reverse. 디바이스 검수에서 빈 화면이 정보 부재 신호가 아니라 단순 누락처럼 느껴졌음. 외유내강 톤(사실 + 자연스러운 미래 동작, 직접 약속·칭찬 ✕)으로 placeholder 추가.

**카피 길이 가이드**

- 본문: 2~4문장. 50~80자 내외.
- 줄바꿈: `\n` 하드코딩 금지. 위젯 자연 wrap 허용. (Claude Design 검증: `text-wrap: pretty` + `word-break: keep-all` 패턴, 320/414px 폭에서 깨짐 없음.)
- 미주: "PM2.5 {xx}µg/m³ · {월}월 {일}일 ({요일})" 형태.

**시각 스펙**

- 배경: DT.white
- 모서리: 16px
- 내부 padding: 20px
- 카드 제목: 15px SemiBold, DT.text
- 카피 본문: 15px Regular, DT.text, lineHeight 1.6
- 미주 텍스트: 12px, DT.gray

### 4.4 카드 3 — 추세 한 줄 (TrendLine)

**레이아웃**

별도 카드 박스 없음. 페이지 마지막 텍스트 한 줄로 표시.

```
  {이모지}  {추세 카피 한 줄}
```

- 좌측 padding: 16px (페이지 기본 여백)
- **상하 padding: 12px** — Claude Design 결정 (마지막 layer 무게 확보)
- **색상: DT.text 14px Regular** — Claude Design 결정 (gray→text로 본문톤 유지, 별도 카드 박스 없이 존재감 확보)

**임계값 매트릭스**

Δ = 이번 주 평균 final_ratio − 지난주 평균 final_ratio

| 분류 | 조건 | 이모지 | 카피 |
|---|---|---|---|
| 많이 좋아짐 | Δ ≤ -0.3 | 🌿 | "지난주보다 많이 깨끗했어요" |
| 조금 좋아짐 | -0.3 < Δ ≤ -0.1 | 🌱 | "지난주보다 조금 깨끗했어요" |
| 비슷 | -0.1 < Δ < +0.1 | ➡️ | "지난주와 비슷한 한 주였어요" |
| 조금 안 좋아짐 | +0.1 ≤ Δ < +0.3 | ⚠️ | "지난주보다 조금 안 좋았어요" |
| 많이 안 좋아짐 | Δ ≥ +0.3 | 🌫️ | "지난주보다 많이 안 좋았어요" |

**표시 규칙**

- 지난주(7~14일 전) AQI 기록이 1일 이상 있어야 표시.
- 지난주 데이터 없음 → **슬롯 자체 미렌더링**. fallback 카피 없음 (Lead 결정 3번).

**지난주 데이터 가져오기**

```dart
// getDailyAqiAverages(days: 14) 로 14일 가져온 후 날짜 기준 분리
// daysAgo: DateTime.now().difference(date).inDays
final thisWeek = rows.where((r) => daysAgo(r) <= 7);
final lastWeek = rows.where((r) => daysAgo(r) > 7 && daysAgo(r) <= 14);
```

### 4.5 카드 4 — 단순화된 ReportSummaryCard (유지)

**레이아웃**

```
┌────────────────────────────────────┐
│  {요약 문장 — 1~2줄}               │   ← 15px, DT.text
│                                    │
│  ─────────────────                 │
│                                    │
│    위험일          마스크 착용       │
│      {N}일           {N}일         │
└────────────────────────────────────┘
```

**변경 사항**

- 기존 3개 수치(위험일·마스크일·방어율) 중 **방어율 % 삭제** (차터 §7.5, Lead 결정 1번).
- 위험일 카운트 + 마스크 착용일 카운트만 남김 (사실 진술 — §7.5 위반 아님).
- `_StatCell('방어율', ...)` 제거. `_VertDivider` 1개로 줄어듦.
- `ReportSummaryData.summaryText` 재작성 — "방어율" 언급 제거.
  - 예: "이번 주는 위험한 날 없이 지냈어요."
  - 예: "이번 주 중 3일이 당신 기준을 넘었어요."
- `ReportSummaryData.defenseRate` 필드는 모델에 남겨두되 UI에서 미사용.

**dominantGrade 재계산 (final_ratio 기반)**

기존 코드는 PM2.5 절대값 기준 등급 문자열을 사용. final_ratio 기반으로 변경:

| 7일 평균 final_ratio | dominantGrade | 배경색 |
|---|---|---|
| < 0.5 | '좋음' | DT.safeBg |
| < 1.0 | '보통' | DT.white |
| < 1.5 | '나쁨' | DT.cautionBg |
| ≥ 1.5 | '매우나쁨' | DT.dangerBg |

### 4.6 카드 순서 (최종 페이지 레이아웃)

```
[타이틀] 리포트 · {측정소} · 최근 7일
[카드 4] ReportSummaryCard (단순화)           ← 숫자 2개 요약 먼저
[카드 1] WeeklyOverviewCard (한 주의 그림)    ← 7일 시각화
[카드 2] InsightCard (인사이트, 데이터 없으면 숨김)
[카드 3] TrendLine (추세 한 줄, 데이터 없으면 숨김)
[여백] 24px
```

> ReportSummaryCard를 맨 위에 두는 이유: 숫자(위험일/마스크일)가 먼저 눈에 들어오면 "이번 주 어땠지"를 2초 안에 훑을 수 있다. 한 주의 그림은 그 다음 레이어.

---

## 5. 톤·카피 매트릭스

### 5.1 차터 §7.5 톤 규칙 재확인

이 문서의 모든 카피는 아래 규칙을 따른다:

| 케이스 | 톤 |
|---|---|
| 사용자가 행동 챙긴 경우 | 행동 칭찬형 — 사실로 칭찬을 유도 |
| 사용자가 행동 못 챙긴 경우 | 사실 진술형 — 평가 없이 fallback |
| 못 챙긴 날 부각 | **금지** |
| 직접 칭찬 ("잘하셨어요") | **금지** |
| 점수·% 평가 지표 | **금지** |
| 자기 비교 (지난주 vs 이번주) | 허용·권장 |
| 절대 목표 vs 사용자 비교 | **금지** |

### 5.2 카테고리별 카피 원칙

**행동 매칭 (actionMatch)**

- "챙기셨네요" (사실 확인형) ← 허용.
- "잘하셨어요" / "대단해요" ← 금지.
- "못 챙긴 다른 날"은 언급하지 않음.

**환경 피크 (envPeak)**

- 가장 나쁜 날을 알려주되 "그러므로 조심하세요" 식의 경고 금지.
- 마스크 챙겼으면 조용히 인정. 못 챙겼으면 언급 자체를 생략.

**주중-주말 (weekdayWeekend)**

- "출퇴근 때문에" 같은 추론 금지 (사실 모름).
- 패턴을 관찰 사실로만 전달.

**평균 요약 (avgSummary)**

- 중립 진술. "괜찮은 편이었어요" / "조금 안 좋은 편이었어요" 수준.
- "7일 평균 22.3µg/m³" 같은 직접 숫자 노출 금지.

**모두 안전 (allSafe)**

- 안도감 전달. "내내 괜찮았어요."
- 과도한 축하 표현 금지.

### 5.3 추세 한 줄 카피

추세 카피는 단문 1문장 고정. 줄바꿈 없음. 이모지 1개 앞에 붙임.

- 🌿 "지난주보다 많이 깨끗했어요"
- 🌱 "지난주보다 조금 깨끗했어요"
- ➡️ "지난주와 비슷한 한 주였어요"
- ⚠️ "지난주보다 조금 안 좋았어요"
- 🌫️ "지난주보다 많이 안 좋았어요"

### 5.4 단위·표기 통일

- PM2.5·PM10 농도 단위: 전 화면 **`µg/m³`** (그리스문자 뮤, U+00B5).
- `μg`, `ug`, `㎍` 사용 금지.
- 날짜 표기: `{월}월 {일}일 ({요일})` — 예: "5월 3일 (토)".
- 요일 라벨 (원 아래): 월/화/수/목/금/토/일 (한 글자 이상 2글자 이내).

---

## 6. 시공 단계 (4단계)

### 단계 0: 데이터·로직 ✅ 완료 (Phase 3에서 처리됨)

신규 작업 없음. 모두 이미 구현되어 있다.

| 항목 | 파일 | 상태 |
|---|---|---|
| DB v4 마이그레이션 (pm10_value 추가) | `local_database.dart` | ✅ |
| aqi_records 14일 보존 | `local_database.dart` | ✅ |
| `getNotificationsWithAqiContext()` | `local_database.dart` | ✅ |
| `NotificationWithAqiContext` 모델 | `report_models.dart` | ✅ |
| `computeHistoricalFinalRatio()` | `dust_calculator.dart` | ✅ |

### 단계 1: 인사이트 엔진 (신규 로직·모델)

UI 건드리지 않고 로직·모델만 추가. 단계 2의 전제.

**작업**

1. **DB 쿼리 메서드 신규 추가** (`lib/core/database/local_database.dart`):
   ```dart
   Future<List<Map<String, dynamic>>> getDailyAqiAverages({
     required String stationName,
     required int days,
   })  // 날짜별 pm25_avg, pm10_avg, day(yyyy-MM-dd)

   Future<Map<String, List<NotificationLog>>> getLogsGroupedByDate({
     required int days,
   })  // 날짜(yyyy-MM-dd) → NotificationLog 그룹
   ```

2. `InsightCategory` enum 정의 (신규 파일 또는 `report_models.dart` 내):
   ```dart
   enum InsightCategory { actionMatch, envPeak, weekdayWeekend, avgSummary, allSafe }
   ```

3. `InsightData` 클래스:
   ```dart
   class InsightData {
     final InsightCategory category;
     final String bodyText;       // 렌더링할 최종 카피
     final String? footnoteText;  // "PM2.5 XXµg/m³ · 5월 3일 (토)" 형태
   }
   ```

4. `DayCircleData` 클래스:
   ```dart
   class DayCircleData {
     final DateTime date;
     final double? finalRatio;   // null = 데이터 없음
     final bool maskWorn;
     final bool isToday;
   }
   ```

5. `InsightEngine` 함수 (static class 또는 top-level 함수):
   - 입력: `weeklyNotifs`, `weeklyAqi`, `tFinalPm25`, `lastWeekAqi`
   - 출력: `InsightData?` (null이면 슬롯 숨김)
   - §3.2 알고리즘 구현
   - §3.3 카피 템플릿 → 변수 치환 → `InsightData.bodyText`

6. `insightProvider` (Riverpod FutureProvider):
   - 의존: `localDatabaseProvider`, `locationStateProvider`, `profileProvider`
   - 14일 AQI + 7일 알림 데이터 동시 로드
   - `InsightEngine.compute()` 호출
   - 반환: `AsyncValue<InsightData?>`

7. `weeklyOverviewProvider` (신규 FutureProvider):
   - `getDailyAqiAverages(days: 7)` + `getLogsGroupedByDate(days: 7)` 동시 로드
   - 7개 `DayCircleData` 목록 반환

**영향 파일**

- 수정: `lib/core/database/local_database.dart` (신규 쿼리 메서드 2개 추가)
- 수정: `lib/features/report_tab/models/report_models.dart` (신규 클래스 추가)
- 수정: `lib/features/report_tab/providers/report_providers.dart` (insightProvider, weeklyOverviewProvider 추가)
- 참조만: `lib/core/utils/dust_calculator.dart`

**테스트 요건**

`test/features/report_tab/insight_engine_test.dart` (신규):

| 케이스 | 기대 결과 |
|---|---|
| 마스크 착용 알림 있음, hasAqiContext=true | category=actionMatch |
| 착용 알림 3개, ratio 0.8/1.2/1.5 | ratio 1.5 기준으로 카피 생성 |
| 마스크 없음, final_ratio≥1.0 날 있음 | category=envPeak |
| 평일 ratio 1.0, 주말 ratio 0.7 | category=weekdayWeekend |
| 평일 ratio 0.8, 주말 ratio 0.75 (차이 < 0.15) | weekdayWeekend 아님 |
| 위 조건 전부 미충족, 데이터 있음 | category=avgSummary |
| 7일 전부 ratio < 1.0 | category=allSafe |
| AQI 없음, 알림 없음 | null 반환 |
| hasAqiContext=false 전부, notification.pm25Value 있음 | notification 값으로 카피 생성 |

추세 계산:
- Δ = -0.4 → TrendCategory.muchBetter
- Δ = 0.05 → TrendCategory.similar
- 지난주 데이터 없음 → null 반환

### 단계 2: 한 주의 그림 위젯

단계 1 완료 후 진입.

**작업**

1. `WeeklyOverviewCard` 위젯 신규 (`lib/features/report_tab/widgets/weekly_overview_card.dart`):
   - `weeklyOverviewProvider` 사용
   - 7개 원 + 요일 라벨
   - final_ratio → 색상 매핑 (§4.2 스펙)
   - 마스크 링 (색상은 §10 의뢰 결과 반영)
   - 오늘 점 (4px circle, DT.primary)
   - 누락일 점선 보더

**영향 파일**

- 신규: `lib/features/report_tab/widgets/weekly_overview_card.dart`
- 기존 위젯 파일 없으면 `lib/features/report_tab/widgets/` 디렉토리 신규 생성

**테스트 요건**

`test/features/report_tab/weekly_overview_card_test.dart` (신규):
- 7일 모두 데이터 있음 → 7개 원 렌더링
- 누락 날 → grayLt + 점선 보더
- 오늘 → 내부 점 렌더링
- 마스크 착용 날 → 링 렌더링
- RiskLevel 별 색상 (5단계 + 누락)

### 단계 3: 인사이트 카드 + 추세 + 레이아웃 재조립

단계 2 완료 후 진입.

**작업**

1. `InsightCard` 위젯 신규 (`lib/features/report_tab/widgets/insight_card.dart`):
   - `insightProvider` 사용
   - `InsightData?.bodyText` 렌더링
   - null이면 `SizedBox.shrink()` 반환

2. `TrendLine` 위젯 신규 (`lib/features/report_tab/widgets/trend_line.dart`):
   - 이번 주·지난주 평균 final_ratio 비교
   - Δ 값 기반 카피 + 이모지
   - 지난주 데이터 없으면 `SizedBox.shrink()` 반환

3. `report_tab.dart` 레이아웃 재조립:
   - `PeriodSelector` 제거
   - `DailyBarChartCard` 제거
   - `MaskCalendarCard` 제거
   - `HighlightCard` 제거
   - 새 순서: ReportSummaryCard → WeeklyOverviewCard → InsightCard → TrendLine

4. `ReportSummaryCard` 수정:
   - `_StatCell('방어율', ...)` 제거
   - `_VertDivider` 1개로 축소
   - `summaryText` 재작성 (방어율 언급 제거)
   - `dominantGrade` 재계산 (final_ratio 기반, §4.5 표 참고)

5. `report_providers.dart` 정리:
   - `highlightProvider` 제거
   - `calendarProvider` 제거
   - `dailyBarProvider` 제거
   - `selectedPeriodProvider` 제거
   - 불용 import 정리

6. `report_models.dart` 정리:
   - `ReportPeriod` enum 제거
   - `DailyBarData`, `CalendarDayData`, `CalendarDayStatus`, `HighlightData` 제거
   - `gradeFromPm25()` 함수: 내부 사용 없어지면 제거

**영향 파일**

- 수정: `lib/features/report_tab/report_tab.dart`
- 수정: `lib/features/report_tab/providers/report_providers.dart`
- 수정: `lib/features/report_tab/models/report_models.dart`
- 신규: `lib/features/report_tab/widgets/insight_card.dart`
- 신규: `lib/features/report_tab/widgets/trend_line.dart`

**테스트 요건**

- TrendLine: 지난주 데이터 없음 → SizedBox.shrink
- TrendLine: Δ별 카피 5케이스
- InsightCard: InsightData null → SizedBox.shrink
- ReportSummaryCard: 방어율 셀 없음 확인
- 레이아웃: PeriodSelector 없음 확인
- 통합: `flutter analyze` + `flutter test` 전체 통과

---

## 7. 작업 원칙

### 7.1 절대 규칙

- **각 단계는 독립적으로 빌드되고 테스트 통과해야 함.** 중간 상태에서 앱이 깨지면 안 됨.
- **단계 0은 완료됨. 단계 1 없이 단계 2·3 진행 금지.**
- **로직 변경이 다른 feature에 영향 주는지 반드시 조사.**
- **설계 문서에 명시되지 않은 색상·폰트·간격 조정 금지.**
- **기능 추가 금지.** 재설계에만 집중.
- **새 디자인 토큰 추가 금지.**

### 7.2 놓치지 말 것

- 각 단계 작업 전, **영향받는 파일 목록**을 먼저 조사 후 보고.
- 설계 모호 시 **질문으로 멈추기.** 추측 금지.
- 각 단계 끝에 `flutter analyze` + `flutter test` 통과 필수.
- 단위 표기 `µg/m³` 일관성 확인 (µ는 U+00B5).

### 7.3 질문 타이밍

- 설계 문서와 기존 코드가 충돌할 때.
- 다른 feature (케어 탭, 프로필 탭, 알림 스케줄러 등)에 영향 예상 시.
- 로직 변경이 기존 테스트를 다수 깨뜨릴 때.

---

## 8. 테스트 전략

### 단계 1 — 도메인 단위 테스트

**`test/features/report_tab/insight_engine_test.dart`**

| 케이스 | 입력 | 기대 결과 |
|---|---|---|
| actionMatch 기본 | 마스크 착용 알림 1개, hasAqiContext=true | category=actionMatch, bodyText 비어 있지 않음 |
| actionMatch ratio 기준 | 착용 알림 3개, 각 ratio 0.8/1.2/1.5 | ratio 1.5인 알림의 데이터로 카피 생성 |
| envPeak 기본 | AQI 기록 중 1일 ratio≥1.0, 마스크 없음 | category=envPeak |
| weekdayWeekend 기본 | 평일 avg ratio 1.0, 주말 avg ratio 0.7 | category=weekdayWeekend |
| weekdayWeekend 미만 | 평일 avg ratio 0.8, 주말 avg ratio 0.75 | weekdayWeekend 아님 |
| avgSummary | AQI 있음, 위 조건 전부 미충족 | category=avgSummary |
| allSafe | 7일 전부 ratio < 1.0 | category=allSafe |
| 빈 케이스 G-1 | AQI 없음, 알림 없음 | null 반환 |
| G-4 fallback | hasAqiContext=false, notification.pm25Value=25 | notification 값 사용하여 카피 생성 |

추세 계산 테스트:

| 케이스 | Δ | 기대 |
|---|---|---|
| 많이 좋아짐 | -0.4 | TrendCategory.muchBetter |
| 조금 좋아짐 | -0.2 | TrendCategory.slightlyBetter |
| 비슷 | 0.05 | TrendCategory.similar |
| 조금 안 좋아짐 | +0.2 | TrendCategory.slightlyWorse |
| 많이 안 좋아짐 | +0.4 | TrendCategory.muchWorse |
| 지난주 없음 | 데이터 없음 | null 반환 |

### 단계 2~3 — 위젯 테스트

- `WeeklyOverviewCard`: 7개 원 렌더링, 색상, 마스크 링, 오늘 점, 누락일
- `InsightCard`: InsightData 있음/없음 케이스
- `TrendLine`: TrendData 있음/없음 케이스
- `ReportSummaryCard`: 방어율 셀 미노출 확인

---

## 9. 1차 출시 제외 (다음 사이클)

차터 §7.6 + Lead 추가 결정:

- "내 기준 19µg/m³인 이유" 깊이 펼치기 — 탭하면 T_final 계산 근거를 보여주는 확장 패널
- 월간·연간 회고 — 캘린더형 월간 뷰, 연간 요약
- 미니 지식 카드 — PM2.5·PM10 차이, 마스크 필터 원리 등 1탭 교육 카드
- 연속 며칠 스트릭 — "3일 연속 챙기셨어요" 종류의 연속성 지표
- 사회적 비교 — 같은 지역 사용자 평균, 전국 평균 비교
- 다크 모드 — 앱 전체 라이트 전용이 1차 범위 (Lead 결정 2번)
- 인사이트 카드 탭 상세 펼치기 — 1차 제외. 현재 탭 인터랙션 없음.

---

## 10. Claude Design 비주얼 의뢰 컨텍스트

> 이 섹션은 자기충족적입니다. 다른 섹션을 읽지 않아도 Claude Design에 의뢰할 수 있습니다.

---

### 앱 소개

`mask_alert` 는 개인 건강 프로필 기반으로 미세먼지 마스크 착용 알림을 보내는 Flutter 앱 (iOS/Android)입니다. 사용자는 자신의 호흡기 질환·민감도·야외 활동 시간을 입력하면, 앱이 개인 임계치 T_final을 계산해 "지금 마스크 쓰세요"를 알려줍니다.

지금 의뢰하는 화면은 **리포트 탭** — 지난 7일을 돌아보는 회고 화면입니다.

---

### 무드 = 외유내강

표면은 **"프로페셔널한 친구"** 입니다. 매일 만나는 건 아니지만 만나면 정확히 알려주는 지인. 과하게 친밀하지 않고, 데이터 분석가처럼 차갑지도 않습니다.

안에는 단단한 알고리즘이 돌아가고 있지만 사용자 눈에는 보이지 않습니다. 숫자와 통계를 번역해서 자연스러운 한 단락으로 건냅니다.

**레퍼런스 무드**: Apple Health·Fitness의 데이터 카드 + Oura의 일일 요약. 잘 정돈된 진료 기록지에 격식 없는 메모가 붙어 있는 느낌. 애니메이션과 색상은 절제되어 있지만 한 번 보면 핵심을 이해할 수 있습니다.

**금지 무드**: 헬스케어 앱의 과도한 색상 포인트, 게이미피케이션 배지, 경고·알림 느낌의 빨강 강조.

---

### 색상·폰트·간격 시스템

앱 전체에서 사용하는 디자인 토큰. 새 색상 추가는 하지 않습니다.

**배경·중립**
- `background` = `#F9FAFB` (페이지 배경)
- `white` = `#FFFFFF` (카드 배경)
- `grayLt` = `#F3F4F6` (누락 셀 배경)
- `border` = `#E5E7EB`
- `gray` = `#6B7280` (서브 텍스트, 미주)
- `text` = `#111827` (본문 텍스트)

**5단계 위험도 색상 (원 배경)**
- low (final_ratio < 0.5) → `safeLt` = `#DCFCE7` (연초록)
- normal (< 1.0) → `primaryLt` = `#DBEAFE` (연파랑)
- warning (< 1.5) → `cautionLt` = `#FEF3C7` (연노랑)
- danger (< 2.0) → `dangerLt` = `#FEE2E2` (연분홍빨강)
- critical (≥ 2.0) → `dangerLt` + 1px `danger`(#DC2626) 보더

**강조색**
- `primary` = `#2563EB` (파랑, 오늘 강조 dot)
- `safe` = `#16A34A` (초록)
- `caution` = `#D97706` (주황)
- `danger` = `#DC2626` (빨강)

**폰트**: 한국어 기본 시스템 폰트. 별도 커스텀 폰트 없음.

**모서리**: 카드 16px 통일. 원 셀은 BoxShape.circle.

**간격**: 카드 간 20px, 카드 내부 padding 20px.

---

### 화면 레이아웃 텍스트 목업

아래는 실제 카피 길이를 포함한 텍스트 목업입니다.

```
┌─────────────────────────────────┐
│                                 │
│  리포트                          │  ← 24px Bold
│  서울 용산구 · 최근 7일           │  ← 12px, gray
│                                 │
│  ┌─────────────────────────┐   │
│  │                          │   │  [ReportSummaryCard]
│  │ 이번 주는 위험한 날이      │   │  ← 15px Regular (1~2줄)
│  │ 없이 지냈어요.            │   │
│  │                          │   │
│  │ ───────────────────────  │   │
│  │                          │   │
│  │   위험일       마스크착용  │   │  ← 11px, gray 라벨
│  │    0일           3일      │   │  ← 28px Bold tabular-nums
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 한 주의 그림              │   │  [WeeklyOverviewCard]
│  │                          │   │
│  │  ○  ○  ○  ○  ○  ○  ●   │   │  ← 원 직경 32px, ● = 마스크 링
│  │                          │   │
│  │  월  화  수  목  금  토 일 │   │  ← 11px, gray
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 이번 주의 발견            │   │  [InsightCard]
│  │                          │   │
│  │ 수요일 저녁, PM2.5가      │   │  ← 15px Regular, lineHeight 1.6
│  │ 28µg/m³까지 올랐어요.    │   │
│  │ 당신 기준(19µg/m³)으로는 │   │
│  │ 나쁨 수준이었는데,        │   │
│  │ 그 때 마스크를 챙기셨네요. │   │
│  │ ───────────────────────  │   │
│  │ PM2.5 28µg/m³ · 5월 1일  │   │  ← 12px, gray (미주)
│  └─────────────────────────┘   │
│                                 │
│  🌱  지난주보다 조금 깨끗했어요  │  ← TrendLine (배경 없음, 14px, gray)
│                                 │
└─────────────────────────────────┘
```

---

### 핵심 의뢰 사항

**[의뢰 A] 마스크 링 색상**

마스크를 착용한 날의 원 외곽에 2px 링을 표시합니다. 링 색상 두 가지 안:

- **옵션 1**: `text` (#111827 진한 회색-검정) — 절제되고 단정한 느낌
- **옵션 2**: `primary` (#2563EB 파랑) — 행동을 긍정적으로 강조하는 느낌

원의 배경색이 5가지 연한 색(#DCFCE7 / #DBEAFE / #FEF3C7 / #FEE2E2 / #F3F4F6)이므로, 두 색 중 어느 쪽이 더 잘 보이고 "외유내강" 무드에 맞는지 의견이 필요합니다.

**[의뢰 B] 오늘 날짜 강조**

오늘 날짜의 원을 강조하는 방법으로 두 가지를 고려 중입니다:
- (a) 원 안에 작은 dot (4px, primary 색)
- (b) 요일 라벨을 primary 색 + bold
- (c) 두 가지 동시 적용

두 가지를 동시에 적용하면 과한지, 하나만 선택하는 게 나은지 의견 부탁드립니다.

**[의뢰 C] 인사이트 카드 — 본문과 미주 사이 구분선**

카드 안에 세 가지 텍스트 계층이 있습니다:
- 카드 제목: "이번 주의 발견" (15px SemiBold)
- 본문 카피: 3~4문장 (15px Regular)
- 미주: "PM2.5 28µg/m³ · 5월 1일 (수)" (12px Regular, gray)

본문과 미주 사이 1px 구분선(border 색)이 필요한지, 아니면 폰트 크기·색상 차이로 충분한지 의견 부탁드립니다.

**[의뢰 D] 추세 한 줄 — 존재감**

추세 한 줄은 별도 카드 없이 텍스트 + 이모지만으로 표시됩니다. 현재 계획:
- 좌측 패딩 16px, 상하 여백 8px
- 14px Regular, gray 색상

너무 존재감이 약해 보이면 어떻게 조정하면 좋을지 의견이 필요합니다. 단, 별도 카드 박스(배경색)를 추가하는 방향은 제외입니다.

---

### 인터랙션 정책

- **탭**: 인사이트 카드 탭 → 아무 동작 없음 (깊이 펼치기 1차 제외).
- **스크롤**: 자연 스크롤. 상단 고정 없음.
- **당겨서 새로고침**: 데이터 새로고침 (기존 패턴 유지).
- **애니메이션**: 카드 진입 fade-in 300ms, Curves.easeOut (케어 탭 동일 패턴).
- **다크 모드**: 1차 제외. 라이트 모드 전용.

---

*이 의뢰서는 mask_alert 리포트 탭 v1 설계 기준입니다.*
*[의뢰 A] 링 색상 결정은 단계 2 구현 전에 받아야 합니다.*
