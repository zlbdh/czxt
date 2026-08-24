$ErrorActionPreference = 'Stop'

function Get-BorrowingLocalStateArtifactRows {
  return @(
    @('固定文件名', 'capture.local.json'),
    @('schema', 'borrowing-capture-local-state/v1'),
    @(
      '顶层键序',
      'schema,source_type,local_source_path,web_raw_bytes_path,web_response_metadata_path'
    ),
    @('Git', 'local_source_path、web_raw_bytes_path、web_response_metadata_path 均为 null'),
    @('Local', '仅 local_source_path 为路径；两个 web 路径均为 null'),
    @('Web', 'local_source_path 为 null；两个 web 路径均为路径'),
    @(
      '路径值',
      '绝对规范化 NFC 路径使用既有 canonical JSON string 算法；缺省使用 JSON null'
    ),
    @('canonical bytes', 'compact JSON；UTF-8 无 BOM；恰好一个末尾 LF'),
    @('写入时点', 'fingerprint 与 capture_id 冻结后；同卷 staging 内原子写入'),
    @('敏感边界', '禁止进入 tracked 卡、12 行 stdout 或 reason'),
    @(
      'REUSED',
      '可写后清理自有 staging；既有 tracked 与现存 cache 字节/mtime 不变；仅允许恢复全缺失 ignored cache'
    ),
    @('preflight', '创建 staging 前确认借鉴区 ignore 合同')
  )
}

function Get-BorrowingSourceCardProjectionRows {
  return @(
    @('固定文件名', '来源版本卡.md'),
    @('canonical bytes', 'UTF-8 无 BOM；LF；恰好一个末尾 LF'),
    @('生产时钟', 'UTC yyyy-MM-ddTHH:mm:ss.fffZ'),
    @('AuthorizationTime 输入', '必须含时区；解析后统一投影 UTC yyyy-MM-ddTHH:mm:ss.fffZ'),
    @(
      '时钟复用',
      'captured_at、capture_id 日期、初始历史时间、默认权限授权时间使用同一值'
    ),
    @('时钟 seam', '仅 card helper 内部可注入；façade 禁止时钟参数'),
    @('初始历史', 'none→ready；reason=initial-capture；confirmation=capture-executor'),
    @('默认授权', 'source=default-policy；scope=current-capture；time=生产时钟'),
    @('类型事实表', '仅适用表写事实；两个非适用表的每个 data cell 均为 not-applicable'),
    @(
      '幂等包含',
      'canonical_locator、适用类型事实、九维生效值、所有偏离默认的规范化授权 time/source/scope'
    ),
    @(
      '幂等排除',
      'capture_id、captured_at、初始历史、默认授权时间、非适用表、本机路径状态'
    ),
    @('既有卡', '复用前仍须按完整 schema 全量合法')
  )
}

function Get-BorrowingWebSnapshotArtifactRows {
  return @(
    @('raw 路径', '快照/response.bin'),
    @('metadata 路径', '快照/response.metadata.json'),
    @('raw bytes', '原始响应字节逐字节保存'),
    @(
      '顶层键序',
      'schema,original_url,final_url,redirect_chain,status_code,mime,charset,etag,last_modified'
    ),
    @('redirect item 键序', 'status_code,location_url'),
    @('值', '使用输入合同规定的规范化值'),
    @('canonical bytes', 'compact JSON；UTF-8 无 BOM；恰好一个末尾 LF'),
    @('metadata 计量', '输入字节与 canonical 文件字节各自计量；canonical 计量包含末尾 LF'),
    @('MIME 输入', '必须已为小写并匹配 MIME 正则；不得做大小写归一')
  )
}

function Get-BorrowingCardInputSafetyRows {
  return @(
    @(
      'AuthorizationSource / AuthorizationScope',
      'NFC；非空；各自 UTF-8 512 字节以内；拒绝 pipe/backtick/TAB/C0/C1/U+2028/U+2029'
    ),
    @(
      'LocalDisplayName',
      '与 source_id 格式相同且 UTF-8 128 字节以内；canonical_locator=local:<LocalDisplayName>'
    ),
    @('投影', '只写规范化安全值；禁止把原始输入拼入 Markdown 或 frontmatter'),
    @('本机状态', '非权威；不得参与幂等稳定比较或成为验收唯一证据')
  )
}

function Get-BorrowingCaptureRedDecisionRows {
  return @(
    @('ADS', '对应检查阶段', 'source-unsafe', '不得晋升'),
    @('Local manifest/read-after 变化', 'capture', 'source-unsafe', '保留 staging'),
    @('Local 普通 IO', 'capture', 'capture-failed', '已有 staging 时保留'),
    @(
      'move 后链接变化', 'promotion', 'source-unsafe',
      '原子回滚；capture_path=none；staging_path=恢复路径'
    ),
    @(
      'idempotency-conflict', 'idempotency', 'idempotency-conflict',
      '发生在 P4t-before 前；p4t_before=not-run；p4t_after=not-run'
    )
  )
}

function Invoke-BorrowingCommandArtifactCases {
  param([string]$Text)

  Invoke-CzxtContract 'command appendix locks capture local state artifact' {
    $usage = Get-BorrowingMarkdownSection $Text '使用边界'
    $section = Get-BorrowingMarkdownSection $usage 'capture.local.json 合同' 3
    Assert-BorrowingExactOrderedTable $section @('本机状态项', '精确合同') `
      (Get-BorrowingLocalStateArtifactRows) 'capture local state artifact table'
  }

  Invoke-CzxtContract 'command appendix locks source card projection and clock' {
    $usage = Get-BorrowingMarkdownSection $Text '使用边界'
    $section = Get-BorrowingMarkdownSection $usage '来源版本卡投影合同' 3
    Assert-BorrowingExactOrderedTable $section @('来源卡投影项', '精确合同') `
      (Get-BorrowingSourceCardProjectionRows) 'source card projection table'
    Assert-BorrowingExactOrderedTable $section @('卡片输入项', '精确合同') `
      (Get-BorrowingCardInputSafetyRows) 'source card input safety table'
  }

  Invoke-CzxtContract 'command appendix locks canonical Web snapshot artifacts' {
    $web = Get-BorrowingMarkdownSection $Text 'Web 接入'
    $section = Get-BorrowingMarkdownSection $web 'Web canonical metadata 落盘合同' 3
    Assert-BorrowingExactOrderedTable $section @('Web 快照项', '精确合同') `
      (Get-BorrowingWebSnapshotArtifactRows) 'Web snapshot artifact table'
  }

  Invoke-CzxtContract 'command appendix locks capture RED classifications' {
    $usage = Get-BorrowingMarkdownSection $Text '使用边界'
    $section = Get-BorrowingMarkdownSection $usage 'capture RED 分类' 3
    Assert-BorrowingExactOrderedTable $section @(
      '失败场景', 'stage', 'reason_code', '文件系统结果'
    ) (Get-BorrowingCaptureRedDecisionRows) 'capture RED decision table'
  }
}
