[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-source-test-support.ps1')

Initialize-P4tTestFixture
try {
  $cases = @()
  foreach ($type in @('git', 'local', 'web')) {
    $root = New-ProjectSkeleton ('source-valid-' + $type)
    $record = New-P4tSourceCapture -Root $root -SourceType $type
    $cases += [pscustomobject]@{ Name = $type + ' ready capture'; Root = $root; Record = $record }
  }

  $modeUnknownRoot = New-ProjectSkeleton 'source-mode-unknown'
  Remove-Item -LiteralPath (Join-Path $modeUnknownRoot '.czxt-project-root') -Force
  $modeConflictRoot = New-ProjectSkeleton 'source-mode-conflict'
  Write-P4tUtf8 (Join-Path $modeConflictRoot '.czxt-template-root') `
    "czxt-root-mode=template`nschema=1`n"
  $modeCases = @(
    [pscustomobject]@{
      Name = 'project-as-template'; Root = (New-ProjectSkeleton 'source-project-as-template')
      SuppliedMode = 'template'; ActualMode = 'project'
    },
    [pscustomobject]@{
      Name = 'template-as-project'; Root = (New-TemplateSkeleton 'source-template-as-project')
      SuppliedMode = 'project'; ActualMode = 'template'
    },
    [pscustomobject]@{
      Name = 'unknown-root'; Root = $modeUnknownRoot
      SuppliedMode = 'unknown'; ActualMode = 'unknown'
    },
    [pscustomobject]@{
      Name = 'conflicting-root'; Root = $modeConflictRoot
      SuppliedMode = 'conflict'; ActualMode = 'conflict'
    }
  )
  $unsafeSkeletonRoot = New-ProjectSkeleton 'source-unsafe-empty-skeleton'
  $unsafeSkeletonPath = Join-Path $unsafeSkeletonRoot '借鉴区\模板\来源版本卡.md'
  $unsafeSkeletonText = [IO.File]::ReadAllText($unsafeSkeletonPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $unsafeSkeletonPath `
    $unsafeSkeletonText.Replace('`P4t fixture`', '`Bearer abc`')

  Invoke-CzxtContract 'source positive fixtures contain all three offline cache forms' {
    Assert-CzxtEqual 3 $cases.Count 'source positive fixture count'
    foreach ($case in $cases) {
      Assert-CzxtTrue (Test-Path -LiteralPath $case.Record.CardPath -PathType Leaf) `
        ($case.Name + ' card')
      Assert-CzxtTrue ($case.Record.CaptureId.EndsWith(
          $case.Record.Fingerprint.Substring(0, 12), [StringComparison]::Ordinal)) `
        ($case.Name + ' capture suffix')
    }
    Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $cases[0].Record.CapturePath `
          '快照\repository.git') -PathType Container) 'Git bare cache'
    Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $cases[1].Record.CapturePath `
          '快照\manifest.tsv') -PathType Leaf) 'Local manifest cache'
    Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $cases[2].Record.CapturePath `
          '快照\response.bin') -PathType Leaf) 'Web raw cache'
    Assert-CzxtEqual 4 $modeCases.Count 'source mode anti-spoof case count'
  }

  $script:SourceHelperReady = $false
  Invoke-CzxtContract 'P4t source helper exists with its dedicated leaf API' {
    Import-P4tHelper -FileName 'borrowing-source-cards.ps1' `
      -CommandName 'Invoke-BorrowingP4tSourceCheck'
    $script:SourceHelperReady = $true
  }

  if ($script:SourceHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('source positive: ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tSourceCheck -Root $case.Root -Mode project
        Assert-P4tResult $result 0 $case.Name
        Assert-CzxtTrue ($null -ne $result.PSObject.Properties['ReadyCaptures']) `
          ($case.Name + ' lacks ready map')
        Assert-CzxtTrue (@($result.ReadyCaptures | Where-Object {
              $_.SourceId -ceq $case.Record.SourceId -and
              $_.CaptureId -ceq $case.Record.CaptureId -and
              $_.Fingerprint -ceq $case.Record.Fingerprint
            }).Count -eq 1) ($case.Name + ' ready map projection')
        if ($case.Record.SourceType -in @('git', 'web')) {
          $card = [IO.File]::ReadAllText($case.Record.CardPath, $script:P4tUtf8NoBom)
          foreach ($anchor in @(
              'access_policy: source-read-only', 'network_policy: source-read-only',
              'execution_policy: deny', 'upstream_write_policy: deny')) {
            Assert-CzxtTrue $card.Contains($anchor) ($case.Name + ' permission ' + $anchor)
          }
        }
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
      }
    }
    Invoke-CzxtContract 'source rejects credential in an empty project source-card skeleton' {
      $before = Get-P4tTreeState $unsafeSkeletonRoot
      $result = Invoke-BorrowingP4tSourceCheck $unsafeSkeletonRoot project
      Assert-P4tResult $result 10 'credential-bearing empty source-card skeleton'
      Assert-P4tTreeUnchanged $before (Get-P4tTreeState $unsafeSkeletonRoot) `
        'credential-bearing empty skeleton read-only'
    }
    foreach ($modeCase in $modeCases) {
      Invoke-CzxtContract ('source rejects forged mode: ' + $modeCase.Name) {
        $before = Get-P4tTreeState $modeCase.Root
        $result = Invoke-BorrowingP4tSourceCheck `
          -Root $modeCase.Root -Mode $modeCase.SuppliedMode
        Assert-P4tResult $result 10 $modeCase.Name
        Assert-CzxtEqual $modeCase.ActualMode ([string]$result.Mode) `
          ($modeCase.Name + ' independently detected RootMode')
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $modeCase.Root) `
          ($modeCase.Name + ' read-only')
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
