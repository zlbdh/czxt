$ErrorActionPreference = 'Stop'

function Assert-P4tPathInside {
  param([string]$Path, [string]$Parent, [string]$Context = 'path')
  $full = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
  $parentFull = [IO.Path]::GetFullPath($Parent).TrimEnd('\', '/')
  $prefix = $parentFull + [IO.Path]::DirectorySeparatorChar
  Assert-CzxtTrue ($full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) `
    ("{0} escaped fixture parent: {1}" -f $Context, $full)
  Assert-CzxtTrue (-not $full.Equals($parentFull, [StringComparison]::OrdinalIgnoreCase)) `
    ("{0} resolved to fixture parent" -f $Context)
  return $full
}

function Remove-P4tTestFixture {
  if ($null -eq $script:P4tFixtureRoot) { return }
  $root = Assert-P4tPathInside -Path $script:P4tFixtureRoot `
    -Parent $script:P4tFixtureParent -Context 'cleanup root'
  foreach ($link in @($script:P4tReparsePaths | Sort-Object Length -Descending)) {
    try {
      $safeLink = Assert-P4tPathInside -Path $link -Parent $root -Context 'cleanup reparse path'
      if ([IO.Directory]::Exists($safeLink)) { [IO.Directory]::Delete($safeLink, $false) }
      elseif ([IO.File]::Exists($safeLink)) { [IO.File]::Delete($safeLink) }
    }
    catch { Write-Warning ('P4t fixture reparse cleanup refused: ' + $_.Exception.Message) }
  }
  if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
  $script:P4tReparsePaths.Clear()
  $script:P4tFixtureRoot = $null
}

function Get-P4tTreeState {
  param([string]$Root)
  $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
  if (-not (Test-Path -LiteralPath $rootFull -PathType Container)) { return @() }
  $pending = New-Object Collections.Generic.Queue[string]
  $pending.Enqueue($rootFull)
  $rows = New-Object Collections.Generic.List[string]
  while ($pending.Count -gt 0) {
    $current = $pending.Dequeue()
    foreach ($entry in @(Get-ChildItem -LiteralPath $current -Force | Sort-Object Name)) {
      $relative = $entry.FullName.Substring($rootFull.Length).TrimStart('\', '/') -replace '\\', '/'
      $isReparse = ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
      if ($entry.PSIsContainer) {
        $rows.Add(('D|{0}|{1}' -f $relative, $isReparse))
        if (-not $isReparse) { $pending.Enqueue($entry.FullName) }
      }
      else {
        $bytes = [IO.File]::ReadAllBytes($entry.FullName)
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $hash = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant() }
        finally { $sha.Dispose() }
        $rows.Add(('F|{0}|{1}|{2}|{3}' -f $relative, $bytes.Length, $entry.LastWriteTimeUtc.Ticks, $hash))
      }
    }
  }
  return @($rows | Sort-Object)
}

function Assert-P4tTreeUnchanged {
  param([string[]]$Before, [string[]]$After, [string]$Context)
  Assert-CzxtEqual $Before.Count $After.Count ($Context + ' entry count')
  for ($index = 0; $index -lt $Before.Count; $index++) {
    Assert-CzxtEqual $Before[$index] $After[$index] ($Context + ' entry ' + $index)
  }
}

function New-P4tJunction {
  param([string]$LinkPath, [string]$TargetPath)
  $link = Assert-P4tPathInside -Path $LinkPath -Parent $script:P4tFixtureRoot -Context 'junction'
  $target = Assert-P4tPathInside -Path $TargetPath -Parent $script:P4tFixtureRoot -Context 'junction target'
  if (-not (Test-Path -LiteralPath $target -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $target -Force)
  }
  $parent = Split-Path -Parent $link
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  [void](New-Item -ItemType Junction -Path $link -Target $target)
  $script:P4tReparsePaths.Add($link)
  return $link
}
