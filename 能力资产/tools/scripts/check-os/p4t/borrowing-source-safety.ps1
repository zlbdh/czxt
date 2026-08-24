$ErrorActionPreference = 'Stop'

function global:Test-BorrowingP4tIgnoreContract {
  param([string]$Root, $Failures)
  $path = Join-Path $Root '借鉴区\.gitignore'
  try {
    [byte[]]$bytes = Read-BorrowingStableSafeFileBytes $path p4t-source source-unsafe
    $text = (New-Object Text.UTF8Encoding($false, $true)).GetString($bytes)
    foreach ($line in @('/来源/*/*/快照/**', '/来源/*/*/*.local.json')) {
      if (@($text.Replace("`r`n", "`n").Split("`n")) -cnotcontains $line) {
        throw 'ignore rule missing'
      }
    }
  }
  catch { Add-BorrowingP4tSourceIssue $Failures '借鉴区 .gitignore 缺少来源缓存静态忽略规则' }
}

function global:Test-BorrowingP4tSourceSkeletonSafety {
  param([string]$Root, $Failures)
  try {
    $skeleton = Get-BorrowingValidatedSourceCardSkeleton -Root $Root
    if (Test-BorrowingCredentialMaterial ([string]$skeleton.ProjectName)) {
      throw 'source-card skeleton project name contains credential material'
    }
  }
  catch { Add-BorrowingP4tSourceIssue $Failures '借鉴区来源卡模板缺失、不安全或含凭据' }
}

function global:Get-BorrowingP4tTrackedSourceValues {
  param($Candidate)
  $values = New-Object 'Collections.Generic.List[string]'
  if ($null -eq $Candidate.CardBytes) { throw 'tracked source card bytes are missing' }
  [void]$values.Add((New-Object Text.UTF8Encoding($false, $true)).GetString(
      [byte[]]$Candidate.CardBytes))
  foreach ($name in @(
      'SourceId', 'CaptureId', 'SourceType', 'CaptureStatus', 'CanonicalLocator',
      'FingerprintAlgorithm', 'Fingerprint', 'CapturedAt')) {
    $property = $Candidate.PSObject.Properties[$name]
    if ($null -eq $property) { throw ('tracked source value is missing: ' + $name) }
    [void]$values.Add([string]$property.Value)
  }
  foreach ($property in @($Candidate.Permissions.PSObject.Properties)) {
    [void]$values.Add([string]$property.Value)
  }
  foreach ($authorization in @($Candidate.PermissionAuthorizations)) {
    foreach ($property in @($authorization.PSObject.Properties)) {
      [void]$values.Add([string]$property.Value)
    }
  }
  foreach ($value in @($Candidate.FactNames) + @($Candidate.FactValues)) {
    [void]$values.Add([string]$value)
  }
  return $values.ToArray()
}

function global:Test-BorrowingP4tTrackedSourceSafety {
  param($Candidate)
  try {
    foreach ($value in @(Get-BorrowingP4tTrackedSourceValues $Candidate)) {
      if (Test-BorrowingCredentialMaterial $value) { return $false }
    }
    return $true
  }
  catch { return $false }
}
