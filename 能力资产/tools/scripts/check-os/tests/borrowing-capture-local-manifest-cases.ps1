[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-local-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:LocalHelperReady = $false
  Invoke-CzxtContract 'capture Local helper exists with M0 through M3 primitives' {
    Import-BorrowingLocalTestModules
    $script:LocalHelperReady = $true
  }
  if ($script:LocalHelperReady) {
    Invoke-CzxtContract 'Local M0 canonical manifest uses Ordinal paths exact bytes and identities' {
      $source = New-BorrowingLocalSourceFixture 'manifest-source'
      $ops = New-BorrowingProductionLocalOperations
      $snapshot = Get-BorrowingLocalSnapshot -Path $source -Phase 'source-before' -Operations $ops
      $expected = "559aead08264d5795d3909718cdd05abd49572e84fe55590eef31a88a08fdffd`t1`ta.txt`n" +
        "06eb7d6a69ee19e5fbdf749018d3d2abfa04bcbd1365db312eb86dc7169389b8`t2`tnested/z.bin`n"
      Assert-CzxtEqual $expected ([Text.Encoding]::UTF8.GetString($snapshot.ManifestBytes)) `
        'canonical manifest bytes'
      Assert-CzxtEqual 'b043fcbdd474954585b2d6c75da7411221ff737e8bef5adc5422044434c51067' `
        $snapshot.Fingerprint 'manifest fingerprint'
      Assert-CzxtEqual 2 $snapshot.FileCount 'manifest file count'
      Assert-CzxtEqual 3 $snapshot.TotalBytes 'manifest total bytes'
      Assert-CzxtTrue (-not [string]::IsNullOrWhiteSpace($snapshot.RootIdentityKey)) `
        'manifest root identity'
      foreach ($entry in $snapshot.Entries) {
        Assert-CzxtEqual 1 $entry.NumberOfLinks ('manifest link count ' + $entry.RelativePath)
      }
    }

    Invoke-CzxtContract 'Local input rejects Root boundaries before any staging exists' {
      $root = New-BorrowingFixtureRoot 'local-boundary-root' project
      $inside = Join-Path $root 'input'
      [void](New-Item -ItemType Directory -Path $inside)
      Write-CzxtNoBomText (Join-Path $inside 'payload.txt') 'x'
      $ops = New-BorrowingProductionLocalOperations
      Assert-BorrowingFailureCode {
        New-BorrowingLocalInput -Root $root -LocalPath $inside `
          -LocalDisplayName 'safe-source' -Operations $ops
      } 'input' 'source-boundary'
      Assert-CzxtEqual 0 @(
        Get-ChildItem -LiteralPath (Join-Path $root '借鉴区') -Recurse -Force |
          Where-Object { $_.Name -like '.staging-*' }
      ).Count 'boundary staging count'
    }

    Invoke-CzxtContract 'Local empty source keeps content directory and five zero-byte manifests' {
      $root = New-BorrowingFixtureRoot 'local-empty-root' project
      $source = New-BorrowingLocalSourceFixture 'empty-source' $true
      $staging = Join-Path $root '借鉴区\来源\empty-source\.staging-empty'
      $capture = Join-Path $root '借鉴区\来源\empty-source\local-20260719-e3b0c44298fc'
      [void](New-Item -ItemType Directory -Path $staging -Force)
      $ops = New-BorrowingProductionLocalOperations
      $input = New-BorrowingLocalInput $root $source 'empty-source' $ops
      $candidate = New-BorrowingLocalCandidate $input $staging $ops
      [IO.Directory]::Move($staging, $capture)
      $promoted = Confirm-BorrowingLocalPromotion $candidate $capture $ops
      foreach ($bytes in @(
          $candidate.SourceBefore.ManifestBytes, $candidate.SourceAfter.ManifestBytes,
          $candidate.StagingContent.ManifestBytes, $promoted.ManifestBytes,
          [IO.File]::ReadAllBytes((Join-Path $capture '快照\manifest.tsv'))
        )) { Assert-CzxtEqual 0 $bytes.Length 'empty manifest bytes' }
      Assert-CzxtEqual 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' `
        $candidate.Fingerprint 'empty fingerprint'
      Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $capture '快照\内容') -PathType Container) `
        'empty content directory'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
