#!/usr/bin/env bash
# Claude Code Next.js Harness — 원클릭 설치 스크립트
# 실행: bash install.sh  (또는 curl -fsSL <raw-url> | bash)
# 현재 디렉토리가 대상 프로젝트 루트여야 함.

set -euo pipefail

# ====== 설정 ======
TEMPLATE_DIR="${TEMPLATE_DIR:-$HOME/.claude/templates/nextjs-harness}"
# degit 경유로 직접 다운로드한 경우, install.sh 자신이 있는 디렉토리를 템플릿 소스로
if [ ! -d "$TEMPLATE_DIR" ] && [ -d "$(dirname "${BASH_SOURCE[0]}")/.claude" ]; then
  TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ ! -d "$TEMPLATE_DIR/.claude" ]; then
  echo "ERROR: 템플릿을 찾을 수 없습니다: $TEMPLATE_DIR"
  echo "해결: TEMPLATE_DIR=/path/to/template bash install.sh"
  exit 1
fi

echo "▶ Installing from: $TEMPLATE_DIR"
echo "▶ Installing to:   $(pwd)"
echo ""

# ====== 사전 체크 ======
if [ ! -f "package.json" ]; then
  echo "⚠  package.json이 없습니다. Next.js (또는 TS) 프로젝트 루트에서 실행하세요."
  read -rp "계속 진행하시겠습니까? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || exit 1
fi

# ====== .claude 복사 (기존 파일 보존) ======
echo "▶ Copying .claude/ (preserves existing files)"
mkdir -p .claude/hooks .claude/agents .claude/skills
cp -n "$TEMPLATE_DIR/.claude/hooks/"*.sh .claude/hooks/ 2>/dev/null || true
cp -n "$TEMPLATE_DIR/.claude/agents/"*.md .claude/agents/ 2>/dev/null || true
cp -rn "$TEMPLATE_DIR/.claude/skills/"* .claude/skills/ 2>/dev/null || true

# ====== settings.json 처리 ======
if [ -f ".claude/settings.json" ]; then
  echo "⚠  .claude/settings.json이 이미 존재합니다."
  echo "   기존 설정 → .claude/settings.json.bak 으로 백업"
  echo "   템플릿 설정 → .claude/settings.json.template 으로 저장"
  echo "   수동으로 hooks 블록을 머지하세요."
  cp .claude/settings.json .claude/settings.json.bak
  cp "$TEMPLATE_DIR/.claude/settings.json" .claude/settings.json.template
else
  cp "$TEMPLATE_DIR/.claude/settings.json" .claude/settings.json
  echo "▶ .claude/settings.json 생성"
fi

# ====== AGENTS.md / CLAUDE.md ======
if [ ! -f "AGENTS.md" ]; then
  cp "$TEMPLATE_DIR/AGENTS.md" ./
  echo "▶ AGENTS.md 생성 (프로젝트별 내용은 직접 채워넣으세요)"
else
  echo "✓ AGENTS.md 이미 존재 — 건너뜀"
fi

if [ ! -f "CLAUDE.md" ]; then
  cp "$TEMPLATE_DIR/CLAUDE.md" ./
  echo "▶ CLAUDE.md 생성 (프로젝트별 내용은 직접 채워넣으세요)"
else
  if ! head -5 CLAUDE.md | grep -q '@AGENTS.md'; then
    echo "⚠  기존 CLAUDE.md 발견 — 최상단에 '@AGENTS.md' 한 줄을 직접 추가하세요."
  fi
fi

# ====== 실행 권한 (Unix) ======
chmod +x .claude/hooks/*.sh 2>/dev/null || true

# ====== doctor.sh 복사 ======
cp "$TEMPLATE_DIR/doctor.sh" .claude/hooks/ 2>/dev/null || true
chmod +x .claude/hooks/doctor.sh 2>/dev/null || true

echo ""
echo "═══════════════════════════════════════════════"
echo "✓ 설치 완료"
echo "═══════════════════════════════════════════════"
echo ""
echo "다음 단계:"
echo ""
echo "  1. 진단 실행:"
echo "     bash .claude/hooks/doctor.sh"
echo ""
echo "  2. Biome 없으면 설치:"
echo "     bun add -d @biomejs/biome   # or npm i -D"
echo ""
echo "  3. Claude Code를 재시작하세요"
echo "     (훅은 세션 시작 시 로드됩니다)"
echo ""
echo "  4. 테스트:"
echo "     아무 .ts 파일을 수정해보세요 → Biome/tsc 진단이 자동으로 들어옵니다"
echo ""
echo "문제 있으면 doctor.sh 출력을 확인하세요."
