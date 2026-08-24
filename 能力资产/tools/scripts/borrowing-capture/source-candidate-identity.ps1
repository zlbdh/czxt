$ErrorActionPreference = 'Stop'

function global:ConvertTo-BcvJsonString {
  param([string]$Value)
  if (-not (Get-Command ConvertTo-BorrowingCanonicalJsonString `
        -CommandType Function -ErrorAction SilentlyContinue)) {
    Throw-BorrowingCandidateFailure 'canonical JSON helper is unavailable' `
      'missing-trusted-component'
  }
  return ConvertTo-BorrowingCanonicalJsonString $Value
}

function global:Get-BorrowingSourceStableIdentity {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)]$Candidate)
  try {
    $contract = Get-BcvPermissionContract
    if ($null -eq $Candidate -or
        [string]::IsNullOrEmpty([string]$Candidate.CanonicalLocator) -or
        @($Candidate.FactNames).Count -eq 0 -or
        @($Candidate.FactNames).Count -ne @($Candidate.FactValues).Count -or
        @($Candidate.PermissionAuthorizations).Count -ne 9) {
      Throw-BorrowingCandidateFailure 'stable identity input is invalid'
    }
    $factParts = New-Object 'Collections.Generic.List[string]'
    for ($index = 0; $index -lt @($Candidate.FactNames).Count; $index++) {
      [void]$factParts.Add(
        (ConvertTo-BcvJsonString ([string]$Candidate.FactNames[$index])) + ':' +
        (ConvertTo-BcvJsonString ([string]$Candidate.FactValues[$index]))
      )
    }
    $permissionParts = New-Object 'Collections.Generic.List[string]'
    $overrideParts = New-Object 'Collections.Generic.List[string]'
    for ($index = 0; $index -lt 9; $index++) {
      $dimension = $contract.Dimensions[$index]
      $propertyName = $contract.PropertyNames[$index]
      $value = [string]$Candidate.Permissions.$propertyName
      $authorization = @($Candidate.PermissionAuthorizations)[$index]
      if ([string]$authorization.Dimension -cne $dimension -or
          [string]$authorization.Value -cne $value) {
        Throw-BorrowingCandidateFailure 'stable permission order is invalid'
      }
      [void]$permissionParts.Add(
        (ConvertTo-BcvJsonString $dimension) + ':' + (ConvertTo-BcvJsonString $value)
      )
      if (-not [bool]$authorization.IsDefault) {
        [void]$overrideParts.Add(
          '{"dimension":' + (ConvertTo-BcvJsonString $dimension) + ',"time":' +
          (ConvertTo-BcvJsonString ([string]$authorization.AuthorizationTime)) +
          ',"source":' +
          (ConvertTo-BcvJsonString ([string]$authorization.AuthorizationSource)) +
          ',"scope":' +
          (ConvertTo-BcvJsonString ([string]$authorization.AuthorizationScope)) + '}'
        )
      }
    }
    $stableIdentity = '{"canonical_locator":' +
      (ConvertTo-BcvJsonString ([string]$Candidate.CanonicalLocator)) + ',"facts":{' +
      (@($factParts) -join ',') + '},"permissions":{' +
      (@($permissionParts) -join ',') + '},"authorization_overrides":[' +
      (@($overrideParts) -join ',') + ']}'
    [byte[]]$bytes = [Text.Encoding]::UTF8.GetBytes($stableIdentity)
    return [pscustomobject][ordered]@{
      StableIdentity = $stableIdentity
      StableIdentitySha256 = Get-BcvSha256Hex $bytes
    }
  }
  catch {
    if (Test-BcvKnownFailure $_.Exception) { throw }
    Throw-BorrowingCandidateFailure 'stable identity could not be recomputed'
  }
}
