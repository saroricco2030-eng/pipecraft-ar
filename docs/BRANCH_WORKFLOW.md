# Branch Workflow — Fix Propagation Guard

> **포터블 규칙서.** 이 문서는 어떤 git 프로젝트에도 그대로 복사해 쓸 수 있다. Flutter/Next.js/Python 등 언어 무관.
>
> **해결하는 문제**: 브랜치 A 에서 수정한 버그가 main 에 반영되지 않음 → 새 브랜치를 main 에서 fork 할 때마다 같은 버그 상속.
>
> **다루지 않는 것**: 일반적인 GitFlow, CI/CD 구성 — 그건 별개 문서.

---

## 1. 골드 룰

1. **모든 `[fix]` 커밋은 1주일 내 main 에 병합되어야 한다.**
2. **`[fix]` 커밋을 포함한 브랜치는 폐기 전 반드시 main 으로 PR 생성.**
3. **새 worktree / branch 를 시작할 때 `main` 이 최신인지 먼저 확인한다.**

이 3개만 지켜도 "수정했는데 다시 생김" 상황은 영구 제거됨.

## 2. 커밋 네이밍 규약 (포터블)

```
[type] 짧은 설명 (50자 이내)

자세한 설명 (선택)

Co-Authored-By: 본인 <email>
```

**type** (이 스캐너가 인식하는 값):
- `fix` — 버그 수정. **반드시 main 반영 대상**.
- `feat` — 새 기능. PR 경로 일반.
- `design` — UI/디자인.
- `refactor` — 구조 정리.
- `docs`, `chore`, `test` — main 반영 우선순위 낮음.

⚠️ 스캐너는 `[type]` 형식으로 파싱한다. `feat:` `fix:` 같은 Conventional Commits 도 별도 옵션으로 지원.

## 3. 자동 감지 스캐너

`tools/scan-orphan-fixes.sh` — git 만 있으면 어떤 환경에서도 동작.

### 로컬 사용
```bash
./tools/scan-orphan-fixes.sh
# Output:
#   claude/magical-edison: 3 orphan fix commits
#     89919c4 [fix] Quiz overlap regression
#     ffcb4e9 [fix] Quiz retry/next buttons overlap
#     cf90086 [fix] Quiz explanation overlay transparency
```

### CI 주간 스캔
`.github/workflows/orphan-fix-weekly-scan.yml` 이 매주 월요일 09:00 UTC 에 실행 → orphan 발견 시 자동으로 이슈 생성 (Slack/Discord webhook 연결도 가능).

### 판정 기준
- **main 에 없는 `[fix]` 커밋이 있는 브랜치** = orphan
- 주 단위 집계 후 카운트 ≥ 3 이면 알림 강화

## 4. 표준 워크플로우 (다이어그램)

```
┌────────────────────────────────────────────────────────────┐
│  SHORT-LIVED FIX BRANCH (권장 경로)                         │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  1.  git checkout -b fix/quiz-overlap main                 │
│  2.  ... 수정 ...                                           │
│  3.  git commit -m "[fix] Quiz overlap"                    │
│  4.  git push origin fix/quiz-overlap                      │
│  5.  gh pr create --base main --fill                       │
│  6.  gh pr merge --squash --auto                           │
│  7.  브랜치 자동 삭제 (GitHub 설정)                          │
│                                                            │
│  결과: main 에 즉시 반영, 브랜치 수명 <1일                   │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│  LONG-LIVED WORKTREE (작업 분리 필요 시)                    │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  1.  git worktree add .claude/worktrees/feat-x main        │
│  2.  브랜치 `claude/feat-x` 에서 작업                        │
│  3.  [fix] 커밋 하나라도 들어가면 ⚠️ 즉시 main 에도 반영:    │
│                                                            │
│       옵션 A (cherry-pick):                                │
│         git checkout main && git cherry-pick <SHA>         │
│                                                            │
│       옵션 B (PR 일부만):                                   │
│         gh pr create --base main --head claude/feat-x \    │
│           --title "Backport [fix] commits only"            │
│                                                            │
│  4.  최종적으로 브랜치 전체를 main 에 merge 하거나 폐기      │
│                                                            │
│  주의: 브랜치 폐기 전 scan-orphan-fixes.sh 필수 실행         │
└────────────────────────────────────────────────────────────┘
```

## 5. Pre-push Hook (옵션)

`.githooks/pre-push` — 로컬에서 `[fix]` 커밋을 non-main 브랜치에 푸시하려 할 때 경고.

설치:
```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-push   # Unix
```

Windows (git-bash): 동일.

이 훅은 차단하지 않고 **경고만** 한다. 의도적 장기 브랜치 작업을 막으면 생산성 해친다.

## 6. 신규 worktree 시작 전 체크리스트

```bash
# 1. main 최신화
git fetch origin
git checkout main
git pull --ff-only

# 2. orphan 스캔 (옵션이지만 강력 권장)
./tools/scan-orphan-fixes.sh

# 3. 새 worktree 생성
git worktree add .claude/worktrees/<name> -b claude/<name> main

# 4. 작업 시작
```

**왜 중요한가**: main 이 stale 이면 새 worktree 는 구식 main 을 상속. 이미 다른 브랜치에서 수정된 버그를 다시 만남.

## 7. 관리 자동화 레벨

| 레벨 | 도구 | 효과 |
|---|---|---|
| 🟢 L1 — 수동 | 본 문서 규칙 숙지 | 기본 |
| 🟡 L2 — 세미자동 | scan-orphan-fixes.sh 수동 실행 | 인지 강화 |
| 🟠 L3 — 주간 | CI scheduled scan + issue 자동 생성 | 놓치지 않음 |
| 🔴 L4 — 실시간 | pre-push hook + push 시 auto-PR 생성 | 누락 불가능 |

권장: L3 먼저 도입 → 3개월 운영 후 noise 없으면 L4 로.

## 8. 상태 점검 (지금 이 리포에서 실행)

```bash
# 모든 원격 branch 의 orphan 개수
git fetch --all
for br in $(git branch -r | grep -v HEAD); do
  count=$(git log --oneline "$br" ^origin/main 2>/dev/null | grep -cE "^\w+ \[fix\]")
  [ "$count" -gt 0 ] && echo "$br: $count orphan fix commits"
done
```

## 9. 다른 프로젝트에 이식

> **전제**: 소스 리포 `saroricco2030-eng/HVAC-R-Pulse` 는 현재 **비공개**.
> 공개 전환 시 맨 아래 "curl 방식" 이 자동 활성화됨. 그 전까지는 아래 두 방법 중 택1.

### 🟢 방법 1 — 로컬 경로 (솔로 dev, 가장 간단)

HVAC-R Pulse 가 이미 로컬에 클론되어 있음:
```bash
# 소스를 먼저 최신화
cd "C:/Users/saror/Desktop/HVAC-R Pulse"
git checkout main && git pull

# 타겟 프로젝트로 이동
cd /path/to/your-other-project

# 설치 (Windows git-bash, macOS, Linux 공용)
bash "C:/Users/saror/Desktop/HVAC-R Pulse/tools/install-branch-guard.sh" \
     --from-local="C:/Users/saror/Desktop/HVAC-R Pulse"
```

### 🟢 방법 2 — `gh` CLI (비공개 리포 + 인증된 계정)

```bash
gh api "repos/saroricco2030-eng/HVAC-R-Pulse/contents/tools/install-branch-guard.sh" \
  --jq .content | base64 -d | bash -s -- --dry-run
```

⚠ 위 방법은 installer 만 가져오고, installer 가 내부적으로 다시 `git clone` 을 시도함 → 비공개 리포라면 clone 도 실패. **방법 1 (--from-local) 이 근본 해결책.**

### 내부 처리 (양쪽 공통)

- 5개 파일 복사 (`docs/BRANCH_WORKFLOW.md`, `tools/scan-orphan-fixes.sh`, `.github/workflows/orphan-fix-weekly-scan.yml`, `.githooks/pre-push`, `.orphan-fix-ignore`)
- 기존 파일 있으면 `*.bak` 으로 자동 백업
- `git config core.hooksPath .githooks` 활성화
- `gh` 있으면 `orphan-fix` 라벨 자동 생성
- 마지막에 스캐너 smoke-test 실행해서 orphan 현황 즉시 보고

### 사전 확인 (dry-run)

변경 없이 어떤 파일이 설치될지 미리보기:
```bash
bash "/path/to/install-branch-guard.sh" --from-local=/path/to/HVAC-R-Pulse --dry-run
```

### 🔵 방법 3 — curl (리포 공개 전환 후)

소스 리포를 public 으로 전환하면:
```bash
curl -sSL https://raw.githubusercontent.com/saroricco2030-eng/HVAC-R-Pulse/main/tools/install-branch-guard.sh | bash
```

### 옵션

```bash
BRANCH_GUARD_SOURCE=<url>  # 포크 사용 시 URL 오버라이드
BRANCH_GUARD_REF=<ref>     # main 이외 branch/tag
MAIN_BRANCH=master         # 타겟 리포의 기본 branch 이름
SKIP_HOOK=1                # pre-push 훅 활성화 건너뛰기
SKIP_LABEL=1               # gh label create 건너뛰기
```

### 프로젝트별 이상치

- Monorepo: 스캐너에 `MAIN_BRANCH=develop` 같은 환경변수로 베이스 전환 가능
- Conventional Commits (`fix:` 형식): 스캐너가 기본적으로 지원 (regex 에 포함)
- Slack/Discord 이슈 알림: GitHub 리포 설정에서 issue webhook 추가 (스캐너 외부 관심사)

### 수동 복사 (최소 파일만)

```
docs/BRANCH_WORKFLOW.md
tools/scan-orphan-fixes.sh
.github/workflows/orphan-fix-weekly-scan.yml
.githooks/pre-push (optional)
.orphan-fix-ignore (starter)
```

그 후:
1. `git config core.hooksPath .githooks`
2. `gh label create orphan-fix --color FF6B00`
3. 커밋 + push

## 10. FAQ

**Q. 이 규칙이 작은 수정까지 강제하나?**  
A. `[fix]` 로 태깅된 커밋만. `[chore]` `[docs]` `[test]` 는 자유. 실수로 `[fix]` 를 남용하지 않는 것이 관건.

**Q. 대형 리팩토링 PR 에 `[fix]` 가 섞여있으면?**  
A. 리팩토링은 `[refactor]` 태그. 안에 포함된 개별 수정들은 main 에 선제 cherry-pick 하는 것이 안전.

**Q. Emergency hotfix 는?**  
A. `hotfix/*` 브랜치 네이밍 사용 + main 에 직접 PR + fast-track merge. 스캐너는 hotfix/* 도 감지한다.

**Q. private 브랜치의 WIP fix 가 main 에 가면 안 되는데?**  
A. 커밋 제목을 `[wip]` 로 시작. 스캐너는 `[wip]` 를 필터링. 준비되면 rebase 로 `[fix]` 로 변경.

---

*Last updated: 2026-04-19. 원본: HVAC-R Pulse 프로젝트 "claude/magical-edison 에서 fix 되었으나 main 미반영으로 반복 재발" 사건 post-mortem.*
