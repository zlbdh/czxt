$ErrorActionPreference = 'Stop'

function Write-AdrFixtureText {
  param([string]$Root, [string]$RelativePath, [string]$Content)
  Write-CzxtNoBomText (Join-Path $Root $RelativePath) $Content
}

function Initialize-MinimalTemplateRoot {
  param([string]$Root, [int]$EntryTotal, [int]$EntryCurrent, [int]$EntryReplaced)

  Write-AdrFixtureText $Root '.czxt-template-root' ''
  Write-AdrFixtureText $Root 'README.md' @'
# 操作系统模板

P1 已完成；P2 未完成。
'@
  Write-AdrFixtureText $Root '操作系统/00_总入口.md' ('
# 操作系统 · 总入口

能力资产/
└── 元规则池 + {0} ADR 永久档案（{1} 现行 + {2} 被替代/覆盖）
' -f $EntryTotal, $EntryCurrent, $EntryReplaced)
  Write-AdrFixtureText $Root '操作系统/04_台账/长期产品化路线图.md' 'P1 已完成；P2 未完成；自托管首证。'
  Write-AdrFixtureText $Root 'Docs/3-开发文档/README.md' '项目实例真值；模板根不预设。'
  Write-AdrFixtureText $Root 'Docs/3-开发文档/项目结构.md' '模板根导航；项目实例导航；项目实例真值。'
  Write-AdrFixtureText $Root 'Docs/3-开发文档/技术栈.md' '项目实例真值；[填写]。'
  Write-AdrFixtureText $Root 'Docs/3-开发文档/API规范.md' '项目实例真值；协议层；模型层；[填写]。'
  Write-AdrFixtureText $Root 'Docs/3-开发文档/数据库schema.md' '项目实例真值；迁移与兼容；[填写]。'
  Write-AdrFixtureText $Root '能力资产/skills/项目体检.md' '定向当前真值检查；项目实例真值。'
  Write-AdrFixtureText $Root '能力资产/tools/依赖矩阵.md' '项目实例真值。'
  Write-AdrFixtureText $Root '能力资产/shared/品牌词典.md' '协议层；模型层。'
  Write-AdrFixtureText $Root '操作系统/05_记忆/INDEX.md' '项目实例真值。'
  Write-AdrFixtureText $Root '项目配置/_模板.project.json' '{}'
  Write-AdrFixtureText $Root '项目区/清单.md' '模板项目区骨架。'

  $playbooks = @(
    '操作系统/02_智能体/操作系统PM-框架管家.md',
    '操作系统/02_智能体/产品PM-需求拆解者.md',
    '操作系统/02_智能体/技术PM-修复决策者.md',
    '操作系统/02_智能体/测试PM-质量门户.md',
    '操作系统/02_智能体/开发PM-实施者.md',
    '操作系统/02_智能体/测试发布PM-闭环者.md',
    '操作系统/02_智能体/运营PM-运营咪咪.md'
  )
  foreach ($playbook in $playbooks) {
    Write-AdrFixtureText $Root $playbook '项目实例真值。'
  }

  Write-AdrFixtureText $Root '确认改动/README.md' @'
| 待审批 | 进行中 | 已完成 | 已弃用 | 拒绝 |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 |
'@
}

function Add-AdrSet {
  param(
    [string]$Root,
    [int]$Total = 39,
    [int[]]$ReplacedNumbers = @(3, 7, 11),
    [int[]]$OmitFiles = @(),
    [int[]]$OmitRows = @(),
    [int[]]$UnknownStatusNumbers = @(),
    [switch]$DuplicateFileNumber,
    [switch]$DuplicateIndexRow
  )

  $adrDir = Join-Path $Root 'Docs/3-开发文档/adr'
  [void](New-Item -ItemType Directory -Path $adrDir -Force)
  Write-CzxtNoBomText (Join-Path $adrDir '_模板.md') '# ADR 模板'

  $rows = New-Object System.Collections.Generic.List[string]
  $rows.Add('---')
  $rows.Add(('description: ADR 永久决策档案索引（{0} 个 ADR）' -f $Total))
  $rows.Add('---')
  $rows.Add('# ADR')
  $rows.Add('| 编号 | 标题 | 状态 | 日期 |')
  $rows.Add('|---|---|---|---|')

  for ($i = 1; $i -le $Total; $i++) {
    $num = '{0:D3}' -f $i
    if ($OmitFiles -notcontains $i) {
      Write-CzxtNoBomText (Join-Path $adrDir ('ADR-{0}-测试决策.md' -f $num)) "# ADR-$num`n"
    }

    if ($OmitRows -notcontains $i) {
      $status = '现行'
      if ($ReplacedNumbers -contains $i) { $status = '被 ADR-999 部分替代' }
      if ($UnknownStatusNumbers -contains $i) { $status = '草稿' }
      $rows.Add(('| ADR-{0} | 测试决策 {0} | {1} | 2026-09-04 |' -f $num, $status))
      if ($DuplicateIndexRow -and $i -eq 1) {
        $rows.Add(('| ADR-{0} | 重复测试决策 {0} | {1} | 2026-09-04 |' -f $num, $status))
      }
    }
  }

  if ($DuplicateFileNumber) {
    Write-CzxtNoBomText (Join-Path $adrDir 'ADR-001-重复测试决策.md') '# duplicate ADR-001'
  }

  Write-CzxtNoBomText (Join-Path $adrDir 'README.md') (($rows -join "`n") + "`n")
}

function New-AdrFixtureRoot {
  param(
    [int]$Total = 39,
    [int[]]$ReplacedNumbers = @(3, 7, 11),
    [int]$EntryTotal = $Total,
    [int]$EntryCurrent = ($Total - @($ReplacedNumbers).Count),
    [int]$EntryReplaced = @($ReplacedNumbers).Count,
    [int[]]$OmitFiles = @(),
    [int[]]$OmitRows = @(),
    [int[]]$UnknownStatusNumbers = @(),
    [switch]$DuplicateFileNumber,
    [switch]$DuplicateIndexRow
  )

  $root = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
  # 创建成功才登记所有权；finally 只清本轮登记项，保留同父历史与并发现场。
  [void](New-Item -ItemType Directory -Path $root -ErrorAction Stop)
  $script:AdrOwnedFixtureRoots.Add($root)
  Initialize-MinimalTemplateRoot -Root $root -EntryTotal $EntryTotal -EntryCurrent $EntryCurrent -EntryReplaced $EntryReplaced
  Add-AdrSet -Root $root -Total $Total -ReplacedNumbers $ReplacedNumbers `
    -OmitFiles $OmitFiles -OmitRows $OmitRows -UnknownStatusNumbers $UnknownStatusNumbers `
    -DuplicateFileNumber:$DuplicateFileNumber -DuplicateIndexRow:$DuplicateIndexRow
  return $root
}

function Invoke-AdrGate {
  param([string]$ScriptPath, [string]$Root)
  return Invoke-CzxtPowerShell -ScriptPath $ScriptPath -ScriptArguments @('-Root', $Root)
}

function Assert-AdrCleanupIsolation {
  param([string]$ContractPath)
  $parent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-adr-cleanup-contracts'))
  $sandbox = Join-Path $parent ([guid]::NewGuid().ToString('N'))
  [void](New-Item -ItemType Directory -Path $sandbox)
  $previousTemp = $env:TEMP
  try {
    $sharedParent = Join-Path $sandbox 'czxt-adr-governance-count-tests'
    $sentinels = @(
      (Join-Path $sharedParent 'historical-failure/sentinel.txt'),
      (Join-Path $sharedParent 'other-running-round/sentinel.txt')
    )
    foreach ($sentinel in $sentinels) { Write-CzxtNoBomText $sentinel 'owned by another round' }
    $env:TEMP = $sandbox
    $result = Invoke-CzxtPowerShell -ScriptPath $ContractPath -ScriptArguments @('-CleanupProbe')
    $env:TEMP = $previousTemp
    Assert-CzxtEqual 0 $result.ExitCode ('cleanup probe failed: {0}' -f $result.StdErr)
    foreach ($sentinel in $sentinels) {
      Assert-CzxtTrue (Test-Path -LiteralPath $sentinel -PathType Leaf) ('cleanup removed foreign sentinel: {0}' -f $sentinel)
      Assert-CzxtEqual 'owned by another round' ([IO.File]::ReadAllText($sentinel)) 'foreign sentinel content changed'
    }
    $ownedRoot = $result.StdOut.Trim()
    Assert-CzxtTrue ($ownedRoot.StartsWith($sharedParent + '\', [StringComparison]::OrdinalIgnoreCase)) 'probe did not report its own fixture'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $ownedRoot)) 'cleanup left its own fixture behind'
  }
  finally {
    $env:TEMP = $previousTemp
    Remove-CzxtFixture -FixtureParent $parent -FixtureRoot $sandbox
  }
}
