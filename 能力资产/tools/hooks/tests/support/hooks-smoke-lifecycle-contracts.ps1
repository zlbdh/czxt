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
    Invoke-HooksSmokeClaudeContracts -Root $Root -Paths $Paths
    Invoke-HooksSmokeP4bTouchContracts -Root $Root -Paths $Paths
  } finally {
    Remove-HooksSmokeChatFixture -Fixture $fixture
  }
}
