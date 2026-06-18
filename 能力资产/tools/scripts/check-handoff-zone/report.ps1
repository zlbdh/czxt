function Write-HandoffIssueBlock {
  param(
    [object[]]$Items,
    [string]$Title,
    [scriptblock]$Format,
    [int]$Limit = 0
  )

  if ($Items.Count -eq 0) { return }

  Write-Host ""
  Write-Host $Title -ForegroundColor Yellow
  $outputItems = $Items
  if ($Limit -gt 0) {
    $outputItems = @($Items | Select-Object -First $Limit)
  }
  $outputItems | ForEach-Object {
    Write-Host (& $Format $_) -ForegroundColor Yellow
  }
}
