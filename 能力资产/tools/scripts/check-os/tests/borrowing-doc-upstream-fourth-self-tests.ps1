[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-artifact-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-git-plan-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-parameter-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-web-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-resource-cases.ps1')

function Assert-BorrowingFourthThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected fourth-review rejection: {0}" -f $Context)
}

function New-BorrowingFourthTable {
  param([string[]]$Header, [object[]]$Rows)
  $lines = @(
    ('| ' + ($Header -join ' | ') + ' |')
    ('|' + (@($Header | ForEach-Object { '---' }) -join '|') + '|')
  )
  foreach ($row in $Rows) { $lines += '| ' + ($row -join ' | ') + ' |' }
  return ($lines -join "`n") + "`n"
}

function Assert-BorrowingFourthTableMutations {
  param(
    [string[]]$Header,
    [object[]]$Rows,
    [object[]]$Mutations,
    [string]$Context
  )
  $valid = New-BorrowingFourthTable $Header $Rows
  Assert-BorrowingExactOrderedTable $valid $Header $Rows ("valid {0}" -f $Context)
  foreach ($mutation in $Mutations) {
    $invalid = $valid.Replace($mutation[0], $mutation[1])
    Assert-BorrowingFourthThrows {
      Assert-BorrowingExactOrderedTable $invalid $Header $Rows ("invalid {0}" -f $Context)
    } $Context
  }
}

Invoke-CzxtContract 'fourth-review self-test rejects local-state and card projection drift' {
  Assert-BorrowingFourthTableMutations @('本机状态项', '精确合同') `
    (Get-BorrowingLocalStateArtifactRows) @(
      @('capture.local.json', 'source.local.json'),
      @('使用既有 canonical JSON string 算法', '使用任意 JSON string 算法'),
      @('UTF-8 无 BOM；恰好一个末尾 LF', 'UTF-8 BOM；任意换行'),
      @('同卷 staging 内原子写入', '直接写正式目录'),
      @('既有 tracked 与现存 cache 字节/mtime 不变', '覆盖既有 cache')
    ) 'capture local-state bytes'
  Assert-BorrowingFourthTableMutations @('来源卡投影项', '精确合同') `
    (Get-BorrowingSourceCardProjectionRows) @(
      @('UTC yyyy-MM-ddTHH:mm:ss.fffZ', '本地时间'),
      @('使用同一值', '分别取当前时间'),
      @('每个 data cell 均为 not-applicable', '留空'),
      @('所有偏离默认的规范化授权 time/source/scope', '只比较权限值')
    ) 'source-card projection'
  Assert-BorrowingFourthTableMutations @('卡片输入项', '精确合同') `
    (Get-BorrowingCardInputSafetyRows) @(
      @('UTF-8 512 字节以内', '不限长度'),
      @('与 source_id 格式相同', '任意显示名'),
      @('非权威', '唯一验收证据')
    ) 'source-card input safety'
}

Invoke-CzxtContract 'fourth-review self-test rejects Web artifact and strict-parser drift' {
  Assert-BorrowingFourthTableMutations @('Web 快照项', '精确合同') `
    (Get-BorrowingWebSnapshotArtifactRows) @(
      @('response.metadata.json', 'metadata.json'),
      @('恰好一个末尾 LF', '无固定结尾'),
      @('canonical 计量包含末尾 LF', '不计末尾 LF'),
      @('不得做大小写归一', '自动转小写')
    ) 'Web snapshot bytes'
  Assert-BorrowingFourthTableMutations @('Web 规范化项', '精确合同') `
    (Get-BorrowingWebNormalizationRows) @(
      @('Match.Length=输入长度', '仅 IsMatch'),
      @('必须已为小写', '接受大写')
    ) 'MIME full match'
}

Invoke-CzxtContract 'fourth-review self-test rejects unsafe Git plan and cache drift' {
  Assert-BorrowingFourthTableMutations @('Git 步骤', '精确合同') `
    (Get-BorrowingGitCommandPlanRows) @(
      @('ls-remote --refs --exit-code', 'ls-remote'),
      @('--no-write-fetch-head', '--write-fetch-head'),
      @('且等于 ls-remote advertised oid', '且不比较远端 oid'),
      @('不得 checkout', 'checkout 工作树')
    ) 'Git command plan'
  Assert-BorrowingFourthTableMutations @('Git runner 项', '精确合同') `
    (Get-BorrowingGitRunnerRows) @(
      @('移除全部 GIT_*', '继承全部 GIT_*'),
      @('GIT_TERMINAL_PROMPT=0', 'GIT_TERMINAL_PROMPT=1'),
      @('taskkill.exe /PID <pid> /T /F', '仅停止等待'),
      @('不得穿透 façade', '允许 façade 注入')
    ) 'Git runner hardening'
  Assert-BorrowingFourthTableMutations @('Git cache 项', '精确合同') `
    (Get-BorrowingGitCacheRows) @(
      @('拒绝重复键、include、includeIf、remote.*', '允许 remote.origin.url'),
      @('--unreachable', '--no-dangling'),
      @('NumberOfLinks=1', '忽略 hardlink'),
      @('禁止 smudge/下载/执行', '自动下载')
    ) 'Git cache allowlist'
}

Invoke-CzxtContract 'fourth-review self-test rejects host and capture-stage regressions' {
  Assert-BorrowingFourthTableMutations @('参数边界项', '精确合同') `
    (Get-BorrowingFacadeParameterRows) @(
      @('显式业务参数', '含隐式 common parameters'),
      @('固定 12 行不保证', '固定 12 行保证'),
      @('仅 powershell -File', '支持任意内嵌调用'),
      @('-Root $PWD.Path', '-Root $PWD')
    ) 'PowerShell host boundary'
  Assert-BorrowingFourthTableMutations @(
    '失败场景', 'stage', 'reason_code', '文件系统结果'
  ) (Get-BorrowingCaptureRedDecisionRows) @(
    @('capture_path=none', 'capture_path=正式目录'),
    @('发生在 P4t-before 前', '发生在 P4t-after 后'),
    @('source-unsafe', 'capture-failed')
  ) 'capture RED classification'
}

Complete-CzxtContracts
