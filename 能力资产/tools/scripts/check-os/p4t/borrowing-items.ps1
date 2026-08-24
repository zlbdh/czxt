$ErrorActionPreference = 'Stop'

$bpiModuleRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $bpiModuleRoot 'borrowing-common.ps1')
. (Join-Path $borrowingP4tCaptureRoot 'source-candidate-validator.ps1')
foreach ($leaf in @(
    'borrowing-item-parser.ps1', 'borrowing-item-inventory.ps1',
    'borrowing-item-references.ps1', 'borrowing-item-state.ps1',
    'borrowing-item-closure.ps1')) {
  . (Join-Path $bpiModuleRoot $leaf)
}

function global:New-BpiValidationContext {
  param([string]$Root, $SourceState)
  $failures = New-Object 'Collections.Generic.List[string]'
  $safeRoot = $null
  $mode = 'unknown'
  try {
    $safeRoot = Resolve-BorrowingP4tSafeRoot -Root $Root
    $mode = Get-BpiRootMode $safeRoot
  }
  catch { Add-BpiFailure $failures 'P4t item Root 无效或不安全' }
  # 公开 leaf 必须自行 fail closed，不能把模式前置校验只寄托在 façade。
  if ($mode -cnotin @('project', 'template')) {
    Add-BpiFailure $failures ('P4t item RootMode 无效：' + $mode)
  }
  $sourceIndex = New-BpiSourceIndex $SourceState $failures
  $cards = @()
  if ($null -ne $safeRoot) {
    $cards = @(Get-BpiItemInventory $safeRoot $failures)
    try { Assert-BpiSupersedesGraph $cards }
    catch { Add-BpiFailure $failures '借鉴事项 supersedes 引用缺失或成环' }
  }
  return [pscustomobject]@{
    Root = $safeRoot; Mode = $mode; Cards = $cards
    SourceIndex = $sourceIndex; Failures = $failures
  }
}

function global:Test-BpiCardContract {
  param($Card, $Context, [switch]$AllowEmptyClosedSeal)
  Assert-BpiSourceBindings $Card $Context.SourceIndex
  Assert-BpiItemStateContract $Card $Context.Root `
    -AllowEmptyClosedSeal:$AllowEmptyClosedSeal
}

function global:Invoke-BpiSingleItemValidation {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$CardPath,
    [Parameter(Mandatory = $true)]$SourceState,
    [switch]$AllowEmptyClosedSeal
  )
  $context = New-BpiValidationContext $Root $SourceState
  $target = $null
  try { $fullCardPath = [IO.Path]::GetFullPath($CardPath) }
  catch {
    Add-BpiFailure $context.Failures '目标借鉴卡路径无效'
    $fullCardPath = ''
  }
  foreach ($card in $context.Cards) {
    if ($card.Path.Equals($fullCardPath, [StringComparison]::OrdinalIgnoreCase)) {
      if ($null -ne $target) {
        Add-BpiFailure $context.Failures '目标借鉴卡路径不唯一'
      }
      $target = $card
    }
  }
  if ($null -eq $target) { Add-BpiFailure $context.Failures '目标借鉴卡不在事项 inventory 中' }
  else {
    try {
      Test-BpiCardContract $target $context -AllowEmptyClosedSeal:$AllowEmptyClosedSeal
    }
    catch { Add-BpiFailure $context.Failures ('目标借鉴卡合同失败：' + $target.BorrowId) }
  }
  return [pscustomobject][ordered]@{
    IsValid = $context.Failures.Count -eq 0
    Mode = $context.Mode
    Root = $context.Root
    Card = $target
    Failures = [string[]]$context.Failures.ToArray()
  }
}

function global:Invoke-BorrowingP4tItemCheck {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)]$SourceState
  )
  $warnings = New-Object 'Collections.Generic.List[string]'
  $context = New-BpiValidationContext $Root $SourceState
  foreach ($card in $context.Cards) {
    try { Test-BpiCardContract $card $context }
    catch { Add-BpiFailure $context.Failures ('借鉴事项合同失败：' + $card.BorrowId) }
  }
  return New-BorrowingP4tCheckResult -Mode $context.Mode `
    -Warnings $warnings -Failures $context.Failures
}
