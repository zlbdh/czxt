[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')

function New-P4tIsolationCase {
  param([string]$Name, [string]$RelativePath, [string]$Content)
  $root = New-ProjectSkeleton ('isolation-' + $Name)
  Write-P4tUtf8 (Join-Path $root ('app\' + $RelativePath)) $Content
  return [pscustomobject]@{ Name = $Name; Root = $root; Mode = 'project'; Exit = 10 }
}

function New-P4tIsolationOversizedTextCase {
  $root = New-ProjectSkeleton 'isolation-oversized-text'
  $path = Join-Path $root 'app\oversized.txt'
  $bytes = [Text.Encoding]::ASCII.GetBytes(('a' * (8MB + 1)))
  [IO.File]::WriteAllBytes($path, $bytes)
  return [pscustomobject]@{ Name = 'oversized-text'; Root = $root; Mode = 'project'; Exit = 10 }
}

function New-P4tIsolationOversizedBoundaryCase {
  $root = New-ProjectSkeleton 'isolation-oversized-boundary'
  $path = Join-Path $root 'app\oversized-boundary.txt'
  $bytes = [Text.Encoding]::ASCII.GetBytes(('a' * (8MB + 1)))
  $marker = [Text.Encoding]::UTF8.GetBytes('借')
  [Array]::Copy($marker, 0, $bytes, 65535, $marker.Length)
  [IO.File]::WriteAllBytes($path, $bytes)
  return [pscustomobject]@{ Name = 'oversized-utf8-boundary'; Root = $root; Mode = 'project'; Exit = 10 }
}

function New-P4tIsolationBinaryCase {
  $root = New-ProjectSkeleton 'isolation-binary-positive'
  $path = Join-Path $root 'app\payload.blob'
  $pathBytes = [Text.Encoding]::UTF8.GetBytes("../借鉴区/来源/example`n")
  $bytes = New-Object byte[] ($pathBytes.Length + 2)
  $bytes[0] = 0xFF
  $bytes[1] = 0x00
  [Array]::Copy($pathBytes, 0, $bytes, 2, $pathBytes.Length)
  [IO.File]::WriteAllBytes($path, $bytes)
  return [pscustomobject]@{ Name = 'binary-is-not-text'; Root = $root; Mode = 'project'; Exit = 0 }
}

function New-P4tIsolationUtf16Case {
  param([string]$Name, [bool]$BigEndian)
  $root = New-ProjectSkeleton ('isolation-' + $Name)
  $path = Join-Path $root 'app\index.html'
  $encoding = New-Object Text.UnicodeEncoding($BigEndian, $true, $true)
  [IO.File]::WriteAllText($path, '<script src="../借鉴区/来源/example/app.js"></script>', $encoding)
  return [pscustomobject]@{ Name = $Name; Root = $root; Mode = 'project'; Exit = 10 }
}

Initialize-P4tTestFixture
try {
  $cases = @(
    (New-P4tIsolationCase 'import' 'import.js' "import x from '../借鉴区/模板/借鉴卡.md';`n"),
    (New-P4tIsolationCase 'require' 'require.js' "const x = require('../借鉴区/模板/借鉴卡.md');`n"),
    (New-P4tIsolationCase 'file-dependency' 'package.json' '{"dependencies":{"x":"file:../借鉴区/来源/example"}}'),
    (New-P4tIsolationCase 'workspace-config' 'pnpm-workspace.yaml' "packages:`n  - '../借鉴区/来源/*'`n"),
    (New-P4tIsolationCase 'build-config' 'vite.config.js' "alias: { borrowed: '../借鉴区/事项' }`n"),
    (New-P4tIsolationCase 'script-call' 'build.ps1' "& '..\借鉴区\来源\example\run.ps1'`n"),
    (New-P4tIsolationCase 'runtime-read' 'runtime.js' "readFileSync('../借鉴区/来源/example/data.bin');`n"),
    (New-P4tIsolationCase 'dist-runtime' 'dist/runtime.js' "readFileSync('../../借鉴区/来源/example/data.bin');`n"),
    (New-P4tIsolationCase 'build-runtime' 'build/runtime.js' "readFileSync('../../借鉴区/来源/example/data.bin');`n"),
    (New-P4tIsolationCase 'next-runtime' '.next/server/runtime.js' "readFileSync('../../../借鉴区/来源/example/data.bin');`n"),
    (New-P4tIsolationCase 'target-runtime' 'target/runtime.conf' 'BORROWED_PATH=../../借鉴区/来源/example'),
    (New-P4tIsolationCase 'out-runtime' 'out/runtime.js' "readFileSync('../../借鉴区/来源/example/data.bin');`n"),
    (New-P4tIsolationCase 'html-runtime' 'index.html' '<script src="../借鉴区/来源/example/app.js"></script>'),
    (New-P4tIsolationCase 'dotenv-config' '.env' 'BORROWED_PATH=../借鉴区/来源/example'),
    (New-P4tIsolationCase 'conf-config' 'runtime.conf' 'include=../借鉴区/来源/example'),
    (New-P4tIsolationCase 'extensionless-runtime' 'launcher' 'source ../借鉴区/来源/example/run.sh'),
    (New-P4tIsolationCase 'project-relative-line-start' 'relative-line.txt' '借鉴区/来源/example/run.sh'),
    (New-P4tIsolationCase 'project-relative-whitespace' 'relative-space.txt' 'source 借鉴区/来源/example/run.sh'),
    (New-P4tIsolationCase 'project-relative-equals' 'relative-equals.env' 'BORROWED_PATH=借鉴区/来源/example'),
    (New-P4tIsolationCase 'project-relative-colon' 'relative-colon.conf' 'source:借鉴区/来源/example'),
    (New-P4tIsolationCase 'project-relative-paren' 'relative-paren.js' 'open(借鉴区/来源/example/data.bin)'),
    (New-P4tIsolationCase 'project-relative-bracket' 'relative-bracket.js' 'paths=[借鉴区/来源/example]'),
    (New-P4tIsolationOversizedTextCase),
    (New-P4tIsolationOversizedBoundaryCase),
    (New-P4tIsolationBinaryCase),
    (New-P4tIsolationUtf16Case 'utf16le-runtime' $false),
    (New-P4tIsolationUtf16Case 'utf16be-runtime' $true)
  )
  $junctionRoot = New-ProjectSkeleton 'isolation-junction'
  [void](New-P4tJunction (Join-Path $junctionRoot 'app\borrowed-link') (Join-Path $junctionRoot '借鉴区'))
  $cases += [pscustomobject]@{ Name = 'junction'; Root = $junctionRoot; Mode = 'project'; Exit = 10 }

  $docsRoot = New-ProjectSkeleton 'isolation-docs-positive'
  Write-P4tUtf8 (Join-Path $docsRoot 'Docs\reference.md') @'
# 来源记录
- URL: https://example.invalid/source
- capture: local-20260719-aaaaaaaaaaaa
- card: [借鉴卡](../借鉴区/事项/borrow-20260719-example/借鉴卡.md)
'@
  Write-P4tUtf8 (Join-Path $docsRoot 'CHANGELOG.md') "- 记录 capture ID，不构成运行时依赖。`n"
  Write-P4tUtf8 (Join-Path $docsRoot 'app\localized.js') "export const local = 'localized';`n"
  $cases += [pscustomobject]@{ Name = 'docs-and-localized-copy'; Root = $docsRoot; Mode = 'project'; Exit = 0 }

  $templateRoot = New-TemplateSkeleton 'isolation-template-positive'
  $cases += [pscustomobject]@{ Name = 'template-without-app'; Root = $templateRoot; Mode = 'template'; Exit = 0 }
  $sentinelRoot = New-ProjectSkeleton 'isolation-untrusted-content'
  $sentinel = Join-Path $sentinelRoot 'sentinel-must-not-exist.txt'
  Write-Utf8Bom (Join-Path $sentinelRoot '借鉴区\来源\untrusted\快照\do-not-run.ps1') `
    "[IO.File]::WriteAllText('$($sentinel.Replace("'", "''"))','executed')`n"
  $cases += [pscustomobject]@{
    Name = 'untrusted-source-content-is-data'; Root = $sentinelRoot; Mode = 'project'; Exit = 0
    Sentinel = $sentinel
  }

  $modeUnknownRoot = New-ProjectSkeleton 'isolation-mode-unknown'
  Remove-Item -LiteralPath (Join-Path $modeUnknownRoot '.czxt-project-root') -Force
  $modeConflictRoot = New-ProjectSkeleton 'isolation-mode-conflict'
  Write-P4tUtf8 (Join-Path $modeConflictRoot '.czxt-template-root') `
    "czxt-root-mode=template`nschema=1`n"
  $modeCases = @(
    [pscustomobject]@{
      Name = 'project-as-template'; Root = (New-ProjectSkeleton 'isolation-project-as-template')
      SuppliedMode = 'template'; ActualMode = 'project'
    },
    [pscustomobject]@{
      Name = 'template-as-project'; Root = (New-TemplateSkeleton 'isolation-template-as-project')
      SuppliedMode = 'project'; ActualMode = 'template'
    },
    [pscustomobject]@{
      Name = 'unknown-root'; Root = $modeUnknownRoot
      SuppliedMode = 'unknown'; ActualMode = 'unknown'
    },
    [pscustomobject]@{
      Name = 'conflicting-root'; Root = $modeConflictRoot
      SuppliedMode = 'conflict'; ActualMode = 'conflict'
    }
  )

  Invoke-CzxtContract 'isolation fixtures cover business dependencies and legal references' {
    Assert-CzxtEqual 31 $cases.Count 'isolation case count'
    Assert-CzxtEqual 4 $modeCases.Count 'isolation mode anti-spoof case count'
    Assert-CzxtTrue ((Get-Item -LiteralPath (Join-Path $junctionRoot 'app\borrowed-link') -Force).Attributes `
      -band [IO.FileAttributes]::ReparsePoint) 'isolation junction fixture'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $sentinel)) 'untrusted sentinel already exists'
  }

  $script:IsolationHelperReady = $false
  Invoke-CzxtContract 'P4t isolation helper exists with its dedicated leaf API' {
    Import-P4tHelper 'borrowing-isolation.ps1' 'Invoke-BorrowingP4tIsolationCheck'
    $script:IsolationHelperReady = $true
  }
  if ($script:IsolationHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('isolation: ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tIsolationCheck -Root $case.Root -Mode $case.Mode
        Assert-P4tResult $result $case.Exit $case.Name
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
        if ($null -ne $case.PSObject.Properties['Sentinel']) {
          Assert-CzxtTrue (-not (Test-Path -LiteralPath $case.Sentinel)) 'helper executed source content'
        }
      }
    }
    Invoke-CzxtContract 'isolation results do not leak between roots' {
      Assert-P4tResult (Invoke-BorrowingP4tIsolationCheck $cases[0].Root project) 10 'bad root'
      Assert-P4tResult (Invoke-BorrowingP4tIsolationCheck $docsRoot project) 0 'good root after bad'
    }
    foreach ($modeCase in $modeCases) {
      Invoke-CzxtContract ('isolation rejects forged mode: ' + $modeCase.Name) {
        $before = Get-P4tTreeState $modeCase.Root
        $result = Invoke-BorrowingP4tIsolationCheck `
          -Root $modeCase.Root -Mode $modeCase.SuppliedMode
        Assert-P4tResult $result 10 $modeCase.Name
        Assert-CzxtEqual $modeCase.ActualMode ([string]$result.Mode) `
          ($modeCase.Name + ' independently detected RootMode')
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $modeCase.Root) `
          ($modeCase.Name + ' read-only')
      }
    }
    Invoke-CzxtContract 'isolation rejects a hardlink replacement between file check and read' {
      $root = New-ProjectSkeleton 'isolation-file-swap'
      $path = Join-Path $root 'app\runtime.js'
      $outside = Join-Path $script:P4tFixtureRoot 'isolation-file-swap-outside.js'
      Write-P4tUtf8 $path "export const safe = true;`n"
      Write-P4tUtf8 $outside "export const outside = true;`n"
      $script:P4tIsolationFileSwapPath = $path
      $script:P4tIsolationFileSwapTarget = $outside
      $injected = $false
      $script:P4tIsolationTestInjections = @{
        'before-file-read' = {
          param($context)
          if (([string]$context.Path).Equals(
              $script:P4tIsolationFileSwapPath, [StringComparison]::OrdinalIgnoreCase)) {
            [IO.File]::Delete($script:P4tIsolationFileSwapPath)
            [void](New-Item -ItemType HardLink -Path $script:P4tIsolationFileSwapPath `
              -Target $script:P4tIsolationFileSwapTarget)
            $script:P4tIsolationFileSwapRan = $true
          }
        }
      }
      $script:P4tIsolationFileSwapRan = $false
      try { $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project }
      finally { $script:P4tIsolationTestInjections = $null }
      $injected = [bool]$script:P4tIsolationFileSwapRan
      Assert-CzxtTrue $injected 'file replacement injection did not run after the initial safety check'
      Assert-P4tResult $result 10 'file replacement between check and read'
    }
    Invoke-CzxtContract 'isolation revalidates a queued directory before enumeration' {
      $root = New-ProjectSkeleton 'isolation-directory-swap'
      $directory = Join-Path $root 'app\queued'
      $outside = Join-Path $script:P4tFixtureRoot 'isolation-empty-outside'
      [void](New-Item -ItemType Directory -Path $directory)
      [void](New-Item -ItemType Directory -Path $outside)
      $script:P4tIsolationDirectorySwapPath = $directory
      $script:P4tIsolationDirectorySwapTarget = $outside
      $script:P4tIsolationDirectorySwapRan = $false
      $script:P4tIsolationTestInjections = @{
        'before-directory-enumeration' = {
          param($context)
          if (([string]$context.Path).Equals(
              $script:P4tIsolationDirectorySwapPath, [StringComparison]::OrdinalIgnoreCase)) {
            [IO.Directory]::Delete($script:P4tIsolationDirectorySwapPath, $false)
            [void](New-P4tJunction $script:P4tIsolationDirectorySwapPath `
              $script:P4tIsolationDirectorySwapTarget)
            $script:P4tIsolationDirectorySwapRan = $true
          }
        }
      }
      try { $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project }
      finally { $script:P4tIsolationTestInjections = $null }
      Assert-CzxtTrue ([bool]$script:P4tIsolationDirectorySwapRan) `
        'directory replacement injection did not run after enqueue'
      Assert-P4tResult $result 10 'queued directory replacement before enumeration'
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
