# PIPECRAFT AR

HVAC-R 배관 밴딩 계산 + ARCore 실측 거리 측정 앱

## Features

### Bending Calculator
삽입길이, 목표각도, 관경, 기기를 입력하면 **세팅각도 / 호길이 / 단축량**을 자동 산출합니다.
스프링백 보정값이 기기별로 자동 적용됩니다.

### Offset Bending
장애물 높이/폭을 입력하면 **B1·B2 삽입길이 / 오프셋 길이 / 전체 배관 길이**를 산출합니다.

### AR Measurement
ARCore 기반 다중 포인트 거리 측정. 2점 이상 터치로 구간별·합계 거리를 실측하고, 결과를 밴딩 계산에 바로 연동할 수 있습니다.

## Supported Machines

| Pipe OD (mm) | ROBEND 4000 | REMS Curvo | Min. Bend Radius (mm) |
|:---:|:---:|:---:|:---:|
| 15 | 2° | 2° | 45 |
| 19 | 2° | 2° | 57 |
| 22 | 3° | 2° | 66 |
| 25 | 3° | 3° | 75 |
| 28 | 3° | 3° | 84 |
| 35 | 4° | 4° | 105 |

## Tech Stack

| | |
|---|---|
| Framework | Flutter (Android only) |
| Language | Dart 3.10 + Kotlin |
| AR | ARCore SDK 1.47.0 (native, via Platform Channel) |
| Rendering | OpenGL ES 2.0 |
| Min SDK | 24 (Android 7.0) |

## Project Structure

```
lib/
├── main.dart                         # Entry point, 3-tab navigation
├── core/
│   ├── constants/pipe_specs.dart     # Pipe specs & springback values
│   └── models/bend_result.dart       # BendResult model
├── features/
│   ├── bending/
│   │   ├── bending_calculator.dart   # Bending & Offset calculators
│   │   └── bending_screen.dart       # Bending UI
│   ├── offset/
│   │   └── offset_screen.dart        # Offset bending UI
│   └── ar/
│       └── ar_screen.dart            # AR measurement history
└── services/
    └── ar_measure_service.dart       # MethodChannel bridge

android/.../kotlin/com/athvacr/pipecraft_ar/
├── MainActivity.kt                   # Flutter ↔ Native bridge
├── ArMeasureActivity.kt              # ARCore session & hit testing
└── rendering/
    ├── BackgroundRenderer.kt         # Camera feed GL rendering
    └── PointLineRenderer.kt          # Point & line GL rendering
```

## Build

```bash
flutter pub get
flutter build apk --debug
```

> ARCore 지원 기기 필요. 에뮬레이터에서는 AR 측정이 동작하지 않습니다.

## License

MIT
