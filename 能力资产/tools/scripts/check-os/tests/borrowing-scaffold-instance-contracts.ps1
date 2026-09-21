$ErrorActionPreference = 'Stop'

function Invoke-BorrowingInstanceContracts {
  param(
    [string]$TemplateRoot,
    [string]$InstallerPath,
    [string]$P4aPath,
    [string]$InstanceRoot,
    [string[]]$StaticPaths,
    [string[]]$SkeletonPaths
  )

  $install = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments @(
    '-ProjectRoot', $InstanceRoot, '-ProjectName', 'B2 骨架实例', '-AppRepoDir', 'app'
  )
  Invoke-CzxtContract 'real installer copies only a fresh borrowing skeleton' {
    Assert-CzxtEqual 0 $install.ExitCode ("installer stderr: {0}" -f $install.StdErr)
    foreach ($relativePath in $SkeletonPaths) {
      $fullPath = Join-Path $InstanceRoot ($relativePath.Replace('/', '\'))
      Assert-CzxtTrue (Test-Path -LiteralPath $fullPath -PathType Leaf) `
        ("instance missing: {0}" -f $relativePath)
    }
    $sourceChildren = @(Get-ChildItem -LiteralPath (Join-Path $InstanceRoot '借鉴区\来源') -Force)
    $itemChildren = @(Get-ChildItem -LiteralPath (Join-Path $InstanceRoot '借鉴区\事项') -Force)
    Assert-CzxtEqual 1 $sourceChildren.Count 'fresh source directory should contain only .gitkeep'
    Assert-CzxtEqual '.gitkeep' $sourceChildren[0].Name 'fresh source directory sentinel'
    Assert-CzxtEqual 0 $sourceChildren[0].Length 'fresh source sentinel must be zero-byte'
    Assert-CzxtEqual 1 $itemChildren.Count 'fresh item directory should contain only .gitkeep'
    Assert-CzxtEqual '.gitkeep' $itemChildren[0].Name 'fresh item directory sentinel'
    Assert-CzxtEqual 0 $itemChildren[0].Length 'fresh item sentinel must be zero-byte'
    foreach ($relativePath in $StaticPaths) {
      $text = [IO.File]::ReadAllText((Join-Path $InstanceRoot ($relativePath.Replace('/', '\'))))
      Assert-CzxtTrue (-not $text.Contains('{{PROJECT_NAME}}')) `
        ("placeholder remained in {0}" -f $relativePath)
      if ($relativePath -ne '借鉴区/.gitignore') {
        Assert-CzxtTrue $text.Contains('B2 骨架实例') `
          ("project placeholder was not replaced in {0}" -f $relativePath)
      }
    }
    $ownedCaptureRuntimes = @(
      '能力资产\tools\scripts\borrowing-owned-directory.ps1',
      '能力资产\tools\scripts\borrowing-owned-file.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-staging.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-staging-content.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-staging-cleanup.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-tree-seal-native.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-tree-seal-inventory.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-tree-seal.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-tree-seal-remove.ps1',
      '能力资产\tools\scripts\borrowing-capture\orchestrator-seals.ps1',
      '能力资产\tools\scripts\borrowing-capture\p4t-component-seal.ps1',
      '能力资产\tools\scripts\installer-render-text.ps1',
      '能力资产\tools\scripts\check-pm-tracking\git-status.ps1',
      '能力资产\tools\scripts\check-os\adr-governance-truth.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-support.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-unit-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-hook-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-regex-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-anchor-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\pm-tracking-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\pm-tracking-contract-support.ps1',
      '能力资产\tools\scripts\check-os\tests\adr-governance-count-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\adr-governance-count-test-support.ps1',
      '能力资产\tools\scripts\check-os\tests\borrowing-owned-rename-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\borrowing-owned-tree-seal-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\borrowing-capture-git-auxiliary-cleanup-cases.ps1'
    )
    foreach ($runtimeRelative in $ownedCaptureRuntimes) {
      Assert-CzxtTrue (Test-Path -LiteralPath `
          (Join-Path $InstanceRoot $runtimeRelative) -PathType Leaf) `
        ('fresh instance omitted owned capture runtime: ' + $runtimeRelative)
      Assert-CzxtEqual `
        (Get-BorrowingByteSignature (Join-Path $TemplateRoot $runtimeRelative)) `
        (Get-BorrowingByteSignature (Join-Path $InstanceRoot $runtimeRelative)) `
        ('fresh instance runtime bytes differ: ' + $runtimeRelative)
    }
  }

  Invoke-CzxtContract 'real installer interpolates its target path in the state trajectory' {
    $stateText = [IO.File]::ReadAllText((Join-Path $InstanceRoot '状态.md'))
    $normalizedFragment = '实例化操作系统到 {0}：' -f `
      [IO.Path]::GetFullPath($InstanceRoot)
    Assert-CzxtEqual 1 `
      ([regex]::Matches($stateText, [regex]::Escape($normalizedFragment))).Count `
      'fresh installer should append exactly one normalized ProjectRoot fragment'
    $literalFragment = '实例化操作系统到 $ProjectRoot：'
    Assert-CzxtEqual 0 `
      ([regex]::Matches($stateText, [regex]::Escape($literalFragment))).Count `
      'fresh installer must not retain a literal ProjectRoot variable name'
    $expectedColumns = ' | 操作系统 PM「框架管家」 | 操作系统 PM「框架管家」 | {0}生成项目区/项目配置/需求入口/TASKS/业务仓库目录骨架，并完成占位符替换。 | ✅ Q1-Q7：framework / 操作系统 PM | ✅ |' -f `
      $normalizedFragment
    $trackPattern = '(?m)^\| (?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2})' + `
      [regex]::Escape($expectedColumns) + '\r?$'
    $trackMatches = [regex]::Matches($stateText, $trackPattern)
    Assert-CzxtEqual 1 $trackMatches.Count `
      'fresh installer should append exactly one complete timestamped trajectory row'
    if ($trackMatches.Count -eq 1) {
      $parsedTime = [datetime]::MinValue
      Assert-CzxtTrue ([datetime]::TryParseExact($trackMatches[0].Groups['time'].Value, `
          'yyyy-MM-dd HH:mm', [Globalization.CultureInfo]::InvariantCulture, `
          [Globalization.DateTimeStyles]::None, [ref]$parsedTime)) `
        'fresh installer trajectory timestamp must be a valid stable minute value'
    }
  }

  Invoke-CzxtContract 'template and instance P4a integrate the borrowing guard' {
    $templateResult = Invoke-CzxtPowerShell -ScriptPath $P4aPath `
      -ScriptArguments @('-Root', $TemplateRoot)
    Assert-CzxtEqual 0 $templateResult.ExitCode ("template P4a stderr: {0}" -f $templateResult.StdErr)
    $instanceP4a = Join-Path $InstanceRoot '能力资产\tools\scripts\check-os\p4a-basic-integrity.ps1'
    $instanceResult = Invoke-CzxtPowerShell -ScriptPath $instanceP4a `
      -ScriptArguments @('-Root', $InstanceRoot)
    Assert-CzxtEqual 0 $instanceResult.ExitCode ("instance P4a stderr: {0}" -f $instanceResult.StdErr)
  }

  Invoke-CzxtContract 'real instance capture accepts its rewritten source-card skeleton' {
    $referenceRoot = Join-Path (Split-Path -Parent $InstanceRoot) 'local-reference'
    [void](New-Item -ItemType Directory -Path $referenceRoot -Force)
    $capturePath = Join-Path $InstanceRoot `
      '能力资产\tools\scripts\capture-borrowing-source.ps1'
    $capture = Invoke-CzxtPowerShell -ScriptPath $capturePath -ScriptArguments @(
      '-Root', $InstanceRoot, '-SourceType', 'Local',
      '-SourceId', 'scaffold-instance', '-LocalPath', $referenceRoot,
      '-LocalDisplayName', 'scaffold-instance'
    )
    Assert-CzxtEqual 0 $capture.ExitCode ("instance capture stderr: {0}" -f $capture.StdErr)
    Assert-CzxtTrue ([regex]::IsMatch($capture.StdOut, '(?m)^result=READY\r?$')) `
      'instance capture did not produce a ready source'
  }

  Invoke-CzxtContract 'Force preserves source/item bytes and an existing non-installer file' {
    $existing = Join-Path $InstanceRoot '用户笔记.md'
    Write-CzxtNoBomText $existing `
      "name={{PROJECT_NAME}}`nroot={{PROJECT_ROOT}}`napp={{APP_REPO_DIR}}`n"
    $existingBefore = Get-BorrowingByteSignature $existing
    $protected = New-BorrowingProtectedFixture
    $before = @{}
    foreach ($entry in $protected.GetEnumerator()) {
      $path = Join-Path $InstanceRoot $entry.Key
      [void](New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force)
      [IO.File]::WriteAllBytes($path, $entry.Value)
      $before[$entry.Key] = Get-BorrowingByteSignature $path
    }
    $runtimeRelatives = @(
      '能力资产\tools\scripts\check-os\p4t\borrowing-item-closure.ps1',
      '能力资产\tools\scripts\borrowing-owned-directory.ps1',
      '能力资产\tools\scripts\borrowing-owned-file.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-staging.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-staging-content.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-staging-cleanup.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-tree-seal-native.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-tree-seal-inventory.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-tree-seal.ps1',
      '能力资产\tools\scripts\borrowing-capture\owned-tree-seal-remove.ps1',
      '能力资产\tools\scripts\borrowing-capture\orchestrator-seals.ps1',
      '能力资产\tools\scripts\borrowing-capture\p4t-component-seal.ps1',
      '能力资产\tools\scripts\installer-render-text.ps1',
      '能力资产\tools\scripts\check-pm-tracking\git-status.ps1',
      '能力资产\tools\scripts\check-os\adr-governance-truth.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-support.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-unit-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-hook-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-regex-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\installer-render-anchor-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\pm-tracking-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\pm-tracking-contract-support.ps1',
      '能力资产\tools\scripts\check-os\tests\adr-governance-count-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\adr-governance-count-test-support.ps1',
      '能力资产\tools\scripts\check-os\tests\borrowing-owned-rename-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\borrowing-owned-tree-seal-contracts.ps1',
      '能力资产\tools\scripts\check-os\tests\borrowing-capture-git-auxiliary-cleanup-cases.ps1'
    )
    foreach ($runtimeRelative in $runtimeRelatives) {
      $runtimePath = Join-Path $InstanceRoot $runtimeRelative
      [IO.File]::Delete($runtimePath)
      Assert-CzxtTrue (-not (Test-Path -LiteralPath $runtimePath)) `
        ('Force upgrade fixture failed to remove runtime: ' + $runtimeRelative)
    }
    $forceStatePath = Join-Path $InstanceRoot '状态.md'
    $stateSentinel = '<!-- czxt-force-state-sentinel:{0} -->' -f `
      [guid]::NewGuid().ToString('N')
    [IO.File]::AppendAllText($forceStatePath, "`n$stateSentinel", `
      (New-Object Text.UTF8Encoding($false)))
    $preForceStateBytes = [IO.File]::ReadAllBytes($forceStatePath)
    $preForceStateText = [IO.File]::ReadAllText($forceStatePath)
    Assert-CzxtTrue $preForceStateText.EndsWith($stateSentinel, `
        [StringComparison]::Ordinal) `
      'Force state sentinel was not persisted before the upgrade'
    $forced = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments @(
      '-ProjectRoot', $InstanceRoot, '-ProjectName', 'B2 骨架实例', '-AppRepoDir', 'app', '-Force'
    )
    Assert-CzxtEqual 0 $forced.ExitCode ("Force installer stderr: {0}" -f $forced.StdErr)
    $forceStateBytes = [IO.File]::ReadAllBytes($forceStatePath)
    $forceStateText = [IO.File]::ReadAllText($forceStatePath)
    $bytePrefixMatches = $forceStateBytes.Length -gt $preForceStateBytes.Length
    if ($bytePrefixMatches) {
      for ($index = 0; $index -lt $preForceStateBytes.Length; $index++) {
        if ($forceStateBytes[$index] -ne $preForceStateBytes[$index]) {
          $bytePrefixMatches = $false
          break
        }
      }
    }
    Assert-CzxtTrue $bytePrefixMatches `
      'Force must preserve every pre-existing state byte as an exact prefix'
    Assert-CzxtTrue $forceStateText.StartsWith($preForceStateText, `
        [StringComparison]::Ordinal) `
      'Force must preserve the complete pre-existing state text as an exact prefix'
    Assert-CzxtEqual 1 `
      ([regex]::Matches($forceStateText, [regex]::Escape($stateSentinel))).Count `
      'Force must preserve the unique pre-existing state sentinel exactly once'
    $normalizedRoot = [IO.Path]::GetFullPath($InstanceRoot)
    $normalizedFragment = '实例化操作系统到 {0}：' -f $normalizedRoot
    Assert-CzxtEqual 2 `
      ([regex]::Matches($forceStateText, [regex]::Escape($normalizedFragment))).Count `
      'fresh plus Force should append exactly two normalized ProjectRoot fragments'
    $literalFragment = '实例化操作系统到 $ProjectRoot：'
    Assert-CzxtEqual 0 `
      ([regex]::Matches($forceStateText, [regex]::Escape($literalFragment))).Count `
      'fresh plus Force must not retain a literal ProjectRoot variable name'
    $expectedColumns = ' | 操作系统 PM「框架管家」 | 操作系统 PM「框架管家」 | {0}生成项目区/项目配置/需求入口/TASKS/业务仓库目录骨架，并完成占位符替换。 | ✅ Q1-Q7：framework / 操作系统 PM | ✅ |' -f `
      $normalizedFragment
    $trackPattern = '(?m)^\| (?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2})' + `
      [regex]::Escape($expectedColumns) + '\r?$'
    $trackMatches = [regex]::Matches($forceStateText, $trackPattern)
    Assert-CzxtEqual 2 $trackMatches.Count `
      'fresh plus Force should append exactly two complete timestamped trajectory rows'
    foreach ($trackMatch in $trackMatches) {
      $parsedTime = [datetime]::MinValue
      Assert-CzxtTrue ([datetime]::TryParseExact($trackMatch.Groups['time'].Value, `
          'yyyy-MM-dd HH:mm', [Globalization.CultureInfo]::InvariantCulture, `
          [Globalization.DateTimeStyles]::None, [ref]$parsedTime)) `
        'installer trajectory timestamp must be a valid stable minute value'
    }
    $forceSuffix = $forceStateText.Substring($preForceStateText.Length)
    $suffixPattern = '^\n\| (?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2})' + `
      [regex]::Escape($expectedColumns) + '$'
    $suffixMatch = [regex]::Match($forceSuffix, $suffixPattern)
    Assert-CzxtTrue $suffixMatch.Success `
      'Force must append only one complete timestamped trajectory row after the exact prefix'
    if ($suffixMatch.Success) {
      $suffixTime = [datetime]::MinValue
      Assert-CzxtTrue ([datetime]::TryParseExact($suffixMatch.Groups['time'].Value, `
          'yyyy-MM-dd HH:mm', [Globalization.CultureInfo]::InvariantCulture, `
          [Globalization.DateTimeStyles]::None, [ref]$suffixTime)) `
        'Force appended trajectory timestamp must be a valid stable minute value'
    }
    foreach ($runtimeRelative in $runtimeRelatives) {
      $runtimePath = Join-Path $InstanceRoot $runtimeRelative
      $templateRuntime = Join-Path $TemplateRoot $runtimeRelative
      Assert-CzxtTrue (Test-Path -LiteralPath $runtimePath -PathType Leaf) `
        ('Force did not restore runtime: ' + $runtimeRelative)
      Assert-CzxtEqual (Get-BorrowingByteSignature $templateRuntime) `
        (Get-BorrowingByteSignature $runtimePath) `
        ('Force runtime bytes differ from template: ' + $runtimeRelative)
    }
    foreach ($relativePath in @(
        '.codex\.codex', '.claude\.claude', '操作系统\操作系统',
        '能力资产\能力资产', 'PM工作区\PM工作区', '交接区\交接区',
        '确认改动\确认改动', '项目配置\项目配置', 'Docs\Docs')) {
      Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $InstanceRoot $relativePath))) `
        ("Force created a nested directory copy: {0}" -f $relativePath)
    }
    foreach ($relativePath in $protected.Keys) {
      $path = Join-Path $InstanceRoot $relativePath
      Assert-CzxtEqual $before[$relativePath] (Get-BorrowingByteSignature $path) `
        ("Force changed protected bytes: {0}" -f $relativePath)
    }
    Assert-CzxtEqual $existingBefore (Get-BorrowingByteSignature $existing) `
      'Force rewrote placeholders in an existing non-installer file'
    foreach ($relativePath in $StaticPaths) {
      $text = [IO.File]::ReadAllText((Join-Path $InstanceRoot ($relativePath.Replace('/', '\'))))
      Assert-CzxtTrue (-not $text.Contains('{{PROJECT_NAME}}')) `
        ("Force left static placeholder in {0}" -f $relativePath)
      if ($relativePath -ne '借鉴区/.gitignore') {
        Assert-CzxtTrue $text.Contains('B2 骨架实例') `
          ("Force skipped static rewrite in {0}" -f $relativePath)
      }
    }
  }
}
