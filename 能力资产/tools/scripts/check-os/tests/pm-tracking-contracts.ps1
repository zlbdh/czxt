# PM tracking contracts for 能力资产/tools/scripts/check-pm-tracking.ps1

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$script:repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..\..")
$script:checker = Join-Path $script:repoRoot "能力资产\tools\scripts\check-pm-tracking.ps1"
$script:p4fChecker = Join-Path $script:repoRoot "能力资产\tools\scripts\check-os\p4f-pm-tracking.ps1"
$script:tempRoots = New-Object System.Collections.Generic.List[string]
$script:failures = New-Object System.Collections.Generic.List[string]
. (Join-Path $PSScriptRoot "pm-tracking-contract-support.ps1")

try {
  Assert-ExitCode "clean independent Git ignores committed file mtime after old PM track" 5 {
    $root = New-CzxtFixture -WithGit
    Set-TreeLastWriteTime -Root $root -Time (Get-Date)
    return $root
  }

  Assert-ExitCode "fresh clean independent Git exits success directly" 0 {
    return New-CzxtFixture -WithGit -TrackTimestamp ((Get-Date).ToString("yyyy-MM-dd HH:mm"))
  }

  Assert-P4fExitCode "p4f wrapper maps stale clean independent Git to success" 0 {
    $root = New-CzxtFixture -WithGit
    Set-TreeLastWriteTime -Root $root -Time (Get-Date)
    return $root
  }

  Assert-ExitCode "clean Git worktree root ignores committed file mtime after old PM track" 5 {
    $base = New-CzxtFixture -WithGit
    $worktreeParent = New-TempRoot
    $worktree = Join-Path $worktreeParent "真实 worktree"
    & git -C $base worktree add --detach -q $worktree HEAD | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git worktree add failed in $base" }
    Set-TreeLastWriteTime -Root $worktree -Time (Get-Date)
    return $worktree
  }

  Assert-ExitCode "untracked framework file in independent Git requires PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root "操作系统\untracked.md") -Value "new`n"
    return $root
  }

  Assert-ExitCode "untracked framework path with Chinese spaces in independent Git requires PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root "操作系统\中文 空格.md") -Value "new`n"
    return $root
  }

  Assert-Cp936ExitCode "CP936 parent still detects Chinese space framework path" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root "操作系统\中文 空格.md") -Value "new`n"
    return $root
  }

  Assert-ExitCode "modified framework file in independent Git requires PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root "能力资产\tracked.md") -Value "modified`n"
    return $root
  }

  Assert-ExitCode "staged framework file in independent Git requires PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root "Docs\staged.md") -Value "staged`n"
    & git -C $root -c core.autocrlf=false add "Docs/staged.md" | Out-Null
    return $root
  }

  Assert-ExitCode "deleted framework file in independent Git requires PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Remove-Item -LiteralPath (Join-Path $root "Docs\tracked.md")
    return $root
  }

  Assert-ExitCode "renamed framework file in independent Git requires PM track" 10 {
    $root = New-CzxtFixture -WithGit
    & git -C $root mv "Docs/tracked.md" "Docs/renamed.md" | Out-Null
    return $root
  }

  Assert-ExitCode "installer script changes in independent Git require PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root "实例化项目.ps1") -Value "# changed installer`n"
    return $root
  }

  Assert-ExitCode "gitignore changes in independent Git require PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root ".gitignore") -Value "ignored/`nnew-ignore/`n"
    return $root
  }

  Assert-ExitCode "gitattributes changes in independent Git require PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root ".gitattributes") -Value "*.ps1 text eol=lf`n*.md text eol=lf`n"
    return $root
  }

  Assert-ExitCode "codex hook config changes in independent Git require PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root ".codex\hooks.json") -Value "{`"changed`":true}"
    return $root
  }

  Assert-ExitCode "claude hook config changes in independent Git require PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root ".claude\settings.json") -Value "{`"changed`":true}"
    return $root
  }

  Assert-ExitCode "template root marker changes in independent Git require PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root ".czxt-template-root") -Value "changed`n"
    return $root
  }

  Assert-ExitCode "untracked project root marker in independent Git requires PM track" 10 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root ".czxt-project-root") -Value "project`n"
    return $root
  }

  Assert-ExitCode "business-only Git changes do not require PM track" 5 {
    $root = New-CzxtFixture -WithGit -WithAppFile
    Write-Utf8File -Path (Join-Path $root "business\src\app.js") -Value "console.log('business');`n"
    return $root
  }

  Assert-ExitCode "ignored-only Git changes do not require PM track" 5 {
    $root = New-CzxtFixture -WithGit
    Write-Utf8File -Path (Join-Path $root "ignored\scratch.md") -Value "ignored`n"
    return $root
  }

  Assert-ExitCode "non-Git project keeps mtime fallback for framework changes" 10 {
    $root = New-CzxtFixture
    Set-TreeLastWriteTime -Root $root -Time ([DateTime]"2000-01-01T00:00:00")
    Write-Utf8File -Path (Join-Path $root "操作系统\mtime.md") -Value "mtime`n"
    return $root
  }

  Assert-ExitCode "project inside outer Git but not an independent root keeps mtime fallback" 10 {
    $outer = New-TempRoot
    $root = Join-Path $outer "中文 空格 项目"
    [void][System.IO.Directory]::CreateDirectory($root)
    New-CzxtFixture -Root $root | Out-Null
    & git -C $outer init -q | Out-Null
    & git -C $outer -c core.autocrlf=false add . | Out-Null
    & git -C $outer -c user.name=pm-tracking-test -c user.email=pm-tracking@example.invalid commit -m outer -q | Out-Null
    Set-TreeLastWriteTime -Root $root -Time (Get-Date)
    return $root
  }

  Assert-ExitCode "nested independent Git root does not inherit outer Git mtime fallback" 5 {
    $outer = New-TempRoot
    & git -C $outer init -q | Out-Null
    $root = Join-Path $outer "中文 空格 子仓库"
    [void][System.IO.Directory]::CreateDirectory($root)
    New-CzxtFixture -Root $root -WithGit | Out-Null
    Set-TreeLastWriteTime -Root $root -Time (Get-Date)
    return $root
  }

  Assert-ExitCode "broken Git metadata is not treated as clean" 10 {
    $root = New-CzxtFixture
    Set-TreeLastWriteTime -Root $root -Time ([DateTime]"2000-01-01T00:00:00")
    Write-Utf8File -Path (Join-Path $root ".git") -Value "gitdir: Z:\definitely-missing-czxt-git-dir`n"
    return $root
  }

  Assert-ExitCode "broken Git metadata fails even when PM track is fresh" 10 {
    $root = New-CzxtFixture
    $freshState = @"
# 状态

## PM 切换轨迹

| 时间 | 从角色 | 到角色 | 任务 | decision-checkpoint 跑过？ | 完成回流 |
|---|---|---|---|---|---|
| $((Get-Date).ToString("yyyy-MM-dd HH:mm")) | 项目 PM「咪咪」 | 操作系统 PM「框架管家」 | 新轨迹 | ✅ | ✅ |
"@
    Write-Utf8File -Path (Join-Path $root "状态.md") -Value $freshState
    Set-TreeLastWriteTime -Root $root -Time ([DateTime]"2000-01-01T00:00:00")
    Write-Utf8File -Path (Join-Path $root ".git") -Value "gitdir: Z:\definitely-missing-czxt-git-dir`n"
    return $root
  }
} finally {
  foreach ($root in $tempRoots) {
    if (Test-Path -LiteralPath $root) {
      Assert-SafeTempRoot -Path $root
      Remove-Item -LiteralPath $root -Recurse -Force
    }
  }
}

if ($failures.Count -gt 0) {
  Write-Host ""
  Write-Host "FAIL pm-tracking contracts: $($failures.Count)" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host ""
    Write-Host $failure -ForegroundColor Red
  }
  exit 1
}

Write-Host ""
Write-Host "PASS pm-tracking contracts"
exit 0
