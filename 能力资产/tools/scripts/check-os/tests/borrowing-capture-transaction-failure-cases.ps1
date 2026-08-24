[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-transaction-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:TransactionReady = $false
  Invoke-CzxtContract 'capture transaction helper exists for rollback branches' {
    Import-BorrowingTransactionTestModules
    $script:TransactionReady = $true
  }
  if ($script:TransactionReady) {
    Invoke-CzxtContract 'transaction P4t-before nonzero never moves or repairs' {
      $context = New-BorrowingTransactionFixture 'before-fail' New
      $result = Invoke-BorrowingCaptureTransactionCore $context `
        (New-BorrowingTransactionOperations $context 5 0)
      Assert-CzxtEqual 'FAIL' $result.Result 'before failure result'
      Assert-CzxtEqual 'p4t-before' $result.Stage 'before failure stage'
      Assert-CzxtEqual 'p4t-not-zero' $result.ReasonCode 'before failure reason'
      Assert-CzxtEqual '5' $result.P4tBefore 'before failure exit'
      Assert-CzxtEqual 'not-run' $result.P4tAfter 'before failure after gate'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
        'before failure staging missing'
      Assert-CzxtEqual $false (Test-Path -LiteralPath $context.CapturePath) `
        'before failure moved capture'
    }

    Invoke-CzxtContract 'transaction preserves P4t start-failed and timeout projections' {
      foreach ($case in @(
          [pscustomobject]@{ Gate = 'p4t-before'; Projection = 'start-failed' },
          [pscustomobject]@{ Gate = 'p4t-after'; Projection = 'timeout' }
        )) {
        $context = New-BorrowingTransactionFixture `
          ('projection-' + $case.Projection) New
        $failureGate = $case.Gate
        $projection = $case.Projection
        $operations = New-BorrowingTransactionOperations $context
        $operations.RunP4t = {
          param($ctx, [string]$Gate)
          if ($Gate -ceq $failureGate) {
            $exception = New-Object InvalidOperationException('fixture P4t process failure')
            $exception.Data['BorrowingStage'] = $Gate
            $exception.Data['BorrowingReasonCode'] = 'p4t-process-failed'
            $exception.Data['BorrowingP4tProjection'] = $projection
            throw $exception
          }
          return New-BorrowingP4tResult 0
        }.GetNewClosure()
        $result = Invoke-BorrowingCaptureTransactionCore $context $operations
        Assert-CzxtEqual 'FAIL' $result.Result ($projection + ' result')
        Assert-CzxtEqual $failureGate $result.Stage ($projection + ' stage')
        Assert-CzxtEqual 'p4t-process-failed' $result.ReasonCode `
          ($projection + ' reason')
        if ($failureGate -ceq 'p4t-before') {
          Assert-CzxtEqual $projection $result.P4tBefore 'before projection'
          Assert-CzxtEqual 'not-run' $result.P4tAfter 'before after projection'
          Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
            'start failure staging retained'
        }
        else {
          Assert-CzxtEqual '0' $result.P4tBefore 'after before projection'
          Assert-CzxtEqual $projection $result.P4tAfter 'after projection'
          Assert-CzxtEqual $false (Test-Path -LiteralPath $context.CapturePath) `
            'timeout capture rolled back'
          Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
            'timeout staging restored'
        }
      }
    }

    Invoke-CzxtContract 'transaction new P4t-after failure atomically restores staging' {
      $context = New-BorrowingTransactionFixture 'new-after-fail' New
      $result = Invoke-BorrowingCaptureTransactionCore $context `
        (New-BorrowingTransactionOperations $context 0 5)
      Assert-CzxtEqual 'FAIL' $result.Result 'new after result'
      Assert-CzxtEqual 'p4t-after' $result.Stage 'new after stage'
      Assert-CzxtEqual 'p4t-not-zero' $result.ReasonCode 'new after reason'
      Assert-CzxtEqual $false (Test-Path -LiteralPath $context.CapturePath) `
        'new rollback capture still exists'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
        'new rollback staging missing'
      Assert-BorrowingTransactionTrace $result @(
        'preflight','input','staging-created','capture','candidate-validator','idempotency',
        'new','p4t-before','atomic-move','post-link-check','p4t-after','rollback'
      ) 'new after failure'
    }

    Invoke-CzxtContract 'transaction repair P4t-after failure restores the all-missing cache state' {
      $context = New-BorrowingTransactionFixture 'repair-after-fail' RepairMissingCache
      $card = Join-Path $context.CapturePath '来源版本卡.md'
      $before = [IO.File]::ReadAllBytes($card)
      $result = Invoke-BorrowingCaptureTransactionCore $context `
        (New-BorrowingTransactionOperations $context 0 5)
      Assert-CzxtEqual 'FAIL' $result.Result 'repair after result'
      Assert-CzxtEqual 'p4t-after' $result.Stage 'repair after stage'
      Assert-CzxtEqual $false (Test-Path -LiteralPath (Join-Path $context.CapturePath '快照')) `
        'repair rollback snapshot remains'
      Assert-CzxtEqual $false (Test-Path -LiteralPath `
          (Join-Path $context.CapturePath 'capture.local.json')) 'repair rollback local state remains'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
        'repair rollback staging missing'
      Assert-CzxtEqual ([Convert]::ToBase64String($before)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($card))) 'repair rollback tracked bytes'
    }

    Invoke-CzxtContract 'transaction post-link failure rolls back before P4t-after' {
      $context = New-BorrowingTransactionFixture 'post-link-fail' New
      $ops = New-BorrowingTransactionOperations $context
      $ops.PostLinkCheck = {
        param($ctx)
        $exception = New-Object InvalidOperationException('fixture post-link failure')
        $exception.Data['BorrowingStage'] = 'promotion'
        $exception.Data['BorrowingReasonCode'] = 'source-unsafe'
        throw $exception
      }
      $result = Invoke-BorrowingCaptureTransactionCore $context $ops
      Assert-CzxtEqual 'FAIL' $result.Result 'post-link result'
      Assert-CzxtEqual 'promotion' $result.Stage 'post-link stage'
      Assert-CzxtEqual 'source-unsafe' $result.ReasonCode 'post-link reason'
      Assert-CzxtEqual 'not-run' $result.P4tAfter 'post-link P4t-after'
      Assert-CzxtEqual $false (Test-Path -LiteralPath $context.CapturePath) `
        'post-link capture remains'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
        'post-link staging missing'
    }

    Invoke-CzxtContract 'transaction reports rollback failure without compensating delete' {
      $context = New-BorrowingTransactionFixture 'rollback-fail' New
      $result = Invoke-BorrowingCaptureTransactionCore $context `
        (New-BorrowingTransactionOperations $context 0 5 $true $false)
      Assert-CzxtEqual 'FAIL' $result.Result 'rollback failure result'
      Assert-CzxtEqual 'rollback' $result.Stage 'rollback failure stage'
      Assert-CzxtEqual 'rollback-failed' $result.ReasonCode 'rollback failure reason'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.CapturePath -PathType Container) `
        'rollback failure capture was deleted'
      Assert-CzxtEqual $false (Test-Path -LiteralPath $context.StagingPath) `
        'rollback failure fabricated staging'
    }

    Invoke-CzxtContract 'transaction reports cleanup failure using actual path state' {
      $context = New-BorrowingTransactionFixture 'cleanup-fail' HealthyReuse
      $result = Invoke-BorrowingCaptureTransactionCore $context `
        (New-BorrowingTransactionOperations $context 0 0 $false $true)
      Assert-CzxtEqual 'FAIL' $result.Result 'cleanup failure result'
      Assert-CzxtEqual 'cleanup' $result.Stage 'cleanup failure stage'
      Assert-CzxtEqual 'cleanup-failed' $result.ReasonCode 'cleanup failure reason'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.CapturePath -PathType Container) `
        'cleanup failure capture missing'
      Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
        'cleanup failure staging missing'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
