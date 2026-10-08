$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'borrowing-doc-rules-capture-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-link-stage-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-identifier-safety-cases.ps1')

function Invoke-BorrowingDocRulesCases {
  param([string]$Root)
  $relative = '能力资产/rules/借鉴治理.md'
  $indexRelative = '能力资产/rules/README.md'

  Invoke-CzxtContract 'borrowing rule document exists' {
    Assert-CzxtTrue (Test-BorrowingDocFile $Root $relative) ("missing file: {0}" -f $relative)
  }

  if (Test-BorrowingDocFile $Root $relative) {
    $text = Get-BorrowingDocText $Root $relative
    Invoke-BorrowingRuleSchemaCases -Text $text
    Invoke-BorrowingRulePolicyCases -Text $text
    Invoke-BorrowingRuleStateCases -Text $text
    Invoke-BorrowingRuleMachineCases -Text $text
    Invoke-BorrowingRuleExecutionCases -Text $text
    Invoke-BorrowingRuleCaptureCases -Text $text
    Invoke-BorrowingRuleLinkStageCases -Text $text
    Invoke-BorrowingRuleIdentifierSafetyCases -Text $text

    Invoke-CzxtContract 'borrowing rule stays declarative' {
      Assert-BorrowingDocExcludesAll $text @(
        '```powershell', 'capture-borrowing-source.ps1',
        'none → draft', 'draft → assessing',
        'implementation_ready → implementing', 'verifying → closed'
      ) 'declarative rule boundary'
      Assert-BorrowingDocNoMatch $text '(?im)^#{2,4}\s*(接入|执行|操作)步骤\s*$' 'rule step heading'
    }
  }

  Invoke-CzxtContract 'rules index lists borrowing governance exactly once' {
    $index = Get-BorrowingDocText $Root $indexRelative
    $scan = Get-BorrowingMarkdownScan $index
    $inventoryHeadings = @()
    for ($line = 0; $line -lt $scan.Lines.Count; $line++) {
      if (-not $scan.OutsideFence[$line]) { continue }
      $heading = [regex]::Match($scan.Lines[$line],
        '^[ ]{0,3}##[ \t]+(?<title>文件清单|Inventory)(?:[ \t]+#+)?[ \t]*$')
      if ($heading.Success) { $inventoryHeadings += $heading.Groups['title'].Value }
    }
    Assert-CzxtEqual 1 $inventoryHeadings.Count 'rules index inventory section count'
    $section = Get-BorrowingMarkdownSection $index $inventoryHeadings[0]
    $linkPattern = '\[(?:借鉴治理\.md|Borrowing Governance)\]\(借鉴治理\.md\)'
    Assert-BorrowingDocMatchCount $section $linkPattern 1 'rules inventory borrowing entry count'
    Assert-BorrowingDocMatchCount $index $linkPattern 1 'rules index total entry count'
  }
}
