<!-- BEGIN:nextjs-agent-rules -->

# Next.js: ALWAYS read docs before coding

Before any Next.js work, find and read the relevant doc in `node_modules/next/dist/docs/` (Next.js 16.2+) or `.next-docs/` (earlier versions). Your training data is outdated — the bundled docs are the source of truth for the installed version.

If neither path exists, run `npx @next/codemod@latest agents-md` or consult https://nextjs.org/docs.

<!-- END:nextjs-agent-rules -->

# Project — Agent Rules

<!-- 프로젝트별로 아래 섹션을 커스터마이징 -->

## Stack

<!-- 예: Next.js 16 App Router · React 19 · TypeScript 5 · Tailwind v4 · Biome · Drizzle ORM · PostgreSQL -->

## Quick Start

```bash
bun run dev       # or npm/pnpm/yarn dev
bun run build
bun run test
bunx @biomejs/biome check --fix
```

## Non-negotiable Rules

<!-- 프로젝트 고유 규칙. 훅으로 강제 가능한 건 훅에, 아닌 건 여기에. -->

1. **API routes**: authentication required on first line (hook-enforced).
2. **No DB access from Client Components**: use API routes + React Query.
3. **No `console.log` in production code**: use `logger`.
4. **No direct edits** to `.env*`, `tsconfig.json`, lockfiles, migrations (hook-enforced).
5. **Verify before "done"**: `tsc --noEmit` + tests for changed modules.

## Route Groups / Directory Map

<!-- 예:
- `(marketing)/` — public landing
- `(app)/` — authenticated app
- `(admin)/` — admin console
-->

## Where to Find Things

- DB schema: `<path>`
- Auth: `<path>`
- API routes: `<path>`
- Integrations: `<path>`

## Communication

<!-- 프로젝트별 언어/톤 규칙 -->
