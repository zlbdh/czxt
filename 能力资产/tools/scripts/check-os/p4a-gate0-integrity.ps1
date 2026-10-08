$ErrorActionPreference = "Stop"

function Test-CzxtP4aRootMode {
  param([string]$RootMode, [object]$Failures)
  if ($RootMode -notin @('template', 'project')) {
    $Failures.Add("🔴 Invalid root mode: $RootMode (requires a template-only or project-only marker)")
  }
}

function Test-CzxtWinPsEncodingGate {
  param([string]$Root, [object]$Failures, [object]$Passes)
  $gateRel = "能力资产/tools/scripts/check-winps-encoding.ps1"
  $gatePath = Join-Path $Root $gateRel
  if (-not (Test-Path -LiteralPath $gatePath -PathType Leaf)) {
    $Failures.Add("🔴 Windows PowerShell encoding gate is missing: $gateRel")
    return
  }
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $gatePath -Root $Root
  $gateExit = $LASTEXITCODE
  if ($gateExit -ne 0) {
    $Failures.Add("🔴 Windows PowerShell encoding gate failed with exit $gateExit")
  } else {
    $Passes.Add("Windows PowerShell encoding gate")
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
    $Failures.Add("🔴 Instantiation script is missing: $installerRel")
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
    $Failures.Add("🔴 Instantiation script lacks the `$copyItems list")
    return
  }
  $items = @([regex]::Matches($match.Groups["body"].Value, '"([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value })
  foreach ($item in $ExpectedItems) {
    if ($items -notcontains $item) {
      $Failures.Add("🔴 Instantiation script `$copyItems is missing: $item")
    } else {
      $Passes.Add("Instantiation script copy list: $item")
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
    $Failures.Add("🔴 Instantiation script must not copy .czxt-template-root")
  } else {
    $Passes.Add("Instantiation script excludes the template marker")
  }

  $hasProjectMarker = (
    ($MarkerText -match [regex]::Escape('.czxt-project-root')) -and
    ($MarkerText -match 'czxt-root-mode=project') -and
    ($MarkerText -match 'schema=1')
  )
  if ($hasProjectMarker) {
    $Passes.Add("Instantiation script creates project marker schema=1")
  } else {
    $Failures.Add("🔴 Instantiation script does not create project marker schema=1")
  }

  $preservesPs1Bom = (
    ($ScriptText -match '\$Utf8Bom\s*=\s*New-Object\s+System\.Text\.UTF8Encoding\(\$true\)') -and
    ($ScriptText -match '\$file\.Extension\.Equals\("\.ps1"') -and
    ($ScriptText -match 'Write-CzxtInstallerTextFile[\s\S]{0,400}-TargetPath\s+\$file\.FullName[\s\S]{0,400}-Encoding\s+\$writeEncoding')
  )
  if ($preservesPs1Bom) {
    $Passes.Add("Instantiation script writes .ps1 files with UTF-8 BOM encoding")
  } else {
    $Failures.Add("🔴 Instantiation script does not write .ps1 files with UTF-8 BOM encoding")
  }
}
