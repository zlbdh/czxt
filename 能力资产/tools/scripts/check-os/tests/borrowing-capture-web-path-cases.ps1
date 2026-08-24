[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-web-test-support.ps1')

function New-BorrowingWebInputFiles {
  param([string]$Name)
  $directory = Join-Path $script:BorrowingCaptureFixtureRoot $Name
  [void](New-Item -ItemType Directory -Path $directory -Force)
  $raw = Join-Path $directory 'response.bin'
  $metadata = Join-Path $directory 'response.json'
  Write-BorrowingFixtureBytes $raw ([byte[]](0x00, 0xFF, 0x41))
  Write-BorrowingFixtureBytes $metadata `
    (ConvertTo-BorrowingFixtureUtf8 (Get-BorrowingValidWebMetadataText))
  return [pscustomobject]@{ Raw = $raw; Metadata = $metadata }
}

Initialize-BorrowingCaptureFixture
try {
  $script:WebHelperReady = $false
  Invoke-CzxtContract 'capture Web helper exists with external-input boundary primitive' {
    Import-BorrowingWebTestModules
    $script:WebHelperReady = $true
  }
  if ($script:WebHelperReady) {
    Invoke-CzxtContract 'Web accepts disjoint sibling inputs and exposes different physical identities' {
      $root = New-BorrowingFixtureRoot 'project' project
      $files = New-BorrowingWebInputFiles 'project-sibling'
      $input = Open-BorrowingWebInput -Root $root `
        -WebRawBytesPath $files.Raw -WebResponseMetadataPath $files.Metadata `
        -Operations (New-BorrowingProductionWebOperations)
      Assert-CzxtTrue ($input.RawPath -match '^[A-Z]:\\') 'canonical raw path'
      Assert-CzxtTrue ($input.MetadataPath -match '^[A-Z]:\\') 'canonical metadata path'
      Assert-CzxtTrue ($input.RawIdentityKey -cne $input.MetadataIdentityKey) `
        'Web input identities differ'
    }

    Invoke-CzxtContract 'Web rejects Root descendants same path and hardlink aliases before staging' {
      $root = New-BorrowingFixtureRoot 'web-boundary-root' project
      $inside = Join-Path $root 'inputs'
      $insideFiles = New-BorrowingWebInputFiles 'web-boundary-root\inputs'
      $ops = New-BorrowingProductionWebOperations
      Assert-BorrowingFailureCode {
        Open-BorrowingWebInput $root $insideFiles.Raw $insideFiles.Metadata $ops
      } 'input' 'source-boundary'

      $outside = New-BorrowingWebInputFiles 'web-outside'
      Assert-BorrowingFailureCode {
        Open-BorrowingWebInput $root $outside.Raw $outside.Raw $ops
      } 'input' 'source-boundary'

      $alias = Join-Path (Split-Path -Parent $outside.Raw) 'raw-alias.bin'
      [void](New-Item -ItemType HardLink -Path $alias -Target $outside.Raw -Force)
      Assert-BorrowingFailureCode {
        Open-BorrowingWebInput $root $outside.Raw $alias $ops
      } 'input' 'source-boundary'
      Assert-CzxtEqual 0 @(
        Get-ChildItem -LiteralPath (Join-Path $root '借鉴区') -Recurse -Force |
          Where-Object { $_.Name -like '.staging-*' }
      ).Count 'Web boundary staging count'
    }

    Invoke-CzxtContract 'Web resists same-length ABA while reading raw input bytes' {
      $root = New-BorrowingFixtureRoot 'web-read-aba-root' project
      $files = New-BorrowingWebInputFiles 'web-read-aba-input'
      $attacker = Join-Path $script:BorrowingCaptureFixtureRoot 'web-read-attacker.bin'
      $parked = Join-Path $script:BorrowingCaptureFixtureRoot 'web-read-parked.bin'
      [byte[]]$safeBytes = [IO.File]::ReadAllBytes($files.Raw)
      Write-BorrowingFixtureBytes $attacker ([byte[]](0x42, 0x41, 0x44))
      $ops = New-BorrowingProductionWebOperations
      $originalRead = $ops.ReadAllBytes
      $script:BwpLegacyReadRan = $false
      $rawPath = [IO.Path]::GetFullPath($files.Raw)
      $ops.ReadAllBytes = ({
        param([string]$Path)
        if (-not $script:BwpLegacyReadRan -and
            [IO.Path]::GetFullPath($Path) -ieq $rawPath) {
          [IO.File]::Move($Path, $parked)
          [IO.File]::Move($attacker, $Path)
          try { [byte[]]$bytes = & $originalRead $Path }
          finally {
            [IO.File]::Move($Path, $attacker)
            [IO.File]::Move($parked, $Path)
          }
          $script:BwpLegacyReadRan = $true
          return ,$bytes
        }
        return ,([byte[]](& $originalRead $Path))
      }).GetNewClosure()
      $input = Open-BorrowingWebInput $root $files.Raw $files.Metadata $ops
      Assert-CzxtTrue (-not [bool]$script:BwpLegacyReadRan) `
        'Web input still used the path-based ReadAllBytes seam'
      Assert-CzxtEqual ([Convert]::ToBase64String($safeBytes)) `
        ([Convert]::ToBase64String([byte[]]$input.RawBytes)) `
        'Web ABA changed the accepted raw bytes'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
