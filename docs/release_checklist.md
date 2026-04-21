# 출시 체크리스트

> 기준일: 2026-04-22 | 대상: mask_alert Android Play Store 출시

---

## 1. 버전 정보 (`android/app/build.gradle.kts`)

`build.gradle.kts`는 `flutter.versionCode` / `flutter.versionName`을 사용하므로
실제 값은 `pubspec.yaml`의 `version` 필드가 기준.

| 항목 | 현재 값 |
|---|---|
| pubspec.yaml version | `1.0.4+6` |
| versionName (Play Store 표시) | `1.0.4` |
| versionCode (정수 빌드 번호) | `6` |

- ✅ 이상 없음 — 출시 전 `pubspec.yaml` version 값을 올려서 versionCode를 이전 출시보다 크게 유지해야 함.

---

## 2. SDK 버전 (`android/app/build.gradle.kts`)

`minSdk`, `targetSdk`, `compileSdk` 모두 Flutter SDK 기본값 위임(`flutter.*`).
Flutter SDK (현재 설치본) 기본값:

| 항목 | 현재 값 | Play Store 요건 (2026) |
|---|---|---|
| minSdkVersion | 24 (Android 7.0) | 제한 없음 |
| targetSdkVersion | **36** | **35 이상 필수** |
| compileSdkVersion | 36 | — |

- ✅ 이상 없음 — targetSdk 36으로 Play Store 2026년 기준(35+) 충족.

---

## 3. ProGuard/R8 — Crashlytics 매핑 파일 업로드

`build.gradle.kts` 플러그인 선언:
```
id("com.google.firebase.crashlytics")
```

- ✅ 이상 없음 — Crashlytics Gradle 플러그인이 릴리스 빌드 시 R8 매핑 파일을 Firebase에 **자동** 업로드함. 별도 설정 불필요.
- 참고: `firebaseCrashlyticsMappingFileUploadEnabled = false`로 비활성화하지 않았으므로 기본 활성 상태.

---

## 4. 서명 키 (`android/key.properties`)

- ✅ 파일 존재 확인 — `android/key.properties` 로컬에 존재함 (gitignore 대상, 내용 미확인).
- `build.gradle.kts`에 조건부 로드 로직 있음 (`if (keyPropertiesFile.exists())`).
- 주의: CI/CD 환경이나 새 머신에서는 `key.properties`와 keystore 파일을 별도로 배치해야 함.

---

## 5. AndroidManifest.xml 권한 목록

파일: `android/app/src/main/AndroidManifest.xml`

| 권한 | 용도 | 상태 |
|---|---|---|
| `INTERNET` | API 호출, Firebase | ✅ |
| `ACCESS_FINE_LOCATION` | GPS 위치 감지 | ✅ |
| `ACCESS_COARSE_LOCATION` | 대략 위치 | ✅ |
| `ACCESS_BACKGROUND_LOCATION` | 백그라운드 위치 | ✅ 명시적 제거 (`tools:node="remove"`) |
| `POST_NOTIFICATIONS` | 알림 (Android 13+) | ✅ |
| `RECEIVE_BOOT_COMPLETED` | 기기 재시작 후 알림 복구 | ✅ |
| `WAKE_LOCK` | 백그라운드 작업 | ✅ |
| `FOREGROUND_SERVICE` | WorkManager foreground | ✅ |

- ✅ 이상 없음 — 백그라운드 위치 권한이 명시적으로 제거되어 있어 Play Store 심사 위험 없음.

---

## 6. 개인정보처리방침 URL

- Play Store 등록 URL: `https://yulgoklee.github.io/mask/`
- 파일 위치: `docs/privacy-policy.html` (GitHub Pages 서빙)
- `docs/index.html` → `privacy-policy.html` 리다이렉트 설정 있음.

- [ ] 확인 필요 — GitHub Pages가 해당 URL로 실제 서빙 중인지 브라우저에서 직접 접속 확인 필요.
  - 해결: GitHub 레포 Settings > Pages에서 `docs` 폴더로 소스가 설정되어 있는지 확인.

---

## 7. 앱 아이콘 (`android/app/src/main/res/`)

| 폴더 | 파일 | 상태 |
|---|---|---|
| `mipmap-mdpi` | `ic_launcher.png` | ✅ |
| `mipmap-hdpi` | `ic_launcher.png` | ✅ |
| `mipmap-xhdpi` | `ic_launcher.png` | ✅ |
| `mipmap-xxhdpi` | `ic_launcher.png` | ✅ |
| `mipmap-xxxhdpi` | `ic_launcher.png` | ✅ |
| `mipmap-anydpi-v26` | adaptive icon | [ ] 확인 필요 |

- [ ] `mipmap-anydpi-v26` 폴더 없음 — Android 8.0+ 적응형 아이콘 미설정.
  - 해결: `flutter_launcher_icons` 패키지로 adaptive icon 생성하거나, `ic_launcher.xml` + `ic_launcher_background.xml`/`ic_launcher_foreground.xml` 수동 추가.
  - Play Store 심사 통과는 가능하나, Android 8+ 기기에서 아이콘이 잘릴 수 있음.

---

## 8. 출시용 AAB 빌드

```bash
flutter build appbundle --release
```

- 출력 경로: `build/app/outputs/bundle/release/app-release.aab`
- Play Console에서 해당 `.aab` 파일을 업로드.
- ✅ `build.gradle.kts` release signingConfig가 `key.properties` 기반으로 설정되어 있음.
- 주의: `key.properties`가 없으면 서명 없이 빌드되어 Play Console 업로드 불가.
