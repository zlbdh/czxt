[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
function Write-P4tOversizedBinary {
  param([string]$Path)
  [IO.File]::WriteAllBytes($Path, (New-Object byte[] (8MB + 1)))
}
function New-P4tOversizedMutationRoot {
  param([string]$Name)
  $root = New-ProjectSkeleton $Name
  $early = Join-Path $root 'app\a'
  $late = Join-Path $root 'app\z'
  [void](New-Item -ItemType Directory -Path $early)
  [void](New-Item -ItemType Directory -Path $late)
  $path = Join-Path $early 'payload.bin'
  Write-P4tOversizedBinary $path
  Write-P4tUtf8 (Join-Path $late 'late.js') "export const late = true;`n"
  return [pscustomobject]@{ Root = $root; Path = $path; Late = $late }
}
function Invoke-P4tOversizedMutation {
  param($Fixture, [scriptblock]$Mutation)
  $script:P4tIsolationBudgetMutationRan = $false
  $script:P4tIsolationTestInjections = @{
    'after-directory-inventory' = {
      param($context)
      if (-not $script:P4tIsolationBudgetMutationRan -and
          ([string]$context.Path).Equals(
            $Fixture.Late, [StringComparison]::OrdinalIgnoreCase)) {
        & $Mutation $Fixture.Path
        $script:P4tIsolationBudgetMutationRan = $true
      }
    }
  }
  try { return Invoke-BorrowingP4tIsolationCheck $Fixture.Root project }
  finally { $script:P4tIsolationTestInjections = $null }
}
function Invoke-P4tExpectedFullReadSwapCase {
  param([string]$Name, [ValidateSet('app', 'config')][string]$Kind, [int]$SwapOnCall)
  $root = New-ProjectSkeleton ('isolation-expected-read-' + $Name)
  $target = if ($Kind -eq 'config') {
    Join-Path $root '项目配置\fixture.project.json'
  }
  else {
    $path = Join-Path $root 'app\small.bin'
    Write-P4tUtf8 $path 'safe'
    $path
  }
  $backup = $target + '.expected'
  $script:P4tExpectedReadTarget = $target
  $script:P4tExpectedReadCalls = 0
  $script:P4tExpectedReadSwapRan = $false
  $script:P4tExpectedReadEnteredContent = $false
  $script:P4tIsolationTestInjections = @{
    'before-expected-full-handle-open' = {
      param($context)
      if (([string]$context.Path).Equals(
          $script:P4tExpectedReadTarget, [StringComparison]::OrdinalIgnoreCase)) {
        $script:P4tExpectedReadCalls++
        if ($script:P4tExpectedReadCalls -eq $SwapOnCall) {
          [IO.File]::Move($script:P4tExpectedReadTarget, $backup)
          [IO.File]::WriteAllBytes(
            $script:P4tExpectedReadTarget, (New-Object byte[] (8MB + 1)))
          $script:P4tExpectedReadSwapRan = $true
        }
      }
    }
    'before-expected-full-content-read' = {
      param($context)
      if ($script:P4tExpectedReadSwapRan -and
          ([string]$context.Path).Equals(
          $script:P4tExpectedReadTarget, [StringComparison]::OrdinalIgnoreCase)) {
        $script:P4tExpectedReadEnteredContent = $true
      }
    }
  }
  try { $result = Invoke-BorrowingP4tIsolationCheck $root project }
  finally {
    $script:P4tIsolationTestInjections = $null
    if (Test-Path -LiteralPath $backup -PathType Leaf) {
      [IO.File]::Delete($target)
      [IO.File]::Move($backup, $target)
    }
  }
  return [pscustomobject]@{
    Result = $result; Swapped = $script:P4tExpectedReadSwapRan
    ReadEntered = $script:P4tExpectedReadEnteredContent
  }
}
Initialize-P4tTestFixture
try {
  Import-P4tHelper 'borrowing-isolation.ps1' 'Invoke-BorrowingP4tIsolationCheck'
  Invoke-CzxtContract 'directory inventory charges the budget during lazy enumeration' {
    $snapshotPath = Join-Path $script:P4tModuleRoot 'borrowing-isolation-snapshot.ps1'
    $source = [IO.File]::ReadAllText($snapshotPath, [Text.UTF8Encoding]::new($true))
    Assert-CzxtTrue ($source -match '\.EnumerateFileSystemInfos\(') `
      'directory inventory does not use lazy filesystem enumeration'
    Assert-CzxtTrue ($source -notmatch 'Get-ChildItem') `
      'directory inventory materializes entries before applying its budget'
    foreach ($name in @(
        'borrowing-isolation-tree.ps1', 'borrowing-isolation-project.ps1',
        'borrowing-isolation.ps1')) {
      $consumer = [IO.File]::ReadAllText((Join-Path $script:P4tModuleRoot $name))
      Assert-CzxtTrue ($consumer -notmatch `
          'Read-BorrowingStableSafeFile(?:Snapshot|Bytes)') `
        ($name + ' still uses a full reader without ExpectedSnapshot')
    }
  }
  Invoke-CzxtContract 'isolation rejects a project card above its per-file byte limit' {
    $root = New-ProjectSkeleton 'isolation-budget-config-limit'
    $path = Join-Path $root '项目配置\fixture.project.json'
    $text = [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false))
    Write-P4tUtf8 $path ($text + (' ' * (1MB + 1)))
    $result = Invoke-BorrowingP4tIsolationCheck $root project
    Assert-P4tResult $result 10 'project card per-file byte limit'
  }
  Invoke-CzxtContract 'project card initial and closeout reads share one byte budget' {
    $failRoot = New-ProjectSkeleton 'isolation-budget-config-total-fail'
    $failPath = Join-Path $failRoot '项目配置\fixture.project.json'
    $length = [uint64](Get-Item -LiteralPath $failPath).Length
    $script:P4tIsolationBudgetOverrides = @{
      MaxProjectConfigReadBytes = [uint64](($length * 2) - 1)
    }
    try { $failed = Invoke-BorrowingP4tIsolationCheck $failRoot project }
    finally { $script:P4tIsolationBudgetOverrides = $null }
    Assert-P4tResult $failed 10 'project card shared byte budget below boundary'

    $passRoot = New-ProjectSkeleton 'isolation-budget-config-total-pass'
    $passPath = Join-Path $passRoot '项目配置\fixture.project.json'
    $passLength = [uint64](Get-Item -LiteralPath $passPath).Length
    $script:P4tIsolationBudgetOverrides = @{
      MaxProjectConfigReadBytes = [uint64]($passLength * 2)
    }
    try { $passed = Invoke-BorrowingP4tIsolationCheck $passRoot project }
    finally { $script:P4tIsolationBudgetOverrides = $null }
    Assert-P4tResult $passed 0 'project card shared byte budget exact boundary'
  }
  foreach ($case in @(
      [pscustomobject]@{ Name = 'tree'; Kind = 'app'; Call = 1 },
      [pscustomobject]@{ Name = 'business'; Kind = 'app'; Call = 2 },
      [pscustomobject]@{ Name = 'config'; Kind = 'config'; Call = 1 })) {
    Invoke-CzxtContract ('expected full reader rejects pre-open growth: ' + $case.Name) {
      $actual = Invoke-P4tExpectedFullReadSwapCase `
        $case.Name $case.Kind $case.Call
      Assert-CzxtTrue ([bool]$actual.Swapped) `
        ($case.Name + ' expected-read replacement injection did not run')
      Assert-CzxtTrue (-not [bool]$actual.ReadEntered) `
        ($case.Name + ' entered content read after pre-open replacement')
      Assert-P4tResult $actual.Result 10 ($case.Name + ' expected-read replacement')
    }
  }
  Invoke-CzxtContract 'business scan charges late files before content reads' {
    $root = New-ProjectSkeleton 'isolation-budget-late-files'
    $script:P4tIsolationLateFilesRan = $false
    $script:P4tIsolationTestInjections = @{
      'after-tree-baseline' = {
        param($context)
        Write-P4tUtf8 (Join-Path $context.Path 'a.js') 'a'
        Write-P4tUtf8 (Join-Path $context.Path 'b.js') 'b'
        $script:P4tIsolationLateFilesRan = $true
      }
    }
    $script:P4tIsolationBudgetOverrides = @{ MaxFiles = [uint64]1 }
    try { $result = Invoke-BorrowingP4tIsolationCheck $root project }
    finally {
      $script:P4tIsolationBudgetOverrides = $null
      $script:P4tIsolationTestInjections = $null
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationLateFilesRan) `
      'late-file injection did not run after baseline'
    Assert-CzxtTrue (@($result.Failures) -contains '业务扫描资源预算超限：b.js') `
      'late files were not rejected at the business-read budget point'
  }
  Invoke-CzxtContract 'business scan charges late file bytes before content reads' {
    $root = New-ProjectSkeleton 'isolation-budget-late-bytes'
    $script:P4tIsolationLateBytesRan = $false
    $script:P4tIsolationTestInjections = @{
      'after-tree-baseline' = {
        param($context)
        [IO.File]::WriteAllBytes(
          (Join-Path $context.Path 'late.bin'), (New-Object byte[] (8MB)))
        $script:P4tIsolationLateBytesRan = $true
      }
    }
    $script:P4tIsolationBudgetOverrides = @{ MaxDigestBytes = [uint64]65535 }
    try { $result = Invoke-BorrowingP4tIsolationCheck $root project }
    finally {
      $script:P4tIsolationBudgetOverrides = $null
      $script:P4tIsolationTestInjections = $null
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationLateBytesRan) `
      'late-byte injection did not run after baseline'
    Assert-CzxtTrue (@($result.Failures) -contains '业务扫描资源预算超限：late.bin') `
      'late bytes were not rejected at the business-read budget point'
  }
  Invoke-CzxtContract 'isolation fails closed when the whole-call file budget is exceeded' {
    $root = New-ProjectSkeleton 'isolation-budget-files'
    Write-P4tUtf8 (Join-Path $root 'app\a.js') "export const a = 1;`n"
    Write-P4tUtf8 (Join-Path $root 'app\b.js') "export const b = 2;`n"
    $script:P4tIsolationBudgetOverrides = @{ MaxFiles = [uint64]1 }
    try { $result = Invoke-BorrowingP4tIsolationCheck $root project }
    finally { $script:P4tIsolationBudgetOverrides = $null }
    Assert-P4tResult $result 10 'whole-call file budget exceeded'
  }
  Invoke-CzxtContract 'isolation fails closed when the directory-entry budget is exceeded' {
    $root = New-ProjectSkeleton 'isolation-budget-entries'
    [void](New-Item -ItemType Directory -Path (Join-Path $root 'app\a'))
    [void](New-Item -ItemType Directory -Path (Join-Path $root 'app\b'))
    $script:P4tIsolationBudgetOverrides = @{ MaxDirectoryEntries = [uint64]1 }
    try { $result = Invoke-BorrowingP4tIsolationCheck $root project }
    finally { $script:P4tIsolationBudgetOverrides = $null }
    Assert-P4tResult $result 10 'whole-call directory-entry budget exceeded'
  }
  Invoke-CzxtContract 'isolation fails closed when the digest-byte budget is exceeded' {
    $root = New-ProjectSkeleton 'isolation-budget-digest'
    Write-P4tUtf8 (Join-Path $root 'app\payload.bin') 'ab'
    $script:P4tIsolationBudgetOverrides = @{ MaxDigestBytes = [uint64]1 }
    try { $result = Invoke-BorrowingP4tIsolationCheck $root project }
    finally { $script:P4tIsolationBudgetOverrides = $null }
    Assert-P4tResult $result 10 'whole-call digest-byte budget exceeded'
  }
  Invoke-CzxtContract 'oversized digest budget counts exactly three 64KiB prefixes' {
    $failRoot = New-ProjectSkeleton 'isolation-budget-prefix-fail'
    Write-P4tOversizedBinary (Join-Path $failRoot 'app\payload.bin')
    $script:P4tIsolationBudgetOverrides = @{ MaxDigestBytes = [uint64](196608 - 1) }
    try { $failed = Invoke-BorrowingP4tIsolationCheck $failRoot project }
    finally { $script:P4tIsolationBudgetOverrides = $null }
    Assert-P4tResult $failed 10 'three-prefix digest budget below boundary'

    $passRoot = New-ProjectSkeleton 'isolation-budget-prefix-pass'
    Write-P4tOversizedBinary (Join-Path $passRoot 'app\payload.bin')
    $script:P4tIsolationBudgetOverrides = @{ MaxDigestBytes = [uint64]196608 }
    try { $passed = Invoke-BorrowingP4tIsolationCheck $passRoot project }
    finally { $script:P4tIsolationBudgetOverrides = $null }
    Assert-P4tResult $passed 0 'three-prefix digest budget exact boundary'
  }
  Invoke-CzxtContract 'oversized tail-only mutation stays outside prefix-observable semantics' {
    $fixture = New-P4tOversizedMutationRoot 'isolation-budget-tail'
    $result = Invoke-P4tOversizedMutation $fixture {
      param($path)
      $stream = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Write)
      try {
        [void]$stream.Seek(-1, [IO.SeekOrigin]::End)
        $stream.WriteByte(1)
      }
      finally { $stream.Dispose() }
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationBudgetMutationRan) `
      'oversized tail mutation injection did not run'
    Assert-P4tResult $result 0 'oversized tail-only mutation'
  }
  Invoke-CzxtContract 'oversized prefix mutation is detected' {
    $fixture = New-P4tOversizedMutationRoot 'isolation-budget-prefix-change'
    $result = Invoke-P4tOversizedMutation $fixture {
      param($path)
      $stream = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Write)
      try { [void]$stream.Seek(10, [IO.SeekOrigin]::Begin); $stream.WriteByte(1) }
      finally { $stream.Dispose() }
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationBudgetMutationRan) `
      'oversized prefix mutation injection did not run'
    Assert-P4tResult $result 10 'oversized prefix mutation'
  }
  Invoke-CzxtContract 'oversized length mutation is detected' {
    $fixture = New-P4tOversizedMutationRoot 'isolation-budget-length-change'
    $result = Invoke-P4tOversizedMutation $fixture {
      param($path)
      $stream = New-Object IO.FileStream($path, [IO.FileMode]::Append, [IO.FileAccess]::Write)
      try { $stream.WriteByte(1) } finally { $stream.Dispose() }
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationBudgetMutationRan) `
      'oversized length mutation injection did not run'
    Assert-P4tResult $result 10 'oversized length mutation'
  }
  Invoke-CzxtContract 'oversized identity replacement is detected' {
    $fixture = New-P4tOversizedMutationRoot 'isolation-budget-identity-change'
    $result = Invoke-P4tOversizedMutation $fixture {
      param($path)
      $backup = $path + '.original'
      [IO.File]::Move($path, $backup)
      Write-P4tOversizedBinary $path
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationBudgetMutationRan) `
      'oversized identity mutation injection did not run'
    Assert-P4tResult $result 10 'oversized identity mutation'
  }
}
finally {
  $script:P4tIsolationBudgetOverrides = $null
  $script:P4tIsolationTestInjections = $null
  Remove-P4tTestFixture
}
Complete-CzxtContracts
