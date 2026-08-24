[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-guards.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-guard.ps1')

function Assert-BorrowingSelfTestThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected rejection: {0}" -f $Context)
}

Invoke-CzxtContract 'self-test table parser accepts the pipe-free capture format' {
  $table = @'
| 标识 | 固定格式 |
|---|---|
| source_type | git / local / web |
| capture_id | <source_type>-<YYYYMMDD>-<12hex> |
'@
  Assert-BorrowingTableRow $table @('source_type', 'git / local / web') 'source type row'
  Assert-BorrowingTableRow $table @('capture_id', '<source_type>-<YYYYMMDD>-<12hex>') 'capture ID row'
}

Invoke-CzxtContract 'self-test section parser ignores fenced headings but preserves fenced body' {
  $fencedOnly = @'
```markdown
## 共同前置检查
伪规范
```
'@
  Assert-BorrowingSelfTestThrows {
    [void](Get-BorrowingMarkdownSection $fencedOnly '共同前置检查')
  } 'heading exists only inside a fence'
  $real = @'
## 共同前置检查
正文起点
```markdown
## 接入
围栏内示例仍属于正文
```
正文终点
## 接入
外部下一节
'@
  $section = Get-BorrowingMarkdownSection $real '共同前置检查'
  Assert-BorrowingDocContainsAll $section @(
    '正文起点', '## 接入', '围栏内示例仍属于正文', '正文终点'
  ) 'fence-aware real section body'
  Assert-CzxtTrue (-not $section.Contains('外部下一节')) 'real next heading did not end section'
}

Invoke-CzxtContract 'self-test section parser honors long tilde fences' {
  $text = @'
~~~~markdown
## 共同前置检查
~~~
仍在四波浪围栏内
~~~~
## 共同前置检查
真实正文
'@
  $section = Get-BorrowingMarkdownSection $text '共同前置检查'
  Assert-CzxtTrue ($section.Trim() -ceq '真实正文') 'long tilde fence closed too early'
}

Invoke-CzxtContract 'self-test fenced-only item h3 cannot satisfy a body area' {
  $text = @'
## 借鉴卡
```markdown
### 问题与成功标准
伪正文区
```
'@
  $item = Get-BorrowingMarkdownSection $text '借鉴卡'
  Assert-BorrowingSelfTestThrows {
    [void](Get-BorrowingMarkdownSection $item '问题与成功标准' 3)
  } 'item h3 exists only inside a fence'
}

Invoke-CzxtContract 'self-test README guard blocks inventory and normative escapes' {
  $unsafe = @(
    "## 来源清单`n",
    "## 来源列表`n| 名称 | 版本 | 状态 |`n|---|---|---|`n| example | v1 | ready |`n",
    "### 事项台账`n",
    "## 来源/事项索引`n",
    "| 来源 | 版本 |`n|---|---|`n",
    "| 事项名称 | 状态 |`n|---|---|`n",
    "| **来源** | [版本](#version) | _状态_ | 备注 |`n|---|---|---|---|`n",
    "| [参考来源](reference.md) | `capture_id` | 说明 |`n|---|---|---|`n",
    ('| `名称` | `版本` | `状态` |' + "`n|---|---|---|`n"),
    "| 权限字段 | 允许值 | 默认值 |`n|---|---|---|`n",
    "| 权限维度 | 生效值 | 授权时间 | 授权来源 | 适用范围 |`n|---|---|---|---|---|`n",
    "| lifecycle_status | 允许 decision | 必须满足 |`n|---|---|---|`n",
    "| 旧状态 | 新状态 | decision/条件 |`n|---|---|---|`n"
  )
  foreach ($text in $unsafe) {
    Assert-BorrowingSelfTestThrows { Assert-BorrowingReadmeProjectionOnly $text 'fixture' } $text.Trim()
  }
}

Invoke-CzxtContract 'self-test README guard permits static navigation and trigger tables' {
  $safe = @'
| 文件 | 一句话 |
|---|---|
| 借鉴治理.md | 静态规则导航 |

| 触发 | 进入哪个 workflow |
|---|---|
| 参考 / 吸收 | [借鉴闭环.md](借鉴闭环.md) |
'@
  Assert-BorrowingReadmeProjectionOnly $safe 'safe README fixture'
}

Invoke-CzxtContract 'self-test A B C ownership ignores explanatory cross references' {
  $sections = @{
    A = "- 只读比较`n说明：远端取源属于 B 类。"
    B = "- 远端取源`n说明：路径逃逸属于 C 类。"
    C = '- 路径逃逸'
  }
  Assert-BorrowingActionOwnership $sections 'A' @('只读比较') 'A ownership fixture'
  Assert-BorrowingActionOwnership $sections 'B' @('远端取源') 'B ownership fixture'
  Assert-BorrowingActionOwnership $sections 'C' @('路径逃逸') 'C ownership fixture'
  $fencedAction = @'
```markdown
- 只读比较
```
'@
  $fenced = @{
    A = $fencedAction
    B = '- 远端取源'
    C = '- 路径逃逸'
  }
  Assert-BorrowingSelfTestThrows {
    Assert-BorrowingActionOwnership $fenced 'A' @('只读比较') 'fenced action fixture'
  } 'A action exists only inside a fence'
  $misclassified = @{
    A = "- 只读比较`n- 远端取源"
    B = '说明远端取源需要确认。'
    C = '- 路径逃逸'
  }
  Assert-BorrowingSelfTestThrows {
    Assert-BorrowingActionOwnership $misclassified 'B' @('远端取源') 'misclassification fixture'
  } 'misclassified exact action item'
}

Invoke-CzxtContract 'self-test command guard blocks optioned Git and every internal helper' {
  $unsafe = @(
    'git -c core.hooksPath=NUL clone https://example.invalid/repo.git',
    'git.exe --no-optional-locks fetch origin main',
    'borrowing-capture/git.ps1',
    'borrowing-capture\local.ps1',
    'borrowing-capture/web.ps1',
    'source-candidate-validator.ps1',
    'CoPy-ItEm source target',
    'GET-FILEHASH source',
    '-rUnNeR injected',
    '-TrAnSpOrT fake',
    'ScRiPtBlOcK payload',
    'GIT-RUNNER.PS1'
  )
  foreach ($text in $unsafe) {
    Assert-BorrowingSelfTestThrows { Assert-BorrowingCommandPublicSurface $text } $text
  }
  Assert-BorrowingCommandPublicSurface 'capture-borrowing-source.ps1；Git 安全参数由执行器落实。'
}

Invoke-CzxtContract 'self-test workflow trigger accepts any trigger-word order' {
  $unordered = @'
| 触发 | 进入哪个 workflow |
|---|---|
| 吸收 / 对标 / 借鉴 / 参考 | [借鉴闭环.md](借鉴闭环.md) |
'@
  Assert-BorrowingWorkflowTriggerProjection $unordered
  $triggerCell = '吸收 / 对标 / 借鉴 / 参考'
  foreach ($word in @('借鉴', '参考', '对标', '吸收')) {
    $remaining = @(($triggerCell -split ' / ') | Where-Object { $_ -cne $word }) -join ' / '
    $missing = $unordered.Replace($triggerCell, $remaining)
    Assert-BorrowingSelfTestThrows {
      Assert-BorrowingWorkflowTriggerProjection $missing
    } ("missing workflow trigger word: {0}" -f $word)
  }
}

Complete-CzxtContracts
