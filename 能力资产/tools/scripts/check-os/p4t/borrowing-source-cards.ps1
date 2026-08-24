$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'borrowing-common.ps1')
. (Join-Path $borrowingP4tCaptureRoot 'source-candidate-validator.ps1')

function global:Add-BorrowingP4tSourceIssue {
  param($List, [string]$Message)
  [void]$List.Add($Message)
}

. (Join-Path $PSScriptRoot 'borrowing-source-safety.ps1')
. (Join-Path $PSScriptRoot 'borrowing-source-references.ps1')
. (Join-Path $PSScriptRoot 'borrowing-source-inventory.ps1')
. (Join-Path $PSScriptRoot 'borrowing-source-git.ps1')

function global:Invoke-BorrowingP4tSourceCheck {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)]
    [ValidateSet('template', 'project', 'unknown', 'conflict')][string]$Mode
  )
  $warnings = New-Object 'Collections.Generic.List[string]'
  $failures = New-Object 'Collections.Generic.List[string]'
  $ready = New-Object 'Collections.Generic.List[object]'
  $retired = New-Object 'Collections.Generic.List[object]'
  $suppliedMode = $Mode.ToLowerInvariant()
  $detectedMode = 'unknown'
  try { $safeRoot = Resolve-BorrowingP4tSafeRoot $Root }
  catch { Add-BorrowingP4tSourceIssue $failures $_.Exception.Message; $safeRoot = $null }
  if ($null -ne $safeRoot) {
    $detectedMode = Get-BorrowingP4tRootMode -Root $safeRoot
    if ($detectedMode -eq 'unknown') {
      Add-BorrowingP4tSourceIssue $failures 'Root 缺 marker'
    }
    elseif ($detectedMode -eq 'conflict') {
      Add-BorrowingP4tSourceIssue $failures 'Root marker 冲突'
    }
    if ($suppliedMode -cne $detectedMode) {
      Add-BorrowingP4tSourceIssue $failures 'RootMode 与传入 Mode 不一致'
    }
  }
  $byCapture = @{}; $byStableIdentity = @{}
  if ($null -ne $safeRoot -and $failures.Count -eq 0 -and $detectedMode -eq 'project') {
    Test-BorrowingP4tIgnoreContract $safeRoot $failures
    Test-BorrowingP4tTrackedCache $safeRoot $failures
    Test-BorrowingP4tSourceSkeletonSafety $safeRoot $failures
    $sources = Join-Path $safeRoot '借鉴区\来源'
    $inventory = @(Get-BorrowingP4tSafeSourceInventory $sources $failures)
    if (Test-Path -LiteralPath $sources -PathType Container) {
      foreach ($inventoryEntry in $inventory) {
        $captureDirectory = [IO.DirectoryInfo]$inventoryEntry.CaptureDirectory
          try {
            $cards = @(Get-BorrowingP4tSafeSourceCards $captureDirectory.FullName)
            if ($cards.Count -ne 1 -or $cards[0].DirectoryName -cne $captureDirectory.FullName) {
              throw 'capture card count invalid'
            }
            $candidate = Get-BorrowingValidatedSourceCandidate $captureDirectory.FullName
            if (-not (Test-BorrowingP4tTrackedSourceSafety $candidate)) {
              throw 'source tracked values contain credential material'
            }
            if ($byCapture.ContainsKey($candidate.CaptureId) -or
                $byStableIdentity.ContainsKey($candidate.StableIdentitySha256)) {
              throw 'source capture identity is duplicated'
            }
            $byCapture[$candidate.CaptureId] = $candidate
            $byStableIdentity[$candidate.StableIdentitySha256] = $candidate
            if ($candidate.IgnoredCacheState.State -ceq 'AllMissing' -and
                $candidate.Permissions.StoragePolicy -ceq 'local-only') {
              Add-BorrowingP4tSourceIssue $warnings `
                ('来源本地缓存缺失：' + $candidate.SourceId + '/' + $candidate.CaptureId)
            }
            elseif ($candidate.IgnoredCacheState.State -cne 'Healthy') {
              throw 'source cache is incomplete'
            }
            if (-not (Test-BorrowingP4tGitSnapshot $candidate)) {
              throw 'Git source cache does not match card facts'
            }
            if ($candidate.CaptureStatus -ceq 'ready') { [void]$ready.Add($candidate) }
            else { [void]$retired.Add($candidate) }
          }
          catch {
            Add-BorrowingP4tSourceIssue $failures `
              ('来源 capture 无效：' + $inventoryEntry.SourceName + '/' + $captureDirectory.Name)
          }
      }
      foreach ($reference in @(Get-BorrowingP4tItemReferences $safeRoot $failures)) {
        $candidate = $byCapture[$reference.CaptureId]
        if ($null -eq $candidate -or $candidate.SourceId -cne $reference.SourceId -or
            $candidate.Fingerprint -cne $reference.Fingerprint -or
            ($reference.Status -notin @('closed', 'cancelled') -and
              $candidate.CaptureStatus -cne 'ready')) {
          Add-BorrowingP4tSourceIssue $failures `
            ('事项引用了不可用来源 capture：' + $reference.ItemId)
        }
      }
    }
  }
  $base = New-BorrowingP4tCheckResult $detectedMode $warnings $failures
  Add-Member -InputObject $base -NotePropertyName ReadyCaptures `
    -NotePropertyValue @($ready.ToArray())
  Add-Member -InputObject $base -NotePropertyName RetiredCaptures `
    -NotePropertyValue @($retired.ToArray())
  return $base
}
