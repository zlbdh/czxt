$ErrorActionPreference = 'Stop'

$null = . (Join-Path $PSScriptRoot 'borrowing-common.ps1')

function global:Add-P4tIsolationFailure {
  param([Collections.Generic.List[string]]$Failures, [string]$Message)
  if (-not $Failures.Contains($Message)) { [void]$Failures.Add($Message) }
}

function global:Test-P4tIsolationPathInside {
  param([string]$Candidate, [string]$Parent)
  $candidateFull = [IO.Path]::GetFullPath($Candidate).TrimEnd('\', '/')
  $parentFull = [IO.Path]::GetFullPath($Parent).TrimEnd('\', '/')
  return $candidateFull.StartsWith(
    $parentFull + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase)
}

function global:Get-P4tIsolationEncodingInfo {
  param([byte[]]$Bytes, [int]$Length)
  if ($Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
    return [pscustomobject]@{
      Encoding = New-Object Text.UnicodeEncoding($false, $false, $true)
      Offset = 2
    }
  }
  if ($Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
    return [pscustomobject]@{
      Encoding = New-Object Text.UnicodeEncoding($true, $false, $true)
      Offset = 2
    }
  }
  $offset = if ($Length -ge 3 -and $Bytes[0] -eq 0xEF -and
    $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) { 3 } else { 0 }
  return [pscustomobject]@{
    Encoding = New-Object Text.UTF8Encoding($false, $true)
    Offset = $offset
  }
}

function global:Test-P4tIsolationSnapshotEqual {
  param($Expected, $Actual)
  if ($null -eq $Expected -or $null -eq $Actual) { return $false }
  if (-not ([string]$Expected.CanonicalPath).Equals(
      [string]$Actual.CanonicalPath, [StringComparison]::OrdinalIgnoreCase)) { return $false }
  if ([string]$Expected.IdentityKey -cne [string]$Actual.IdentityKey) { return $false }
  if ([string]$Expected.Kind -cne [string]$Actual.Kind) { return $false }
  if ([string]$Expected.Kind -ceq 'File' -and
      [uint64]$Expected.Length -ne [uint64]$Actual.Length) { return $false }
  return $true
}

$null = . (Join-Path $PSScriptRoot 'borrowing-isolation-snapshot.ps1')
$null = . (Join-Path $PSScriptRoot 'borrowing-isolation-budget.ps1')
$null = . (Join-Path $PSScriptRoot 'borrowing-isolation-tree.ps1')
$null = . (Join-Path $PSScriptRoot 'borrowing-isolation-project.ps1')

function global:Test-P4tIsolationTextFile {
  param(
    $ExpectedFile,
    [string]$AppRoot,
    [Collections.Generic.List[string]]$Failures,
    $Budget
  )

  $relative = ([string]$ExpectedFile.CanonicalPath).Substring($AppRoot.Length).TrimStart('\', '/') -replace '\\', '/'
  try {
    $before = Get-BorrowingSafePathInfo -Path $ExpectedFile.CanonicalPath `
      -ExpectedKind File -Stage 'p4t-isolation' -ReasonCode 'unsafe-business-path'
    if (-not (Test-P4tIsolationSnapshotEqual $ExpectedFile $before)) {
      throw 'business file changed before read'
    }
  }
  catch {
    Add-P4tIsolationFailure $Failures ('业务文件检查后改变：' + $relative)
    return
  }
  $maximumBytes = 8MB
  $plannedBytes = if ([uint64]$before.Length -gt [uint64]$maximumBytes) {
    [uint64]65536
  }
  else { [uint64]$before.Length }
  try { Use-P4tIsolationResourceBudget $Budget 1 0 $plannedBytes }
  catch {
    Add-P4tIsolationFailure $Failures ('业务扫描资源预算超限：' + $relative)
    return
  }
  if ([uint64]$before.Length -gt [uint64]$maximumBytes) {
    # 超限文本必须 fail closed；Decoder 的非终结读取可避免 UTF-8 字符恰在采样边界被误判为二进制。
    try {
      $prefixSnapshot = Read-P4tIsolationStablePrefixSnapshot -ExpectedFile $before
      [byte[]]$prefix = $prefixSnapshot.Bytes
      $read = [int]$prefixSnapshot.BytesRead
      if ($read -gt 0) {
        $encodingInfo = Get-P4tIsolationEncodingInfo $prefix $read
        $decoder = $encodingInfo.Encoding.GetDecoder()
        $characters = New-Object char[] $read
        $byteCount = $read - [int]$encodingInfo.Offset
        $characterCount = $decoder.GetChars(
          $prefix, [int]$encodingInfo.Offset, $byteCount, $characters, 0, $false)
        $containsNul = $false
        for ($index = 0; $index -lt $characterCount; $index++) {
          if ($characters[$index] -eq [char]0) { $containsNul = $true; break }
        }
        if (-not $containsNul) {
          Add-P4tIsolationFailure $Failures ('业务文本超出隔离扫描上限：' + $relative)
        }
      }
    }
    catch [Text.DecoderFallbackException] {
      if (-not (Test-P4tIsolationHasNulEvidence $prefix $read)) {
        Add-P4tIsolationFailure $Failures ('业务文本编码无效：' + $relative)
      }
    }
    catch { Add-P4tIsolationFailure $Failures ('业务文本无法安全读取：' + $relative) }
    return
  }

  # 按内容而非扩展名识别文本，避免 HTML、环境文件或无扩展名启动器绕过零依赖扫描。
  try {
    $fullSnapshot = Read-P4tIsolationExpectedFullSnapshot `
      -ExpectedFile $before -MaximumBytes $plannedBytes
    [byte[]]$bytes = $fullSnapshot.Bytes
    $encodingInfo = Get-P4tIsolationEncodingInfo $bytes $bytes.Length
    $text = $encodingInfo.Encoding.GetString(
      $bytes, [int]$encodingInfo.Offset, $bytes.Length - [int]$encodingInfo.Offset)
  }
  catch [Text.DecoderFallbackException] {
    if (-not (Test-P4tIsolationHasNulEvidence $bytes $bytes.Length)) {
      Add-P4tIsolationFailure $Failures ('业务文本编码无效：' + $relative)
    }
    return
  }
  catch {
    Add-P4tIsolationFailure $Failures ('业务文本无法安全读取：' + $relative)
    return
  }
  if ($text.IndexOf([char]0) -ge 0) { return }
  if ($text -match '(?i)(?<![\p{L}\p{N}_])借鉴区(?=[\\/]|["''])') {
    Add-P4tIsolationFailure $Failures ('业务文件直接依赖借鉴区：' + $relative)
  }
}

function global:Test-P4tIsolationBusinessTree {
  param(
    [string]$AppRoot,
    [Collections.Generic.List[string]]$Failures,
    $Budget
  )

  # 构建/运行产物也可能被实际部署或执行，必须扫描；只跳过明确的第三方、VCS、覆盖率与缓存树。
  $excluded = @('.git', 'node_modules', 'coverage', '.cache')
  $pending = New-Object Collections.Generic.Queue[object]
  try {
    $appInfo = Get-BorrowingSafePathInfo -Path $AppRoot -ExpectedKind Directory `
      -Stage 'p4t-isolation' -ReasonCode 'unsafe-business-path'
  }
  catch {
    Add-P4tIsolationFailure $Failures '业务目录不安全'
    return
  }
  $pending.Enqueue($appInfo)
  while ($pending.Count -gt 0) {
    $expectedDirectory = $pending.Dequeue()
    $directory = [string]$expectedDirectory.CanonicalPath
    if ($script:P4tIsolationTestInjections -is [Collections.IDictionary] -and
        $script:P4tIsolationTestInjections.Contains('before-directory-enumeration')) {
      & $script:P4tIsolationTestInjections['before-directory-enumeration'] `
        ([pscustomobject]@{ Path = $directory })
    }
    try {
      $initialInventory = Get-P4tIsolationDirectoryInventory $expectedDirectory $Budget
    }
    catch {
      Add-P4tIsolationFailure $Failures '业务目录无法读取'
      continue
    }
    Invoke-P4tIsolationTestInjection 'after-directory-inventory' `
      ([pscustomobject]@{ Path = $directory })
    foreach ($entry in @($initialInventory.Entries)) {
      if ($entry.IsContainer) {
        if ($excluded -contains $entry.Name.ToLowerInvariant()) { continue }
        $pending.Enqueue($entry.Snapshot)
        continue
      }
      if ($script:P4tIsolationTestInjections -is [Collections.IDictionary] -and
          $script:P4tIsolationTestInjections.Contains('before-file-read')) {
        & $script:P4tIsolationTestInjections['before-file-read'] `
          ([pscustomobject]@{ Path = $entry.Snapshot.CanonicalPath })
      }
      Test-P4tIsolationTextFile -ExpectedFile $entry.Snapshot `
        -AppRoot $AppRoot -Failures $Failures -Budget $Budget
    }
    try {
      $finalInventory = Get-P4tIsolationDirectoryInventory `
        $initialInventory.Directory $Budget
      # 这是扫描窗口首尾一致性，不承诺检查返回后的文件系统不可变化。
      if (-not (Test-P4tIsolationDirectoryInventoryEqual `
          $initialInventory $finalInventory)) {
        throw 'business directory entries changed during scan'
      }
    }
    catch {
      Add-P4tIsolationFailure $Failures ('业务目录扫描期间改变：' + $directory)
    }
  }
}

function global:Invoke-BorrowingP4tIsolationCheck {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)]
    [ValidateSet('template', 'project', 'unknown', 'conflict')][string]$Mode
  )

  $suppliedMode = $Mode.ToLowerInvariant()
  $detectedMode = 'unknown'
  $warnings = New-Object Collections.Generic.List[string]
  $failures = New-Object Collections.Generic.List[string]
  try { $safeRoot = Resolve-BorrowingP4tSafeRoot -Root $Root }
  catch {
    Add-P4tIsolationFailure $failures 'Root 无效'
    return New-BorrowingP4tCheckResult $detectedMode $warnings $failures
  }
  $detectedMode = Get-BorrowingP4tRootMode -Root $safeRoot
  if ($detectedMode -eq 'unknown') {
    Add-P4tIsolationFailure $failures 'Root 缺 marker'
  }
  elseif ($detectedMode -eq 'conflict') {
    Add-P4tIsolationFailure $failures 'Root marker 冲突'
  }
  if ($suppliedMode -cne $detectedMode) {
    Add-P4tIsolationFailure $failures 'RootMode 与传入 Mode 不一致'
  }
  if ($failures.Count -eq 0 -and $detectedMode -eq 'project') {
    $budget = $null
    try { $budget = New-P4tIsolationResourceBudget }
    catch { Add-P4tIsolationFailure $failures '隔离扫描资源预算无效' }
    $resolution = if ($null -ne $budget) {
      Resolve-P4tIsolationAppRoot -Root $safeRoot -Failures $failures -Budget $budget
    } else { $null }
    if ($null -ne $resolution) {
      $excluded = @('.git', 'node_modules', 'coverage', '.cache')
      $baseline = $null
      try {
        $baseline = Get-P4tIsolationTreeSnapshot `
          $resolution.AppRootSnapshot $excluded $budget
      }
      catch { Add-P4tIsolationFailure $failures '业务树基线无法安全建立' }
      if ($null -ne $baseline) {
        Invoke-P4tIsolationTestInjection 'after-tree-baseline' `
          ([pscustomobject]@{ Path = [string]$resolution.AppRoot })
        # 基线、业务扫描、最终树复核均对实际读取独立计量，并共用一次调用预算。
        Test-P4tIsolationBusinessTree -AppRoot $resolution.AppRoot `
          -Failures $failures -Budget $budget
        try {
          $finalTree = Get-P4tIsolationTreeSnapshot $baseline.Root $excluded $budget
          if (-not (Test-P4tIsolationTreeSnapshotEqual $baseline $finalTree)) {
            throw 'business tree changed during scan'
          }
        }
        catch { Add-P4tIsolationFailure $failures '业务树在隔离扫描期间改变' }
      }
      try { Assert-P4tIsolationProjectResolutionStable $resolution $budget }
      catch { Add-P4tIsolationFailure $failures '项目卡在隔离扫描期间改变' }
    }
  }
  return New-BorrowingP4tCheckResult $detectedMode $warnings $failures
}
