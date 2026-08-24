[CmdletBinding()]
param(
  [ValidateSet('all', 'rules', 'skill', 'workflow', 'boundary')]
  [string]$Area = 'all'
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = $utf8
$OutputEncoding = $utf8

. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-guards.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-guard.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-schema-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-policy-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-state-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-machine-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-execution-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-skill-main-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-skill-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-workflow-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-boundary-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-source-card-template-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-cross-document-cases.ps1')

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))

if ($Area -eq 'all' -or $Area -eq 'rules') {
  Invoke-BorrowingDocRulesCases -Root $root
}
if ($Area -eq 'all' -or $Area -eq 'skill') {
  Invoke-BorrowingDocSkillCases -Root $root
}
if ($Area -eq 'all' -or $Area -eq 'workflow') {
  Invoke-BorrowingDocWorkflowCases -Root $root
}
if ($Area -eq 'all' -or $Area -eq 'boundary') {
  Invoke-BorrowingDocBoundaryCases -Root $root
  Invoke-BorrowingSourceCardTemplateCases -Root $root
  Invoke-BorrowingCrossDocumentCases -Root $root
}

Complete-CzxtContracts
