param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Claude Code PreToolUse 适配器（PROP-038 / 议题 CG / 安全与隐私铁律）：
# Edit/Write 若往「非 .env」文件写入疑似密钥/凭据（结构化 key 模式）时，permissionDecision=ask 提醒确认。
# 设计取舍：只 ASK，绝不 deny（避免误拦真实工作）；只认 {20,} 长度的结构化 key 模式（避免文档里 "sk-ant-..." 省略号误报）；
# .env / .env.local 是密钥的合法去处 → 一律放行。全程 fail-safe：任何不确定/出错都放行（continue）。

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {}

function Allow { [ordered]@{ continue = $true } | ConvertTo-Json -Compress; exit 0 }

$raw = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrEmpty($raw)) { $raw = $raw.TrimStart([char]0xFEFF) }
if ([string]::IsNullOrWhiteSpace($raw)) { Allow }
try { $e = $raw | ConvertFrom-Json } catch { Allow }

$fp = ""
try { if ($e.tool_input.file_path) { $fp = [string]$e.tool_input.file_path } } catch {}
if ([string]::IsNullOrWhiteSpace($fp)) { Allow }

# 拼出将要写入的文本：Write 用 content；Edit 用 new_string
$content = ""
try {
  if ($e.tool_input.content) { $content = [string]$e.tool_input.content }
  if ($e.tool_input.new_string) { $content = $content + "`n" + [string]$e.tool_input.new_string }
} catch {}
if ([string]::IsNullOrWhiteSpace($content)) { Allow }

# .env / .env.local / .env.*.local 是密钥合法去处（且通常 gitignore）→ 放行；
# .env.example / .env.local.example 等 tracked 示例文件不能放行真实 key。
$fpN = $fp -replace '\\', '/'
$baseName = ($fpN -split '/')[-1]
if ($baseName -match '^\.env$|^\.env\.local$|^\.env\..+\.local$') { Allow }

# 结构化密钥模式（要求足够长，避免文档省略号误报）
$patterns = @(
  'sk-ant-[A-Za-z0-9_\-]{20,}',
  'sk-[A-Za-z0-9]{32,}',
  'AKIA[0-9A-Z]{16}',
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
)
$hit = $null
foreach ($p in $patterns) { if ($content -match $p) { $hit = $p; break } }
if (-not $hit) { Allow }

$reason = "疑似密钥/凭据将写入非 .env 文件：$fp（命中模式 $hit）。按议题 CG + 安全与隐私铁律：密钥不进 git tracked 文件 / 不贴文档。若是占位或示例可继续；真实密钥请改放 .env.local。"
[ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName = "PreToolUse"
    permissionDecision = "ask"
    permissionDecisionReason = $reason
  }
} | ConvertTo-Json -Depth 6 -Compress
