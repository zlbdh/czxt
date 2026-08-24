$ErrorActionPreference = 'Stop'

function New-BsiSealAttestationLine {
  param([string]$BorrowId, $Snapshot)
  Assert-BsiCondition ($BorrowId -cmatch `
      '\Aborrow-[0-9]{8}-[a-z0-9](?:[a-z0-9._-]{0,126}[a-z0-9_-])?\z') `
    'seal 证明 borrow_id 无效'
  Assert-BsiCondition ($Snapshot.IdentityKey -cmatch `
      '\A[0-9a-f]{8}:[0-9a-f]{8}:[0-9a-f]{8}\z') `
    'seal 证明 identity 无效'
  $hash = Get-BorrowingSha256Hex -Bytes $Snapshot.Bytes
  return 'SEALED borrow_id={0} identity_key={1} length={2} sha256={3}' -f `
    $BorrowId, $Snapshot.IdentityKey, ([uint64]$Snapshot.Length), $hash
}

function ConvertFrom-BsiSealAttestation {
  param([string]$Output)
  Assert-BsiCondition ($null -ne $Output) 'seal helper 缺少证明输出'
  $normalized = $Output.Replace("`r`n", "`n").Replace("`r", "`n")
  if ($normalized.EndsWith("`n", [StringComparison]::Ordinal)) {
    $normalized = $normalized.Substring(0, $normalized.Length - 1)
  }
  Assert-BsiCondition (-not $normalized.Contains("`n")) 'seal helper 证明输出不是单行'
  $pattern = '\ASEALED borrow_id=(?<borrow>borrow-[0-9]{8}-[a-z0-9](?:[a-z0-9._-]{0,126}[a-z0-9_-])?) identity_key=(?<identity>[0-9a-f]{8}:[0-9a-f]{8}:[0-9a-f]{8}) length=(?<length>0|[1-9][0-9]*) sha256=(?<sha>[0-9a-f]{64})\z'
  $match = [regex]::Match($normalized, $pattern)
  Assert-BsiCondition $match.Success 'seal helper 证明格式无效'
  return [pscustomobject]@{
    BorrowId = $match.Groups['borrow'].Value
    IdentityKey = $match.Groups['identity'].Value
    Length = [uint64]::Parse($match.Groups['length'].Value,
      [Globalization.CultureInfo]::InvariantCulture)
    Sha256 = $match.Groups['sha'].Value
  }
}
