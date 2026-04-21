#!/usr/bin/env bash
# PostToolUse quality hook — Biome auto-fix + tsc diagnostics.
# Uses node for JSON parsing (jq-free, portable).
#
# Project customization:
# - Replace Biome with Prettier+ESLint: see README FAQ
# - Replace bun with npm/pnpm/yarn: swap `bunx` → `npx`

set -euo pipefail

input="$(cat)"

# Extract file_path via node (node is always available in Next.js projects)
file="$(printf '%s' "$input" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const j=JSON.parse(d);process.stdout.write(j.tool_input?.file_path||'')}catch(e){}})" 2>/dev/null || true)"

case "$file" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac

[ ! -f "$file" ] && exit 0

export PATH="$HOME/.bun/bin:$PATH"

runner=""
if command -v bunx >/dev/null 2>&1; then
  runner="bunx"
elif command -v npx >/dev/null 2>&1; then
  runner="npx --yes"
else
  exit 0
fi

# Phase 1: silent auto-fix
$runner @biomejs/biome check --write --no-errors-on-unmatched "$file" >/dev/null 2>&1 || true

# Phase 2: collect diagnostics
biome_diag="$($runner @biomejs/biome check --no-errors-on-unmatched "$file" 2>&1 | head -30 || true)"
tsc_diag=""
if [ -f "tsconfig.json" ]; then
  tsc_diag="$(timeout 10s $runner tsc --noEmit --incremental --tsBuildInfoFile .claude/.tsbuildinfo 2>&1 | grep -F "$file" | head -10 || true)"
fi

combined=""
if [ -n "$biome_diag" ] && ! echo "$biome_diag" | grep -qiE "no (issues|problems|errors)"; then
  combined="=== Biome ===\n${biome_diag}\n"
fi
if [ -n "$tsc_diag" ]; then
  combined="${combined}=== TypeScript ===\n${tsc_diag}\n"
fi

if [ -n "$combined" ]; then
  printf '%s' "$combined" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{process.stdout.write(JSON.stringify({hookSpecificOutput:{hookEventName:'PostToolUse',additionalContext:d}}))})"
fi

exit 0
