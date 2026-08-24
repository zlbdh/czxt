$ErrorActionPreference = 'Stop'

function Get-BorrowingWindowsPathRows {
  return @(
    @(
      'v1 平台范围',
      'Windows 本机 fixed drive 的 drive-letter 绝对路径；拒绝相对、UNC、device namespace、subst/network/removable 路径'
    ),
    @(
      '词法预检',
      '先 NFC 与 GetFullPath；拒绝 NUL、C0/C1/U+2028/U+2029、drive colon 之外的 colon、尾空格/尾点段、Windows 保留设备段'
    ),
    @(
      '最终路径',
      'CreateFileW 打开 handle；GetFinalPathNameByHandleW 使用 FILE_NAME_NORMALIZED + VOLUME_NAME_DOS；仅移除固定 \\?\ 前缀；drive letter 大写、反斜杠、NFC'
    ),
    @(
      '逐层安全',
      '从 volume root 到目标逐层以 handle 校验；任一 reparse tag、symlink、junction、ADS、非常规类型或 API 不可用均硬失败'
    ),
    @('常规文件', 'BY_HANDLE_FILE_INFORMATION.NumberOfLinks 必须等于 1；文件身份=VolumeSerialNumber + FileIndexHigh + FileIndexLow'),
    @(
      '路径关系',
      'canonical DOS path 使用 OrdinalIgnoreCase 与目录分隔符边界比较 equality/ancestor/descendant；不得用字符串裸前缀'
    ),
    @('本机状态投影', 'capture.local.json 只写上述 canonical DOS path；使用 canonical JSON string；不得写输入拼法')
  )
}

function Get-BorrowingLocalCaptureRows {
  return @(
    @(
      'LocalPath',
      '既有安全常规目录；与 Root 及 Root/借鉴区 均不得相等或互为 ancestor/descendant；写入前完成验证'
    ),
    @('内容路径', '快照/内容/；逐相对路径复制全部常规文件；无隐式排除'),
    @('manifest 路径', '快照/manifest.tsv；内容为 sha256-manifest-v1 canonical bytes；允许空文件'),
    @(
      '全链一致性',
      'source-before、source-after、staging-content、promoted-content 四次 canonical manifest 必须两两相同，且均与 stored manifest.tsv 字节逐字节相等'
    ),
    @(
      '时点顺序',
      'input/source-before→创建同卷 staging→capture/复制→source-after→staging-content→写 stored manifest→candidate validator→idempotency→P4t-before→atomic move→promotion/promoted-content 与身份链复核→P4t-after；顺序不可交换'
    ),
    @(
      '重复安全检查',
      'source-before 在创建 staging 前检查；复制后重新生成 source-after 与 staging-content，并复查 link、ADS、type、API 与资源上限；任一不符→capture/source-unsafe'
    ),
    @(
      '身份链',
      'source-before 与 source-after 的 source root identity、相对路径集合及逐文件 identity 必须相同；staging-content 的 root 及逐文件 identity 必须与 source 对应 identity 不同且所有常规文件 NumberOfLinks=1；同卷 atomic move 后 promoted-content 的 root 及逐文件 identity 必须与 staging-content 对应 identity 相同且所有常规文件 NumberOfLinks=1；任一不符按所在阶段 source-unsafe'
    ),
    @(
      'promotion 复核',
      'promoted-content manifest 与前三次 manifest 或 stored manifest.tsv 不相等，或 promoted-content 的 root/逐文件 identity 与 staging-content 基线不同，或出现 link、ADS、type、API 失败→promotion/source-unsafe 并立即 rollback'
    ),
    @('fingerprint', '全链一致后取 source-before canonical manifest bytes 的 lowercase SHA-256'),
    @('空目录', '快照/内容/ 必须存在；五份 manifest bytes 均为零字节；文件数=0、字节数=0')
  )
}

function Get-BorrowingWebInputPathRows {
  return @(
    @(
      '两项输入',
      'WebRawBytesPath 与 WebResponseMetadataPath 均为既有安全常规文件；写入前完成完整 Windows 路径与文件身份验证'
    ),
    @(
      'Root 边界',
      '两输入与 Root 及 Root/借鉴区 均不得相等或互为 ancestor/descendant；不得从借鉴区回读形成自引用'
    ),
    @(
      '互异',
      'canonical path 必须 OrdinalIgnoreCase 不同且文件身份三元组不同；同路径、hardlink alias 或同一实体均拒绝'
    ),
    @('链接边界', '任一 reparse/link/ADS/NumberOfLinks!=1 或身份 API 不可用→input/source-boundary'),
    @('联网边界', '只读取两个已授权输入文件；不得发起网络请求、重定向或外部进程')
  )
}

function Get-BorrowingWebIntegerRows {
  return @(
    @('status_code token', 'JSON number token 必须匹配 0 或 [1-9][0-9]*；随后范围 100..599'),
    @(
      'redirect status token',
      'JSON number token 必须匹配 0 或 [1-9][0-9]*；随后范围 300..399 且不等于 304'
    ),
    @('固定拒绝', '负数、前导零、小数、指数、200.0、2e2、字符串数字')
  )
}

function Invoke-BorrowingCommandInputPathCases {
  param([string]$Text)

  Invoke-CzxtContract 'command appendix locks Windows path and file identity' {
    $usage = Get-BorrowingMarkdownSection $Text '使用边界'
    $section = Get-BorrowingMarkdownSection $usage 'Windows 路径与文件身份合同' 3
    Assert-BorrowingExactOrderedTable $section @('路径安全项', '精确合同') `
      (Get-BorrowingWindowsPathRows) 'Windows path identity table'
  }
  Invoke-CzxtContract 'command appendix locks Local snapshot and four-way manifest' {
    $local = Get-BorrowingMarkdownSection $Text '本地接入'
    $section = Get-BorrowingMarkdownSection $local 'Local canonical 落盘合同' 3
    Assert-BorrowingExactOrderedTable $section @('Local 项', '精确合同') `
      (Get-BorrowingLocalCaptureRows) 'Local canonical capture table'
    Assert-BorrowingDocExcludesAll $section @(
      'move 后 link/identity 与 source-before 不同'
    ) 'obsolete Local source-to-promotion identity comparison'
  }
  Invoke-CzxtContract 'command appendix locks Web input file identity' {
    $web = Get-BorrowingMarkdownSection $Text 'Web 接入'
    $section = Get-BorrowingMarkdownSection $web 'Web 输入路径合同' 3
    Assert-BorrowingExactOrderedTable $section @('Web 输入项', '精确合同') `
      (Get-BorrowingWebInputPathRows) 'Web input identity table'
  }
  Invoke-CzxtContract 'command appendix locks JSON integer token grammar' {
    $web = Get-BorrowingMarkdownSection $Text 'Web 接入'
    $section = Get-BorrowingMarkdownSection $web 'WebResponseMetadataPath 输入合同' 3
    Assert-BorrowingExactOrderedTable $section @('JSON 整数项', '精确合同') `
      (Get-BorrowingWebIntegerRows) 'Web integer grammar table'
  }
}
