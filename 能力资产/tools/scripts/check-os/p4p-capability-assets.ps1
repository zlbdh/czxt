param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"

$checks = @(
    @{ Path = "能力资产/README.md"; Pattern = '等 12 文件|操作系统 PM-框架管家|部分子目录允许产品 PM 写|(?i:including 12 files|Operating System PM-Framework Steward|some subdirectories allow Product PM writes)'; Label = "Capability-asset entry still has obsolete counts, PM names, or unauthorized write guidance" },
    @{ Path = "能力资产/shared/README.md"; Pattern = '跨载体协作|(?i:cross-runtime collaboration)'; Label = "Shared README still describes cross-branch collaboration as cross-runtime work" },
    @{ Path = "能力资产/shared/分支间协作机制.md"; Pattern = '工具载体协作位|Cowork chat 上下文|操作系统 / 产品 / 技术 / 测试 / 运营 PM|(?i:tool-runtime collaboration slot|Cowork chat context|Operating System / Product / Technical / Test / Operations PM)'; Label = "Cross-branch collaboration still uses obsolete tool subjects or assigns Operations PM to two branches" },
    @{ Path = "能力资产/rules/codex-push后防御.md"; Pattern = 'Cowork chat 内继续工作的 PM|PM 在 Cowork chat 内继续操作前|Cowork 这边查看实际状态|任何 Cowork 内 Edit|让 Cowork 完全停止 file 操作|(?i:PM continuing work in Cowork chat|before the PM continues operations in Cowork chat|check the actual state on the Cowork side|any Edit within Cowork|make Cowork stop all file operations)'; Label = "Codex push safeguards still depend on the Cowork runtime" },
    @{ Path = "能力资产/mcp/INSTALLED.md"; Pattern = '项目核心使用（必装）|workspace（bash \+ web_fetch）|session_info（如需读 transcript）|computer-use（仅 Cowork 桌面控制）|cowork（仅 Cowork 文件 mount）|(?i:Core project use \(required installation\)|workspace \(bash \+ web_fetch\)|session_info \(when reading transcripts\)|computer-use \(Cowork desktop control only\)|cowork \(Cowork file mounts only\))'; Label = "MCP inventory still treats historical namesake MCPs as current requirements" },
    @{ Path = "能力资产/agents/README.md"; Pattern = '当前 Codex runtime|spawn_agent|项目 PM / 操作系统 PM / 产品 PM / 技术 PM / 测试 PM / 运营 PM|(?<!不)沉淀自动执行高风险动作|(?i:current Codex runtime|Project PM / Operating System PM / Product PM / Technical PM / Test PM / Operations PM|(?<!Do not )establish agents that automatically perform high-risk actions)'; Label = "Reserved agent area still binds work to a tool, omits PM roles, or implies automatic high-risk actions" },
    @{ Path = "能力资产/workflows/README.md"; Pattern = '自动 ship 链|(?i:automatic ship chain)'; Label = "Reserved workflow area still implies automated release actions" },
    @{ Path = "能力资产/shared/品牌词典.md"; Pattern = 'token-plan-sgp|数据不出境|SGP 节点|(?i:data does not leave the country|SGP node)'; Label = "Brand glossary still includes an obsolete endpoint or an unconfirmed data-residency promise" },
    @{ Path = "能力资产/shared/分支间协作机制.md"; Pattern = 'PM工作区/运营PM-运营咪咪/状态.md|项目 PM drop|元规则池当前 23|Memory 系统|(?i:Project PM drop|meta-rule pool currently 23|Memory system)'; Label = "Cross-branch collaboration still has obsolete status, memory, or direct-submission guidance" },
    @{ Path = "能力资产/skills/项目体检.md"; Pattern = 'P4a-P4[op]'; Label = "Health-check entry does not include P4q" },
    @{ Path = "能力资产/skills/README.md"; Pattern = 'P4a-P4[op]'; Label = "Skills README does not include P4q" },
    @{ Path = "能力资产/tools/README.md"; Pattern = 'P4a-P4[op]'; Label = "Tools README does not include P4q" },
    @{ Path = "能力资产/tools/scripts/check-os/write-summary.ps1"; Pattern = 'P4n\+P4o\+P4p(?!\+P4q)'; Label = "Health-check summary does not include P4q" },
    @{ Path = "能力资产/mcp/README.md"; Pattern = '补到 .* C 类边界|MCP 跟 AI 边界 C 类|(?i:add to .* Class C boundaries|MCP and AI boundaries are Class C)'; Label = "MCP README still classifies all Git/external actions as Class C" },
    @{ Path = "能力资产/mcp/INSTALLED.md"; Pattern = '当前 0 使用（已装但未触发）|大量已装 MCP|Claude Code \| Claude Code 配置 \| 同上|实际 MCP token / API key 仍走 \\.env\\.local|(?i:currently 0 used \(installed but not triggered\)|many installed MCPs|Claude Code \| Claude Code configuration \| same as above|actual MCP token / API key still uses \.env\.local)'; Label = "MCP inventory still has obsolete installation-status or secret-handling guidance" }
)

$hits = @()
foreach ($check in $checks) {
    $path = Join-Path $Root $check.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($match in [regex]::Matches($text, $check.Pattern)) {
        $line = ($text.Substring(0, $match.Index) -split "`n").Count
        $hits += "$($check.Path):L$line $($check.Label)"
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  🔴 Obsolete language in remaining capability assets: $($hits.Count) matches" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ Shared / MCP / agent / workflow obsolete-language guards passed" -ForegroundColor Green
exit 0
