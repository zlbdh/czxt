$ErrorActionPreference = 'Stop'

function New-CzxtInstallerCopyPlanEntry {
  param(
    [string]$ProjectRoot,
    [string]$SourcePath,
    [string]$TargetPath,
    [string]$Item,
    [switch]$Force
  )
  $sourceItem = Get-Item -LiteralPath $SourcePath -Force -ErrorAction Stop
  $expected = $null
  $expectedSource = $null
  $treePlan = $null
  if ($sourceItem.PSIsContainer) {
    $targetExists = Test-Path -LiteralPath $TargetPath
    if ($targetExists -and -not $Force) {
      throw "目标已存在：$TargetPath。若确认覆盖，请加 -Force。"
    }
    $expectAbsentTree = $false
    $treePlan = New-CzxtInstallerTreePlan -ProjectRoot $ProjectRoot `
      -SourcePath $SourcePath -TargetPath $TargetPath
  } else {
    $expectedSource = Get-CzxtInstallerFileState -Path $SourcePath `
      -Context ("复制来源 {0}" -f $Item)
    $expectation = Get-CzxtInstallerTargetExpectation -ProjectRoot $ProjectRoot `
      -TargetPath $TargetPath -Context ("复制目标 {0}" -f $Item) -AllowExisting:$Force
    $expectAbsentTree = $expectation.Mode -eq 'ExpectAbsent'
    $expected = $expectation.State
    Assert-CzxtInstallerFileStateStable $expectedSource `
      (Get-CzxtInstallerFileState -Path $SourcePath -Context ("复制来源 {0}" -f $Item)) `
      ("复制来源 {0}" -f $Item)
  }
  return [pscustomobject]@{
    Item = $Item
    Source = $SourcePath
    Target = $TargetPath
    ExpectAbsentTree = $expectAbsentTree
    TreePlan = $treePlan
    ExpectedPresentState = $expected
    ExpectedSourceState = $expectedSource
  }
}

function Copy-CzxtInstallerBoundFile {
  param(
    [string]$ProjectRoot,
    [string]$SourcePath,
    [string]$TargetPath,
    [string]$Context,
    [switch]$AllowExisting,
    [object]$InstalledFiles
  )
  $expectation = Get-CzxtInstallerTargetExpectation -ProjectRoot $ProjectRoot `
    -TargetPath $TargetPath -Context $Context -AllowExisting:$AllowExisting
  $sourceState = Get-CzxtInstallerFileState -Path $SourcePath -Context ($Context + '来源')
  Copy-CzxtInstallerFile -ProjectRoot $ProjectRoot -SourcePath $SourcePath `
    -TargetPath $TargetPath -Context $Context `
    -ExpectAbsent:($expectation.Mode -eq 'ExpectAbsent') `
    -ExpectedPresentState $expectation.State -ExpectedSourceState $sourceState `
    -InstalledFiles $InstalledFiles
}
