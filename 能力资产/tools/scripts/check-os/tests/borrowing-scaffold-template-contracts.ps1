$ErrorActionPreference = 'Stop'

function Invoke-BorrowingTemplateContracts {
  param(
    [string]$TemplateRoot,
    [string]$InstallerPath,
    [string[]]$SkeletonPaths
  )

  Invoke-CzxtContract 'template contains the neutral borrowing skeleton' {
    foreach ($relativePath in $SkeletonPaths) {
      $fullPath = Join-Path $TemplateRoot ($relativePath.Replace('/', '\'))
      Assert-CzxtTrue (Test-Path -LiteralPath $fullPath -PathType Leaf) `
        ("missing skeleton path: {0}" -f $relativePath)
    }
    foreach ($relativePath in @('借鉴区/来源/.gitkeep', '借鉴区/事项/.gitkeep')) {
      $sentinel = Get-Item -LiteralPath (Join-Path $TemplateRoot ($relativePath.Replace('/', '\\')))
      Assert-CzxtEqual 0 $sentinel.Length ("sentinel must be zero-byte: {0}" -f $relativePath)
    }
  }

  Invoke-CzxtContract 'installer excludes borrowing root and exposes dedicated copy' {
    $installerText = [IO.File]::ReadAllText($InstallerPath)
    $match = [regex]::Match($installerText, '\$copyItems\s*=\s*@\((?<body>[\s\S]*?)\)')
    Assert-CzxtTrue $match.Success 'installer copyItems list is missing'
    $copyItems = @([regex]::Matches($match.Groups['body'].Value, '"([^"]+)"') |
      ForEach-Object { $_.Groups[1].Value })
    Assert-CzxtTrue ($copyItems -notcontains '借鉴区') 'copyItems must not recursively copy 借鉴区'
    Assert-BorrowingContainsAll $installerText @(
      'Copy-BorrowingZoneSkeleton',
      'Test-CzxtBorrowingPlaceholderRewriteAllowed'
    ) 'installer dedicated borrowing integration'
  }

  Invoke-CzxtContract 'borrowing gitignore isolates only local cache and staging' {
    $cases = @(
      @('借鉴区/来源/example/git-20260718-a1b2c3d4e5f6/快照/code.ps1', $true),
      @('借鉴区/来源/example/git-20260718-a1b2c3d4e5f6/source.local.json', $true),
      @('借鉴区/事项/borrow-20260718-example/证据/raw/page.bin', $true),
      @('借鉴区/来源/example/.staging-123/file.bin', $true),
      @('借鉴区/模板/来源版本卡.md', $false),
      @('借鉴区/模板/借鉴卡.md', $false),
      @('借鉴区/来源/example/git-20260718-a1b2c3d4e5f6/来源版本卡.md', $false),
      @('借鉴区/事项/borrow-20260718-example/借鉴卡.md', $false),
      @('借鉴区/事项/borrow-20260718-example/证据/验证摘要.md', $false)
    )
    foreach ($case in $cases) {
      Assert-BorrowingGitIgnoreState -TemplateRoot $TemplateRoot `
        -RelativePath $case[0] -ExpectedIgnored $case[1]
    }
  }

  Invoke-CzxtContract 'borrowing README is the static Skill entry with zero business dependency' {
    $path = Join-Path $TemplateRoot '借鉴区\README.md'
    $text = [IO.File]::ReadAllText($path)
    Assert-BorrowingContainsAll $text @(
      '[借鉴 Skill](../能力资产/skills/借鉴.md)',
      "Get-ChildItem -LiteralPath '借鉴区/来源'",
      "Get-ChildItem -LiteralPath '借鉴区/事项'",
      '不维护第二份活跃索引表',
      '业务仓库不得通过', 'import', 'require', 'file:',
      '工作区/构建配置', '脚本', '运行时读取'
    ) 'borrowing README'
    $skillLinks = [regex]::Matches($text, '\]\(\.\./能力资产/skills/借鉴\.md\)')
    Assert-CzxtEqual 1 $skillLinks.Count 'borrowing README must expose exactly one Skill link'
    $concreteSourceName = '小小' + '的我'
    Assert-CzxtTrue (-not $text.Contains($concreteSourceName)) 'template README leaked a concrete source name'
  }

  Invoke-CzxtContract 'source card template follows appendix B' {
    $path = Join-Path $TemplateRoot '借鉴区\模板\来源版本卡.md'
    $text = [IO.File]::ReadAllText($path)
    Assert-BorrowingContainsAll $text @(
      'schema: borrowing-source/v1', 'source_id:', 'capture_id:', 'source_type:',
      'capture_status:', 'canonical_locator:', 'fingerprint_algorithm:', 'fingerprint:',
      'captured_at:', 'rights_status:', 'access_policy:', 'reuse_scope:',
      'execution_policy:', 'network_policy:', 'storage_policy:', 'distribution_policy:',
      'upstream_write_policy: deny', 'auto_refresh: false',
      '权限维度 | 生效值 | 授权时间 | 授权来源 | 适用范围',
      '| auto_refresh | false |',
      'ref', 'object format', 'manifest', '原始 URL', '管理历史'
    ) 'source card template'
    Assert-CzxtTrue $text.Contains('{{PROJECT_NAME}}') 'source template lost project placeholder anchor'
  }

  Invoke-CzxtContract 'borrowing card template follows appendix C' {
    $path = Join-Path $TemplateRoot '借鉴区\模板\借鉴卡.md'
    $text = [IO.File]::ReadAllText($path)
    Assert-BorrowingContainsAll $text @(
      'schema: borrowing-item/v1', 'borrow_id:', 'title:', 'lifecycle_status:',
      'decision:', 'impact_level:', 'owner_pm:', 'blocked:', 'created_at:', 'updated_at:',
      'supersedes:', 'closure_seal_sha256:', '问题与成功标准',
      'source_id | capture_id | fingerprint | 证据定位符',
      '已有能力 | 可借鉴点 | 冲突 | 结论 | 理由', '明确采纳', '明确不采纳',
      '目标文件', '责任 PM', 'PROP/ADR', '验收标准', '实施记录', 'fresh 验证证据',
      '时间 | 旧状态 | 新状态 | decision | 原因 | 确认'
    ) 'borrowing card template'
    Assert-CzxtTrue $text.Contains('{{PROJECT_NAME}}') 'borrowing template lost project placeholder anchor'
  }

}
