#!/usr/bin/env bash
# PreToolUse — block writes to protected config/lock/migration files.
# Uses node for JSON parsing (jq-free).
#
# Project customization: edit the `protected` array below.

set -euo pipefail

input="$(cat)"
file="$(printf '%s' "$input" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const j=JSON.parse(d);process.stdout.write(j.tool_input?.file_path||'')}catch(e){}})" 2>/dev/null || true)"

[ -z "$file" ] && exit 0

protected=(
  "tsconfig.json"
  "biome.json"
  "next.config.ts"
  "next.config.js"
  "next.config.mjs"
  "drizzle.config.ts"
  "prisma/schema.prisma"
  "playwright.config.ts"
  "vitest.config.ts"
  "postcss.config.js"
  "postcss.config.mjs"
  "tailwind.config.ts"
  "bun.lockb"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
)

if echo "$file" | grep -qE '(^|/)\.env(\..+)?$'; then
  echo "[BLOCKED] .env 파일 직접 수정 금지" >&2
  echo "FIX: 시크릿은 Vercel dashboard / AWS Secrets Manager / 1Password에서 관리" >&2
  exit 2
fi

if echo "$file" | grep -qE '(supabase/migrations|prisma/migrations|db/migrations)/.+\.(sql|ts|js)$'; then
  echo "[BLOCKED] 적용된 마이그레이션 수정 금지" >&2
  echo "FIX: 새 마이그레이션 파일 추가" >&2
  exit 2
fi

for p in "${protected[@]}"; do
  if echo "$file" | grep -qE "(^|/)${p}$"; then
    echo "[BLOCKED] $p 은 보호 파일입니다" >&2
    echo "FIX: 설정이 아니라 코드를 고치세요." >&2
    exit 2
  fi
done

exit 0
