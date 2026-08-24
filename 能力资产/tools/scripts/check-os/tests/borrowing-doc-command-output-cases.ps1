$ErrorActionPreference = 'Stop'

function Get-BorrowingResultAssociationRows {
  return @(
    @('exit 0', '当且仅当 result=READY 或 REUSED'),
    @('exit 10', '当且仅当 result=FAIL'),
    @(
      'READY',
      'stage=complete；reason_code=none；p4t_before=0；p4t_after=0；capture_path=根内新 capture 绝对路径；staging_path=none（已晋升）'
    ),
    @(
      'REUSED healthy',
      'stage=complete；reason_code=none；p4t_before=0；p4t_after=not-run；capture_path=根内既有 capture 绝对路径；staging_path=none（已清理）'
    ),
    @(
      'REUSED repaired',
      'stage=complete；reason_code=none；p4t_before=not-run；p4t_after=0；capture_path=根内既有 capture 绝对路径；staging_path=none（已清理）；仅恢复全缺失 ignored cache'
    ),
    @('FAIL', 'stage=失败点；reason_code 非 none；reason 非空')
  )
}

function Get-BorrowingP4tOutputRows {
  return @(
    @('not-run', 'P4t 未启动；对应字段=not-run'),
    @(
      'start-failed',
      'P4t 启动失败；对应字段=start-failed；stage=对应 p4t-before 或 p4t-after；reason_code=p4t-process-failed'
    ),
    @(
      'timeout',
      'P4t 已启动后超时并杀进程树；对应字段=timeout；stage=对应 p4t-before 或 p4t-after；reason_code=p4t-process-failed'
    ),
    @('integer=0', 'P4t 正常退出原码；对应门通过'),
    @(
      'integer=5 / 10 / 其他非 0',
      'P4t 正常退出原码；stage=对应 p4t-before 或 p4t-after；reason_code=p4t-not-zero'
    ),
    @(
      'p4t-after 失败',
      'integer 非 0 / start-failed / timeout 均原子 rollback'
    )
  )
}

function Get-BorrowingHandledOutputRows {
  return @(
    @('已知调用', '固定 12 行', '空'),
    @('内部异常', '固定 12 行', '空'),
    @('host 未知参数绑定错误', '合同外', '合同外')
  )
}

function Get-BorrowingReasonSanitizationRows {
  return @(
    @('组成', '仅可信常量 + 字段名/阶段'),
    @('禁止拼接', '输入值 / 路径 / stderr / 来源内容'),
    @('字符', '单行；禁止 C0 / C1 / U+2028 / U+2029'),
    @('编码长度', 'UTF-8 不超过 512 字节')
  )
}

function Get-BorrowingOutputPathRows {
  return @(
    @(
      'capture_path / staging_path',
      '仅允许输出根内 capture/staging 绝对路径或 none；按输出时实际存在性报告；不得把回滚历史伪装为当前存在'
    ),
    @('禁止输出', 'LocalPath / Web 输入路径 / Git URL')
  )
}

function Invoke-BorrowingCommandOutputCases {
  param([string]$Text)
  $usage = Get-BorrowingMarkdownSection $Text '使用边界'
  $section = Get-BorrowingMarkdownSection $usage 'façade 机读输出' 3

  Invoke-CzxtContract 'command appendix locks result and exit associations' {
    Assert-BorrowingExactOrderedTable $section @('结果关联项', '精确合同') `
      (Get-BorrowingResultAssociationRows) 'facade result association table'
  }

  Invoke-CzxtContract 'command appendix locks P4t output mappings' {
    Assert-BorrowingExactOrderedTable $section @('P4t 情形', '输出合同') `
      (Get-BorrowingP4tOutputRows) 'facade P4t mapping table'
  }

  Invoke-CzxtContract 'command appendix locks handled and host-error output boundaries' {
    Assert-BorrowingExactOrderedTable $section @('调用类别', 'stdout', 'stderr') `
      (Get-BorrowingHandledOutputRows) 'facade handled output table'
  }

  Invoke-CzxtContract 'command appendix locks reason sanitization' {
    Assert-BorrowingExactOrderedTable $section @('reason 规则', '精确合同') `
      (Get-BorrowingReasonSanitizationRows) 'facade reason sanitization table'
  }

  Invoke-CzxtContract 'command appendix locks safe absolute output paths' {
    Assert-BorrowingExactOrderedTable $section @('路径输出项', '精确合同') `
      (Get-BorrowingOutputPathRows) 'facade output path table'
  }
}
