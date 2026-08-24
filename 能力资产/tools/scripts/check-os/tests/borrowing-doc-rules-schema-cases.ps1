$ErrorActionPreference = 'Stop'

function Invoke-BorrowingRuleSchemaCases {
  param([string]$Text)

  Invoke-CzxtContract 'borrowing rule locks source_id in one inline-code span' {
    $section = Get-BorrowingMarkdownSection $Text '标识与路径'
    $header = @('标识', '固定格式')
    Assert-BorrowingSingleInlineCodeTableCell $section $header 'source_id' 1 `
      '[a-z0-9](?:[a-z0-9._-]{0,126}[a-z0-9_-])?' 'source_id format'
  }

  Invoke-CzxtContract 'borrowing rule locks capture_id in one inline-code span' {
    $section = Get-BorrowingMarkdownSection $Text '标识与路径'
    $header = @('标识', '固定格式')
    Assert-BorrowingSingleInlineCodeTableCell $section $header 'capture_id' 1 `
      '<source_type>-<YYYYMMDD>-<12hex>' 'capture_id format'
  }

  Invoke-CzxtContract 'borrowing rule locks borrow_id in one inline-code span' {
    $section = Get-BorrowingMarkdownSection $Text '标识与路径'
    $header = @('标识', '固定格式')
    Assert-BorrowingSingleInlineCodeTableCell $section $header 'borrow_id' 1 `
      'borrow-[0-9]{8}-(?:[a-z0-9])(?:[a-z0-9._-])*(?:-[0-9]+)?' 'borrow_id format'
  }

  Invoke-CzxtContract 'borrowing rule locks source type and path boundary' {
    $section = Get-BorrowingMarkdownSection $Text '标识与路径'
    Assert-BorrowingTableRow $section @('source_type', 'git / local / web') 'source_type values'
    Assert-BorrowingDocContainsAll $section @(
      '规范化', '仍位于', '借鉴区/', 'local:<display-name>',
      '绝对本机路径', 'capture.local.json', '凭据', '不得成为闭环验收的唯一证据'
    ) 'identifier path boundary'
  }

  Invoke-CzxtContract 'borrowing rule locks exact source fingerprint contracts' {
    $section = Get-BorrowingMarkdownSection $Text '来源版本卡'
    $rows = @(
      @('git', 'git-object', '完整 peeled commit object ID'),
      @('local', 'sha256-manifest-v1', 'canonical manifest UTF-8 字节的小写 SHA-256'),
      @('web', 'sha256-raw-bytes-v1', '原始响应字节的小写 SHA-256')
    )
    Assert-BorrowingExactTable $section @(
      '来源类型', 'fingerprint_algorithm', 'fingerprint 合同'
    ) $rows 'source fingerprint table'
  }

  Invoke-CzxtContract 'borrowing rule owns every source-card public field' {
    $section = Get-BorrowingMarkdownSection $Text '来源版本卡'
    $fields = @(
      'schema', 'source_id', 'capture_id', 'source_type', 'capture_status',
      'canonical_locator', 'fingerprint_algorithm', 'fingerprint', 'captured_at',
      'rights_status', 'access_policy', 'reuse_scope', 'execution_policy',
      'network_policy', 'storage_policy', 'distribution_policy',
      'upstream_write_policy', 'auto_refresh'
    )
    Assert-BorrowingExactFirstColumnTable $section @('公共字段', '合同') $fields 'source-card public field table'
    Assert-BorrowingDocContainsAll $section @(
      'schema: borrowing-source/v1', 'ready', 'retired', '身份与指纹字段不可改写',
      'fingerprint 不变返回 REUSED', 'fingerprint 改变才新增 capture',
      '活动事项', 'closed/cancelled', '管理历史'
    ) 'source-card lifecycle'
  }

  Invoke-CzxtContract 'borrowing rule owns Git Local and Web fact tables' {
    $git = Get-BorrowingMarkdownSection $Text 'Git 事实表' 3
    $gitFields = @('ref', 'ref 类型', 'object format', 'commit', 'tree', 'submodule 状态', 'LFS 状态')
    Assert-BorrowingExactFirstColumnTable $git @('事实字段', '合同') $gitFields 'Git fact table'
    $local = Get-BorrowingMarkdownSection $Text 'Local 事实表' 3
    $localFields = @('manifest 算法', '文件数', '字节数', '排除项', '失败项')
    Assert-BorrowingExactFirstColumnTable $local @('事实字段', '合同') $localFields 'Local fact table'
    $web = Get-BorrowingMarkdownSection $Text 'Web 事实表' 3
    $webFields = @(
      '原始 URL', '最终 URL', '重定向', '状态码', 'MIME',
      'charset', 'ETag', 'Last-Modified', '响应哈希'
    )
    Assert-BorrowingExactFirstColumnTable $web @('事实字段', '合同') $webFields 'Web fact table'
  }

  Invoke-CzxtContract 'borrowing rule locks Git ref types to branch or tag' {
    $git = Get-BorrowingMarkdownSection $Text 'Git 事实表' 3
    $header = @('事实字段', '合同')
    Assert-BorrowingTableCellValue $git $header 'ref 类型' 1 'branch / tag' 'Git ref type'
  }

  Invoke-CzxtContract 'borrowing rule locks full literal Git refs' {
    $git = Get-BorrowingMarkdownSection $Text 'Git 事实表' 3
    $header = @('事实字段', '合同')
    Assert-BorrowingTableCellValue $git $header 'ref' 1 `
      '完整字面 refs/heads/* 或 refs/tags/*；拒绝短名、符号 ref、revspec' 'Git literal ref contract'
  }

  Invoke-CzxtContract 'borrowing rule owns every item frontmatter field' {
    $section = Get-BorrowingMarkdownSection $Text '借鉴卡'
    $fields = @(
      'schema', 'borrow_id', 'title', 'lifecycle_status', 'decision',
      'impact_level', 'owner_pm', 'blocked', 'created_at', 'updated_at',
      'supersedes', 'closure_seal_sha256'
    )
    Assert-BorrowingExactFirstColumnTable $section @('frontmatter 字段', '合同') $fields 'item frontmatter field table'
    Assert-BorrowingDocContainsAll $section @('schema: borrowing-item/v1') 'item schema'
  }

  Invoke-CzxtContract 'borrowing rule locks item owner PM values' {
    $section = Get-BorrowingMarkdownSection $Text '借鉴卡'
    $owners = 'project-pm / sediment-pm / operating-system-pm / product-pm / technical-pm / test-pm / operations-pm / development-pm / release-pm'
    Assert-BorrowingTableCellValue $section @('frontmatter 字段', '合同') `
      'owner_pm' 1 $owners 'item owner_pm enum'
  }

  Invoke-CzxtContract 'borrowing rule maps seven logical areas to template titles' {
    $section = Get-BorrowingMarkdownSection $Text '借鉴卡'
    $rows = @(
      @('问题与成功标准', '问题与成功标准'),
      @('来源绑定', '来源绑定'),
      @('候选矩阵', '候选矩阵'),
      @('采纳与不采纳', '明确采纳 / 明确不采纳'),
      @('落地范围与治理', '目标与责任'),
      @('验收与实施证据', '验收标准 / 实施记录 / fresh 验证证据'),
      @('状态历史', '状态历史 / 阻塞信息')
    )
    Assert-BorrowingExactTable $section @('逻辑区', '模板标题') $rows 'item logical-area mapping'
  }

  Invoke-CzxtContract 'borrowing rule locks all seven item content contracts' {
    $section = Get-BorrowingMarkdownSection $Text '借鉴卡'
    Assert-BorrowingDocContainsAll $section @(
      'source_id / capture_id / fingerprint / 证据定位符',
      '已有能力 / 可借鉴点 / 冲突 / 结论 / 理由',
      '明确采纳', '明确不采纳', '目标文件', '责任 PM',
      'L1-L4', 'PROP/ADR', 'fresh 验证证据',
      '时间 / 旧状态 / 新状态 / decision / 原因 / 确认'
    ) 'item body contracts'
  }
}
