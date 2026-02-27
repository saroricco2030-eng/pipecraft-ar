# PIPECRAFT AR — 프로젝트 브리핑

HVAC-R 배관 밴딩 계산 + ARCore 실측 거리 측정 Flutter 앱 (Android only)

---

## 앱 구조 (3탭 구성)

| 탭 | 화면 | 기능 |
|----|------|------|
| 1. 밴딩 | `BendingScreen` | 삽입길이 → 세팅각도 + 호길이 + 단축량 자동 산출 |
| 2. 오프셋 | `OffsetScreen` | 장애물 높이/폭 → B1/B2 삽입길이 자동 산출 |
| 3. AR 측정 | `ArScreen` | ARCore로 2점+ 거리 측정 → 밴딩/오프셋에 자동 입력 |

---

## 핵심 아키텍처

```
Flutter UI (Dart)
    ↕ MethodChannel "pipecraft/ar_measure"
Android Native (Kotlin)
    ↕ ARCore SDK 1.40.0 + OpenGL ES 2.0
```

- ARCore 플러그인 안 씀 → 직접 Platform Channel로 네이티브 구현
- AR 액티비티에서 측정 후 거리(mm) double 값을 Flutter로 반환
- Flutter에서는 Provider 없이 setState로 상태 관리 중

---

## 파일 구조 & 역할

### Flutter (Dart)
```
lib/
├── main.dart                          — 앱 진입점, 3탭 네비게이션 (IndexedStack)
├── core/
│   ├── constants/pipe_specs.dart      — 관경별 스펙(OD→최소반경), 스프링백 보정값 테이블
│   └── models/bend_result.dart        — BendResult 모델 (setAngle, arcLength, shortenLength 등)
├── features/
│   ├── bending/
│   │   ├── bending_calculator.dart    — BendingCalculator + OffsetCalculator 계산 엔진
│   │   └── bending_screen.dart        — 밴딩 화면 UI (532줄)
│   ├── offset/
│   │   └── offset_screen.dart         — 오프셋 화면 UI (534줄)
│   └── ar/
│       └── ar_screen.dart             — AR 측정 기록 리스트 + 측정 버튼 (275줄)
├── services/
│   └── ar_measure_service.dart        — MethodChannel 브릿지, 카메라 권한 처리
└── shared/widgets/
    └── pipe_selector.dart             — (비어있음)
```

### Android Native (Kotlin)
```
android/app/src/main/kotlin/com/athvacr/pipecraft_ar/
├── MainActivity.kt                    — Flutter↔Native 브릿지 (MethodChannel 핸들러)
├── ArMeasureActivity.kt               — AR 핵심! GLSurfaceView.Renderer 구현 (631줄)
└── rendering/
    ├── BackgroundRenderer.kt          — 카메라 피드 GL 렌더링 (187줄)
    └── PointLineRenderer.kt           — 포인트(원형) + 라인 GL 렌더링 (125줄)
```

---

## 밴딩 계산 공식

```
setAngle = targetAngle + springBack[machine][od]
arcLength = minRadius[od] × (targetAngle × π / 180)
shortenLength = arcLength
consumedLength = insertLength + arcLength
```

### 오프셋 계산 공식
```
offsetLength = obsHeight / sin(angle)
horizMove = obsHeight / tan(angle)
b1Insert = preDist
b2Insert = preDist + offsetLength
totalLength = preDist + offsetLength×2 + obsWidth + postDist
```

---

## 지원 기기 & 스프링백 보정값 (°)

| 관경(mm) | ROBEND 4000 | REMS Curvo |
|----------|-------------|------------|
| 15       | 2           | 2          |
| 19       | 2           | 2          |
| 22       | 3           | 2          |
| 25       | 3           | 3          |
| 28       | 3           | 3          |
| 35       | 4           | 4          |

## 관경별 최소 곡률반경 (mm)

| 15 → 45 | 19 → 57 | 22 → 66 | 25 → 75 | 28 → 84 | 35 → 105 |

---

## AR 측정 동작 방식

1. Flutter에서 "AR 측정 시작" 버튼 → `ArMeasureService.getDistance()` 호출
2. MethodChannel → `MainActivity` → `ArMeasureActivity` 실행
3. ARCore 세션 시작 (평면감지 + Instant Placement 폴백)
4. 화면 터치 → hitTest로 앵커 배치 (우선순위: Plane > Point > InstantPlacement)
5. **다중 포인트 지원**: 1→2→3→4... 무제한 포인트 추가 가능
6. 연속된 포인트 간 라인 자동 연결 + 구간별 거리 + 합계 표시
7. 버튼: 되돌리기(마지막 포인트 제거) / 초기화(전체 리셋) / 확인(합계 반환)
8. "확인" → `setResult(RESULT_OK, 합계거리mm)` → Flutter로 double 반환

### AR 렌더링 스펙
- 포인트: **80px 원형** (fragment shader에서 gl_PointCoord 마스킹 + smoothstep 안티앨리어싱)
- 라인: **60px 두께** (현장 가시성 확보)
- 시작점: 파란색 `(0.22, 0.74, 0.97)`, 이후 포인트: 앰버색 `(1.0, 0.62, 0.04)`
- 라인: 파란색

---

## UI 디자인 현황

현재 **라이트 테마** 적용 중 (CLAUDE.md에는 다크테마라고 되어있지만 실제 구현은 라이트):
- 배경: `#F5F3F0` (베이지)
- 주요 색상: `#C8102E` (레드)
- 강조 색상: `#1A7A4A` (그린, 결과값 표시)
- 카드: 흰색, radius 12
- 폰트: DM Sans (텍스트) + DM Mono (수치)

---

## 기술 스택

- **Flutter** (Android only), Dart ^3.10.8
- **ARCore SDK 1.40.0** (네이티브 Kotlin)
- **OpenGL ES 2.0** (AR 렌더링)
- **패키지**: provider 6.1.1, go_router 13.0.0, permission_handler 11.3.0
- **App ID**: `com.athvacr.pipecraft_ar`
- **Min SDK**: 24
- **테스트 기기**: SM-S938N (갤럭시)

---

## 최근 작업 이력 (2026-02-27)

1. AR 포인트를 사각형 20px → **원형 80px**로 변경 (shader 수정)
2. AR 라인 두께 5px → **60px**로 변경
3. **다중 포인트 측정** 구현 (2점 제한 해제 → 무제한)
4. **되돌리기 버튼** 추가 (마지막 포인트 제거)
5. 구간별 거리 + 합계 표시 UI 추가

---

## 개발 규칙

1. 파일 구조 변경 전 반드시 기존 구조 파악
2. Plan → Implement → Validate 순서
3. 기능 단위 커밋
4. 밴딩 공식 변경 시 검증 데이터 대조 필수
5. ARCore 코드는 실기기 테스트 필수
