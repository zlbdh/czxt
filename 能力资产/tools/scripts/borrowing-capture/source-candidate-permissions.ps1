$ErrorActionPreference = 'Stop'

function global:Get-BcvPermissionContract {
  return [pscustomobject]@{
    PropertyNames = @(
      'RightsStatus', 'AccessPolicy', 'ReuseScope', 'ExecutionPolicy', 'NetworkPolicy',
      'StoragePolicy', 'DistributionPolicy', 'UpstreamWritePolicy', 'AutoRefresh'
    )
    Dimensions = @(
      'rights_status', 'access_policy', 'reuse_scope', 'execution_policy', 'network_policy',
      'storage_policy', 'distribution_policy', 'upstream_write_policy', 'auto_refresh'
    )
    Defaults = [ordered]@{
      rights_status = 'unverified'; access_policy = 'local-read-only'
      reuse_scope = 'inspect-and-analyze-only'; execution_policy = 'deny'
      network_policy = 'deny'; storage_policy = 'local-only'
      distribution_policy = 'deny'; upstream_write_policy = 'deny'; auto_refresh = 'false'
    }
    Allowed = @{
      rights_status = @('unverified', 'verified', 'restricted')
      access_policy = @('local-read-only', 'source-read-only')
      reuse_scope = @('inspect-and-analyze-only', 'copy-internal-approved',
        'adapt-internal-approved', 'redistribute-approved')
      execution_policy = @('deny', 'sandbox-approved')
      network_policy = @('deny', 'source-read-only')
      storage_policy = @('local-only', 'tracked-metadata-only', 'tracked-content-approved')
      distribution_policy = @('deny', 'internal-approved', 'external-approved')
      upstream_write_policy = @('deny'); auto_refresh = @('false')
    }
  }
}

function global:Get-BcvValidatedPermissions {
  param($Card)
  $contract = Get-BcvPermissionContract
  $permissions = [ordered]@{}
  $authorizations = New-Object 'Collections.Generic.List[object]'
  for ($index = 0; $index -lt 9; $index++) {
    $dimension = $contract.Dimensions[$index]
    $propertyName = $contract.PropertyNames[$index]
    $value = [string]$Card.$dimension
    if ($contract.Allowed[$dimension] -cnotcontains $value) {
      Throw-BorrowingCandidateFailure 'source card permission value is invalid'
    }
    [string[]]$cells = ConvertFrom-BcvCardRow $Card.Lines[32 + $index] 5
    if ($cells[0] -cne $dimension -or $cells[1] -cne $value) {
      Throw-BorrowingCandidateFailure 'source card permission row does not match frontmatter'
    }
    $isDefault = $value -ceq $contract.Defaults[$dimension]
    if (-not (Test-BcvUtcTimestamp $cells[2])) {
      Throw-BorrowingCandidateFailure 'source card authorization time is invalid'
    }
    if ($isDefault) {
      if ($cells[2] -cne $Card.captured_at -or $cells[3] -cne 'default-policy' -or
          $cells[4] -cne 'current-capture') {
        Throw-BorrowingCandidateFailure 'default permission authorization is not canonical'
      }
    }
    elseif ([Text.Encoding]::UTF8.GetByteCount($cells[3]) -gt 512 -or
        [Text.Encoding]::UTF8.GetByteCount($cells[4]) -gt 512 -or
        [string]::IsNullOrWhiteSpace($cells[3]) -or
        [string]::IsNullOrWhiteSpace($cells[4]) -or
        (Test-BorrowingCredentialMaterial $cells[3]) -or
        (Test-BorrowingCredentialMaterial $cells[4])) {
      Throw-BorrowingCandidateFailure 'permission override authorization is invalid'
    }
    $permissions[$propertyName] = $value
    [void]$authorizations.Add([pscustomobject][ordered]@{
        Dimension = $dimension; Value = $value; AuthorizationTime = $cells[2]
        AuthorizationSource = $cells[3]; AuthorizationScope = $cells[4]
        IsDefault = $isDefault
      })
  }
  $expectedAccess = if ($Card.source_type -ceq 'local') { 'local-read-only' } else { 'source-read-only' }
  $expectedNetwork = if ($Card.source_type -ceq 'local') { 'deny' } else { 'source-read-only' }
  if ($permissions.AccessPolicy -cne $expectedAccess -or
      $permissions.NetworkPolicy -cne $expectedNetwork -or
      $permissions.ExecutionPolicy -cne 'deny' -or
      $permissions.UpstreamWritePolicy -cne 'deny') {
    Throw-BorrowingCandidateFailure 'source type permission combination is invalid'
  }
  return [pscustomobject]@{
    Permissions = [pscustomobject]$permissions
    PermissionAuthorizations = $authorizations.ToArray()
  }
}
