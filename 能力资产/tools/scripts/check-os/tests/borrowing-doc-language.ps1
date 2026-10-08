$ErrorActionPreference = 'Stop'

# Exact, position-preserving projection for reviewed English documentation only.
# No substring, case-folding, whitespace, or numeric aliases are accepted.
# Canonical lines retain the established legacy assertions, including historical
# capture examples; English capture examples reflect the actual plain-none protocol.
function ConvertTo-BorrowingDocContractText {
  param([string]$Text, [string]$RelativePath)
  $dataName = switch -CaseSensitive ($RelativePath) {
    '能力资产/skills/借鉴.md' { 'borrowing-doc-skill-language.json' }
    '能力资产/skills/借鉴-命令附录.md' { 'borrowing-doc-command-language.json' }
    '操作系统/07_完整工作流/借鉴闭环.md' { 'borrowing-doc-workflow-language.json' }
    '能力资产/rules/借鉴治理.md' { 'borrowing-doc-rule-language.json' }
    '操作系统/05_记忆/行为反思.md' { 'borrowing-doc-reflection-language.json' }
    default { return $Text }
  }
  $data = Get-Content -LiteralPath (Join-Path $PSScriptRoot $dataName) -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($data.schema -cne 'borrowing-doc-language/v1' -or $data.relativePath -cne $RelativePath) {
    throw 'Borrowing documentation language map has an invalid identity'
  }
  # Legacy documents continue through their original semantic assertions unchanged.
  if (-not $Text.Contains([string]$data.englishHeading)) { return $Text }
  $lines = @($Text.Replace("`r`n", "`n") -split "`n")
  if ($lines.Count -ne $data.lines.Count) {
    throw ('English borrowing document line count changed: {0}' -f $RelativePath)
  }
  $canonical = New-Object 'Collections.Generic.List[string]'
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -cne [string]$data.lines[$i].english) {
      throw ('Unknown English borrowing contract line: {0}:{1}' -f $RelativePath, ($i + 1))
    }
    [void]$canonical.Add([string]$data.lines[$i].canonical)
  }
  return ($canonical -join "`n")
}
