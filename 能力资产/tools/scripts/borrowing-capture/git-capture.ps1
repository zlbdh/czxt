$ErrorActionPreference = 'Stop'

function global:Invoke-BgGit {
  param([scriptblock]$RunGit, [string[]]$Arguments, [string]$Mode = 'text')
  try { $result = & $RunGit $Arguments $Mode }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Stop-Bg capture capture-failed
  }
  if ($null -eq $result -or $result.ExitCode -ne 0 -or
      -not [string]::IsNullOrEmpty($result.StdErr)) {
    Stop-Bg capture capture-failed
  }
  return $result
}

function global:Get-BgOidLine {
  param($Result, [int]$Length)
  $pattern = '\A([0-9a-f]{' + $Length + '})\n\z'
  if ($Result.StdOut -cnotmatch $pattern) { Stop-Bg capture capture-failed }
  return $Matches[1]
}

function global:Test-BgLfsPointer {
  param([scriptblock]$RunGit, [string]$Repository, [string]$Commit)
  try {
    $result = & $RunGit @('-C', $Repository, 'grep', '-I', '-n', '-z', '-e',
      '^version https://git-lfs.github.com/spec/v1$', $Commit, '--') 'record-nul'
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Stop-Bg capture capture-failed
  }
  if ($null -eq $result -or -not [string]::IsNullOrEmpty($result.StdErr) -or
      $result.ExitCode -notin @(0, 1)) { Stop-Bg capture capture-failed }
  if ($result.ExitCode -eq 1) {
    if ($result.StdOut.Length -ne 0) { Stop-Bg capture capture-failed }
    return $false
  }
  return $result.StdOut.Contains("`01`0version https://git-lfs.github.com/spec/v1`n")
}

function global:Invoke-BorrowingGitCapture {
  param(
    [string]$StagingPath, [string]$CanonicalLocator, [string]$FullRef,
    [ValidateSet('branch', 'tag')][string]$RefType, [scriptblock]$RunGit,
    $Operations
  )
  $staging = [IO.Path]::GetFullPath($StagingPath).TrimEnd('\')
  $removeTrusted = $false
  if ($null -eq $RunGit) {
    $resolved = Resolve-BorrowingGitExecutable
    $runner = New-BorrowingGitRunner $resolved.Path $staging
    $trusted = $runner.TrustedEmptyDirectory
    $RunGit = {
      param($arguments, $mode)
      Invoke-BorrowingGitRunner $runner $arguments $mode
    }.GetNewClosure()
  }
  else {
    $trusted = Join-Path $staging '.git-trusted-empty'
    if ($null -ne $Operations -and $null -ne $Operations.CreateDirectory) {
      $createDirectory = $Operations.CreateDirectory
      & $createDirectory $trusted
    }
    else {
      [void](New-Item -ItemType Directory -Path $trusted -Force)
      $removeTrusted = $true
    }
  }
  $probe = Invoke-BgGit $RunGit @(
    'ls-remote', '--refs', '--exit-code', $CanonicalLocator, $FullRef
  )
  $escapedRef = [regex]::Escape($FullRef)
  if ($probe.StdOut -cnotmatch `
      ('\A([0-9a-f]{40}|[0-9a-f]{64})\t' + $escapedRef + '\n\z')) {
    Stop-Bg capture capture-failed
  }
  $advertised = $Matches[1]
  $format = if ($advertised.Length -eq 40) { 'sha1' } else { 'sha256' }
  $oidLength = $advertised.Length
  $snapshot = Join-Path $staging '快照'
  $repo = Join-Path $snapshot 'repository.git'
  if ($null -ne $Operations -and $null -ne $Operations.CreateDirectory) {
    $createDirectory = $Operations.CreateDirectory
    & $createDirectory $snapshot
    & $createDirectory $repo
  }
  else { [void](New-Item -ItemType Directory -Path $snapshot -Force) }
  [void](Invoke-BgGit $RunGit @(
      'init', '--quiet', '--bare', ('--object-format=' + $format),
      ('--template=' + $trusted), $repo
    ))
  if ($removeTrusted) { Remove-Item -LiteralPath $trusted -Force }
  $configPath = Join-Path $repo 'config'
  [byte[]]$configBytes = Get-BgConfigBytes $format
  if ($null -ne $Operations -and $null -ne $Operations.ReplaceFileBytes) {
    $replaceFileBytes = $Operations.ReplaceFileBytes
    & $replaceFileBytes $configPath $configBytes
  }
  else { [IO.File]::WriteAllBytes($configPath, $configBytes) }
  [void](Invoke-BgGit $RunGit @(
      '-C', $repo, 'fetch', '--quiet', '--depth=1', '--no-tags',
      '--no-recurse-submodules', '--no-write-fetch-head', '--no-auto-maintenance',
      '--no-write-commit-graph', '--force', $CanonicalLocator,
      ('+' + $FullRef + ':refs/czxt/capture')
    ))
  $shown = Get-BgOidLine (Invoke-BgGit $RunGit @(
      '-C', $repo, 'show-ref', '--verify', '--hash', 'refs/czxt/capture'
    )) $oidLength
  if ($shown -cne $advertised) { Stop-Bg capture capture-failed }
  $commit = Get-BgOidLine (Invoke-BgGit $RunGit @(
      '-C', $repo, 'rev-parse', '--verify', 'refs/czxt/capture^{commit}'
    )) $oidLength
  $tree = Get-BgOidLine (Invoke-BgGit $RunGit @(
      '-C', $repo, 'rev-parse', '--verify', ($commit + '^{tree}')
    )) $oidLength
  [void](Invoke-BgGit $RunGit @(
      '-C', $repo, 'update-ref', '--no-deref', 'HEAD', $commit
    ))
  $listing = Invoke-BgGit $RunGit @(
    '-C', $repo, 'ls-tree', '-r', '-z', '-l', '--full-tree', $tree
  ) 'record-nul'
  if ($listing.StdOut.Length -gt 0 -and -not $listing.StdOut.EndsWith("`0")) {
    Stop-Bg capture capture-failed
  }
  $submodule = 'not-detected'
  $lfs = 'not-detected'
  $attributeOids = @()
  $records = if ($listing.StdOut.Length -eq 0) { @() }
    else { @($listing.StdOut.TrimEnd([char]0).Split([char]0)) }
  foreach ($record in $records) {
    if ($record -cnotmatch `
        '\A([0-7]{6}) (blob|commit) ([0-9a-f]+) +([0-9]+|-)\t(.+)\z' -or
        $Matches[3].Length -ne $oidLength) { Stop-Bg capture source-unsafe }
    $mode = $Matches[1]
    $oid = $Matches[3]
    $path = $Matches[5]
    if ($path -match '[\\\x00-\x1F\x7F-\x9F\u2028\u2029]' -or
        $path.StartsWith('/') -or @($path.Split('/') | Where-Object {
          $_ -in @('', '.', '..')
        }).Count -gt 0) { Stop-Bg capture source-unsafe }
    if ($mode -eq '120000') { Stop-Bg capture source-unsafe }
    if ($mode -eq '160000') { $submodule = 'detected' }
    elseif ($mode -notin @('100644', '100755')) { Stop-Bg capture source-unsafe }
    if ($path.Split('/')[-1] -ceq '.gitattributes') { $attributeOids += $oid }
  }
  foreach ($oid in $attributeOids) {
    $attribute = Invoke-BgGit $RunGit @('-C', $repo, 'cat-file', 'blob', $oid)
    if ($attribute.StdOut -match `
        '(?m)(?:^|[ \t])filter[ \t]*=[ \t]*lfs(?:[ \t]|$)') {
      $lfs = 'detected'
      break
    }
  }
  if ($lfs -eq 'not-detected' -and (Test-BgLfsPointer $RunGit $repo $commit)) {
    $lfs = 'detected'
  }
  Test-BorrowingGitCache $repo $format $advertised $commit $tree $RunGit
  $facts = [pscustomobject][ordered]@{
    Ref = $FullRef; RefType = $RefType; ObjectFormat = $format
    Commit = $commit; Tree = $tree
    SubmoduleStatus = $submodule; LfsStatus = $lfs
  }
  return [pscustomobject][ordered]@{
    Schema = 'czxt-borrowing-git-candidate/v1'; SourceType = 'git'
    CanonicalLocator = $CanonicalLocator; FullRef = $FullRef; Ref = $FullRef
    RefType = $RefType; ObjectFormat = $format; AdvertisedOid = $advertised
    Commit = $commit; Tree = $tree; FingerprintAlgorithm = 'git-object'
    Fingerprint = $commit; SubmoduleStatus = $submodule; LfsStatus = $lfs
    GitFacts = $facts
  }
}
