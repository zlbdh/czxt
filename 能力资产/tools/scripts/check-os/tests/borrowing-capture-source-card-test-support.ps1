$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

$script:BorrowingGoldenClock = [DateTimeOffset]::Parse('2026-07-19T01:02:03.456Z')

function Import-BorrowingSourceCardTestModules {
  Import-BorrowingCaptureModules @('source-card', 'common')
  foreach ($name in @(
      'Get-BorrowingValidatedSourceCardSkeleton',
      'New-BorrowingSourceCardArtifactCore',
      'New-BorrowingCaptureLocalStateBytes'
    )) { Assert-BorrowingCommandExists $name }
}

function New-BorrowingGoldenRoot {
  param([string]$Name)
  $root = New-BorrowingFixtureRoot $Name project
  $path = Join-Path $root '借鉴区\模板\来源版本卡.md'
  $text = [IO.File]::ReadAllText($path)
  $text = $text.Replace('`{{PROJECT_NAME}}`', '`测试项目`')
  [IO.File]::WriteAllText($path, $text, $script:CzxtUtf8NoBom)
  return $root
}

function New-BorrowingGoldenPermissions {
  param([ValidateSet('git', 'local', 'web')][string]$SourceType)
  $map = @{
    Root = 'C:\fixture'; SourceType = $SourceType; SourceId = ('source-' + $SourceType)
  }
  if ($SourceType -eq 'local') {
    $map.LocalPath = 'C:\fixture-local'
    $map.LocalDisplayName = 'fixture-local'
  }
  elseif ($SourceType -eq 'git') {
    $map.GitLocator = 'https://example.invalid/owner/repo.git'
    $map.GitRef = 'refs/heads/main'
  }
  else {
    $map.WebRawBytesPath = 'C:\fixture-response.bin'
    $map.WebResponseMetadataPath = 'C:\fixture-response.json'
  }
  if ($SourceType -ne 'local') {
    $map.AccessPolicy = 'source-read-only'
    $map.NetworkPolicy = 'source-read-only'
    $map.AuthorizationTime = '2026-07-19T09:00:00+08:00'
    $map.AuthorizationSource = 'approved-fixture'
    $map.AuthorizationScope = 'current-capture'
  }
  return Resolve-BorrowingCaptureRequest -BoundParameters $map
}

function Assert-BorrowingSourceCardGolden {
  param([string]$ExpectedText, [string]$ExpectedSha256, $Candidate, [string]$Name)
  $root = New-BorrowingGoldenRoot ('golden-' + $Name)
  $skeleton = Get-BorrowingValidatedSourceCardSkeleton -Root $root
  $permissions = New-BorrowingGoldenPermissions $Candidate.SourceType
  $artifact = New-BorrowingSourceCardArtifactCore -Skeleton $skeleton `
    -Candidate $Candidate -Permissions $permissions -UtcNow $script:BorrowingGoldenClock
  $expectedTextWithLf = $ExpectedText.Replace("`r`n", "`n").TrimStart("`n").TrimEnd("`n") + "`n"
  $expectedBytes = [Text.Encoding]::UTF8.GetBytes($expectedTextWithLf)
  Assert-CzxtEqual ([Convert]::ToBase64String($expectedBytes)) `
    ([Convert]::ToBase64String($artifact.Bytes)) ($Name + ' golden bytes')
  Assert-CzxtEqual $ExpectedSha256 (Get-BorrowingSha256Hex -Bytes $artifact.Bytes) `
    ($Name + ' golden SHA-256')
  Assert-CzxtTrue (-not (Test-CzxtUtf8Bom (Join-Path $root '借鉴区\模板\来源版本卡.md'))) `
    ($Name + ' skeleton fixture BOM')
  return $artifact
}
