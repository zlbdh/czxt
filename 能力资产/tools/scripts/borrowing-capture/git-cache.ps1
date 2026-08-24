$ErrorActionPreference = 'Stop'

$bgGitCacheRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command Read-BorrowingStableSafeFileSnapshot -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $bgGitCacheRoot 'trusted-file-read.ps1')
}

function global:Get-BgConfigBytes {
  param([string]$Format)
  if ($Format -eq 'sha1') {
    $lines = @('[core]', "`trepositoryformatversion = 0", "`tfilemode = false",
      "`tbare = true", "`tsymlinks = false", "`tignorecase = true")
  }
  elseif ($Format -eq 'sha256') {
    $lines = @('[core]', "`trepositoryformatversion = 1", "`tfilemode = false",
      "`tbare = true", "`tsymlinks = false", "`tignorecase = true", '[extensions]',
      "`tobjectformat = sha256")
  }
  else { Stop-Bg candidate candidate-invalid }
  return [Text.Encoding]::UTF8.GetBytes(($lines -join "`n") + "`n")
}

function global:Test-BgBytes {
  param([string]$Path, [byte[]]$Expected)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Stop-Bg candidate candidate-invalid
  }
  $snapshot = Read-BorrowingStableSafeFileSnapshot `
    $Path candidate source-unsafe
  [byte[]]$actual = $snapshot.Bytes
  if ($actual.Length -ne $Expected.Length) { Stop-Bg candidate candidate-invalid }
  for ($index = 0; $index -lt $actual.Length; $index++) {
    if ($actual[$index] -ne $Expected[$index]) {
      Stop-Bg candidate candidate-invalid
    }
  }
}

function global:Test-BorrowingGitCache {
  param(
    [string]$RepositoryPath, [string]$ObjectFormat, [string]$AdvertisedOid,
    [string]$CommitOid, [string]$TreeOid, [scriptblock]$RunGit
  )
  $oidLength = if ($ObjectFormat -eq 'sha1') { 40 }
    elseif ($ObjectFormat -eq 'sha256') { 64 }
    else { Stop-Bg candidate candidate-invalid }
  foreach ($oid in @($AdvertisedOid, $CommitOid, $TreeOid)) {
    if ($oid -cnotmatch ('\A[0-9a-f]{' + $oidLength + '}\z')) {
      Stop-Bg candidate candidate-invalid
    }
  }
  $repo = [IO.Path]::GetFullPath($RepositoryPath).TrimEnd('\')
  [void](Get-BorrowingSafePathInfo $repo Directory candidate source-unsafe)
  foreach ($item in @(Get-ChildItem -LiteralPath $repo -Force -Recurse)) {
    $kind = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
    [void](Get-BorrowingSafePathInfo $item.FullName $kind candidate source-unsafe)
  }
  $top = @(Get-ChildItem -LiteralPath $repo -Force)
  foreach ($item in $top) {
    if ($item.PSIsContainer) {
      if ($item.Name -cnotin @('objects', 'refs')) {
        Stop-Bg candidate candidate-invalid
      }
    }
    elseif ($item.Name -cnotin @('HEAD', 'config', 'shallow')) {
      Stop-Bg candidate candidate-invalid
    }
  }
  foreach ($required in @('HEAD', 'config', 'objects', 'refs')) {
    if ($top.Name -cnotcontains $required) { Stop-Bg candidate candidate-invalid }
  }
  Test-BgBytes (Join-Path $repo 'config') (Get-BgConfigBytes $ObjectFormat)
  Test-BgBytes (Join-Path $repo 'HEAD') `
    ([Text.Encoding]::UTF8.GetBytes($CommitOid + "`n"))
  $refs = Join-Path $repo 'refs'
  $ref = Join-Path $refs 'czxt\capture'
  Test-BgBytes $ref ([Text.Encoding]::UTF8.GetBytes($AdvertisedOid + "`n"))
  $refFiles = @(Get-ChildItem -LiteralPath $refs -File -Recurse -Force)
  if ($refFiles.Count -ne 1 -or $refFiles[0].FullName -cne $ref) {
    Stop-Bg candidate candidate-invalid
  }
  foreach ($directory in @(Get-ChildItem -LiteralPath $refs -Directory -Recurse -Force)) {
    $relative = $directory.FullName.Substring($refs.Length + 1).Replace('\', '/')
    if ($relative -cnotin @('heads', 'tags', 'czxt')) {
      Stop-Bg candidate candidate-invalid
    }
  }
  $shallow = Join-Path $repo 'shallow'
  if (Test-Path -LiteralPath $shallow) {
    Test-BgBytes $shallow ([Text.Encoding]::UTF8.GetBytes($CommitOid + "`n"))
  }
  $objects = Join-Path $repo 'objects'
  $packs = @{}
  foreach ($directory in @(Get-ChildItem -LiteralPath $objects -Directory -Recurse -Force)) {
    $relative = $directory.FullName.Substring($objects.Length + 1).Replace('\', '/')
    if ($relative -cnotmatch '\A(?:info|pack|[0-9a-f]{2})\z') {
      Stop-Bg candidate candidate-invalid
    }
    if ($relative -match '\A[0-9a-f]{2}\z' -and
        @(Get-ChildItem -LiteralPath $directory.FullName -Force).Count -eq 0) {
      Stop-Bg candidate candidate-invalid
    }
  }
  foreach ($file in @(Get-ChildItem -LiteralPath $objects -File -Recurse -Force)) {
    $relative = $file.FullName.Substring($objects.Length + 1).Replace('\', '/')
    if ($relative -match ('\A[0-9a-f]{2}/[0-9a-f]{' + ($oidLength - 2) + '}\z')) {
      continue
    }
    if ($relative -match `
        ('\Apack/(pack-[0-9a-f]{' + $oidLength + '})\.(pack|idx|rev)\z')) {
      if (-not $packs.ContainsKey($Matches[1])) { $packs[$Matches[1]] = @{} }
      $packs[$Matches[1]][$Matches[2]] = $true
      continue
    }
    Stop-Bg candidate candidate-invalid
  }
  foreach ($packSet in $packs.Values) {
    if (-not $packSet.pack -or -not $packSet.idx) {
      Stop-Bg candidate candidate-invalid
    }
  }
  if (@(Get-ChildItem -LiteralPath (Join-Path $objects 'info') -Force).Count -ne 0) {
    Stop-Bg candidate candidate-invalid
  }
  if ($null -eq $RunGit) {
    $resolved = Resolve-BorrowingGitExecutable
    $staging = Split-Path (Split-Path $repo -Parent) -Parent
    $runner = New-BorrowingGitRunner $resolved.Path $staging
    $RunGit = {
      param($arguments, $mode)
      Invoke-BorrowingGitRunner $runner $arguments $mode
    }.GetNewClosure()
  }
  $fsck = Invoke-BgGit $RunGit @('-C', $repo, 'fsck', '--full', '--strict',
    '--no-reflogs', '--unreachable', '--no-progress')
  if ($fsck.StdOut.Length -ne 0) { Stop-Bg candidate candidate-invalid }
}
