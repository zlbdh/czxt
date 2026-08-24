[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-parameter-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-git-plan-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-input-path-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-transaction-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-capture-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-identifier-safety-cases.ps1')

function New-BorrowingFifthTable {
  param([string[]]$Header, [object[]]$Rows)
  $lines = @(
    ('| ' + ($Header -join ' | ') + ' |')
    ('|' + (@($Header | ForEach-Object { '---' }) -join '|') + '|')
  )
  foreach ($row in $Rows) { $lines += '| ' + ($row -join ' | ') + ' |' }
  return ($lines -join "`n") + "`n"
}

function Assert-BorrowingFifthMutations {
  param([string[]]$Header, [object[]]$Rows, [object[]]$Mutations, [string]$Context)
  $valid = New-BorrowingFifthTable $Header $Rows
  Assert-BorrowingExactOrderedTable $valid $Header $Rows ("valid {0}" -f $Context)
  foreach ($mutation in $Mutations) {
    $thrown = $false
    try {
      $invalid = $valid.Replace($mutation[0], $mutation[1])
      Assert-BorrowingExactOrderedTable $invalid $Header $Rows ("invalid {0}" -f $Context)
    }
    catch { $thrown = $true }
    Assert-CzxtTrue $thrown ("expected fifth-review rejection: {0}" -f $Context)
  }
}

Invoke-CzxtContract 'fifth-review self-test rejects executable Git drift' {
  Assert-BorrowingFifthMutations @('Git 步骤', '精确合同') `
    (Get-BorrowingGitCommandPlanRows) @(
      @('update-ref --no-deref HEAD', 'symbolic-ref HEAD'),
      @('git -C <repository.git> ls-tree', 'git ls-tree'),
      @('show-ref --verify --hash', 'rev-parse refs/czxt/capture')
    ) 'Git command targeting'
  Assert-BorrowingFifthMutations @('Git runner 项', '精确合同') `
    (Get-BorrowingGitRunnerRows) @(
      @('GIT_CEILING_DIRECTORIES=runner-root', 'GIT_CEILING_DIRECTORIES=runner-root/cwd'),
      @('SSH_ASKPASS_REQUIRE', 'SSH_ASKPASS_ONLY'),
      @('UseShellExecute=false', 'UseShellExecute=true'),
      @('每流 67108864 字节', '无上限'),
      @('唯一精确匹配的 fixture locator', '任意 locator')
    ) 'Git runner isolation'
  Assert-BorrowingFifthMutations @('Git cache 项', '精确合同') `
    (Get-BorrowingGitCacheRows) @(
      @('detached', 'symbolic'),
      @('拒绝重复键', '允许重复键'),
      @('--no-progress', '--progress'),
      @('成对', '可孤立')
    ) 'Git cache canonical bytes'
  Assert-BorrowingFifthMutations @('Git config line-array 项', '精确合同') `
    (Get-BorrowingGitConfigLineArrayRows) @(
      @('<TAB>repositoryformatversion = 0', 'repositoryformatversion=0'),
      @('按序以 LF 连接', '任意换行连接')
    ) 'Git config canonical line-array'
  Assert-BorrowingFifthMutations @('Git 失败场景', 'stage / reason_code') `
    (Get-BorrowingGitFailureRows) @(
      @('candidate / source-unsafe', 'candidate / candidate-invalid'),
      @('capture / resource-limit', 'capture / capture-failed')
    ) 'Git failure projection'
}

Invoke-CzxtContract 'fifth-review self-test rejects facade language drift' {
  Assert-BorrowingFifthMutations @('参数边界项', '精确合同') `
    (Get-BorrowingFacadeParameterRows) @(
      @('完整且仅有', '至少包含'),
      @('ValueFromPipeline', '允许 pipeline')
    ) 'facade public params'
  Assert-BorrowingFifthMutations @(
    'SourceType 输入', 'source_type 卡片值', '通用必填', '类型必填', '类型禁止', '权限与授权'
  ) (Get-BorrowingFacadeSourceMatrixRows) @(
    @('GitLocator,GitRef', 'GitLocator'),
    @('三者全部禁止', '三者可选')
  ) 'facade source matrix'
  Assert-BorrowingFifthMutations @('标识安全项', '精确合同') `
    (Get-BorrowingIdentifierSafetyRows) @(
      @('1..128 ASCII bytes', '不限长度'),
      @('con/prn/aux/nul', '仅拒绝 con')
    ) 'Windows-safe identifiers'
}

Invoke-CzxtContract 'fifth-review self-test rejects Local and Web boundary drift' {
  Assert-BorrowingFifthMutations @('路径安全项', '精确合同') `
    (Get-BorrowingWindowsPathRows) @(
      @('fixed drive', '任意路径'),
      @('NumberOfLinks 必须等于 1', '链接数未知可 warning')
    ) 'Windows path identity'
  Assert-BorrowingFifthMutations @('Local 项', '精确合同') `
    (Get-BorrowingLocalCaptureRows) @(
      @('快照/manifest.tsv', 'manifest.tsv'),
      @('全链一致性', '前后两次一致'),
      @('source root identity、相对路径集合及逐文件 identity 必须相同', '只比较 manifest'),
      @('必须与 source 对应 identity 不同', '可以与 source 对应 identity 相同'),
      @('必须与 staging-content 对应 identity 相同', '必须与 source-before 对应 identity 相同')
    ) 'Local canonical snapshot'
  Assert-BorrowingFifthMutations @('Web 输入项', '精确合同') `
    (Get-BorrowingWebInputPathRows) @(
      @('文件身份三元组不同', '路径字符串不同'),
      @('不得从借鉴区回读', '允许借鉴区输入')
    ) 'Web file identity'
  Assert-BorrowingFifthMutations @('JSON 整数项', '精确合同') `
    (Get-BorrowingWebIntegerRows) @(
      @('200.0、2e2', '允许等值小数和指数'),
      @('字符串数字', '允许字符串数字')
    ) 'strict JSON integer'
}

Invoke-CzxtContract 'fifth-review self-test rejects transaction and renderer drift' {
  Assert-BorrowingFifthMutations @('事务分支', '精确合同') `
    (Get-BorrowingTransactionRows) @(
      @('不得 move', '先 move'),
      @('P4t-after=not-run', 'P4t-after=0'),
      @('禁止补偿删除或覆盖', '失败时强制删除')
    ) 'capture transaction'
  Assert-BorrowingFifthMutations @('P4t runner 项', '精确合同') `
    (Get-BorrowingP4tRunnerRows) @(
      @('1048576', 'unbounded'),
      @('/T /F', '/F')
    ) 'P4t child runner'
  Assert-BorrowingFifthMutations @('renderer 项', '精确合同') `
    (Get-BorrowingSourceCardRendererRows) @(
      @('固定 line-array renderer', '任意 Markdown renderer'),
      @('逐字节 golden', '字段级相等')
    ) 'source-card renderer'
}

Invoke-CzxtContract 'fifth-review self-test rejects missing-cache overwrite drift' {
  Assert-BorrowingFifthMutations @('幂等场景', '精确合同') `
    (Get-BorrowingIdempotencyContractRows) @(
      @('全部缺失', '部分缺失'),
      @('禁止覆盖', '允许覆盖')
    ) 'idempotent cache repair'
  Assert-BorrowingFifthMutations @('ignored cache 项', '精确合同') `
    (Get-BorrowingExpectedCacheRows) @(
      @('快照/repository.git/、capture.local.json', 'capture.local.json'),
      @('空目录也算成员', '空目录不算成员'),
      @('父快照/均不存在', '父快照/可存在'),
      @('禁止覆盖或补齐', '允许覆盖或补齐')
    ) 'ignored cache repair set'
}

Complete-CzxtContracts
