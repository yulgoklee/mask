# 마스크 알림 (Mask Alert)

> 내 몸에 맞는 미세먼지 알림

같은 공기도 사람마다 다르게 영향을 줘요.
호흡기 상태, 활동량, 민감도 — 9가지 요소로 개인 임계치(T_final)를 계산해,
"오늘 보통이에요"가 아니라 "지수님 기준으로 마스크 챙기세요"라고 알려드립니다.

▸ 한국환경공단 에어코리아 실시간 데이터 (PM2.5 + PM10 종합 판단)  
▸ 6종 페르소나로 본인의 위험 프로파일 진단  
▸ 외출 시각·민감도·기저질환 반영한 개인 알림 기준치

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| 🌍 실시간 종합 판단 | PM2.5 + PM10 final_ratio = max(pm25/T, pm10/T_pm10) 기반 5단계 위험도 |
| 🧬 6종 페르소나 진단 | 호흡기·활동량·민감도 등 9개 요소로 개인 프로파일 분석 |
| 🎯 개인 임계치 T_final | 35µg/m³ 일반 기준이 아닌, 내 몸 기준으로 알림 (예: 21µg/m³) |
| 😷 마스크 추천 | 위험도에 따라 KF80 / KF94 / 착용 불필요 자동 안내 |
| 🔔 4종 알림 | 외출 전 / 전날 예보 / 귀가 후 / 실시간 경보 |
| 📊 12시간 추세 차트 | verdict 한 줄 요약 + final_ratio 영역 음영 |
| 📍 위치 자동 감지 | GPS 기반 가장 가까운 측정소 자동 선택 |

---

## 아키텍처

```
사용자 기기 (Flutter 앱)
       │
       ▼
Firebase Cloud Functions   ← API 키는 서버에만 보관
  ├─ proxyMeasurement      ← 실시간 측정값
  ├─ proxyForecast         ← 단기 예보
  └─ proxyStations         ← 측정소 검색 (번들 데이터, API 불필요)
       │
       ▼
한국환경공단 에어코리아 API
```

- 앱 바이너리에 API 키 미포함 — Cloud Functions이 서버에서 중계
- 오프라인 측정소 검색: 전국 ~250개 측정소 데이터를 Functions에 번들링
- 백그라운드 알림: Android Workmanager + 포그라운드 즉시 체크 병행

---

## 시작하기

### 1. 사전 준비

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 설치 (`>=3.0.0`)
- [Firebase 프로젝트](https://console.firebase.google.com) 생성 및 Android 앱 등록
- [공공데이터포털](https://www.data.go.kr) 에어코리아 API 키 발급 (서버용)

### 2. 클론 & 의존성 설치

```bash
git clone https://github.com/yulgoklee/mask.git
cd mask
flutter pub get
```

### 3. Firebase 설정

```bash
# Firebase CLI 설치
npm install -g firebase-tools
firebase login

# FlutterFire CLI로 google-services.json 자동 생성
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Cloud Functions 배포

```bash
cd functions
npm install

# Firebase Secret Manager에 API 키 등록
firebase secrets:set AIR_KOREA_API_KEY

# 배포
firebase deploy --only functions
```

배포 후 출력되는 URL을 복사해둡니다:
```
✔ Function URL (proxyMeasurement): https://asia-northeast3-PROJECT_ID.cloudfunctions.net/proxyMeasurement
```

### 5. 앱 설정

```bash
cp lib/core/config/app_config.dart.example lib/core/config/app_config.dart
```

`lib/core/config/app_config.dart` 파일에 Cloud Functions URL 입력:

```dart
class AppConfig {
  // Cloud Functions 사용 시 API 키는 앱에 불필요 (서버에서 관리)
  static const String airKoreaApiKey = '';

  // Cloud Functions 베이스 URL (배포 후 복사한 URL에서 함수명 제외)
  static const String cloudFunctionsBaseUrl =
      'https://asia-northeast3-PROJECT_ID.cloudfunctions.net';
}
```

> ⚠️ `app_config.dart`는 `.gitignore`에 포함되어 있습니다. 절대 커밋하지 마세요.

### 6. 실행

```bash
# 개발
flutter run

# 백그라운드 알림 테스트 (실제 프로덕션과 동일한 동작)
flutter run --release
```

---

## API 키 발급

1. [공공데이터포털](https://www.data.go.kr) 접속 및 회원가입
2. **"한국환경공단_에어코리아_대기오염정보"** 검색
3. 활용신청 → 승인 후 **일반 인증키(Encoding)** 복사
4. Firebase Secret Manager에 등록:
   ```bash
   firebase secrets:set AIR_KOREA_API_KEY
   ```

> 승인은 즉시~수 분 내 자동 승인됩니다.  
> API 키는 서버(Cloud Functions)에만 저장되며, 앱 바이너리에는 포함되지 않습니다.

---

## 기술 스택

### 앱 (Flutter)

| 분류 | 라이브러리 |
|------|-----------|
| 상태관리 | flutter_riverpod ^2.5.1 |
| 네트워크 | dio ^5.4.3 |
| 로컬 저장 | shared_preferences ^2.2.3 |
| 알림 | flutter_local_notifications ^17.2.2 |
| 백그라운드 | workmanager ^0.9.0 |
| 위치 | geolocator ^13.0.1 |
| 권한 | permission_handler ^11.3.1 |
| 분석 | firebase_analytics ^12.2.0 |
| 오류 수집 | firebase_crashlytics ^5.1.0 |

### 서버 (Firebase Cloud Functions)

| 분류 | 내용 |
|------|------|
| 런타임 | Node.js 18 (TypeScript) |
| 플랫폼 | Firebase Cloud Functions v2 |
| 보안 | Secret Manager로 API 키 관리 |
| 측정소 | 전국 ~250개 번들 데이터 (API 불필요) |

---

## 프로젝트 구조

```
mask/
├── functions/                   # Firebase Cloud Functions (서버)
│   └── src/
│       ├── index.ts             # proxyMeasurement / proxyForecast / proxyStations
│       └── stations.ts          # 전국 측정소 번들 데이터
│
└── lib/                         # Flutter 앱
    ├── core/
    │   ├── config/              # app_config.dart (gitignored)
    │   ├── constants/           # 색상, 미세먼지 기준값
    │   ├── services/
    │   │   ├── air_korea_service.dart          # 직접 호출 (개발/폴백)
    │   │   ├── cloud_functions_data_source.dart # Cloud Functions 프록시
    │   │   ├── dust_data_source.dart           # 공통 인터페이스
    │   │   ├── background_service.dart         # Workmanager 관리
    │   │   ├── notification_scheduler.dart     # 알림 발송 로직
    │   │   └── notification_service.dart       # 로컬 알림 표시
    │   └── utils/
    ├── data/
    │   ├── models/              # DustData, UserProfile, NotificationSetting 등
    │   └── repositories/        # DustRepository, ProfileRepository
    ├── features/
    │   ├── home/                # 홈 탭 — 위험도 카드, 상세 화면
    │   ├── care/                # 케어 탭 — 12시간 추세 차트 + 상태 카드
    │   │   ├── models/
    │   │   ├── providers/
    │   │   └── widgets/
    │   ├── profile_tab/         # 프로필 탭 — 페르소나 카드, 설정 진입
    │   │   └── widgets/
    │   ├── report_tab/          # 리포트 탭
    │   │   ├── models/
    │   │   └── providers/
    │   ├── onboarding/          # 8단계 신규 유저 흐름
    │   │                        # splash → welcome → 진단(Q1~Q8) → 분석
    │   │                        # → 진단 결과 → 위치 → 알림 → 완료
    │   ├── diagnosis/           # 재진단 화면
    │   ├── profile/             # 건강 프로필 편집
    │   ├── my_body_info/        # 신체 정보 편집
    │   ├── my_state/            # 현재 상태 편집
    │   ├── notification_setting/ # 알림 시간·종류 설정
    │   ├── settings/            # 앱 설정
    │   ├── info/                # 미세먼지 정보
    │   ├── location_setup/      # GPS 기반 측정소 선택
    │   ├── tutorial/            # 튜토리얼
    │   └── splash/              # 스플래시 화면
    ├── providers/               # Riverpod 프로바이더
    └── widgets/                 # DustGaugeWidget, GradeBadge 등
```

---

## 알림 동작 방식

알림은 Android Workmanager가 백그라운드에서 15분마다 체크합니다.

```
설정한 알림 시간 ±30분 이내에 Workmanager 체크 → 알림 발송
```

| 알림 종류 | 기본 시간 | 중복 방지 |
|----------|----------|---------|
| 외출 전 알림 | 오전 7:00 | 하루 1회 |
| 전날 예보 알림 | 오후 9:00 | 하루 1회 |
| 귀가 후 알림 | 오후 6:00 | 하루 1회 |
| 실시간 경보 | 수치 급등 시 | 시간당 1회 |

> 배터리 절약 모드나 제조사별 백그라운드 제한으로 알림이 지연될 수 있습니다.  
> Android 설정 → 배터리 → 앱별 최적화에서 **"제한 없음"** 으로 설정하면 더 안정적입니다.

---

## 개인정보처리방침

앱 배포에 필요한 개인정보처리방침은 GitHub Pages로 제공됩니다.

- URL: `https://yulgoklee.github.io/mask/`
- 파일 위치: `docs/privacy-policy.html`

> Play Store 제출 시 위 URL을 개인정보처리방침 링크로 입력하세요.

---

## 데이터 출처

- 실시간 측정 데이터: [한국환경공단 에어코리아](https://www.airkorea.or.kr)
- API: [공공데이터포털 에어코리아 대기오염정보](https://www.data.go.kr/data/15073861/openapi.do)

---

## 라이선스

MIT License
