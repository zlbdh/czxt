$ErrorActionPreference = 'Stop'

# Literal language alternatives for the cross-document contract only.
# Other borrowing assertion helpers and machine-readable identifiers are unchanged.
$script:BorrowingCrossLanguageAliases = @'
{
  "fingerprint: <完整值>": ["fingerprint: <complete-value>"],
  "capture.local.json/v1` 只保存固定 5 键": ["capture.local.json/v1` stores exactly five fixed keys"],
  "真实凭据不由借鉴区持久化": ["The borrowing area must not persist actual credentials"],
  "操作系统或工具的凭据存储": ["operating-system or tool credential storage"],
  "私有 Git / Web 内容先在借鉴区外预取": ["Prefetch private Git/Web content outside the borrowing area"],
  "新 schema、独立 B 类授权与专用秘密存储方案": ["a new schema, separate Class B authorization, and dedicated secret storage"],
  "私有访问参数进入被忽略的 `*.local.json`": ["Private access parameters go into ignored `*.local.json`"],
  "Skill 只能调用可信关闭入口 `close-borrowing-item.ps1`": ["The Skill may invoke only the trusted `close-borrowing-item.ps1` closure entry point"],
  "完整根 P4t": ["full-root P4t"],
  "终锁复核": ["verifies the final official-card lock"],
  "锁内清理": ["performs cleanup under lock"],
  "全部成功才输出 closed": ["Report closed only after all steps succeed"],
  "由 Skill 调用独立 seal helper": ["The Skill invokes a separate seal helper"],
  "不得": ["Do not", "must not"],
  "只有实际返回值为 `project` 才能继续": ["continue only when the actual return value is `project`"],
  "fixture 以 `template-only` / `project-only` 表示 marker 组合": ["Fixtures use `template-only` / `project-only` for marker combinations"],
  "实际分别返回 `template` / `project`": ["actual `Get-CzxtRootMode` results of `template` / `project`"],
  "仅 `project` 可进入": ["Only `project` continues"],
  "只有 project-only 才能继续": ["Only project-only can continue"],
  "template-only、unknown、conflict 均 exit 10": ["template-only, unknown, and conflict all return exit 10"],
  "任何硬链接": ["no reparse points, symlinks, junctions, or hardlinks"],
  "API 不可用均硬失败": ["Unavailable link-count APIs fail hard"],
  "NumberOfLinks 必须等于 1": ["must prove `NumberOfLinks=1`"],
  "无法确认则硬失败": ["Inability to confirm is a hard failure"],
  "不得降级为 warning": ["never a warning"],
  "声明外硬链接": ["undeclared hardlinks"],
  "硬失败或明确 warning": ["hard failure or an explicit warning"],
  "fingerprint 不变": ["fingerprint is unchanged"],
  "fingerprint 改变": ["fingerprint changes", "Changed fingerprints", "fingerprints change"],
  "新增 capture": ["Create a new capture", "create new captures", "Create new captures"],
  "刷新成功也必须新增 capture": ["Successful refresh must also create a new capture"],
  "刷新永远新增 capture": ["Refresh always creates a new capture"],
  "来源刷新必须新增 capture": ["Source refresh must create a new capture"],
  "失败不写正式 ready 卡片": ["Failure writes no official ready card"],
  "允许保留被忽略的候选卡与 staging": ["Ignored candidate cards and staging may remain"],
  "捕获失败": ["Capture failure"],
  "不登记正式 ready": ["register no official ready capture"],
  "可保留被忽略的候选卡与 staging": ["Ignored candidate cards and staging may remain"],
  "同状态追加证据": ["Same-state evidence additions"],
  "仅限活动状态": ["allowed only in active states"],
  "只读检测": ["Read-only detection", "detected and recorded read-only"],
  "禁止": ["are prohibited"],
  "下载": ["downloading"],
  "执行": ["execution"],
  "禁 hooks、凭据提示、LFS、submodule": ["Prohibit hooks, credential prompts, LFS, and submodules"],
  "全量字节与 SHA-256": ["complete bytes, and SHA-256"],
  "前 `64 KiB`": ["first `64 KiB`"],
  "三轮实际读取": ["three actual-read passes", "The three read passes"],
  "全调用共享预算": ["The three read passes share one fail-closed budget"],
  "`20000` 个文件": ["`20000` files"],
  "`100000` 个目录项": ["`100000` directory entries"],
  "`512 MiB` 摘要读取": ["`512 MiB` of digest reads"],
  "项目卡单次 `1 MiB`": ["Project-card reads allow `1 MiB` each"],
  "两次合计 `2 MiB`": ["`2 MiB` across initial/final reads"],
  "严格 UTF-8": ["strict UTF-8"],
  "带 BOM 的 UTF-16LE / UTF-16BE": ["BOM-marked UTF-16LE / UTF-16BE"],
  "非终止解码器": ["non-finalizing decoder"],
  "保留当前正式卡与 staging": ["retain the current official card and staging"],
  "不可逆": ["irreversible"],
  "不回滚正式卡": ["do not roll back the official card"],
  "任一步失败恢复原活动字节": ["Restore the original active bytes on any failure"],
  "seal helper、根 P4t、终锁复核或锁内清理失败均执行恢复": ["Restore after every seal helper, root P4t, final-lock verification, or locked-cleanup failure"],
  "seal 原子写入": ["atomic seal write"],
  "受信父目录句柄": ["trusted parent-directory handle"],
  "相对原子创建 staging 目录": ["atomically create the staging directory relative to"],
  "目录句柄相对 CreateNew": ["handle-relative CreateNew"],
  "同一 handle 写入、flush 并绑定": ["write, flush, and bind it on that same handle"],
  "文件 lease 贯穿整个事务": ["file lease throughout the transaction"],
  "目录保持非空": ["directory stays nonempty", "directory remains nonempty"],
  "也以目录句柄相对 CreateNew": ["with handle-relative CreateNew as well"],
  "先 Verify 再绝对路径 CreateNew": ["Verify first, then use absolute-path CreateNew"],
  "Verify 后再以绝对路径 CreateNew": ["After Verify, use absolute-path CreateNew"],
  "同一 handle 设置 delete-pending": ["set delete-pending on that same handle"],
  "立即进入 `content-deleted`": ["Immediately enter `content-deleted`"],
  "目录创建句柄同句柄删除": ["delete the directory through its creation handle"],
  "验证与路径打开之间不得留窗口": ["Leave no gap between validation and path opening"],
  "创建失败只删除本事务句柄绑定对象": ["Creation failures delete only objects bound to this transaction's handles"],
  "P4t exit 0 后": ["After P4t exit 0"],
  "单次 OPEN_REPARSE_POINT 打开": ["one OPEN_REPARSE_POINT open"],
  "同一 handle 复核 canonical path": ["Recheck canonical path, regular non-reparse type, link count=1, identity, length, and bytes from that same handle"],
  "常规非 reparse 类型": ["regular non-reparse type"],
  "identity、length 与 bytes": ["identity, length, and bytes"],
  "持有到 staging 清理结束": ["Hold this exclusive lease until staging cleanup finishes"],
  "禁止“先安全路径验证再按路径重开”": ["Never validate a safe path and then reopen by path"],
  "正式卡所有权快照": ["official-card ownership snapshot"],
  "当前 staging 候选快照": ["current staging-candidate snapshot"],
  "两个独立状态": ["are independent states"],
  "必须分别验证": ["Rollback must validate each separately", "Rollback validates each separately"],
  "不得提前把 staging 期望改成 sealed 字节": ["Do not prematurely change the staging expectation to sealed bytes"],
  "Set 提交后状态对象先更新": ["After the Set operation in `Set-BctCandidateBytes` commits, update the state object before later checks that may fail"],
  "物理别名": ["physical aliases", "physical-alias overlap"],
  "源与目标": ["source, and target"],
  "输出 manifest": ["output manifest"],
  "失败不承诺全局原子回滚": ["promises no global atomic rollback on failure", "Failed multi-file installation promises no global atomic rollback", "no promise of global atomic rollback on failure"],
  "保留可审计残留": ["Preserve auditable remnants"],
  "每个已安装或改写输出即时登记": ["Register each installed or rewritten output immediately"],
  "最终 marker/成功输出前对 manifest 全部条目保持只读共享 lease": ["Before the final marker/success output, retain read-only shared leases on every manifest entry"],
  "任务启动基线": ["task's starting baseline"],
  "空白分隔敏感键": ["whitespace-delimited sensitive keys"],
  "JSON Unicode 转义键": ["JSON Unicode-escaped keys"],
  "标点开头的非空显式值": ["explicit nonempty values beginning with punctuation"],
  "畸形 Unicode 转义按凭据 fail closed": ["Malformed Unicode escapes fail closed as credentials"]
}
'@ | ConvertFrom-Json

function Get-BorrowingCrossLanguageAlternatives {
  param([string]$Needle)
  $choices = @($Needle)
  $property = $script:BorrowingCrossLanguageAliases.PSObject.Properties[$Needle]
  if ($null -ne $property) { $choices += @($property.Value) }
  return $choices
}

function Assert-BorrowingCrossContainsAll {
  param([string]$Text, [string[]]$Needles, [string]$Context)
  foreach ($needle in $Needles) {
    $found = $false
    foreach ($choice in @(Get-BorrowingCrossLanguageAlternatives $needle)) {
      if ($Text.Contains($choice)) { $found = $true; break }
    }
    Assert-CzxtTrue $found ("{0} missing: {1}" -f $Context, $needle)
  }
}

function Assert-BorrowingCrossExcludesAll {
  param([string]$Text, [string[]]$Needles, [string]$Context)
  foreach ($needle in $Needles) {
    foreach ($choice in @(Get-BorrowingCrossLanguageAlternatives $needle)) {
      Assert-CzxtTrue (-not $Text.Contains($choice)) `
        ("{0} must not contain: {1}" -f $Context, $choice)
    }
  }
}

function Assert-BorrowingCrossLineSequence {
  param([string]$Text, [string[]]$ExpectedLines, [string]$Context)
  $actual = @($Text.Replace("`r`n", "`n") -split "`n")
  for ($start = 0; $start -le $actual.Count - $ExpectedLines.Count; $start++) {
    $matched = $true
    for ($offset = 0; $offset -lt $ExpectedLines.Count; $offset++) {
      $lineMatched = $false
      foreach ($choice in @(Get-BorrowingCrossLanguageAlternatives $ExpectedLines[$offset])) {
        if ($actual[$start + $offset] -ceq $choice) { $lineMatched = $true; break }
      }
      if (-not $lineMatched) { $matched = $false; break }
    }
    if ($matched) { return }
  }
  throw ("{0} missing exact contiguous lines" -f $Context)
}
