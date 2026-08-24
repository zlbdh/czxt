$ErrorActionPreference = 'Stop'

function global:New-P4tIsolationResourceBudget {
  $limits = [ordered]@{
    MaxFiles = [uint64]20000
    MaxDirectoryEntries = [uint64]100000
    MaxDigestBytes = [uint64](512MB)
    MaxProjectConfigBytes = [uint64](1MB)
    MaxProjectConfigReadBytes = [uint64](2MB)
  }
  if ($script:P4tIsolationBudgetOverrides -is [Collections.IDictionary]) {
    foreach ($name in @($limits.Keys)) {
      if ($script:P4tIsolationBudgetOverrides.Contains($name)) {
        $value = [uint64]$script:P4tIsolationBudgetOverrides[$name]
        if ($value -eq 0) { throw ('isolation budget must be positive: ' + $name) }
        $limits[$name] = $value
      }
    }
  }
  return [pscustomobject]@{
    MaxFiles = [uint64]$limits.MaxFiles
    MaxDirectoryEntries = [uint64]$limits.MaxDirectoryEntries
    MaxDigestBytes = [uint64]$limits.MaxDigestBytes
    MaxProjectConfigBytes = [uint64]$limits.MaxProjectConfigBytes
    MaxProjectConfigReadBytes = [uint64]$limits.MaxProjectConfigReadBytes
    Files = [uint64]0
    DirectoryEntries = [uint64]0
    DigestBytes = [uint64]0
    ProjectConfigReadBytes = [uint64]0
  }
}

function global:Use-P4tIsolationResourceBudget {
  param(
    $Budget,
    [uint64]$Files = 0,
    [uint64]$DirectoryEntries = 0,
    [uint64]$DigestBytes = 0
  )
  if ($null -eq $Budget) { throw 'isolation resource budget is missing' }
  foreach ($usage in @(
      [pscustomobject]@{ Name = 'Files'; Limit = 'MaxFiles'; Increment = $Files },
      [pscustomobject]@{
        Name = 'DirectoryEntries'; Limit = 'MaxDirectoryEntries'
        Increment = $DirectoryEntries
      },
      [pscustomobject]@{
        Name = 'DigestBytes'; Limit = 'MaxDigestBytes'; Increment = $DigestBytes
      })) {
    $remaining = [uint64]$Budget.($usage.Limit) - [uint64]$Budget.($usage.Name)
    if ([uint64]$usage.Increment -gt $remaining) {
      throw ('isolation resource budget exceeded: ' + $usage.Name)
    }
  }
  $Budget.Files = [uint64]$Budget.Files + $Files
  $Budget.DirectoryEntries = [uint64]$Budget.DirectoryEntries + $DirectoryEntries
  $Budget.DigestBytes = [uint64]$Budget.DigestBytes + $DigestBytes
}

function global:Use-P4tIsolationProjectConfigBudget {
  param($Budget, [uint64]$Length)
  if ($null -eq $Budget) { throw 'isolation resource budget is missing' }
  if ($Length -gt [uint64]$Budget.MaxProjectConfigBytes) {
    throw 'project config exceeds its per-file byte limit'
  }
  $remaining = [uint64]$Budget.MaxProjectConfigReadBytes -
    [uint64]$Budget.ProjectConfigReadBytes
  if ($Length -gt $remaining) {
    throw 'project config whole-call byte budget exceeded'
  }
  $Budget.ProjectConfigReadBytes = [uint64]$Budget.ProjectConfigReadBytes + $Length
}
