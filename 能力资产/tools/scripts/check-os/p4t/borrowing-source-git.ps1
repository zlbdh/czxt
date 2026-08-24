$ErrorActionPreference = 'Stop'

foreach ($dependency in @(
    'process.ps1', 'git-runner.ps1', 'git-input.ps1',
    'git-capture.ps1', 'git-cache.ps1')) {
  . (Join-Path $borrowingP4tCaptureRoot $dependency)
}

function global:New-BorrowingP4tReadOnlyGitContext {
  param([string]$WorkingDirectory)
  $resolved = Resolve-BorrowingGitExecutable
  $environment = New-BorrowingProcessEnvironment -RemovePrefixes @('GIT_') `
    -RemoveNames @('HOME', 'USERPROFILE', 'XDG_CONFIG_HOME', 'SSH_ASKPASS',
      'SSH_ASKPASS_REQUIRE') -Overrides ([ordered]@{
      GIT_TERMINAL_PROMPT = '0'; GIT_CONFIG_NOSYSTEM = '1'
      GIT_CONFIG_GLOBAL = 'NUL'; GIT_CONFIG_SYSTEM = 'NUL'
      GIT_LFS_SKIP_SMUDGE = '1'; GIT_PROTOCOL_FROM_USER = '0'
      GIT_ALLOW_PROTOCOL = ''; GIT_NO_REPLACE_OBJECTS = '1'
      GIT_OPTIONAL_LOCKS = '0'; LC_ALL = 'C'; LANG = 'C'
    })
  $prefix = @(
    '--no-pager', '-c', 'credential.helper=', '-c', 'core.askPass=',
    '-c', 'core.hooksPath=NUL', '-c', 'core.fsmonitor=false',
    '-c', 'filter.lfs.clean=', '-c', 'filter.lfs.smudge=',
    '-c', 'filter.lfs.process=', '-c', 'filter.lfs.required=false',
    '-c', 'submodule.recurse=false', '-c', 'fetch.recurseSubmodules=false',
    '-c', 'protocol.file.allow=never', '-c', 'protocol.ext.allow=never',
    '-c', 'maintenance.auto=false', '-c', 'gc.auto=0',
    '-c', 'http.extraHeader='
  )
  return [pscustomobject][ordered]@{
    Executable = [string]$resolved.Path
    WorkingDirectory = [IO.Path]::GetFullPath($WorkingDirectory)
    Environment = $environment
    Prefix = [string[]]$prefix
  }
}

function global:Invoke-BorrowingP4tGitRead {
  param(
    $Context,
    [string[]]$Arguments,
    [ValidateSet('text', 'record-nul')][string]$Mode = 'text'
  )
  $invoke = @{
    Executable = [string]$Context.Executable
    ArgumentList = [string[]](@($Context.Prefix) + @($Arguments))
    WorkingDirectory = [string]$Context.WorkingDirectory
    EnvironmentVariables = $Context.Environment
    TimeoutMilliseconds = 30000
    StdOutLimitBytes = 8388608
    StdErrLimitBytes = 1048576
    Stage = 'p4t-source'
    TimeoutReasonCode = 'source-unsafe'
    FailureReasonCode = 'source-unsafe'
  }
  if ($Mode -ceq 'record-nul') { $invoke.AllowStdOutNul = $true }
  return Invoke-BorrowingBoundedProcess @invoke
}

function global:Test-BorrowingP4tTrackedCache {
  param([string]$Root, $Failures)
  try {
    $context = New-BorrowingP4tReadOnlyGitContext $Root
    $probe = Invoke-BorrowingP4tGitRead $context `
      @('-C', $Root, 'rev-parse', '--is-inside-work-tree')
    if ($probe.ExitCode -ne 0) { return }
    if (-not [string]::IsNullOrEmpty($probe.StdErr) -or
        $probe.StdOut.Trim() -cne 'true') { throw 'worktree probe invalid' }
    foreach ($pathspec in @(
        ':(glob)借鉴区/来源/*/*/快照/**',
        ':(glob)借鉴区/来源/*/*/*.local.json')) {
      $tracked = Invoke-BorrowingP4tGitRead $context `
        @('-C', $Root, 'ls-files', '--', $pathspec)
      if ($tracked.ExitCode -ne 0 -or -not [string]::IsNullOrEmpty($tracked.StdErr)) {
        throw 'tracked cache query failed'
      }
      if ($tracked.StdOut.Length -gt 0) {
        Add-BorrowingP4tSourceIssue $Failures '来源 raw/cache 不得被 Git 跟踪'
        return
      }
    }
  }
  catch { Add-BorrowingP4tSourceIssue $Failures 'git ls-files 来源缓存追踪检查失败' }
}

function global:Get-BorrowingP4tAdvertisedOid {
  param([string]$Repository, [string]$ObjectFormat)
  $length = if ($ObjectFormat -ceq 'sha1') { 40 }
    elseif ($ObjectFormat -ceq 'sha256') { 64 }
    else { throw 'Git object format invalid' }
  $path = Join-Path $Repository 'refs\czxt\capture'
  [byte[]]$bytes = Read-BorrowingStableSafeFileBytes $path p4t-source source-unsafe
  $text = (New-Object Text.UTF8Encoding($false, $true)).GetString($bytes)
  if ($text -cnotmatch ('\A[0-9a-f]{' + $length + '}\n\z')) {
    throw 'Git advertised oid invalid'
  }
  return $text.TrimEnd("`n")
}

function global:Test-BorrowingP4tGitSnapshot {
  param($Candidate)
  if ($Candidate.SourceType -cne 'git' -or
      $Candidate.IgnoredCacheState.State -cne 'Healthy') { return $true }
  try {
    $repo = Join-Path $Candidate.CaptureDirectory '快照\repository.git'
    $context = New-BorrowingP4tReadOnlyGitContext $Candidate.CaptureDirectory
    $runner = {
      param($arguments, $mode)
      Invoke-BorrowingP4tGitRead $context ([string[]]$arguments) $mode
    }.GetNewClosure()
    $advertised = Get-BorrowingP4tAdvertisedOid $repo `
      ([string]$Candidate.TypeFacts.ObjectFormat)
    Test-BorrowingGitCache $repo ([string]$Candidate.TypeFacts.ObjectFormat) `
      $advertised ([string]$Candidate.TypeFacts.Commit) `
      ([string]$Candidate.TypeFacts.Tree) $runner
    return $true
  }
  catch { return $false }
}
