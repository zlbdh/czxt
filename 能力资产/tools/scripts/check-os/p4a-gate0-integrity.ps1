$ErrorActionPreference = "Stop"

function Test-CzxtP4aRootMode {
  param([string]$RootMode, [object]$Failures)
  if ($RootMode -notin @('template', 'project')) {
    $Failures.Add("🔴 根模式非法：$RootMode（要求 template-only 或 project-only marker）")
  }
}

function Test-CzxtWinPsEncodingGate {
  param([string]$Root, [object]$Failures, [object]$Passes)
  $gateRel = "能力资产/tools/scripts/check-winps-encoding.ps1"
  $gatePath = Join-Path $Root $gateRel
  if (-not (Test-Path -LiteralPath $gatePath -PathType Leaf)) {
    $Failures.Add("🔴 缺 Windows PowerShell 编码门禁：$gateRel")
    return
  }
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $gatePath -Root $Root
  $gateExit = $LASTEXITCODE
  if ($gateExit -ne 0) {
    $Failures.Add("🔴 Windows PowerShell 编码门禁失败 exit $gateExit")
  } else {
    $Passes.Add("Windows PowerShell 编码门禁")
  }
}

function Test-CzxtInstallerCopyItems {
  param(
    [string]$Root,
    [string[]]$ExpectedItems,
    [object]$Failures,
    [object]$Passes
  )
  $installerRel = "实例化项目.ps1"
  $installerPath = Join-Path $Root $installerRel
  if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    $Failures.Add("🔴 缺实例化脚本：$installerRel")
    return
  }
  $scriptText = Get-Content -LiteralPath $installerPath -Raw -Encoding UTF8
  $markerHelperPath = Join-Path $Root `
    '能力资产\tools\scripts\installer-output-manifest.ps1'
  $markerText = $scriptText
  if (Test-Path -LiteralPath $markerHelperPath -PathType Leaf) {
    $markerText += "`n" + (Get-Content -LiteralPath $markerHelperPath -Raw -Encoding UTF8)
  }
  $match = [regex]::Match($scriptText, '\$copyItems\s*=\s*@\((?<body>[\s\S]*?)\)')
  if (-not $match.Success) {
    $Failures.Add("🔴 实例化脚本未找到 `$copyItems 清单")
    return
  }
  $items = @([regex]::Matches($match.Groups["body"].Value, '"([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value })
  foreach ($item in $ExpectedItems) {
    if ($items -notcontains $item) {
      $Failures.Add("🔴 实例化脚本 `$copyItems 缺少：$item")
    } else {
      $Passes.Add("实例化脚本复制清单：$item")
    }
  }
  Test-CzxtInstallerGate0Contract -ScriptText $scriptText -MarkerText $markerText `
    -CopyItems $items `
    -Failures $Failures -Passes $Passes
}

function Test-CzxtInstallerGate0Contract {
  param(
    [string]$ScriptText,
    [string]$MarkerText,
    [string[]]$CopyItems,
    [object]$Failures,
    [object]$Passes
  )
  if ($CopyItems -contains ".czxt-template-root") {
    $Failures.Add("🔴 实例化脚本不得复制 .czxt-template-root")
  } else {
    $Passes.Add("实例化脚本不复制模板 marker")
  }

  $hasProjectMarker = (
    ($MarkerText -match [regex]::Escape('.czxt-project-root')) -and
    ($MarkerText -match 'czxt-root-mode=project') -and
    ($MarkerText -match 'schema=1')
  )
  if ($hasProjectMarker) {
    $Passes.Add("实例化脚本生成 project marker schema=1")
  } else {
    $Failures.Add("🔴 实例化脚本未生成 project marker schema=1")
  }

  $preservesPs1Bom = (
    ($ScriptText -match '\$Utf8Bom\s*=\s*New-Object\s+System\.Text\.UTF8Encoding\(\$true\)') -and
    ($ScriptText -match '\$file\.Extension\.Equals\("\.ps1"') -and
    ($ScriptText -match 'Write-CzxtInstallerTextFile[\s\S]{0,400}-TargetPath\s+\$file\.FullName[\s\S]{0,400}-Encoding\s+\$writeEncoding')
  )
  if ($preservesPs1Bom) {
    $Passes.Add("实例化脚本按 .ps1 选择 UTF-8 BOM 写回")
  } else {
    $Failures.Add("🔴 实例化脚本未按 .ps1 选择 UTF-8 BOM 写回")
  }
}
