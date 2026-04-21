#!/usr/bin/env bash
# Claude Code Next.js Harness — 진단 스크립트
# "안되네" 원인을 자동으로 찾아냄.

echo "═══════════════════════════════════════════════"
echo " Claude Code Harness Doctor"
echo "═══════════════════════════════════════════════"
echo ""

fail=0
warn=0

check() {
  local label="$1"
  local status="$2"
  local detail="${3:-}"
  case "$status" in
    OK)   printf "  ✓ %-40s %s\n" "$label" "$detail" ;;
    WARN) printf "  ⚠ %-40s %s\n" "$label" "$detail"; warn=$((warn+1)) ;;
    FAIL) printf "  ✗ %-40s %s\n" "$label" "$detail"; fail=$((fail+1)) ;;
  esac
}

# ====== 1. 필수 도구 ======
echo "[1/6] 필수 도구"
if command -v node >/dev/null 2>&1; then
  check "node" OK "$(node --version)"
else
  check "node" FAIL "훅이 JSON 파싱에 node를 사용합니다. https://nodejs.org/"
fi

if command -v bash >/dev/null 2>&1; then
  check "bash" OK "$(bash --version | head -1 | awk '{print $4}')"
else
  check "bash" FAIL "Git Bash 또는 WSL 필요 (Windows)"
fi

if command -v bunx >/dev/null 2>&1; then
  check "bunx" OK "$(bunx --version 2>/dev/null || echo '?')"
elif command -v npx >/dev/null 2>&1; then
  check "npx (bunx 대체)" OK "$(npx --version)"
else
  check "bunx/npx" FAIL "Biome/tsc 실행 불가"
fi
echo ""

# ====== 2. 프로젝트 구조 ======
echo "[2/6] 프로젝트 구조"
[ -f "package.json" ] && check "package.json" OK || check "package.json" FAIL "Next.js/TS 프로젝트 루트에서 실행하세요"
[ -f "tsconfig.json" ] && check "tsconfig.json" OK || check "tsconfig.json" WARN "tsc 훅이 동작 안 할 수 있음"
[ -f "biome.json" ] || [ -f "biome.jsonc" ] && check "biome.json" OK || check "biome.json" WARN "Biome 설정 없음 — 'bunx @biomejs/biome init' 실행"
echo ""

# ====== 3. 하네스 파일 ======
echo "[3/6] 하네스 파일"
[ -f "AGENTS.md" ] && check "AGENTS.md" OK || check "AGENTS.md" WARN "없음"
[ -f "CLAUDE.md" ] && check "CLAUDE.md" OK || check "CLAUDE.md" WARN "없음"

if [ -f "CLAUDE.md" ] && head -5 CLAUDE.md | grep -q '@AGENTS.md'; then
  check "CLAUDE.md imports AGENTS.md" OK
elif [ -f "CLAUDE.md" ] && [ -f "AGENTS.md" ]; then
  check "CLAUDE.md imports AGENTS.md" WARN "'@AGENTS.md' 한 줄을 최상단에 추가하세요"
fi

[ -d ".claude" ] && check ".claude/" OK || check ".claude/" FAIL "설치 미완료"
[ -f ".claude/settings.json" ] && check "settings.json" OK || check "settings.json" FAIL "훅이 등록 안 됨"
echo ""

# ====== 4. 훅 스크립트 ======
echo "[4/6] 훅 스크립트"
for h in pre-protect-files.sh pre-protect-bash.sh post-quality.sh; do
  if [ -f ".claude/hooks/$h" ]; then
    if [ -r ".claude/hooks/$h" ]; then
      check "$h" OK
    else
      check "$h" FAIL "읽기 권한 없음"
    fi
  else
    check "$h" FAIL "누락"
  fi
done
echo ""

# ====== 5. settings.json 유효성 + 훅 참조 ======
echo "[5/6] settings.json 검증"
if [ -f ".claude/settings.json" ] && command -v node >/dev/null 2>&1; then
  if node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'))" 2>/dev/null; then
    check "JSON 유효" OK
    pre_count=$(node -e "const c=JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'));console.log((c.hooks?.PreToolUse||[]).length)")
    post_count=$(node -e "const c=JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'));console.log((c.hooks?.PostToolUse?.[0]?.hooks||[]).length)")
    check "PreToolUse matchers" OK "$pre_count 개"
    check "PostToolUse hooks" OK "$post_count 개"
    # 참조하는 훅 파일 존재 여부
    missing=$(node -e "
      const c = JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'));
      const fs = require('fs');
      const refs = [];
      for (const group of ['PreToolUse','PostToolUse']) {
        for (const m of (c.hooks?.[group] || [])) {
          for (const h of (m.hooks || [])) {
            const match = h.command?.match(/bash\s+(\S+\.sh)/);
            if (match) refs.push(match[1]);
          }
        }
      }
      const missing = refs.filter(r => !fs.existsSync(r));
      console.log(missing.join(','));
    ")
    if [ -z "$missing" ]; then
      check "모든 훅 파일 존재" OK
    else
      check "누락된 훅 파일" FAIL "$missing"
    fi
  else
    check "JSON 유효" FAIL "파싱 에러"
  fi
fi
echo ""

# ====== 6. 라이브 파이어 테스트 ======
echo "[6/6] 라이브 파이어"
if [ -f ".claude/hooks/pre-protect-files.sh" ]; then
  out=$(printf '%s' '{"tool_input":{"file_path":".env"}}' | bash .claude/hooks/pre-protect-files.sh 2>&1 >/dev/null || true)
  if echo "$out" | grep -q BLOCKED; then
    check ".env 차단 테스트" OK
  else
    check ".env 차단 테스트" FAIL "훅이 반응 안 함"
  fi
fi

if [ -f ".claude/hooks/pre-protect-bash.sh" ]; then
  out=$(printf '%s' '{"tool_input":{"command":"git push --force origin main"}}' | bash .claude/hooks/pre-protect-bash.sh 2>&1 >/dev/null || true)
  if echo "$out" | grep -q BLOCKED; then
    check "force push 차단 테스트" OK
  else
    check "force push 차단 테스트" FAIL "훅이 반응 안 함"
  fi
fi
echo ""

# ====== 요약 ======
echo "═══════════════════════════════════════════════"
if [ "$fail" -eq 0 ] && [ "$warn" -eq 0 ]; then
  echo " ✓ 전체 통과 — Claude Code 재시작하면 활성화됩니다"
elif [ "$fail" -eq 0 ]; then
  echo " ⚠ 경고 $warn 건 (동작은 함)"
else
  echo " ✗ 실패 $fail 건 — 위 FAIL 항목을 수정하세요"
fi
echo "═══════════════════════════════════════════════"
echo ""
echo "훅이 설치됐어도 Claude Code 세션을 재시작해야 로드됩니다."
echo "현재 세션에서는 기존 훅이 계속 쓰입니다."

exit $fail
