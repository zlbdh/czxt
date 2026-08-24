[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-candidate-validator-test-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-capture-candidate-validator-card-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-capture-candidate-validator-cache-contracts.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:BcvReady = $false
  Invoke-CzxtContract 'candidate validator exports its fixed public API' {
    Import-BorrowingCandidateValidatorModules
    $script:BcvReady = $true
  }

  if ($script:BcvReady) {
    Invoke-CzxtContract 'Git Local and Web canonical cards validate against renderer identity' {
      foreach ($type in @('git', 'local', 'web')) {
        $root = New-BcvRoot ('valid-' + $type)
        $capture = New-BcvCapture -Root $root -SourceType $type `
          -WithCache:($type -ne 'git')
        $actual = Get-BorrowingValidatedSourceCandidate `
          -CaptureDirectory $capture.CaptureDirectory
        Assert-CzxtEqual $type $actual.SourceType ($type + ' source type')
        Assert-CzxtEqual $capture.Artifact.StableIdentitySha256 `
          $actual.StableIdentitySha256 ($type + ' stable identity')
        $identity = Get-BorrowingSourceStableIdentity -Candidate $actual
        Assert-CzxtEqual $actual.StableIdentitySha256 `
          $identity.StableIdentitySha256 ($type + ' identity recompute')
      }
      $sha256 = New-BcvCapture -Root (New-BcvRoot 'valid-git-sha256') `
        -SourceType git -Variant 2
      $sha256Card = Get-BorrowingValidatedSourceCandidate $sha256.CaptureDirectory
      Assert-CzxtEqual 'sha256' $sha256Card.TypeFacts.ObjectFormat `
        'Git SHA-256 object format'
      Assert-CzxtEqual 64 $sha256Card.Fingerprint.Length 'Git SHA-256 object length'
    }

    Invoke-BcvStrictCardContracts

    Invoke-CzxtContract 'formal directories are strict while source-scoped staging is accepted' {
      $root = New-BcvRoot 'directory-rules'
      $staging = New-BcvCapture -Root $root -SourceType local -WithCache `
        -DirectoryName '.staging-fixture'
      [void](Get-BorrowingValidatedSourceCandidate $staging.CaptureDirectory)
      $wrongCapture = New-BcvCapture -Root (New-BcvRoot 'wrong-capture') `
        -SourceType local -DirectoryName 'local-20260719-deadbeefdead'
      Assert-BcvCandidateInvalid $wrongCapture
      $wrongSource = New-BcvCapture -Root (New-BcvRoot 'wrong-source') `
        -SourceType local -SourceDirectoryName 'other-source'
      Assert-BcvCandidateInvalid $wrongSource
    }

    Invoke-CzxtContract 'ready and retired cards share stable identity despite volatile changes' {
      $first = New-BcvCapture -Root (New-BcvRoot 'volatile-first') `
        -SourceType local -WithCache `
        -Clock ([DateTimeOffset]::Parse('2026-07-19T01:02:03.456Z'))
      $second = New-BcvCapture -Root (New-BcvRoot 'volatile-second') `
        -SourceType local -WithCache `
        -Clock ([DateTimeOffset]::Parse('2026-07-20T02:03:04.567Z'))
      Set-BcvCardText $second {
        param($text)
        $text.Replace('capture_status: ready', 'capture_status: retired').TrimEnd("`n") +
          "`n| 2026-07-21T00:00:00.000Z | ready | retired | superseded | project-pm |`n"
      }
      $a = Get-BorrowingValidatedSourceCandidate $first.CaptureDirectory
      $b = Get-BorrowingValidatedSourceCandidate $second.CaptureDirectory
      Assert-CzxtEqual $a.StableIdentitySha256 $b.StableIdentitySha256 `
        'volatile fields excluded from stable identity'
      Assert-CzxtEqual 'retired' $b.CaptureStatus 'retired status accepted'
    }

    Invoke-CzxtContract 'stable fact changes alter StableIdentitySha256' {
      $first = New-BcvCapture -Root (New-BcvRoot 'stable-first') `
        -SourceType local -WithCache -Variant 1
      $second = New-BcvCapture -Root (New-BcvRoot 'stable-second') `
        -SourceType local -WithCache -Variant 2
      $a = Get-BorrowingValidatedSourceCandidate $first.CaptureDirectory
      $b = Get-BorrowingValidatedSourceCandidate $second.CaptureDirectory
      Assert-CzxtTrue ($a.StableIdentitySha256 -cne $b.StableIdentitySha256) `
        'stable facts change identity'
    }

    Invoke-BcvCacheContracts
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
