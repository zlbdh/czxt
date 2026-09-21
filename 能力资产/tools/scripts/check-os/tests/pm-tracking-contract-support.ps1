# Shared helpers for pm-tracking-contracts.ps1.

$ErrorActionPreference = "Stop"

function New-TempRoot {
  $root = Join-Path ([System.IO.Path]::GetTempPath()) ("czxt-pmtracking-" + [Guid]::NewGuid().ToString("N"))
  [void][System.IO.Directory]::CreateDirectory($root)
  $script:tempRoots.Add($root)
  return $root
}

function Assert-SafeTempRoot {
  param([string]$Path)

  $full = [System.IO.Path]::GetFullPath($Path)
  $temp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
  if (-not $full.StartsWith($temp, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "refuse cleanup outside temp: $full"
  }
  if ([System.IO.Path]::GetFileName($full) -notmatch '^czxt-pmtracking-[0-9a-f]{32}$') {
    throw "refuse cleanup unknown temp root: $full"
  }
}

function Write-Utf8File {
  param([string]$Path, [string]$Value)

  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
    [void][System.IO.Directory]::CreateDirectory($dir)
  }
  $utf8Bom = New-Object System.Text.UTF8Encoding($true)
  [System.IO.File]::WriteAllText($Path, ($Value -replace "`r`n?", "`n"), $utf8Bom)
}

function Set-TreeLastWriteTime {
  param([string]$Root, [DateTime]$Time)

  Get-ChildItem -LiteralPath $Root -Recurse -Force | ForEach-Object {
    if ($_.FullName -notmatch '\\\.git(\\|$)') {
      $_.LastWriteTime = $Time
    }
  }
}

function New-CzxtFixture {
  param(
    [switch]$WithGit,
    [switch]$WithAppFile,
    [string]$Root = "",
    [string]$TrackTimestamp = "2000-01-01 00:00"
  )

  if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = New-TempRoot
  }

  Write-Utf8File -Path (Join-Path $Root "状态.md") -Value @"
# 状态

## PM 切换轨迹

| 时间 | 从角色 | 到角色 | 任务 | decision-checkpoint 跑过？ | 完成回流 |
|---|---|---|---|---|---|
| $TrackTimestamp | 项目 PM「咪咪」 | 操作系统 PM「框架管家」 | 初始化旧轨迹 | ✅ | ✅ |
"@
  Write-Utf8File -Path (Join-Path $Root "操作系统\tracked.md") -Value "tracked`n"
  Write-Utf8File -Path (Join-Path $Root "能力资产\tracked.md") -Value "tracked`n"
  Write-Utf8File -Path (Join-Path $Root "Docs\tracked.md") -Value "tracked`n"
  Write-Utf8File -Path (Join-Path $Root "README.md") -Value "README`n"
  Write-Utf8File -Path (Join-Path $Root "实例化项目.ps1") -Value "# installer`n"
  Write-Utf8File -Path (Join-Path $Root ".gitignore") -Value "ignored/`n"
  Write-Utf8File -Path (Join-Path $Root ".gitattributes") -Value "*.ps1 text eol=lf`n"
  Write-Utf8File -Path (Join-Path $Root ".codex\hooks.json") -Value "{}"
  Write-Utf8File -Path (Join-Path $Root ".claude\settings.json") -Value "{}"
  Write-Utf8File -Path (Join-Path $Root ".czxt-template-root") -Value "template`n"
  if ($WithAppFile) {
    Write-Utf8File -Path (Join-Path $Root "business\src\app.js") -Value "console.log('tracked');`n"
  }

  if ($WithGit) {
    & git -C $Root init -q | Out-Null
    & git -C $Root -c core.autocrlf=false add . | Out-Null
    & git -C $Root -c user.name=pm-tracking-test -c user.email=pm-tracking@example.invalid commit -m init -q | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git commit failed in $Root" }
  }

  return $Root
}

function Invoke-Checker {
  param([string]$Root, [string]$Script = $script:checker)

  $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Root $Root -Threshold 1 2>&1 | Out-String
  return [pscustomobject]@{
    ExitCode = $LASTEXITCODE
    Output = $output
  }
}

function Invoke-CheckerInCp936 {
  param([string]$Root, [string]$Script = $script:checker)

  $wrapper = Join-Path (New-TempRoot) "invoke-cp936.ps1"
  Write-Utf8File -Path $wrapper -Value @"
`$oldOut = [Console]::OutputEncoding
`$oldIn = [Console]::InputEncoding
try {
  [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(936)
  [Console]::InputEncoding = [System.Text.Encoding]::GetEncoding(936)
  & '$Script' -Root '$Root' -Threshold 1
  `$code = `$LASTEXITCODE
} finally {
  [Console]::OutputEncoding = `$oldOut
  [Console]::InputEncoding = `$oldIn
}
exit `$code
"@
  $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $wrapper 2>&1 | Out-String
  return [pscustomobject]@{
    ExitCode = $LASTEXITCODE
    Output = $output
  }
}

function Assert-ExitCode {
  param([string]$Name, [int]$Expected, [scriptblock]$Arrange)

  try {
    $root = & $Arrange
    $result = Invoke-Checker -Root $root
    if ($result.ExitCode -ne $Expected) {
      $script:failures.Add("$Name expected exit $Expected, got $($result.ExitCode)`n$($result.Output)")
    } else {
      Write-Host "PASS $Name"
    }
  } catch {
    $script:failures.Add("$Name threw: $($_.Exception.Message)")
  }
}

function Assert-P4fExitCode {
  param([string]$Name, [int]$Expected, [scriptblock]$Arrange)

  try {
    $root = & $Arrange
    $result = Invoke-Checker -Root $root -Script $script:p4fChecker
    if ($result.ExitCode -ne $Expected) {
      $script:failures.Add("$Name expected p4f exit $Expected, got $($result.ExitCode)`n$($result.Output)")
    } else {
      Write-Host "PASS $Name"
    }
  } catch {
    $script:failures.Add("$Name threw: $($_.Exception.Message)")
  }
}

function Assert-Cp936ExitCode {
  param([string]$Name, [int]$Expected, [scriptblock]$Arrange)

  try {
    $root = & $Arrange
    $result = Invoke-CheckerInCp936 -Root $root
    if ($result.ExitCode -ne $Expected) {
      $script:failures.Add("$Name expected CP936 exit $Expected, got $($result.ExitCode)`n$($result.Output)")
    } else {
      Write-Host "PASS $Name"
    }
  } catch {
    $script:failures.Add("$Name threw: $($_.Exception.Message)")
  }
}
