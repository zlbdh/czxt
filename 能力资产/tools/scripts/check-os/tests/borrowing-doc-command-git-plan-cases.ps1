$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'borrowing-doc-command-git-runtime-cases.ps1')

function Get-BorrowingGitCommandPlanRows {
  return @(
    @('缓存路径', '快照/repository.git；bare shallow cache；无 working tree'),
    @(
      '远端探测',
      'git ls-remote --refs --exit-code <canonical-locator> <full-ref>'
    ),
    @(
      '探测结果',
      '恰好一行 <oid><TAB><full-ref>；ref 逐字相等；oid 40/64hex 分别判定 sha1/sha256'
    ),
    @(
      '初始化',
      'git init --quiet --bare --object-format=<object-format> --template=<trusted-empty-dir> <repository.git>'
    ),
    @(
      '精确 fetch',
      'git -C <repository.git> fetch --quiet --depth=1 --no-tags --no-recurse-submodules --no-write-fetch-head --no-auto-maintenance --no-write-commit-graph --force <canonical-locator> +<full-ref>:refs/czxt/capture'
    ),
    @(
      'TOCTOU',
      'git -C <repository.git> show-ref --verify --hash refs/czxt/capture；恰好输出 <lowercase-oid><LF> 且等于 ls-remote advertised oid'
    ),
    @(
      'peel',
      'git -C <repository.git> rev-parse --verify refs/czxt/capture^{commit}；再以 git -C <repository.git> rev-parse --verify <commit>^{tree}；fingerprint=完整 lowercase commit oid'
    ),
    @('HEAD', 'git -C <repository.git> update-ref --no-deref HEAD <commit>；形成 detached HEAD'),
    @(
      'tree',
      'git -C <repository.git> ls-tree -r -z -l --full-tree <tree>；路径严格 UTF-8；不得 checkout'
    ),
    @('失败', '能力缺失→preflight/missing-trusted-component；Git 非零→capture/capture-failed')
  )
}

function Get-BorrowingGitInputRows {
  return @(
    @(
      'GitLocator 字符',
      'NFC；UTF-8 不超过 1024 字节；拒绝反斜杠、percent、空白、C0/C1/U+2028/U+2029'
    ),
    @(
      'GitLocator URI',
      '[Uri] 绝对 HTTPS；userinfo/query/fragment 必须为空；仅默认 443；禁止相对、UNC、file、IP literal'
    ),
    @(
      'GitLocator host',
      'IdnMapping(UseStd3AsciiRules=true) 转 ASCII 后小写；拒绝尾点；每 label 与总长必须合法'
    ),
    @(
      'GitLocator path',
      'ASCII 绝对路径；每段仅 [A-Za-z0-9._~-] 且首字符不得为点；末段必须为非空 basename.git；拒绝 dot-segment、重复 slash、尾 slash'
    ),
    @('canonical_locator', 'https://<lowercase-ascii-host><case-preserved-path>；显式 :443 移除；不得保存原始 locator'),
    @(
      'GitRef 词法',
      'NFC ASCII；UTF-8 不超过 1024 字节；完整 refs/heads/ 或 refs/tags/；拒绝 pipe、backtick、TAB、C0/C1/U+2028/U+2029'
    ),
    @('GitRef Git 校验', 'git check-ref-format <full-ref> 必须 exit 0 且 stdout/stderr 为空'),
    @('GitRef 投影', 'ref 类型由前缀唯一派生为 branch/tag；表格写规范化原值，不做 revspec 或符号解析')
  )
}

function Invoke-BorrowingCommandGitPlanCases {
  param([string]$Text)

  Invoke-CzxtContract 'command appendix locks exact Git command plan' {
    $git = Get-BorrowingMarkdownSection $Text 'Git 接入'
    $section = Get-BorrowingMarkdownSection $git 'Git 精确执行合同' 3
    Assert-BorrowingExactOrderedTable $section @('Git 步骤', '精确合同') `
      (Get-BorrowingGitCommandPlanRows) 'Git command plan table'
  }
  Invoke-CzxtContract 'command appendix locks canonical Git locator and ref inputs' {
    $git = Get-BorrowingMarkdownSection $Text 'Git 接入'
    $section = Get-BorrowingMarkdownSection $git 'Git 精确执行合同' 3
    Assert-BorrowingExactOrderedTable $section @('Git 输入项', '精确合同') `
      (Get-BorrowingGitInputRows) 'Git input contract table'
  }
  Invoke-BorrowingCommandGitRuntimeCases -Text $Text
}
