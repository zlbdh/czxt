[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-web-test-support.ps1')

function Initialize-BorrowingFacadeProjectSkeleton {
  param([string]$Root)
  $path = Join-Path $Root '借鉴区\模板\来源版本卡.md'
  $text = [IO.File]::ReadAllText($path)
  $text = $text.Replace('`{{PROJECT_NAME}}`', '`集成测试项目`')
  [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding($false)))
}

function Get-BorrowingFacadeLocalArguments {
  param([string]$Root, [string]$Source)
  return @(
    '-Root', $Root, '-SourceType', 'Local', '-SourceId', 'local-fixture',
    '-LocalPath', $Source, '-LocalDisplayName', 'local-fixture'
  )
}

function Get-BorrowingFacadeWebArguments {
  param([string]$Root, [string]$RawPath, [string]$MetadataPath)
  return @(
    '-Root', $Root, '-SourceType', 'Web', '-SourceId', 'web-fixture',
    '-WebRawBytesPath', $RawPath, '-WebResponseMetadataPath', $MetadataPath,
    '-AccessPolicy', 'source-read-only', '-NetworkPolicy', 'source-read-only',
    '-AuthorizationTime', '2026-07-19T09:00:00+08:00',
    '-AuthorizationSource', 'approved-fixture',
    '-AuthorizationScope', 'current-capture'
  )
}

Initialize-BorrowingCaptureFixture
try {
  Invoke-CzxtContract 'capture façade completes Local READY then byte-stable REUSED' {
    $root = New-BorrowingFixtureRoot 'facade-local-root' project
    Initialize-BorrowingFacadeProjectSkeleton $root
    $source = Join-Path $script:BorrowingCaptureFixtureRoot 'facade-local-source'
    [void](New-Item -ItemType Directory -Path $source)
    Write-BorrowingFixtureBytes (Join-Path $source 'payload.bin') ([byte[]](0, 1, 255))
    $arguments = Get-BorrowingFacadeLocalArguments $root $source
    $firstProcess = Invoke-BorrowingFacade $arguments
    Assert-CzxtEqual 0 $firstProcess.ExitCode 'Local READY exit'
    Assert-CzxtEqual '' $firstProcess.StdErr 'Local READY stderr'
    $first = ConvertFrom-BorrowingFacadeOutput $firstProcess.StdOut
    Assert-CzxtEqual 'READY' $first.result 'Local first result'
    Assert-CzxtEqual 'complete' $first.stage 'Local first stage'
    Assert-CzxtEqual '0' $first.p4t_before 'Local first P4t-before'
    Assert-CzxtEqual '0' $first.p4t_after 'Local first P4t-after'
    Assert-CzxtTrue (Test-Path -LiteralPath $first.capture_path -PathType Container) `
      'Local capture path'
    Assert-CzxtEqual 'none' $first.staging_path 'Local first staging'
    $cardPath = Join-Path $first.capture_path '来源版本卡.md'
    $beforeBytes = [IO.File]::ReadAllBytes($cardPath)
    $beforeTime = (Get-Item $cardPath).LastWriteTimeUtc.Ticks

    $secondProcess = Invoke-BorrowingFacade $arguments
    Assert-CzxtEqual 0 $secondProcess.ExitCode 'Local REUSED exit'
    $second = ConvertFrom-BorrowingFacadeOutput $secondProcess.StdOut
    Assert-CzxtEqual 'REUSED' $second.result 'Local second result'
    Assert-CzxtEqual $first.capture_path $second.capture_path 'Local reused path'
    Assert-CzxtEqual '0' $second.p4t_before 'Local reuse P4t-before'
    Assert-CzxtEqual 'not-run' $second.p4t_after 'Local reuse P4t-after'
    Assert-CzxtEqual ([Convert]::ToBase64String($beforeBytes)) `
      ([Convert]::ToBase64String([IO.File]::ReadAllBytes($cardPath))) 'Local reused card bytes'
    Assert-CzxtEqual $beforeTime (Get-Item $cardPath).LastWriteTimeUtc.Ticks `
      'Local reused card mtime'
  }

  Invoke-CzxtContract 'capture façade repairs only an entirely missing Web ignored-cache set' {
    $root = New-BorrowingFixtureRoot 'facade-web-root' project
    Initialize-BorrowingFacadeProjectSkeleton $root
    $inputRoot = Join-Path $script:BorrowingCaptureFixtureRoot 'facade-web-input'
    [void](New-Item -ItemType Directory -Path $inputRoot)
    $raw = Join-Path $inputRoot 'response.bin'
    $metadata = Join-Path $inputRoot 'response.json'
    Write-BorrowingFixtureBytes $raw ([byte[]](0, 255, 65, 10))
    Write-BorrowingFixtureBytes $metadata `
      (ConvertTo-BorrowingFixtureUtf8 (Get-BorrowingValidWebMetadataText))
    $arguments = Get-BorrowingFacadeWebArguments $root $raw $metadata
    $firstProcess = Invoke-BorrowingFacade $arguments
    Assert-CzxtEqual 0 $firstProcess.ExitCode 'Web READY exit'
    $first = ConvertFrom-BorrowingFacadeOutput $firstProcess.StdOut
    Assert-CzxtEqual 'READY' $first.result 'Web first result'
    $cardPath = Join-Path $first.capture_path '来源版本卡.md'
    $beforeBytes = [IO.File]::ReadAllBytes($cardPath)
    $beforeTime = (Get-Item $cardPath).LastWriteTimeUtc.Ticks
    Remove-Item -LiteralPath (Join-Path $first.capture_path '快照') -Recurse -Force
    Remove-Item -LiteralPath (Join-Path $first.capture_path 'capture.local.json') -Force

    $repairProcess = Invoke-BorrowingFacade $arguments
    Assert-CzxtEqual 0 $repairProcess.ExitCode 'Web repair exit'
    $repair = ConvertFrom-BorrowingFacadeOutput $repairProcess.StdOut
    Assert-CzxtEqual 'REUSED' $repair.result 'Web repair result'
    Assert-CzxtEqual 'not-run' $repair.p4t_before 'Web repair P4t-before'
    Assert-CzxtEqual '0' $repair.p4t_after 'Web repair P4t-after'
    Assert-CzxtTrue (Test-Path -LiteralPath `
        (Join-Path $repair.capture_path '快照\response.bin') -PathType Leaf) `
      'Web repaired raw cache'
    Assert-CzxtTrue (Test-Path -LiteralPath `
        (Join-Path $repair.capture_path 'capture.local.json') -PathType Leaf) `
      'Web repaired local state'
    Assert-CzxtEqual ([Convert]::ToBase64String($beforeBytes)) `
      ([Convert]::ToBase64String([IO.File]::ReadAllBytes($cardPath))) 'Web repaired card bytes'
    Assert-CzxtEqual $beforeTime (Get-Item $cardPath).LastWriteTimeUtc.Ticks `
      'Web repaired card mtime'
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
