$ErrorActionPreference = 'Stop'

$script:CzxtBorrowingScaffoldHelper = Join-Path $PSScriptRoot 'p4a-borrowing-scaffold.ps1'

function Add-CzxtBorrowingAssetPrefix {
  param([string]$Prefix, [string[]]$Names)
  return @($Names | ForEach-Object { $Prefix + $_ + '.ps1' })
}

function Get-CzxtBorrowingAssetManifest {
  param([string]$RootMode)

  $files = @(
    '借鉴区/README.md',
    '借鉴区/.gitignore',
    '借鉴区/模板/来源版本卡.md',
    '借鉴区/模板/借鉴卡.md',
    '能力资产/rules/借鉴治理.md',
    '能力资产/skills/借鉴.md',
    '能力资产/skills/借鉴-命令附录.md',
    '操作系统/07_完整工作流/借鉴闭环.md',
    '能力资产/tools/scripts/check-readme-indexes/borrowing-governance-anchor.ps1',
    '能力资产/tools/scripts/installer-borrowing-zone.ps1',
    '能力资产/tools/scripts/installer-borrowing-skeleton.ps1',
    '能力资产/tools/scripts/installer-path-safety.ps1',
    '能力资产/tools/scripts/installer-file-safety.ps1',
    '能力资产/tools/scripts/installer-source-copy.ps1',
    '能力资产/tools/scripts/installer-handle-lease.ps1',
    '能力资产/tools/scripts/installer-replace-transaction.ps1',
    '能力资产/tools/scripts/installer-output-manifest.ps1',
    '能力资产/tools/scripts/installer-tree-plan.ps1',
    '能力资产/tools/scripts/installer-copy-expectation.ps1',
    '能力资产/tools/scripts/check-os/p4a-borrowing-assets.ps1',
    '能力资产/tools/scripts/check-os/p4a-borrowing-scaffold.ps1',
    '能力资产/tools/scripts/check-os/framework-scope.ps1',
    '能力资产/tools/scripts/capture-borrowing-source.ps1',
    '能力资产/tools/scripts/close-borrowing-item.ps1',
    '能力资产/tools/scripts/borrowing-close-candidate.ps1',
    '能力资产/tools/scripts/borrowing-close-transaction.ps1',
    '能力资产/tools/scripts/borrowing-close-staging.ps1',
    '能力资产/tools/scripts/borrowing-owned-directory.ps1',
    '能力资产/tools/scripts/borrowing-owned-file.ps1',
    '能力资产/tools/scripts/seal-borrowing-item.ps1',
    '能力资产/tools/scripts/borrowing-seal-transaction.ps1',
    '能力资产/tools/scripts/borrowing-conditional-replace.ps1',
    '能力资产/tools/scripts/borrowing-seal-attestation.ps1',
    '能力资产/tools/scripts/borrowing-owned-object.ps1',
    '能力资产/tools/scripts/check-os/p4t-borrowing-consistency.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-capture-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-owned-rename-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-owned-tree-seal-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-capture-git-auxiliary-cleanup-cases.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-capture-test-support.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-contract-support.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-template-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-p4a-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-instance-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-path-safety-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-file-cas-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-installer-race-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-recovery-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-directory-lock-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-transaction-window-contracts.ps1',
    '能力资产/tools/scripts/check-os/tests/borrowing-assets-p4a-contracts.ps1'
  )
  $files += Add-CzxtBorrowingAssetPrefix `
    '能力资产/tools/scripts/borrowing-capture/' @(
      'common', 'credential-safety', 'file-safety', 'file-safety-relation', 'git', 'git-cache',
      'git-capture', 'git-input', 'git-runner', 'json-parser', 'local',
      'local-capture', 'local-identity', 'local-manifest', 'orchestrator',
      'orchestrator-operations', 'orchestrator-path-guards', 'orchestrator-seals',
      'orchestrator-preparation', 'orchestrator-transaction',
      'orchestrator-validation', 'owned-staging', 'owned-staging-cleanup',
      'owned-staging-content', 'owned-tree-seal-native',
      'owned-tree-seal-inventory', 'owned-tree-seal',
      'owned-tree-seal-remove', 'p4t-component-seal', 'p4t-runner',
      'process', 'process-encoding',
      'source-candidate-cache', 'source-candidate-cache-layout', 'source-candidate-card',
      'source-candidate-fact-primitives', 'source-candidate-facts',
      'source-candidate-fingerprint', 'source-candidate-fingerprint-local',
      'source-candidate-fingerprint-web', 'source-candidate-identity',
      'source-candidate-parser', 'source-candidate-permissions',
      'source-candidate-validator', 'source-card', 'source-card-renderer',
      'source-card-skeleton', 'staging-failure', 'transaction',
      'transaction-result', 'trusted-file-read', 'web', 'web-json'
    )
  $files += Add-CzxtBorrowingAssetPrefix `
    '能力资产/tools/scripts/check-os/p4t/' @(
      'borrowing-common', 'borrowing-mode', 'borrowing-source-cards',
      'borrowing-source-inventory', 'borrowing-source-git',
      'borrowing-source-references', 'borrowing-source-safety',
      'borrowing-item-cards', 'borrowing-item-inventory',
      'borrowing-item-parser', 'borrowing-item-references',
      'borrowing-item-state', 'borrowing-item-closure',
      'borrowing-items', 'borrowing-isolation', 'borrowing-isolation-snapshot',
      'borrowing-isolation-budget', 'borrowing-isolation-tree',
      'borrowing-isolation-project'
    )
  $files += Add-CzxtBorrowingAssetPrefix `
    '能力资产/tools/scripts/check-os/tests/' @(
      'borrowing-item-seal-contracts', 'p4t-borrowing-contracts',
      'borrowing-item-close-transaction-contracts',
      'p4t-borrowing-facade-cases', 'p4t-borrowing-isolation-cases',
      'p4t-borrowing-isolation-race-cases', 'p4t-borrowing-isolation-window-cases',
      'p4t-borrowing-isolation-budget-cases',
      'p4t-borrowing-item-cases', 'p4t-borrowing-item-closure-cases',
      'p4t-borrowing-item-permission-cases',
      'p4t-borrowing-item-reference-cases', 'p4t-borrowing-item-state-cases',
      'p4t-borrowing-item-test-support', 'p4t-borrowing-item-valid-cases',
      'p4t-borrowing-mode-cases', 'p4t-borrowing-safety-test-support',
      'p4t-borrowing-source-cache-cases',
      'p4t-borrowing-source-cache-test-support',
      'p4t-borrowing-source-cases', 'p4t-borrowing-source-permission-cases',
      'p4t-borrowing-source-retirement-cases',
      'p4t-borrowing-source-schema-cases',
      'p4t-borrowing-source-test-support',
      'p4t-borrowing-source-valid-cases', 'p4t-borrowing-test-support'
    )

  if ($RootMode -eq 'template') {
    $files += @(
      '.czxt-template-root',
      '实例化项目.ps1',
      '借鉴区/来源/.gitkeep',
      '借鉴区/事项/.gitkeep'
    )
  } elseif ($RootMode -eq 'project') {
    $files += '.czxt-project-root'
  }

  return [pscustomobject]@{
    Files = [string[]]$files
    Directories = [string[]]@(
      '借鉴区', '借鉴区/模板', '借鉴区/来源', '借鉴区/事项',
      '能力资产/tools/scripts/borrowing-capture',
      '能力资产/tools/scripts/check-os/p4t'
    )
  }
}

function Test-CzxtBorrowingAssetPath {
  param(
    [string]$Root,
    [string]$RelativePath,
    [ValidateSet('Leaf', 'Container')][string]$PathType,
    [object]$Failures,
    [object]$Passes
  )
  $path = Join-Path $Root ($RelativePath.Replace('/', '\'))
  if (Test-Path -LiteralPath $path -PathType $PathType) {
    $Passes.Add($RelativePath)
    return
  }
  $label = if ($PathType -eq 'Leaf') { '文件' } else { '目录' }
  $Failures.Add(('🔴 借鉴资产缺必查{0}：{1}' -f $label, $RelativePath))
}

function Test-CzxtBorrowingAssets {
  param(
    [string]$Root,
    [string]$RootMode,
    [object]$Failures,
    [object]$Passes
  )
  if ($RootMode -notin @('template', 'project')) {
    $Failures.Add(('🔴 借鉴资产根模式非法：{0}' -f $RootMode))
    return
  }

  $manifest = Get-CzxtBorrowingAssetManifest -RootMode $RootMode
  foreach ($relativePath in $manifest.Files) {
    Test-CzxtBorrowingAssetPath -Root $Root -RelativePath $relativePath `
      -PathType Leaf -Failures $Failures -Passes $Passes
  }
  foreach ($relativePath in $manifest.Directories) {
    Test-CzxtBorrowingAssetPath -Root $Root -RelativePath $relativePath `
      -PathType Container -Failures $Failures -Passes $Passes
  }

  if (Test-Path -LiteralPath $script:CzxtBorrowingScaffoldHelper -PathType Leaf) {
    . $script:CzxtBorrowingScaffoldHelper
    Test-CzxtBorrowingScaffold -Root $Root -RootMode $RootMode `
      -Failures $Failures -Passes $Passes
  }
}
