param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

# 发布前门禁（PROP-038 Layer 4 / zlbdh approve 2026-06-14）
# push 前强制 vitest run + vite build 全过；任一失败 → exit 1 阻止 push。
# trigger：pre-push（git push 时自动）+ manual（随时手动跑）。
# 注意 1：用 `npm test`(=vitest run 非 watch) + `npm run build`，不会挂死。
# 注意 2：必须走 `cmd /c "npm ..."` 而非 `& npm ...` —— 本机 `npm` 解析到 npm.ps1 shim，
#         `& npm <subcmd>` 会把参数解析错（npm 收到 "pm" → Unknown command）。cmd /c 走 npm.cmd 标准路径。

$ErrorActionPreference = "Stop"
$frameworkScope = Join-Path $PSScriptRoot "check-os\framework-scope.ps1"
if (Test-Path -LiteralPath $frameworkScope -PathType Leaf) {
  . $frameworkScope
}

$repo = Join-Path $Root "{{APP_REPO_DIR}}"
if (-not (Test-Path -LiteralPath (Join-Path $repo "package.json"))) {
  if ((Get-Command Test-IsTemplateRoot -ErrorAction SilentlyContinue) -and (Test-IsTemplateRoot -Root $Root)) {
    Write-Host "  🟡 模板根未实例化 {{APP_REPO_DIR}}，跳过业务发布门禁" -ForegroundColor Yellow
    exit 5
  }
  Write-Host "  🔴 {{APP_REPO_DIR}}/package.json 不存在 — 发布门禁无法确认仓库，fail-closed" -ForegroundColor Red
  exit 1
}

Push-Location $repo
try {
  Write-Host "  ▶ 发布门禁 1/2：npm test（vitest run）..." -ForegroundColor Cyan
  cmd /c "npm test"
  $testCode = $LASTEXITCODE
  if ($testCode -ne 0) {
    Write-Host "  🔴 发布门禁失败：vitest 未全过（exit $testCode）— 修测试后再 push" -ForegroundColor Red
    exit 1
  }
  Write-Host "  ▶ 发布门禁 2/2：npm run build（vite build）..." -ForegroundColor Cyan
  cmd /c "npm run build"
  $buildCode = $LASTEXITCODE
  if ($buildCode -ne 0) {
    Write-Host "  🔴 发布门禁失败：vite build 出错（exit $buildCode）— 修构建后再 push" -ForegroundColor Red
    exit 1
  }
  Write-Host "  ✅ 发布门禁：vitest run + vite build 全过，放行 push" -ForegroundColor Green
  exit 0
} finally {
  Pop-Location
}
