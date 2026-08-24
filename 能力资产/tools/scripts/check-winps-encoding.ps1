[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,

    [switch]$ListOnly
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

function Write-Failure {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
}

function Get-WorkspaceRelativePath {
    param([string]$RootPath, [string]$FullPath)
    $rootPrefix = $RootPath.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $canonical = [IO.Path]::GetFullPath($FullPath)
    if (-not $canonical.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw ("path escapes Root: {0}" -f $canonical)
    }
    return $canonical.Substring($rootPrefix.Length).Replace('\', '/')
}

function Test-ExcludedPath {
    param([string]$RelativePath)
    $path = '/' + $RelativePath.TrimStart('/') + '/'
    if ($path.StartsWith('/.git/', [StringComparison]::OrdinalIgnoreCase)) { return $true }
    if ($path.StartsWith('/项目区/本地实例/', [StringComparison]::OrdinalIgnoreCase)) { return $true }
    if ($path.StartsWith('/借鉴区/', [StringComparison]::OrdinalIgnoreCase) -and
        $path.IndexOf('/快照/', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    return $false
}

function Get-TargetScripts {
    param([string]$RootPath)

    $paths = New-Object 'Collections.Generic.Dictionary[string,string]' ([StringComparer]::OrdinalIgnoreCase)
    $errors = New-Object 'Collections.Generic.List[string]'
    $rootScript = Join-Path $RootPath '实例化项目.ps1'
    if (Test-Path -LiteralPath $rootScript -PathType Leaf) {
        try {
            $relative = Get-WorkspaceRelativePath -RootPath $RootPath -FullPath $rootScript
            if (-not (Test-ExcludedPath $relative)) { $paths[$relative] = $rootScript }
        }
        catch { $errors.Add(("实例化项目.ps1: 发现失败: {0}" -f $_.Exception.Message)) }
    }

    foreach ($scope in @('.claude', '.codex', '能力资产')) {
        $scopePath = Join-Path $RootPath $scope
        if (-not (Test-Path -LiteralPath $scopePath -PathType Container)) { continue }
        try {
            $files = @(Get-ChildItem -LiteralPath $scopePath -Filter '*.ps1' -File -Recurse -ErrorAction Stop)
            foreach ($file in $files) {
                $relative = Get-WorkspaceRelativePath -RootPath $RootPath -FullPath $file.FullName
                if (-not (Test-ExcludedPath $relative)) { $paths[$relative] = $file.FullName }
            }
        }
        catch { $errors.Add(("{0}: 发现失败: {1}" -f $scope, $_.Exception.Message)) }
    }

    [string[]]$relativePaths = @($paths.Keys)
    [Array]::Sort($relativePaths, [StringComparer]::OrdinalIgnoreCase)
    $files = foreach ($relative in $relativePaths) {
        [pscustomobject]@{ RelativePath = $relative; FullPath = $paths[$relative] }
    }
    return [pscustomobject]@{ Files = @($files); Errors = @($errors) }
}

function Test-Utf8Bom {
    param([string]$Path)
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        return ($stream.ReadByte() -eq 0xEF -and
            $stream.ReadByte() -eq 0xBB -and
            $stream.ReadByte() -eq 0xBF)
    }
    finally { $stream.Dispose() }
}

try {
    $rootPath = [IO.Path]::GetFullPath($Root)
}
catch {
    Write-Failure ("[FAIL] Root 无效: {0}" -f $_.Exception.Message)
    exit 10
}

if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
    Write-Failure ("[FAIL] Root 不存在或不是目录: {0}" -f $rootPath)
    exit 10
}

try {
    $discovery = Get-TargetScripts -RootPath $rootPath
}
catch {
    Write-Failure ("[FAIL] 文件发现失败: {0}" -f $_.Exception.Message)
    exit 10
}

if ($discovery.Errors.Count -gt 0) {
    foreach ($message in $discovery.Errors) { Write-Failure ("[FAIL] {0}" -f $message) }
    exit 10
}

if ($ListOnly) {
    foreach ($file in $discovery.Files) { Write-Output $file.RelativePath }
    exit 0
}

$failureCount = 0
foreach ($file in $discovery.Files) {
    try {
        if (-not (Test-Utf8Bom -Path $file.FullPath)) {
            Write-Failure ("[FAIL] {0}: 缺少 UTF-8 BOM (EF BB BF)" -f $file.RelativePath)
            $failureCount++
            continue
        }
    }
    catch {
        Write-Failure ("[FAIL] {0}: 读取失败: {1}" -f $file.RelativePath, $_.Exception.Message)
        $failureCount++
        continue
    }

    try {
        $tokens = $null
        $parseErrors = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            $file.FullPath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        foreach ($parseError in @($parseErrors)) {
            $line = $parseError.Extent.StartLineNumber
            $column = $parseError.Extent.StartColumnNumber
            Write-Failure ("[FAIL] {0}: 语法错误 L{1}:C{2}: {3}" -f
                $file.RelativePath, $line, $column, $parseError.Message)
            $failureCount++
        }
    }
    catch {
        Write-Failure ("[FAIL] {0}: 读取失败: {1}" -f $file.RelativePath, $_.Exception.Message)
        $failureCount++
    }
}

if ($failureCount -gt 0) { exit 10 }
Write-Output ("WINPS_ENCODING_OK count={0}" -f $discovery.Files.Count)
exit 0
