$ErrorActionPreference = 'Stop'

$script:BorrowingTrustedRootModeLine = '必须从固定受信任路径 `能力资产/tools/scripts/check-os/framework-scope.ps1` dot-source 后调用 `Get-CzxtRootMode`；操作者不得替换加载路径。'
$script:BorrowingStagingFailureLines = @(
  '零写入 preflight 失败：staging 输出固定为 `none（未创建）`。',
  '仅在已有 staging 时输出其规范化路径。'
)

. (Join-Path $PSScriptRoot 'borrowing-doc-skill-workflow-contract-data.ps1')

function Invoke-BorrowingSkillMainCases {
  param([string]$Text)

  Invoke-CzxtContract 'borrowing Skill locks triggers and four modes in its section' {
    $section = Get-BorrowingMarkdownSection $Text '触发与模式'
    Assert-BorrowingDocContainsAll $Text @('name: borrowing', 'type: procedural') 'Skill frontmatter'
    Assert-BorrowingDocContainsAll $section @(
      '借鉴', '参考', '对标', '吸收', '学习其他项目',
      '添加参考源', '更新参考源', '审计参考源',
      '接入', '评估', '落地', '审计'
    ) 'Skill trigger and mode section'
  }

  Invoke-CzxtContract 'borrowing Skill common preflight has the required line order' {
    $preflight = Get-BorrowingMarkdownSection $Text '共同前置检查'
    Assert-BorrowingOrderedText $preflight @(
      '目标问题', '来源', '允许动作', 'A/B/C', '任何写入前',
      'Get-CzxtRootMode', 'project-only'
    ) 'Skill shared preflight order'
    Assert-BorrowingDocContainsAll $preflight @(
      'template-only', 'unknown', 'conflict', '零写入拒绝',
      'staging', '卡片', 'local state'
    ) 'Skill shared preflight refusal'
  }

  Invoke-CzxtContract 'borrowing Skill locks the trusted RootMode loader path' {
    $preflight = Get-BorrowingMarkdownSection $Text '共同前置检查'
    Assert-BorrowingLineSequence $preflight @($script:BorrowingTrustedRootModeLine) `
      'Skill trusted RootMode loader'
  }

  Invoke-CzxtContract 'borrowing Skill locks one RootMode matrix across all modes' {
    $preflight = Get-BorrowingMarkdownSection $Text '共同前置检查'
    Assert-BorrowingExactOrderedTable $preflight @(
      'RootMode', 'Skill 允许模式', '写入边界'
    ) $script:BorrowingSkillRootModeRows 'Skill RootMode matrix'
    $access = Get-BorrowingMarkdownSection $Text '接入'
    Assert-BorrowingLineSequence $access @($script:BorrowingSkillAccessRootModeLine) `
      'Skill access RootMode refusal'
  }

  Invoke-CzxtContract 'borrowing Skill access flow references preflight then facade and ready gate' {
    $section = Get-BorrowingMarkdownSection $Text '接入'
    Assert-BorrowingOrderedText $section @(
      '共同前置检查', 'capture-borrowing-source.ps1', 'P4t', 'exit 0', 'ready'
    ) 'Skill access flow'
    Assert-BorrowingDocContainsAll $section @(
      'template-only / unknown / conflict', '前置拒绝'
    ) 'Skill access refusal reference'
  }

  Invoke-CzxtContract 'borrowing Skill evaluation flow is complete and ordered' {
    $section = Get-BorrowingMarkdownSection $Text '评估'
    Assert-BorrowingOrderedText $section @(
      '当前已有能力', '候选矩阵', '明确采纳', '明确不采纳', 'decision'
    ) 'Skill evaluation flow'
    Assert-BorrowingDocContainsAll $section @('冲突', '理由', '证据') 'Skill evaluation evidence'
  }

  Invoke-CzxtContract 'borrowing Skill delivery flow rechecks governance before evidence' {
    $section = Get-BorrowingMarkdownSection $Text '落地'
    Assert-BorrowingOrderedText $section @(
      'Q1-Q7', 'L1-L4', '审批', '目标路径', '责任 PM', '实施', 'fresh 验证证据'
    ) 'Skill delivery flow'
    Assert-BorrowingDocContainsAll $section @(
      '按目标路径白名单', 'adopt', 'copy-internal-approved',
      'adapt', 'adapt-internal-approved', '不得把其他 `reuse_scope` 推导成实施权限'
    ) 'Skill delivery ownership and source permission boundary'
  }

  Invoke-CzxtContract 'borrowing Skill audit is read-only offline and non-executing' {
    $section = Get-BorrowingMarkdownSection $Text '审计'
    Assert-BorrowingOrderedText $section @('只读', '离线', '不联网', '不执行来源内容', 'P4t') 'Skill audit flow'
    Assert-BorrowingDocContainsAll $section @('不刷新', '不写卡片') 'Skill audit zero-write boundary'
  }

  Invoke-CzxtContract 'borrowing Skill seals before P4t and exposes failure output' {
    $section = Get-BorrowingMarkdownSection $Text '关闭与失败'
    Assert-BorrowingOrderedText $section @(
      '关闭条件', 'close-borrowing-item.ps1', 'seal-borrowing-item.ps1',
      'P4t', 'exit 0', 'closed'
    ) 'Skill close flow'
    Assert-BorrowingDocContainsAll $section @(
      '不得手填', '不得重算', '失败阶段', '原因', 'staging 路径',
      '恢复建议', '不得宣称 ready', '不得宣称 closed'
    ) 'Skill failure output'
  }

  Invoke-CzxtContract 'borrowing Skill locks preflight staging failure output' {
    $section = Get-BorrowingMarkdownSection $Text '关闭与失败'
    Assert-BorrowingLineSequence $section $script:BorrowingStagingFailureLines `
      'Skill staging failure output'
  }

  Invoke-CzxtContract 'borrowing Skill locks the shared close transaction' {
    $section = Get-BorrowingMarkdownSection $Text '关闭与失败'
    $close = Get-BorrowingMarkdownSection $section '关闭事务' 3
    Assert-BorrowingExactOrderedTable $close @('关闭顺序', '精确动作', '失败边界') `
      $script:BorrowingCloseTransactionRows 'Skill close transaction table'
    Assert-BorrowingLineSequence $close @($script:BorrowingCloseScopeLine) `
      'Skill close transaction scope'
  }

  Invoke-CzxtContract 'borrowing Skill fixed output is exact and contiguous' {
    $section = Get-BorrowingMarkdownSection $Text '固定输出'
    Assert-BorrowingLineSequence $section @(
      '【借鉴闭环】',
      '事项：<borrow_id>｜状态：<status>｜决策：<decision>',
      '来源：<source_id>@<capture_id>（<fingerprint>）',
      '目标：<target files / none>',
      '验证：<evidence / pending>',
      '边界：未执行来源｜无业务直接依赖｜无外部写入',
      'P4t：PASS / WARN / FAIL'
    ) 'borrowing Skill fixed output'
  }

  Invoke-CzxtContract 'borrowing Skill does not duplicate rule or workflow truth' {
    Assert-BorrowingDocExcludesAll $Text @(
      'schema: borrowing-source/v1', 'schema: borrowing-item/v1',
      '| 权限字段 | 允许值 | 默认值 |', '| lifecycle_status | 允许 decision |',
      'none → draft', 'draft → assessing', 'implementation_ready → implementing'
    ) 'Skill responsibility boundary'
  }
}
