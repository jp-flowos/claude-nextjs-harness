---
description: 하네스 설치 직후 AGENTS.md/CLAUDE.md를 이 프로젝트 실제 내용으로 채우기 (Plan Mode → 초안 → 승인 → 작성)
---

# /fill-project-docs

이 프로젝트의 `AGENTS.md`와 `CLAUDE.md`를 실제 내용으로 채웁니다. 하네스 설치 직후 1회 실행.

두 파일은 `jp-flowos/claude-nextjs-harness` 템플릿에서 복사된 빈 스캐폴드 상태입니다. 내용을 추론하지 말고 반드시 코드베이스를 먼저 탐색해서 사실 기반으로 채우세요.

## 실행 순서

**Plan Mode로 진입한 뒤 작업**. 바로 파일을 쓰지 말고, 탐색 → 초안 → 사용자 승인 → 작성 순서를 지킵니다.

### 1. 탐색

아래 순서로 코드베이스를 탐색하고, "비명백한" 관례 위주로 사실을 모읍니다.

- `package.json` — 프레임워크, 의존성, scripts
- `tsconfig.json`, `biome.json`/`.eslintrc*`, `next.config.*` — 설정 툴체인
- 디렉토리 구조 — `src/`, `app/`, `pages/`, `components/`, `lib/` 중 실제 사용되는 것
- 다음 질문에 답할 만큼 읽기:
  - **인증 방식**? (guard 함수명, 세션 저장, 공개 경로)
  - **DB 접근 패턴**? (ORM, helper 함수, server/client 분리)
  - **API 라우트 관례**? (첫 줄 패턴, 에러 처리, 응답 형태)
  - **라우트 그룹 구조**? (각 `(group)/`의 용도와 layout 프로바이더)
  - **환경변수**? (`.env.example` 또는 실제 참조 패턴)
  - **lint/format 툴**? (biome, eslint, prettier)
  - **테스트 러너**? (vitest, jest, playwright)
  - **특이한 프로젝트 관례**? (파일 크기 제한, 네이밍, 금지 패턴)
- 반복적으로 눈에 띄는 "비명백한" 관례 3–5개 뽑아내기 — 이게 두 문서의 핵심이 됩니다.

### 2. 채우기 규칙

#### AGENTS.md
- 최상단 `<!-- BEGIN:nextjs-agent-rules -->` ~ `<!-- END:nextjs-agent-rules -->` 블록은 Next.js 공식 영역 — **절대 수정 금지**.
- 그 아래 프로젝트 섹션만 채움:
  - **Stack**: 실제 버전 기재 (package.json 근거)
  - **Quick Start**: 실제 package.json scripts 기준 명령만
  - **Non-negotiable Rules**: 훅으로 강제되는 규칙에는 `(hook-enforced)` 라벨, 아닌 건 규칙만 간결히
  - **Route Groups / Directory Map**: 실제 존재하는 것만
  - **Where to Find Things**: 실제 경로만

#### CLAUDE.md
- 최상단 `@AGENTS.md` 한 줄 유지 (중복 금지)
- **50–120줄 안에 끝낼 것**. 넘치면 `.claude/skills/<domain>/SKILL.md`로 분리.
- **포함**: 자주 쓰는 명령 cheatsheet, 1–2 문단 아키텍처 TL;DR, 비명백한 관례, 핵심 env vars
- **제외**: 코드 읽으면 알 수 있는 것, 프레임워크 기본 컨벤션, 자주 변하는 사실, 길이 설명

### 3. 검증

각 줄에 Anthropic 공식 기준을 적용:

> "이 줄을 지우면 Claude가 실수할까? 아니면 지워라."

통과 못 하는 줄은 모두 제거. CLAUDE.md의 bloat은 중요한 규칙을 묻히게 만듭니다.

## 산출물

Plan Mode 안에서 아래를 제시:

1. **탐색 발견 요약** (bullet list) — Stack, 인증, DB, 라우트 구조 등
2. **AGENTS.md 최종 내용** (code block)
3. **CLAUDE.md 최종 내용** (code block)
4. **스킬로 분리한 내용** (있는 경우, 파일명 + 내용 요약)
5. **검증 체크**:
   - [ ] AGENTS.md의 `<!-- BEGIN:nextjs-agent-rules -->` 블록 보존
   - [ ] CLAUDE.md 최상단 `@AGENTS.md` 존재
   - [ ] CLAUDE.md 줄수 120 이하
   - [ ] Stack 버전이 package.json과 일치
   - [ ] Route Groups가 실제 디렉토리와 일치
   - [ ] 훅으로 강제되는 규칙에 `(hook-enforced)` 라벨

사용자가 OK하면 실제 파일에 작성. 사용자가 수정 요청하면 재작성 후 다시 제시.

## 규칙

- **언어**: 내용은 한국어, 코드 블록 / 명령어 / 변수명은 영어
- **존재하지 않는 것을 만들어내지 말 것**: 디렉토리, 함수, 환경변수 모두 실제 grep 결과에 근거
- **추측 금지**: 모르면 "(추가 확인 필요)"로 표기하고 사용자에게 물어볼 것
- **마케팅 문구 금지**: "강력한", "최고의" 같은 수식어는 전부 삭제
