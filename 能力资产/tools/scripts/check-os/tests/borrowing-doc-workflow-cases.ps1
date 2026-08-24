$ErrorActionPreference = 'Stop'

$script:BorrowingRootModeRows = @(
  @('project-only', 'project', '允许写入型接入/建卡/状态变更'),
  @('template-only', 'template', '仅允许模板模式只读 P4t 审计'),
  @('无标记', 'unknown', '零写入；硬失败'),
  @('双标记', 'conflict', '零写入；硬失败')
)
$script:BorrowingRootModeReturnLine = 'RootMode 函数只返回 `project` / `template` / `unknown` / `conflict`；禁止返回“项目模式”“模板模式”等人类标签。'
$script:BorrowingCapturePromotionRows = @(
  @('1', 'candidate validator/候选校验', 'staging 候选卡可声明 capture_status: ready；exit 0'),
  @('2', '晋升前根 P4t', 'exit 0'),
  @('3', '原子移动', 'staging→目标 capture'),
  @('4', '晋升后根 P4t', 'exit 0'),
  @('5', '正式 ready', '前后根 P4t 均 exit 0 后才确认/输出')
)
$script:BorrowingCaptureFailureRows = @(
  @('candidate validator 或任一根 P4t exit 5/10', '不得晋升为 ready'),
  @('晋升后根 P4t exit 5/10', '原子移回 staging；不得保留 ready'),
  @('独立审计 exit 5', '仅 WARN；不得推进任何状态'),
  @('独立审计 exit 10', 'FAIL；硬失败；不得推进任何状态；不得修复写入')
)

. (Join-Path $PSScriptRoot 'borrowing-doc-workflow-quality-cases.ps1')

function Invoke-BorrowingDocWorkflowCases {
  param([string]$Root)
  $relative = '操作系统/07_完整工作流/借鉴闭环.md'
  $indexRelative = '操作系统/07_完整工作流/README.md'

  Invoke-CzxtContract 'borrowing workflow document exists' {
    Assert-CzxtTrue (Test-BorrowingDocFile $Root $relative) ("missing file: {0}" -f $relative)
  }

  if (Test-BorrowingDocFile $Root $relative) {
    $text = Get-BorrowingDocText $Root $relative
    Invoke-BorrowingWorkflowQualityCases -Text $text

    Invoke-CzxtContract 'borrowing workflow locks exact RootMode returns and permissions' {
      $section = Get-BorrowingMarkdownSection $text '进入条件'
      Assert-BorrowingExactOrderedTable $section @(
        'marker 组合', 'RootMode 实际返回值', 'workflow 权限'
      ) $script:BorrowingRootModeRows 'workflow RootMode table'
      Assert-BorrowingLineSequence $section @($script:BorrowingRootModeReturnLine) `
        'workflow RootMode machine return values'
    }

    Invoke-CzxtContract 'borrowing workflow locks capture double gates and rollback' {
      $section = Get-BorrowingMarkdownSection $text '失败恢复'
      Assert-BorrowingExactOrderedTable $section @('顺序', '捕获晋升步骤', '精确结果') `
        $script:BorrowingCapturePromotionRows 'capture promotion double-gate table'
      Assert-BorrowingExactOrderedTable $section @('事件', '精确结果') `
        $script:BorrowingCaptureFailureRows 'capture promotion failure table'
    }

    Invoke-CzxtContract 'borrowing workflow locks exact role and path-owner rows' {
      $section = Get-BorrowingMarkdownSection $text '角色流'
      $roleRows = @(
        @('项目 PM', '编排与路由', '不借此扩大路径白名单'),
        @('操作系统 PM', '管理来源与卡片', '借鉴区/** 与 framework 白名单'),
        @('目标决策 PM', '仅提供领域评估结论', '不写来源卡或事项卡'),
        @('测试 PM', '制定验证策略', '不替代目标路径责任 PM')
      )
      Assert-BorrowingExactTable $section @('角色', '本闭环职责', '写入边界') $roleRows 'workflow role table'
      $pathRows = @(
        @('framework', '操作系统 PM'), @('需求', '产品 PM'),
        @('业务/测试代码', '开发 PM'), @('发布', '测试发布 PM；仍需另行授权')
      )
      Assert-BorrowingExactTable $section @('目标路径', '责任 PM/实施载体') $pathRows 'workflow path-owner table'
    }

    Invoke-CzxtContract 'borrowing workflow locks every adjacent transition row' {
      $section = Get-BorrowingMarkdownSection $text '状态流'
      $rows = @(
        @('none', 'draft', 'pending；首次记录'),
        @('draft', 'assessing', 'pending；至少一个 ready capture'),
        @('assessing', 'implementation_ready', 'adopt / adapt；Q1-Q7、L1-L4 与审批通过'),
        @('assessing', 'parked', 'defer；有恢复条件或复查时间'),
        @('assessing', 'closed', 'reject；有评估证据与拒绝理由；进入关闭事务'),
        @('parked', 'assessing', 'pending / adopt / adapt / reject / defer；恢复条件满足'),
        @('implementation_ready', 'implementing', 'adopt / adapt；范围与责任角色确定'),
        @('implementing', 'verifying', 'adopt / adapt；实施记录存在'),
        @('verifying', 'closed', 'adopt / adapt；fresh 验证证据完成；进入关闭事务'),
        @('任一活动状态', 'cancelled', '任意；有取消原因')
      )
      Assert-BorrowingExactTable $section @('旧状态', '新状态', 'decision/条件') $rows 'workflow transition table'
      Assert-BorrowingDocMatchCount $text '(?m)^##\s+状态流\s*$' 1 'workflow transition source count'
    }

    Invoke-CzxtContract 'borrowing workflow locks history blocked and terminal invariants' {
      $section = Get-BorrowingMarkdownSection $text '状态流'
      Assert-BorrowingDocContainsAll $section @(
        'blocked=true 只允许活动状态', 'blocked_from', 'reason', 'resume_condition',
        '解除后回到原状态', '状态变化必须追加历史', '时间非递减',
        'adopt` 要求每个 capture 的 `reuse_scope=copy-internal-approved',
        'adapt` 要求每个 capture 的 `reuse_scope=adapt-internal-approved',
        '其他范围不建立隐式权限层级',
        '历史末行的 lifecycle_status 与 frontmatter 当前值一致',
        '历史末行的 decision 与 frontmatter 当前值一致'
      ) 'workflow state invariants'
    }

    Invoke-CzxtContract 'borrowing workflow covers decisions approvals recovery and release' {
      $decision = Get-BorrowingMarkdownSection $text '决策与审批'
      Assert-BorrowingDocContainsAll $decision @(
        'pending', 'adopt', 'adapt', 'reject', 'defer', 'Q1-Q7', 'L1-L4', '审批'
      ) 'workflow decisions and approvals'
      $recovery = Get-BorrowingMarkdownSection $text '失败恢复'
      Assert-BorrowingDocContainsAll $recovery @(
        '捕获失败', '不生成 ready', '验证失败', '保留在 verifying',
        '不 reset', '不静默删除'
      ) 'workflow recovery'
      Assert-BorrowingOrderedText $recovery @(
        '刷新失败', '旧 capture 与旧事项不受影响',
        'fingerprint 不变返回 REUSED', 'fingerprint 改变才新增 capture',
        '旧事项保持原 source_id + capture_id + fingerprint 引用',
        '不得自动跟随新 capture'
      ) 'workflow refresh immutability'
      $completion = Get-BorrowingMarkdownSection $text '完成条件'
      Assert-BorrowingDocContainsAll $completion @('发布', '另行授权') 'workflow release authorization'
      Assert-BorrowingOrderedText $completion @(
        'close-borrowing-item.ps1', 'seal-borrowing-item.ps1', '根 P4t', 'exit 0'
      ) 'workflow trusted close entry'
    }

    Invoke-CzxtContract 'borrowing workflow does not duplicate schema or permission enums' {
      Assert-BorrowingDocExcludesAll $text @(
        'schema: borrowing-source/v1', 'schema: borrowing-item/v1',
        '| source_id | capture_id | fingerprint |',
        '| 权限字段 | 允许值 | 默认值 |',
        'rights_status=unverified|verified|restricted',
        'reuse_scope=inspect-and-analyze-only|copy-internal-approved'
      ) 'workflow responsibility boundary'
    }
  }

  Invoke-CzxtContract 'workflow index has one file row and one same-line trigger row' {
    $index = Get-BorrowingDocText $Root $indexRelative
    Assert-BorrowingIndexLink $index '文件清单' '借鉴闭环.md' '借鉴闭环.md' 1
    $trigger = Get-BorrowingMarkdownSection $index '速记 — 流程触发表'
    Assert-BorrowingWorkflowTriggerProjection $trigger
    Assert-BorrowingDocMatchCount $index '\[借鉴闭环\.md\]\(借鉴闭环\.md\)' 2 'workflow index total projection count'
  }
}
