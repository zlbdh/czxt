[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot '../../installer-render-text.ps1')
$anchorRoot = Join-Path $PSScriptRoot '../../check-readme-indexes'
$values = @{ APP_REPO_DIR='frontend.v2/app'; PROJECT_NAME='演示$()[x]'; CURRENT_SPRINT='Sprint.[x]$()' }
$cases = @(
  @{ File='agents-playbook-anchor.ps1'; Label='env 例外精确字段'; Exact='frontend.v2/app/.env.local` baseUrl/model/apiKey'; Near='frontendXv2/app/.env.local` baseUrl/model/apiKey' },
  @{ File='agents-playbook-anchor.ps1'; Label='产品 PM 测试路径禁写'; Exact='frontend.v2/app/src/**/__tests__/'; Near='frontendXv2/app/src/**/__tests__/' },
  @{ File='architecture-anchor.ps1'; Label='env 路径精确化'; Exact='frontend.v2/app/.env.local'; Near='frontendXv2/app/.env.local' },
  @{ File='memory-spec-anchor.ps1'; Label='项目外存储铁律过宽'; Exact='项目所需数据 / 配置 / 状态，必须在 `D:\WGKJ\演示$()[x]\` 内，Git 版本化'; Near='项目所需数据 / 配置 / 状态，必须在 `D:\WGKJ\演示x\` 内，Git 版本化' },
  @{ File='ledger-spec-anchor.ps1'; Label='Sprint 总览阶段边界'; Exact='Sprint 总览指针（当前 Sprint.[x]$()；明细表阶段截至 Sprint-7）'; Near='Sprint 总览指针（当前 SprintAx；明细表阶段截至 Sprint-7）' },
  @{ File='ledger-spec-anchor.ps1'; Label='Sprint 节奏当前 Sprint'; Exact='当前 **Sprint.[x]$()**'; Near='当前 **SprintAx**' },
  @{ File='governance-semantics-requirements-tests.ps1'; Label='v3.0 需求基线历史边界'; Exact='历史需求基线说明：当前 Sprint.[x]$() 发布状态'; Near='历史需求基线说明：当前 SprintAx 发布状态' },
  @{ File='governance-semantics-requirements-tests.ps1'; Label='产品路线图历史边界'; Exact='历史路线图说明 Sprint.[x]$()'; Near='历史路线图说明 SprintAx' }
)
foreach ($case in $cases) {
  Invoke-CzxtContract ('生产锚点参数正则语义: ' + $case.Label) {
    $source = [IO.File]::ReadAllText((Join-Path $anchorRoot $case.File))
    $text = ConvertTo-CzxtInstallerRenderedText $source '.ps1' $values
    $tokens=$null; $errors=$null
    $ast = [Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$errors)
    $commands = @($ast.FindAll({ param($node)
      $node -is [Management.Automation.Language.CommandAst] -and
      $node.CommandElements.Count -eq 4 -and
      $node.CommandElements[-1] -is [Management.Automation.Language.StringConstantExpressionAst]
    }, $true) | Where-Object { $_.CommandElements[-1].Value -ceq $case.Label })
    Assert-CzxtEqual 1 $commands.Count '没有唯一定位真实锚点断言'
    # 执行生产脚本实际传给断言器的表达式，再用独立正/负文本检验其语义。
    $pattern = & ([scriptblock]::Create($commands[0].CommandElements[2].Extent.Text))
    Assert-CzxtTrue ([regex]::IsMatch($case.Exact, $pattern)) '漏掉了字面参数的真实文本'
    Assert-CzxtTrue (-not [regex]::IsMatch($case.Near, $pattern)) '把参数元字符扩展为其它文本'
  }
}
Complete-CzxtContracts
