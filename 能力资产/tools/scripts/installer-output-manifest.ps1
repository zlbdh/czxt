$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'installer-render-text.ps1')

function New-CzxtInstallerOutputManifest {
  return [pscustomobject]@{
    Schema = 'czxt-installer-output/v1'
    Entries = @{}
  }
}

function Assert-CzxtInstallerOutputManifest {
  param([object]$InstalledFiles)
  if ($null -eq $InstalledFiles -or
      $InstalledFiles.Schema -cne 'czxt-installer-output/v1' -or
      $null -eq $InstalledFiles.Entries -or
      -not ($InstalledFiles.Entries -is [Collections.IDictionary])) {
    throw 'Invalid installer output manifest.'
  }
}

function Set-CzxtInstallerOutputState {
  param([object]$InstalledFiles, [object]$State)
  if ($null -eq $InstalledFiles) { return }
  Assert-CzxtInstallerOutputManifest -InstalledFiles $InstalledFiles
  if ($null -eq $State -or [string]::IsNullOrWhiteSpace([string]$State.Path) -or
      [string]::IsNullOrWhiteSpace([string]$State.Identity) -or
      [string]::IsNullOrWhiteSpace([string]$State.Sha256)) {
    throw 'Installer output state is missing fields from the five-element tuple.'
  }
  $path = Get-CzxtBorrowingFullPath $State.Path
  $InstalledFiles.Entries[$path] = [pscustomobject]@{
    Path = $path
    Identity = [string]$State.Identity
    NumberOfLinks = [uint32]$State.NumberOfLinks
    Length = [uint64]$State.Length
    Sha256 = [string]$State.Sha256
  }
}

function Get-CzxtInstallerOutputState {
  param([object]$InstalledFiles, [string]$Path)
  Assert-CzxtInstallerOutputManifest -InstalledFiles $InstalledFiles
  $full = Get-CzxtBorrowingFullPath $Path
  if (-not $InstalledFiles.Entries.Contains($full)) {
    throw ("Target is not an installer output owned by this transaction: {0}" -f $full)
  }
  return $InstalledFiles.Entries[$full]
}

function Get-CzxtInstallerOutputStates {
  param([object]$InstalledFiles)
  Assert-CzxtInstallerOutputManifest -InstalledFiles $InstalledFiles
  return @($InstalledFiles.Entries.Values | Sort-Object Path)
}

function Open-CzxtInstallerOutputManifestLeases {
  param([string]$ProjectRoot, [object]$InstalledFiles)
  Assert-CzxtInstallerOutputManifest -InstalledFiles $InstalledFiles
  $leases = New-Object Collections.ArrayList
  try {
    foreach ($state in @(Get-CzxtInstallerOutputStates -InstalledFiles $InstalledFiles)) {
      $path = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
        -CandidatePath $state.Path -Context 'Final installer output'
      $lease = Open-CzxtInstallerFileLease -Path $path -ExpectedState $state `
        -Context 'Final installer output'
      [void]$leases.Add($lease.Native)
    }
    return [pscustomobject]@{ Items = [object[]]$leases.ToArray() }
  }
  catch {
    foreach ($lease in $leases.ToArray()) { $lease.Dispose() }
    throw
  }
}

function Close-CzxtInstallerOutputManifestLeases {
  param([object]$LeaseSet)
  if ($null -eq $LeaseSet) { return }
  foreach ($lease in $LeaseSet.Items) { $lease.Dispose() }
}

function Complete-CzxtInstallerOutput {
  param(
    [string]$ProjectRoot, [object]$InstalledFiles,
    [Text.Encoding]$Encoding, [switch]$Force,
    [scriptblock]$OnVerified
  )
  $leases = Open-CzxtInstallerOutputManifestLeases `
    -ProjectRoot $ProjectRoot -InstalledFiles $InstalledFiles
  try {
    foreach ($state in @(Get-CzxtInstallerOutputStates -InstalledFiles $InstalledFiles)) {
      $extension = [IO.Path]::GetExtension($state.Path)
      if ($extension -notin @('.json', '.ps1')) { continue }
      $snapshot = Get-CzxtInstallerOutputTextSnapshot -ProjectRoot $ProjectRoot `
        -InstalledFiles $InstalledFiles -TargetPath $state.Path -Context 'Final installer format validation'
      Assert-CzxtInstallerRenderedText -Text $snapshot.Text -Extension $extension -Path $state.Path
    }
    $marker = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
      -CandidatePath (Join-Path $ProjectRoot '.czxt-project-root') `
      -Context 'Project-root marker target'
    $expectation = Get-CzxtInstallerTargetExpectation -ProjectRoot $ProjectRoot `
      -TargetPath $marker -Context 'Project-root marker target' -AllowExisting:$Force
    Write-CzxtInstallerTextFile -ProjectRoot $ProjectRoot -TargetPath $marker `
      -Content "czxt-root-mode=project`nschema=1`n" -Encoding $Encoding `
      -Context 'Project-root marker target' `
      -ExpectAbsent:($expectation.Mode -eq 'ExpectAbsent') `
      -ExpectedPresentState $expectation.State -InstalledFiles $InstalledFiles
    $markerState = Get-CzxtInstallerOutputState -InstalledFiles $InstalledFiles -Path $marker
    $markerLease = Open-CzxtInstallerFileLease -Path $marker `
      -ExpectedState $markerState -Context 'Final project-root marker output'
    try { if ($null -ne $OnVerified) { & $OnVerified } }
    finally { $markerLease.Native.Dispose() }
  }
  finally { Close-CzxtInstallerOutputManifestLeases $leases }
}

function Get-CzxtInstallerFileSnapshot {
  param(
    [string]$ProjectRoot,
    [string]$TargetPath,
    [string]$Context = 'Installer file snapshot',
    [object]$ExpectedTargetState,
    [scriptblock]$BeforeSnapshotRead,
    [scriptblock]$AfterSnapshotRead
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  try {
    if ($null -ne $BeforeSnapshotRead) { & $BeforeSnapshotRead $target }
    $native = [Czxt.InstallerNative]::ReadSnapshot($target)
  }
  finally {
    if ($null -ne $AfterSnapshotRead) { & $AfterSnapshotRead $target }
  }
  $state = ConvertTo-CzxtInstallerFileState -NativeState $native -Path $target -Context $Context
  if ($null -ne $ExpectedTargetState) {
    Assert-CzxtInstallerFileStateStable $ExpectedTargetState $state $Context
  }
  return [pscustomobject]@{ State = $state; Bytes = [byte[]]$native.Bytes }
}

function Get-CzxtInstallerTextSnapshot {
  param(
    [string]$ProjectRoot,
    [string]$TargetPath,
    [string]$Context = 'Installer text snapshot',
    [object]$ExpectedTargetState,
    [scriptblock]$BeforeSnapshotRead,
    [scriptblock]$AfterSnapshotRead
  )
  $snapshot = Get-CzxtInstallerFileSnapshot -ProjectRoot $ProjectRoot `
    -TargetPath $TargetPath -Context $Context -ExpectedTargetState $ExpectedTargetState `
    -BeforeSnapshotRead $BeforeSnapshotRead -AfterSnapshotRead $AfterSnapshotRead
  $offset = if ($snapshot.Bytes.Length -ge 3 -and $snapshot.Bytes[0] -eq 0xEF -and
      $snapshot.Bytes[1] -eq 0xBB -and $snapshot.Bytes[2] -eq 0xBF) { 3 } else { 0 }
  $utf8 = New-Object Text.UTF8Encoding($false, $true)
  try { $text = $utf8.GetString($snapshot.Bytes, $offset, $snapshot.Bytes.Length - $offset) }
  catch { throw ("{0} is not valid UTF-8: {1}" -f $Context, $snapshot.State.Path) }
  return [pscustomobject]@{ State = $snapshot.State; Text = $text }
}

function Get-CzxtInstallerOutputTextSnapshot {
  param(
    [string]$ProjectRoot,
    [object]$InstalledFiles,
    [string]$TargetPath,
    [string]$Context = 'Installer output text snapshot'
  )
  $expected = Get-CzxtInstallerOutputState -InstalledFiles $InstalledFiles -Path $TargetPath
  return Get-CzxtInstallerTextSnapshot -ProjectRoot $ProjectRoot `
    -TargetPath $TargetPath -Context $Context -ExpectedTargetState $expected
}
