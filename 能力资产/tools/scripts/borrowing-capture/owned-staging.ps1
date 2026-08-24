$ErrorActionPreference = 'Stop'

$ownedStagingModuleRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$ownedStagingScriptsRoot = Split-Path $ownedStagingModuleRoot -Parent
foreach ($helper in @(
    'borrowing-owned-directory.ps1', 'borrowing-owned-file.ps1',
    'borrowing-owned-object.ps1'
  )) {
  $helperPath = Join-Path $ownedStagingScriptsRoot $helper
  if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    Throw-BorrowingFailure preflight missing-trusted-component `
      'capture owned staging helper is missing'
  }
  . $helperPath
}
if (-not (Get-Command Read-BorrowingStableSafeFileSnapshot -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $ownedStagingModuleRoot 'trusted-file-read.ps1')
}

function global:ConvertFrom-BorrowingOwnedNativePath {
  param([string]$Path, [string]$Stage, [string]$ReasonCode)
  try {
    $canonical = $Path.Normalize([Text.NormalizationForm]::FormC).Replace('/', '\')
    if (-not $canonical.StartsWith('\\?\', [StringComparison]::Ordinal) -or
        $canonical.Length -lt 7) { throw 'native prefix' }
    $canonical = $canonical.Substring(4)
    if ($canonical -notmatch '\A[A-Za-z]:\\') { throw 'fixed drive' }
    return $canonical.Substring(0, 1).ToUpperInvariant() + $canonical.Substring(1)
  }
  catch { Throw-BorrowingFailure $Stage $ReasonCode 'owned native path is unsafe' }
}

function global:Get-BorrowingOwnedNativeIdentity {
  param($Native)
  return '{0:x8}:{1:x8}:{2:x8}' -f $Native.VolumeSerialNumber,
    $Native.FileIndexHigh, $Native.FileIndexLow
}

function global:Test-BorrowingOwnedSamePath {
  param([string]$Left, [string]$Right)
  return [string]::Equals($Left, $Right, [StringComparison]::OrdinalIgnoreCase)
}

function global:New-BorrowingOwnedDirectoryState {
  param($Native, [string]$ExpectedPath, [bool]$Created,
    [string]$Stage, [string]$ReasonCode)
  $canonical = ConvertFrom-BorrowingOwnedNativePath $Native.FinalPath $Stage $ReasonCode
  if (-not (Test-BorrowingOwnedSamePath $canonical $ExpectedPath)) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned directory physical path changed'
  }
  return [pscustomobject]@{
    Path = $canonical; CanonicalPath = $canonical
    IdentityKey = Get-BorrowingOwnedNativeIdentity $Native
    Created = $Created; Native = $Native
  }
}

function global:Open-BorrowingOwnedDirectoryState {
  param([string]$Path, [string]$Stage, [string]$ReasonCode,
    [AllowNull()][string]$ExpectedIdentityKey = $null)
  $safe = Get-BorrowingSafePathInfo $Path Directory $Stage $ReasonCode
  $native = $null
  try {
    $native = [Czxt.B.AtomicDirectoryLease]::OpenExisting($safe.CanonicalPath)
    $owned = New-BorrowingOwnedDirectoryState $native $safe.CanonicalPath $false `
      $Stage $ReasonCode
    if ($owned.IdentityKey -cne $safe.IdentityKey -or
        (-not [string]::IsNullOrEmpty($ExpectedIdentityKey) -and
          $owned.IdentityKey -cne $ExpectedIdentityKey)) {
      Throw-BorrowingFailure $Stage $ReasonCode 'owned directory identity changed'
    }
    $native = $null
    return $owned
  }
  finally { if ($null -ne $native) { $native.Dispose() } }
}

function global:New-BorrowingOwnedDirectoryRelative {
  param($Parent, [string]$LeafName, [string]$Stage, [string]$ReasonCode)
  if ($null -eq $Parent -or $null -eq $Parent.Native) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned directory parent lease is missing'
  }
  $native = $null
  try {
    $Parent.Native.Verify()
    $expected = [IO.Path]::GetFullPath((Join-Path $Parent.Path $LeafName)).Normalize(
      [Text.NormalizationForm]::FormC)
    $native = [Czxt.B.AtomicDirectoryLease]::CreateRelative(
      $Parent.Native, $LeafName)
    $owned = New-BorrowingOwnedDirectoryState $native $expected $true $Stage $ReasonCode
    $native = $null
    return $owned
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Throw-BorrowingFailure $Stage $ReasonCode 'owned directory relative create failed'
  }
  finally { if ($null -ne $native) { $native.Dispose() } }
}

function global:New-BorrowingOwnedStagingCore {
  param($Prepared)
  $sources = $null; $source = $null; $staging = $null
  try {
    $sourcesPath = Join-Path $Prepared.Root '借鉴区\来源'
    $sources = Open-BorrowingOwnedDirectoryState $sourcesPath preflight `
      missing-trusted-component
    $sourcePath = Join-Path $sources.Path $Prepared.Request.SourceId
    if (Test-Path -LiteralPath $sourcePath -PathType Leaf) {
      Throw-BorrowingFailure input source-boundary `
        'source directory conflicts with a file'
    }
    if (Test-Path -LiteralPath $sourcePath -PathType Container) {
      $source = Open-BorrowingOwnedDirectoryState $sourcePath input source-boundary
    }
    else {
      $source = New-BorrowingOwnedDirectoryRelative $sources `
        $Prepared.Request.SourceId input source-boundary
    }
    if ((Get-BorrowingPathRelation $sources.Path $source.Path) -cne 'ancestor') {
      Throw-BorrowingFailure input source-boundary 'owned source directory escaped'
    }
    $leaf = '.staging-' + [guid]::NewGuid().ToString('N')
    $staging = New-BorrowingOwnedDirectoryRelative $source $leaf capture capture-failed
    if ($script:BorrowingOwnedStagingTestInjections -is [Collections.IDictionary] -and
        $script:BorrowingOwnedStagingTestInjections.Contains('after-staging-created')) {
      & $script:BorrowingOwnedStagingTestInjections['after-staging-created'] $staging
    }
    $directories = New-Object `
      'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
    $files = New-Object `
      'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
    return [pscustomobject]@{
      Schema = 'borrowing-owned-staging/v1'
      SourcePath = $source.Path; StagingPath = $staging.Path
      SourceIdentityKey = $source.IdentityKey
      StagingIdentityKey = $staging.IdentityKey
      SourcesLease = $sources; SourceLease = $source; StagingLease = $staging
      DirectoryLeases = $directories; FileLeases = $files
      OriginalStagingPath = $staging.Path; State = 'staging'
    }
  }
  catch {
    $creationFailure = $_
    if ($null -ne $staging -and $null -ne $staging.Native) {
      Set-BorrowingGeneratedStagingFailurePath $creationFailure.Exception `
        $Prepared.Root $source.Path $staging.Path
      try { $staging.Native.Dispose() } catch { }
      $staging.Native = $null
    }
    foreach ($owned in @($source, $sources)) {
      if ($null -ne $owned -and $null -ne $owned.Native) {
        try { $owned.Native.Dispose() } catch { }
        $owned.Native = $null
      }
    }
    throw $creationFailure
  }
}

function global:Close-BorrowingOwnedDirectoryState {
  param($Owned)
  if ($null -ne $Owned -and $null -ne $Owned.Native) {
    $Owned.Native.Dispose()
    $Owned.Native = $null
  }
}

function global:Close-BorrowingOwnedStagingLeases {
  param($Ownership)
  if ($null -eq $Ownership) { return }
  foreach ($owned in @($Ownership.FileLeases.Values)) {
    if ($null -ne $owned.Native) {
      try { $owned.Native.Dispose() } catch { }
      $owned.Native = $null
    }
  }
  $directories = @($Ownership.DirectoryLeases.Values | Sort-Object {
      ([string]$_.Path).Length
    } -Descending)
  foreach ($owned in $directories) {
    try { Close-BorrowingOwnedDirectoryState $owned } catch { }
  }
  foreach ($owned in @(
      $Ownership.StagingLease, $Ownership.SourceLease, $Ownership.SourcesLease
    )) {
    try { Close-BorrowingOwnedDirectoryState $owned } catch { }
  }
}

function global:Open-BorrowingOwnedExistingCapture {
  param([string]$Path, [string]$ExpectedIdentityKey)
  return Open-BorrowingOwnedDirectoryState $Path idempotency `
    idempotency-conflict $ExpectedIdentityKey
}

function global:New-BorrowingOwnedAuxiliaryStaging {
  param($Ownership, [string]$Prefix)
  if ($null -eq $Ownership -or $null -eq $Ownership.SourceLease -or
      $null -eq $Ownership.SourceLease.Native -or
      [string]::IsNullOrWhiteSpace($Prefix) -or
      -not $Prefix.StartsWith('.staging-', [StringComparison]::Ordinal)) {
    Throw-BorrowingFailure promotion source-unsafe `
      'owned auxiliary staging request is unsafe'
  }
  $leaf = $Prefix + [guid]::NewGuid().ToString('N')
  $staging = New-BorrowingOwnedDirectoryRelative `
    $Ownership.SourceLease $leaf promotion source-unsafe
  $directories = New-Object `
    'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
  $files = New-Object `
    'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
  return [pscustomobject]@{
    Schema = 'borrowing-owned-staging/v1'
    SourcePath = $Ownership.SourceLease.Path; StagingPath = $staging.Path
    SourceIdentityKey = $Ownership.SourceLease.IdentityKey
    StagingIdentityKey = $staging.IdentityKey
    SourcesLease = $null; SourceLease = $null; StagingLease = $staging
    DirectoryLeases = $directories; FileLeases = $files
    OriginalStagingPath = $staging.Path; State = 'auxiliary'
  }
}

. (Join-Path $ownedStagingModuleRoot 'owned-staging-content.ps1')
. (Join-Path $ownedStagingModuleRoot 'owned-tree-seal.ps1')
