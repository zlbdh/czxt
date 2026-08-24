$ErrorActionPreference = 'Stop'

function Invoke-BorrowingCrossDocumentCases {
  param([string]$Root)

  $rule = Get-BorrowingDocText $Root '能力资产/rules/借鉴治理.md'
  $design = Get-BorrowingDocText $Root `
    'Docs/3-开发文档/2026-07-18-借鉴闭环-设计规格.md'
  $appendix = Get-BorrowingDocText $Root `
    'Docs/3-开发文档/2026-07-18-借鉴闭环-设计规格-附录.md'
  $plan = Get-BorrowingDocText $Root `
    'Docs/3-开发文档/2026-07-18-借鉴闭环-实施计划-B-核心能力.md'
  $planC = Get-BorrowingDocText $Root `
    'Docs/3-开发文档/2026-07-18-借鉴闭环-实施计划-C-P4t与收口.md'
  $workflow = Get-BorrowingDocText $Root '操作系统/07_完整工作流/借鉴闭环.md'
  $skill = Get-BorrowingDocText $Root '能力资产/skills/借鉴.md'
  $commandAppendix = Get-BorrowingDocText $Root '能力资产/skills/借鉴-命令附录.md'
  $adr = Get-BorrowingDocText $Root `
    'Docs/3-开发文档/adr/ADR-039-统一借鉴区与闭环治理.md'
  $reflection = Get-BorrowingDocText $Root '操作系统/05_记忆/行为反思.md'

  Invoke-CzxtContract 'design appendix publishes a self-consistent Git ready example' {
    Assert-BorrowingLineSequence $appendix @(
      'source_type: git',
      'capture_status: ready',
      'canonical_locator: https://example.invalid/owner/repo.git',
      'fingerprint_algorithm: git-object',
      'fingerprint: <完整值>',
      'captured_at: 2026-07-18T00:00:00.000Z',
      'rights_status: unverified',
      'access_policy: source-read-only',
      'reuse_scope: inspect-and-analyze-only',
      'execution_policy: deny',
      'network_policy: source-read-only',
      'storage_policy: local-only',
      'distribution_policy: deny',
      'upstream_write_policy: deny',
      'auto_refresh: false'
    ) 'Git ready source-card example'
    Assert-BorrowingDocContainsAll $appendix @(
      'capture.local.json/v1` 只保存固定 5 键',
      '真实凭据不由借鉴区持久化', '操作系统或工具的凭据存储',
      '私有 Git / Web 内容先在借鉴区外预取',
      '新 schema、独立 B 类授权与专用秘密存储方案'
    ) 'design appendix local-secret boundary'
    Assert-BorrowingDocExcludesAll $appendix @(
      '私有访问参数进入被忽略的 `*.local.json`'
    ) 'obsolete appendix ignored-secret persistence guidance'
    Assert-BorrowingDocContainsAll $rule @(
      '`capture.local.json/v1` 固定为 5 键',
      '真实凭据不由借鉴区持久化', '操作系统或工具的凭据存储',
      '私有 Git / Web 内容必须在借鉴区外预取'
    ) 'rule local-secret boundary'
    Assert-BorrowingDocContainsAll $design @(
      'Skill 只能调用可信关闭入口 `close-borrowing-item.ps1`',
      '`seal-borrowing-item.ps1`', '完整根 P4t', '终锁复核', '锁内清理',
      '全部成功才输出 closed'
    ) 'design trusted close transaction'
    Assert-BorrowingDocExcludesAll $design @(
      '由 Skill 调用独立 seal helper'
    ) 'obsolete direct seal entry'
  }

  Invoke-CzxtContract 'core plan distinguishes marker fixtures from RootMode values' {
    Assert-BorrowingDocContainsAll $design @(
      'Skill 只能调用可信关闭入口 `close-borrowing-item.ps1`',
      '`seal-borrowing-item.ps1`', '完整根 P4t', '终锁复核', '锁内清理',
      '全部成功才输出 closed'
    ) 'design trusted close transaction'
    Assert-BorrowingDocExcludesAll $design @(
      '由 Skill 调用独立 seal helper'
    ) 'obsolete direct seal entry'
    foreach ($entry in @(
        @('rule', $rule), @('design', $design), @('ADR-039', $adr)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        'dist', 'build', '.next', 'target', 'out', '不得'
      ) ("{0} build-output isolation" -f $entry[0])
    }
    Assert-BorrowingDocContainsAll $plan @(
      '只有实际返回值为 `project` 才能继续',
      'fixture 以 `template-only` / `project-only` 表示 marker 组合',
      '实际分别返回 `template` / `project`',
      '仅 `project` 可进入',
      'RootMode=`project` preflight'
    ) 'core-plan RootMode contract'
    Assert-BorrowingDocExcludesAll $plan @(
      '只有 project-only 才能继续',
      'template-only、unknown、conflict 均 exit 10',
      'project-only preflight'
    ) 'obsolete RootMode wording'
  }

  Invoke-CzxtContract 'borrowing documents make every hardlink uncertainty fatal' {
    Assert-BorrowingDocContainsAll $appendix @(
      '任何硬链接', 'NumberOfLinks', 'API 不可用均硬失败'
    ) 'design hardlink contract'
    Assert-BorrowingDocContainsAll $planC @(
      'NumberOfLinks 必须等于 1', '无法确认则硬失败', '不得降级为 warning'
    ) 'P4t plan hardlink contract'
    Assert-BorrowingDocExcludesAll $appendix @('声明外硬链接') 'obsolete declared-hardlink exception'
    Assert-BorrowingDocExcludesAll $planC @(
      '硬失败或明确 warning'
    ) 'obsolete link warning branch'
  }

  Invoke-CzxtContract 'borrowing documents distinguish refresh reuse from new capture' {
    foreach ($entry in @(
        @('rule', $rule),
        @('workflow', $workflow),
        @('design', $design),
        @('design appendix', $appendix),
        @('ADR-039', $adr),
        @('core plan', $plan)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        'fingerprint 不变', 'REUSED', 'fingerprint 改变', '新增 capture'
      ) ("{0} refresh idempotency" -f $entry[0])
    }
    foreach ($entry in @(
        @('workflow', $workflow), @('design', $design), @('ADR-039', $adr), @('core plan', $plan)
      )) {
      Assert-BorrowingDocExcludesAll $entry[1] @(
        '刷新成功也必须新增 capture', '刷新永远新增 capture', '来源刷新必须新增 capture'
      ) ("{0} obsolete unconditional refresh creation" -f $entry[0])
    }
  }

  Invoke-CzxtContract 'borrowing documents distinguish staging candidates from formal cards' {
    Assert-BorrowingLineSequence $rule @(
      'staging 失败不生成正式卡；允许保留被忽略的候选卡与 staging。'
    ) 'rule formal-card boundary'
    Assert-BorrowingDocContainsAll $design @(
      '失败不写正式 ready 卡片', '允许保留被忽略的候选卡与 staging'
    ) 'design formal-card boundary'
    Assert-BorrowingDocContainsAll $appendix @(
      '捕获失败', '不登记正式 ready', '可保留被忽略的候选卡与 staging'
    ) 'design appendix formal-card boundary'
  }

  Invoke-CzxtContract 'borrowing documents limit same-state evidence to active states' {
    foreach ($entry in @(
        @('design appendix', $appendix),
        @('workflow', $workflow)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        '同状态追加证据', '仅限活动状态'
      ) ("{0} active same-state evidence" -f $entry[0])
    }
  }

  Invoke-CzxtContract 'borrowing documents allow only passive Git LFS and submodule detection' {
    foreach ($entry in @(
        @('rule', $rule),
        @('design', $design),
        @('design appendix', $appendix)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        'LFS', 'submodule', '只读检测', '禁止', '下载', '执行'
      ) ("{0} passive Git detection" -f $entry[0])
    }
    Assert-BorrowingDocExcludesAll $design @(
      '禁 hooks、凭据提示、LFS、submodule'
    ) 'obsolete Git total-denial wording'
  }

  Invoke-CzxtContract 'borrowing documents publish the bounded P4t isolation observation model' {
    Assert-BorrowingDocContainsAll $rule @(
      '`≤8 MiB`', '全量字节与 SHA-256', '`>8 MiB`', '前 `64 KiB`',
      '不承诺发现观测范围外的尾部同身份同长度改写',
      '`20000` 个文件', '`100000` 个目录项', '`512 MiB` 摘要读取',
      '项目卡单次 `1 MiB`', '两次合计 `2 MiB`',
      '树基线、业务扫描和最终树复核'
    ) 'rule bounded P4t observation and budgets'
    Assert-BorrowingDocContainsAll $adr @(
      '8 MiB', '64 KiB', '三轮实际读取', '全调用共享预算',
      '`20000` 个文件', '`100000` 个目录项', '`512 MiB` 摘要读取',
      '项目卡单次 `1 MiB`', '两次合计 `2 MiB`'
    ) 'ADR bounded P4t observation'
    foreach ($entry in @(@('rule', $rule), @('design appendix', $appendix))) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        '严格 UTF-8', '带 BOM 的 UTF-16LE / UTF-16BE', '非终止解码器'
      ) ($entry[0] + ' strict text decoder boundary')
    }
    Assert-BorrowingDocContainsAll $appendix @(
      '`≤8 MiB`', '全量字节与 SHA-256', '`>8 MiB`', '前 `64 KiB`',
      '三轮实际读取', '`20000` 个文件', '`100000` 个目录项',
      '`512 MiB` 摘要读取', '项目卡单次 `1 MiB`', '两次合计 `2 MiB`'
    ) 'appendix exact P4t observation and budgets'
  }

  Invoke-CzxtContract 'borrowing documents distinguish close rollback from preserved ownership evidence' {
    Assert-BorrowingDocContainsAll $rule @(
      '`stage=seal / reason_code=seal-ownership-unproven`',
      '保留当前正式卡与 staging', '不得尝试回滚',
      '材料证明已绑定当前正式对象但 `borrow_id` 不一致',
      '`content-deleted`', '不可逆完成点', '禁止回滚正式卡'
    ) 'rule close ownership and irreversible point'
    foreach ($entry in @(
        @('Skill', $skill), @('command appendix', $commandAppendix),
        @('workflow', $workflow), @('design', $design),
        @('design appendix', $appendix), @('ADR-039', $adr)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        'no-overwrite', 'seal-ownership-unproven', '保留当前正式卡与 staging',
        'borrow_id', 'content-deleted', '不可逆', '不回滚正式卡'
      ) ($entry[0] + ' close failure boundary')
    }
    Assert-BorrowingDocContainsAll $rule @(
      'target→backup', 'temporary→target', 'target 为空',
      '移动前后', 'identity', '补偿不得覆盖'
    ) 'rule seal and close no-overwrite transaction'
    foreach ($entry in @(
        @('rule', $rule), @('Skill', $skill),
        @('command appendix', $commandAppendix), @('workflow', $workflow),
        @('ADR-039', $adr)
      )) {
      Assert-BorrowingDocExcludesAll $entry[1] @(
        '任一步失败恢复原活动字节',
        'seal helper、根 P4t、终锁复核或锁内清理失败均执行恢复'
      ) ($entry[0] + ' obsolete universal rollback')
    }
    Assert-BorrowingDocExcludesAll $rule @(
      'seal 原子写入'
    ) 'obsolete seal atomic-write wording'
  }

  Invoke-CzxtContract 'borrowing close documents bind staging creation to retained handles' {
    foreach ($entry in @(
        @('rule', $rule), @('command appendix', $commandAppendix),
        @('workflow', $workflow), @('design', $design),
        @('design appendix', $appendix), @('ADR-039', $adr)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        '受信父目录句柄', '相对原子创建 staging 目录',
        '`原活动卡.bin`', '目录句柄相对 CreateNew',
        '同一 handle 写入、flush 并绑定', '文件 lease 贯穿整个事务',
        '目录保持非空', '`借鉴卡.md`', '也以目录句柄相对 CreateNew'
      ) ($entry[0] + ' close handle-relative staging creation')
      Assert-BorrowingDocExcludesAll $entry[1] @(
        '先 Verify 再绝对路径 CreateNew',
        'Verify 后再以绝对路径 CreateNew'
      ) ($entry[0] + ' obsolete verify-then-absolute-create wording')
    }
  }

  Invoke-CzxtContract 'borrowing close documents lock cleanup order and handle ownership' {
    foreach ($entry in @(
        @('rule', $rule), @('command appendix', $commandAppendix),
        @('workflow', $workflow), @('design', $design),
        @('design appendix', $appendix), @('ADR-039', $adr)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        '`Candidate→retained Original→content-deleted→directory`',
        '同一 handle 设置 delete-pending',
        '立即进入 `content-deleted`', '目录创建句柄同句柄删除',
        '验证与路径打开之间不得留窗口',
        '创建失败只删除本事务句柄绑定对象'
      ) ($entry[0] + ' close handle-bound cleanup order')
    }
    Assert-BorrowingDocContainsAll $reflection @(
      '反思 33', '受信父目录句柄', '相对 CreateNew',
      'retained Original', 'delete-pending', '`content-deleted`',
      '创建失败只删除本事务句柄绑定对象'
    ) 'reflection close handle lifetime lesson'
  }

  Invoke-CzxtContract 'borrowing close documents require one post-P4t formal-card handle' {
    foreach ($entry in @(
        @('rule', $rule), @('command appendix', $commandAppendix),
        @('workflow', $workflow), @('design', $design),
        @('design appendix', $appendix), @('ADR-039', $adr)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        'P4t exit 0 后', '单次 OPEN_REPARSE_POINT 打开',
        '同一 handle 复核 canonical path', '常规非 reparse 类型',
        'link count=1', 'identity、length 与 bytes',
        '持有到 staging 清理结束',
        '禁止“先安全路径验证再按路径重开”'
      ) ($entry[0] + ' post-P4t single-handle formal lock')
    }
    Assert-BorrowingDocContainsAll $reflection @(
      '反思 34', 'OPEN_REPARSE_POINT', 'canonical path',
      'link count=1', '持有到 staging 清理结束',
      '禁止“先安全路径验证再按路径重开”'
    ) 'reflection post-P4t formal-handle lesson'
  }

  Invoke-CzxtContract 'borrowing close documents keep formal and staging snapshots independent' {
    foreach ($entry in @(
        @('rule', $rule), @('command appendix', $commandAppendix),
        @('workflow', $workflow), @('design', $design),
        @('design appendix', $appendix), @('ADR-039', $adr)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        '正式卡所有权快照', '当前 staging 候选快照',
        '两个独立状态', '必须分别验证',
        '不得提前把 staging 期望改成 sealed 字节',
        'Set 提交后状态对象先更新'
      ) ($entry[0] + ' independent formal and staging snapshots')
    }
    Assert-BorrowingDocContainsAll $reflection @(
      '反思 35', '正式卡所有权快照', '当前 staging 候选快照',
      '两个独立状态', 'Set 提交后状态对象先更新',
      '不得提前把 staging 期望改成 sealed 字节'
    ) 'reflection independent close snapshots lesson'
  }

  Invoke-CzxtContract 'borrowing design publishes installer no-overwrite and residual-state semantics' {
    foreach ($entry in @(
        @('design', $design), @('design appendix', $appendix), @('ADR-039', $adr)
      )) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        'no-overwrite', 'target→backup', 'prepared→target',
        'GetFinalPathNameByHandleW', '物理别名', '源与目标', 'subst', '输出 manifest',
        '失败不承诺全局原子回滚', '保留可审计残留'
      ) ($entry[0] + ' installer transaction contract')
    }
    Assert-BorrowingDocContainsAll $design @(
      '每个已安装或改写输出即时登记',
      '最终 marker/成功输出前对 manifest 全部条目保持只读共享 lease'
    ) 'design exact output-manifest lease scope'
  }

  Invoke-CzxtContract 'borrowing command appendix publishes exact close diagnostics and WinPS state protocol' {
    Assert-BorrowingDocContainsAll $commandAppendix @(
      '`stage=seal / reason_code=seal-ownership-unproven`',
      '材料证明已绑定当前正式对象但 `borrow_id` 不一致',
      '可按完整快照安全恢复原活动卡',
      '带可写 `Value` 属性的显式状态对象',
      '不得使用可选 `[ref]` 参数',
      '尝试路径', '先写入状态对象', '再创建 staging 目录'
    ) 'command appendix close diagnostic and attempted-path contract'
  }

  Invoke-CzxtContract 'borrowing appendix labels the full audit range and task-start parse baseline' {
    Assert-BorrowingDocContainsAll $appendix @(
      'P4a-P4t', '任务启动基线', '124/124 ParseFile'
    ) 'appendix audit range and parse baseline'
    Assert-BorrowingDocContainsAll $design @(
      '任务启动基线', '124/124'
    ) 'design parse baseline label'
  }

  Invoke-CzxtContract 'behavior reflection limits the original universal close rollback wording' {
    Assert-BorrowingDocContainsAll $reflection @(
      '初版“失败恢复原字节”', '反思 28', '反思 31',
      'ownership 可证明', '`content-deleted`'
    ) 'reflection successor qualification for close rollback'
  }

  Invoke-CzxtContract 'borrowing credential documentation covers encoded separators and values' {
    foreach ($entry in @(@('rule', $rule), @('design appendix', $appendix))) {
      Assert-BorrowingDocContainsAll $entry[1] @(
        '空白分隔敏感键', 'JSON Unicode 转义键',
        '标点开头的非空显式值', '畸形 Unicode 转义按凭据 fail closed'
      ) ($entry[0] + ' credential separator boundary')
    }
  }
}
