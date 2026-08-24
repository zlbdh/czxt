$ErrorActionPreference = 'Stop'

function Get-BorrowingResourceMeasurementRows {
  return @(
    @(
      'leaf', 'Local',
      'manifest 条目数；创建 staging 前及复制后对 source-after/staging 重复检查',
      'resource-limit'
    ),
    @(
      'leaf', 'Git',
      '选定 tree 的非 tree 条目数；仅 fetch 后在 staging 内检查',
      'resource-limit'
    ),
    @(
      '总字节', 'Local',
      '按每个规范化路径的文件长度求和；创建 staging 前及复制后对 source-after/staging 重复检查',
      'resource-limit'
    ),
    @(
      '总字节', 'Git',
      '按每个 leaf 可达 blob 的未压缩 size 求和；重复路径重复计；仅 fetch 后在 staging 内检查',
      'resource-limit'
    ),
    @('总字节', 'Web', 'raw 响应字节长度；创建 staging 前检查', 'resource-limit'),
    @(
      '单项字节', 'Local',
      '每个文件长度；创建 staging 前及复制后对 source-after/staging 重复检查',
      'resource-limit'
    ),
    @(
      '单项字节', 'Git',
      '每个 leaf 可达 blob 的未压缩 size；仅 fetch 后在 staging 内检查',
      'resource-limit'
    ),
    @('单项字节', 'Web', 'raw 响应字节长度；创建 staging 前检查', 'resource-limit'),
    @(
      'Git cache 字节', 'Git',
      'fetch 后 staging repository.git 下全部常规文件长度之和；仅在 staging 内检查',
      'resource-limit'
    ),
    @(
      '深度', 'Local',
      '规范化相对路径按 / 分段数；根级文件=1；空集=0；创建 staging 前及复制后重复检查',
      'resource-limit'
    ),
    @(
      '深度', 'Git',
      '规范化相对路径按 / 分段数；根级文件=1；空集=0；仅 fetch 后在 staging 内检查',
      'resource-limit'
    ),
    @(
      '路径 UTF-8 字节', 'Local',
      '规范化相对路径；创建 staging 前及复制后对 source-after/staging 重复检查',
      'resource-limit'
    ),
    @(
      '路径 UTF-8 字节', 'Git',
      '规范化相对路径；仅 fetch 后在 staging 内检查',
      'resource-limit'
    ),
    @(
      'metadata 字节', 'Web',
      '输入字节与 canonical 文件字节（含末尾 LF）各自计量；创建 staging 前检查',
      'resource-limit'
    ),
    @('redirect', 'Web', 'redirect_chain 数组元素数；创建 staging 前检查', 'resource-limit'),
    @('Git timeout', 'Git', '每个 Git 子进程 wall-clock', 'resource-limit'),
    @(
      'P4t timeout', 'Local / Git / Web',
      '每次 P4t wall-clock；对应前后门', 'p4t-process-failed'
    )
  )
}

function Get-BorrowingResourceStageRows {
  return @(
    @(
      'Local', '所有内容/路径上限',
      '创建 staging 前检查；复制后对 source-after 与 staging 重复检查'
    ),
    @('Web', 'raw 与输入/canonical metadata', '创建 staging 前检查'),
    @('Git', '所有内容/路径上限', '仅 fetch 后在 staging 内检查')
  )
}

function Get-BorrowingResourceCommonRows {
  return @(
    @('Int64', '任一计数或求和溢出即硬失败'),
    @(
      '越界 reason',
      '除 P4t timeout 使用 p4t-process-failed 外，其余资源越界均使用 resource-limit'
    )
  )
}

function Get-BorrowingTimeoutContractRows {
  return @(
    @(
      'Git timeout', '每个 Git 子进程 wall-clock',
      '超时杀进程树', 'stage=capture；reason_code=resource-limit'
    ),
    @(
      'P4t timeout', '每次 P4t wall-clock',
      '超时杀进程树；按前后门规则回退',
      'stage=对应 p4t-before 或 p4t-after；reason_code=p4t-process-failed'
    )
  )
}

function Invoke-BorrowingCommandResourceCases {
  param([string]$Text)
  $usage = Get-BorrowingMarkdownSection $Text '使用边界'
  $section = Get-BorrowingMarkdownSection $usage 'v1 固定资源上限' 3

  Invoke-CzxtContract 'command appendix locks exact resource measurement objects and timing' {
    Assert-BorrowingExactOrderedTable $section @(
      '资源项', '适用来源', '计量对象与时点', 'reason'
    ) (Get-BorrowingResourceMeasurementRows) 'resource measurement table'
  }

  Invoke-CzxtContract 'command appendix locks Git and P4t timeout mechanics' {
    Assert-BorrowingExactOrderedTable $section @(
      '超时项', '计时边界', '超时动作', 'stage / reason'
    ) (Get-BorrowingTimeoutContractRows) 'resource timeout table'
  }

  Invoke-CzxtContract 'command appendix locks fixed resource stages' {
    Assert-BorrowingExactOrderedTable $section @(
      '适用来源', '固定范围', '固定检查阶段'
    ) (Get-BorrowingResourceStageRows) 'resource stage table'
  }

  Invoke-CzxtContract 'command appendix locks resource overflow and reason rules' {
    Assert-BorrowingExactOrderedTable $section @('资源公共项', '精确合同') `
      (Get-BorrowingResourceCommonRows) 'resource common rule table'
  }
}
