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

Invoke-Contract '公开树 seal 的创建、断言、关闭与精确删除接口' {
  foreach ($name in @(
      'New-BorrowingOwnedTreeSeal', 'Assert-BorrowingOwnedTreeSeal',
      'Close-BorrowingOwnedTreeSeal', 'Remove-BorrowingOwnedTreeSeal'
    )) {
    Assert-Contract ($null -ne (Get-Command $name -CommandType Function `
          -ErrorAction SilentlyContinue)) ("缺少接口：{0}" -f $name)
  }
}

Invoke-Contract '创建 seal 会关闭旧后代 lease 并绑定目录与文件内容' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    Assert-Contract ($null -ne $fixture.Directory.Native) '测试目录 lease 未建立'
    Assert-Contract ($null -ne $fixture.File.Native) '测试文件 lease 未建立'
    $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership `
      $fixture.Ownership.StagingPath

    Assert-Contract ($null -eq $fixture.Directory.Native) '旧目录 lease 未关闭'
    Assert-Contract ($null -eq $fixture.File.Native) '旧文件 lease 未关闭'
    Assert-Contract ($seal.Directories.Count -eq 1) 'seal 目录清单不精确'
    Assert-Contract ($seal.Files.Count -eq 1) 'seal 文件清单不精确'
    $sealedFile = @($seal.Files.Values)[0]
    Assert-Contract ($sealedFile.Sha256 -ceq `
        (Get-BorrowingSha256Hex $fixture.Bytes)) `
      'seal 未持有流式 SHA-256 摘要'
    Assert-Contract ($null -eq $sealedFile.PSObject.Properties['Bytes']) `
      'seal 仍将整文件字节常驻内存'
    Assert-BorrowingOwnedTreeSeal $seal
    $writeFailure = $null
    try { [IO.File]::WriteAllBytes($fixture.FilePath, [byte[]](9, 9, 9)) }
    catch { $writeFailure = $_ }
    Assert-Contract ($null -ne $writeFailure) 'seal 期间文件仍可被写入'
  }
  finally { Remove-SealFixture $fixture $seal }
}

Invoke-Contract 'seal 在分配文件句柄前拒绝超出总字节预算' {
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
    Assert-Contract ($null -ne $failure) 'seal 未拒绝超出总字节预算'
    Assert-Contract ($failure.Exception.Data['BorrowingReasonCode'] -ceq `
        'resource-limit') 'seal 资源越界 reason code 不稳定'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestLimits = $null
    Remove-SealFixture $fixture $seal
  }
}

Invoke-Contract 'seal 逐成员遍历并立即拒绝超出成员预算' {
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
    Assert-Contract ($null -ne $failure) 'seal 未拒绝超出成员预算'
    Assert-Contract ($failure.Exception.Data['BorrowingReasonCode'] -ceq `
        'resource-limit') 'seal 成员越界 reason code 不稳定'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestLimits = $null
    Remove-SealFixture $fixture $seal
  }
}

Invoke-Contract 'Assert 会拒绝 seal 后新增的树成员' {
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
    Assert-Contract ($null -ne $failure) '新增成员未使 seal 断言失败'
    Assert-Contract ($failure.Exception.Data['BorrowingReasonCode'] -ceq `
        'source-unsafe') '新增成员失败原因码不稳定'
  }
  finally { Remove-SealFixture $fixture $seal }
}

Invoke-Contract '创建 seal 的第二次全树对账拒绝并发新增成员' {
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
    Assert-Contract ($null -ne $failure) '第二次全树对账未拒绝并发新增成员'
    Assert-Contract ([IO.File]::Exists(
        (Join-Path $fixture.Ownership.StagingPath 'raced.txt'))) `
      'seal 创建失败时删除了并发新增成员'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestInjections = $null
    Remove-SealFixture $fixture $seal
  }
}

Invoke-Contract 'Close 会释放 seal 持有的文件写入锁' {
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
    Assert-Contract ($null -ne $moveFailure) 'seal 期间目录仍可被改名'
    Close-BorrowingOwnedTreeSeal $seal
    [IO.File]::WriteAllBytes($fixture.FilePath, [byte[]](7, 8, 9))
    Assert-Contract ([Convert]::ToBase64String(
        [IO.File]::ReadAllBytes($fixture.FilePath)) -ceq 'BwgJ') `
      'Close 后文件锁未释放'
    $renamed = Join-Path $fixture.Ownership.StagingPath 'renamed'
    [IO.Directory]::Move($fixture.Directory.Path, $renamed)
    Assert-Contract ([IO.Directory]::Exists($renamed)) `
      'Close 后目录改名锁未释放'
  }
  finally { Remove-SealFixture $fixture $seal }
}

Invoke-Contract 'Remove 仅按 seal 账本同句柄删除完整树' {
  $fixture = $null; $seal = $null
  try {
    $fixture = New-SealFixture
    $stagingPath = $fixture.Ownership.StagingPath
    $seal = New-BorrowingOwnedTreeSeal $fixture.Ownership $stagingPath
    Remove-BorrowingOwnedTreeSeal $seal
    Assert-Contract (-not [IO.Directory]::Exists($stagingPath)) `
      'Remove 后 seal 根目录仍存在'
  }
  finally { Remove-SealFixture $fixture $seal }
}

Invoke-Contract 'Remove 验证后注入 unknown 时保留 unknown 并失败' {
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
    Assert-Contract ($null -ne $failure) 'unknown 注入后 Remove 未失败'
    Assert-Contract ($failure.Exception.Data['BorrowingStage'] -ceq 'cleanup' -and
        $failure.Exception.Data['BorrowingReasonCode'] -ceq 'cleanup-failed') `
      'Remove 清理失败未归一化 stage/reason code'
    Assert-Contract ([IO.File]::Exists($unknown)) 'Remove 删除了未登记 unknown'
    Assert-Contract ([IO.File]::ReadAllText($unknown) -ceq 'must-survive') `
      'Remove 改变了未登记 unknown 内容'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestInjections = $null
    Remove-SealFixture $fixture $seal
  }
}

Invoke-Contract 'Remove 在删除前识别并保留并发注入的 ADS' {
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
      ('ADS 并发注入未真实发生: ' + $script:BorrowingTreeAdsError)
    Assert-Contract ($null -ne $failure) 'ADS 注入后 Remove 未失败'
    Assert-Contract ([IO.File]::Exists($fixture.FilePath)) `
      'Remove 删除了带未登记 ADS 的主文件'
    Assert-Contract (@(Get-Item -LiteralPath $fixture.FilePath `
          -Stream 'injected-unknown').Count -eq 1) `
      'Remove 删除了未登记 ADS'
  }
  finally {
    $script:BorrowingOwnedTreeSealTestInjections = $null
    Remove-SealFixture $fixture $seal
  }
}

Write-Host ("borrowing owned tree seal contracts: {0}/10 passed" -f $script:Passed)
