[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:FileSafetyReady = $false
  Invoke-CzxtContract 'capture file-safety helper exists with handle identity primitives' {
    Import-BorrowingCaptureModules @('file-safety', 'common')
    foreach ($name in @('Get-BorrowingSafePathInfo', 'Get-BorrowingPathRelation')) {
      Assert-BorrowingCommandExists $name
    }
    $script:FileSafetyReady = $true
  }

  if ($script:FileSafetyReady) {
    Invoke-CzxtContract 'safe path info returns canonical fixed-drive identity for a regular file' {
      $directory = Join-Path $script:BorrowingCaptureFixtureRoot 'safe-path'
      [void](New-Item -ItemType Directory -Path $directory)
      $path = Join-Path $directory 'payload.bin'
      Write-BorrowingFixtureBytes $path ([byte[]](0x00, 0xFF, 0x41))
      $actual = Get-BorrowingSafePathInfo -Path $path -ExpectedKind File `
        -Stage input -ReasonCode source-boundary
      Assert-CzxtEqual 'borrowing-safe-path/v1' $actual.Schema 'path schema'
      Assert-CzxtEqual 'File' $actual.Kind 'path kind'
      Assert-CzxtEqual 3 $actual.Length 'file length'
      Assert-CzxtEqual 1 $actual.NumberOfLinks 'file link count'
      Assert-CzxtTrue ($actual.CanonicalPath -match '^[A-Z]:\\') 'canonical drive-letter path'
      Assert-CzxtTrue (-not [string]::IsNullOrWhiteSpace($actual.IdentityKey)) 'file identity key'
      Assert-CzxtEqual 'Fixed' $actual.DriveType 'fixed drive'
      Assert-CzxtEqual $false $actual.IsSubst 'subst state'
    }

    Invoke-CzxtContract 'safe path ignores only volume-root metadata streams' {
      $workspaceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))
      $workspaceInfo = Get-BorrowingSafePathInfo $workspaceRoot Directory input source-boundary
      Assert-CzxtEqual $workspaceRoot $workspaceInfo.CanonicalPath 'workspace canonical path'

      $directory = Join-Path $script:BorrowingCaptureFixtureRoot 'directory-ads'
      [void](New-Item -ItemType Directory -Path $directory)
      Set-Content -LiteralPath $directory -Stream secret -Value 'secret' -NoNewline
      Assert-BorrowingFailureCode {
        Get-BorrowingSafePathInfo $directory Directory input source-boundary
      } 'input' 'source-boundary'
    }

    Invoke-CzxtContract 'path relation uses directory boundaries instead of bare prefixes' {
      $project = Join-Path $script:BorrowingCaptureFixtureRoot 'project'
      $child = Join-Path $project '借鉴区'
      $sibling = Join-Path $script:BorrowingCaptureFixtureRoot 'project-sibling'
      foreach ($path in @($child, $sibling)) {
        [void](New-Item -ItemType Directory -Path $path -Force)
      }
      $projectInfo = Get-BorrowingSafePathInfo $project Directory input source-boundary
      $childInfo = Get-BorrowingSafePathInfo $child Directory input source-boundary
      $siblingInfo = Get-BorrowingSafePathInfo $sibling Directory input source-boundary
      Assert-CzxtEqual 'ancestor' `
        (Get-BorrowingPathRelation $projectInfo.CanonicalPath $childInfo.CanonicalPath) `
        'project relation to child'
      Assert-CzxtEqual 'descendant' `
        (Get-BorrowingPathRelation $childInfo.CanonicalPath $projectInfo.CanonicalPath) `
        'child relation to project'
      Assert-CzxtEqual 'disjoint' `
        (Get-BorrowingPathRelation $projectInfo.CanonicalPath $siblingInfo.CanonicalPath) `
        'prefix sibling relation'
      Assert-CzxtEqual 'equal' `
        (Get-BorrowingPathRelation $projectInfo.CanonicalPath $projectInfo.CanonicalPath) `
        'same path relation'
    }

    Invoke-CzxtContract 'safe path rejects relative UNC device ADS and reserved segments' {
      $base = Join-Path $script:BorrowingCaptureFixtureRoot 'unsafe-inputs'
      [void](New-Item -ItemType Directory -Path $base)
      $file = Join-Path $base 'payload.txt'
      Write-CzxtNoBomText $file 'x'
      Set-Content -LiteralPath $file -Stream secret -Value 'secret' -NoNewline
      foreach ($path in @(
          'relative\payload.txt', '\\server\share\payload.txt',
          '\\?\C:\payload.txt', ($file + ':secret'), (Join-Path $base 'CON.txt')
        )) {
        Assert-BorrowingFailureCode {
          Get-BorrowingSafePathInfo $path File input source-boundary
        } 'input' 'source-boundary'
      }
      Assert-BorrowingFailureCode {
        Get-BorrowingSafePathInfo $file File input source-boundary
      } 'input' 'source-boundary'
    }

    Invoke-CzxtContract 'safe path rejects hardlinks and reparse directories without traversal' {
      $base = Join-Path $script:BorrowingCaptureFixtureRoot 'link-inputs'
      $target = Join-Path $base 'target'
      [void](New-Item -ItemType Directory -Path $target -Force)
      $original = Join-Path $target 'original.txt'
      $alias = Join-Path $target 'alias.txt'
      Write-CzxtNoBomText $original 'same bytes'
      [void](New-Item -ItemType HardLink -Path $alias -Target $original -Force)
      foreach ($path in @($original, $alias)) {
        Assert-BorrowingFailureCode {
          Get-BorrowingSafePathInfo $path File input source-boundary
        } 'input' 'source-boundary'
      }

      $junctionTarget = Join-Path $base 'junction-target'
      $junction = Join-Path $base 'junction'
      [void](New-Item -ItemType Directory -Path $junctionTarget)
      [void](New-Item -ItemType Junction -Path $junction -Target $junctionTarget)
      Assert-BorrowingFailureCode {
        Get-BorrowingSafePathInfo $junction Directory input source-boundary
      } 'input' 'source-boundary'
      Assert-CzxtTrue (Test-Path -LiteralPath $junctionTarget -PathType Container) `
        'junction target was traversed or removed'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
