$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeLifecycleContracts {
  param(
    [string]$Root,
    [object]$Paths
  )

  $fixture = New-HooksSmokeChatFixture -Root $Root
  try {
    Invoke-HooksSmokeChatOutputContracts -Root $Root -Paths $Paths -Fixture $fixture
    Invoke-HooksSmokeCodexContracts -Root $Root -Paths $Paths -Fixture $fixture
    $claudeTempRoot = [System.IO.Path]::GetTempPath()
    $claudeFixtureRoot = Join-Path $claudeTempRoot ("{{APP_REPO_DIR}}-hooks-claude-pm-target-" + [guid]::NewGuid().ToString("N"))
    $claudeConcurrentSentinel = Join-Path $claudeTempRoot ("{{APP_REPO_DIR}}-hooks-claude-pm-concurrent-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $claudeConcurrentSentinel | Out-Null
    try {
      Invoke-HooksSmokeClaudeContracts -Root $Root -Paths $Paths -TempRoot $claudeFixtureRoot
      Assert-True (-not (Test-Path -LiteralPath $claudeFixtureRoot)) "Claude contracts left the owned temp root: $claudeFixtureRoot"
      Assert-True (Test-Path -LiteralPath $claudeConcurrentSentinel) "Claude lifecycle cleanup deleted a concurrent same-prefix temp sentinel"
    } finally {
      foreach ($ownedPath in @($claudeFixtureRoot, $claudeConcurrentSentinel)) {
        if (Test-Path -LiteralPath $ownedPath) {
          Remove-Item -LiteralPath $ownedPath -Recurse -Force
        }
      }
    }
    Invoke-HooksSmokeClaudePathGateContracts -Root $Root -Paths $Paths
    Invoke-HooksSmokeP4bTouchContracts -Root $Root -Paths $Paths
  } finally {
    Remove-HooksSmokeChatFixture -Fixture $fixture
  }
}
