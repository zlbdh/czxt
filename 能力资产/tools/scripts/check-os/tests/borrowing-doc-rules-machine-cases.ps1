$ErrorActionPreference = 'Stop'

function Get-BorrowingManifestContractRows {
  return @(
    @('输入集合', '仅包含规则选定的常规文件'),
    @('路径规范化', '相对路径统一为 /，再做 Unicode NFC'),
    @('路径拒绝', '拒绝空路径、绝对路径、.、..、TAB、CR、LF；规范化后必须唯一'),
    @('排序', '使用 StringComparer.Ordinal 按规范化相对路径排序'),
    @('单行格式', '<lowercase-sha256>\t<byte-length>\t<normalized-relative-path>\n'),
    @('编码', 'UTF-8 无 BOM'),
    @('空集合', 'canonical manifest 为零字节'),
    @('非空集合', '每个文件恰好一行，末尾恰好一个 LF'),
    @('最终 fingerprint', 'canonical manifest 字节的小写 SHA-256'),
    @('晋级一致性', 'source-before/source-after/staging-content/promotion 后 target 四次 canonical manifest 必须两两相同，且均与 stored manifest 字节逐字节相同')
  )
}

function Get-BorrowingSourceHistoryContractRows {
  return @(
    @('固定列', '时间 / 旧状态 / 新状态 / 原因 / 确认'),
    @(
      '合法转换全集',
      'none→ready（初始捕获成功） / ready→retired（所有引用事项 closed/cancelled）'
    ),
    @('retired', '终态，禁止回到 ready')
  )
}

function Invoke-BorrowingRuleMachineCases {
  param([string]$Text)

  Invoke-CzxtContract 'borrowing rule selects sha256-manifest-v1 in Local facts' {
    $local = Get-BorrowingMarkdownSection $Text 'Local 事实表' 3
    Assert-BorrowingTableCellValue $local @('事实字段', '合同') `
      'manifest 算法' 1 'sha256-manifest-v1' 'Local manifest algorithm'
  }

  Invoke-CzxtContract 'borrowing rule locks the ordered canonical manifest machine contract' {
    $section = Get-BorrowingMarkdownSection $Text 'sha256-manifest-v1 机器合同' 3
    Assert-BorrowingExactOrderedTable $section @('规范项', '精确合同') `
      (Get-BorrowingManifestContractRows) 'canonical manifest machine table'
  }

  Invoke-CzxtContract 'borrowing rule locks the manifest line as one exact code span' {
    $section = Get-BorrowingMarkdownSection $Text 'sha256-manifest-v1 机器合同' 3
    Assert-BorrowingSingleInlineCodeTableCell $section @('规范项', '精确合同') `
      '单行格式' 1 '<lowercase-sha256>\t<byte-length>\t<normalized-relative-path>\n' `
      'canonical manifest line format'
  }

  Invoke-CzxtContract 'borrowing rule locks source management history as an exact machine table' {
    $section = Get-BorrowingMarkdownSection $Text '来源管理历史机器合同' 3
    Assert-BorrowingExactOrderedTable $section @('规范项', '精确合同') `
      (Get-BorrowingSourceHistoryContractRows) 'source management history machine table'
  }

  Invoke-CzxtContract 'borrowing rule locks the exact Git submodule fact' {
    $git = Get-BorrowingMarkdownSection $Text 'Git 事实表' 3
    $header = @('事实字段', '合同')
    Assert-BorrowingTableCellValue $git $header 'submodule 状态' 1 `
      'detected / not-detected；只读检测；禁止初始化/下载/执行' 'Git submodule fact'
  }

  Invoke-CzxtContract 'borrowing rule locks the exact Git LFS fact' {
    $git = Get-BorrowingMarkdownSection $Text 'Git 事实表' 3
    $header = @('事实字段', '合同')
    Assert-BorrowingTableCellValue $git $header 'LFS 状态' 1 `
      'detected / not-detected；只读检测；禁止 smudge/下载/执行' 'Git LFS fact'
  }

  Invoke-CzxtContract 'borrowing rule derives capture_id and rejects full-hash collisions' {
    $section = Get-BorrowingMarkdownSection $Text '标识与路径'
    $rows = @(
      @('capture_id 末尾 12hex', '完整 fingerprint 的前 12 个小写十六进制字符'),
      @('短前缀冲突', '相同 12hex 对应不同完整 fingerprint 时必须硬失败，且不得覆盖已有 capture')
    )
    Assert-BorrowingExactOrderedTable $section @('capture_id 规则', '精确合同') `
      $rows 'capture_id fingerprint binding table'
  }
}
