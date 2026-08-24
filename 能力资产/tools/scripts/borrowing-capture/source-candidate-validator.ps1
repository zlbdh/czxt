$ErrorActionPreference = 'Stop'

$bcvRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command Throw-BorrowingFailure -CommandType Function -ErrorAction SilentlyContinue)) {
  . (Join-Path $bcvRoot 'common.ps1')
}
if (-not (Get-Command Get-BorrowingSafePathInfo -CommandType Function -ErrorAction SilentlyContinue)) {
  . (Join-Path $bcvRoot 'file-safety.ps1')
}
if (-not (Get-Command Get-BorrowingValidatedSourceCardSkeleton `
      -CommandType Function -ErrorAction SilentlyContinue)) {
  . (Join-Path $bcvRoot 'source-card-skeleton.ps1')
}
if (-not (Get-Command Read-BorrowingStrictWebMetadata `
      -CommandType Function -ErrorAction SilentlyContinue)) {
  . (Join-Path $bcvRoot 'web-json.ps1')
}

foreach ($leaf in @(
    'source-candidate-parser.ps1', 'source-candidate-permissions.ps1',
    'source-candidate-fact-primitives.ps1', 'source-candidate-facts.ps1',
    'source-candidate-identity.ps1', 'source-candidate-cache.ps1',
    'source-candidate-fingerprint-local.ps1',
    'source-candidate-fingerprint-web.ps1', 'source-candidate-fingerprint.ps1',
    'source-candidate-card.ps1'
  )) {
  . (Join-Path $bcvRoot $leaf)
}
