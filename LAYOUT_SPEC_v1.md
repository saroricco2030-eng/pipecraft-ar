# PIPECRAFT AR — LAYOUT_SPEC_v1.md
# UX 개선: "Result First + Shared Settings" 리팩토링 명세

> **목적**: 현장 기사가 장갑 낀 채로, 스크롤 없이, 3초 안에 결과를 확인하는 구조로 전환
> **참조**: `pipecraft_ux_prototype.html` (Before/After 비교 프로토타입)
> **원칙**: 레이아웃 + 상태관리만 변경. 계산 로직·AR 서비스·테마·데이터 모델 건드리지 않음.

---

## 0. 변경 범위 요약

| 파일 | 변경 유형 | 핵심 |
|------|-----------|------|
| `lib/main.dart` | **대폭 수정** | Machine/OD 상태를 MainShell로 끌어올림 + Settings Strip 공유 위젯 |
| `lib/features/bending/bending_screen.dart` | **대폭 수정** | Hero Result Zone + 입력 플로우 통합 + 방향 4버튼 가로 |
| `lib/features/offset/offset_screen.dart` | **대폭 수정** | Result First + 입력값 접기 + Step Guide 인라인 수치 |
| `lib/core/theme/app_theme.dart` | **미수정** | 그대로 유지 |
| `lib/core/constants/pipe_specs.dart` | **미수정** | 그대로 유지 |
| `lib/core/models/bend_result.dart` | **미수정** | 그대로 유지 |
| `lib/features/bending/bending_calculator.dart` | **미수정** | 그대로 유지 |
| `lib/services/ar_measure_service.dart` | **미수정** | 그대로 유지 |
| `lib/features/ar/ar_screen.dart` | **미수정** | 그대로 유지 |

---

## 1. main.dart — 공유 상태 + Settings Strip

### 1-1. 상태 끌어올리기

현재 `Machine _machine`과 `int _selectedOd`가 BendingScreen과 OffsetScreen 각각에 독립으로 있다.
→ **MainShell로 끌어올려서** 두 탭이 동일 값을 공유하게 한다.

```
변경 전: BendingScreen._machine, OffsetScreen._machine (각각 별도)
변경 후: _MainShellState._machine, _MainShellState._selectedOd → callback으로 전달
```

**MainShell 상태 필드 추가:**
```dart
class _MainShellState extends State<MainShell> {
  int _index = 0;
  Machine _machine = Machine.robend4000;    // ← 추가
  int _selectedOd = 15;                      // ← 추가

  @override
  void initState() {
    super.initState();
    _loadSettings();                          // ← 추가: SharedPreferences에서 복원
  }
}
```

**저장/복원:**
- SharedPreferences 키: `'global_machine'`, `'global_od'` (기존 bending 전용 키와 분리)
- 변경 시 즉시 저장
- BendingScreen/OffsetScreen 내부의 machine/od 관련 SharedPreferences 로직 제거

**전달 방식 — 콜백:**
```dart
// MainShell.build()에서
BendingScreen(
  machine: _machine,
  selectedOd: _selectedOd,
  onMachineChanged: (m) { setState(() => _machine = m); _saveSettings(); },
  onOdChanged: (od) { setState(() => _selectedOd = od); _saveSettings(); },
),
OffsetScreen(
  machine: _machine,
  selectedOd: _selectedOd,
  onMachineChanged: (m) { setState(() => _machine = m); _saveSettings(); },
  onOdChanged: (od) { setState(() => _selectedOd = od); _saveSettings(); },
),
```

### 1-2. Settings Strip — 공유 위젯

AppBar 바로 아래, 각 탭 화면 **바깥**(MainShell body 레벨)에 고정 배치.
→ 어떤 탭에서든 동일한 Settings Strip이 보인다.

**위젯 트리:**
```
MainShell
  └ Scaffold
    ├ body: Column
    │  ├ _SettingsStrip(...)          ← AppBar 없이 최상단 고정
    │  └ Expanded(IndexedStack(...))  ← 탭 영역
    └ bottomNavigationBar: NavigationBar(...)
```

**_SettingsStrip 위젯 스펙:**
```
Container
  height: 44  (8pt 그리드: 44dp)
  color: AppColors.headerBg
  padding: EdgeInsets.symmetric(horizontal: 16)
  border-bottom: 1px AppColors.border
  
  └ Row
    ├ _SettingsPill(label: '기기', value: _machine.shortLabel, onTap: → Bottom Sheet)
    ├ SizedBox(width: 8)
    ├ _SettingsPill(label: '관경', value: '${_selectedOd}mm', onTap: → Bottom Sheet)
    └ Spacer + Text(springback info, DM Mono 11sp, AppColors.text3)
```

**_SettingsPill 스펙:**
```
GestureDetector → Container
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)
  decoration: BoxDecoration(
    color: AppColors.card,
    borderRadius: 20,
    border: 1px AppColors.border,
  )
  └ Row(mainAxisSize: min)
    ├ Text(label, DM Sans 10sp w500, AppColors.text3)
    ├ SizedBox(width: 6)
    ├ Text(value, DM Mono 13sp w600, AppColors.text)
    └ SizedBox(width: 4) + Text('▼', 10sp, AppColors.text3)
```

**Machine shortLabel 확장:**
```dart
extension MachineX on Machine {
  String get shortLabel => switch (this) {
    Machine.robend4000 => 'R4000',
    Machine.remsCurvo => 'Curvo',
  };
}
```

**Bottom Sheet (기기 변경 시):**
- `showModalBottomSheet`
- Machine 목록 + 관경 목록을 세로로 나열
- 현재 선택값 하이라이트 (AppColors.primary)
- 선택 시 callback 호출 → MainShell setState → 양쪽 탭 갱신

### 1-3. AppBar 변경

**현재 구조**: 각 화면(Bending/Offset)이 자체 AppBar를 가짐
**변경**: MainShell에 단일 AppBar + Settings Strip → 각 화면은 AppBar 제거

```dart
// MainShell.build()
Scaffold(
  backgroundColor: c.background,
  appBar: AppBar(
    backgroundColor: c.card,
    elevation: 0,
    centerTitle: false,
    toolbarHeight: 48,   // 기존 56 → 48로 컴팩트
    title: Row(children: [
      Container(w:8, h:8, BoxShape.circle, c.primary),
      SizedBox(width: 8),
      Text(_appBarTitle, DM Sans 15sp w700 letterSpacing:1.0),
    ]),
    actions: [themeToggle],
  ),
  body: Column(children: [
    _SettingsStrip(...),
    Expanded(IndexedStack(index: _index, children: _screens)),
  ]),
  bottomNavigationBar: NavigationBar(...),  // 기존과 동일
)
```

`_appBarTitle`은 `_index`에 따라:
- 0 → 'PIPECRAFT AR'
- 1 → 'Offset Bending'
- 2 → 'AR 측정'

---

## 2. BendingScreen — Hero Result + 입력 통합

### 2-1. 생성자 변경

```dart
class BendingScreen extends StatefulWidget {
  final Machine machine;
  final int selectedOd;
  final ValueChanged<Machine> onMachineChanged;
  final ValueChanged<int> onOdChanged;

  const BendingScreen({
    super.key,
    required this.machine,
    required this.selectedOd,
    required this.onMachineChanged,
    required this.onOdChanged,
  });
}
```

### 2-2. 제거 항목

- `_machine` 필드 → `widget.machine` 사용
- `_selectedOd` 필드 → `widget.selectedOd` 사용
- `_buildMachineToggle()` 삭제
- `_buildPipeChips()` 삭제
- `_buildSpringBackInfo()` 삭제
- `_buildSectionLabel()` 삭제 (필요 시 인라인 텍스트로 대체)
- Machine/OD 관련 SharedPreferences 로직 삭제 (MainShell에서 처리)
- AppBar 관련 코드 삭제 (MainShell로 이동)

### 2-3. 새 화면 구조 (위젯 트리)

```
Scaffold(backgroundColor: c.background)  ← AppBar 없음
  └ Column
    ├ _HeroResultZone(...)              ← 고정, 스크롤 밖
    ├ Expanded
    │  └ SingleChildScrollView
    │    └ Column
    │      ├ _InputFlowCard(...)        ← 삽입+각도+방향 통합
    │      ├ SizedBox(height: 16)
    │      ├ _AddBendButton(...)
    │      ├ if (_bends.isNotEmpty) ...
    │      │  ├ SizedBox(height: 16)
    │      │  ├ _SummaryCard(...)       ← 기존 유지
    │      │  ├ _RoutePreview(...)      ← 기존 유지
    │      │  └ for bend in _bends → _CompactBendCard(...)  ← 간소화
    │      └ else → _EmptyState(...)
    └ _BottomBar(...)                   ← 기존 유지 (초기화 + 다음 꺾기 + AR 버튼)
```

### 2-4. _HeroResultZone 스펙

> 입력값이 변경될 때마다 실시간으로 세팅각도를 미리 보여준다.
> 꺾기를 "추가"하지 않아도 현재 설정 기준 결과를 즉시 표시.

```
Container
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [c.card, c.background],
    ),
  )
  padding: EdgeInsets.fromLTRB(16, 20, 16, 16)
  
  └ Column(crossAxisAlignment: center)
    ├ Text('세팅 각도', DM Sans 11sp w600 uppercase letterSpacing:1.5, c.text3)
    ├ SizedBox(height: 4)
    ├ Row(mainAxisAlignment: center)  ← 큰 숫자 + 단위
    │  ├ Text('${_previewSetAngle}', DM Mono 56sp w700, c.accent, letterSpacing: -2)
    │  └ Text('°', DM Sans 18sp w500, c.text3)
    ├ SizedBox(height: 12)
    └ Row(mainAxisAlignment: center, spacing: 24)
      ├ _SubItem(label: '목표', value: '${_selectedAngle.toInt()}°')
      ├ _SubItem(label: '호 길이', value: '${_previewArcLength}mm')
      └ _SubItem(label: '소비', value: '${_previewConsumed}mm')
```

**미리보기 계산:**
```dart
// BendingScreen 내부
int get _previewSetAngle {
  final sb = springBack[widget.machine]?[widget.selectedOd] ?? 2;
  return (_selectedAngle + sb).round();
}

int get _previewArcLength {
  final spec = pipeSpecs[widget.selectedOd];
  if (spec == null) return 0;
  return (spec.minRadius * (_selectedAngle * pi / 180)).round();
}

int get _previewConsumed {
  final insert = double.tryParse(_insertController.text) ?? 0;
  return (insert + _previewArcLength).round();
}
```

**_SubItem 스펙:**
```
Column(crossAxisAlignment: center)
  ├ Text(label, DM Sans 10sp w500, c.text3)
  ├ SizedBox(height: 2)
  └ Text(value, DM Mono 16sp w600, c.text)
```

### 2-5. _InputFlowCard 스펙

> 삽입길이+각도를 한 섹션, 방향을 다른 섹션으로. 하나의 카드 안에 Divider로 구분.

```
Container
  decoration: cardDeco(c)
  clipBehavior: Clip.antiAlias
  
  └ Column
    ├ ─── Section 1: 삽입 + 각도 ───
    │  Padding(14, 16)
    │  ├ Text('삽입 길이 + 각도', DM Sans 11sp w600 uppercase, c.text3)
    │  ├ SizedBox(height: 10)
    │  └ Row(crossAxisAlignment: end)
    │    ├ Expanded → Column
    │    │  └ Row(crossAxisAlignment: baseline)
    │    │    ├ TextField(기존 _insertController, DM Mono 32sp w500)
    │    │    └ Text('mm', DM Sans 14sp, c.text3)
    │    └ Row(spacing: 4)
    │      └ for angle in [30, 45, 60, 90]:
    │        GestureDetector → AnimatedContainer
    │          width: 56, height: 56       ← 장갑 터치 56dp
    │          borderRadius: 12
    │          selected → c.chipSelected / c.chipUnselected
    │          Text('${angle}°', DM Mono 15sp w600)
    │
    ├ Divider(1px, c.border)
    │
    └ ─── Section 2: 방향 ───
      Padding(14, 16)
      ├ Text('꺾는 방향', DM Sans 11sp w600 uppercase, c.text3)
      ├ SizedBox(height: 10)
      └ Row(4개 Expanded, spacing: 8)   ← 가로 4열 배치!
        for dir in [up, down, left, right]:
          GestureDetector → AnimatedContainer
            height: 56                    ← 장갑 터치 56dp
            borderRadius: 12
            border: 2px (selected → c.primary / c.border)
            selected → c.primary bg, white text
            └ Row(mainAxisAlignment: center, spacing: 6)
              ├ Icon(arrow, 20dp)
              └ Text(방향명, DM Sans 13sp w600)
```

**방향 레이블 (이모지 제거):**
```dart
extension BendDirectionX on BendDirection {
  // emoji getter 제거하거나 유지하되 UI에서 사용하지 않음
  String get shortLabel => const {
    'up': '위',
    'down': '아래',
    'left': '좌',
    'right': '우',
  }[name]!;
  
  IconData get icon => switch (this) {
    BendDirection.up => Icons.arrow_upward,
    BendDirection.down => Icons.arrow_downward,
    BendDirection.left => Icons.arrow_back,
    BendDirection.right => Icons.arrow_forward,
  };
}
```

### 2-6. 꺾기 추가 버튼

```
SizedBox(width: ∞, height: 56)            ← 기존 52 → 56dp
  └ ElevatedButton.icon
    icon: Icon(Icons.add_rounded, 20)
    label: '꺾기 추가', DM Sans 16sp w700   ← 기존 15 → 16sp
    style:
      backgroundColor: c.primary
      foregroundColor: white
      elevation: 0
      borderRadius: 14                     ← 기존 cardRadius(12) → 14
      boxShadow: [BoxShadow(c.primary.withOpacity(0.3), blur:16, offset:0,4)]
```

### 2-7. _CompactBendCard (히스토리 간소화)

> 기존 풀 카드(헤더+결과+마킹+스텝 4줄) → 1줄 컴팩트 카드로.
> 탭하면 기존 풀 카드로 확장 (ExpansionTile 또는 커스텀 토글).

**접힌 상태 (기본):**
```
Container(margin: bottom 8)
  decoration: cardDeco(c)
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)
  
  └ InkWell(onTap: → 확장 토글)
    └ Row
      ├ Container(28x28, circle, c.headerBg)
      │  └ Text('${i+1}', DM Mono 12sp w700, c.accent)
      ├ SizedBox(width: 12)
      ├ Expanded → Column(crossAxisAlignment: start)
      │  ├ Text('${angle}° ${direction.shortLabel} 방향', DM Sans 13sp w500, c.text)
      │  └ Text('삽입 ${insertLen}mm · ${pipeOd}mm', DM Sans 11sp, c.text3)
      ├ Text('${setAngle}°', DM Mono 14sp w600, c.accent)
      ├ SizedBox(width: 8)
      └ Icon(expanded ? Icons.expand_less : Icons.expand_more, c.text3)
```

**펼친 상태:**
기존 `_buildBendCard()` 내용 그대로 (결과 + 마킹 + 스텝 4줄) 카드 아래에 표시.

---

## 3. OffsetScreen — Result First + 입력 접기

### 3-1. 생성자 변경

BendingScreen과 동일:
```dart
class OffsetScreen extends StatefulWidget {
  final Machine machine;
  final int selectedOd;
  final ValueChanged<Machine> onMachineChanged;
  final ValueChanged<int> onOdChanged;
  // ...
}
```

### 3-2. 제거 항목

- `_machine` → `widget.machine`
- `_selectedOd` → `widget.selectedOd`
- `_buildMachineToggle()` 삭제
- `_buildPipeChips()` 삭제
- `_buildSpringBackInfo()` 삭제
- `_buildSectionLabel()` 삭제
- AppBar 삭제

### 3-3. 새 화면 구조

**핵심 변경**: 입력 → 결과 순서를 **결과 → 다이어그램 → 스텝 → 접힌 입력** 순서로 뒤집기.

```
Scaffold(backgroundColor: c.background)  ← AppBar 없음
  └ Column
    ├ if (_result != null)
    │  └ _OffsetHeroResult(...)          ← 고정, 스크롤 밖
    ├ Expanded
    │  └ SingleChildScrollView
    │    └ Column
    │      ├ if (_result != null) ...
    │      │  ├ _OffsetMiniDiagram(...)  ← 기존 다이어그램 축소 버전
    │      │  ├ SizedBox(height: 12)
    │      │  ├ _CompactStepGuide(...)   ← 수치 인라인
    │      │  ├ SizedBox(height: 12)
    │      │  └ _CollapsedInputBar(...)  ← 입력값 한 줄 요약 + 펼치기
    │      ├ if (_result == null)
    │      │  └ _InputExpandedCard(...)  ← 입력 풀 표시 (결과 없을 때)
    │      ├ SizedBox(height: 12)
    │      └ _AngleButtons(...)          ← 각도 선택은 항상 노출
    └ _ArButton(...)                     ← 기존과 동일
```

### 3-4. _OffsetHeroResult 스펙

```
Container
  padding: EdgeInsets.fromLTRB(16, 16, 16, 12)
  
  └ Column
    ├ Row(mainAxisAlignment: center, spacing: 32)
    │  ├ Column(center)
    │  │  ├ Text('B1 삽입', DM Sans 11sp w600, c.text3)
    │  │  ├ SizedBox(height: 4)
    │  │  └ RichText
    │  │    ├ TextSpan('${b1Insert}', DM Mono 36sp w700, c.accent)
    │  │    └ TextSpan('mm', DM Sans 14sp, c.text3)
    │  └ Column(center)
    │    ├ Text('B2 삽입', DM Sans 11sp w600, c.text3)
    │    ├ SizedBox(height: 4)
    │    └ RichText
    │      ├ TextSpan('${b2Insert}', DM Mono 36sp w700, c.accent)
    │      └ TextSpan('mm', DM Sans 14sp, c.text3)
    │
    ├ SizedBox(height: 12)
    └ Row(mainAxisAlignment: center, spacing: 20)
      ├ _MiniStat('세팅', '${setAngle}°', c.accent)
      ├ _MiniStat('경사', '${offsetLength}mm', c.text)
      └ _MiniStat('총', '${totalLength}mm', c.text)
```

**_MiniStat:**
```
RichText(
  Text('$label ', DM Sans 12sp, c.text3),
  Text('$value', DM Mono 12sp w700, $valueColor),
)
```

### 3-5. _CompactStepGuide 스펙

> 기존 StepGuide의 subtitle를 제거하고, 핵심 수치를 오른쪽에 크게 배치.

```
Container
  decoration: cardDeco(c)
  clipBehavior: Clip.antiAlias
  
  └ Column
    for (i, step) in steps:
      InkWell(onTap: → toggle step)
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)
        border-bottom: 1px c.border (마지막 제외)
        └ Row
          ├ Container(28x28, circle)
          │  done → c.accent bg, white text
          │  pending → c.headerBg, c.text2
          │  └ Text('${i+1}', DM Mono 12sp w700)
          ├ SizedBox(width: 12)
          ├ Expanded → Text(step.title, DM Sans 13sp w600, c.text)
          │  ※ done → lineThrough
          └ Text(step.value, DM Mono 15sp w700, c.accent)
            ※ 마지막 단계(평행확인)는 '✓' 표시
```

**steps 데이터:**
```dart
final steps = [
  (title: 'B1 마킹', value: '${r.b1Insert.round()}mm'),
  (title: 'B1 꺾기 (장애물 방향)', value: '${setAngle}°'),
  (title: 'B2 마킹', value: '${r.b2Insert.round()}mm'),
  (title: 'B2 꺾기 (반대 방향)', value: '${setAngle}°'),
  (title: '평행 확인', value: '✓'),
];
```

### 3-6. _CollapsedInputBar 스펙

> 결과가 있을 때 입력값을 한 줄로 접어서 보여줌. 탭하면 펼침.

```
GestureDetector(onTap: → setState _inputExpanded toggle)
  Container
    decoration: BoxDecoration(c.headerBg, borderRadius: 12, border: 1px c.border)
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)
    
    └ Row
      ├ Expanded → Wrap(spacing: 16)
      │  ├ _InlineVal('높이', _heightCtrl.text)
      │  ├ _InlineVal('폭', _widthCtrl.text)
      │  ├ _InlineVal('앞', _preCtrl.text)
      │  └ _InlineVal('뒤', _postCtrl.text)
      └ Text('수정 ▼' / '접기 ▲', DM Sans 10sp, c.text3)

if (_inputExpanded)
  AnimatedContainer / AnimatedSize
    └ _buildInputCard(c)   ← 기존 4개 입력필드 카드 그대로 재사용
```

**_InlineVal:**
```
RichText(
  Text('$label ', DM Sans 12sp, c.text3),
  Text('$value', DM Mono 12sp w600, c.text),
)
```

### 3-7. 입력값 없는 초기 상태

`_result == null`일 때는 입력 카드가 펼쳐진 상태로 보이고, Hero는 숨김.
→ 기존 `_buildInputCard(c)` + `_buildAngleButtons(c)` 그대로 표시.

---

## 4. 공통 수치 규격

### 터치 타겟 (장갑 환경 56dp)

| 요소 | 현재 | 변경 후 |
|------|------|---------|
| 방향 버튼 | 52×52dp (D-pad) | 56dp 높이 × Expanded 너비 (가로 4열) |
| 각도 버튼 | ~44dp 높이 | 56×56dp 정사각 |
| 관경 칩 | 40dp 높이 | 제거됨 (pill → Bottom Sheet) |
| 꺾기 추가 버튼 | 52dp | 56dp |
| AR 버튼 | 52dp | 56dp |

### 8pt 그리드 수치

```
padding 전체: 16dp (수평)
카드 내부 padding: 14~16dp
요소 간 gap: 8, 12, 16, 20, 24dp
borderRadius: 카드 12dp, 버튼 12~14dp, pill 20dp
Hero 숫자: 56sp (밴딩 세팅각도), 36sp (오프셋 B1/B2)
보조 수치: 16sp
라벨: 10~11sp uppercase
```

### 폰트 맵

| 용도 | 폰트 | 크기 | Weight |
|------|-------|------|--------|
| Hero 숫자 | DM Mono | 56sp | 700 |
| 중형 숫자 | DM Mono | 36sp | 700 |
| 인라인 수치 | DM Mono | 15~16sp | 600 |
| 입력 필드 | DM Mono | 32sp | 500 |
| 섹션 라벨 | DM Sans | 11sp | 600, uppercase, letterSpacing 0.5~1.5 |
| 본문 | DM Sans | 13sp | 500~600 |
| 보조 텍스트 | DM Sans | 11~12sp | 400~500 |

---

## 5. 상태 변화 인터랙션

### 밴딩 탭 — 실시간 미리보기

1. 사용자가 삽입길이 TextField 입력 → `onChanged` → `setState` → Hero 숫자 업데이트
2. 각도 버튼 탭 → `setState(_selectedAngle = a)` → Hero 업데이트
3. 방향 버튼 탭 → `setState(_selectedDirection = dir)` (Hero에는 영향 없음)
4. "꺾기 추가" → 기존 `_addBend()` 로직 그대로 → 리스트에 추가
5. Settings pill 탭 → Bottom Sheet → 기기/관경 변경 → Hero 업데이트

### 오프셋 탭 — 입력 접기/펼치기

1. 초기: `_result == null` → 입력 카드 펼침, Hero 숨김
2. 유효한 값 입력 → `_calculate()` → `_result != null` → Hero 표시, 입력 접힘
3. "수정 ▼" 탭 → `_inputExpanded = true` → 입력 카드 애니메이션 펼침
4. 입력값 변경 → `_calculate()` → Hero 실시간 업데이트
5. "접기 ▲" 탭 → `_inputExpanded = false`

---

## 6. 마이그레이션 주의사항

### 보존 필수 (건드리지 마)

- `BendingCalculator.calculate()` / `OffsetCalculator.calculate()` 로직 전체
- `_BendEntry` 클래스 (toJson/fromJson 포함)
- `BendDirection` enum + extensions (기존 emoji/label은 유지, shortLabel만 추가)
- `_RoutePainter` / `_OffsetPainter` CustomPainter 전체
- `ArMeasureService` 호출 로직 전체
- 하단 AR 버튼 동작 (밴딩: 직접 삽입길이 입력, 오프셋: 필드 선택 Bottom Sheet)
- SharedPreferences 밴딩 데이터 저장/복원 (`_prefsKeyBends`) — 기기/OD 키만 글로벌로 이전
- 테마 토글 (ThemeController) 로직
- 다이얼로그: 초기화 확인, 권한 거부

### 삭제 OK

- 각 화면의 Machine 토글 위젯
- 각 화면의 관경 칩 위젯
- 각 화면의 SpingBack 정보 라인
- 각 화면의 섹션 라벨 빌더 (`_buildSectionLabel`)
- 각 화면의 자체 AppBar

### SharedPreferences 키 변경

```
기존 (삭제):
  'bending_machine' → 제거
  'bending_od' → 제거

신규 (MainShell):
  'global_machine' → Machine.index
  'global_od' → int

유지:
  'bending_data' → 밴딩 히스토리 JSON (기존 그대로)
  'theme_mode' → 테마 (기존 그대로)
```

### 마이그레이션 로직 (1회)

MainShell `_loadSettings()`에서:
1. 먼저 `'global_machine'` / `'global_od'` 시도
2. 없으면 `'bending_machine'` / `'bending_od'`에서 읽어와서 global로 복사
3. 구 키 삭제

---

## 7. 작업 순서 (Claude Code용)

```
STEP 1: main.dart 수정
  - Machine/OD 상태를 _MainShellState로 이동
  - SharedPreferences global 키 + 마이그레이션
  - _SettingsStrip + _SettingsPill 위젯 추가
  - AppBar를 MainShell로 통합
  - BendingScreen/OffsetScreen 생성자에 콜백 파라미터 추가
  - Bottom Sheet (기기/관경 선택) 구현
  → flutter analyze 통과 확인

STEP 2: bending_screen.dart 수정
  - 생성자 변경 (machine/od/callbacks)
  - Machine 토글, 관경 칩, SpingBack, AppBar 제거
  - _HeroResultZone 추가 (미리보기 계산)
  - _InputFlowCard (삽입+각도+방향 통합)
  - 방향 D-pad → 가로 4버튼
  - _CompactBendCard (접기/펼치기)
  - 꺾기 추가 버튼 56dp
  - BendDirection.shortLabel / icon 확장 추가
  → flutter analyze 통과 확인

STEP 3: offset_screen.dart 수정
  - 생성자 변경
  - Machine 토글, 관경 칩, AppBar 제거
  - _OffsetHeroResult 추가
  - _CompactStepGuide (수치 인라인)
  - _CollapsedInputBar (접기/펼치기)
  - 레이아웃 순서: Hero → 다이어그램 → 스텝 → 입력
  → flutter analyze 통과 확인

STEP 4: 최종 검증
  - 전체 flutter analyze --no-fatal-infos
  - 다크/라이트 모드 양쪽 AppColors 토큰만 사용 확인
  - 문자열 리터럴 → i18n 키 변환 (기존에도 하드코딩이므로 현상 유지 또는 별도 태스크)
```

---

## 8. 참고 — 현재 코드 파일 위치

```
lib/
  main.dart                              ← STEP 1
  core/
    constants/pipe_specs.dart            (미수정)
    models/bend_result.dart              (미수정)
    theme/app_theme.dart                 (미수정)
  features/
    bending/
      bending_calculator.dart            (미수정)
      bending_screen.dart                ← STEP 2
    offset/
      offset_screen.dart                 ← STEP 3
    ar/
      ar_screen.dart                     (미수정)
  services/
    ar_measure_service.dart              (미수정)
```
