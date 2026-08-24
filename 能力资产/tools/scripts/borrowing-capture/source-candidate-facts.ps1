$ErrorActionPreference = 'Stop'

function global:Get-BcvValidatedWebFacts {
  param($Card, [string[]]$Cells)
  if ($Card.fingerprint_algorithm -cne 'sha256-raw-bytes-v1' -or
      $Card.fingerprint -cnotmatch '\A[0-9a-f]{64}\z' -or
      $Cells[8] -cne $Card.fingerprint -or
      -not (Test-BcvCanonicalWebFactToken $Cells[5]) -or
      -not (Test-BcvCanonicalWebFactToken $Cells[6]) -or
      -not (Test-BcvCanonicalWebFactToken $Cells[7])) {
    Throw-BorrowingCandidateFailure 'Web source facts are invalid'
  }
  $json = '{"schema":"borrowing-web-response/v1","original_url":' +
    (ConvertTo-BorrowingCanonicalJsonString $Cells[0]) + ',"final_url":' +
    (ConvertTo-BorrowingCanonicalJsonString $Cells[1]) + ',"redirect_chain":' +
    $Cells[2] + ',"status_code":' + $Cells[3] + ',"mime":' +
    (ConvertTo-BorrowingCanonicalJsonString $Cells[4]) + ',"charset":' + $Cells[5] +
    ',"etag":' + $Cells[6] + ',"last_modified":' + $Cells[7] + "}`n"
  try {
    $metadata = Read-BorrowingStrictWebMetadata -Bytes ([Text.Encoding]::UTF8.GetBytes($json))
    [byte[]]$canonical = ConvertTo-BorrowingCanonicalWebMetadataBytes $metadata
  }
  catch { Throw-BorrowingCandidateFailure 'Web source facts are invalid' }
  if (-not (Test-BcvBytesEqual $canonical ([Text.Encoding]::UTF8.GetBytes($json))) -or
      $metadata.FinalUrl -cne $Card.canonical_locator) {
    Throw-BorrowingCandidateFailure 'Web source facts are not canonical'
  }
  return [pscustomobject][ordered]@{
    OriginalUrl = $Cells[0]; FinalUrl = $Cells[1]; RedirectChain = $Cells[2]
    StatusCode = [int]$Cells[3]; Mime = $Cells[4]; Charset = $Cells[5]
    Etag = $Cells[6]; LastModified = $Cells[7]; ResponseHash = $Cells[8]
  }
}

function global:Get-BcvValidatedFacts {
  param($Card)
  [string[]]$git = ConvertFrom-BcvCardRow $Card.Lines[46] 7
  [string[]]$local = ConvertFrom-BcvCardRow $Card.Lines[52] 5
  [string[]]$web = ConvertFrom-BcvCardRow $Card.Lines[58] 9
  $na7 = @(1..7 | ForEach-Object { 'not-applicable' })
  $na5 = @(1..5 | ForEach-Object { 'not-applicable' })
  $na9 = @(1..9 | ForEach-Object { 'not-applicable' })
  if ($Card.source_type -ceq 'git') {
    if (($local -join "`0") -cne ($na5 -join "`0") -or
        ($web -join "`0") -cne ($na9 -join "`0")) {
      Throw-BorrowingCandidateFailure 'non-applicable fact rows are invalid'
    }
    $facts = Get-BcvValidatedGitFacts $Card $git
    $names = @('ref', 'ref_type', 'object_format', 'commit', 'tree',
      'submodule_status', 'lfs_status')
    $values = $git
  }
  elseif ($Card.source_type -ceq 'local') {
    if (($git -join "`0") -cne ($na7 -join "`0") -or
        ($web -join "`0") -cne ($na9 -join "`0")) {
      Throw-BorrowingCandidateFailure 'non-applicable fact rows are invalid'
    }
    $facts = Get-BcvValidatedLocalFacts $Card $local
    $names = @('manifest_algorithm', 'file_count', 'total_bytes', 'exclusions', 'failures')
    $values = $local
  }
  else {
    if (($git -join "`0") -cne ($na7 -join "`0") -or
        ($local -join "`0") -cne ($na5 -join "`0")) {
      Throw-BorrowingCandidateFailure 'non-applicable fact rows are invalid'
    }
    $facts = Get-BcvValidatedWebFacts $Card $web
    $names = @('original_url', 'final_url', 'redirect_chain', 'status_code', 'mime',
      'charset', 'etag', 'last_modified', 'response_hash')
    $values = $web
  }
  return [pscustomobject]@{
    TypeFacts = $facts; FactNames = [string[]]$names; FactValues = [string[]]$values
  }
}
