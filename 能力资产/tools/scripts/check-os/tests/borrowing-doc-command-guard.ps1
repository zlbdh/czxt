$ErrorActionPreference = 'Stop'

function Test-BorrowingGitCommandLine {
  param([string]$Line, [bool]$CodeContext)
  $value = $Line.TrimStart()
  $value = [regex]::Replace($value, '^(?:[-*+]\s+|>\s+)', '')
  $value = [regex]::Replace($value, '^(?:PS[^>]*>|\$|>)\s*', '', 'IgnoreCase')
  $pattern = '^(?:&[ \t]*)?(?:[''"])?git(?:\.exe)?(?:[''"])?(?<tail>(?:[ \t]+|`+).*)?$'
  $match = [regex]::Match($value, $pattern, 'IgnoreCase')
  if (-not $match.Success) { return $false }
  $tail = $match.Groups['tail'].Value.TrimStart()
  if ($tail.Length -eq 0) { return $true }
  if ($tail[0] -eq '`') { return $true }
  return [regex]::IsMatch([string]$tail[0], '[-A-Za-z0-9./]')
}

function Test-BorrowingContainsGitCommand {
  param([string]$Text)
  $scan = Get-BorrowingMarkdownScan $Text
  for ($index = 0; $index -lt $scan.Lines.Count; $index++) {
    $line = $scan.Lines[$index]
    $codeContext = -not $scan.OutsideFence[$index]
    if (Test-BorrowingGitCommandLine $line $codeContext) { return $true }
    foreach ($match in [regex]::Matches($line, '`+(?<code>[^`\r\n]+)`+')) {
      if (Test-BorrowingGitCommandLine $match.Groups['code'].Value $true) { return $true }
    }
  }
  return $false
}

function Assert-BorrowingCommandPublicSurface {
  param([string]$Text)
  Assert-CzxtTrue (-not (Test-BorrowingContainsGitCommand $Text)) `
    'command appendix exposes a direct git/git.exe command'
  Assert-BorrowingDocNoMatch $Text '(?i)borrowing-capture[/\\][^\s)`]+\.ps1' 'internal capture helper path'
  Assert-BorrowingDocNoMatch $Text '(?i)source-candidate-validator\.ps1' 'candidate validator helper path'
  Assert-BorrowingDocNoMatch $Text '(?i)(copy-item|get-filehash|certutil|sha256sum|-runner|-transport|scriptblock|git-runner\.ps1)' 'manual capture or injected runner'
}
