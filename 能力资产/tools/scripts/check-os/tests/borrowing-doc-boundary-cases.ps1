$ErrorActionPreference = 'Stop'

function Invoke-BorrowingDocBoundaryCases {
  param([string]$Root)
  $zoneRelative = '借鉴区/README.md'
  $ruleRelative = '能力资产/rules/借鉴治理.md'
  $skillRelative = '能力资产/skills/借鉴.md'
  $workflowRelative = '操作系统/07_完整工作流/借鉴闭环.md'

  Invoke-CzxtContract 'borrowing zone README has one resolvable main Skill link' {
    $text = Get-BorrowingDocText $Root $zoneRelative
    Assert-BorrowingRelativeLink -Root $Root -SourceRelativePath $zoneRelative `
      -Text $text -Target '../能力资产/skills/借鉴.md' -Expected 1
    Assert-BorrowingDocMatchCount $text '借鉴-命令附录\.md' 0 'zone README must not expose appendix'
    Assert-BorrowingDocNoMatch $text '\]\([^)]*(借鉴治理|借鉴闭环)\.md(?:#[^)]*)?\)' 'zone README direct rule/workflow link'
    Assert-BorrowingDocMatchCount $text '(?i)\]\([^)]*能力资产/skills/[^)]*\)' 1 'zone README total Skill links'
    Assert-BorrowingDocMatchCount $text '(?m)\[[^\]]+\]\([^)]+\)' 1 'zone README total Markdown links'
    Assert-BorrowingDocContainsAll $text @(
      'capture.local.json/v1` 只保存固定 schema 的规范化本机路径',
      '真实凭据不由借鉴区持久化', '操作系统或工具的凭据存储',
      '私有 Git / Web 内容须在借鉴区外预取',
      '新增 schema、独立 B 类授权与专用秘密存储方案'
    ) 'zone README local-secret boundary'
    Assert-BorrowingDocExcludesAll $text @(
      '私有访问参数和凭据只能进入被忽略的本机状态'
    ) 'obsolete ignored-secret persistence guidance'
  }

  Invoke-CzxtContract 'borrowing READMEs do not copy normative or active tables' {
    foreach ($relative in @(
        $zoneRelative, '能力资产/rules/README.md',
        '能力资产/skills/README.md', '操作系统/07_完整工作流/README.md'
      )) {
      $text = Get-BorrowingDocText $Root $relative
      Assert-BorrowingReadmeProjectionOnly $text $relative
      Assert-BorrowingDocExcludesAll $text @(
        'schema: borrowing-source/v1', 'schema: borrowing-item/v1',
        '| 权限字段 | 允许值 | 默认值 |',
        '| 旧状态 | 新状态 | decision/条件 |',
        '【借鉴闭环】'
      ) ("normative projection in {0}" -f $relative)
    }
  }

  if (Test-BorrowingDocFile $Root $ruleRelative) {
    Invoke-CzxtContract 'borrowing rule links to the main Skill' {
      $text = Get-BorrowingDocText $Root $ruleRelative
      Assert-BorrowingRelativeLink -Root $Root -SourceRelativePath $ruleRelative `
        -Text $text -Target '../skills/借鉴.md' -Expected 1
    }
  }

  if (Test-BorrowingDocFile $Root $skillRelative) {
    Invoke-CzxtContract 'borrowing Skill links to rule and workflow' {
      $text = Get-BorrowingDocText $Root $skillRelative
      Assert-BorrowingRelativeLink -Root $Root -SourceRelativePath $skillRelative `
        -Text $text -Target '../rules/借鉴治理.md' -Expected 1
      Assert-BorrowingRelativeLink -Root $Root -SourceRelativePath $skillRelative `
        -Text $text -Target '../../操作系统/07_完整工作流/借鉴闭环.md' -Expected 1
    }
  }

  if (Test-BorrowingDocFile $Root $workflowRelative) {
    Invoke-CzxtContract 'borrowing workflow links to rule Skill and zone' {
      $text = Get-BorrowingDocText $Root $workflowRelative
      Assert-BorrowingRelativeLink -Root $Root -SourceRelativePath $workflowRelative `
        -Text $text -Target '../../能力资产/rules/借鉴治理.md' -Expected 1
      Assert-BorrowingRelativeLink -Root $Root -SourceRelativePath $workflowRelative `
        -Text $text -Target '../../能力资产/skills/借鉴.md' -Expected 1
      Assert-BorrowingRelativeLink -Root $Root -SourceRelativePath $workflowRelative `
        -Text $text -Target '../../借鉴区/README.md' -Expected 1
    }
  }

  if ((Test-BorrowingDocFile $Root $ruleRelative) -and
      (Test-BorrowingDocFile $Root $skillRelative) -and
      (Test-BorrowingDocFile $Root $workflowRelative)) {
    Invoke-CzxtContract 'borrowing documents keep their three responsibilities disjoint' {
      $rule = Get-BorrowingDocText $Root $ruleRelative
      $skill = Get-BorrowingDocText $Root $skillRelative
      $workflow = Get-BorrowingDocText $Root $workflowRelative
      Assert-BorrowingDocContainsAll $rule @('schema', '权限模型', '行为分级') 'rule ownership'
      Assert-BorrowingDocContainsAll $skill @('触发与模式', '固定输出') 'Skill ownership'
      Assert-BorrowingDocContainsAll $workflow @('角色流', '状态流', '失败恢复') 'workflow ownership'
      Assert-BorrowingDocNoMatch $skill '(?m)^\|\s*权限字段\s*\|' 'permission table copied to Skill'
      Assert-BorrowingDocNoMatch $workflow '(?m)^\|\s*(source_id|borrow_id)\s*\|' 'schema table copied to workflow'
      Assert-BorrowingDocNoMatch $rule '(?m)^\|\s*旧状态\s*\|\s*新状态\s*\|' 'transition table copied to rule'
    }
  }
}
