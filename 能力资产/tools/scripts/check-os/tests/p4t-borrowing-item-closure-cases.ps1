[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-item-test-support.ps1')

function New-P4tItemClosureCase {
  param([string]$Name)
  $root = New-ProjectSkeleton ('item-closure-' + $Name)
  $source = New-P4tSourceCapture $root local 'source-item'
  Add-Member -InputObject $source -NotePropertyName Permissions `
    -NotePropertyValue ([pscustomobject]@{ ReuseScope = 'adapt-internal-approved' }) -Force
  return [pscustomobject]@{
    Name = $Name; Root = $root; Source = $source
    SourceState = New-P4tSourceState @($source); Item = $null
  }
}

Initialize-P4tTestFixture
try {
  $cases = @()
  $case = New-P4tItemClosureCase 'adopt-target-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-no-target' `
    -Bindings @($case.Source) -Status closed -Decision adopt -IncludeTarget $false -Seal $true
  $cases += $case
  $case = New-P4tItemClosureCase 'adapt-difference-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-no-diff' `
    -Bindings @($case.Source) -Status closed -Decision adapt -IncludeDifference $false -Seal $true
  $cases += $case
  $case = New-P4tItemClosureCase 'fresh-evidence-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-no-evidence' `
    -Bindings @($case.Source) -Status closed -Decision adapt -IncludeFreshEvidence $false -Seal $true
  $cases += $case
  $case = New-P4tItemClosureCase 'implementation-record-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-no-implementation' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    '- 已在 `app/borrowed.txt` 完成本地化实施。', '- 当前尚未实施。')
  $cases += $case
  $case = New-P4tItemClosureCase 'reject-evidence-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-reject-no-evidence' `
    -Bindings @($case.Source) -Status closed -Decision reject -IncludeRejectEvidence $false -Seal $true
  $cases += $case
  $case = New-P4tItemClosureCase 'reject-reason-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-reject-no-reason' `
    -Bindings @($case.Source) -Status closed -Decision reject -IncludeRejectReason $false -Seal $true
  $cases += $case
  $case = New-P4tItemClosureCase 'closed-seal-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-no-seal' `
    -Bindings @($case.Source) -Status closed -Decision adapt
  $cases += $case
  $case = New-P4tItemClosureCase 'active-seal-present'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-active-seal' @($case.Source)
  [void](Set-P4tFixtureSeal $case.Item.CardPath)
  $cases += $case

  $case = New-P4tItemClosureCase 'target-file-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-target-missing' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  Remove-Item -LiteralPath (Join-Path $case.Root 'app\borrowed.txt') -Force
  $cases += $case

  $case = New-P4tItemClosureCase 'target-is-directory'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-target-directory' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  $targetPath = Join-Path $case.Root 'app\borrowed.txt'
  Remove-Item -LiteralPath $targetPath -Force
  [void](New-Item -ItemType Directory -Path $targetPath)
  $cases += $case

  $case = New-P4tItemClosureCase 'target-through-reparse'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-target-reparse' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  $outsideTarget = Join-Path $script:P4tFixtureRoot 'closure-target-reparse'
  [void](New-Item -ItemType Directory -Path $outsideTarget -Force)
  Write-P4tUtf8 (Join-Path $outsideTarget 'borrowed.txt') "linked target`n"
  $targetLink = Join-Path $case.Root 'app\linked-target'
  [void](New-P4tJunction $targetLink $outsideTarget)
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    '| app/borrowed.txt | development-pm | L1 | ADR-039 |',
    '| app/linked-target/borrowed.txt | development-pm | L1 | ADR-039 |')
  [void](Set-P4tFixtureSeal $case.Item.CardPath)
  $cases += $case

  $case = New-P4tItemClosureCase 'target-inside-borrowing-zone'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-target-borrowing' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  $itemRoot = Split-Path -Parent $case.Item.CardPath
  $borrowTarget = Join-Path $itemRoot '证据\implementation.txt'
  Write-P4tUtf8 $borrowTarget "not a delivery target`n"
  $relativeTarget = '借鉴区/事项/' + $case.Item.BorrowId + '/证据/implementation.txt'
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    '| app/borrowed.txt | development-pm | L1 | ADR-039 |',
    ('| ' + $relativeTarget + ' | operating-system-pm | L1 | ADR-039 |'))
  [void](Set-P4tFixtureSeal $case.Item.CardPath)
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-file-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-evidence-file-missing' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  Remove-Item -LiteralPath (Join-Path (Split-Path -Parent $case.Item.CardPath) `
      '证据\验证摘要.md') -Force
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-is-directory'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-evidence-directory' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  $evidencePath = Join-Path (Split-Path -Parent $case.Item.CardPath) '证据\验证摘要.md'
  Remove-Item -LiteralPath $evidencePath -Force
  [void](New-Item -ItemType Directory -Path $evidencePath)
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-zero-byte'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-evidence-empty-file' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  $evidencePath = Join-Path (Split-Path -Parent $case.Item.CardPath) '证据\验证摘要.md'
  [IO.File]::WriteAllBytes($evidencePath, [byte[]]@())
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-arbitrary-file'
  $case.Item = New-P4tItemCard -Root $case.Root `
    -BorrowId 'borrow-20260719-evidence-arbitrary' -Bindings @($case.Source) `
    -Status closed -Decision adapt -Seal $true
  $evidencePath = Join-Path (Split-Path -Parent $case.Item.CardPath) '证据\验证摘要.md'
  Write-P4tUtf8 $evidencePath "arbitrary non-empty evidence`n"
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-command-unbound'
  $case.Item = New-P4tItemCard -Root $case.Root `
    -BorrowId 'borrow-20260719-evidence-command' -Bindings @($case.Source) `
    -Status closed -Decision adapt -Seal $true
  $evidencePath = Join-Path (Split-Path -Parent $case.Item.CardPath) '证据\验证摘要.md'
  $record = [IO.File]::ReadAllText($evidencePath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $evidencePath ([regex]::Replace(
      $record, '(?m)^command_sha256=[0-9a-f]{64}$', ('command_sha256=' + ('0' * 64))))
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-time-unbound'
  $case.Item = New-P4tItemCard -Root $case.Root `
    -BorrowId 'borrow-20260719-evidence-time' -Bindings @($case.Source) `
    -Status closed -Decision adapt -Seal $true
  $evidencePath = Join-Path (Split-Path -Parent $case.Item.CardPath) '证据\验证摘要.md'
  $record = [IO.File]::ReadAllText($evidencePath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $evidencePath $record.Replace(
    'time=2026-07-19T05:30:00+00:00', 'time=2026-07-19T05:31:00+00:00')
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-exit-unbound'
  $case.Item = New-P4tItemCard -Root $case.Root `
    -BorrowId 'borrow-20260719-evidence-exit' -Bindings @($case.Source) `
    -Status closed -Decision adapt -Seal $true
  $evidencePath = Join-Path (Split-Path -Parent $case.Item.CardPath) '证据\验证摘要.md'
  $record = [IO.File]::ReadAllText($evidencePath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $evidencePath $record.Replace("exit=0`n", "exit=10`n")
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-target-hash-stale'
  $case.Item = New-P4tItemCard -Root $case.Root `
    -BorrowId 'borrow-20260719-evidence-target-stale' -Bindings @($case.Source) `
    -Status closed -Decision adapt -Seal $true
  Write-P4tUtf8 (Join-Path $case.Root 'app\borrowed.txt') "target changed after verification`n"
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-inside-staging'
  $case.Item = New-P4tItemCard -Root $case.Root `
    -BorrowId 'borrow-20260719-evidence-staging' -Bindings @($case.Source) `
    -Status closed -Decision adapt -Seal $true
  $itemRoot = Split-Path -Parent $case.Item.CardPath
  $staging = Join-Path $itemRoot ('.staging-close-' + ('a' * 32))
  [void](New-Item -ItemType Directory -Path $staging)
  Write-P4tUtf8 (Join-Path $staging '原活动卡.bin') (Get-P4tEvidenceRecordText $case.Root)
  Write-P4tUtf8 (Join-Path $staging '借鉴卡.md') "retained candidate`n"
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    'evidence=证据/验证摘要.md',
    ('evidence=' + (Split-Path -Leaf $staging) + '/原活动卡.bin'))
  [void](Set-P4tFixtureSeal $case.Item.CardPath)
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-through-reparse'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-evidence-reparse' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  $outsideEvidence = Join-Path $script:P4tFixtureRoot 'closure-evidence-reparse'
  [void](New-Item -ItemType Directory -Path $outsideEvidence -Force)
  Write-P4tUtf8 (Join-Path $outsideEvidence '验证摘要.md') "linked evidence`n"
  $evidenceLink = Join-Path (Split-Path -Parent $case.Item.CardPath) '证据链接'
  [void](New-P4tJunction $evidenceLink $outsideEvidence)
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    'evidence=证据/验证摘要.md', 'evidence=证据链接/验证摘要.md')
  [void](Set-P4tFixtureSeal $case.Item.CardPath)
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-empty-bullet'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-evidence-empty' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    '- time=2026-07-19T05:30:00+00:00; command=powershell -File check.ps1; exit=0; evidence=证据/验证摘要.md',
    '- ')
  [void](Set-P4tFixtureSeal $case.Item.CardPath)
  $cases += $case

  $case = New-P4tItemClosureCase 'fresh-evidence-before-verifying'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-evidence-too-early' `
    -Bindings @($case.Source) -Status closed -Decision adapt -Seal $true
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    'time=2026-07-19T05:30:00+00:00', 'time=2026-07-19T04:30:00+00:00')
  [void](Set-P4tFixtureSeal $case.Item.CardPath)
  $cases += $case

  $staleCases = @()
  foreach ($mutation in @('body', 'status', 'time', 'evidence')) {
    $case = New-P4tItemClosureCase ('sealed-' + $mutation + '-changed')
    $case.Item = New-P4tItemCard -Root $case.Root `
      -BorrowId ('borrow-20260719-sealed-' + $mutation) -Bindings @($case.Source) `
      -Status closed -Decision adapt -Seal $true
    if ($mutation -eq 'body') {
      $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
      Write-P4tUtf8 $case.Item.CardPath $text.Replace('减少重复治理实现', '正文已被改写')
    }
    elseif ($mutation -eq 'status') {
      Set-P4tFrontmatterField $case.Item.CardPath lifecycle_status verifying
    }
    elseif ($mutation -eq 'time') {
      Set-P4tFrontmatterField $case.Item.CardPath updated_at '2026-07-20T00:00:00+00:00'
    }
    else {
      $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
      Write-P4tUtf8 $case.Item.CardPath $text.Replace('exit=0; evidence=', 'exit=10; evidence=')
    }
    $cases += $case
    $staleCases += $case
  }

  Invoke-CzxtContract 'item closure fixtures cover branch evidence and stale seal detection' {
    Assert-CzxtEqual 28 $cases.Count 'item closure case count'
    foreach ($case in $staleCases) {
      $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
      $stored = [regex]::Match($text, '(?m)^closure_seal_sha256: ([0-9a-f]{64})$').Groups[1].Value
      Assert-CzxtTrue ($stored -cne (Get-P4tClosureSealFromText $text)) `
        ($case.Name + ' fixture seal unexpectedly matches')
    }
  }

  $script:ItemHelperReady = $false
  Invoke-CzxtContract 'P4t item helper exists for closure cases' {
    Import-P4tHelper 'borrowing-item-cards.ps1' 'Invoke-BorrowingP4tItemCheck'
    $script:ItemHelperReady = $true
  }
  if ($script:ItemHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('item closure rejects ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tItemCheck $case.Root $case.SourceState
        Assert-P4tResult $result 10 $case.Name
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
