[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')

$templateRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))
$helperPath = Join-Path $templateRoot '能力资产\tools\scripts\check-os\p4a-borrowing-assets.ps1'
$p4aPath = Join-Path $templateRoot '能力资产\tools\scripts\check-os\p4a-basic-integrity.ps1'

$script:BorrowingAssetsHelperReady = $false
if (Test-Path -LiteralPath $helperPath -PathType Leaf) {
  . $helperPath
}
Invoke-CzxtContract 'P4a borrowing assets helper exists' {
  Assert-CzxtTrue (Test-Path -LiteralPath $helperPath -PathType Leaf) `
    'missing p4a-borrowing-assets.ps1'
  Assert-CzxtTrue ($null -ne (Get-Command Get-CzxtBorrowingAssetManifest -ErrorAction SilentlyContinue)) `
    'missing borrowing asset manifest API'
  Assert-CzxtTrue ($null -ne (Get-Command Test-CzxtBorrowingAssets -ErrorAction SilentlyContinue)) `
    'missing borrowing asset test API'
  $script:BorrowingAssetsHelperReady = $true
}

if ($script:BorrowingAssetsHelperReady) {
  Invoke-CzxtContract 'borrowing manifest covers complete critical chain' {
    $manifest = Get-CzxtBorrowingAssetManifest -RootMode template
    $criticalFiles = @(
      '.czxt-template-root',
      '借鉴区/来源/.gitkeep',
      '借鉴区/事项/.gitkeep',
      '能力资产/rules/借鉴治理.md',
      '能力资产/skills/借鉴.md',
      '能力资产/skills/借鉴-命令附录.md',
      '操作系统/07_完整工作流/借鉴闭环.md',
      '能力资产/tools/scripts/check-readme-indexes/borrowing-governance-anchor.ps1',
      '能力资产/tools/scripts/installer-borrowing-skeleton.ps1',
      '能力资产/tools/scripts/installer-path-safety.ps1',
      '能力资产/tools/scripts/installer-file-safety.ps1',
      '能力资产/tools/scripts/installer-source-copy.ps1',
      '能力资产/tools/scripts/installer-handle-lease.ps1',
      '能力资产/tools/scripts/installer-replace-transaction.ps1',
      '能力资产/tools/scripts/installer-output-manifest.ps1',
      '能力资产/tools/scripts/installer-tree-plan.ps1',
      '能力资产/tools/scripts/installer-copy-expectation.ps1',
      '能力资产/tools/scripts/check-os/p4a-borrowing-scaffold.ps1',
      '能力资产/tools/scripts/capture-borrowing-source.ps1',
      '能力资产/tools/scripts/check-os/tests/borrowing-capture-contracts.ps1',
      '能力资产/tools/scripts/check-os/tests/borrowing-owned-tree-seal-contracts.ps1',
      '能力资产/tools/scripts/check-os/tests/borrowing-capture-git-auxiliary-cleanup-cases.ps1',
      '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-contracts.ps1',
      '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-file-cas-contracts.ps1',
      '能力资产/tools/scripts/check-os/p4t/borrowing-source-git.ps1',
      '能力资产/tools/scripts/check-os/p4t/borrowing-source-inventory.ps1',
      '能力资产/tools/scripts/close-borrowing-item.ps1',
      '能力资产/tools/scripts/borrowing-close-candidate.ps1',
      '能力资产/tools/scripts/borrowing-close-transaction.ps1',
      '能力资产/tools/scripts/borrowing-owned-directory.ps1',
      '能力资产/tools/scripts/borrowing-owned-file.ps1',
      '能力资产/tools/scripts/check-os/tests/borrowing-owned-rename-contracts.ps1',
      '能力资产/tools/scripts/seal-borrowing-item.ps1',
      '能力资产/tools/scripts/borrowing-seal-transaction.ps1'
    )
    foreach ($relativePath in $criticalFiles) {
      Assert-CzxtTrue ($manifest.Files -ccontains $relativePath) `
        ('manifest missing critical file: ' + $relativePath)
    }
    $captureLeaves = @(Get-ChildItem -LiteralPath (Join-Path $templateRoot `
          '能力资产\tools\scripts\borrowing-capture') -File -Filter '*.ps1')
    foreach ($leaf in $captureLeaves) {
      $relativePath = '能力资产/tools/scripts/borrowing-capture/' + $leaf.Name
      Assert-CzxtTrue ($manifest.Files -ccontains $relativePath) `
        ('manifest missing capture production leaf: ' + $relativePath)
    }
    $p4tLeaves = @(Get-ChildItem -LiteralPath (Join-Path $templateRoot `
          '能力资产\tools\scripts\check-os\p4t') -File -Filter '*.ps1')
    foreach ($leaf in $p4tLeaves) {
      $relativePath = '能力资产/tools/scripts/check-os/p4t/' + $leaf.Name
      Assert-CzxtTrue ($manifest.Files -ccontains $relativePath) `
        ('manifest missing P4t production leaf: ' + $relativePath)
    }
    $p4tTests = @(Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object {
        $_.Name -like 'p4t-borrowing-*.ps1' -or
        $_.Name -in @(
          'borrowing-item-seal-contracts.ps1',
          'borrowing-item-close-transaction-contracts.ps1')
      })
    Assert-CzxtEqual 26 $p4tTests.Count 'P4t test/fixture inventory drifted'
    foreach ($leaf in $p4tTests) {
      $relativePath = '能力资产/tools/scripts/check-os/tests/' + $leaf.Name
      Assert-CzxtTrue ($manifest.Files -ccontains $relativePath) `
        ('manifest missing P4t test/fixture: ' + $relativePath)
    }
    foreach ($relativePath in @(
        '借鉴区', '借鉴区/模板', '借鉴区/来源', '借鉴区/事项',
        '能力资产/tools/scripts/borrowing-capture',
        '能力资产/tools/scripts/check-os/p4t')) {
      Assert-CzxtTrue ($manifest.Directories -ccontains $relativePath) `
        ('manifest missing critical directory: ' + $relativePath)
    }
  }

  Invoke-CzxtContract 'borrowing manifest separates template and project artifacts' {
    $templateManifest = Get-CzxtBorrowingAssetManifest -RootMode template
    $projectManifest = Get-CzxtBorrowingAssetManifest -RootMode project
    Assert-CzxtTrue ($templateManifest.Files -ccontains '.czxt-template-root') `
      'template marker is not required in template mode'
    Assert-CzxtTrue ($templateManifest.Files -ccontains '借鉴区/来源/.gitkeep') `
      'template source placeholder is not required'
    Assert-CzxtTrue ($templateManifest.Files -ccontains '借鉴区/事项/.gitkeep') `
      'template item placeholder is not required'
    Assert-CzxtTrue ($projectManifest.Files -ccontains '.czxt-project-root') `
      'project marker is not required in project mode'
    Assert-CzxtTrue (-not ($projectManifest.Files -ccontains '.czxt-template-root')) `
      'project mode must not require template marker'
    Assert-CzxtTrue (-not ($projectManifest.Files -ccontains '借鉴区/来源/.gitkeep')) `
      'project mode must not require source placeholder'
    Assert-CzxtTrue (-not ($projectManifest.Files -ccontains '借鉴区/事项/.gitkeep')) `
      'project mode must not require item placeholder'
  }

  Invoke-CzxtContract 'borrowing asset check reports missing critical leaf without throwing' {
    $failures = New-Object 'Collections.Generic.List[string]'
    $passes = New-Object 'Collections.Generic.List[string]'
    Test-CzxtBorrowingAssets -Root $templateRoot -RootMode template `
      -Failures $failures -Passes $passes
    Assert-CzxtEqual 0 $failures.Count ('template asset failures: ' + ($failures -join ' | '))

    $missingRoot = Join-Path $env:TEMP ('czxt-p4a-borrowing-assets-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $missingRoot -Force)
    try {
      $missingFailures = New-Object 'Collections.Generic.List[string]'
      $missingPasses = New-Object 'Collections.Generic.List[string]'
      Test-CzxtBorrowingAssets -Root $missingRoot -RootMode project `
        -Failures $missingFailures -Passes $missingPasses
      Assert-CzxtTrue (($missingFailures -join "`n").Contains(
          '能力资产/tools/scripts/check-os/p4t/borrowing-source-git.ps1')) `
        'missing source Git leaf was not reported'
      Assert-CzxtTrue (($missingFailures -join "`n").Contains('.czxt-project-root')) `
        'missing project marker was not reported'
    }
    finally {
      if (Test-Path -LiteralPath $missingRoot) {
        Remove-Item -LiteralPath $missingRoot -Recurse -Force
      }
    }
  }

  Invoke-CzxtContract 'borrowing asset check rejects unknown mode without throwing' {
    $failures = New-Object 'Collections.Generic.List[string]'
    $passes = New-Object 'Collections.Generic.List[string]'
    Test-CzxtBorrowingAssets -Root $templateRoot -RootMode unknown `
      -Failures $failures -Passes $passes
    Assert-CzxtTrue (($failures -join "`n").Contains('借鉴资产根模式非法')) `
      'unknown mode was not rejected'
  }
}

Invoke-CzxtContract 'P4a basic delegates borrowing checks only through assets aggregator' {
  $text = [IO.File]::ReadAllText($p4aPath)
  Assert-CzxtTrue ($text.Contains('. (Join-Path $PSScriptRoot "p4a-borrowing-assets.ps1")')) `
    'P4a basic does not load borrowing assets aggregator'
  Assert-CzxtTrue ($text.Contains('Test-CzxtBorrowingAssets -Root')) `
    'P4a basic does not call borrowing assets aggregator'
  Assert-CzxtTrue (-not $text.Contains('. (Join-Path $PSScriptRoot "p4a-borrowing-scaffold.ps1")')) `
    'P4a basic still loads borrowing scaffold directly'
  Assert-CzxtTrue (-not $text.Contains('Test-CzxtBorrowingScaffold -Root')) `
    'P4a basic still calls borrowing scaffold directly'
}

Complete-CzxtContracts
