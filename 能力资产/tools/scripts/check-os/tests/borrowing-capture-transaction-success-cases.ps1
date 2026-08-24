[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-transaction-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:TransactionReady = $false
  Invoke-CzxtContract 'capture transaction helper exists for success branches' {
    Import-BorrowingTransactionTestModules
    $script:TransactionReady = $true
  }
  if ($script:TransactionReady) {
    Invoke-CzxtContract 'transaction enumerates exact ignored cache members by source type' {
      $expected = @{
        git = @('快照/repository.git/', 'capture.local.json')
        local = @('快照/内容/', '快照/manifest.tsv', 'capture.local.json')
        web = @('快照/response.bin', '快照/response.metadata.json', 'capture.local.json')
      }
      foreach ($sourceType in $expected.Keys) {
        $actual = @(Get-BorrowingExpectedCacheMembers $sourceType)
        Assert-CzxtEqual ($expected[$sourceType] -join ',') ($actual -join ',') `
          ('expected cache members ' + $sourceType)
      }
    }

    Invoke-CzxtContract 'transaction conflict preserves staging and skips both P4t gates' {
      $context = New-BorrowingTransactionFixture 'conflict' Conflict
      $result = Invoke-BorrowingCaptureTransactionCore -Context $context `
        -Operations (New-BorrowingTransactionOperations $context)
      Assert-CzxtEqual 'FAIL' $result.Result 'conflict result'
      Assert-CzxtEqual 'idempotency' $result.Stage 'conflict stage'
      Assert-CzxtEqual 'idempotency-conflict' $result.ReasonCode 'conflict reason'
      Assert-CzxtEqual 'not-run' $result.P4tBefore 'conflict p4t-before'
      Assert-CzxtEqual 'not-run' $result.P4tAfter 'conflict p4t-after'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
        'conflict staging missing'
      Assert-BorrowingTransactionTrace $result @(
        'preflight','input','staging-created','capture','candidate-validator','idempotency',
        'idempotency-conflict'
      ) 'conflict'
    }

    Invoke-CzxtContract 'transaction healthy reuse gates before cleanup and never moves existing capture' {
      $context = New-BorrowingTransactionFixture 'healthy' HealthyReuse
      $card = Join-Path $context.CapturePath '来源版本卡.md'
      $beforeBytes = [IO.File]::ReadAllBytes($card)
      $beforeTime = (Get-Item $card).LastWriteTimeUtc.Ticks
      $result = Invoke-BorrowingCaptureTransactionCore $context `
        (New-BorrowingTransactionOperations $context)
      Assert-CzxtEqual 'REUSED' $result.Result 'healthy result'
      Assert-CzxtEqual '0' $result.P4tBefore 'healthy p4t-before'
      Assert-CzxtEqual 'not-run' $result.P4tAfter 'healthy p4t-after'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.CapturePath -PathType Container) `
        'healthy capture missing'
      Assert-CzxtEqual $false (Test-Path -LiteralPath $context.StagingPath) `
        'healthy staging not cleaned'
      Assert-CzxtEqual ([Convert]::ToBase64String($beforeBytes)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($card))) 'healthy tracked bytes'
      Assert-CzxtEqual $beforeTime (Get-Item $card).LastWriteTimeUtc.Ticks 'healthy tracked mtime'
      Assert-CzxtTrue ([bool]$context.FinalChecked) `
        'healthy reuse returned REUSED without a final bound check'
      Assert-CzxtEqual 2 ([int]$context.FinalCheckCount) `
        'healthy reuse final check count'
      Assert-BorrowingTransactionTrace $result @(
        'preflight','input','staging-created','capture','candidate-validator','idempotency',
        'reuse','p4t-before','final-check','cleanup','final-check-after-cleanup',
        'complete'
      ) 'healthy reuse'
    }

    Invoke-CzxtContract 'transaction missing-cache repair installs only cache and runs only P4t-after' {
      $context = New-BorrowingTransactionFixture 'repair' RepairMissingCache
      $card = Join-Path $context.CapturePath '来源版本卡.md'
      $beforeBytes = [IO.File]::ReadAllBytes($card)
      $beforeTime = (Get-Item $card).LastWriteTimeUtc.Ticks
      $result = Invoke-BorrowingCaptureTransactionCore $context `
        (New-BorrowingTransactionOperations $context)
      Assert-CzxtEqual 'REUSED' $result.Result 'repair result'
      Assert-CzxtEqual 'not-run' $result.P4tBefore 'repair p4t-before'
      Assert-CzxtEqual '0' $result.P4tAfter 'repair p4t-after'
      Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $context.CapturePath `
            '快照\response.bin') -PathType Leaf) 'repair raw cache'
      Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $context.CapturePath `
            'capture.local.json') -PathType Leaf) 'repair local state'
      Assert-CzxtEqual ([Convert]::ToBase64String($beforeBytes)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($card))) 'repair tracked bytes'
      Assert-CzxtEqual $beforeTime (Get-Item $card).LastWriteTimeUtc.Ticks 'repair tracked mtime'
      Assert-CzxtTrue ([bool]$context.FinalChecked) `
        'repair returned REUSED without a final bound check'
      Assert-CzxtEqual 2 ([int]$context.FinalCheckCount) `
        'repair final check count'
      Assert-BorrowingTransactionTrace $result @(
        'preflight','input','staging-created','capture','candidate-validator','idempotency',
        'repair-missing-cache','install-missing-cache','post-link-check','p4t-after',
        'final-check','cleanup','final-check-after-cleanup','complete'
      ) 'repair'
    }

    Invoke-CzxtContract 'transaction new branch uses two gates around atomic move' {
      $context = New-BorrowingTransactionFixture 'new' New
      $result = Invoke-BorrowingCaptureTransactionCore $context `
        (New-BorrowingTransactionOperations $context)
      Assert-CzxtEqual 'READY' $result.Result 'new result'
      Assert-CzxtEqual '0' $result.P4tBefore 'new p4t-before'
      Assert-CzxtEqual '0' $result.P4tAfter 'new p4t-after'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.CapturePath -PathType Container) `
        'new capture missing'
      Assert-CzxtEqual $false (Test-Path -LiteralPath $context.StagingPath) `
        'new staging still exists'
      Assert-CzxtTrue ([bool]$context.FinalChecked) `
        'new transaction returned READY without a final bound check'
      Assert-CzxtEqual 1 ([int]$context.FinalCheckCount) `
        'new final check count'
      Assert-BorrowingTransactionTrace $result @(
        'preflight','input','staging-created','capture','candidate-validator','idempotency',
        'new','p4t-before','atomic-move','post-link-check','p4t-after','final-check',
        'complete'
      ) 'new'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
