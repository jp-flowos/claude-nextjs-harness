# Next.js Claude Code 하네스 템플릿

이 템플릿은 Next.js 프로젝트에 Claude Code 하네스 엔지니어링(훅·서브에이전트·스킬·보호 게이트)을 빠르게 이식하기 위한 재사용 자산이다. 신규 프로젝트, 기존 프로젝트 어디에나 적용 가능.

## 설계 철학

> 품질은 프롬프트가 아니라 메커니즘으로 강제한다.

피드백 계층의 속도 순서:
```
PostToolUse Hook (ms) > pre-commit (s) > CI (min) > human review (h)
```

빠른 계층일수록 비용 대비 효과가 크다. 반복되는 실수는 전부 훅으로 내린다.

## 포함 자산

| 경로 | 역할 |
|---|---|
| `AGENTS.md` | Next.js 공식 agent 진입점 (번들 docs 포인터) |
| `CLAUDE.md` | 프로젝트 규약 (@AGENTS.md import, 50–120줄 권장) |
| `.claude/settings.json` | 훅 + enabledPlugins |
| `.claude/hooks/post-quality.sh` | Biome auto-fix + tsc 진단 (PostToolUse) |
| `.claude/hooks/pre-protect-files.sh` | 보호 파일(.env, lockfile, config) 쓰기 차단 |
| `.claude/hooks/pre-protect-bash.sh` | 파괴적 Bash 명령 차단 (rm -rf, --force, DROP TABLE) |
| `.claude/agents/nextjs-reviewer.md` | RSC/Client 경계, Server Actions, 캐싱 리뷰어 |
| `.claude/skills/new-api-route/SKILL.md` | API 라우트 스캐폴딩 패턴 |

## 빠른 적용 (기존 프로젝트)

```bash
# 1. 프로젝트 루트로 이동
cd /path/to/your-nextjs-project

# 2. 템플릿 복사 (.claude 하위 + root files)
TEMPLATE="$HOME/.claude/templates/nextjs-harness"
cp -n "$TEMPLATE/AGENTS.md" ./
cp -rn "$TEMPLATE/.claude" ./

# 3. 훅 실행권한
chmod +x .claude/hooks/*.sh

# 4. CLAUDE.md 최상단에 @AGENTS.md import 한 줄 추가 (기존 파일 있으면 수동)
#    없으면 템플릿 복사:
#    cp -n "$TEMPLATE/CLAUDE.md" ./

# 5. Biome 없으면 설치 (bun / npm / pnpm 중 하나)
bun add -d @biomejs/biome
# npm i -D @biomejs/biome
# pnpm add -D @biomejs/biome

# 6. 훅 작동 테스트 — 아무 .ts 파일 저장
echo 'const x:number=1' > tmp.ts
bash .claude/hooks/post-quality.sh <<< '{"tool_input":{"file_path":"tmp.ts"}}'
rm tmp.ts

# 7. Claude Code 재시작 (훅은 세션 시작 시 로드)
```

## 빠른 적용 (신규 프로젝트)

```bash
# 1. Next.js canary 생성 (16.2+ 번들 docs 자동 포함)
bunx create-next-app@canary my-app
cd my-app

# 2. 템플릿 복사
TEMPLATE="$HOME/.claude/templates/nextjs-harness"
cp -rn "$TEMPLATE/.claude" ./

# 3. CLAUDE.md/AGENTS.md는 create-next-app이 이미 생성 — 템플릿 내용을 참고해 보강
#    create-next-app이 만든 AGENTS.md는 최소 버전. 템플릿의 Rules 섹션을 추가.

# 4. Biome 초기화
bunx @biomejs/biome init

# 5. 훅 실행권한 + 테스트 (위와 동일)
chmod +x .claude/hooks/*.sh
```

## 프로젝트별 커스터마이징 포인트

템플릿은 제네릭하다. 각 프로젝트에서 다음을 조정한다.

### A. AGENTS.md
- 상단 `<!-- BEGIN:nextjs-agent-rules -->` 블록은 Next.js 관리 영역 — 건드리지 말 것
- 하단에 프로젝트 고유 규칙 추가 (도메인, 불변량, 라우트 그룹)

### B. CLAUDE.md
- Anthropic 권장: 50–120줄 유지. 넘치면 `.claude/skills/*/SKILL.md`로 이전.
- "이 줄을 지우면 AI가 실수할까? 아니면 지워라."
- 포함할 것: 명령어 cheatsheet, 아키텍처 TL;DR, 비명백한 규약, 환경변수
- 제외할 것: 코드에서 추론 가능한 것, 프레임워크 기본 컨벤션, 변경 잦은 사실

### C. `.claude/hooks/pre-protect-files.sh`
기본으로 보호하는 파일: `.env*`, `tsconfig.json`, `biome.json`, `next.config.ts`, `*.lock*`, `drizzle.config.ts`, `playwright.config.ts`, `vitest.config.ts`.

프로젝트에 따라 추가:
- Prisma 쓰면 `prisma/schema.prisma`, `prisma/migrations/*`
- Terraform 쓰면 `*.tfstate`
- 이미 적용된 DB 마이그레이션 디렉토리

편집: `protected=(...)` 배열에 경로 추가.

### D. `.claude/hooks/post-quality.sh`
- 기본: Biome + tsc
- Prettier/ESLint 프로젝트: `bunx @biomejs/biome` 호출을 `npx prettier --write + npx eslint --fix`로 교체
- Deno: `deno fmt + deno lint + deno check`
- bun 대신 npm/pnpm/yarn: `bunx` → `npx` (또는 매니저 이름)

### E. 도메인 스킬 추가
`.claude/skills/<domain>/SKILL.md` 형식. 프로젝트 고유 패턴 (3rd-party API 연동, Stripe 구독, 멀티테넌시 등)을 하나씩 추가.

### F. 도메인 서브에이전트 추가
`.claude/agents/<role>.md` — 예: security-reviewer, api-contract-reviewer, migration-reviewer.

## 단계별 롤아웃 (권장)

**1일차 (30분)** — 최소 효과 최대:
1. `AGENTS.md` 생성
2. `post-quality.sh` + 설정 활성화 (파일 저장 시 Biome+tsc 자동 피드백)
3. Claude Code 재시작 → 아무 .ts 수정해보고 훅 발화 확인

**1주차**:
4. `pre-protect-files.sh` + `pre-protect-bash.sh` 활성화
5. CLAUDE.md 다이어트 (> 150줄이면 반드시)
6. `nextjs-reviewer` 서브에이전트 추가

**1달차**:
7. 도메인 스킬/에이전트 3–5개 작성
8. context7 MCP 추가 (`claude mcp add context7`)
9. Next.js 16.2+로 업그레이드 → 번들 docs 활용
10. 반복 실수가 보이면 훅으로 내린다 (CLAUDE.md에 쓰지 말고)

## 검증

훅이 실제로 발화하는지 확인:

```bash
# 테스트 파일
cat > tmp-test.ts <<'EOF'
const x:number=1;
function foo( ) { return x  }
EOF

# post-quality.sh 직접 실행
echo '{"tool_input":{"file_path":"tmp-test.ts"}}' | bash .claude/hooks/post-quality.sh
# → Biome 출력이 나오면 정상

# pre-protect-files.sh 차단 테스트
echo '{"tool_input":{"file_path":".env"}}' | bash .claude/hooks/pre-protect-files.sh
echo "exit code: $?"
# → exit code 2 가 나오면 정상

# pre-protect-bash.sh 차단 테스트
echo '{"tool_input":{"command":"rm -rf /tmp/foo"}}' | bash .claude/hooks/pre-protect-bash.sh
echo "exit code: $?"
# → "rm -rf" 패턴은 루트 계열만 잡으므로 패스 (의도된 동작)
echo '{"tool_input":{"command":"git push --force origin main"}}' | bash .claude/hooks/pre-protect-bash.sh
echo "exit code: $?"
# → exit code 2

rm -f tmp-test.ts
```

## 자주 묻는 것

**Q. Stop 훅으로 `bun run test`를 걸어도 되나?**
A. 프로젝트 테스트가 수 초 안에 끝나면 OK. 수십 초 걸리면 every-turn에 매달면 워크플로가 막힌다. 대신 `/guard` 같은 슬래시 커맨드 또는 pre-commit 훅에 두고, "완료 직전만" 실행하는 게 낫다.

**Q. 여러 프로젝트에서 훅 스크립트를 공유하려면?**
A. 두 가지 옵션:
1. 각 프로젝트에 `.claude/hooks/`를 복사 (독립성 ✓ / 업데이트 수동)
2. 훅 command를 `bash ~/.claude/hooks/post-quality.sh` 로 절대 경로로 지정 (공유 ✓ / 프로젝트 커스터마이징 ✗)

원칙적으로 1번 권장. 스크립트는 안정화된 후에 업데이트 빈도가 낮다.

**Q. Windows에서 훅이 안 도는데?**
A. `bash`가 PATH에 있어야 한다 (Git Bash, WSL, MSYS2 중 하나). PowerShell 단독 환경이면 훅을 `.ps1`로 포팅하거나 WSL 기반 Claude Code 사용.

**Q. CLAUDE.md는 CLAUDE.local.md랑 뭐가 다른가?**
A. `CLAUDE.md`는 git checkin → 팀 공유. `CLAUDE.local.md`는 gitignore → 개인 오버라이드. 개인 선호(예: 더 상세한 로깅 요청, 특정 IDE 환경)는 local에.

**Q. AGENTS.md vs CLAUDE.md 차이?**
A. AGENTS.md는 "모든 코딩 에이전트(Claude, Cursor, Copilot…)가 읽는 공통 진입점" (Next.js 16.2 공식 규약). CLAUDE.md는 Claude 전용 추가 규약. CLAUDE.md 최상단에 `@AGENTS.md`를 import하면 중복 없이 둘을 통합 가능.

## 출처

- [Claude Code Best Practices — Anthropic](https://code.claude.com/docs/en/best-practices)
- [Harness Engineering Best Practices 2026](https://nyosegawa.com/en/posts/harness-engineering-best-practices-2026/)
- [Skill Issue: Harness Engineering — HumanLayer](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
- [Next.js AI Agents Guide](https://nextjs.org/docs/app/guides/ai-agents)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)

---

Version: 1.0 (2026-04)
License: MIT
