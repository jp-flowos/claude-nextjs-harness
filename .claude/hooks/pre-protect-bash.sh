#!/usr/bin/env bash
# PreToolUse — block destructive Bash commands.
# Uses node for JSON parsing (jq-free).
#
# Patterns require executable context (e.g. --no-verify only blocks inside `git` commands),
# so echo'd / commented instances of these strings do not trigger false positives.

set -euo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const j=JSON.parse(d);process.stdout.write(j.tool_input?.command||'')}catch(e){}})" 2>/dev/null || true)"

[ -z "$cmd" ] && exit 0

# Strip quoted string literals to avoid false positives on echo'd payloads.
stripped="$(printf '%s' "$cmd" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")"

# Self-contained destructive patterns — only root / system dirs / HOME / bare wildcards.
destructive_patterns=(
  'rm[[:space:]]+-rf?[[:space:]]+/([[:space:]]|$|\*|\.\.)'
  'rm[[:space:]]+-rf?[[:space:]]+/(bin|etc|usr|var|lib|sbin|boot|sys|proc|dev|root|home|Users|Windows)([/[:space:]]|$)'
  'rm[[:space:]]+-rf?[[:space:]]+\$HOME'
  'rm[[:space:]]+-rf?[[:space:]]+~/?([[:space:]]|$)'
  'rm[[:space:]]+-rf?[[:space:]]+\*([[:space:]]|$)'
  'sudo[[:space:]]+'
  'chmod[[:space:]]+777'
  ':\(\)\s*\{.*:\|:'
)

for p in "${destructive_patterns[@]}"; do
  if echo "$stripped" | grep -qiE -- "$p"; then
    echo "[BLOCKED] 파괴 명령어 감지: $p" >&2
    echo "명령어: $cmd" >&2
    exit 2
  fi
done

# Git-specific dangerous patterns — only when `git` is present
if echo "$stripped" | grep -qE 'git[[:space:]]'; then
  git_dangerous=(
    'git[[:space:]]+push[[:space:]]+.*(--force|-f[[:space:]]|-f$)'
    'git[[:space:]]+push[[:space:]]+.*\+[a-zA-Z]'
    'git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+origin'
    'git[[:space:]]+(commit|rebase|cherry-pick|merge|revert).*--no-verify'
    'git[[:space:]]+(commit|rebase|cherry-pick|merge|revert|tag).*--no-gpg-sign'
    'git[[:space:]]+branch[[:space:]]+-D'
    'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f'
  )
  for p in "${git_dangerous[@]}"; do
    if echo "$stripped" | grep -qiE -- "$p"; then
      echo "[BLOCKED] 위험한 git 명령어: $p" >&2
      echo "명령어: $cmd" >&2
      exit 2
    fi
  done
fi

# SQL destructive — check against the ORIGINAL cmd (SQL is inside quotes for psql -c).
if echo "$stripped" | grep -qiE '(psql|mysql|sqlite3?|pg_[a-z]+|duckdb)[[:space:]]'; then
  sql_dangerous=(
    'DROP[[:space:]]+(TABLE|DATABASE|SCHEMA|INDEX)'
    'TRUNCATE[[:space:]]+TABLE'
    'DELETE[[:space:]]+FROM[[:space:]]+[a-zA-Z_]+[[:space:]]*(;|$|--)'
  )
  for p in "${sql_dangerous[@]}"; do
    if echo "$cmd" | grep -qiE -- "$p"; then
      echo "[BLOCKED] 파괴적 SQL: $p" >&2
      echo "명령어: $cmd" >&2
      exit 2
    fi
  done
fi

# Warnings
if echo "$stripped" | grep -qE 'git[[:space:]]+add[[:space:]]+(-A|--all|\.|\*)[[:space:]]*$'; then
  echo "[WARN] 'git add -A/./.' 는 민감 파일을 포함할 수 있습니다. 특정 파일을 지정하세요." >&2
fi

exit 0
