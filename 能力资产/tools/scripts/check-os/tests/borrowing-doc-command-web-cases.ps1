$ErrorActionPreference = 'Stop'

function Get-BorrowingWebNormalizationRows {
  return @(
    @(
      'URL 解析',
      '[Uri] 绝对 HTTPS；禁止 userinfo、query、fragment、backslash、CR、LF'
    ),
    @('host', 'IDN 转 ASCII 后小写'),
    @('port', '仅允许默认 443；规范化输出移除端口'),
    @(
      'path',
      'RFC3986 dot-segment 解析；UriEscaped；percent 十六进制大写；空路径规范为 /'
    ),
    @('canonical_locator', 'normalized final_url'),
    @('nullable JSON null', '卡片投影为裸 null'),
    @('nullable JSON string', '使用 canonical JSON string 算法'),
    @('字符串 "null"', '与 JSON null 可区分'),
    @(
      'mime',
      '^[a-z0-9][a-z0-9!#$%&''*+.^_~-]*/[a-z0-9][a-z0-9!#$%&''*+.^_~-]*$'
    ),
    @('mime 输入', '必须已为小写并匹配上述正则；不得做大小写归一'),
    @(
      'mime 全长',
      '禁止 C0/C1/U+2028/U+2029；Match.Index=0 且 Match.Length=输入长度；不得仅用 IsMatch'
    ),
    @('mime 附加禁止', 'pipe / backtick / 参数'),
    @(
      'redirect_chain',
      '紧凑 JSON；固定键序 status_code,location_url；字符串使用相同转义；空链 []'
    ),
    @('卡片单元格', '禁止原始 pipe、TAB、CR、LF')
  )
}

function Get-BorrowingCanonicalJsonStringRows {
  return @(
    @('预处理', 'NFC；双引号包裹'),
    @(
      '短转义',
      'quote→\"；backslash→\\；BS/FF/LF/CR/TAB→\b/\f/\n/\r/\t'
    ),
    @(
      'unicode 转义',
      '其余 C0、全部 C1、pipe、U+2028、U+2029→大写 4 位 \uXXXX'
    ),
    @('原样 UTF-8', '其他 Unicode scalar；非 BMP 原样'),
    @('slash', '不转义')
  )
}

function Invoke-BorrowingCommandWebCases {
  param([string]$Text)
  $web = Get-BorrowingMarkdownSection $Text 'Web 接入'
  $section = Get-BorrowingMarkdownSection $web 'WebResponseMetadataPath 输入合同' 3

  Invoke-CzxtContract 'command appendix locks Web normalization and card projection algorithms' {
    Assert-BorrowingExactOrderedTable $section @('Web 规范化项', '精确合同') `
      (Get-BorrowingWebNormalizationRows) 'Web normalization projection table'
  }

  Invoke-CzxtContract 'command appendix locks canonical JSON string escaping' {
    Assert-BorrowingExactOrderedTable $section @(
      'canonical JSON string 项', '精确合同'
    ) (Get-BorrowingCanonicalJsonStringRows) 'canonical JSON string table'
  }

  Invoke-CzxtContract 'command appendix locks MIME as one exact regex code span' {
    $regex = '^[a-z0-9][a-z0-9!#$%&''*+.^_~-]*/[a-z0-9][a-z0-9!#$%&''*+.^_~-]*$'
    Assert-BorrowingSingleInlineCodeTableCell $section @('Web 规范化项', '精确合同') `
      'mime' 1 $regex 'Web MIME regex'
  }
}
