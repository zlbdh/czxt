$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function Import-BorrowingGitInputTestModules {
  Import-BorrowingCaptureModules @('git', 'common')
  foreach ($name in @('ConvertTo-BorrowingGitLocator', 'ConvertTo-BorrowingGitRef')) {
    Assert-BorrowingCommandExists $name
  }
}

function Import-BorrowingGitRunnerTestModules {
  Import-BorrowingCaptureModules @('git-runner', 'process', 'file-safety', 'common')
  foreach ($name in @(
      'Resolve-BorrowingGitExecutable', 'New-BorrowingGitRunner',
      'New-BorrowingGitProcessSpec', 'Invoke-BorrowingGitRunner'
    )) { Assert-BorrowingCommandExists $name }
}

function Import-BorrowingGitCaptureTestModules {
  Import-BorrowingCaptureModules @(
    'git', 'git-runner', 'process', 'file-safety', 'common'
  )
  foreach ($name in @('Invoke-BorrowingGitCapture', 'Test-BorrowingGitCache')) {
    Assert-BorrowingCommandExists $name
  }
}

function Invoke-BorrowingFixtureGit {
  param([string[]]$Arguments, [hashtable]$Environment = @{})
  $old = @{}
  $fixed = @{
    GIT_CONFIG_NOSYSTEM = '1'; GIT_CONFIG_GLOBAL = 'NUL'; GIT_CONFIG_SYSTEM = 'NUL'
    GIT_TERMINAL_PROMPT = '0'; GIT_OPTIONAL_LOCKS = '0'; LC_ALL = 'C'; LANG = 'C'
  }
  foreach ($key in $Environment.Keys) { $fixed[$key] = [string]$Environment[$key] }
  try {
    foreach ($key in $fixed.Keys) {
      $old[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
      [Environment]::SetEnvironmentVariable($key, $fixed[$key], 'Process')
    }
    $output = @(& git @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
  }
  finally {
    foreach ($key in $fixed.Keys) {
      [Environment]::SetEnvironmentVariable($key, $old[$key], 'Process')
    }
  }
  if ($exitCode -ne 0) {
    throw ('fixture git failed ({0}): git {1}; output={2}' -f `
        $exitCode, ($Arguments -join ' '), ($output -join "`n"))
  }
  return @($output)
}

function New-BorrowingGitRepositoryFixture {
  param([string]$Name, [ValidateSet('sha1', 'sha256')][string]$ObjectFormat = 'sha1')
  $base = Join-Path $script:BorrowingCaptureFixtureRoot $Name
  $seed = Join-Path $base 'seed'
  $origin = Join-Path $base 'origin.git'
  [void](New-Item -ItemType Directory -Path $base -Force)
  Invoke-BorrowingFixtureGit @(
    '-C', $base, 'init', '--quiet', '--initial-branch=main',
    ('--object-format=' + $ObjectFormat), 'seed'
  ) | Out-Null
  Write-CzxtNoBomText (Join-Path $seed 'README.md') "fixture`n"
  Invoke-BorrowingFixtureGit @('-C', $seed, 'add', '--', 'README.md') | Out-Null
  $identity = @(
    '-c', 'user.name=CZXT Fixture', '-c', 'user.email=fixture@example.invalid',
    '-c', 'commit.gpgsign=false'
  )
  $dates = @{
    GIT_AUTHOR_DATE = '2026-07-19T01:02:03Z'
    GIT_COMMITTER_DATE = '2026-07-19T01:02:03Z'
  }
  Invoke-BorrowingFixtureGit (@('-C', $seed) + $identity + @(
      'commit', '--quiet', '-m', 'fixture main'
    )) $dates | Out-Null
  $mainCommit = (@(Invoke-BorrowingFixtureGit @('-C', $seed, 'rev-parse', 'HEAD')))[0].Trim()
  Invoke-BorrowingFixtureGit (@('-C', $seed) + $identity + @(
      'tag', '-a', 'v1.0.0', '-m', 'fixture tag'
    )) @{ GIT_COMMITTER_DATE = '2026-07-19T01:03:03Z' } | Out-Null

  Invoke-BorrowingFixtureGit @('-C', $seed, 'switch', '--quiet', '-c', 'detected') | Out-Null
  Write-CzxtNoBomText (Join-Path $seed '.gitattributes') "*.lfs filter=lfs`n"
  Write-CzxtNoBomText (Join-Path $seed 'asset.lfs') `
    "version https://git-lfs.github.com/spec/v1`noid sha256:0000000000000000000000000000000000000000000000000000000000000000`nsize 0`n"
  Invoke-BorrowingFixtureGit @('-C', $seed, 'add', '--', '.gitattributes', 'asset.lfs') | Out-Null
  Invoke-BorrowingFixtureGit @(
    '-C', $seed, 'update-index', '--add', '--cacheinfo',
    ('160000,' + $mainCommit + ',vendor/submodule')
  ) | Out-Null
  Invoke-BorrowingFixtureGit (@('-C', $seed) + $identity + @(
      'commit', '--quiet', '-m', 'fixture detected'
    )) $dates | Out-Null

  Invoke-BorrowingFixtureGit @('-C', $seed, 'switch', '--quiet', 'main') | Out-Null
  Invoke-BorrowingFixtureGit @('-C', $seed, 'switch', '--quiet', '-c', 'unsafe') | Out-Null
  $blobPath = Join-Path $base 'symlink-blob.txt'
  Write-CzxtNoBomText $blobPath 'outside-target'
  $blobOid = (@(Invoke-BorrowingFixtureGit @('-C', $seed, 'hash-object', '-w', $blobPath)))[0].Trim()
  Invoke-BorrowingFixtureGit @(
    '-C', $seed, 'update-index', '--add', '--cacheinfo',
    ('120000,' + $blobOid + ',unsafe-link')
  ) | Out-Null
  Invoke-BorrowingFixtureGit (@('-C', $seed) + $identity + @(
      'commit', '--quiet', '-m', 'fixture unsafe'
    )) $dates | Out-Null
  Invoke-BorrowingFixtureGit @('-C', $seed, 'switch', '--quiet', 'main') | Out-Null
  Invoke-BorrowingFixtureGit @('-C', $base, 'clone', '--quiet', '--bare', '--no-local', $seed, 'origin.git') | Out-Null
  return [pscustomobject]@{
    Base = $base; Seed = $seed; Origin = $origin; ObjectFormat = $ObjectFormat
    LogicalLocator = ('https://fixture.invalid/' + $Name + '.git')
    MainCommit = $mainCommit
  }
}

function New-BorrowingOfflineGitAdapter {
  param([string]$LogicalLocator, [string]$OriginPath, $Trace)
  $logical = $LogicalLocator
  $origin = [IO.Path]::GetFullPath($OriginPath)
  $traceRef = $Trace
  $body = {
    param([string[]]$LogicalArguments, [string]$StdOutMode)
    [void]$traceRef.Add(($LogicalArguments -join [char]0x1F))
    $actual = @()
    $mapped = $false
    foreach ($argument in $LogicalArguments) {
      if ($argument -ceq $logical) {
        $actual += $origin
        $mapped = $true
      }
      else { $actual += $argument }
    }
    if (-not $mapped -and @($LogicalArguments | Where-Object {
          $_ -match '^https://fixture\.invalid/'
        }).Count -gt 0) {
      throw 'unmapped fixture locator'
    }
    $environment = New-BorrowingProcessEnvironment -RemovePrefixes @('GIT_') `
      -RemoveNames @('SSH_ASKPASS', 'SSH_ASKPASS_REQUIRE') `
      -Overrides @{ GIT_ALLOW_PROTOCOL = 'file'; GIT_TERMINAL_PROMPT = '0'; LC_ALL = 'C'; LANG = 'C' }
    $arguments = @(
      '--no-pager', '-c', 'protocol.file.allow=always', '-c', 'credential.helper=',
      '-c', 'core.hooksPath=NUL', '-c', 'filter.lfs.smudge=', '-c', 'submodule.recurse=false'
    ) + $actual
    return Invoke-BorrowingBoundedProcess -Executable (Get-Command git).Source `
      -ArgumentList $arguments -WorkingDirectory $script:BorrowingCaptureFixtureRoot `
      -EnvironmentVariables $environment -TimeoutMilliseconds 30000 `
      -StdOutLimitBytes 8388608 -StdErrLimitBytes 8388608 `
      -AllowStdOutNul:($StdOutMode -eq 'record-nul') `
      -Stage capture -TimeoutReasonCode resource-limit -FailureReasonCode capture-failed
  }
  return $body.GetNewClosure()
}
