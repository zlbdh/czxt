# PM tracking Git-aware framework change detection.

$ErrorActionPreference = "Stop"

function Get-PmTrackingFrameworkDirs {
  return @(".codex", ".claude", "操作系统", "能力资产", "PM工作区", "确认改动", "交接区", "Docs", "项目配置", "借鉴区")
}

function Get-PmTrackingRootFrameworkFiles {
  return @(
    "AGENTS.md",
    "README.md",
    "TASKS.md",
    "状态.md",
    "实例化项目.ps1",
    ".gitignore",
    ".gitattributes",
    ".czxt-template-root",
    ".czxt-project-root"
  )
}

function ConvertTo-PmTrackingFullPath {
  param([string]$Path)

  return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function ConvertTo-PmTrackingRelativePath {
  param([string]$ProjectRoot, [string]$Path)

  $root = ConvertTo-PmTrackingFullPath -Path $ProjectRoot
  $full = ConvertTo-PmTrackingFullPath -Path $Path
  if ($full.Equals($root, [System.StringComparison]::OrdinalIgnoreCase)) {
    return ""
  }
  $prefix = $root + [System.IO.Path]::DirectorySeparatorChar
  if ($full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $full.Substring($prefix.Length) -replace '/', '\'
  }
  return $Path
}

function ConvertFrom-PmTrackingGitPath {
  param([string]$Path)

  $value = $Path.Trim()
  if ($value.Length -ge 2 -and $value[0] -eq '"' -and $value[$value.Length - 1] -eq '"') {
    $value = $value.Substring(1, $value.Length - 2)
    $value = $value -replace '\\n', "`n"
    $value = $value -replace '\\t', "`t"
    $value = $value -replace '\\"', '"'
    $value = $value -replace '\\\\', '\'
  }
  return ($value -replace '/', '\').TrimStart('\')
}

function Test-PmTrackingFrameworkRelativePath {
  param([string]$Path)

  $relative = ($Path -replace '/', '\').TrimStart('\')
  foreach ($file in (Get-PmTrackingRootFrameworkFiles)) {
    if ($relative.Equals($file, [System.StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
  }
  foreach ($dir in (Get-PmTrackingFrameworkDirs)) {
    if ($relative.Equals($dir, [System.StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
    if ($relative.StartsWith($dir + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
  }
  return $false
}

function Get-PmTrackingPorcelainPaths {
  param([string]$Line)

  if ([string]::IsNullOrWhiteSpace($Line) -or $Line.Length -lt 4) {
    return @()
  }

  $pathPart = $Line.Substring(3)
  if ($pathPart -like "* -> *") {
    return @($pathPart -split ' -> ', 2 | ForEach-Object { ConvertFrom-PmTrackingGitPath -Path $_ })
  }

  return @(ConvertFrom-PmTrackingGitPath -Path $pathPart)
}

function Test-PmTrackingHasOwnGitMarker {
  param([string]$ProjectRoot)

  return (Test-Path -LiteralPath (Join-Path $ProjectRoot ".git"))
}

function Invoke-PmTrackingGit {
  param([string[]]$Arguments)

  $previousErrorActionPreference = $ErrorActionPreference
  $previousOutputEncoding = [Console]::OutputEncoding
  $previousInputEncoding = [Console]::InputEncoding
  $ErrorActionPreference = "Continue"
  try {
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [Console]::OutputEncoding = $utf8NoBom
    [Console]::InputEncoding = $utf8NoBom
    $output = @(& git @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
  } finally {
    [Console]::OutputEncoding = $previousOutputEncoding
    [Console]::InputEncoding = $previousInputEncoding
    $ErrorActionPreference = $previousErrorActionPreference
  }

  return [pscustomobject]@{
    ExitCode = $exitCode
    Output = @($output)
  }
}

function Get-PmTrackingMTimeFrameworkChanges {
  param([string]$ProjectRoot, [DateTime]$TrackWindowEnd)

  $paths = @()
  foreach ($dir in (Get-PmTrackingFrameworkDirs)) {
    $path = Join-Path $ProjectRoot $dir
    if (Test-Path -LiteralPath $path) {
      $paths += @(Get-ChildItem -LiteralPath $path -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt $TrackWindowEnd } |
        ForEach-Object { ConvertTo-PmTrackingRelativePath -ProjectRoot $ProjectRoot -Path $_.FullName })
    }
  }

  foreach ($name in (Get-PmTrackingRootFrameworkFiles)) {
    $path = Join-Path $ProjectRoot $name
    if ((Test-Path -LiteralPath $path) -and ((Get-Item -LiteralPath $path).LastWriteTime -gt $TrackWindowEnd)) {
      $paths += $name
    }
  }

  return @($paths | Sort-Object -Unique)
}

function Get-PmTrackingGitFrameworkChanges {
  param([string]$ProjectRoot)

  $status = Invoke-PmTrackingGit -Arguments @("-C", $ProjectRoot, "-c", "core.quotePath=false", "status", "--porcelain=v1", "--untracked-files=all", "--ignored=no")
  if ($status.ExitCode -ne 0) {
    return [pscustomobject]@{
      StatusAvailable = $false
      ChangedPaths = @("<Git 状态不可读：$($status.Output -join ' ')>")
    }
  }

  $changed = @()
  foreach ($line in @($status.Output)) {
    foreach ($path in (Get-PmTrackingPorcelainPaths -Line ([string]$line))) {
      if (Test-PmTrackingFrameworkRelativePath -Path $path) {
        $changed += $path
      }
    }
  }

  return [pscustomobject]@{
    StatusAvailable = $true
    ChangedPaths = @($changed | Sort-Object -Unique)
  }
}

function Get-PmTrackingFrameworkChangeProbe {
  param([string]$ProjectRoot, [DateTime]$TrackWindowEnd)

  $root = ConvertTo-PmTrackingFullPath -Path $ProjectRoot
  $ownGitMarker = Test-PmTrackingHasOwnGitMarker -ProjectRoot $root
  $gitCommand = Get-Command git -ErrorAction SilentlyContinue

  if ($null -ne $gitCommand) {
    $topLevelResult = Invoke-PmTrackingGit -Arguments @("-C", $root, "rev-parse", "--show-toplevel")
    if ($topLevelResult.ExitCode -eq 0 -and $topLevelResult.Output.Count -gt 0) {
      $topLevel = ConvertTo-PmTrackingFullPath -Path ([string]$topLevelResult.Output[0])
      if ($topLevel.Equals($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        $gitProbe = Get-PmTrackingGitFrameworkChanges -ProjectRoot $root
        return [pscustomobject]@{
          Method = "git"
          StatusAvailable = $gitProbe.StatusAvailable
          FrameworkChanged = (-not $gitProbe.StatusAvailable) -or (@($gitProbe.ChangedPaths).Count -gt 0)
          ChangedPaths = @($gitProbe.ChangedPaths)
        }
      }
    } elseif ($ownGitMarker) {
      return [pscustomobject]@{
        Method = "git-error"
        StatusAvailable = $false
        FrameworkChanged = $true
        ChangedPaths = @("<Git 根不可读：$($topLevelResult.Output -join ' ')>")
      }
    }
  } elseif ($ownGitMarker) {
    return [pscustomobject]@{
      Method = "git-error"
      StatusAvailable = $false
      FrameworkChanged = $true
      ChangedPaths = @("<Git 命令不可用，无法确认独立 Git 根是否 clean>")
    }
  }

  $mtimePaths = Get-PmTrackingMTimeFrameworkChanges -ProjectRoot $root -TrackWindowEnd $TrackWindowEnd
  return [pscustomobject]@{
    Method = "mtime"
    StatusAvailable = $true
    FrameworkChanged = @($mtimePaths).Count -gt 0
    ChangedPaths = @($mtimePaths)
  }
}
