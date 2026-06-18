param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"

$checks = @(
    @{ Path = "能力资产/README.md"; Pattern = '等 12 文件|操作系统 PM-框架管家|部分子目录允许产品 PM 写'; Label = "能力资产总入口仍含旧计数、旧 PM 写法或越权写入口径" },
    @{ Path = "能力资产/shared/README.md"; Pattern = '跨载体协作'; Label = "shared README 仍把跨分支协作写成跨载体" },
    @{ Path = "能力资产/shared/分支间协作机制.md"; Pattern = '工具载体协作位|Cowork chat 上下文|操作系统 / 产品 / 技术 / 测试 / 运营 PM'; Label = "分支间协作仍残留旧工具主语或运营 PM 双重归属" },
    @{ Path = "能力资产/rules/codex-push后防御.md"; Pattern = 'Cowork chat 内继续工作的 PM|PM 在 Cowork chat 内继续操作前|Cowork 这边查看实际状态|任何 Cowork 内 Edit|让 Cowork 完全停止 file 操作'; Label = "Codex push 防御仍绑定 Cowork 运行时" },
    @{ Path = "能力资产/mcp/INSTALLED.md"; Pattern = '项目核心使用（必装）|workspace（bash \+ web_fetch）|session_info（如需读 transcript）|computer-use（仅 Cowork 桌面控制）|cowork（仅 Cowork 文件 mount）'; Label = "MCP 清单仍把历史同名 MCP 当当前必装项" },
    @{ Path = "能力资产/agents/README.md"; Pattern = '当前 Codex runtime|spawn_agent|项目 PM / 操作系统 PM / 产品 PM / 技术 PM / 测试 PM / 运营 PM|(?<!不)沉淀自动执行高风险动作'; Label = "agents 预留区仍绑定工具、遗漏 9 PM 或暗示高风险自动执行" },
    @{ Path = "能力资产/workflows/README.md"; Pattern = '自动 ship 链'; Label = "workflows 预留区仍暗示发布动作可自动化" },
    @{ Path = "能力资产/shared/品牌词典.md"; Pattern = 'token-plan-sgp|数据不出境|SGP 节点'; Label = "品牌词典仍含旧 endpoint 或未确认数据驻留承诺" },
    @{ Path = "能力资产/shared/分支间协作机制.md"; Pattern = 'PM工作区/运营PM-运营咪咪/状态.md|项目 PM drop|元规则池当前 23|Memory 系统'; Label = "分支间协作仍含旧状态/记忆/直投口径" },
    @{ Path = "能力资产/skills/项目体检.md"; Pattern = 'P4a-P4[op]'; Label = "项目体检入口未同步 P4q" },
    @{ Path = "能力资产/skills/README.md"; Pattern = 'P4a-P4[op]'; Label = "skills README 未同步 P4q" },
    @{ Path = "能力资产/tools/README.md"; Pattern = 'P4a-P4[op]'; Label = "tools README 未同步 P4q" },
    @{ Path = "能力资产/tools/scripts/check-os/write-summary.ps1"; Pattern = 'P4n\+P4o\+P4p(?!\+P4q)'; Label = "体检汇总文案未同步 P4q" },
    @{ Path = "能力资产/mcp/README.md"; Pattern = '补到 .* C 类边界|MCP 跟 AI 边界 C 类'; Label = "MCP README 仍把 git/外部动作一概写成 C 类" },
    @{ Path = "能力资产/mcp/INSTALLED.md"; Pattern = '当前 0 使用（已装但未触发）|大量已装 MCP|Claude Code \| Claude Code 配置 \| 同上|实际 MCP token / API key 仍走 \\.env\\.local'; Label = "MCP INSTALLED 仍含安装状态/secret 旧口径" }
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
    Write-Host "  🔴 能力资产剩余区旧口径：$($hits.Count) 处" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ shared / mcp / agents / workflows 旧口径守卫通过" -ForegroundColor Green
exit 0
