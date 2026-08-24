$ErrorActionPreference = 'Stop'

function global:Stop-BorrowingGitRunnerFailure {
  param([string]$Stage, [string]$ReasonCode, [string]$Reason)
  Throw-BorrowingFailure -Stage $Stage -ReasonCode $ReasonCode -Reason $Reason
}

function global:Resolve-BorrowingGitExecutable {
  $failure = {
    Stop-BorrowingGitRunnerFailure preflight missing-trusted-component `
      'trusted Git capability is unavailable'
  }
  try {
    $command = Get-Command git.exe -CommandType Application -ErrorAction Stop | `
      Select-Object -First 1
    $path = [IO.Path]::GetFullPath([string]$command.Source)
    if (-not [IO.Path]::IsPathRooted($path) -or
        -not (Test-Path -LiteralPath $path -PathType Leaf)) { & $failure }

    $environment = New-BorrowingProcessEnvironment -RemovePrefixes @('GIT_') `
      -RemoveNames @('SSH_ASKPASS', 'SSH_ASKPASS_REQUIRE') `
      -Overrides @{ LC_ALL = 'C'; LANG = 'C'; GIT_TERMINAL_PROMPT = '0' }
    $result = Invoke-BorrowingBoundedProcess -Executable $path `
      -ArgumentList @('--version') -WorkingDirectory (Split-Path -Parent $path) `
      -EnvironmentVariables $environment -TimeoutMilliseconds 30000 `
      -StdOutLimitBytes 1048576 -StdErrLimitBytes 1048576 -Stage preflight `
      -TimeoutReasonCode missing-trusted-component `
      -FailureReasonCode missing-trusted-component
    if ($result.ExitCode -ne 0 -or -not [string]::IsNullOrEmpty($result.StdErr) -or
        $result.StdOut -cnotmatch `
          '\Agit version ([0-9]+(?:\.[0-9]+){2,3})(?:[^\r\n]*)?\r?\n?\z') {
      & $failure
    }
    $version = [Version]$Matches[1]
    if ($version -lt [Version]'2.43.0') { & $failure }
    return [pscustomobject][ordered]@{ Path = $path; Version = $version }
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    & $failure
  }
}

function global:New-BorrowingGitRunner {
  param(
    [Parameter(Mandatory, Position = 0)][string]$ExecutablePath,
    [Parameter(Mandatory, Position = 1)][string]$StagingPath
  )
  try {
    $executable = [IO.Path]::GetFullPath($ExecutablePath)
    $staging = [IO.Path]::GetFullPath($StagingPath).TrimEnd('\')
  }
  catch {
    Stop-BorrowingGitRunnerFailure preflight missing-trusted-component `
      'Git runner path is invalid'
  }
  if (-not [IO.Path]::IsPathRooted($executable) -or
      -not (Test-Path -LiteralPath $executable -PathType Leaf) -or
      -not (Test-Path -LiteralPath $staging -PathType Container)) {
    Stop-BorrowingGitRunnerFailure preflight missing-trusted-component `
      'Git runner path is unavailable'
  }

  $runnerRoot = Join-Path $staging 'git-runner-root'
  $workingDirectory = Join-Path $runnerRoot 'cwd'
  $isolatedHome = Join-Path $staging 'git-runner-home'
  $trustedEmpty = Join-Path $staging 'git-trusted-empty'
  foreach ($directory in @(
      $runnerRoot, $workingDirectory, $isolatedHome, $trustedEmpty
    )) {
    if (Test-Path -LiteralPath $directory -PathType Leaf) {
      Stop-BorrowingGitRunnerFailure preflight missing-trusted-component `
        'Git runner directory conflicts with a file'
    }
    [void](New-Item -ItemType Directory -Path $directory -Force)
  }

  $environment = New-BorrowingProcessEnvironment -RemovePrefixes @('GIT_') `
    -RemoveNames @('SSH_ASKPASS', 'SSH_ASKPASS_REQUIRE') -Overrides ([ordered]@{
      GIT_TERMINAL_PROMPT = '0'; GIT_CONFIG_NOSYSTEM = '1'
      GIT_CONFIG_GLOBAL = 'NUL'; GIT_CONFIG_SYSTEM = 'NUL'
      GIT_LFS_SKIP_SMUDGE = '1'; GIT_PROTOCOL_FROM_USER = '0'
      GIT_ALLOW_PROTOCOL = 'https'; GIT_NO_REPLACE_OBJECTS = '1'
      GIT_OPTIONAL_LOCKS = '0'; GIT_CEILING_DIRECTORIES = $runnerRoot
      LC_ALL = 'C'; LANG = 'C'; HOME = $isolatedHome
      USERPROFILE = $isolatedHome; XDG_CONFIG_HOME = $isolatedHome
    })
  $prefix = @(
    '--no-pager', '-c', 'credential.helper=', '-c', 'core.askPass=',
    '-c', ('core.hooksPath=' + $trustedEmpty),
    '-c', 'filter.lfs.clean=', '-c', 'filter.lfs.smudge=',
    '-c', 'filter.lfs.process=', '-c', 'filter.lfs.required=false',
    '-c', 'submodule.recurse=false', '-c', 'fetch.recurseSubmodules=false',
    '-c', 'protocol.file.allow=never', '-c', 'protocol.ext.allow=never',
    '-c', 'maintenance.auto=false', '-c', 'gc.auto=0',
    '-c', 'http.sslVerify=true', '-c', 'http.followRedirects=false',
    '-c', 'http.extraHeader='
  )
  return [pscustomobject][ordered]@{
    Schema = 'czxt-borrowing-git-runner/v1'; ExecutablePath = $executable
    RunnerRoot = $runnerRoot; WorkingDirectory = $workingDirectory
    Home = $isolatedHome; TrustedEmptyDirectory = $trustedEmpty
    Environment = $environment; ArgvPrefix = [string[]]$prefix
    TimeoutMilliseconds = 300000; StdOutLimitBytes = 67108864
    StdErrLimitBytes = 67108864
  }
}

function global:New-BorrowingGitProcessSpec {
  param(
    [Parameter(Mandatory, Position = 0)]$Runner,
    [Parameter(Mandatory, Position = 1)][string[]]$Arguments,
    [Parameter(Position = 2)][ValidateSet('text', 'record-nul')]
    [string]$StdOutMode = 'text'
  )
  if ($null -eq $Runner -or $Runner.Schema -cne 'czxt-borrowing-git-runner/v1' -or
      $null -eq $Arguments) {
    Stop-BorrowingGitRunnerFailure capture capture-failed `
      'Git runner invocation is invalid'
  }
  foreach ($argument in $Arguments) {
    if ($null -eq $argument -or ([string]$argument).IndexOf([char]0) -ge 0) {
      Stop-BorrowingGitRunnerFailure capture capture-failed `
        'Git argument is invalid'
    }
  }
  return [ordered]@{
    Executable = [string]$Runner.ExecutablePath
    ArgumentList = [string[]](@($Runner.ArgvPrefix) + @($Arguments))
    WorkingDirectory = [string]$Runner.WorkingDirectory
    EnvironmentVariables = $Runner.Environment
    TimeoutMilliseconds = [int]$Runner.TimeoutMilliseconds
    StdOutLimitBytes = [int]$Runner.StdOutLimitBytes
    StdErrLimitBytes = [int]$Runner.StdErrLimitBytes
    AllowStdOutNul = ($StdOutMode -ceq 'record-nul')
    Stage = 'capture'; TimeoutReasonCode = 'resource-limit'
    FailureReasonCode = 'capture-failed'
  }
}

function global:Invoke-BorrowingGitRunner {
  param(
    [Parameter(Mandatory, Position = 0)]$Runner,
    [Parameter(Mandatory, Position = 1)][string[]]$Arguments,
    [Parameter(Position = 2)][ValidateSet('text', 'record-nul')]
    [string]$StdOutMode = 'text'
  )
  $spec = New-BorrowingGitProcessSpec $Runner $Arguments $StdOutMode
  return Invoke-BorrowingBoundedProcess @spec
}
