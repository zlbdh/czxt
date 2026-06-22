param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "framework-scope.ps1")

if (-not (Test-IsTemplateRoot -Root $Root)) {
  Write-Host "  ℹ️ 非模板根模式：跳过模板纯净度守卫"
  exit 0
}

$failures = New-Object System.Collections.Generic.List[string]

function Get-RelativePathCompat {
  param([string]$BasePath, [string]$FullPath)

  $base = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\'
  $full = [System.IO.Path]::GetFullPath($FullPath)
  if ($full.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $full.Substring($base.Length)
  }
  return $full
}

$configDir = Join-Path $Root "项目配置"
if (Test-Path -LiteralPath $configDir -PathType Container) {
  foreach ($file in Get-ChildItem -LiteralPath $configDir -Filter "*.project.json" -File) {
    if ($file.Name -ne "_模板.project.json") {
      $rel = Get-RelativePathCompat -BasePath $Root -FullPath $file.FullName
      $failures.Add("$rel 不应进入模板仓库；具体项目卡请放本机项目目录或 项目区/本地实例/")
    }
  }
}

$terms = @(
  ("小小" + "的我"),
  ("x" + "xdw"),
  ("com.zlbdh." + "mimi"),
  ("轻薄" + "肌"),
  ("小" + "眯"),
  ("知乎" + "首篇"),
  ("5-" + "Tab"),
  ("品牌" + "尽调"),
  ("A" + "阶段发布"),
  ("W1-" + "L1"),
  ("xiaoxiao" + "dewo")
)
$extensions = @(".md", ".ps1", ".json", ".txt", ".html", ".js", ".ts", ".jsx", ".tsx", ".yml", ".yaml")
$skipDirs = @("\.git\", "\本地实例\")

$files = Get-ChildItem -LiteralPath $Root -Recurse -Force -File | Where-Object {
  $path = $_.FullName
  foreach ($skip in $skipDirs) {
    if ($path -like "*$skip*") { return $false }
  }
  $extensions -contains $_.Extension.ToLowerInvariant()
}

foreach ($file in $files) {
  $rel = Get-RelativePathCompat -BasePath $Root -FullPath $file.FullName
  foreach ($term in $terms) {
    if ($rel.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
      $failures.Add("$rel 路径名发现来源项目残留：$term")
    }
  }

  try {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  } catch {
    continue
  }
  foreach ($term in $terms) {
    $idx = $text.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase)
    if ($idx -lt 0) { continue }
    $line = ($text.Substring(0, $idx) -split "`n").Count
    $failures.Add("$rel`:L$line 发现来源项目残留：$term")
  }
}

if ($failures.Count -gt 0) {
  Write-Host "  🔴 模板纯净度失败：$($failures.Count) 处" -ForegroundColor Red
  foreach ($failure in $failures) { Write-Host "    - $failure" -ForegroundColor Red }
  exit 10
}

Write-Host "  ✅ 模板纯净度通过：无具体项目卡 / 无已知来源项目残留" -ForegroundColor Green
exit 0
