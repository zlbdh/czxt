$ErrorActionPreference = 'Stop'

function global:Resolve-P4tIsolationAppRoot {
  param([string]$Root, [Collections.Generic.List[string]]$Failures, $Budget)

  $configDir = Join-Path $Root '项目配置'
  try {
    $configDirInfo = Get-BorrowingSafePathInfo -Path $configDir -ExpectedKind Directory `
      -Stage 'p4t-isolation' -ReasonCode 'unsafe-project-config'
    $configInventory = Get-P4tIsolationDirectoryInventory $configDirInfo $Budget
    $configs = @($configInventory.Entries | Where-Object {
        -not $_.IsContainer -and $_.Name -like '*.project.json'
      })
  }
  catch {
    Add-P4tIsolationFailure $Failures 'The project-configuration directory is missing or unsafe'
    return $null
  }

  $concrete = @($configs | Where-Object { $_.Name -cne '_模板.project.json' })
  if ($concrete.Count -gt 0) { $configs = $concrete }
  if ($configs.Count -ne 1) {
    Add-P4tIsolationFailure $Failures 'The project card is missing or not unique; cannot determine the business directory'
    return $null
  }

  try {
    # Deduct the safe path snapshot length from the budget before allowing a full project-card read.
    Use-P4tIsolationProjectConfigBudget `
      $Budget ([uint64]$configs[0].Snapshot.Length)
    $configSnapshot = Read-P4tIsolationExpectedFullSnapshot `
      -ExpectedFile $configs[0].Snapshot `
      -MaximumBytes ([uint64]$configs[0].Snapshot.Length) `
      -ReasonCode 'unsafe-project-config'
    $encodingInfo = Get-P4tIsolationEncodingInfo `
      $configSnapshot.Bytes $configSnapshot.Bytes.Length
    $configText = $encodingInfo.Encoding.GetString(
      $configSnapshot.Bytes, [int]$encodingInfo.Offset,
      $configSnapshot.Bytes.Length - [int]$encodingInfo.Offset)
    $config = $configText | ConvertFrom-Json
    $relative = [string]$config.appRepoDir
    if ([string]::IsNullOrWhiteSpace($relative) -or [IO.Path]::IsPathRooted($relative)) {
      throw 'invalid appRepoDir'
    }
    $appRoot = [IO.Path]::GetFullPath((Join-Path $Root $relative))
    $borrowingRoot = [IO.Path]::GetFullPath((Join-Path $Root '借鉴区'))
    if (-not (Test-P4tIsolationPathInside $appRoot $Root) -or
        $appRoot.Equals($borrowingRoot, [StringComparison]::OrdinalIgnoreCase) -or
        (Test-P4tIsolationPathInside $appRoot $borrowingRoot)) {
      throw 'appRepoDir escaped Root'
    }
    $info = Get-BorrowingSafePathInfo -Path $appRoot -ExpectedKind Directory `
      -Stage 'p4t-isolation' -ReasonCode 'unsafe-app-root'
    return [pscustomobject]@{
      AppRoot = [string]$info.CanonicalPath
      AppRootSnapshot = $info
      ConfigSnapshot = $configSnapshot
      ConfigDirectoryInventory = $configInventory
    }
  }
  catch {
    Add-P4tIsolationFailure $Failures 'The project card or business directory is invalid'
    return $null
  }
}

function global:Assert-P4tIsolationProjectResolutionStable {
  param($Resolution, $Budget)

  $configBefore = Get-BorrowingSafePathInfo `
    $Resolution.ConfigSnapshot.CanonicalPath File `
    'p4t-isolation' 'unsafe-project-config'
  if (-not (Test-BorrowingTrustedSnapshotEqual `
      $Resolution.ConfigSnapshot $configBefore)) {
    throw 'project config changed before closeout read'
  }
  Use-P4tIsolationProjectConfigBudget `
    $Budget ([uint64]$Resolution.ConfigSnapshot.Length)
  $configAfter = Read-P4tIsolationExpectedFullSnapshot `
    -ExpectedFile $Resolution.ConfigSnapshot `
    -MaximumBytes ([uint64]$Resolution.ConfigSnapshot.Length) `
    -ReasonCode 'unsafe-project-config'
  if (-not (Test-P4tIsolationBytesEqual `
        $Resolution.ConfigSnapshot.Bytes $configAfter.Bytes)) {
    throw 'project config changed during isolation scan'
  }
  $directoryAfter = Get-P4tIsolationDirectoryInventory `
    $Resolution.ConfigDirectoryInventory.Directory $Budget
  if (-not (Test-P4tIsolationDirectoryInventoryEqual `
      $Resolution.ConfigDirectoryInventory $directoryAfter)) {
    throw 'project config directory changed during isolation scan'
  }
}
