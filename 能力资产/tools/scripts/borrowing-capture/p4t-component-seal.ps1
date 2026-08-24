$ErrorActionPreference = 'Stop'

$p4tComponentSealRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command Get-BorrowingTrustedHandleSnapshot -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $p4tComponentSealRoot 'trusted-file-read.ps1')
}

function global:Get-BorrowingP4tComponentPaths {
  param([string]$Root, [string]$Stage = 'preflight')
  try {
    $rootInfo = Get-BorrowingSafePathInfo $Root Directory $Stage `
      missing-trusted-component
    $paths = New-Object 'Collections.Generic.Dictionary[string,string]' `
      ([StringComparer]::OrdinalIgnoreCase)
    $main = Join-Path $rootInfo.CanonicalPath `
      '能力资产\tools\scripts\check-os\p4t-borrowing-consistency.ps1'
    $mainInfo = Get-BorrowingSafePathInfo $main File $Stage `
      missing-trusted-component
    $paths[$mainInfo.CanonicalPath] = $mainInfo.CanonicalPath

    foreach ($relative in @(
        '能力资产\tools\scripts\check-os\p4t',
        '能力资产\tools\scripts\borrowing-capture'
      )) {
      $directory = Join-Path $rootInfo.CanonicalPath $relative
      # 最小化的合同 fixture 可以只提供无依赖的 main；一旦目录存在就必须完整固定其 PS1 集。
      if (-not (Test-Path -LiteralPath $directory)) { continue }
      $directoryInfo = Get-BorrowingSafePathInfo $directory Directory $Stage `
        missing-trusted-component
      if ((Get-BorrowingPathRelation $rootInfo.CanonicalPath `
            $directoryInfo.CanonicalPath) -cne 'ancestor') {
        throw 'trusted component directory crosses project boundary'
      }
      $files = @(Get-ChildItem -LiteralPath $directoryInfo.CanonicalPath `
          -Filter '*.ps1' -File -Force -ErrorAction Stop)
      if ($files.Count -eq 0) { throw 'trusted component directory is empty' }
      foreach ($file in $files) {
        $fileInfo = Get-BorrowingSafePathInfo $file.FullName File $Stage `
          missing-trusted-component
        if ((Get-BorrowingPathRelation $rootInfo.CanonicalPath `
              $fileInfo.CanonicalPath) -cne 'ancestor') {
          throw 'trusted component crosses project boundary'
        }
        $paths[$fileInfo.CanonicalPath] = $fileInfo.CanonicalPath
      }
    }
    [string[]]$ordered = @($paths.Values)
    [Array]::Sort($ordered, [StringComparer]::OrdinalIgnoreCase)
    return $ordered
  }
  catch {
    Throw-BorrowingP4tFailure $Stage missing-trusted-component `
      'the fixed P4t component set is unavailable'
  }
}

function global:Read-BorrowingP4tSealedBytes {
  param($Stream, [uint64]$Length)
  if ($Length -gt [uint64][int]::MaxValue) {
    throw 'trusted component is too large'
  }
  $Stream.Position = 0
  [byte[]]$bytes = New-Object byte[] ([int]$Length)
  $offset = 0
  while ($offset -lt $bytes.Length) {
    $read = $Stream.Read($bytes, $offset, $bytes.Length - $offset)
    if ($read -le 0) { throw 'trusted component read ended early' }
    $offset += $read
  }
  return ,$bytes
}

function global:Test-BorrowingP4tBytesEqual {
  param([byte[]]$Expected, [byte[]]$Actual)
  if ($null -eq $Expected -or $null -eq $Actual -or
      $Expected.Length -ne $Actual.Length) { return $false }
  for ($index = 0; $index -lt $Expected.Length; $index++) {
    if ($Expected[$index] -ne $Actual[$index]) { return $false }
  }
  return $true
}

function global:Close-BorrowingP4tComponentSeal {
  param($Seal)
  if ($null -eq $Seal -or [bool]$Seal.IsClosed) { return }
  foreach ($item in @($Seal.Items)) {
    if ($null -ne $item.Stream) {
      try { $item.Stream.Dispose() } catch {}
    }
  }
  $Seal.IsClosed = $true
}

function global:New-BorrowingP4tComponentSeal {
  param([string]$Root)
  $items = New-Object 'Collections.Generic.List[object]'
  $current = $null
  try {
    foreach ($path in @(Get-BorrowingP4tComponentPaths $Root preflight)) {
      $before = Get-BorrowingSafePathInfo $path File preflight `
        missing-trusted-component
      # FileShare.Read 保留读取能力，但在两道 gate 之间禁止写入、删除和改名。
      $current = New-Object IO.FileStream(
        $before.CanonicalPath, [IO.FileMode]::Open, [IO.FileAccess]::Read,
        [IO.FileShare]::Read)
      $opened = Get-BorrowingTrustedHandleSnapshot $current.SafeFileHandle `
        preflight missing-trusted-component
      [byte[]]$bytes = Read-BorrowingP4tSealedBytes $current $opened.Length
      $after = Get-BorrowingTrustedHandleSnapshot $current.SafeFileHandle `
        preflight missing-trusted-component
      if (-not (Test-BorrowingTrustedSnapshotEqual $before $opened) -or
          -not (Test-BorrowingTrustedSnapshotEqual $opened $after)) {
        throw 'trusted component changed while sealing'
      }
      [void]$items.Add([pscustomobject]@{
          Path = [string]$opened.CanonicalPath
          IdentityKey = [string]$opened.IdentityKey
          Length = [uint64]$opened.Length
          Bytes = $bytes
          Stream = $current
        })
      $current = $null
    }
    return [pscustomobject]@{
      Schema = 'czxt-borrowing-p4t-component-seal/v1'
      Root = [IO.Path]::GetFullPath($Root)
      Items = [object[]]$items.ToArray()
      IsClosed = $false
    }
  }
  catch {
    if ($null -ne $current) { try { $current.Dispose() } catch {} }
    $partial = [pscustomobject]@{ Items = [object[]]$items.ToArray(); IsClosed = $false }
    Close-BorrowingP4tComponentSeal $partial
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Throw-BorrowingP4tFailure preflight missing-trusted-component `
      'the fixed P4t component set could not be sealed'
  }
}

function global:Assert-BorrowingP4tComponentSeal {
  param($Seal, [string]$Stage)
  try {
    if ($null -eq $Seal -or [bool]$Seal.IsClosed) {
      throw 'trusted component seal is closed'
    }
    [string[]]$currentPaths = @(Get-BorrowingP4tComponentPaths $Seal.Root $Stage)
    if ($currentPaths.Count -ne @($Seal.Items).Count) {
      throw 'trusted component set changed'
    }
    for ($index = 0; $index -lt $currentPaths.Count; $index++) {
      $item = $Seal.Items[$index]
      if (-not ([string]$item.Path).Equals($currentPaths[$index], `
            [StringComparison]::OrdinalIgnoreCase) -or
          $null -eq $item.Stream -or -not $item.Stream.CanRead) {
        throw 'trusted component path or handle changed'
      }
      $handle = Get-BorrowingTrustedHandleSnapshot $item.Stream.SafeFileHandle `
        $Stage trusted-component-changed
      $path = Get-BorrowingSafePathInfo $item.Path File $Stage `
        trusted-component-changed
      $expected = [pscustomobject]@{
        CanonicalPath = $item.Path; IdentityKey = $item.IdentityKey
        Length = [uint64]$item.Length
      }
      [byte[]]$bytes = Read-BorrowingP4tSealedBytes $item.Stream $item.Length
      if (-not (Test-BorrowingTrustedSnapshotEqual $expected $handle) -or
          -not (Test-BorrowingTrustedSnapshotEqual $expected $path) -or
          -not (Test-BorrowingP4tBytesEqual $item.Bytes $bytes)) {
        throw 'trusted component identity or bytes changed'
      }
    }
  }
  catch {
    Throw-BorrowingP4tFailure $Stage trusted-component-changed `
      'a sealed P4t component changed'
  }
}

function global:Invoke-BorrowingP4tSealTestInjection {
  param([string]$Name, $Seal)
  if ($script:BorrowingP4tSealTestInjections -is [Collections.IDictionary] -and
      $script:BorrowingP4tSealTestInjections.Contains($Name)) {
    & $script:BorrowingP4tSealTestInjections[$Name] $Seal
  }
}
