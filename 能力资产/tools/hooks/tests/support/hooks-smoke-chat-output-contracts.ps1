$ErrorActionPreference = "Stop"

function New-HooksSmokeChatFixture {
  param([string]$Root)

  $samplePath = Join-Path ([System.IO.Path]::GetTempPath()) "{{APP_REPO_DIR}}-hooks-chat-sample.txt"
  $sampleHandoffName = "_hooks-smoke-chat-summary-valid.md"
  $sampleHandoffRel = "交接区/待接手/$sampleHandoffName"
  $sampleHandoffPath = Join-Path $Root ($sampleHandoffRel -replace '/', '\')

  @"
## hooks smoke handoff
① 时间
② 文件变更
③ 测试状态
④ 接手者待办
⑤ 警戒事项
- Status: HANDOFF
⑥ 追加问答
"@ | Set-Content -LiteralPath $sampleHandoffPath -Encoding UTF8

  $stateLines = Get-Content -LiteralPath (Join-Path $Root "状态.md") -Encoding UTF8
  $stateLineNumber = 0
  for ($i = $stateLines.Count - 1; $i -ge 0; $i--) {
    if ($stateLines[$i] -match '^\|\s*\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\s*\|' -and $stateLines[$i] -match 'PM') {
      $stateLineNumber = $i + 1
      break
    }
  }
  Assert-True ($stateLineNumber -gt 0) "missing PM tracking line in 状态.md"

  $card = @"
【hooks smoke 从 A 到 B】
① 时间：2026-06-13 19:40
② 文件变更：1 新建 / 1 修改（含 commit hash）
③ 测试：hooks-smoke ✅
④ 你要做：[1] 看结果
⑤ 警戒：✅
⑥ 详情：读 $sampleHandoffRel
⑦ PM 切换轨迹：本次 session 加 1 行（状态.md L$stateLineNumber）
"@
  $card | Set-Content -LiteralPath $samplePath -Encoding UTF8

  [PSCustomObject]@{
    SamplePath = $samplePath
    SampleHandoffPath = $sampleHandoffPath
    SampleHandoffRel = $sampleHandoffRel
    StateLineNumber = $stateLineNumber
    Card = $card
  }
}

function Remove-HooksSmokeChatFixture {
  param([object]$Fixture)
  if ($Fixture) {
    Remove-Item -LiteralPath $Fixture.SampleHandoffPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $Fixture.SamplePath -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-HooksSmokeChatOutputContracts {
  param(
    [string]$Root,
    [object]$Paths,
    [object]$Fixture
  )

  $Fixture.Card | Set-Content -LiteralPath $Fixture.SamplePath -Encoding UTF8
  $chatOutput = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.ChatOutput, "-TextPath", $Fixture.SamplePath)
  Assert-True ($chatOutput -match "chat-output") "chat-output bad"

  $prefacedCard = "⑦ PM 切换轨迹：这里是解释文字，不是正式交接卡段。`r`n" + $Fixture.Card
  $prefacedCard | Set-Content -LiteralPath $Fixture.SamplePath -Encoding UTF8
  $prefacedOutput = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.ChatOutput, "-TextPath", $Fixture.SamplePath)
  Assert-True ($prefacedOutput -match "chat-output") "chat-output should ignore explanatory markers before the formal card"

  $badDetail = $Fixture.Card -replace [regex]::Escape($Fixture.SampleHandoffRel), "状态.md"
  $badDetail | Set-Content -LiteralPath $Fixture.SamplePath -Encoding UTF8
  $badDetailOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ChatOutput -TextPath $Fixture.SamplePath 2>&1
  Assert-True ($LASTEXITCODE -eq 13) "chat-output should reject non-handoff detail path"

  $sideRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("{{APP_REPO_DIR}}-hooks-chat-side-" + [guid]::NewGuid().ToString("N"))
  $sidePending = Join-Path $sideRoot "交接区\待接手"
  $sideDone = Join-Path $sideRoot "交接区\已接手"
  $sideSibling = Join-Path $sideRoot "交接区\待接手-旁路"
  try {
    New-Item -ItemType Directory -Path $sidePending -Force | Out-Null
    New-Item -ItemType Directory -Path $sideDone -Force | Out-Null
    New-Item -ItemType Directory -Path $sideSibling -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $Root "状态.md") -Destination (Join-Path $sideRoot "状态.md")
    $sideCard = Join-Path $sideSibling "side.md"
    Set-Content -LiteralPath $sideCard -Encoding UTF8 -Value "# side"
    $sideText = $Fixture.Card -replace [regex]::Escape($Fixture.SampleHandoffRel), $sideCard
    $sideText | Set-Content -LiteralPath $Fixture.SamplePath -Encoding UTF8
    $sideOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ChatOutput -Root $sideRoot -TextPath $Fixture.SamplePath 2>&1
    Assert-True ($LASTEXITCODE -eq 13) "chat-output should reject absolute path in pending sibling directory"
  } finally {
    if (Test-Path -LiteralPath $sideRoot) {
      Remove-Item -LiteralPath $sideRoot -Recurse -Force
    }
  }

  Invoke-HooksSmokeAcceptedDoneChatOutputContract -Root $Root -Paths $Paths -Fixture $Fixture

  $badLine = $Fixture.Card -replace "状态\.md L$($Fixture.StateLineNumber)", "状态.md L1"
  $badLine | Set-Content -LiteralPath $Fixture.SamplePath -Encoding UTF8
  $badLineOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ChatOutput -TextPath $Fixture.SamplePath 2>&1
  Assert-True ($LASTEXITCODE -eq 18) "chat-output should reject non-PM tracking line"

  $n0Card = @"
【hooks smoke 无切帽子】
① 时间：2026-06-13 19:40
② 文件变更：0 新建 / 0 修改
③ 测试：N/A
④ 你要做：[1] 无
⑤ 警戒：✅
⑥ 详情：无
⑦ PM 切换轨迹：N=0 / 本 session 无切帽子
"@
  $n0Card | Set-Content -LiteralPath $Fixture.SamplePath -Encoding UTF8
  $n0Output = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.ChatOutput, "-TextPath", $Fixture.SamplePath)
  Assert-True ($n0Output -match "N=0") "chat-output should allow N=0 without handoff detail path"

  $Fixture.Card | Set-Content -LiteralPath $Fixture.SamplePath -Encoding UTF8
}
