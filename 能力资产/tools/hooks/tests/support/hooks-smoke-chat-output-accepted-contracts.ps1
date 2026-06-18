$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeAcceptedDoneChatOutputContract {
  param(
    [string]$Root,
    [object]$Paths,
    [object]$Fixture
  )

  $sideRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("{{APP_REPO_DIR}}-hooks-chat-accepted-" + [guid]::NewGuid().ToString("N"))
  $pendingDir = Join-Path $sideRoot "交接区\待接手"
  $doneDir = Join-Path $sideRoot "交接区\已接手"
  try {
    New-Item -ItemType Directory -Path $pendingDir, $doneDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $Root "状态.md") -Destination (Join-Path $sideRoot "状态.md")
    $detailRel = "交接区/已接手/_hooks-smoke-chat-summary-accepted.md"
    $detailPath = Join-Path $sideRoot ($detailRel -replace '/', '\')
    Set-Content -LiteralPath $detailPath -Encoding UTF8 -Value "---`nstatus: accepted`n---`n# accepted"
    ($Fixture.Card -replace [regex]::Escape($Fixture.SampleHandoffRel), $detailRel) |
      Set-Content -LiteralPath $Fixture.SamplePath -Encoding UTF8

    $ok = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.ChatOutput, "-Root", $sideRoot, "-TextPath", $Fixture.SamplePath)
    Assert-True ($ok -match "chat-output") "accepted done card should pass when pending is empty"

    Set-Content -LiteralPath (Join-Path $pendingDir "still-pending.md") -Encoding UTF8 -Value "# pending"
    $blocked = powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ChatOutput -Root $sideRoot -TextPath $Fixture.SamplePath 2>&1
    Assert-True ($LASTEXITCODE -eq 13) "accepted done card should fail when pending exists"
  } finally {
    if (Test-Path -LiteralPath $sideRoot) {
      Remove-Item -LiteralPath $sideRoot -Recurse -Force
    }
  }
}
