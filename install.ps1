# Claude Code Next.js Harness - PowerShell 원클릭 설치
# 실행: . .\install.ps1   OR   pwsh install.ps1
# 현재 디렉토리가 대상 프로젝트 루트여야 함.

$ErrorActionPreference = 'Stop'

# 템플릿 소스 결정 — 이 스크립트가 있는 디렉토리가 템플릿 루트
$TEMPLATE_DIR = if ($env:TEMPLATE_DIR) {
  $env:TEMPLATE_DIR
} else {
  $PSScriptRoot
}

if (-not (Test-Path (Join-Path $TEMPLATE_DIR '.claude'))) {
  Write-Host "ERROR: 템플릿을 찾을 수 없습니다: $TEMPLATE_DIR" -ForegroundColor Red
  Write-Host "해결: `$env:TEMPLATE_DIR='...'; .\install.ps1"
  exit 1
}

Write-Host "▶ Installing from: $TEMPLATE_DIR"
Write-Host "▶ Installing to:   $(Get-Location)"
Write-Host ""

# ===== 사전 체크 =====
if (-not (Test-Path 'package.json')) {
  Write-Host "⚠  package.json이 없습니다. Next.js/TS 프로젝트 루트에서 실행하세요." -ForegroundColor Yellow
  $ans = Read-Host "계속 진행하시겠습니까? [y/N]"
  if ($ans -notmatch '^[Yy]$') { exit 1 }
}

# ===== .claude 디렉토리 =====
Write-Host "▶ Copying .claude/ (기존 파일 보존)"
New-Item -ItemType Directory -Force -Path '.claude/hooks','.claude/agents','.claude/skills','.claude/commands' | Out-Null

# 훅 스크립트 복사 (기존 파일 보존)
Get-ChildItem "$TEMPLATE_DIR/.claude/hooks/*.sh" -ErrorAction SilentlyContinue | ForEach-Object {
  $dest = ".claude/hooks/$($_.Name)"
  if (-not (Test-Path $dest)) {
    Copy-Item $_.FullName $dest
  } else {
    Write-Host "  ✓ 이미 존재: $dest (건너뜀)"
  }
}

# 에이전트
Get-ChildItem "$TEMPLATE_DIR/.claude/agents/*.md" -ErrorAction SilentlyContinue | ForEach-Object {
  $dest = ".claude/agents/$($_.Name)"
  if (-not (Test-Path $dest)) { Copy-Item $_.FullName $dest }
}

# 스킬 (디렉토리 단위)
Get-ChildItem "$TEMPLATE_DIR/.claude/skills" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $dest = ".claude/skills/$($_.Name)"
  if (-not (Test-Path $dest)) {
    Copy-Item -Recurse $_.FullName $dest
  } else {
    Write-Host "  ✓ 이미 존재: $dest (건너뜀)"
  }
}

# 슬래시 커맨드
Get-ChildItem "$TEMPLATE_DIR/.claude/commands/*.md" -ErrorAction SilentlyContinue | ForEach-Object {
  $dest = ".claude/commands/$($_.Name)"
  if (-not (Test-Path $dest)) { Copy-Item $_.FullName $dest }
}

# ===== settings.json =====
$settingsDest = '.claude/settings.json'
$settingsSrc  = Join-Path $TEMPLATE_DIR '.claude/settings.json'
if (Test-Path $settingsDest) {
  Write-Host "⚠  .claude/settings.json이 이미 존재합니다." -ForegroundColor Yellow
  Write-Host "   기존 → .claude/settings.json.bak"
  Write-Host "   새 것 → .claude/settings.json.template"
  Write-Host "   수동으로 hooks 블록을 머지하세요."
  Copy-Item $settingsDest '.claude/settings.json.bak'
  Copy-Item $settingsSrc '.claude/settings.json.template'
} else {
  Copy-Item $settingsSrc $settingsDest
  Write-Host "▶ .claude/settings.json 생성"
}

# ===== AGENTS.md / CLAUDE.md =====
if (-not (Test-Path 'AGENTS.md')) {
  Copy-Item (Join-Path $TEMPLATE_DIR 'AGENTS.md') .
  Write-Host "▶ AGENTS.md 생성"
} else {
  Write-Host "  ✓ AGENTS.md 이미 존재"
}

if (-not (Test-Path 'CLAUDE.md')) {
  Copy-Item (Join-Path $TEMPLATE_DIR 'CLAUDE.md') .
  Write-Host "▶ CLAUDE.md 생성"
} else {
  $head = (Get-Content 'CLAUDE.md' -TotalCount 5 -ErrorAction SilentlyContinue) -join "`n"
  if ($head -notmatch '@AGENTS\.md') {
    Write-Host "⚠  기존 CLAUDE.md의 최상단에 '@AGENTS.md' 한 줄을 추가하세요." -ForegroundColor Yellow
  }
}

# ===== doctor.sh 배치 =====
Copy-Item (Join-Path $TEMPLATE_DIR 'doctor.sh') '.claude/hooks/' -ErrorAction SilentlyContinue

# Windows에서는 실행 권한 개념이 다르지만, Git Bash에서 읽히므로 문제 없음.
Write-Host ""
Write-Host "═══════════════════════════════════════════════"
Write-Host "✓ 설치 완료" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════"
Write-Host ""
Write-Host "다음 단계:"
Write-Host ""
Write-Host "  1. 진단 (Git Bash 필요):"
Write-Host "     & 'C:\Program Files\Git\bin\bash.exe' .claude/hooks/doctor.sh"
Write-Host ""
Write-Host "     또는 bash가 PATH에 있으면:"
Write-Host "     bash .claude/hooks/doctor.sh"
Write-Host ""
Write-Host "  2. Biome 없으면 설치:"
Write-Host "     bun add -d '@biomejs/biome'"
Write-Host ""
Write-Host "  3. Claude Code 재시작 — 훅은 세션 시작 시 로드됩니다"
Write-Host ""
Write-Host "  4. 아무 .ts 파일 수정해보세요 → 자동으로 Biome/tsc 진단이 들어옵니다"
