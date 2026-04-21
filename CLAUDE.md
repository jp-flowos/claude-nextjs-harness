@AGENTS.md

# CLAUDE.md

This file supplements AGENTS.md with Claude-specific context. Read AGENTS.md first.

<!-- Anthropic 권장: 50–120줄 유지. 더 긴 내용은 .claude/skills/<domain>/SKILL.md로. -->

## Commands

```bash
bun run dev
bun run build
bun run test
bun run test:e2e
bunx @biomejs/biome check --fix
```

## Architecture TL;DR

<!-- 1–2 문단으로 핵심 아키텍처 요약. 다이어그램 1개 허용. -->

## Authentication

<!-- 인증 패턴 1문단 + 핵심 guard 함수명 -->

## Data Access

- Server: `<getDb/getDbAdmin helper>`
- Client: DB 직접 접근 금지. API routes + React Query.

## Conventions

- Lint/Format: Biome (2-space, double quote, semicolons, 100 char)
- Path alias: `@/*` → `./src/*`
- Test co-location: `__tests__/<file>.test.ts`
- Commit messages: 영어 imperative

## Environment

<!-- 필수 env vars만 나열. 설명은 .env.example에 -->

## Available Slash Commands

<!-- /guard, /deploy 등 -->

## Related Skills

<!-- .claude/skills/ 하위 목록 -->
