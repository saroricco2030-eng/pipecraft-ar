# DESIGN MASTER KNOWLEDGE BASE v3.1
# 앱 UI 때깔 + 완성도 + UX + 성능 + IA/네비게이션 + 오프라인UX + 알람UI + Paywall UX
# 범용 파일 — 프로젝트 무관하게 재사용 가능
#
# v1.0 → v2.0: PART 9(IA & 네비게이션) + PART 10(오프라인 UX) + PART 11(알람 UI) 추가
#               v2.0 보완: 잠긴기능(Paywall) 컴포넌트 + 오프라인×유료잠금 동시 상태 정의
# v2.0 → v3.0: ① PART 8 체크리스트 중복 제거
#               ② PART 12 Flutter 구현 코드 섹션 신규 추가
#               ③ PART 13 Phase별 디자인 컴포넌트 우선순위 신규 추가
# v3.0 → v3.1: ① PART 3 UX 원칙 전면 보강 (Krug·Wroblewski·Nielsen 내용 확장)
#               ② PART 3-5 Don Norman 어포던스 신규 추가
#               ③ PART 3-6 UX 원칙 → Flutter 위젯 매핑 신규 추가
#               ④ PART 3-7 화면 완성 전 UX 체크리스트 신규 추가
#               ⑤ PART 5-3 / PART 13 / PART 14 범용 템플릿화 (프로젝트별 작성)
# v3.1 보강:   ① PART 2-1 여백 시스템 — 12/20px 예외값 명확화 + 카드 패딩 선택 기준 추가
#               ② PART 3-1 Satisficing 원칙 추가 (Krug)
#               ③ PART 3-2 FAB 스크롤 처리 패턴 추가 (Wroblewski)
#               ④ PART 3-3 Heuristic #7 숙련 사용자 효율 추가 (Nielsen)
#               ⑤ PART 3-5 Conceptual Model 피드백 추가 (Norman)
#               ⑥ PART 7-0 트렌드 적용 전 판단 필터 신규 추가 (Malewicz)
#               ⑦ PART 7-2 금지 항목 2개 추가 (Gary Simon)
#               ⑧ PART 12 레퍼런스 코드 직접 컬러값 → 토큰 안내 주석으로 교체

## ▌AI 행동 철칙 — 파일 로드 즉시 적용, 모든 코딩 작업 전 선행

> ⛔ **이 파일은 "참고 자료"가 아니다. 모든 항목은 코드 생성 시 강제 적용된다.**
> 단, 철칙은 창의적 결과물의 **하한선**이다. 상한은 없다 — 더 좋게 만드는 건 항상 허용.

### ① 코딩 전 필수 확인 순서
```
→ CLAUDE.md 헤더 "★ 코딩 전 필수 확인 순서" 5단계가 유일한 기준.
  이 파일에서의 보충 참고:
  - PART 13 템플릿이 비어있으면: 컴포넌트 설계 전 작성 요청 또는 직접 제안
  - PART 14 템플릿이 비어있으면: 페르소나 없이 진행하되 CLAUDE.md에 추가 제안
  - PART 8 체크리스트: 다크Glass / 라이트파스텔 여부에 따라 조건부 항목 적용
```

### ② 절대 금지 (발견 즉시 수정, 예외 없음)
```
❌ Color(0xFF...) / Colors.XXX — AppColors 토큰 외 직접 컬러값 입력
❌ 44dp 미만 터치 영역 (프로젝트별 상세 기준: CLAUDE.md 특이사항)
❌ 아이콘 래퍼 박스 (카드 안 배경 있는 중간 컨테이너)
❌ 8pt 그리드 위반 (13/15/22px 등 — 4pt 단위까지 허용)
❌ 이모지 사용 (UI 어디에도)
❌ 다크 Glass + 라이트 파스텔 혼용 (프로젝트당 하나)
```

### ③ 창의적 판단 허용 범위
```
✅ TextStyle fontSize/fontWeight 직접 지정 — TextTheme 기반이지만
   특수 목적(히어로 수치, 배지, 레이블 등)은 근거 명시 후 커스텀 허용
✅ 새 토큰이 필요한 경우 — CLAUDE.md에 먼저 추가 제안 후 사용
✅ 트렌드 기반 레이아웃 변화 — PART 7 기준, 프로젝트 간 차별화 적극 권장
✅ 애니메이션/전환 효과 — PART 2 기준 내에서 창의적 적용
```

### ④ 검증 리포트 (화면 코드 생성 완료 시마다)
```
"디자인 검증 완료 — 위반 N건 수정 (컬러 N / 터치 N / 그리드 N / 기타 N)"
위반 0건이면: "디자인 검증 완료 — 이상 없음"
```

### ⑤ PART별 역할 요약
```
PART 1~2   — Glass/비주얼 공식 + 레이아웃·컴포넌트 규칙
PART 3     — UX 7원칙 (Krug/Wroblewski/Nielsen/Norman) + Flutter 매핑
PART 4~5   — 라이트모드 + 컬러 시스템 (5-3은 CLAUDE.md 값 사용)
PART 6~7   — 성능 최적화 + 트렌드
PART 8     — ⚠️ Phase 완료마다 실행 체크리스트 (최종 QA 전용 아님)
PART 9~11  — IA/네비게이션 + 오프라인 UX + 알람 UI
PART 12    — Flutter 구현 코드 (AppColors 구조 — 값은 CLAUDE.md에서)
PART 13    — Phase별 핵심 컴포넌트 (프로젝트별 작성)
PART 14    — 도메인 특화 UX & 페르소나 (프로젝트별 작성)
```

### ⑥ PART별 참조 시점 — AI 컨텍스트 효율화
```
[매 화면 필수 참조]   PART 1~4 (비주얼·UX), PART 12 (Flutter 코드)
[해당 기능 구현 시]   PART 9 (IA·네비게이션), PART 10 (오프라인), PART 11 (알람)
[Phase 완료 시]      PART 8 (종합 체크리스트)
[프로젝트 설정 시]   PART 5 (컬러), PART 6 (성능), PART 7 (트렌드), PART 13~14
```
#
# ┌─ 사용 흐름 ──────────────────────────────────────────────────┐
# │ 프로젝트 시작                                                  │
# │  → PART 1 (비주얼 시스템 구축)                                │
# │  → PART 2 (레이아웃/컴포넌트 설계)                            │
# │  → PART 3 (UX 원칙 적용)                                      │
# │       3-1 Krug 직관성 / 3-2 Wroblewski 모바일                 │
# │       3-3 Nielsen 피드백 / 3-4 온보딩                         │
# │       3-5 Norman 어포던스 / 3-6 Flutter 매핑                  │
# │       3-7 UX 체크리스트                                        │
# │  → PART 4 (라이트 모드 분기)                                   │
# │  → PART 5 (팔레트 & 컬러)                                      │
# │       5-1 색상 심리 / 5-2 컬러 팔레트 가이드                  │
# │       5-3 ★ 프로젝트 컬러 토큰 (CLAUDE.md에서 가져옴)        │
# │  → PART 6 (성능 최적화)                                        │
# │  → PART 7 (트렌드 체크)                                        │
# │       7-0 판단 필터 먼저 확인 → 7-1 적용 / 7-2 금지 확인      │
# │  → PART 9 (IA & 네비게이션 구조)                               │
# │  → PART 10 (오프라인 UX 패턴)                                  │
# │  → PART 11 (알람 & 상태 UI 시스템)                             │
# │  → PART 8 (체크리스트) ← ⚠️ 각 Phase 완료마다 실행            │
# │                           최종 QA 전용이 아님. Phase 1 완료    │
# │                           후에도 전 항목 점검.                 │
# │                           ※ 파일 내 배치: PART 11 뒤 (실행순서 반영) │
# │  → PART 12 (Flutter 구현 코드)                                 │
# │  → PART 13 (Phase별 컴포넌트 우선순위) ← 프로젝트별 작성     │
# │  → PART 14 (도메인 특화 UX & 페르소나) ← 프로젝트별 작성     │
# └──────────────────────────────────────────────────────────────┘
#
# 참조 우선순위: 비주얼 임팩트 → UX 검증 → 완성도 마감 → 성능

---

## ▌PART 1. 비주얼 시스템 구축

### 1-1. Liquid Glass / Glassmorphism
*[Michal Malewicz(Glassmorphism 창시), Ghani Pradita, RonDesignLab, Apple HIG iOS26]*

**Glass의 핵심은 배경이다**
- 단색 검정 위 Glass = 아무것도 안 보임 → 반드시 배경 컬러 메시 필요
- 배경: radial-gradient orb 2~3개 (딥 블루·틸·인디고 계열)
- orb 색상 = UI 액센트 컬러 동일 계열로 통일
- 고주파 노이즈 배경 금지 → blur 시 아티팩트

**Glass 레이어 공식 (다크)**
```
background:      rgba(255,255,255, 0.06)    ← 너무 밝으면 저렴해짐
backdrop-filter: blur(20~32px) saturate(1.4~1.8)
border-top:      0.8px solid rgba(255,255,255, 0.15)
border-bottom:   0.8px solid rgba(255,255,255, 0.05)  ← 하단은 항상 더 어둡게
box-shadow:      inset 0 1px 0 rgba(255,255,255, 0.2)
                 0 8px 32px rgba(0,0,0, 0.25)
```

**z-depth 계층 규칙**
```
배경 orb(L0) → 메인 카드(L1, blur 24px) → 서브 카드(L2, blur 16px) → 모달(L3, blur 40px)
```
위로 올수록: blur↑ · border opacity↑ · background opacity↑
*Apple HIG: "base colors are dimmer(배경), elevated colors are brighter(전경)"*

**상단 하이라이트 라인 — 프리미엄과 저렴함을 가르는 한 줄**
```css
.card::before {
  content: ''; position: absolute;
  top: 0; left: 10%; right: 10%; height: 0.8px;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent);
}
```

---

### 1-2. 컬러 시스템
*[Malewicz, Gleb Kuznetsov, Kevin Cantwell, Apple HIG Dark Mode]*

**다크 베이스 토큰** *(설계 참고 예시 — 실제 프로젝트 값은 CLAUDE.md "디자인 시스템" 기준)*
```
--bg:         #0A0C11   순수 검정 금지 — 약간 컬러감 있는 다크
--surface:    #141720   카드 기본
--surface-hi: #1C2030   인풋, 선택 상태
--border:     #252A3A   구분선
```

**액센트 원칙**
- 메인 액센트 1개 + 기능 컬러 최대 5개
- 기능 컬러: 위험(레드) · 경고(앰버) · 성공(틸) · 정보(블루) · 보조(퍼플)
- 다크 배경에서 살아남는 색 = 채도 높게, 명도 중간
- Apple HIG: 다크모드 액센트는 라이트모드보다 약간 밝게 조정
- 순수 흰색(#fff) 절대 금지 → `rgba(255,255,255,0.92)` 사용

**텍스트 계층 (다크)**
```
Primary:   rgba(255,255,255, 0.92)
Secondary: rgba(255,255,255, 0.45)
Muted:     rgba(255,255,255, 0.18~0.22)
```

**글로우 원칙**
- 액센트 요소에만 선택적 적용: `box-shadow: 0 0 12~20px rgba(액센트, 0.3~0.4)`
- 1화면 최대 2~3개 포인트 — 남발 시 저렴해짐
- 텍스트 글로우: 제목/레이블에만, 본문 절대 금지

**다크모드 접근성** *[Apple HIG, Apple Developer Dark Interface 가이드라인]*
- 텍스트 대비율 최소 4.5:1 (WCAG AA), 권장 7:1
- 아이콘 등 비텍스트 요소 최소 3:1
- "gray-on-black" 패턴 위험 — 저시력 사용자 가독성 저하
- Increase Contrast 모드 활성 시 Glass blur 투명도 낮추는 분기 고려

---

### 1-3. 타이포그래피
*[Malewicz, Schoger "Refactoring UI", Caler Edwards, Apple HIG Typography]*

**폰트 페어링**
- 기술/엔지니어링 앱: Monospace(수치) + Sans-serif(레이블) 조합
- 수치/코드: JetBrains Mono, Fira Code
- UI 텍스트: Noto Sans KR (한국어), SF Pro (iOS)

**스케일 (모바일 기준)**
```
페이지 제목:  22~24px  weight 700  letter-spacing -0.3px
카드 제목:    14~16px  weight 600
서브레이블:   11~12px  weight 500  letter-spacing +0.3px
수치/값:      15~18px  Monospace   weight 500
캡션/뱃지:    9~10px   weight 700  letter-spacing +0.5px
```

**위계 원칙**
- 제목: 자간 좁게(-0.3px) → 묵직한 느낌
- 레이블/뱃지: 자간 넓게(+0.5px) → 가독성
- 본문 행간 1.6, 캡션 행간 1.4
- 수치는 반드시 Monospace — 자릿수 흔들림 방지 + 전문성

---

### 1-4. 아이콘 시스템
*[Schoger "Refactoring UI", Pablo Stanley, Apple HIG SF Symbols]*

**카드 내 아이콘 절대 원칙**
- 카드 안에 아이콘 래퍼 박스(icon-wrap) 절대 금지
- 구조: **카드 → 아이콘(48px+) → 텍스트** (중간 컨테이너 없음)
- 여백과 비율로만 공간 분리 (구분선/배경박스 금지)
- 아이콘 컬러 = 기능 컬러 (단순 흰색 금지)

**라인 아이콘 규격**
- stroke-width: 1.5~1.75 (굵으면 아마추어 느낌)
- 카드 내 48px+ / 네비게이션 22px / 인라인 15~16px
- 아이콘 세트 통일: Lucide(기본) / Phosphor / Heroicons 중 하나 (CLAUDE.md 섹션 4-3 확인)
- 이모지 + SVG 혼용 절대 금지

---

### 1-5. 애니메이션 & 트랜지션
*[Cuberto(Awwwards Agency of Year), Apple HIG Motion]*

**모션의 역할**
- 애니메이션 = 피드백 + 브랜드 표현, 장식이 아님 *[Cuberto]*
- 화면 전환에 방향 의미를 부여 (어디서 왔는지, 어디로 가는지)
- 과도한 모션은 오히려 저렴해 보임

**화면 전환 패턴**
```
페이지 전환 (계층 이동):  slide 좌우
모달/바텀시트 등장:       slide up + 배경 scale(0.96) + dimming
모달/바텀시트 닫기:       slide down + 배경 scale(1.0) 복원
탭 전환 (같은 레벨):      fade 0.15s
```

**타이밍 기준**
```
Micro interaction:  100~150ms   즉각 반응감
화면 전환:          250~350ms   방향감 형성
모달 등장:          300ms ease-out
절대 금지:          500ms 이상  → 답답함
```
- Spring 애니메이션 권장 — ease-in/out보다 자연스러움 *[Apple HIG]*

**Micro Animation** *[Cuberto Liquid Tab Bar 사례]*
```
버튼 탭:    scale(0.96) → scale(1.0)  70ms
카드 탭:    scale(0.98)               100ms
탭바 전환:  활성 아이콘 scale up + 인디케이터 slide
아이콘 활성: 컬러 변경 + 미세 bounce
```

> ⚠️ 애니메이션 성능 최적화는 PART 6 참조

---

## ▌PART 2. 레이아웃 & 컴포넌트

### 2-1. 여백 시스템
*[Steve Schoger "Refactoring UI"]*

**8pt Grid**
```
4px  — 아이콘-텍스트 간격, 뱃지 내부           (4pt 예외)
8px  — 컴팩트 패딩, 칩 내부                    (기본 단위)
12px — 관련 요소 간 간격                       (4pt 예외)
16px — 카드 내부 패딩 (기본)
20px — 카드 내부 패딩 (여유) / 섹션 내 요소 간격 (4pt 예외)
24px — 카드 내부 패딩 (넉넉) / 페이지 좌우 패딩  (기본 단위)
32px — 섹션 헤더 상단 여백
48px — 섹션 간 큰 여백
```
> ⚠️ 12px·20px는 4pt 예외값. 기준 단위는 8의 배수. AI는 임의로 12를 "기본값"으로 쓰지 말 것.

**카드 내부 패딩 선택 기준**
```
16px — 정보 밀도 높은 리스트 카드 (목록 아이템, 데이터 행)
20px — 일반 콘텐츠 카드 (대부분의 경우)
24px — 넓고 여유로운 카드 (온보딩, 빈 상태, CTA 카드)
```

**카드 밀도 원칙**
- 카드는 콘텐츠를 꽉 채워야 함 (빈 공간 = 미완성)
- 리스트형: 최소 높이 72px, 아이콘+텍스트+액션 모두 포함
- 그리드형: aspect-ratio 1:1 또는 4:3 고정

**시각적 위계 5단계**
```
1. 페이지 타이틀   — 가장 크고 굵게
2. 섹션 레이블     — 작지만 액센트 컬러 또는 굵은 바
3. 카드 타이틀
4. 서브텍스트/태그
5. Muted 텍스트   — 설명, 타임스탬프
```

---

### 2-2. 그리드 & 레이아웃
*[Malewicz, Caler Edwards, Apple HIG Layout]*

**모바일 그리드**
- 기능/도구 그리드: **3열 고정** (2열=너무 크고, 4열=너무 작음)
- 카드 gap: 8~10px
- 리스트 항목은 전체 너비 카드 (그리드 금지)
- 혼합 레이아웃: 첫 항목 Full-width 강조 → 나머지 그리드

**정보 밀도**
- 1화면 스크롤 없이 핵심: 최대 3~4개 요소
- 폴드 아래: 보조 정보 (스크롤 자연스럽게 유도)
- 상단 고정: 헤더 + 주요 액션 1개

---

### 2-3. 컴포넌트 설계
*[Nielsen Norman Group, Schoger, Apple HIG]*

**버튼 계층**
```
Primary:  gradient + glow shadow + 상단 하이라이트 라인
Secondary: glass 배경 + border
Ghost:    border만, 배경 투명
Danger:   danger 컬러 gradient
비활성:   opacity 0.4  ← 완전히 숨기지 말 것 (Nielsen)
```

**인풋 필드**
- 배경: surface-hi (카드보다 약간 밝게)
- 포커스: border 액센트 컬러 + `0 0 0 3px rgba(액센트, 0.1)` 외곽 링
- 플레이스홀더: Muted(0.18~0.22) — 너무 밝으면 입력값과 혼동
- 단위/접미사: 액센트 컬러 0.7 opacity

**뱃지/태그**
- 배경: 기능 컬러 0.12~0.15 opacity
- 테두리: 기능 컬러 0.25~0.3 opacity
- 텍스트: 기능 컬러 100%
- 규격: 9~10px, letter-spacing +0.5px, font-weight 700

**네비게이션 바**
- 배경: glass blur 20px
- 활성: 액센트 아이콘 + 텍스트 + 하단 인디케이터(16px 너비, 2px 높이, 글로우)
- 비활성: rgba(255,255,255, 0.4)

**탭 컴포넌트**
- Pill 탭: 활성=액센트 배경+흰 텍스트 / 비활성=투명+muted
- 언더라인 탭: 활성=액센트 2px 라인 / 비활성=없음
- 세그먼트 컨트롤: glass 카드 안에 활성 슬라이더

**잠긴 기능(Paywall) 컴포넌트**
*[Nielsen 휴리스틱 #4: Consistency / Krug: "Don't Make Me Think"]*

유료 미구독 기능의 UI 처리 — 강제 팝업 금지, 인라인 유도
```
잠긴 기능 기본 상태:
  opacity: 0.4
  아이콘 오버레이: 자물쇠(lock) — 우상단 소형(16px)
  터치 가능: true (완전히 막지 말 것 — Nielsen 비활성 원칙)

탭 시: 업그레이드 바텀시트 등장 (전체 화면 팝업 절대 금지)
```

업그레이드 바텀시트 구조:
```
[Grab Handle]
[기능 아이콘(48px) + 기능 이름]
[한 줄 가치 설명: "이 기능으로 ~할 수 있습니다"]
[PRO / PRO+ 뱃지 표시]
──────────────────────────────
[티어 비교 간략 카드 — 2열]
  현재 플랜       업그레이드 플랜
  ○ 이 기능 잠김  ● 이 기능 포함
──────────────────────────────
[Primary CTA] "PRO로 업그레이드"
[Ghost]       "나중에"
```

잠긴 기능 시각 규칙:
- 기능 카드/버튼에 잠금 오버레이 → 투명도 0.4 (숨기지 않음 — 기능 존재는 알려야 함)
- 잠금 아이콘 위치: 카드 우상단, 그리드 버튼 중앙 하단
- 업그레이드 바텀시트: 1회 탭에 1회만 등장, 연속 탭 무시
- 사용량 한도(월 N건): 진행 표시 바로 처리 ("이번 달 2건 남음")
  → 소진 시점에 동일한 업그레이드 바텀시트 등장

---

### 2-4. 스크롤 & 바텀시트 패턴
*[Apple HIG, Google Material Design, Nielsen Norman Group, Wolt UX Blog]*

**헤더 스크롤 처리**
```
확장 상태:  큰 타이틀 + 서브타이틀 (Apple Maps/App Store 패턴)
축소 상태:  스크롤 시 타이틀만 남기고 축소
Sticky:     blur 강화(32px) + 하단 구분선 등장
```
완전히 숨기는 헤더는 방향감 상실 → 지양

**바텀시트** *[NN Group: "바텀시트는 progressive disclosure의 한 형태"]*
- 용도: 임시 컨텍스트 정보, 메인 화면 맥락 유지
- Grab Handle(드래그 인디케이터) 필수
- 스와이프 다운 + Back 버튼 모두 닫기 동작
- **바텀시트 위에 바텀시트 중첩 금지** — 사용자 혼란
- 스크롤 콘텐츠: 시트 완전 확장 후 내부 스크롤 (중간 상태 스크롤 방지)
- Top Bar(닫기/뒤로가기) + Sticky Action Bar(CTA) 세트 *[Wolt 사례]*

**스크롤 인터랙션 효과**
- Parallax Header: 배경 이미지 0.5~0.7배 속도 → 깊이감
- Snap Scrolling: 카드 목록 아이템 중앙 snap
- 수평 카루셀: 중앙 scale(1.0) / 양쪽 scale(0.92) + opacity(0.7)

---

## ▌PART 3. UX 완성도
# v3.1 전면 보강 — 원칙 내용 확장 + Norman 신규 + Flutter 위젯 매핑 추가

### 3-1. Don't Make Me Think — Krug
*[Steve Krug, "Don't Make Me Think" — 직관성·인지부하 최소화]*

**핵심 철학**
- 유저는 읽지 않는다, 훑는다(scan) — 설명 대신 구조로 말해라
- 첫 화면에서 설명 없이 무엇을 해야 할지 알 수 있어야 한다
- 툴팁·도움말이 필요하다면 UI가 실패한 것

**Satisficing — 유저는 최선을 찾지 않는다**
- 유저는 완벽한 선택을 하지 않는다. 첫 번째로 "괜찮아 보이는 것"을 클릭한다
- 이 말의 의미: 정보 계층 설계 시 "정확한 구조"보다 "첫눈에 가장 중요한 게 가장 눈에 띄는가"가 우선
- CTA 1개가 압도적으로 눈에 띄어야 한다 — 나머지는 배경으로 물러나야 함
- AI 적용: 화면 설계 시 "어떤 요소가 첫 시선을 끄는가"를 먼저 확인

**3초 테스트**
- 화면을 3초 보고 앱 목적 파악 가능해야 함
- 주요 액션: 가장 크고 밝게, 하단 엄지존
- 레이블은 동사: "저장하기" O / "저장" △

**시각적 계층 = 중요도 지도**
- 가장 중요한 것이 가장 눈에 띄어야 한다
- 모든 것이 강조되면 아무것도 강조되지 않는다
- Primary CTA 1개만 — 같은 레벨 버튼 3개 이상 금지

**노이즈 제거**
- 화면의 모든 요소는 존재 이유가 있어야 한다
- Divider 남발 금지 — 여백으로 구분 가능하면 선 불필요
- Card 중첩 금지 — 카드 안에 카드 금지

**네비게이션**
- 현재 위치 항상 명확 (활성 탭 강조)
- 뒤로가기: 항상 왼쪽 상단
- 뎁스: 최대 3단계 (홈→카테고리→상세)

**빈 상태(Empty State) — 3요소 필수**
```
아이콘/일러스트 + 제목(왜 비었는가) + 액션 버튼(다음 단계 안내)
"없습니다" 한 줄은 기회 낭비 — 브랜드 경험의 일부
```

---

### 3-2. 모바일 퍼스트 — Wroblewski
*[Luke Wroblewski, "Mobile First" — 모바일 제약이 디자인을 개선한다]*

**핵심 철학**
- 모바일은 데스크톱 축소판이 아니다 — 완전히 다른 행동 패턴
- 제약(작은 화면)이 핵심만 남기도록 강제한다 — 버릴 것을 결정하는 것이 설계

**엄지존 설계** *[Steven Hoober 터치 연구 기반]*
```
상단 — 정보 표시 전용 (탭하기 어려운 구역) → AppBar 액션 최소화
중앙 — 콘텐츠 영역
하단 — 주요 액션 (엄지가 편한 구역) → CTA, BottomNavigationBar
```

**터치 타겟** *[Apple HIG 기준: 44pt / 전문직·장갑 환경: 56px 이상 — CLAUDE.md 기준 확인]*
- 버튼/탭: 최소 44×44px (전문직·장갑 환경: 56dp)
- 리스트 아이템: 최소 48px 높이
- 아이콘 버튼: 시각적 크기와 무관하게 44px 터치 영역 확보
- 아이콘이 24px여도 GestureDetector/IconButton 영역은 44px 이상

**FAB 배치 & 스크롤 처리**
```
기본 위치: 우하단 (오른손 엄지 도달 최적)
왼손잡이:  시스템 설정 또는 설정 내 Mirror 옵션 제공 (선택적)

스크롤 중 FAB 처리:
  콘텐츠 가림 방지 → 스크롤 다운 시 FAB 숨김(AnimatedScale/hide)
                    → 스크롤 업 시 FAB 재등장
  구현: ScrollController + AnimatedSlide 조합
  FAB 아래 패딩: 마지막 리스트 아이템에 FloatingActionButton 높이 + 16px 패딩 추가
```

**보조 정보는 숨겨라**
- 초기 화면 = 핵심 정보만 (Wroblewski: "mobile constraints force clarity")
- 부가 정보 → BottomSheet / Expandable / 더보기 패턴으로 처리
- 한 화면 스크롤 없이 볼 수 있는 요소: 최대 3~4개

**폼 입력**
- 한 화면 = 한 가지 질문 원칙 (필드 수 최소화)
- 키보드 올라올 때 CTA 버튼 가려지지 않게
- 숫자 입력 → number 키패드 지정
- 드롭다운/토글로 타이핑 대체 — 선택지가 있으면 입력 금지
- 긴 폼 → PageView로 단계 분할 + TextInputAction.next로 키보드 이동

---

### 3-3. 피드백과 상태 — Nielsen 휴리스틱
*[Jakob Nielsen, 10 Usability Heuristics — 수십년 사용성 연구 기반]*

**핵심 철학**
- 시스템은 항상 유저에게 무슨 일이 일어나고 있는지 알려야 한다 (Heuristic #1)
- 에러 메시지는 인간의 언어로 — "Error 404" ✗ / "페이지를 찾을 수 없어요" ✓
- 일관성과 표준 — 플랫폼 관례를 따라라 (뒤로가기는 항상 좌측 상단)

**3상태 완전 설계 원칙 — 모든 화면에 필수**
```
Loading  → Skeleton UI (레이아웃 유지, 깜빡임 금지)
Empty    → 아이콘 + 제목 + 설명 + CTA (3-1 Empty State 규칙 적용)
Error    → 아이콘 + 에러 설명 + 재시도 버튼
```
⚠️ 이 3가지 중 하나라도 없으면 화면 미완성

**상태별 처리 상세**
```
로딩:    Skeleton UI (레이아웃 유지)
성공:    그린 체크 + 0.8초 자동 닫힘 또는 SnackBar
에러:    빨간 테두리 + 인라인 메시지 (팝업 금지)
진행중:  액센트 컬러 LinearProgressIndicator / CircularProgressIndicator
```

**숙련 사용자 효율 — Heuristic #7 (Flexibility and efficiency)**
- 초보자를 위한 흐름과 숙련자를 위한 단축 경로를 함께 설계
- 매일 쓰는 전문직 도구일수록 이 원칙이 핵심
```
숙련자 패턴:
  스와이프 액션 (리스트 아이템 좌/우 스와이프 → 빠른 실행)
  길게 누르기   → 컨텍스트 메뉴 (자주 쓰는 액션 단축)
  즐겨찾기/핀   → 자주 쓰는 항목 상단 고정
  키보드 단축키 → 태블릿/데스크톱 지원 시
```
- AI 적용: 전문직 도구 설계 시 Dismissible(스와이프) + GestureDetector(롱프레스) 패턴을 기본으로 포함

**피드백 속도**
- 액션 후 0.1초 이내 시스템 반응 필수 — 반응 없으면 유저가 재탭 → 중복 요청
- 0.1초: 즉각 반응(ripple, haptic) / 1초: 로딩 표시 / 10초↑: 진행률 + 취소 버튼

**실수 방지**
- 파괴적 액션(삭제): 확인 단계 필수 (AlertDialog 또는 Undo SnackBar)
- 되돌릴 수 없는 액션: 레드 버튼
- 비활성 버튼: opacity 0.4 (완전히 숨기지 말 것 — 기능 존재는 알려야 함)
- 잘못된 입력 차단 > 에러 메시지 — inputFormatters로 사전 방지

**인지 부하 최소화**
- 기억하게 하지 말고 보여주게 (Heuristic #6)
- 자유 텍스트 입력 < 드롭다운/선택 위젯 — 선택지가 있으면 입력 금지
- 전문 용어 사용 시 인라인 설명 제공

---

### 3-4. 온보딩 설계
*[Apple HIG Progressive Disclosure, Nielsen Norman Group, Appcues 연구]*

**핵심 원칙**
- "show, don't tell" — 기능 나열 말고 가치를 먼저 보여줘라
- Nielsen: "없앨 수 있으면 없애는 게 최선"
- Skip 옵션 항상 제공 — 강제 온보딩 금지

**유형 선택**
```
Benefits-oriented:  "이 앱으로 뭘 할 수 있나" — 가치 제안
Function-oriented:  핵심 기능 1~3개만 안내
Progressive:        바로 앱 진입 후 맥락에 맞는 툴팁 등장
```
기술/전문 앱 권장: Function-oriented + Progressive 조합

**디자인 기준**
- 화면 수: 최대 3개 (초과 시 이탈률 급등)
- 진행 인디케이터 필수 (dots/progress bar) — 끝이 보여야 완료 동기
- 각 화면: 아이콘/일러스트 + 제목 + 한 줄 설명
- 마지막 화면: 동사형 CTA ("시작하기")

---

### 3-5. 어포던스와 멘탈 모델 — Don Norman
*[Don Norman, "The Design of Everyday Things" — UX 개념 창시자]*

**핵심 철학**
- 사람들이 뭔가를 틀리게 사용한다면, 그건 사람의 실수가 아니라 디자인의 실패다
- 생김새가 사용법을 말해야 한다 (Affordance)
- 유저가 이미 갖고 있는 세계관(멘탈 모델)에 맞춰라

**어포던스 — 생김새로 사용법을 전달**
```
버튼:        둥글고 입체적 (눌릴 것 같이) → ElevatedButton / FilledButton
링크:        밑줄 또는 액센트 컬러 → TextButton
입력 필드:   테두리 + 배경색 차이 (입력 가능함을 표시)
드래그:      Grab Handle(점 3개 또는 선) → DragHandle 위젯
스와이프:    카드 끝부분 살짝 노출 → 더 있음을 암시
```

**멘탈 모델 — 기존 관례를 따르면 학습 비용이 없다**
```
스와이프 삭제     → Dismissible 위젯
당겨서 새로고침   → RefreshIndicator
스와이프 뒤로가기 → iOS 기본 제스처 (PopScope 방해 금지)
길게 누르기       → 컨텍스트 메뉴 (ContextMenu)
핀치 줌          → InteractiveViewer
```

**피드백 — 모든 액션은 즉각 반응**
- 탭: InkWell ripple 효과 (시각)
- 중요 액션: HapticFeedback.lightImpact() (촉각)
- 완료: 색상 변화 + 체크 아이콘 (시각)
- 에러: 진동(HapticFeedback.vibrate) + 빨간 테두리 (시각+촉각)

**Conceptual Model 피드백 — 시스템이 어떻게 작동하는지 보여줘라**
- 즉각 반응(ripple)만으론 부족 — "이 데이터가 어디에 저장됐는가"를 보여줘야 함
- 유저가 시스템 상태를 이해할 수 있어야 한다 (Norman + Nielsen 교집합)
```
클라우드 저장:  SnackBar "저장됨" + 상단 동기화 아이콘 변화
오프라인 저장:  "기기에 저장됨 · 연결 시 동기화" 아이콘 + 뱃지
공유 데이터:    "팀에게 공개됨" 상태 레이블 (누가 볼 수 있는지 명시)
삭제:           "30일 후 영구 삭제" (되돌릴 수 있는 기간 명시)
```
AI 적용: 저장/공유/삭제 액션 구현 시 Conceptual Model 피드백을 반드시 포함

**제약으로 실수 방지 — 에러 메시지보다 입력 차단이 낫다**
```
날짜 입력    → showDatePicker() (자유 입력 금지)
숫자만 입력  → TextInputType.number + FilteringTextInputFormatter
범위 선택    → Slider / RangeSlider (직접 입력 금지)
파일 선택    → FilePicker (경로 직접 입력 금지)
```

---

### 3-6. UX 원칙 → Flutter 위젯 매핑
*[v3.1 신규 — 원칙과 구현 사이의 갭을 없애기 위한 직접 매핑표]*

**상태 관리 위젯**
```
Loading 상태    → CircularProgressIndicator / LinearProgressIndicator
                   Shimmer (shimmer 패키지) — Skeleton UI
Empty 상태      → 커스텀 EmptyState 위젯 (아이콘+제목+CTA 세트)
Error 상태      → 커스텀 ErrorState 위젯 (아이콘+설명+재시도버튼)
성공 피드백     → SnackBar (ScaffoldMessenger.of(context).showSnackBar)
```

**피드백 위젯**
```
즉각 터치 반응  → InkWell (ripple) / InkResponse
촉각 피드백     → HapticFeedback.lightImpact() / selectionClick()
삭제 확인       → showDialog(AlertDialog) 또는 SnackBar with Undo action
진행 상태       → LinearProgressIndicator (상단 고정) / Stepper
```

**엄지존 · 네비게이션 위젯**
```
하단 주요 액션  → NavigationBar (M3) / BottomNavigationBar
플로팅 CTA      → FloatingActionButton.extended (텍스트+아이콘)
보조 정보 숨김  → DraggableScrollableSheet / showModalBottomSheet
단계별 폼       → PageView + PageController / Stepper
```

**어포던스 위젯**
```
눌리는 버튼     → FilledButton (M3) / ElevatedButton
소프트 버튼     → OutlinedButton / TextButton
스와이프 삭제   → Dismissible (background: 빨간 아이콘)
당겨서 새로고침 → RefreshIndicator
드래그 정렬     → ReorderableListView
입력 제한       → TextInputFormatter / inputFormatters
```

**터치 타겟 강제**
```dart
// 아이콘 버튼 터치 영역 44px 보장
SizedBox(
  width: 44,
  height: 44,
  child: IconButton(
    iconSize: 24,
    onPressed: () {},
    icon: Icon(Icons.close), // ★ 실제 구현 시 Lucide 아이콘으로 교체 (LucideIcons.x)
  ),
)
```

---

### 3-7. 화면 완성 전 UX 체크리스트
*[7인 전문가 원칙 기반 빠른 점검표 — PART 8 [UX] 섹션에 전부 포함됨]*
*[설계 단계 빠른 리뷰용. 종합 검증은 Phase 완료 시 PART 8 실행]*

```
[ ] 1. 계층이 보이는가?
       Primary CTA 1개, 텍스트 3단계 명도 확인 (Schoger)

[ ] 2. 3초 테스트 통과하는가?
       설명 없이 주요 액션 파악 가능 여부 (Krug)

[ ] 3. 3상태가 모두 있는가?
       Loading / Empty / Error 화면 전부 구현 (Nielsen)

[ ] 4. 모든 상태변화에 피드백이 있는가?
       ripple + haptic + SnackBar 또는 색상 변화 (Norman)

[ ] 5. 핵심 CTA가 엄지존(하단)에 있는가?
       BottomNavigationBar / FAB 위치 확인 (Wroblewski)

[ ] 6. 터치 타겟이 44px 이상인가?
       IconButton, 리스트 아이템 높이 확인 (Wroblewski)

[ ] 7. 어포던스가 명확한가?
       버튼은 눌릴 것 같이, 드래그 가능하면 핸들 표시 (Norman)

[ ] 8. 노이즈가 없는가?
       불필요한 Divider, 중첩 Card, 아이콘 래퍼 박스 제거 (Krug)

[ ] 9. 에러 메시지가 인간 언어인가?
       기술 코드 대신 상황 설명 + 해결 방법 안내 (Nielsen)

[ ] 10. 폼 입력이 최소화됐는가?
        자유 입력 대신 DatePicker/Dropdown/Slider 사용 (Norman)
```

---

## ▌PART 4. 라이트 모드

### 4-1. 라이트 모드 컬러 토큰
*[Apple HIG Light Mode, Google Material You, Schoger "Refactoring UI"]*

**베이스 토큰** *(설계 참고 예시 — 실제 프로젝트 값은 CLAUDE.md "디자인 시스템" 기준)*
```
--bg:         #F5F7FA   순수 흰색 금지 — 약간 회색빛 흰색
--surface:    #FFFFFF   카드
--surface-hi: #EFF2F7   인풋, 선택
--border:     #E2E8F0   구분선
```

**텍스트 계층 (라이트)**
```
Primary:   #1A1A2E
Secondary: #4A5568
Muted:     #A0AEC0
```

**라이트 Glass**
```
background:      rgba(255,255,255, 0.75)
backdrop-filter: blur(20px) saturate(1.3)
border:          1px solid rgba(0,0,0, 0.07)
box-shadow:      0 2px 16px rgba(0,0,0, 0.06),
                 inset 0 1px 0 rgba(255,255,255, 0.9)
```

**섀도우 (라이트)**
```
Low:    0 1px 3px  rgba(0,0,0, 0.08)
Mid:    0 4px 16px rgba(0,0,0, 0.10)
High:   0 8px 32px rgba(0,0,0, 0.12)
컬러:   0 4px 16px rgba(액센트, 0.15)
```

---

### 4-2. 다크/라이트 전환 원칙
*[Apple HIG: "ensure app looks good in both appearance modes"]*

- 다크/라이트 각각 **독립된 컬러 토큰** 설계 (같은 값 공유 금지)
- 액센트는 모드별 별도 튜닝 — 다크에서 쓰는 밝은 액센트를 라이트에 그대로 쓰면 너무 강함
- 흰 배경 이미지는 다크모드에서 floating 현상 → 모드별 분기 처리
- 라이트: 화사하고 친근한 느낌 / 다크: 전문적이고 집중되는 느낌

---

## ▌PART 5. 팔레트 & 컬러 차별화

### 5-1. 예시 팔레트 레퍼런스

> ※ 아래 값은 **설계 참고용 예시**이다. 실제 프로젝트 값은 CLAUDE.md "디자인 시스템" 섹션이 기준.
> 기능 컬러(위험/경고/성공)도 프로젝트별로 다를 수 있으므로, CLAUDE.md 토큰을 우선 참조한다.

**Dark Premium**
```
배경:       #0D0F14
서피스:     #141720
서피스 Hi:  #1C2030
보더:       #252A3A
액센트:     #4FC3F7  메인 블루
위험:       #EF5350
경고:       #FFB300
성공:       #26A69A
보조1:      #7986CB
보조2:      #81C784
텍스트1:    rgba(255,255,255, 0.92)
텍스트2:    rgba(255,255,255, 0.45)
텍스트3:    rgba(255,255,255, 0.18)
```

**Light Premium**
```
배경:       #F5F7FA
서피스:     #FFFFFF
서피스 Hi:  #EFF2F7
보더:       #E2E8F0
액센트:     #0EA5E9
위험:       #DC2626
경고:       #D97706
성공:       #0D9488
보조1:      #6366F1
보조2:      #16A34A
텍스트1:    #1A1A2E
텍스트2:    #4A5568
텍스트3:    #A0AEC0
```

**Glass 조합 공식**
```
다크 Glass:   bg rgba(white,0.06) / border rgba(white,0.12) / highlight rgba(white,0.25)
라이트 Glass: bg rgba(white,0.75) / border rgba(black,0.07) / highlight rgba(white,0.90)
Glow:         rgba(액센트, 0.25~0.35)
배경 orb:     액센트 계열 opacity 0.4~0.6
```

---

### 5-2. 프로젝트별 컬러 차별화
*[Malewicz: "획일적 디자인은 브랜드 없는 앱"]*

**도메인별 컬러 방향성**
```
진단/의료:         딥 블루 + 틸        신뢰, 전문성
물류/배송:         오렌지 + 딥 그린    에너지, 효율
금융:              네이비 + 골드       안정, 프리미엄
식음료:            웜 레드 + 크림      식욕, 따뜻함
에너지/엔지니어링: 일렉트릭 블루 + 앰버  기술, 경고
생산성:            퍼플 + 인디고       집중, 창의
헬스/피트니스:     에너지 그린 + 코랄  활력
```

**컬러 선정 프로세스**
1. 도메인 personality 키워드 3개 추출
2. 키워드에 맞는 컬러 계열 선택
3. 메인 액센트 1개 확정
4. 기능 컬러(위험/경고/성공) 액센트와 충돌 없이 조정
5. 다크/라이트 모드별 각각 튜닝

---

### 5-3. 프로젝트 확정 컬러 토큰 (프로젝트별 작성)

> **★ AI 참조 지침**
> 이 섹션의 토큰은 빈 템플릿이다. 실제 값은 **CLAUDE.md "디자인 시스템" 섹션**에서 가져온다.
> 코딩 시 반드시 CLAUDE.md 값을 우선 참조하고, 임의 컬러값 사용 금지.
> CLAUDE.md 디자인 시스템이 비어있으면 작성을 요청한 후 구현한다.

**프로젝트 personality 정의 (CLAUDE.md에서 확인)**
```
도메인:      (예: B2B SaaS / 소비자 커머스 / 전문직 도구 / 커뮤니티 등)
분위기:      (예: 기술적 신뢰 / 따뜻한 친근감 / 미니멀 프리미엄 등)
```

**Dark Mode 토큰 구조**
```
// 아래 값은 CLAUDE.md "디자인 시스템 > Dark Mode 토큰" 섹션에서 채운다

--bg:           (배경색 — 순수 #000000 금지, 딥 컬러 사용)
--surface:      (Glass 또는 불투명 카드)
--surface-hi:   (인풋, 선택 상태)
--border:       (구분선)
--border-hi:    (카드 상단 하이라이트)

--accent:       (메인 액센트)
--accent-dim:   (액센트 배경)
--accent-glow:  (글로우)

--danger:       #EF5350   // 변경 지양 (인지 일관성)
--warning:      #FBBF24   // 변경 지양
--success:      #34D399   // 변경 지양
--info:         (보조 컬러)

--text-primary:   rgba(255,255,255, 0.92)
--text-secondary: rgba(255,255,255, 0.45)
--text-muted:     rgba(255,255,255, 0.20)

배경 orb:  (Glassmorphism 사용 시 radial-gradient orb 2~3개 정의)
```

**Light Mode 토큰 구조**
```
// 아래 값은 CLAUDE.md "디자인 시스템 > Light Mode 토큰" 섹션에서 채운다

--bg:           (배경색)
--surface:      #FFFFFF 또는 프로젝트 서피스 컬러
--surface-hi:   (인풋, 선택 상태)
--border:       (구분선)
--border-hi:    (카드 상단 하이라이트)

--accent:       (메인 액센트 — 다크와 다른 계열 권장)
--accent-dark:  (텍스트용 어두운 액센트)
--accent-dim:   (액센트 배경)
--accent-glow:  (버튼 그림자)

--btn-gradient: (CTA 버튼 그라디언트 — 선택)

--danger:       #DC2626
--warning:      #F59E0B
--success:      #059669
--info:         (보조 컬러)

--text-primary:   (어두운 텍스트)
--text-secondary: rgba(0,0,0, 0.50)
--text-muted:     rgba(0,0,0, 0.30)
```

**모드 전환 원칙 (모든 프로젝트 공통)**
- 다크/라이트 각각 독립 토큰 (공유 금지)
- 다크와 라이트 액센트는 완전히 다른 계열 사용 권장
- 기능 컬러(danger/warning/success)도 모드별 별도 튜닝
- 다크는 집중/전문성 / 라이트는 친근/접근성 방향으로 의도적 분리



---

## ▌PART 6. 성능 & 렌더링 최적화 (Flutter)

### 6-1. 프레임 예산 & 120Hz
*[Flutter 공식 문서, Android Perfetto 팀, Apple ProMotion 가이드라인]*

**프레임 예산**
```
60Hz  → 16.6ms 이내 렌더링 완료
90Hz  → 11.1ms
120Hz →  8.3ms  ← 이 안에 UI + Raster 스레드 합산이 끝나야 함
```
초과 = Jank(버벅임), Flutter는 기기 능력에 따라 자동 대응

**120Hz 활성화**
- iOS ProMotion: Flutter Metal 엔진이 자동 지원 — 추가 코드 불필요
- Android LTPO 패널(삼성 S시리즈 등): 시스템 자동 조절
- Android 고정 주사율 기기: `flutter_displaymode` 패키지로 명시 설정
```dart
await FlutterDisplayMode.setHighRefreshRate(); // 앱 시작 시 1회
```

**ProMotion 철학** *[Apple ProMotion 가이드라인, Android Perfetto]*
- 120Hz 항상 유지 = 배터리 낭비
- "애니메이션/인터랙션 시만 120Hz, 정적 화면은 낮게"
- **안정적인 60fps > 60~120fps 불규칙 변동** (불규칙이 더 불쾌)

---

### 6-2. Jank 원인과 Impeller
*[Flutter 공식 Performance 문서, Google I/O 2023 Impeller 발표]*

**Jank 3대 원인**
```
1. Shader Compilation Jank  런타임 쉐이더 컴파일 (Skia 시대 주범)
2. 과도한 Widget Rebuild    불필요한 setState 범위 확대
3. 메인 스레드 Heavy 작업   이미지 처리·JSON 파싱을 UI 스레드에서 실행
```

**Impeller — Flutter 기본 렌더러 (3.27+)**
- 쉐이더를 **빌드 타임에 미리 컴파일** → 런타임 컴파일 Jank 완전 제거
- iOS: 3.29부터 강제 적용 / Android: API 29+ 기본 활성화
- 복잡한 화면 래스터화 시간 약 50% 단축
- Glass/Blur 효과가 Impeller에서 훨씬 안정적 (첫 프레임 jank 해소)

---

### 6-3. Flutter 최적화 실전
*[Flutter 공식 문서, Startup House 사례 연구, Flutternest 엔지니어링]*

**Widget Rebuild 최소화**
```dart
// 변하지 않는 위젯: const 필수 — 프레임워크가 rebuild 완전 스킵
const Icon(Icons.settings, size: 48)
const Divider()
const SizedBox(height: 16)
```
- 큰 `build()` 메서드 → 작은 위젯 클래스로 분리 (rebuild 범위 축소)

**RepaintBoundary — 자주 바뀌는 위젯 격리**
```dart
RepaintBoundary(
  child: LiveChart(), // 실시간 수치, 타이머, 애니메이션, 지도, 차트
)
```
- 적용 시 해당 위젯만 repaint, 나머지 화면 영향 없음
- 단순 정적 위젯에 과용 금지 → compositor 오버헤드

**Heavy 작업 분리**
```dart
// JSON 파싱, 이미지 처리 → compute()로 별도 isolate
final result = await compute(parseHeavyJson, rawData);
```

**리스트 — 무조건 builder**
```dart
ListView.builder(itemBuilder: ...)   // 화면 밖은 빌드 안 함
GridView.builder(itemBuilder: ...)
// Column 안에 전체 리스트 넣기 절대 금지 (메모리/CPU 폭발)
```

**이미지 최적화**
```dart
Image.network(url, cacheWidth: 200, cacheHeight: 200) // 썸네일 디코드 크기 지정
precacheImage(NetworkImage(url), context)              // 다음 화면 미리 로드
```

**메모리 누수 방지**
- `AnimationController` / `StreamSubscription` / `TextEditingController`
  → 반드시 `dispose()` 호출
- 미처리 시 반복 네비게이션마다 메모리 누적 → 장기 사용 후 앱 느려짐

---

### 6-4. Glass/Blur 성능 원칙
*[Cuberto 성능 주의사항, Flutter Impeller 문서]*

- `BackdropFilter(blur)` = GPU 비용 높음 → 화면당 사용 최소화
- **스크롤 중 blur 값 변경 절대 금지** — 매 프레임 GPU 재계산
- 고정된 네비게이션바/헤더의 Static blur는 성능 영향 적음
- 반투명 레이어 중첩(Overdraw) 최소화
- 구형 기기: Glass 효과 조건부 적용 (단색 폴백 처리)

---

### 6-5. 프로파일링 원칙
*[Flutter DevTools 공식 문서]*

- **반드시 실기기 + Profile 모드** (Debug 모드는 5~10배 느림)
- DevTools Performance View: UI/Raster 스레드 프레임 시간 확인
- 빨간 프레임 바 = 16ms 초과 = Jank 발생 지점
- "Track Widget Rebuilds"로 불필요한 rebuild 위젯 특정
- **가장 약한 타겟 기기에서 먼저 프로파일링**

---

## ▌PART 7. 트렌드 레이더 — 2025~2026

### 7-0. 트렌드 적용 전 판단 필터
*[Malewicz: "트렌드는 도구다. 페르소나에게 맞을 때만 써라"]*

```
트렌드 적용 전 이 3가지를 확인한다:

1. 페르소나 적합성
   이 앱의 주 페르소나(CLAUDE.md 페르소나 섹션)에게 이 트렌드가 어색하지 않은가?
   예: 50대 현장 기술자 대상 앱에 Liquid Glass → 낯설고 복잡하게 느껴질 수 있음

2. 도메인 신뢰도
   이 트렌드가 앱의 신뢰감을 높이는가 낮추는가?
   예: 의료/안전 앱에 과도한 Ambient Glow → 장난스러워 보일 수 있음

3. 성능 비용
   이 트렌드가 타겟 기기에서 실행 가능한가?
   예: 저사양 Android 기기에 Heavy Glass blur → Jank 발생 (PART 6 참조)

→ 3가지 모두 통과한 트렌드만 적용한다
```

### 7-1. 지금 해야 할 것들
*[Apple iOS 26, Google Material You, Gleb Kuznetsov, Cuberto, Orizon Agency]*

**Liquid Glass** — iOS 26 공식 머티리얼
- 단순 blur가 아닌 굴절+반사 시뮬레이션
- 구현 핵심: 배경 메시 그라디언트 + backdrop-filter + 상단 하이라이트

**Ambient Color** — Material You 방향
- 활성 요소 주변에 해당 컬러 glow → 맥락 반응형 컬러

**Depth & Layering** — z축 적극 활용
- 모달/시트: 배경 dimming + scale(0.96) down

**Micro Typography** — Gleb Kuznetsov 스타일
- Monospace 수치 + 컬러 레이블 → 숫자 자체가 디자인 요소

### 7-2. 피해야 할 것들
```
❌ 순수 Flat Design (2015년 느낌)
❌ 과도한 Neumorphism (접근성 문제)
❌ 무지개 그라디언트 남발
❌ CTA 버튼 3색 이상 그라디언트 — 항상 저렴해 보임 [Gary Simon]
❌ 아이콘 단독 버튼 남발 — 텍스트 없는 아이콘은 숙련자에게만 작동 [Gary Simon]
❌ 카드 안에 아이콘 래퍼 박스 (중첩 컨테이너)
❌ 이모지를 UI 아이콘으로 사용
❌ 모든 요소에 shadow 남발
❌ 텍스트 위 텍스트 그림자
❌ 500ms 이상 트랜지션
❌ 온보딩 3장 초과 강제 슬라이드
```

---

## ▌PART 9. IA & 네비게이션 구조

*[Steve Krug "Don't Make Me Think", Nielsen Norman Group, Apple HIG Navigation]*

### 9-1. 역할 기반 진입 분기 원칙

앱이 다수의 사용자 역할을 가질 때, 단일 IA로 묶으면 모든 역할에게
불필요한 항목이 보여 인지 부하가 높아진다. *(Krug: "노이즈를 줄여라")*

**역할 선택 화면 → IA 분기 패턴**
```
앱 최초 진입
    ↓
역할 선택 화면 (Role Select)
    ├─ 역할 A → 전용 탭 구조 A
    ├─ 역할 B → 전용 탭 구조 B
    └─ 역할 C → 전용 탭 구조 C

공통 원칙:
  - 역할 전환: 설정 탭 → 언제든 가능 (강제 로그아웃 없이)
  - 역할별 탭 수: 4~5개 (NN Group: 3개 미만 = 기능 빈약, 6개 이상 = 혼란)
  - 기본 역할 추천: 직전 사용 역할 자동 선택
```

**탭 우선순위 배치 원칙** *(Wroblewski: 엄지존 하단 중앙 = 가장 자주 쓰는 기능)*
```
탭 1 (좌) — 홈/대시보드       자주 쓰는 정보 요약
탭 2      — 핵심 액션 A       도메인 1순위 기능
탭 3 (중앙) — 핵심 액션 B     가장 중요한 단일 액션 (강조 가능)
탭 4      — 핵심 액션 C       도메인 2순위 기능
탭 5 (우) — 프로필/설정       자주 안 쓰지만 필요한 설정
```

---

### 9-2. 화면 뎁스(Depth) 원칙

*[Krug: 최대 3단계 / Apple HIG: NavigationStack depth 3 권장]*

```
Level 0 — 탭 바 (항상 표시, 절대 숨기지 않음)
Level 1 — 탭 메인 화면 (목록 / 대시보드)
Level 2 — 상세 화면 (아이템 상세, 편집, 실행 화면)
Level 3 — 액션/컨펌 (바텀시트, 모달, 결과 화면)
           ↑ 이 이상 깊어지면 반드시 구조 재설계
```

**Level 3 처리 패턴별 적합 사례**
```
바텀시트:   임시 컨텍스트, 메인 화면 맥락 유지 필요 시
모달 전체화면: 집중이 필요한 멀티스텝 프로세스
Inline 확장: 단순 확인/편집 (접기/펼치기)
별도 탭 분기: 독립 워크플로우 (Level 2에서 새 탭 전환)
```

**뒤로가기 일관성** *(Nielsen 휴리스틱 #3: User control and freedom)*
```
Level 3 (바텀시트/모달): 스와이프다운 + X 버튼 + 백 제스처 모두 닫기
Level 2 (푸시 화면):     좌상단 뒤로가기 화살표 + 스와이프백 제스처
Level 1 (탭):            뒤로가기 없음 (탭 전환만)
탭 외부 화면 (full push): 좌상단 ✕ 닫기 (모달처럼 진입한 경우)
```

---

### 9-3. 빈 상태 & 온보딩 IA

**빈 상태(Empty State) 위계** *(Krug: "없습니다" 한 줄은 기회 낭비)*
```
첫 진입 빈 상태:  일러스트 + 가치 설명 + CTA (기능 첫 사용 유도)
검색 빈 상태:     "찾는 결과가 없습니다" + 검색어 수정 제안
오류 빈 상태:     오류 아이콘 + 원인 설명 + 재시도 버튼
권한 필요 상태:   필요한 이유 + 권한 요청 버튼
```

**다중 역할 앱 온보딩 순서**
```
1. 역할 선택 (강제, Skip 없음 — 역할 모르면 앱 진입 불가)
2. 역할별 핵심 기능 소개 1장 (선택적 Skip 가능)
3. 바로 앱 진입 → Progressive 툴팁으로 나머지 안내
```

---

## ▌PART 10. 오프라인 UX 패턴

*[Nielsen 휴리스틱 #1: Visibility of system status]*
*[NN Group: "오프라인 상태를 숨기는 앱은 사용자 신뢰를 잃는다"]*

### 10-1. 오프라인 상태 표시 원칙

**상태 표시 위치 & 타이밍**
```
인터넷 끊김 감지 즉시:
  → 상단 배너 등장 (animate down, 높이 32px)
  → 배경: 앰버(#FFB300) 또는 다크 베이스 위 amber/0.15
  → 텍스트: "오프라인 모드" + 아이콘 (wifi-off)
  → 서브텍스트: "계산·진단은 정상 사용 가능"

인터넷 복귀 감지:
  → 배너 → 틸/그린 컬러로 1.5초 변환 ("연결됨, 동기화 중...")
  → 동기화 완료 후 배너 자동 사라짐 (slide up 0.3s)
```

**오프라인 불가 기능 처리** *(Nielsen 휴리스틱 #4: Consistency)*
```
온라인 전용 기능 UI 상태:
  opacity: 0.4
  아이콘: wifi-off 오버레이 (우상단 16px)
  탭 시: "인터넷 연결이 필요한 기능입니다" 스낵바 (팝업 아님)

절대 금지:
  ❌ 오프라인 상태에서 온라인 전용 기능 탭 → 빈 화면 로딩
  ❌ 오프라인 상태에서 저장 버튼 탭 → 아무 반응 없음
  ❌ 오프라인 여부 사용자에게 숨김
```

**오프라인 + 유료잠금 동시 상태 처리**
*(온라인 전용이면서 미구독 기능 — 두 조건이 겹치는 경우)*
```
우선순위: 오프라인 상태 > 유료 잠금
  → 현재 오프라인이면 wifi-off 아이콘만 표시
  → 온라인 복귀 후 → 자물쇠(lock) 아이콘으로 전환

이유: 오프라인 상태에서 업그레이드 유도는 결제 불가 → UX 낭비
     사용자에게 가장 즉각적인 장애물 하나만 보여줄 것 (Krug: 단순화)

아이콘 중복 표시 금지:
  ❌ wifi-off + lock 동시 표시 → 혼란
  ✅ 상태에 따라 하나만: 오프라인 중 → wifi-off / 온라인 미구독 → lock
```

---

### 10-2. 오프라인 큐 UX

**저장 대기 상태 표시**
```
오프라인 중 데이터 저장 시:
  → 저장 버튼 탭 → 즉시 로컬 저장 + 성공 피드백
  → 카드/항목에 "동기화 대기 중" 뱃지 (앰버, 작게)
  → 배지 텍스트: "[upload-cloud 아이콘] 저장됨 (미전송)"

온라인 복귀 후 자동 동기화 중:
  → 뱃지 → 스피너 애니메이션 ("전송 중...")

동기화 완료:
  → 뱃지 사라짐 (fade 0.3s)
```

**동기화 충돌 시 사용자 개입**
```
충돌 감지 → 바텀시트 등장
  ┌────────────────────────────────┐
  │ 데이터 충돌이 감지됐습니다      │
  │                                │
  │ [smartphone 아이콘] 기기 저장본 (오늘 14:32)    │
  │ [cloud 아이콘] 서버 저장본 (오늘 13:11)    │
  │                                │
  │ [기기 저장본 유지]  [서버 버전 사용] │
  └────────────────────────────────┘
  
보고서/문서: "기기 저장본 유지" 기본 선택 강조 (로컬 작업 데이터 우선)
장비 기본정보: 두 버전 나란히 비교 표시
```

---

### 10-3. 오프라인 DB 사전 다운로드 UX

**초기 설정 화면 (최초 로그인 후)**
```
"오프라인 사용을 위해 데이터베이스를 다운로드합니다"

필수 DB (자동 시작, 취소 불가):
  [████████████░░░] 62% — [핵심 데이터 DB 이름]
  예상 소요: 약 45초 (Wi-Fi 기준)

선택 DB (선택 가능):
  □ 확장 데이터 캐시 — +[용량]
  □ 추가 콘텐츠 패키지 — +[용량]
  [나중에 설정에서 변경 가능]

하단: [건너뛰기 — 온라인 전용으로 계속]
```

**DB 업데이트 알림**
```
백그라운드 업데이트 완료 시:
  → LEVEL 3 INFO 알림: "[DB 이름] 업데이트됨 (v12 → v13)"
  → 탭 시 변경 내용 요약 바텀시트

수동 업데이트 (설정 → 오프라인 DB 관리):
  현재 버전 / 최신 버전 / 마지막 확인일 표시
  각 DB별 업데이트 버튼
```

---

## ▌PART 11. 알람 & 상태 UI 시스템

*[Nielsen 휴리스틱 #1: Visibility / #5: Error Prevention]*
*[IFMA FMJ 예지보전 원칙 — 알람 피로도 방지]*

### 11-1. 알람 3단계 시각 언어

> ※ 아래 컬러는 CLAUDE.md "디자인 시스템" 기능 컬러 토큰을 사용한다.
> hex값은 기본 참고값이며, 프로젝트 토큰이 다르면 토큰을 따른다.

```
CRITICAL  — AppColors.danger  + 강한 글로우 0 0 12px rgba(danger,0.5)
WARNING   — AppColors.warning + 약한 글로우 0 0 8px  rgba(warning,0.3)
INFO      — AppColors.info    글로우 없음
```

**각 레벨별 UI 컴포넌트 처리**

| 위치             | CRITICAL              | WARNING               | INFO            |
|------------------|-----------------------|-----------------------|-----------------|
| 홈 배너          | 고정, 닫기 불가        | 고정, 스와이프 가능    | 없음            |
| 탭바 배지        | 빨간 원 + 숫자        | 노란 원 + 숫자        | 없음            |
| 알람 목록 행     | 레드 좌측 강조 바     | 앰버 좌측 강조 바     | 틸 좌측 바      |
| 장비 카드 상태   | 레드 테두리 글로우    | 앰버 테두리            | 변화 없음       |
| 푸시 알림        | 강제 (무음 모드 무시)  | 일반 (무음 존중)       | 없음 (기본값)   |

---

### 11-2. 알람 발생 애니메이션

**CRITICAL 알람 등장 패턴**
```
1. 홈 탭 배너: slide down 0.3s spring + 레드 글로우 pulse 2회
2. 탭바 배지: scale(0) → scale(1.2) → scale(1.0) bounce
3. 장비 카드: border-color fade-in 0.5s + glow pulse 반복 (해제 전까지)

pulse 애니메이션:
  0% → opacity 0.5  /  50% → opacity 1.0  /  100% → opacity 0.5
  duration: 2s infinite (CRITICAL) / 없음 (WARNING)
```

**알람 해제 애니메이션**
```
배너: slide up 0.25s + 그린 flash 0.15s → 사라짐
카드 테두리: 레드 → 표준 컬러 fade 0.4s
배지: scale(1.0) → scale(0) fade 0.2s
```

---

### 11-3. 알람 목록 화면 설계

**정렬 원칙** *(Krug: 중요한 것을 먼저)*
```
1순위: CRITICAL (발생 시각 역순)
2순위: WARNING  (발생 시각 역순)
3순위: INFO     (기본 숨김, "더 보기" 탭으로 확장)

미응답 알람: 상단 고정 + "미응답" 레드 뱃지
응답 완료:   하단 배치 + opacity 0.6
```

**알람 카드 구조 (리스트 행)**
```
[좌측 컬러 바 3px] [아이콘] [장비명 + 알람 내용]  [시각]
                            [측정값 스냅샷]         [미응답 뱃지]
```

**알람 상세 (탭 시 바텀시트)**
```
발생 위치 / 항목명
발생 시각 / 지속 시간
측정값 스냅샷 (발생 당시)
추천 액션:  [상세 보기] [담당자 연락]   ← 프로젝트별 액션으로 교체
이력: 동일 항목 최근 알람 목록 (마지막 3건)
```

---

### 11-4. 알람 피로도 방지 *(IFMA FMJ 원칙)*

```
중복 알람 억제:
  동일 장비 + 동일 원인 → 30분 내 재발생 시 묶어서 1개로 표시
  카드에 "(3회 발생)" 카운터 표시

알람 무음 시간대:
  설정 → 알람 무음 시간 (예: 00:00~06:00)
  CRITICAL은 무음 시간 무시 (항상 울림)
  설정 화면에 명확한 안내: "CRITICAL 알람은 항상 울립니다"

알람 임계값 조정 안내:
  동일 유형 알람이 7일간 10회 이상 발생 → "알람 기준 조정을 권장합니다" INFO 알람
```

---

## ▌PART 8. 체크리스트 — Phase 완료마다 실행

*⚠️ Phase 완료 시 전체 점검이 주 용도 (CLAUDE.md 섹션 0 "종합 검증" 단계).*
*설계 단계에서 특정 항목을 참고할 수 있으나, 매 화면 인라인 검증과 혼용 금지.*

> 조건부 항목 표기:
> `[공통]` — 모든 프로젝트 필수
> `[Glass]` — 다크 Glass 스타일 프로젝트만
> `[Light]` — 라이트 파스텔 스타일 프로젝트만
> `[오프라인]` — 오프라인 기능 있는 프로젝트만
> `[알람]` — 알람/알림 기능 있는 프로젝트만
> `[RBAC]` — 다중 역할 앱만

**[ 비주얼 ]**
- [ ] `[공통]` 아이콘 래퍼 박스 없는가 (카드→아이콘→텍스트 구조)
- [ ] `[공통]` 텍스트 위계 3단계 이상 구분되는가
- [ ] `[공통]` 액센트 컬러 1~2개로 절제되어 있는가
- [ ] `[공통]` 수치/값은 Monospace 폰트인가
- [ ] `[공통]` 컬러 팔레트 7색 이내인가
- [ ] `[공통]` 전체 화면 간 일관성 유지되는가
- [ ] `[Glass]` 배경에 컬러 메시/orb 그라디언트 있는가
- [ ] `[Glass]` Glass 카드 상단 하이라이트 라인 있는가
- [ ] `[Light]` 배경이 순수 흰색이 아닌 크림/파스텔 톤인가
- [ ] `[Light]` 카드 그림자가 컬러 틴트 포함인가

**[ i18n ]**
- [ ] `[공통]` 위젯 내 문자열 리터럴이 0개인가
- [ ] `[공통]` 에러 메시지·스낵바·다이얼로그 텍스트도 arb 키인가
- [ ] `[공통]` app_ko.arb / app_en.arb 키 개수가 동일한가 (누락 키 없는가)
- [ ] `[공통]` 플레이스홀더 포함 키가 정확히 동작하는가

**[ UX ]**
- [ ] `[공통]` 3초 내 주요 액션 파악 가능한가 (Krug)
- [ ] `[공통]` Primary CTA 1개가 압도적으로 눈에 띄는가 (Krug Satisficing)
- [ ] `[공통]` 주요 버튼이 엄지존(하단)에 있는가 (Wroblewski)
- [ ] `[공통]` FAB 있는 경우 스크롤 다운 시 숨김 처리됐는가 (Wroblewski)
- [ ] `[공통]` 터치 타겟이 CLAUDE.md 기준을 충족하는가
- [ ] `[공통]` Loading / Empty / Error 3상태 모두 구현됐는가 (Nielsen)
- [ ] `[공통]` 모든 액션에 상태 피드백 있는가 (ripple/SnackBar/햅틱)
- [ ] `[공통]` 저장/공유/삭제 시 Conceptual Model 피드백 있는가 (Norman)
- [ ] `[공통]` 바텀시트에 Grab Handle 있는가
- [ ] `[공통]` 온보딩 3장 이내 + Skip 있는가
- [ ] `[공통]` 숙련 사용자용 스와이프/롱프레스 단축 패턴 포함됐는가 (Nielsen #7 — 전문직 도구일수록 중요)

**[ IA & 네비게이션 ]**
- [ ] `[공통]` 화면 뎁스 3단계 이내인가
- [ ] `[공통]` 뒤로가기 동작이 Level별로 일관성 있는가
- [ ] `[공통]` 탭 수 4~5개 범위인가
- [ ] `[공통]` 빈 상태 4종 (첫 진입/검색/오류/권한) 설계됐는가
- [ ] `[RBAC]` 역할별 IA 분기 정의되어 있는가 (PART 9)

**[ 오프라인 UX ]** ← 오프라인 기능 없는 프로젝트 전체 스킵
- [ ] `[오프라인]` 오프라인 상태 배너 표시 구현됐는가
- [ ] `[오프라인]` 온라인 전용 기능 opacity 0.4 처리됐는가
- [ ] `[오프라인]` 오프라인 저장 → "동기화 대기" 뱃지 있는가
- [ ] `[오프라인]` 동기화 충돌 시 사용자 선택 UI 구현됐는가

**[ 알람 UI ]** ← 알람/알림 기능 없는 프로젝트 전체 스킵
- [ ] `[알람]` CRITICAL/WARNING/INFO 3단계 컬러 정의됐는가
- [ ] `[알람]` CRITICAL 알람 pulse 애니메이션 적용됐는가
- [ ] `[알람]` 알람 목록 우선순위 정렬 구현됐는가
- [ ] `[알람]` 중복 알람 묶음 처리됐는가

**[ 완성도 ]**
- [ ] `[공통]` 8pt grid 지켜졌는가
- [ ] `[공통]` 카드 공간이 콘텐츠로 꽉 채워져 있는가
- [ ] `[공통]` 이모지/아이콘 혼용 없는가
- [ ] `[공통]` 다크/라이트 대비율 4.5:1 이상인가 (Apple HIG)

**[ 성능 ]**
- [ ] `[공통]` 변하지 않는 위젯 const 적용
- [ ] `[공통]` 리스트 ListView.builder / GridView.builder 사용
- [ ] `[공통]` AnimationController dispose() 처리
- [ ] `[공통]` Heavy 작업 compute()로 분리
- [ ] `[공통]` 실기기 Profile 모드 60fps 유지 확인
- [ ] `[Glass]` 스크롤 중 BackdropFilter blur 값 변경 없음
- [ ] `[Glass]` 실시간 위젯 RepaintBoundary 적용

---

*출처: Michal Malewicz / Gleb Kuznetsov / Ghani Pradita / RonDesignLab / Cuberto /
Orizon Agency / Steve Schoger(Refactoring UI) / Gary Simon(DesignCourse) /
Caler Edwards / Juxtopposed / Hyperplexed / Pablo Stanley /
Steve Krug(Don't Make Me Think) / Jakob Nielsen(Nielsen Norman Group) /
Luke Wroblewski / Apple HIG + iOS 26 Liquid Glass + ProMotion /
Google Material You / Wolt UX Engineering Blog /
Flutter 공식 문서(Performance, Impeller, DevTools) /
Google I/O 2023 / Android Perfetto 팀 / flutter_displaymode 패키지*

---

## ▌PART 12. Flutter 구현 코드 레퍼런스 (v3.0 신규)

*CSS 스펙을 Flutter Dart 코드로 직접 변환 — Claude Code가 이 섹션을 우선 참조할 것*

> **★ PART 12 사용 지침**
> AppColors의 실제 색상 값은 **CLAUDE.md "디자인 시스템" 섹션**에서 가져온다.
> 아래 코드는 구조·패턴 레퍼런스다. 색상 상수만 CLAUDE.md 값으로 교체하면 즉시 사용 가능.
> CLAUDE.md 디자인 시스템이 미작성 상태면 먼저 작성을 요청한다.
> ⚠️ 레퍼런스 코드 내 opacity 변형값(`Color(0x1F...)` 등)은 패턴 참고용이다.
> 실제 구현 시 AppColors에 해당 토큰을 추가한 후 교체할 것.

### 12-1. AppColors 토큰 파일

> ⛔ **아래 코드의 `0xFF______` 플레이스홀더는 절대 그대로 출력하지 않는다.**
> 반드시 CLAUDE.md "디자인 시스템" 섹션의 실제 값으로 교체 후 제공.
> 디자인 시스템이 비어있으면 → 이 코드 생성 전 작성 요청.

```dart
// lib/core/theme/app_colors.dart
// ★ 색상 값은 CLAUDE.md "디자인 시스템" 섹션의 토큰을 그대로 사용
// ★ 아래 플레이스홀더를 실제 프로젝트 값으로 교체할 것

class AppColors {
  // ── Dark Mode ─────────────────────────────────────────
  // CLAUDE.md Dark Mode 토큰 참조
  static const darkBg          = Color(0xFF______); // --bg
  static const darkSurface     = Color(0x__FFFFFF); // --surface   (rgba white + opacity)
  static const darkSurfaceHi   = Color(0x__FFFFFF); // --surface-hi
  static const darkBorder      = Color(0x__FFFFFF); // --border
  static const darkBorderHi    = Color(0x__FFFFFF); // --border-hi

  static const darkAccent      = Color(0xFF______); // --accent
  static const darkAccentDim   = Color(0x________); // --accent-dim
  static const darkAccentGlow  = Color(0x________); // --accent-glow

  // 기능 컬러 — 변경 지양 (인지 일관성)
  static const darkDanger      = Color(0xFFEF5350);
  static const darkWarning     = Color(0xFFFBBF24);
  static const darkSuccess     = Color(0xFF34D399);
  static const darkInfo        = Color(0xFF______); // --info

  static const darkText1       = Color(0xEBFFFFFF); // rgba(255,255,255,0.92)
  static const darkText2       = Color(0x73FFFFFF); // rgba(255,255,255,0.45)
  static const darkText3       = Color(0x33FFFFFF); // rgba(255,255,255,0.20)

  // ── Light Mode ────────────────────────────────────────
  // CLAUDE.md Light Mode 토큰 참조
  static const lightBg         = Color(0xFF______); // --bg
  static const lightSurface    = Color(0xFFFFFFFF); // --surface
  static const lightSurfaceHi  = Color(0xFF______); // --surface-hi
  static const lightBorder     = Color(0x________); // --border
  static const lightBorderHi   = Color(0x________); // --border-hi (카드 상단 하이라이트)

  static const lightAccent     = Color(0xFF______); // --accent
  static const lightAccentDark = Color(0xFF______); // --accent-dark
  static const lightAccentDim  = Color(0x________); // --accent-dim
  static const lightAccentGlow = Color(0x________); // --accent-glow (버튼 그림자)

  // 기능 컬러 — 변경 지양 (인지 일관성)
  static const lightDanger     = Color(0xFFDC2626);
  static const lightWarning    = Color(0xFFF59E0B);
  static const lightSuccess    = Color(0xFF059669);
  static const lightInfo       = Color(0xFF______); // --info

  static const lightText1      = Color(0xFF______); // --text-primary
  static const lightText2      = Color(0x80000000); // rgba(0,0,0,0.50)
  static const lightText3      = Color(0x4D000000); // rgba(0,0,0,0.30)
}
```

---

### 12-2. AppTheme (ThemeData)

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.darkAccent,
      secondary: AppColors.darkInfo,
      surface:   AppColors.darkSurface,
      error:     AppColors.darkDanger,
      onPrimary: AppColors.darkBg,
      onSurface: AppColors.darkText1,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceHi,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkAccent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.darkText3),
    ),
    textTheme: _buildTextTheme(AppColors.darkText1, AppColors.darkText2),
    iconTheme: const IconThemeData(color: AppColors.darkText2, size: 22),
    dividerColor: AppColors.darkBorder,
  );

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary:   AppColors.lightAccent,
      secondary: AppColors.lightInfo,
      surface:   AppColors.lightSurface,
      error:     AppColors.lightDanger,
      onPrimary: AppColors.lightSurface, // ⚠️ CTA 위 텍스트 — CLAUDE.md에 --on-accent 토큰 추가 후 교체 권장
      onSurface: AppColors.lightText1,
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      elevation: 0,
      // ★ shadowColor는 CLAUDE.md lightAccentGlow 토큰 사용
      // 예: shadowColor: AppColors.lightAccentGlow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurfaceHi,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightAccent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.lightText3),
    ),
    textTheme: _buildTextTheme(AppColors.lightText1, AppColors.lightText2),
    iconTheme: const IconThemeData(color: AppColors.lightText2, size: 22),
    dividerColor: AppColors.lightBorder,
  );

  static TextTheme _buildTextTheme(Color primary, Color secondary) =>
    TextTheme(
      // 페이지 제목 22~24px weight 700
      headlineMedium: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w700,
        letterSpacing: -0.3, color: primary,
      ),
      // 카드 제목 14~16px weight 600
      titleMedium: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, color: primary,
      ),
      // 서브레이블 11~12px weight 500
      labelSmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500,
        letterSpacing: 0.3, color: secondary,
      ),
      // 본문
      bodyMedium: TextStyle(fontSize: 14, color: primary, height: 1.6),
      // 캡션/뱃지 9~10px
      bodySmall: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 0.5, color: secondary,
      ),
    );
}
```

---

### 12-3. Glass 카드 위젯

```dart
// lib/core/widgets/glass_card.dart

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
    this.blurSigma = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorderHi : AppColors.lightBorderHi,
                width: 0.8,
              ),
              left: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
              right: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
              bottom: BorderSide(
                color: isDark
                    ? const Color(0x0DFFFFFF) // ⚠️ 레퍼런스 한정 — Glass 하단 rgba(255,255,255,0.05)
                                               // 실제 구현 시 AppColors에 darkBorderGlassBottom 토큰 추가 권장
                    : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            boxShadow: isDark
                ? [BoxShadow(color: AppColors.darkAccentGlow, blurRadius: 32, offset: const Offset(0, 8))]
                : [BoxShadow(color: AppColors.lightAccentGlow, blurRadius: 12, offset: const Offset(0, 2))],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
```

---

### 12-4. 상태 뱃지 위젯

```dart
// lib/core/widgets/status_badge.dart
// ⚠️ _resolveColors 내 opacity 변형값(0x1F.., 0x40..)은 레퍼런스 코드 한정.
// 실제 구현 시 AppColors에 배지용 토큰 추가 후 교체할 것. 직접 Color() 금지.
// 사용 예: StatusBadge(label: context.l10n.statusNormal, status: BadgeStatus.normal)
// ⚠️ label에 문자열 직접 전달 금지 — 반드시 context.l10n.키명 사용

enum BadgeStatus { normal, warning, danger, info, muted }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;

  const StatusBadge({super.key, required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _resolveColors(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.$2, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 0.5, color: colors.$3,
        ),
      ),
    );
  }

  (Color, Color, Color) _resolveColors(bool isDark) => switch (status) {
    BadgeStatus.normal  => isDark
        ? (const Color(0x1F34D399), const Color(0x4034D399), AppColors.darkSuccess)
        : (const Color(0x1A059669), const Color(0x33059669), AppColors.lightSuccess),
    BadgeStatus.warning => isDark
        ? (const Color(0x1FFBBF24), const Color(0x40FBBF24), AppColors.darkWarning)
        : (const Color(0x1AF59E0B), const Color(0x33F59E0B), AppColors.lightWarning),
    BadgeStatus.danger  => isDark
        ? (const Color(0x1FEF5350), const Color(0x40EF5350), AppColors.darkDanger)
        : (const Color(0x1ADC2626), const Color(0x33DC2626), AppColors.lightDanger),
    BadgeStatus.info    => isDark
        ? (const Color(0x1F818CF8), const Color(0x40818CF8), AppColors.darkInfo)
        : (const Color(0x1A6366F1), const Color(0x336366F1), AppColors.lightInfo),
    BadgeStatus.muted   => isDark
        ? (AppColors.darkSurface, AppColors.darkBorder, AppColors.darkText2)
        : (AppColors.lightSurfaceHi, AppColors.lightBorder, AppColors.lightText2),
  };
}
```

---

### 12-5. Primary CTA 버튼

```dart
// lib/core/widgets/primary_button.dart
// 사용 예: PrimaryButton(label: context.l10n.commonSave, onTap: _save)
// ⚠️ label에 문자열 직접 전달 금지 — 반드시 context.l10n.키명 사용

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            // ★ 그라디언트 색상은 AppColors 토큰 사용 (CLAUDE.md 값 기반)
            // accent 계열로 그라디언트 구성: accent → accent의 약간 어두운 버전
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkAccent, AppColors.darkAccentGlow.withOpacity(1.0)]
                  : [AppColors.lightAccent, AppColors.lightAccentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: isDark ? AppColors.darkAccentGlow : AppColors.lightAccentDim,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    // ★ CTA 위 컬러: 다크=배경색, 라이트=흰색 계열
                    // CLAUDE.md에 --on-accent 토큰 추가 후 교체 권장
                    color: isDark ? AppColors.darkBg : AppColors.lightSurface,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: isDark ? AppColors.darkBg : AppColors.lightSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
```

---

### 12-6. main.dart 테마 적용

```dart
// lib/main.dart
// ※ onGenerateTitle 사용 시 아래 import 필요:
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

MaterialApp(
  // ⚠️ title은 context 없이 호출되므로 onGenerateTitle 사용
  onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system, // 시스템 설정 자동 추종
  // 수동 전환 원할 시: ThemeMode.dark / ThemeMode.light
  home: const RootScreen(),
)
```


---

## ▌PART 13. Phase별 디자인 컴포넌트 우선순위 (프로젝트별 작성)

*각 Phase 시작 전 반드시 해당 섹션 확인 — "현재 Phase에 필요한 컴포넌트만 구현"*

> **★ 이 PART는 프로젝트별로 작성한다.**
> 아래는 작성 가이드 + 범용 공통 원칙이다.
> Phase 계획은 CLAUDE.md 섹션 0-1에서 가져온다.

---

### 작성 가이드

각 Phase에 대해 아래 형식으로 작성한다:

```
### PHASE N — [Phase 이름]
*[이 Phase에 포함된 기능 코드 목록]*

**핵심 컴포넌트 (반드시 완성)**
- ComponentA: 설명 (PART N 참조)
- ComponentB: 설명

**이 Phase에서 구현 금지**
❌ [기능명] — Phase M 이후

**화면 구조 원칙**
- [이 Phase의 레이아웃 패턴]
```

---

### 공통 — 모든 Phase 적용 규칙

```
✅ 카드 → 아이콘(48px+) → 텍스트 구조 (아이콘 래퍼 박스 절대 금지)
✅ 수치는 항상 Monospace 폰트
✅ 터치 타겟: 기본 44px / 전문직·장갑 환경 56px (CLAUDE.md 기준 확인)
✅ 버튼은 항상 엄지존(하단)
✅ 로딩/성공/에러 3상태 항상 설계
✅ GlassCard 사용 시 배경에 컬러 오브 필수
✅ 다크/라이트 ThemeData 분리 (AppColors 토큰 직접 참조)
✅ ListView/GridView는 무조건 .builder
✅ const 위젯 최대한 활용
```

---

## PART 14. 도메인 특화 UX & 페르소나 (프로젝트별 작성)

> **★ 이 PART는 프로젝트별로 작성한다.**
> 아래는 작성 가이드 + 범용 UX 원칙이다.
> 페르소나 정의는 CLAUDE.md "페르소나" 섹션과 연동한다.

---

### 14-0. 도메인 환경 제약 조건

```
<!-- 이 앱의 사용자가 처한 물리적·기술적·인지적 환경을 기술 -->
<!-- 예: 야외 작업자 / 고령 사용자 / 인터넷 불안정 환경 / 장갑 착용 등 -->

조명:          (예: 실내 사무실 / 야외 직사광선 / 어두운 창고)
네트워크:      (예: 항상 연결 / 간헐적 오프라인 / 오프라인 우선)
신체 제약:     (예: 장갑 착용 / 한 손 사용 / 이동 중 사용)
인지 부하:     (예: 긴장 상태 / 멀티태스킹 / 여유 있는 환경)
```

---

### 14-1. 페르소나 × 진입 플로우 설계

> **CLAUDE.md 페르소나 섹션과 완전 통일** — 두 파일 간 페르소나 명칭 혼용 금지

```
<!-- 각 페르소나에 대해 아래 형식으로 작성 -->

#### [P코드] — [역할명]
특성:         [경험, 목표, 환경]
주요 태스크:  [이 페르소나가 자주 하는 작업]
홈 진입 플로우:
  홈 → [단계1] → [단계2] → [결과]
빠른 접근 니즈: [이 페르소나에게 중요한 숏컷]
```

---

### 14-2. 홈 화면 정보 계층 (Hick's Law 적용)

```
<!-- 홈 화면 CTA 배치 원칙 정의 -->
<!-- Hick's Law: 선택지 수 = 반응 시간. CTA 3개 이하 권장 -->

PRIMARY CTA (1개):    [가장 핵심 액션]
SECONDARY CTA (최대 2개): [보조 액션]
숨김 기능:            [더 보기 뒤로 넣을 고급 기능 목록]
```

---

### 14-3. Progressive Disclosure 계층

```
LEVEL 1 — 즉시 노출
  [기본 결과, 주요 수치, 상태 요약]

LEVEL 2 — 탭/스와이프로 노출
  [상세 정보, 보조 옵션, 히스토리]

LEVEL 3 — 전체화면 모달
  [편집, 상세 설정, 전문가 옵션]
```

---

### 14-4. 터치 접근성 기준

```
// CLAUDE.md "특이사항 > 터치 기준" 에서 확인

일반 터치 타겟:   44×44px (Apple HIG 기준)
전문직·장갑 환경: 56×56px 이상
CTA 버튼:         72dp 이상 (엄지존 하단 고정)
바텀 탭:          64dp
```

---

### 14-5. 화면 완성 전 페르소나 체크리스트

```
- [ ] 주 페르소나가 홈에서 핵심 태스크까지 탭 3회 이내 도달하는가
- [ ] 주 페르소나 기준 3초 안에 "다음에 해야 할 것"이 보이는가
- [ ] 전문 용어가 주 페르소나에게 낯설지 않은가 (또는 설명이 있는가)
- [ ] 오류 발생 시 페르소나가 스스로 복구할 수 있는가
- [ ] 터치 타겟이 페르소나 환경 기준을 충족하는가
```

