$ErrorActionPreference = 'Stop'

function Get-BorrowingTransactionRows {
  return @(
    @('共同前序', 'preflight→input（Local 在本阶段完成 source-before；Git/Web 完成各自写入前输入验证）→创建同卷 staging→capture→candidate validator→idempotency'),
    @(
      'conflict',
      'idempotency-conflict→FAIL；P4t 均 not-run；既有 capture 不变；保留本次 staging'
    ),
    @(
      'reuse healthy',
      'reuse→P4t-before=0→cleanup 自有 staging→REUSED；不得 move；P4t-after=not-run；既有全部字节与 mtime 不变'
    ),
    @(
      'repair eligibility',
      '唯一合法 ready 与稳定事实相同，且按 ignored cache repair 集合表判定该来源类型全部缺失；partial missing、现存损坏或指纹不符均 idempotency-conflict'
    ),
    @(
      'reuse repair',
      'repair-missing-cache→仅安装本次生成的缺失 ignored cache→post-link-check→P4t-after=0→cleanup→REUSED；P4t-before=not-run；既有 tracked 字节与 mtime 不变'
    ),
    @(
      'new',
      'new→P4t-before=0→atomic move→post-link-check→P4t-after=0→READY；仅此分支创建新正式 capture'
    ),
    @('P4t-before 失败', '不得 move/repair；既有不变；保留 staging；FAIL'),
    @(
      'post-link/P4t-after 失败',
      '对本次 move 或 repair 执行原子 rollback；成功后正式路径不存在或恢复原状、staging 存在；FAIL'
    ),
    @(
      'cleanup 失败',
      'stage=cleanup、reason_code=cleanup-failed；不删除未知内容；按输出时实际存在状态报告 capture_path/staging_path'
    ),
    @(
      'rollback 失败',
      'stage=rollback、reason_code=rollback-failed；禁止补偿删除或覆盖；capture_path/staging_path 分别按输出时实际存在性报告'
    ),
    @(
      '路径输出真值',
      'capture_path=正式路径仅当输出时存在否则 none；staging_path=本次 staging 仅当输出时存在否则 none；不得输出输入路径'
    )
  )
}

function Get-BorrowingExpectedCacheRows {
  return @(
    @('Git', '快照/repository.git/、capture.local.json'),
    @('Local', '快照/内容/（空目录也算成员）、快照/manifest.tsv、capture.local.json'),
    @('Web', '快照/response.bin、快照/response.metadata.json、capture.local.json'),
    @(
      '全部缺失判定',
      '仅当本来源类型的全部成员及父快照/均不存在；capture 目录与来源版本卡.md 必须存在且完整合法'
    ),
    @(
      'partial / damaged',
      '任一成员或父快照/已经存在但集合不完整、现存成员损坏或稳定事实不符，均 idempotency/idempotency-conflict；禁止覆盖或补齐'
    )
  )
}

function Get-BorrowingP4tRunnerRows {
  return @(
    @('固定脚本', '<Root>/能力资产/tools/scripts/check-os/p4t-borrowing-consistency.ps1；缺失→preflight/missing-trusted-component'),
    @('executable', '$PSHOME/powershell.exe 的绝对规范路径；executable 自身必须是无 reparse/ADS 的常规文件；仅该固定系统路径允许 Windows 组件服务 hardlink 与系统目录元数据流'),
    @(
      'argv',
      '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <fixed-p4t-path> -Root <canonical-root>；使用同一 Windows argv quoting'
    ),
    @(
      '进程 API',
      'ProcessStartInfo；UseShellExecute=false；CreateNoWindow=true；关闭 stdin；并发读取 stdout/stderr；禁止 shell 与环境注入'
    ),
    @('输出', '每流最多 1048576 原始字节；严格 UTF-8；禁止 NUL；输出只用于门禁且不得拼入 façade reason'),
    @('timeout', '每次独立 120000ms wall-clock'),
    @(
      '终止',
      '超时/输出越界调用绝对 %SystemRoot%/System32/taskkill.exe /PID <pid> /T /F；等待 taskkill、目标和双流退出；任一失败=p4t-process-failed'
    ),
    @('退出投影', '正常退出保留原始 integer；启动失败=start-failed；超时=timeout；不得把非零改写为 0'),
    @('注入边界', 'P4tPath、executable、runner、timeout、transport、script block 均不得成为 façade 参数')
  )
}

function Get-BorrowingSourceCardRendererRows {
  return @(
    @(
      '固定 skeleton',
      '借鉴区/模板/来源版本卡.md；写 staging 前须通过模板结构、strict UTF-8、LF 与静态行 validator；不得接受替代路径'
    ),
    @(
      'renderer',
      '按固定 line-array renderer 生成；frontmatter、标题、静态说明、表头、separator、空行顺序均唯一；禁止通用 YAML/Markdown serializer'
    ),
    @(
      'frontmatter',
      '固定 18 个字段及既有键序；动态值均先通过字段 grammar 后写 plain scalar；不得 quote、折行、escape 或增删字段'
    ),
    @('实例说明', '仅复用通过 validator 的 skeleton 适用项目行；正式路径行投影实际 source_id/capture_id'),
    @('权限表', '固定九行顺序；默认维度使用生产时钟/default-policy/current-capture；偏离维度使用规范化授权三元组'),
    @(
      '类型事实',
      '适用类型恰好一行 canonical cells；两个非适用类型每个 data cell=not-applicable；submodule/LFS 仅 detected/not-detected'
    ),
    @('管理历史', '恰好一行 <production-clock>/none/ready/initial-capture/capture-executor'),
    @('canonical bytes', 'UTF-8 无 BOM；LF；恰好一个末尾 LF；禁止行尾空格'),
    @('golden', 'Git、Local、Web 各以固定时钟和固定 fixture 断言整文件 SHA-256 与逐字节 golden 相等')
  )
}

function Invoke-BorrowingCommandTransactionCases {
  param([string]$Text)
  $usage = Get-BorrowingMarkdownSection $Text '使用边界'
  Invoke-CzxtContract 'command appendix locks capture transaction branches' {
    $section = Get-BorrowingMarkdownSection $usage 'capture 事务顺序' 3
    Assert-BorrowingExactOrderedTable $section @('事务分支', '精确合同') `
      (Get-BorrowingTransactionRows) 'capture transaction table'
  }
  Invoke-CzxtContract 'command appendix enumerates every repairable ignored cache member' {
    $usage = Get-BorrowingMarkdownSection $Text '使用边界'
    $section = Get-BorrowingMarkdownSection $usage 'ignored cache repair 集合' 3
    Assert-BorrowingExactOrderedTable $section @('ignored cache 项', '精确合同') `
      (Get-BorrowingExpectedCacheRows) 'ignored cache repair set table'
  }
  Invoke-CzxtContract 'command appendix locks trusted P4t child runner' {
    $section = Get-BorrowingMarkdownSection $usage 'P4t 子进程合同' 3
    Assert-BorrowingExactOrderedTable $section @('P4t runner 项', '精确合同') `
      (Get-BorrowingP4tRunnerRows) 'P4t child runner table'
  }
  Invoke-CzxtContract 'command appendix locks unique source-card renderer' {
    $section = Get-BorrowingMarkdownSection $usage '来源版本卡 canonical renderer' 3
    Assert-BorrowingExactOrderedTable $section @('renderer 项', '精确合同') `
      (Get-BorrowingSourceCardRendererRows) 'source-card renderer table'
  }
}
