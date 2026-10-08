param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

# Pre-release gate (PROP-038 Layer 4 / zlbdh approved 2026-06-14)
# Require successful vitest run + vite build before push; any failure → exit 1 blocks push.
# Trigger: pre-push (automatically on git push) + manual (run at any time).
# Note 1: use `npm test` (=vitest run, not watch) + `npm run build` so execution terminates.
# Note 2: use `cmd /c "npm ..."`, not `& npm ...`: local `npm` resolves to the npm.ps1 shim,
#         where `& npm <subcmd>` misparses arguments (npm receives "pm" → Unknown command). cmd /c uses the standard npm.cmd path.

$ErrorActionPreference = "Stop"
$frameworkScope = Join-Path $PSScriptRoot "check-os\framework-scope.ps1"
if (Test-Path -LiteralPath $frameworkScope -PathType Leaf) {
  . $frameworkScope
}

$repo = Join-Path $Root "{{APP_REPO_DIR}}"
if (-not (Test-Path -LiteralPath (Join-Path $repo "package.json"))) {
  if ((Get-Command Test-IsTemplateRoot -ErrorAction SilentlyContinue) -and (Test-IsTemplateRoot -Root $Root)) {
    Write-Host "  🟡 Template root has no instantiated {{APP_REPO_DIR}}; skipping the business release gate" -ForegroundColor Yellow
    exit 5
  }
  Write-Host "  🔴 {{APP_REPO_DIR}}/package.json is missing — release gate cannot verify the repository; fail-closed" -ForegroundColor Red
  exit 1
}

Push-Location $repo
try {
  Write-Host "  ▶ Release gate 1/2: npm test (vitest run)..." -ForegroundColor Cyan
  cmd /c "npm test"
  $testCode = $LASTEXITCODE
  if ($testCode -ne 0) {
    Write-Host "  🔴 Release gate failed: vitest did not fully pass (exit $testCode) — fix tests before pushing" -ForegroundColor Red
    exit 1
  }
  Write-Host "  ▶ Release gate 2/2: npm run build (vite build)..." -ForegroundColor Cyan
  cmd /c "npm run build"
  $buildCode = $LASTEXITCODE
  if ($buildCode -ne 0) {
    Write-Host "  🔴 Release gate failed: vite build error (exit $buildCode) — fix the build before pushing" -ForegroundColor Red
    exit 1
  }
  Write-Host "  ✅ Release gate: vitest run + vite build both passed; push permitted" -ForegroundColor Green
  exit 0
} finally {
  Pop-Location
}
