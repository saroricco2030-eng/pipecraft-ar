# 앱 개발 공통 수칙

> AI 개발 파트너 행동 원칙
>
> ┌─ 지식베이스 구조 (범용 2파일 + 프로젝트 1파일) ──────────────────────────┐
> │  3개 파일은 서로를 교차 참조한다. 하나라도 빠지면 참조 연결이 끊긴다.  │
> │  Claude Code 환경 : 프로젝트 루트에 파일 배치 → 자동 로드             │
> │  일반 채팅 환경   : 코딩 요청 시 관련 파일 동시 첨부 필수              │
> │                                                                        │
> │  ★ 코딩 전 필수 확인 순서 (매번) — 이 목록이 유일한 기준              │
> │    1. 이 파일 "디자인 시스템" → AppColors 토큰 + 다크/라이트 스타일 확인│
> │       (비어있으면 토큰 작성 요청)                                      │
> │    2. 이 파일 "특이사항" → 터치 기준 / RBAC 역할 확인                 │
> │    3. 이 파일 "0-1 Phase" → 현재 Phase 범위 확인                      │
> │    4. DESIGN_MASTER PART 13·14 → 컴포넌트 + 페르소나 확인            │
> │    5. SECURITY_MASTER PART 13 → 프로젝트 특화 보안 확인               │
> │                                                                        │
> │  DESIGN_MASTER_v3.1.md          ← 범용 / 프로젝트 무관                │
> │    비주얼·UX·IA·오프라인·알람·성능 / Flutter 코드(PART 12)            │
> │    ※ PART 5-3 컬러 토큰 → 이 파일 "디자인 시스템" 섹션이 덮어씀      │
> │    ※ PART 13(Phase 컴포넌트) · PART 14(도메인 UX) → 프로젝트별 작성 │
> │                                                                        │
> │  SECURITY_MASTER_v4.md          ← 범용 / 프로젝트 무관                │
> │    보안 12개 레이어 · RBAC · 데이터 거버넌스                          │
> │    ★ 보안·RBAC·CLIENT_VIEW 관련 단일 출처(Source of Truth)            │
> │    ※ PART 13(도메인 특화 보안) → 이 파일 "특이사항" 섹션과 연동      │
> │                                                                        │
> │  [프로젝트명]_FEATURE_UNIVERSE.md  ← 프로젝트 전용                   │
> │    해당 프로젝트 기능 전체 정의 + Phase 로드맵                        │
> │    (없는 경우 이 CLAUDE.md 하단 "프로젝트 정보" 섹션에 직접 기재)    │
> └────────────────────────────────────────────────────────────────────────┘
>
> **AI 행동 원칙**
> - 이 파일을 어기는 코드·설계 발견 시 즉시 알리고 수정 방향을 제안한다
> - 모호한 요청은 구현 전에 의도를 확인한다
> - 잘못된 방향이라 판단되면 솔직하게 피드백한다
> - 선택지 필요 시 근거와 함께 제시하고 결정을 기다린다
> - Firestore/DB 구조 확정 시 "데이터 구조" 섹션에 즉시 반영
> - 설계 변경 시 기존 내용 수정 + 변경 이유 한 줄 메모
>
> **기능 완성 기록**
> - Claude Code 환경: AI가 이 파일을 직접 수정하여 기록 (`- [YYYY-MM-DD] 기능명: 설명`)
> - 일반 채팅 환경: AI가 완성 내용을 알려주면 사업주가 직접 파일에 기록

---

> **섹션 참조 시점 가이드**
> ```
> [매 화면 코딩 시 — 항상]  섹션 0~0-2, 1(i18n), 3(UX), 4(디자인)
> [특정 시점에만]           섹션 2(보안) → 인증/API/DB 작업 시
>                          섹션 5(Post-Build) → Phase 완료 시
>                          섹션 6(경쟁앱) → 신규 기능 설계 시
> [프로젝트 설정 시 1회]    섹션 7~12
> ```

## 0. 개발 워크플로우

모든 기능 요청은 아래 순서를 따른다.

```
1. PLAN      — 요구사항 분석 · 사용자 흐름 확인
               현재 Phase 범위 확인 (섹션 0-1)
               ※ 신규 기능 설계 시만: 경쟁앱 레퍼런스 검토 (섹션 6)
               ※ 단순 수정/추가: 경쟁앱 분석 스킵
2. IMPLEMENT — 완성형 코드 제공 (바로 실행 가능한 상태)
               섹션 0-2 자동 적용 규칙 전체 적용
3. VALIDATE  — 2단계 검증 실행 (아래 참조)
```

**검증 2단계 체계**
```
[인라인 검증] — 코드 생성 직후 매번 실행 (빠른 self-check)
  → 섹션 1 i18n 검증 (5단계)
  → 섹션 4-6 디자인 검증 (6단계)
  → 섹션 3 UX 핵심 체크 (3항목):
    ✓ 3상태(Loading/Empty/Error) 구현 여부
    ✓ 주요 CTA 엄지존(하단) 배치 여부
    ✓ 모든 액션에 상태 피드백 존재 여부
  → 리포트 (이 형식이 유일한 출력):
    "검증 완료 — i18n 키 N개 / 디자인 위반 N건 / UX 이상 없음"
    ※ 섹션 1·4-6의 개별 리포트는 내부 절차. 최종 출력은 이 통합 형식 1회.

[종합 검증] — Phase 완료 시 실행 (전수 검사)
  → DESIGN_MASTER PART 8 체크리스트 전체 (i18n·UX·디자인·성능 모두 포함)
  → Post-Build Review (섹션 5) — 리뷰어 시점 평가
  → 개선 포인트 리포트
```

- 파일 구조 변경 · 대규모 리팩토링은 반드시 사전 확인 후 진행
- 에러 발생 시: 원인 + 해결책을 함께 보고

---

## 0-1. Phase 개발 순서

> **현재 구현 중인 Phase 외의 기능은 절대 구현하지 않는다.**
> Phase 경계를 넘는 구현 요청은 수락 전 반드시 확인한다.

```
PHASE 1 — [핵심 코어] ✅ 완료
  밴딩 계산기 (스프링백 보정, 다중 꺾기, 경로 미리보기)
  오프셋 계산기 (장애물 우회, 삽입길이, 세팅각도)
  AR 거리 측정 (ARCore 다중 포인트, 구간별 거리)
  테마 시스템 (다크/라이트/시스템 전환, SharedPreferences 저장)

PHASE 2 — [품질 완성] ← 현재 진행 중
  i18n 인프라 구축 (한국어/영어 arb)
  디자인 토큰 정비 (Soft Coral 라이트 테마, 하드코딩 컬러 제거)
  UX 보강 (햅틱 피드백, 스와이프 삭제, 애니메이션 규격)
  아이콘 통일 (Lucide Icons, 이모지 제거)
  보안 기초 (입력 검증 강화, 빌드 난독화 설정)

PHASE 3 — [확장 기능]
  추가 파이프 규격 / 기기 DB 확장
  측정 결과 PDF 내보내기
  Firebase Crashlytics 연동

PHASE 4 — [스토어 출시]
  개인정보 처리방침 / 이용약관 화면
  앱 아이콘 / 스플래시 화면
  스토어 심사 대응
```

**차후 요청 시 구현 (현재 전 Phase 구현 금지)**
```
클라우드 동기화 / 팀 공유 기능
유료 구독 (Paywall)
iOS 지원
```

**Phase별 핵심 컴포넌트** → DESIGN_MASTER_v3.1.md PART 13 참조 (또는 프로젝트별 작성)
**Phase별 보안 적용 타이밍** → SECURITY_MASTER_v4.md PART 13 참조 (또는 프로젝트별 작성)
**전체 기능 상세 스펙** → [프로젝트명]_FEATURE_UNIVERSE.md 참조

---

## 0-2. Flutter 화면 요청 시 자동 적용 규칙

> 별도 언급 없어도 모든 Flutter 화면 요청에 아래를 무조건 적용한다.

- **⛔ 문자열** — 위젯 안 문자열 리터럴 금지 / 반드시 `context.l10n.키명` 사용 / 섹션 1 규칙 강제 적용
- **⛔ 컬러** — AppColors 토큰만 허용 / Color(0xFF...) · Colors.XXX 직접 입력 금지 / 섹션 4 규칙 강제 적용
- **터치** — 특이사항 "터치 기준" 테이블 따름
- **구조** — 화면 뎁스 3단계 이내 (IA 구조는 FEATURE_UNIVERSE 또는 아래 섹션 참조)
- **완료 후** — 인라인 검증 실행: 섹션 1(i18n) + 섹션 4-6(디자인) + 섹션 3 UX 핵심 3항목
  리포트: `"검증 완료 — i18n 키 N개 / 디자인 위반 N건 / UX 이상 없음"`
  ※ PART 8 종합 체크리스트는 Phase 완료 시 실행 (섹션 0 워크플로우 참조)

## 1. 다국어 (i18n) — 하드코딩 원천봉쇄

> ⛔ **이 섹션은 선택사항이 아니다. 모든 문자열은 처음부터 i18n 키로 작성한다.**
> "나중에 정리하자" 없음. 첫 줄부터 키 사용.

### 강제 규칙

1. **위젯 안에 문자열 직접 삽입 절대 금지**
   ```dart
   // ❌ 절대 금지
   Text('홈')
   Text('저장')
   ElevatedButton(child: Text('시작하기'))
   SnackBar(content: Text('저장되었습니다'))

   // ✅ 유일한 허용 형태
   Text(context.l10n.home)
   Text(context.l10n.save)
   ```

2. **위젯과 arb 키는 반드시 같은 커밋에 포함** — 위젯만 있고 키가 없는 상태 금지
   - 선호: arb 키 먼저 정의 → 위젯 작성
   - 허용: 위젯에 `context.l10n.키명` 사용하며 작성 → 완성 후 arb 키 일괄 추가
   - ⛔ 금지: 위젯에 문자열 리터럴 넣고 "나중에 키 추가"

3. **AppStrings 상수 파일도 금지**
   - `class AppStrings { static const title = '홈'; }` 패턴도 하드코딩과 동일하게 취급

4. **에러 메시지 / 스낵바 / 다이얼로그 / 툴팁 전부 포함** — UI에 노출되는 모든 텍스트 예외 없음

5. **AI가 생성하는 코드에 문자열 리터럴이 보이면 즉시 거부 후 arb 키로 교체하여 제공**

### 셋업 구조

```
lib/
  l10n/
    app_ko.arb      ← 기본 언어 (프로젝트별 결정)
    app_en.arb      ← 영어
  core/
    extensions/
      build_context_ext.dart  ← context.l10n 단축 확장
```

**pubspec.yaml**
```yaml
flutter:
  generate: true

dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
```

**l10n.yaml** (프로젝트 루트)
```yaml
arb-dir: lib/l10n
template-arb-file: app_ko.arb
output-localization-file: app_localizations.dart
```

**build_context_ext.dart**
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension BuildContextExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
```

**MaterialApp 설정**
```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

### arb 키 네이밍 규칙

```
camelCase, 화면명_요소명 형태
  공통     → common_*   예: commonSave, commonCancel, commonError
  화면별   → [screen]_* 예: homeTodayQuiz, quizProgress, resultCorrect

플레이스홀더:
  "quizProgress": "{current} / {total}",
  "@quizProgress": {
    "placeholders": {
      "current": { "type": "int" },
      "total":   { "type": "int" }
    }
  }
```

### AI 자체 검증 절차 (코드 생성 시마다 실행)

```
1. 생성 코드에서 Text( · ElevatedButton(child: Text( · SnackBar(content: Text( 패턴 검색
2. 따옴표 안에 문자열이 있으면 → 즉시 중단
3. arb 양쪽 파일에 키 추가 후 context.l10n.키명 으로 교체
4. 교체 완료 후에만 코드 제공
5. 리포트: "i18n 검증 완료 — 신규 키 N개 추가 (app_ko.arb / app_en.arb)"
```

- 기본 지원: 한국어(ko) · 영어(en) / 추가 언어는 프로젝트별 결정
- 프로젝트 초기 arb 키 목록 → CLAUDE.md "프로젝트 정보 > i18n 초기 키" 섹션에 기재

## 2. 보안
- 설계 단계부터 보안을 반영한다 (Security by Design)
- 필수 체크리스트
  - API 키 · 민감정보: 환경변수 또는 비밀 저장소 사용, 코드 직접 삽입 금지
  - 입력값 검증: 모든 사용자 입력은 서버·클라이언트 양측 검증
  - 인증/인가: 최소 권한 원칙 적용
  - 데이터 전송: HTTPS 강제, 인증서 핀닝 고려
  - 로컬 저장: 민감 데이터는 암호화 저장 (Keychain / Keystore)
- 상세 구현 → SECURITY_MASTER_v4.md 전체 참조
  (OWASP Mobile Top 10 · RBAC · 데이터 거버넌스 · 법적 보존기간 포함)
- **프로젝트 특화 보안** → SECURITY_MASTER_v4.md PART 13 (프로젝트별 작성)
- **AI 행동:** 보안 체크리스트 미충족 항목 발견 시 구현 전 경고

## 3. UX — 철칙

> ⛔ 디자인·i18n과 동일 레벨의 강제 사항. 권고가 아니다.

**코딩 전 필수 확인**
- 신규 화면 설계 시 → CLAUDE.md 페르소나 섹션에서 주 페르소나 확인 후 설계
- 기능 추가 시 → 사용자 흐름(User Flow) 먼저 정의 후 구현

**절대 금지 (발견 즉시 수정)**
```
❌ 홈 화면 동일 레벨 CTA 4개 이상 나열 (Hick's Law)
❌ 홈 → 핵심 결과까지 탭 4회 이상 (3회 이내 원칙)
❌ 터치 타겟 기준 미만 (특이사항 "터치 기준" 테이블 참조)
❌ Loading / Empty / Error 3상태 중 하나라도 누락
❌ 상태 변화에 피드백 없음 (버튼 눌림, 저장 완료, 에러 등)
```

**강제 적용 원칙**
1. **Hick's Law** — 동일 레벨 선택지 최대 3개. 초과 시 그룹핑 또는 Progressive Disclosure
2. **탭 3회 원칙** — 초과 발견 시 플로우 재설계 제안 후 구현
3. **3상태 완전 구현** — 모든 데이터 화면에 Loading / Empty / Error 화면 필수
4. **상태 피드백** — 모든 액션에 ripple + 결과 피드백 (SnackBar / 색상 변화 / 햅틱)
5. **엄지존** — 주요 CTA는 하단 영역 배치 (Wroblewski Mobile-First)

**상세 규칙** → DESIGN_MASTER_v3.1.md PART 3 + PART 14
**UX 빠른 리뷰** → DM PART 3-7 (설계 단계 참고용 / 종합 검증은 Phase 완료 시 PART 8)

## 4. 디자인 — 철칙

> ⛔ 모든 Flutter 화면에 예외 없이 적용. 단, 철칙은 **하한선**이다 — 더 좋게 만드는 건 항상 허용.

### 4-1. 컬러 — 임의값 완전 금지

```
✅ 유일한 허용 소스: 아래 "디자인 시스템" 섹션의 AppColors 토큰
✅ AppColors.accent / AppColors.surface / AppColors.text1 …
❌ Color(0xFF...) 직접 입력 — 토큰에 없는 값 무조건 금지
❌ Colors.blue / Colors.white / Colors.grey 등 Flutter 기본 컬러
❌ Theme.of(context).colorScheme.XXX 단독 사용 (AppColors 경유 없는 경우)
```

- 디자인 시스템 섹션이 비어있으면 → 코드 작성 전 토큰 작성 요청, 임의 생성 금지
- 토큰에 없는 새 값 필요 시 → "디자인 시스템" 섹션에 먼저 추가 제안 후 사용

### 4-2. 컴포넌트 구조

**아이콘 카드**
```
✅ 카드 → 아이콘(48dp+, 상단 중앙) → 텍스트(하단) / 여백·비율로만 분리
❌ 카드 안 아이콘 래퍼 박스(배경 있는 중간 컨테이너) 절대 금지
❌ 아이콘-텍스트 사이 구분선(Divider / border-top) 금지
```

**8pt 그리드** ← UI 수치의 Source of Truth (섹션 11 매직 넘버 규칙에서도 이 기준 참조)
```
✅ 패딩·마진·간격: 8의 배수 (8/16/24/32/48/64)
✅ 예외: 4pt 단위까지 허용 (4/12/20/28 …)
❌ 13/15/22px 등 임의 수치
```

**터치 타겟** → 특이사항 "터치 기준" 테이블이 유일한 기준

### 4-3. 아이콘
```
✅ 기본: Lucide Icons (lucide_flutter) — 변경 시 특이사항 섹션에 기재
   (허용 대안: Phosphor / Heroicons — 프로젝트당 1종 통일)
❌ 이모지 금지 (UI 어디에도)
❌ 업종 클리셰 아이콘 금지
❌ 아이콘 세트 혼용 금지 (프로젝트당 1종만)
→ 포인트 컬러는 AppColors 액센트 토큰만
```

### 4-4. 타이포그래피
```
✅ 기본: Theme.of(context).textTheme.XXX 상속
✅ 특수 목적(히어로 수치, 배지, 레이블 등) → fontSize/fontWeight 직접 지정 허용
   단, 근거 한 줄 주석 필수: // hero number — custom 48sp Bold
✅ 수치·코드: Monospace 폰트 (JetBrains Mono 등)
❌ 근거 없는 임의 fontSize/fontWeight 남발
```

### 4-5. 스타일 일관성
```
다크 Glass:    DESIGN_MASTER PART 1 공식 적용
라이트 파스텔: DESIGN_MASTER PART 4 공식 적용
→ 프로젝트당 하나. 혼용 금지.
→ 프로젝트 스타일은 아래 "디자인 시스템" 섹션에 명시
```

### 4-6. AI 자체 검증 (화면 코드 생성 완료 시마다)
```
1. Color(0xFF...) / Colors.XXX 직접 사용 → AppColors 토큰으로 교체
2. 특이사항 "터치 기준" 미만 터치 영역 → SizedBox로 영역 확장
3. 아이콘 래퍼 박스 → 제거
4. 8pt 그리드 위반 수치 → 교체
5. 이모지 → Lucide 아이콘으로 교체
6. 리포트: "디자인 검증 완료 — 위반 N건 수정 (컬러N/터치N/그리드N)"
```

### 4-7. 트렌드
- 빌드마다 최신 트렌드 반영, 획일적 반복 금지
- **트렌드 적용 전 → DESIGN_MASTER_v3.1.md PART 7-0 판단 필터 3가지 반드시 확인**
  (페르소나 적합성 / 도메인 신뢰도 / 성능 비용 — 3가지 통과한 트렌드만 적용)
- 참조: Mobbin · Dribbble · App Store 피처드 / Schoger · Malewicz · Gary Simon
- 디자인 결정 시 `[참조 소스] → [적용 근거] → [구현 방법]` 형식으로 명시
- 상세 원칙 → DESIGN_MASTER_v3.1.md PART 7 전체

## 5. 완성도 평가 (Post-Build Review) — 종합 검증 단계

> ⚠️ **Phase 완료 시 실행** (섹션 0 "종합 검증" 단계). 매 화면 단위가 아님.
> 매 화면은 인라인 검증(섹션 1 + 3 + 4-6)만 실행. Phase 완료 시 이 섹션을 실행한다.

**실행 기준**
- DESIGN_MASTER PART 8 체크리스트 전체 실행
- 오프라인 기능 없는 프로젝트: PART 10(오프라인 UX) 항목 스킵 명시
- 알람 기능 없는 프로젝트: PART 11(알람 UI) 항목 스킵 명시
- RBAC 없는 프로젝트: 권한 분기 항목 스킵 명시

**평가 기준**
- 저명 앱 리뷰어 시점 (App Store 에디터, The Verge 등)
- App Store / Google Play 심사 가이드라인 적합성
- 접근성 (WCAG 2.1 AA 이상)
- 성능: 실기기 Profile 모드 60fps / const 위젯 / builder 리스트 / dispose 처리
- 섹션 1(i18n) · 섹션 3(UX) · 섹션 4(디자인) 철칙 준수 여부

**리포트 형식**: `[항목] 현재 상태 → 개선 제안`
개선 여부는 사업주 판단으로 결정

## 6. 경쟁앱 분석 · 기능 제안

> **실행 시점**: 신규 기능 설계 시에만. 기존 화면 수정·단순 추가 시에는 스킵.

- 빌드 전: 동종업계 전세계 경쟁앱 기능 분석 → 차별화 포인트 제안
- 빌드 후: 경쟁앱 대비 부족한 기능 적극 제안
- 제안 형식: `[경쟁앱 기능] → [우리 버전 개선 방향] → [예상 효과]`
- **AI 행동:** 신규 기능 구현 시 관련 경쟁앱 사례를 1~2개 함께 언급

## 7. 스토어 등록 기준
- 모든 플랜·코딩은 App Store · Google Play 등록을 최종 기준으로 한다
- 필수 반영 사항
  - 개인정보 처리방침 · 이용약관 화면 포함
  - 앱 추적 투명성 (ATT) / 권한 요청 사유 명시
  - 스크린샷·앱 아이콘 규격 계획 포함
  - 심사 거절 주요 사유 사전 점검 (결제 정책, 콘텐츠 정책)
- **AI 행동:** 심사 거절 가능성이 있는 코드·설계 발견 시 즉시 경고

## 8. 버전 관리
- 브랜치 전략: `main` (배포) · `dev` (개발) · `feature/기능명` (기능 단위)
- 커밋 컨벤션: `[type] 간단한 설명` 형식 사용
  - `feat`: 새 기능
  - `fix`: 버그 수정
  - `design`: UI/디자인 변경
  - `refactor`: 리팩토링
  - `chore`: 설정·의존성 변경
- 배포 전 반드시 `dev → main` PR 후 머지
- 태그 규칙: `v1.0.0` (major.minor.patch)

## 9. 앱 아이콘 · 스플래시 화면
- 스플래시 화면은 빈 화면으로 구성하며, 앱의 컨셉 색상을 배경으로 적용한다
- 텍스트·로고·애니메이션 등 불필요한 요소 금지 (심플 유지)
- 앱 아이콘은 아이콘 영역에 최대한 꽉 차게 디자인한다 (여백 최소화)
- 플랫폼별 규격 준수
  - iOS: 1024×1024px 마스터 이미지 기준, 알파 채널 금지
  - Android: Adaptive Icon 적용 (foreground + background 분리), 108×108dp 기준
- 아이콘 배경색은 스플래시 배경색과 통일하여 브랜드 일관성 유지

## 10. 에러 추적 · 크래시 리포팅
- 모든 앱에 크래시 리포팅 도구를 기본 탑재한다
  - Flutter / Android: Firebase Crashlytics (기본) 또는 Sentry
  - 웹앱: Sentry (프로젝트가 웹앱인 경우만 해당)
  - 선택 기준: Firebase 백엔드 사용 시 Crashlytics, 멀티 플랫폼/비Firebase 시 Sentry
- 로그 레벨 구분: DEBUG · INFO · WARNING · ERROR / 프로덕션에서 DEBUG 출력 금지
- 사용자 식별 정보는 로그에 포함하지 않는다 (개인정보 보호)
- 주요 사용자 행동 이벤트는 Analytics로 별도 추적 (Firebase Analytics 등)
- **개인정보 보호:** Analytics 이벤트에 PII(이름, 이메일, 전화번호 등) 포함 금지 → SECURITY_MASTER_v4.md PART 9 참조
- **AI 행동:** 프로덕션 빌드에 DEBUG 로그 또는 콘솔 출력 잔존 시 즉시 알림

## 11. 코드 품질
- 클린 코드 원칙 준수 (단일 책임, 명확한 네이밍, why 주석)
- 시니어 개발자가 봤을 때 군더더기 없는 코드를 목표로
- 함수/위젯은 하나의 역할만, 200줄 초과 시 분리 검토
- 매직 넘버 금지 — 상수로 분리 (UI 수치는 섹션 4-2 "8pt 그리드" 참조)

---

## 12. 코드 보호 (난독화 · 리버스엔지니어링 방지)

### 빌드 시 필수 적용
- **Flutter 난독화:** 릴리즈 빌드 시 아래 플래그 필수
  ```
  flutter build apk --release --obfuscate --split-debug-info=build/debug-info
  flutter build ios --release --obfuscate --split-debug-info=build/debug-info
  ```
- **Android ProGuard/R8:** `android/app/build.gradle`에 minifyEnabled true 적용
- **iOS 컴파일러 최적화:** Xcode Release 빌드 기본 적용 (별도 설정 불필요)

### 런타임 보호
- **루팅/탈옥 감지:** 기본 `flutter_jailbreak_detection` 또는 고급 `freerasp` 패키지 적용 — 감지 시 보안 경고
  - 상세 선택 기준 → SECURITY_MASTER_v4.md PART 6 참조
- **스크린샷 방지:** 민감 화면 (결제, 비번 등)에서 `FLAG_SECURE` 적용
- **SSL Pinning:** 주요 API 통신에 인증서 핀닝 적용 (중간자 공격 방지)

### 코드 구조 보호
- API 엔드포인트 · 비즈니스 로직은 서버사이드로 분리
- 핵심 알고리즘은 클라이언트에 노출하지 않는다
- **AI 행동:** 핵심 로직이 클라이언트에 노출되는 구조 발견 시 서버 이전 제안

### 한계 인식
- 난독화는 분석을 어렵게 할 뿐 완전 차단은 불가능
- 진짜 보호막은 도메인 노하우 + 운영 경험 + 선점 효과
- 상세 구현 코드 → SECURITY_MASTER_v4.md PART 6 (앱 무결성) 참조

---

# 프로젝트 정보 (프로젝트 시작 시 작성)

## 기본 정보
- 앱 이름: PipeCraft AR
- 플랫폼: Flutter (Android 전용, minSdk 24)
- 타겟 사용자: HVAC-R 배관 현장 기술자 (장갑 착용, 야외/실내 작업장)
- 주요 기능 요약: 파이프 밴딩 계산 + 오프셋 계산 + AR 거리 측정

## 경로
- 주요 소스 경로: `lib/features/` (bending, offset, ar), `lib/core/` (theme, constants, models)
- 네이티브 AR: `android/app/src/main/kotlin/com/athvacr/pipecraft_ar/`
- i18n 파일 경로: `lib/l10n/app_ko.arb` · `lib/l10n/app_en.arb`
- 환경변수 파일: 없음 (외부 API 미사용)

## i18n 초기 키
STEP 1에서 전체 arb 키를 생성한다. 아래는 주요 카테고리:
- `common*` — 공통 (저장, 취소, 에러, 복사, 확인, 삭제, 초기화)
- `bending*` — 밴딩 화면 (기기 선택, 관경, 각도, 방향, 스프링백, 단계 가이드)
- `offset*` — 오프셋 화면 (장애물, 여유, 삽입길이, 세팅각도)
- `ar*` — AR 화면 (측정, 기록, 빈 상태)
- `nav*` — 탭 네비게이션 라벨
- `theme*` — 테마 전환 관련

## 페르소나
- P1 — 현장 배관 기술자: 30~50대, HVAC-R 배관 시공 10년+, 장갑 착용 빈번, 야외/실내 작업장(먼지·소음), 한 손 조작 필요, 인터넷 간헐적. 주요 태스크: 밴딩 각도 계산 → 스프링백 보정 → 삽입길이 확인 → 즉시 시공. 빠른 결과 도출이 최우선.
- P2 — 배관 견습생: 20~30대, 기술 학습 단계, 스프링백 보정·오프셋 개념 이해 필요, 스마트폰 능숙. 주요 태스크: 단계별 가이드 참조하며 학습, AR로 거리 측정 연습.

## 디자인 시스템

- 프로젝트 스타일: **라이트 파스텔** (DM PART 4 적용, Glass 미사용)
- 다크모드 지원 여부: ✅
- 폰트: DM Sans (UI 텍스트) + DM Mono (수치/코드)
- 디자인 레퍼런스: Airbnb Soft Coral (`docs/airbnb_soft_coral_standalone.html`)

**프로젝트 personality**
```
도메인:   전문직 현장 도구 (HVAC-R 배관)
분위기:   따뜻한 신뢰감 + 전문성 (Soft Coral 톤)
키워드:   정확성, 현장감, 따뜻함
```

**Dark Mode 토큰**
```
--bg:             #121212
--surface:        #1E1E1E  (Glass 미사용, 불투명)
--surface-hi:     #252528  (인풋·선택 상태)
--border:         #2A2A2E
--border-hi:      rgba(255,255,255, 0.15)

--accent:         #FF4D6A  (Coral 계열 — 라이트 accent와 동일 계열)
--accent-dim:     rgba(255,77,106, 0.12)
--accent-glow:    rgba(255,77,106, 0.25)

--success:        #2ECC71  (진행/완료 — 배관 공정 진척도)
--success-dim:    #1A3A2A  (성공 배경)
--danger:         #EF5350
--warning:        #FBBF24
--info:           #7986CB

--text-primary:   #F5F5F5  (rgba 255,255,255, 0.96)
--text-secondary: #A0A0A0  (rgba 255,255,255, 0.63)
--text-muted:     #666666  (rgba 255,255,255, 0.40)

--diagram-bg:     #1C1C1E  (CustomPaint 전용)
--nav-bar:        #1A1A1A
--chip-selected:  #F5F5F5
--chip-unselected: #1E1E1E
--step-unchecked: #2A2A2E
```

**Light Mode 토큰** *(Airbnb Soft Coral 레퍼런스 기반)*
```
--bg:             #FFF9F5  (따뜻한 크림 — HTML body bg)
--surface:        #FFFFFF
--surface-hi:     #F0E6DD  (인풋·선택 — HTML border 톤)
--border:         #E8D5C8  (Soft Coral 틴트 — HTML search border)
--border-hi:      rgba(255,255,255, 0.90)

--accent:         #E8876B  (Soft Coral — HTML 메인 컬러)
--accent-dark:    #D4725A  (텍스트/gradient end — HTML gradient)
--accent-dim:     rgba(232,135,107, 0.12)
--accent-glow:    rgba(232,135,107, 0.20)

--btn-gradient:   linear-gradient(135deg, #E8876B, #D4725A)

--success:        #059669  (완료/진척도)
--success-dim:    #EBF7F1
--danger:         #DC2626
--warning:        #F59E0B
--info:           #6366F1

--text-primary:   #2A1F1F  (따뜻한 갈색 — HTML color)
--text-secondary: #5A4A42  (HTML topbar-right)
--text-muted:     #9E8A7E  (HTML card-location)

--diagram-bg:     #1C1C1E  (다이어그램은 다크 유지)
--nav-bar:        #FFFFFF
--chip-selected:  #2A1F1F
--chip-unselected: #FFFFFF
--step-unchecked: #F0E6DD
```

## 외부 서비스 · 의존성
- ARCore SDK 1.47.0 (네이티브 Android, AR 측정용)
- OpenGL ES 2.0 (포인트/라인 렌더링)
- SharedPreferences (로컬 데이터 저장 — 비민감 데이터만)
- Firebase 미사용 (오프라인 전용 앱)

## 특이사항 · 주의사항
- **오프라인 전용 앱**: 서버 통신 없음, 모든 계산은 로컬. 인터넷 필요 없음 (AR만 카메라 필요)
- **Android 전용**: iOS 미지원 (ARCore 의존)
- **터치 기준 (이 테이블이 유일한 기준 — 다른 섹션은 여기를 참조):**
  ```
  일반 버튼/아이콘:  56dp  ← 장갑 환경 (P1 페르소나)
  리스트 아이템:     56dp
  바텀 탭:          64dp
  CTA 버튼:         72dp
  ```
- **아이콘 세트:** Lucide (lucide_flutter)
- **RBAC 역할:** 없음 (단일 사용자 앱, 인증 불필요)

## 개발 진행사항

### 완성된 기능
- [2026-02-28] 밴딩 계산기: 기기/관경 선택, 스프링백 보정, 다중 꺾기, 경로 미리보기, 데이터 저장
- [2026-02-28] 오프셋 계산기: 장애물 우회 계산, 삽입길이, 세팅각도, 다이어그램, AR 연동
- [2026-02-28] AR 측정: ARCore 다중 포인트, 구간별 거리, 측정 이력, 되돌리기/초기화
- [2026-02-28] 테마 시스템: AppColors ThemeExtension, 다크/라이트/시스템 전환, 설정 저장
- [2026-02-28] 보안 강화: 레이스 컨디션 수정, 입력값 검증, 에러 메시지 개선
- [2026-04-16] Phase 2 일괄 정비: i18n 풀체인 (네이티브 AR Activity 포함, 미사용 키 37개 정리), Technical Drawing 다이어그램 (RoutePainter/OffsetPainter 재작성), 밴딩 Sticky Bottom Bar, 오프셋 입력 토글 제거 + 디바운스, AR 자동 빈필드 채움, 56dp 터치 타겟, ProGuard/R8 + 난독화, Sentry 연동, BendEntry 부분 실패 복구, MainShell/ThemeController 분리
- [2026-04-16] 앱 아이콘 적용: Coral 톤 사각형 자동 크롭, adaptive icon 5종 해상도 생성

### 데이터 구조
```
SharedPreferences:
  theme_mode: String (system/light/dark)
  bends: String (JSON array of BendEntry)
  selected_machine: String (robend4000/remsCurvo)
  selected_od: int (15/19/22/25/28/35)
  ar_measurements: String (JSON array of measurement records)
```

### 설계 변경 이력
- [2026-03-08] CLAUDE.md 프로젝트 정보 완성 / Phase 2 품질 개선 착수를 위한 기준 확립
- [2026-03-08] Light Mode 토큰을 Airbnb Soft Coral 레퍼런스 기반으로 재정의 / 현장 기술자 페르소나에 따뜻한 전문성 부여

### Phase 2 체크리스트
- [ ] i18n 인프라 구축 (l10n.yaml, arb 파일, context.l10n 확장)
- [ ] 300+ 하드코딩 문자열 → arb 키 추출
- [ ] AppColors 토큰 확장 (accent-dim, accent-glow, success-dim 등)
- [ ] Light Mode Soft Coral 테마 적용
- [ ] 하드코딩 컬러 제거 (ArMeasureActivity.kt, OffsetPainter)
- [ ] Lucide Icons 도입 + 이모지 제거
- [ ] 터치 타겟 56dp 통일 (장갑 환경)
- [ ] 햅틱 피드백 추가 (저장/삭제/복사)
- [ ] 스와이프 삭제 (밴딩 카드)
- [ ] 빌드 난독화 설정 확인
