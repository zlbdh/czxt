$ErrorActionPreference = 'Stop'

function Get-BorrowingGitRunnerRows {
  return @(
    @('Git 能力基线', 'git version 可解析且 >=2.43.0；生产 executable 为预检解析的绝对路径'),
    @(
      '可信运行目录',
      'runner-root、runner-root/cwd、HOME 与 trusted-empty-dir 均在 staging；WorkingDirectory=runner-root/cwd；GIT_CEILING_DIRECTORIES=runner-root'
    ),
    @('继承环境', '先按不区分大小写移除全部 GIT_*、SSH_ASKPASS、SSH_ASKPASS_REQUIRE'),
    @(
      '固定环境',
      'GIT_TERMINAL_PROMPT=0；GIT_CONFIG_NOSYSTEM=1；GIT_CONFIG_GLOBAL=NUL；GIT_CONFIG_SYSTEM=NUL；GIT_LFS_SKIP_SMUDGE=1；GIT_PROTOCOL_FROM_USER=0；GIT_ALLOW_PROTOCOL=https；GIT_NO_REPLACE_OBJECTS=1；GIT_OPTIONAL_LOCKS=0；GIT_CEILING_DIRECTORIES=<runner-root>；LC_ALL=C；LANG=C'
    ),
    @('隔离 HOME', 'HOME、USERPROFILE、XDG_CONFIG_HOME 指向 staging 内独立可信空目录'),
    @(
      '固定 argv 前缀',
      '--no-pager；credential.helper=；core.askPass=；core.hooksPath=<trusted-empty-dir>；filter.lfs.clean=；filter.lfs.smudge=；filter.lfs.process=；filter.lfs.required=false；submodule.recurse=false；fetch.recurseSubmodules=false；protocol.file.allow=never；protocol.ext.allow=never；maintenance.auto=false；gc.auto=0；http.sslVerify=true；http.followRedirects=false；http.extraHeader='
    ),
    @(
      '进程 API',
      'ProcessStartInfo；UseShellExecute=false；CreateNoWindow=true；RedirectStandardInput/Output/Error=true；启动后立即关闭 stdin；禁止 shell'
    ),
    @(
      'Windows argv quoting',
      '空参数→""；无空白/quote 参数原样；quote 前 N 个 backslash→2N+1 后接 quote；闭引号前 N 个 backslash→2N；其余 backslash 原样'
    ),
    @(
      '输出读取',
      'stdout/stderr 并发按原始字节有界读取；每流 67108864 字节；严格 UTF-8；仅 ls-tree stdout 允许 NUL 作为记录分隔；越界或非法字节硬失败'
    ),
    @(
      'timeout',
      '每个 Git 子进程独立 300000ms wall-clock；超时调用绝对 %SystemRoot%/System32/taskkill.exe /PID <pid> /T /F；等待 taskkill、目标和双流全部退出'
    ),
    @(
      '失败语义',
      '启动/读取/终止/等待任一异常或 kill 后仍存活均不得晋升；timeout/输出越界→capture/resource-limit；其余→capture/capture-failed'
    ),
    @('测试 seam', 'runner、timeout 与传输适配器仅内部 helper 可注入；不得穿透 façade'),
    @(
      '离线 file adapter',
      '仅测试 helper 记录并断言逻辑 HTTPS argv，再把唯一精确匹配的 fixture locator 映射为 file URI，并仅在该测试子进程放开 file；未映射 locator 硬失败；该测试不替代生产协议/环境/argv 隔离测试'
    )
  )
}

function Get-BorrowingGitCacheRows {
  return @(
    @('顶层', '仅 HEAD、config、可选 shallow、objects/、refs/'),
    @(
      'config canonical',
      '字节仅由 Git config canonical line-array 表生成；拒绝重复键、include、includeIf、remote.*、额外 section/key 与任何字节漂移'
    ),
    @('HEAD', 'detached；规范字节=<lowercase-commit-oid><LF>'),
    @(
      'refs',
      '唯一 ref 文件 refs/czxt/capture；规范字节=<lowercase-advertised-oid><LF>；允许 init 生成的空目录'
    ),
    @('shallow', '可缺省；存在时规范字节仅为 <lowercase-commit-oid><LF>'),
    @(
      'objects',
      '仅选定 ref 可达对象；loose object 名符合 object format；pack 与 idx 同 basename 成对、rev 仅可作为同 basename 可选第三件；拒绝孤立 pack/idx/rev；objects/info 仅空目录'
    ),
    @(
      '可达性',
      'git -C <repository.git> fsck --full --strict --no-reflogs --unreachable --no-progress 必须 exit 0 且 stdout/stderr 均为空'
    ),
    @(
      '固定拒绝',
      'hooks、FETCH_HEAD、packed-refs、alternates、logs、modules、worktrees、index、replace refs、额外顶层项'
    ),
    @('文件安全', '所有常规文件 NumberOfLinks=1；reparse/symlink/junction/ADS/API 不可用均硬失败'),
    @('Git symlink', 'tree mode 120000→capture/source-unsafe'),
    @('submodule', 'tree mode 160000→detected；无则 not-detected；禁止初始化/下载/执行'),
    @(
      'LFS',
      'pointer 首行 version https://git-lfs.github.com/spec/v1 或 .gitattributes 含 filter=lfs→detected；无则 not-detected；禁止 smudge/下载/执行'
    )
  )
}

function Get-BorrowingGitConfigLineArrayRows {
  return @(
    @(
      'sha1',
      '["[core]","<TAB>repositoryformatversion = 0","<TAB>filemode = false","<TAB>bare = true","<TAB>symlinks = false","<TAB>ignorecase = true"]'
    ),
    @(
      'sha256',
      '["[core]","<TAB>repositoryformatversion = 1","<TAB>filemode = false","<TAB>bare = true","<TAB>symlinks = false","<TAB>ignorecase = true","[extensions]","<TAB>objectformat = sha256"]'
    ),
    @(
      'canonical bytes',
      '<TAB> 表示单个 0x09 byte；每项严格 UTF-8 且不含 CR/LF；按序以 LF 连接并追加恰好一个末尾 LF；无 BOM'
    )
  )
}

function Get-BorrowingGitFailureRows {
  return @(
    @('HEAD/config/ref/shallow/拓扑/fsck 不规范', 'candidate / candidate-invalid'),
    @('cache 内 reparse、ADS、hardlink、API 不可用', 'candidate / source-unsafe'),
    @('tree mode 120000 或非法 Git 路径', 'capture / source-unsafe'),
    @('advertised OID 与 fetch 后 ref 不同', 'capture / capture-failed'),
    @('timeout 或单流越界', 'capture / resource-limit'),
    @('启动、读取、终止、等待或严格 UTF-8 失败', 'capture / capture-failed')
  )
}

function Invoke-BorrowingCommandGitRuntimeCases {
  param([string]$Text)
  $git = Get-BorrowingMarkdownSection $Text 'Git 接入'
  $section = Get-BorrowingMarkdownSection $git 'Git 精确执行合同' 3
  Invoke-CzxtContract 'command appendix locks hardened Git runner' {
    Assert-BorrowingExactOrderedTable $section @('Git runner 项', '精确合同') `
      (Get-BorrowingGitRunnerRows) 'Git runner contract table'
  }
  Invoke-CzxtContract 'command appendix locks canonical Git cache' {
    Assert-BorrowingExactOrderedTable $section @('Git cache 项', '精确合同') `
      (Get-BorrowingGitCacheRows) 'Git cache contract table'
  }
  Invoke-CzxtContract 'command appendix locks Git config as one canonical byte sequence per object format' {
    Assert-BorrowingExactOrderedTable $section @('Git config line-array 项', '精确合同') `
      (Get-BorrowingGitConfigLineArrayRows) 'Git config line-array table'
  }
  Invoke-CzxtContract 'command appendix locks Git failure stage and reason projection' {
    Assert-BorrowingExactOrderedTable $section @('Git 失败场景', 'stage / reason_code') `
      (Get-BorrowingGitFailureRows) 'Git failure projection table'
  }
}
