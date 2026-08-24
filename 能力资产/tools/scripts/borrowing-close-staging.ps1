$ErrorActionPreference = 'Stop'

$ownedDirectoryPath = Join-Path $PSScriptRoot 'borrowing-owned-directory.ps1'
if (-not (Test-Path -LiteralPath $ownedDirectoryPath -PathType Leaf)) {
  throw 'close 缺少原子 staging 目录 helper'
}
. $ownedDirectoryPath
$ownedFilePath = Join-Path $PSScriptRoot 'borrowing-owned-file.ps1'
if (-not (Test-Path -LiteralPath $ownedFilePath -PathType Leaf)) {
  throw 'close 缺少原子 staging 文件 helper'
}
. $ownedFilePath

function Invoke-BctStagingTestInjection {
  param([string]$Name, $Context)
  if ($script:BctTestInjections -is [Collections.IDictionary] -and
      $script:BctTestInjections.Contains($Name)) {
    & $script:BctTestInjections[$Name] $Context
  }
}

function Write-BctOwnedFile {
  param($Directory, [string]$LeafName, [byte[]]$Bytes, [switch]$RetainLease)
  $path = [IO.Path]::GetFullPath((Join-Path $Directory.CanonicalPath $LeafName))
  $owned = $null
  $complete = $false
  try {
    Invoke-BctStagingTestInjection 'before-staging-owned-file-write' `
      ([pscustomobject]@{ Path = $Path; Bytes = $Bytes })
    $owned = New-BctOwnedFileRelative $Directory $LeafName $Bytes
    # 相对创建的首文件先把目录变为非空，再复核目录仍不是 reparse；
    # 任何原地 reparse 竞态至此只能失败，且尚未发生按路径读取。
    Assert-BctOwnedDirectoryLease $Directory
    Invoke-BctStagingTestInjection 'before-staging-owned-file-snapshot' `
      ([pscustomobject]@{ Path = $owned.Path; Owned = $owned })
    Assert-BctOwnedFileLease $owned
    $result = [pscustomobject]@{
      Path = $owned.Path
      IdentityKey = $owned.IdentityKey
      Length = [uint64]$owned.Length
      Bytes = [byte[]]$owned.Bytes
      Native = if ($RetainLease) { $owned.Native } else { $null }
    }
    if (-not $RetainLease) { Close-BctOwnedFileLease $owned }
    $complete = $true
    return $result
  }
  finally {
    if (-not $complete -and $null -ne $owned) {
      try {
        if ($null -ne $owned.Native) { Remove-BctOwnedFileLease $owned }
      }
      catch {
        throw ('close staging 新建文件失败且补偿失败：' + $_.Exception.Message)
      }
    }
  }
}

function New-BctStaging {
  param(
    $ItemRoot, [byte[]]$OriginalBytes, [byte[]]$CandidateBytes,
    [AllowNull()][object]$AttemptedPath = $null
  )
  $parent = if ($ItemRoot -is [string]) {
    Get-BorrowingSafePathInfo ([string]$ItemRoot) Directory close source-unsafe
  }
  else { $ItemRoot }
  Assert-BciCondition ($null -ne $parent -and
      -not [string]::IsNullOrWhiteSpace([string]$parent.CanonicalPath) -and
      -not [string]::IsNullOrWhiteSpace([string]$parent.IdentityKey)) `
    'close staging 事项父目录快照无效'
  $leafName = '.staging-close-' + [guid]::NewGuid().ToString('N')
  $path = [IO.Path]::GetFullPath((Join-Path $parent.CanonicalPath $leafName))
  if ($null -ne $AttemptedPath) {
    Assert-BciCondition ($null -ne $AttemptedPath.PSObject.Properties['Value']) `
      'close staging AttemptedPath 必须含可写 Value'
    $AttemptedPath.Value = $path
  }
  $directory = $null
  $original = $null
  $candidate = $null
  try {
    Invoke-BctStagingTestInjection 'before-staging-directory-create' `
      ([pscustomobject]@{ Path = $path })
    $directory = New-BctOwnedDirectory $parent $leafName
    Invoke-BctStagingTestInjection 'after-staging-directory-created' `
      ([pscustomobject]@{
          Path = $directory.CanonicalPath
          IdentityKey = $directory.IdentityKey
        })
    $original = Write-BctOwnedFile $directory '原活动卡.bin' $OriginalBytes `
      -RetainLease
    Invoke-BctStagingTestInjection 'after-staging-original-guard-created' `
      ([pscustomobject]@{
          Path = $directory.CanonicalPath
          Directory = $directory
          Original = $original
        })
    Assert-BctOwnedDirectoryLease $directory
    $candidate = Write-BctOwnedFile $directory '借鉴卡.md' $CandidateBytes
    return [pscustomobject]@{
      Path = $directory.CanonicalPath; IdentityKey = $directory.IdentityKey
      Directory = $directory
      Original = $original; Candidate = $candidate; State = 'recoverable'
    }
  }
  catch {
    $creationFailure = $_
    $cleanupFailures = New-Object Collections.Generic.List[string]
    foreach ($owned in @($candidate, $original)) {
      if ($null -ne $owned) {
        try {
          if ($null -ne $owned.Native) { Remove-BctOwnedFileLease $owned }
          elseif ([IO.File]::Exists([string]$owned.Path)) {
            Remove-BsiBoundOwnedFile $owned 'close staging 创建失败补偿 '
          }
        }
        catch { $cleanupFailures.Add($_.Exception.Message) }
      }
    }
    if ($null -ne $directory) {
      try { Remove-BctOwnedDirectory $directory }
      catch { $cleanupFailures.Add($_.Exception.Message) }
      finally { Close-BctOwnedDirectoryLease $directory }
    }
    if ($cleanupFailures.Count -gt 0) {
      throw ('close staging 创建失败且补偿失败；path=' + $path +
        '；原因=' + ($cleanupFailures -join ' / '))
    }
    throw $creationFailure
  }
}

function Set-BctCandidateBytes {
  param($Staging, [byte[]]$Bytes)
  $current = Get-BsiStableSnapshot $Staging.Candidate.Path
  Assert-BsiSnapshotUnchanged $Staging.Candidate $current
  Invoke-BctStagingTestInjection 'before-staging-candidate-update' `
    ([pscustomobject]@{
        Staging = $Staging
        Current = $current
        Bytes = $Bytes
      })
  $temporary = New-BsiTemporaryFile $Staging.Path $Bytes
  try {
    $updated = Invoke-BsiConditionalReplace $temporary $current.Path $current $Bytes
    $temporary = $null
    $Staging.Candidate = $updated
  }
  finally { Remove-BsiOwnedTemporaryFile $temporary }
  Assert-BciCondition (Test-BcvBytesEqual $updated.Bytes $Bytes) '失败候选写入不一致'
}

function Restore-BctStagingFiles {
  param($Staging, [byte[]]$OriginalBytes, [byte[]]$FailureCandidateBytes)
  Assert-BctOwnedDirectoryLease $Staging.Directory
  Assert-BctOwnedFileLease $Staging.Original
  $directory = Get-BorrowingSafePathInfo $Staging.Path Directory rollback source-unsafe
  Assert-BciCondition ($directory.IdentityKey -ceq $Staging.IdentityKey) `
    'rollback staging 身份改变'
  $expected = @{
    '原活动卡.bin' = [pscustomobject]@{ Property = 'Original'; Bytes = $OriginalBytes }
    '借鉴卡.md' = [pscustomobject]@{ Property = 'Candidate'; Bytes = $FailureCandidateBytes }
  }
  foreach ($entry in @(Get-ChildItem -LiteralPath $directory.CanonicalPath -Force)) {
    Assert-BciCondition (-not $entry.PSIsContainer -and $expected.Contains($entry.Name)) `
      'rollback staging 含未知成员'
  }
  foreach ($name in @('原活动卡.bin', '借鉴卡.md')) {
    $spec = $expected[$name]
    $owned = $Staging.($spec.Property)
    $path = Join-Path $directory.CanonicalPath $name
    Assert-BciCondition (Test-BsiSamePath $path $owned.Path) `
      'rollback staging 受信路径改变'
    if ($spec.Property -ceq 'Original') {
      Assert-BctOwnedFileLease $owned
      Assert-BciCondition ((Test-BsiSamePath $path $owned.Path) -and
          [uint64]$owned.Length -eq [uint64]$spec.Bytes.LongLength -and
          (Test-BcvBytesEqual $owned.Bytes $spec.Bytes)) `
        'rollback staging 原活动卡 guard 改变'
      $current = $owned
    }
    elseif (Test-Path -LiteralPath $path -PathType Leaf) {
      $current = Get-BsiStableSnapshot $path
      Assert-BciCondition ($current.IdentityKey -ceq $owned.IdentityKey -and
          (Test-BcvBytesEqual $current.Bytes $spec.Bytes)) `
        'rollback staging 受信文件改变'
    }
    else {
      Assert-BciCondition (-not (Test-Path -LiteralPath $path)) `
        'rollback staging 受信路径类型改变'
      Assert-BciCondition ($spec.Property -cne 'Original') `
        'rollback staging 原活动卡 guard 丢失'
      $current = Write-BctOwnedFile $Staging.Directory $name $spec.Bytes
    }
    $Staging.($spec.Property) = $current
  }
}

function Remove-BctStaging {
  param($Staging)
  Assert-BctOwnedDirectoryLease $Staging.Directory
  $directory = Get-BorrowingSafePathInfo $Staging.Path Directory cleanup source-unsafe
  Assert-BciCondition ($directory.IdentityKey -ceq $Staging.IdentityKey) `
    'close staging 身份改变'
  $entries = @(Get-ChildItem -LiteralPath $directory.CanonicalPath -Force)
  Assert-BciCondition ($entries.Count -eq 2) 'close staging 含未知成员'
  Remove-BsiBoundOwnedFile $Staging.Candidate 'close staging 候选文件 '
  Remove-BctOwnedFileLease $Staging.Original
  $Staging.State = 'content-deleted'
  try {
    # 2026-07-20 by Codex — 清理失败必须在目录删除前保留可恢复注入点。
    if ($script:BctTestInjections -is [Collections.IDictionary] -and
        $script:BctTestInjections.Contains('after-staging-owned-files-deleted')) {
      & $script:BctTestInjections['after-staging-owned-files-deleted'] `
        ([pscustomobject]@{ Staging = $Staging; Directory = $directory })
    }
    Invoke-BctStagingTestInjection 'before-staging-directory-delete' `
      ([pscustomobject]@{ Staging = $Staging; Directory = $directory })
    Remove-BctOwnedDirectory $Staging.Directory
    $Staging.State = 'removed'
  }
  catch {
    Close-BctStagingLeases $Staging
    throw
  }
}

function Close-BctStagingLeases {
  param($Staging)
  if ($null -eq $Staging) { return }
  if ($null -ne $Staging.Original) {
    Close-BctOwnedFileLease $Staging.Original
  }
  if ($null -ne $Staging.Directory) {
    Close-BctOwnedDirectoryLease $Staging.Directory
  }
}
