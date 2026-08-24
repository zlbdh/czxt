$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function Get-BorrowingValidWebMetadataText {
  param(
    [string]$OriginalUrl = 'https://EXAMPLE.invalid:443/a/../b',
    [string]$FinalUrl = 'https://example.invalid/b',
    [string]$RedirectChain = '[]',
    [string]$StatusCode = '200',
    [string]$Mime = 'application/octet-stream',
    [string]$Charset = 'null',
    [string]$Etag = 'null',
    [string]$LastModified = 'null'
  )
  return '{' +
    '"schema":"borrowing-web-response/v1",' +
    '"original_url":"' + $OriginalUrl + '",' +
    '"final_url":"' + $FinalUrl + '",' +
    '"redirect_chain":' + $RedirectChain + ',' +
    '"status_code":' + $StatusCode + ',' +
    '"mime":"' + $Mime + '",' +
    '"charset":' + $Charset + ',' +
    '"etag":' + $Etag + ',' +
    '"last_modified":' + $LastModified + '}'
}

function ConvertTo-BorrowingFixtureUtf8 {
  param([string]$Text)
  return [Text.Encoding]::UTF8.GetBytes($Text)
}

function Import-BorrowingWebJsonTestModules {
  Import-BorrowingCaptureModules @('web-json', 'common')
  foreach ($name in @(
      'Read-BorrowingStrictWebMetadata',
      'ConvertTo-BorrowingCanonicalWebMetadataBytes'
    )) { Assert-BorrowingCommandExists $name }
}

function Import-BorrowingWebTestModules {
  Import-BorrowingCaptureModules @(
    'common', 'file-safety', 'trusted-file-read', 'web-json', 'web'
  )
  foreach ($name in @(
      'New-BorrowingProductionWebOperations', 'Open-BorrowingWebInput',
      'Write-BorrowingWebCandidate'
    )) { Assert-BorrowingCommandExists $name }
}
