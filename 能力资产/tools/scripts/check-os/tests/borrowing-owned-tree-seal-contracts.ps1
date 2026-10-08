$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))
$moduleRoot = Join-Path $repoRoot '能力资产\tools\scripts\borrowing-capture'
. (Join-Path $moduleRoot 'common.ps1')
. (Join-Path $moduleRoot 'file-safety.ps1')
. (Join-Path $moduleRoot 'trusted-file-read.ps1')
. (Join-Path $moduleRoot 'owned-staging.ps1')

$script:Passed = 0

function Assert-Contract {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Invoke-Contract {
  param([string]$Name, [scriptblock]$Body)
  & $Body
  $script:Passed++
  Write-Host ("[PASS] {0}" -f $Name)
}

function New-SealFixture {
  $root = Join-Path ([IO.Path]::GetTempPath()) (
    'czxt-owned-tree-seal-' + [Guid]::NewGuid().ToString('N'))
  [void][IO.Directory]::CreateDirectory((Join-Path $root '借鉴区\来源'))
  $ownership = New-BorrowingOwnedStagingCore ([pscustomobject]@{
      Root = $root
      Request = [pscustomobject]@{ SourceId = 'seal-contract' }
    })
  $directoryPath = Join-Path $ownership.StagingPath 'nested'
  $filePath = Join-Path $directoryPath 'payload.bin'
  $directory = Get-BorrowingOwnedDirectoryAtPath $ownership $directoryPath
  $bytes = [Text.Encoding]::UTF8.GetBytes('sealed-payload')
  $file = New-BorrowingOwnedFileAtPath $ownership $filePath $bytes
  return [pscustomobject]@{
    Root = $root; Ownership = $ownership; Directory = $directory
    File = $file; FilePath = $filePath; Bytes = $bytes
  }
}

function Remove-SealFixture {
  param($Fixture, $Seal)
  if ($null -ne $Seal) {
    try { Close-BorrowingOwnedTreeSeal $Seal } catch { }
  }
  if ($null -ne $Fixture -and $null -ne $Fixture.Ownership) {
    try { Close-BorrowingOwnedStagingLeases $Fixture.Ownership } catch { }
  }
  if ($null -ne $Fixture -and [IO.Directory]::Exists($Fixture.Root)) {
    [IO.Directory]::Delete($Fixture.Root, $true)
  }
}

Invoke-Contract 'Public tree-seal creation, assertion, closure, and exact-removal interfaces' {
  foreach ($name in @(
      'New-BorrowingOwnedTreeSeal', 'Assert-BorrowingOwnedTreeSeal',
      'Close-BorrowingOwnedTreeSeal', 'Remove-BorrowingOwnedTreeSeal'
    )) {
    Assert-Contract ($null -ne (Get-Command $name -CommandType Function `
          -ErrorAction SilentlyContinue)) ("Missing interface: {0}" -f $name)
  }
}

Invoke-Contract 'Creating a seal closes old descendant leases and binds directory and file content' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    Assert-Contract ($null -ne $fixture.Directory.Native) 'Test directory lease was not established'
    Assert-Contract ($null -ne $fixture.File.Native) 'Test file lease was not established'
    $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership `
      $fixture.Ownership.StagingPath

    Assert-Contract ($null -eq $fixture.Directory.Native) 'Old directory lease was not closed'
    Assert-Contract ($null -eq $fixture.File.Native) 'Old file lease was not closed'
    Assert-Contract ($seal.Directories.Count -eq 1) 'Seal directory inventory is not exact'
    Assert-Contract ($seal.Files.Count -eq 1) 'Seal file inventory is not exact'
    $sealedFile = @($seal.Files.Values)[0]
    Assert-Contract ($sealedFile.Sha256 -ceq `
        (Get-BorrowingSha256Hex $fixture.Bytes)) `
      'Seal lacks a streaming SHA-256 digest'
    Assert-Contract ($null -eq $sealedFile.PSObject.Properties['Bytes']) `
      'Seal still retains whole-file bytes in memory'
    Assert-BorrowingOwnedTreeSeal $seal
    $writeFailure = $null
    try { [IO.File]::WriteAllBytes($fixture.FilePath, [byte[]](9, 9, 9)) }
    catch { $writeFailure = $_ }
    Assert-Contract ($null -ne $writeFailure) 'File remained writable while sealed'
  }
  finally { Remove-SealFixture $fixture $seal }
}

Invoke-Contract 'Seal rejects total-byte budget overflow before allocating file handles' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    $script:BorrowingOwnedTreeSealTestLimits = @{
      MaxMembers = [uint64]100
      MaxBytes = [uint64]($fixture.Bytes.Length - 1)
    }
    $failure = $null
    try {
      $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership `
        $fixture.Ownership.StagingPath
    }
    catch { $failure = $_ }
    Assert-Contract ($null -ne $failure) 'Seal did not reject total-byte budget overflow'
    Assert-Contract ($failure.Exception.Data['BorrowingReasonCode'] -ceq `
        'resource-limit') 'Seal resource-limit reason code is unstable'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestLimits = $null
    Remove-SealFixture $fixture $seal
  }
}

Invoke-Contract 'Seal traverses members individually and immediately rejects member-budget overflow' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    $script:BorrowingOwnedTreeSealTestLimits = @{
      MaxMembers = [uint64]1
      MaxBytes = [uint64]536870912
    }
    $failure = $null
    try {
      $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership `
        $fixture.Ownership.StagingPath
    }
    catch { $failure = $_ }
    Assert-Contract ($null -ne $failure) 'Seal did not reject member-budget overflow'
    Assert-Contract ($failure.Exception.Data['BorrowingReasonCode'] -ceq `
        'resource-limit') 'Seal member-limit reason code is unstable'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestLimits = $null
    Remove-SealFixture $fixture $seal
  }
}

Invoke-Contract 'Assert rejects tree members added after sealing' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership `
      $fixture.Ownership.StagingPath
    $unknown = Join-Path $fixture.Ownership.StagingPath 'unknown.txt'
    [IO.File]::WriteAllText($unknown, 'unknown')
    $failure = $null
    try { Assert-BorrowingOwnedTreeSeal $seal }
    catch { $failure = $_ }
    Assert-Contract ($null -ne $failure) 'Added member did not cause the seal assertion to fail'
    Assert-Contract ($failure.Exception.Data['BorrowingReasonCode'] -ceq `
        'source-unsafe') 'Added-member failure reason code is unstable'
  }
  finally { Remove-SealFixture $fixture $seal }
}

Invoke-Contract 'The second full-tree reconciliation during seal creation rejects concurrent additions' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    $script:BorrowingOwnedTreeSealTestInjections = @{
      'after-seal-handles-open-before-reconcile' = {
        param($sealedRoot)
        [IO.File]::WriteAllText((Join-Path $sealedRoot 'raced.txt'), 'raced')
      }
    }
    $failure = $null
    try {
      $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership `
        $fixture.Ownership.StagingPath
    }
    catch { $failure = $_ }
    Assert-Contract ($null -ne $failure) 'Second full-tree reconciliation did not reject a concurrent addition'
    Assert-Contract ([IO.File]::Exists(
        (Join-Path $fixture.Ownership.StagingPath 'raced.txt'))) `
      'Failed seal creation deleted a concurrently added member'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestInjections = $null
    Remove-SealFixture $fixture $seal
  }
}

Invoke-Contract 'Close releases the file write lock held by the seal' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership `
      $fixture.Ownership.StagingPath
    $moveFailure = $null
    try {
      [IO.Directory]::Move($fixture.Directory.Path,
        (Join-Path $fixture.Ownership.StagingPath 'renamed'))
    }
    catch { $moveFailure = $_ }
    Assert-Contract ($null -ne $moveFailure) 'Directory remained renamable while sealed'
    Close-BorrowingOwnedTreeSeal $seal
    [IO.File]::WriteAllBytes($fixture.FilePath, [byte[]](7, 8, 9))
    Assert-Contract ([Convert]::ToBase64String(
        [IO.File]::ReadAllBytes($fixture.FilePath)) -ceq 'BwgJ') `
      'File lock was not released after Close'
    $renamed = Join-Path $fixture.Ownership.StagingPath 'renamed'
    [IO.Directory]::Move($fixture.Directory.Path, $renamed)
    Assert-Contract ([IO.Directory]::Exists($renamed)) `
      'Directory rename lock was not released after Close'
  }
  finally { Remove-SealFixture $fixture $seal }
}

Invoke-Contract 'Remove deletes the complete tree only through the seal ledger and the same handles' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    $stagingPath = $fixture.Ownership.StagingPath
    $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership $stagingPath
    Remove-BorrowingOwnedTreeSeal $seal
    Assert-Contract (-not [IO.Directory]::Exists($stagingPath)) `
      'Seal root directory still exists after Remove'
  }
  finally { Remove-SealFixture $fixture $seal }
}

Invoke-Contract 'Remove preserves unknown data injected after verification and fails' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    $root = $fixture.Ownership.StagingPath
    $unknown = Join-Path $root 'nested\injected-unknown.txt'
    $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership $root
    $script:BorrowingOwnedTreeSealTestInjections = @{
      'after-remove-assert-before-delete' = {
        param($sealedRoot)
        [IO.File]::WriteAllText((Join-Path $sealedRoot `
            'nested\injected-unknown.txt'),
          'must-survive')
      }
    }
    $failure = $null
    try { Remove-BorrowingOwnedTreeSeal $seal }
    catch { $failure = $_ }
    Assert-Contract ($null -ne $failure) 'Remove did not fail after unknown data was injected'
    Assert-Contract ($failure.Exception.Data['BorrowingStage'] -ceq 'cleanup' -and
        $failure.Exception.Data['BorrowingReasonCode'] -ceq 'cleanup-failed') `
      'Remove cleanup failure did not normalize the stage/reason code'
    Assert-Contract ([IO.File]::Exists($unknown)) 'Remove deleted unregistered unknown data'
    Assert-Contract ([IO.File]::ReadAllText($unknown) -ceq 'must-survive') `
      'Remove changed unregistered unknown content'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestInjections = $null
    Remove-SealFixture $fixture $seal
  }
}

Invoke-Contract 'Remove detects and preserves concurrently injected ADS before deletion' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    $root = $fixture.Ownership.StagingPath
    $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership $root
    $script:BorrowingTreeAdsCreated = $false
    $script:BorrowingTreeAdsError = ''
    $script:BorrowingOwnedTreeSealTestInjections = @{
      'after-remove-assert-before-delete' = {
        param($sealedRoot)
        $stream = $null
        try {
          $adsPath = (Join-Path $sealedRoot 'nested\payload.bin') +
            ':injected-unknown'
          $stream = [Czxt.B.NP]::CreateFileW(
            ('\\?\' + $adsPath), [uint32]0x40000000, [uint32]7,
            [IntPtr]::Zero, [uint32]1, [uint32]0x80, [IntPtr]::Zero)
          if ($null -eq $stream -or $stream.IsInvalid) {
            throw (New-Object ComponentModel.Win32Exception(
                [Runtime.InteropServices.Marshal]::GetLastWin32Error()))
          }
          $script:BorrowingTreeAdsCreated = $true
        }
        catch {
          $script:BorrowingTreeAdsError = $_.Exception.ToString()
          throw
        }
        finally { if ($null -ne $stream) { $stream.Dispose() } }
      }
    }
    $failure = $null
    try { Remove-BorrowingOwnedTreeSeal $seal }
    catch { $failure = $_ }
    Assert-Contract $script:BorrowingTreeAdsCreated `
      ('Concurrent ADS injection did not actually occur: ' + $script:BorrowingTreeAdsError)
    Assert-Contract ($null -ne $failure) 'Remove did not fail after ADS injection'
    Assert-Contract ([IO.File]::Exists($fixture.FilePath)) `
      'Remove deleted the primary file containing unregistered ADS'
    Assert-Contract (@(Get-Item -LiteralPath $fixture.FilePath `
          -Stream 'injected-unknown').Count -eq 1) `
      'Remove deleted unregistered ADS'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestInjections = $null
    Remove-SealFixture $fixture $seal
  }
}

Write-Host ("borrowing owned tree seal contracts: {0}/10 passed" -f $script:Passed)
