# PIPECRAFT AR

HVAC-R 배관 밴딩 계산 + ARCore 실측 거리 측정 Flutter 앱 (Android only)

## 앱 구조 (3탭)

| 탭 | 화면 | 기능 |
|----|------|------|
| 밴딩 | `BendingScreen` | 삽입길이 → 세팅각도 + 호길이 + 단축량 자동 산출 |
| 오프셋 | `OffsetScreen` | 장애물 높이/폭 → B1/B2 삽입길이 자동 산출 |
| AR 측정 | `ArScreen` | ARCore 다중 포인트 거리 측정 → 밴딩/오프셋에 자동 입력 |

## 아키텍처

```
Flutter UI (Dart) ↔ MethodChannel "pipecraft/ar_measure" ↔ Android Native (Kotlin + ARCore 1.47.0 + OpenGL ES 2.0)
```

- ARCore 플러그인 안 씀 → Platform Channel로 네이티브 직접 구현
- AR 액티비티에서 측정 후 거리(mm) double을 Flutter로 반환
- 상태관리: setState (Provider 미사용)

## 파일 구조

```
lib/
├── main.dart                              — 앱 진입점, 3탭 네비게이션 (IndexedStack), 세로 고정
├── core/
│   ├── constants/pipe_specs.dart          — 관경별 스펙(OD→최소반경), 스프링백 보정값
│   └── models/bend_result.dart            — BendResult 모델
├── features/
│   ├── bending/
│   │   ├── bending_calculator.dart        — BendingCalculator + OffsetCalculator (div-by-zero 보호)
│   │   └── bending_screen.dart            — 밴딩 화면 (방향패드, 꺾기 리스트, 체크리스트, 경로 미리보기)
│   ├── offset/
│   │   └── offset_screen.dart             — 오프셋 화면 (기기/관경 선택, 작업 가이드, 다이어그램)
│   └── ar/
│       └── ar_screen.dart                 — AR 측정 기록 + 개별 삭제 + 측정 버튼
└── services/
    └── ar_measure_service.dart            — MethodChannel 브릿지, 카메라 권한

android/app/src/main/kotlin/com/athvacr/pipecraft_ar/
├── MainActivity.kt                        — Flutter↔Native 브릿지 (레이스 컨디션 보호)
├── ArMeasureActivity.kt                   — AR 핵심 (스레드 안전 anchors, @Volatile 상태)
└── rendering/
    ├── BackgroundRenderer.kt              — 카메라 피드 GL 렌더링
    └── PointLineRenderer.kt               — 포인트(원형 80px) + 라인(60px), 버퍼 재사용, 링크 체크
```

## 밴딩 계산 공식

```
setAngle = targetAngle + springBack[machine][od]
arcLength = minRadius[od] × (targetAngle × π / 180)
shortenLength = arcLength
consumedLength = insertLength + arcLength
```

## 오프셋 계산 공식

```
offsetLength = obsHeight / sin(angle)
horizMove = obsHeight / tan(angle)
b1Insert = preDist
b2Insert = preDist + offsetLength
totalLength = preDist + offsetLength×2 + obsWidth + postDist
```

## 지원 기기 & 스프링백 보정값 (°)

| 관경(mm) | ROBEND 4000 (ROTHENBERGER) | REMS Curvo |
|----------|---------------------------|------------|
| 15       | 2                         | 2          |
| 19       | 2                         | 2          |
| 22       | 3                         | 2          |
| 25       | 3                         | 3          |
| 28       | 3                         | 3          |
| 35       | 4                         | 4          |

## 관경별 최소 곡률반경 (mm)

| 15→45 | 19→57 | 22→66 | 25→75 | 28→84 | 35→105 |

## AR 측정 동작

1. Flutter "AR 측정 시작" → `ArMeasureService.getDistance()`
2. MethodChannel → `MainActivity` → `ArMeasureActivity` 실행
3. ARCore 세션 (평면감지 + Instant Placement 폴백)
4. 터치 → hitTest 앵커 배치 (Plane > Point > InstantPlacement)
5. **다중 포인트**: 1→2→3→4... 무제한, 연속 라인 연결, 구간별+합계 거리 표시
6. 버튼: 되돌리기 / 초기화 / 확인
7. 확인 → 합계 거리(mm) double로 Flutter 반환

### AR 렌더링 스펙
- 포인트: 원형 80px (gl_PointCoord + smoothstep), 시작점 파란색, 이후 앰버색
- 라인: 60px, 파란색 `(0.22, 0.74, 0.97)`

## UI 현황

현재 **라이트 테마** 적용:
- 배경: `#F5F3F0`, 주요: `#C8102E` (레드), 강조: `#1A7A4A` (그린)
- 폰트: DM Sans (텍스트) + DM Mono (수치)
- 카드: 흰색, radius 12

## 기술 스택

- Flutter (Android only), Dart ^3.10.8
- ARCore SDK 1.47.0 (네이티브 Kotlin)
- OpenGL ES 2.0
- App ID: `com.athvacr.pipecraft_ar`, Min SDK 24
- 패키지: permission_handler 11.3.0, shared_preferences 2.3.0
- 테스트 기기: SM-S938N

## 개발 규칙

1. **파일 구조 변경 전 반드시 확인** — 기존 구조를 먼저 파악한 후 수정
2. **Plan → Implement → Validate** 순서 엄수
3. **기능 단위로 커밋** — 하나의 커밋에 하나의 기능
4. 밴딩 공식 변경 시 반드시 검증 데이터와 대조
5. ARCore 관련 코드는 실기기 테스트 필수
