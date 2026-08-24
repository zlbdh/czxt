$ErrorActionPreference = 'Stop'

$preparationModuleRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command Read-BorrowingStableSafeFileBytes -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $preparationModuleRoot 'trusted-file-read.ps1')
}
if (-not (Get-Command Set-BorrowingGeneratedStagingFailurePath -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $preparationModuleRoot 'staging-failure.ps1')
}
if (-not (Get-Command New-BorrowingOwnedStagingCore -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $preparationModuleRoot 'owned-staging.ps1')
}

function global:Assert-BorrowingCaptureIgnoreContract {
  param([string]$Root)
  $path = Join-Path $Root '借鉴区\.gitignore'
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Throw-BorrowingFailure preflight missing-trusted-component 'borrowing ignore contract is missing'
  }
  try {
    [byte[]]$bytes = Read-BorrowingStableSafeFileBytes $path preflight `
      missing-trusted-component
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and `
        $bytes[2] -eq 0xBF) { throw 'BOM' }
    $text = (New-Object Text.UTF8Encoding($false, $true)).GetString($bytes)
  }
  catch {
    Throw-BorrowingFailure preflight missing-trusted-component `
      'borrowing ignore contract is unreadable'
  }
  $lines = @($text.Replace("`r`n", "`n").Split([char]10) | ForEach-Object {
      $_.Trim().TrimStart('/')
    } | Where-Object { $_ -and -not $_.StartsWith('#') })
  foreach ($required in @(
      '来源/*/*/快照/**', '来源/*/*/*.local.json', '**/.staging-*/'
    )) {
    if ($lines -cnotcontains $required) {
      Throw-BorrowingFailure preflight missing-trusted-component `
        'borrowing ignore contract is incomplete'
    }
  }
}

function global:Initialize-BorrowingPreparedInput {
  param($Request)
  $rootInfo = Get-BorrowingSafePathInfo $Request.Root Directory preflight invalid-root
  Assert-BorrowingCaptureIgnoreContract $rootInfo.CanonicalPath
  $skeleton = Get-BorrowingValidatedSourceCardSkeleton $rootInfo.CanonicalPath
  switch ($Request.SourceType) {
    'local' {
      $operations = New-BorrowingProductionLocalOperations
      $typedInput = New-BorrowingLocalInput -Root $rootInfo.CanonicalPath `
        -LocalPath $Request.LocalPath -LocalDisplayName $Request.LocalDisplayName `
        -Operations $operations
      $p4tSpec = New-BorrowingP4tProcessSpec -Root $rootInfo.CanonicalPath
      return [pscustomobject]@{
        Root = $rootInfo.CanonicalPath; Request = $Request; Skeleton = $skeleton
        TypedInput = $typedInput; Operations = $operations; P4tSpec = $p4tSpec
      }
    }
    'web' {
      $operations = New-BorrowingProductionWebOperations
      $typedInput = Open-BorrowingWebInput -Root $rootInfo.CanonicalPath `
        -WebRawBytesPath $Request.WebRawBytesPath `
        -WebResponseMetadataPath $Request.WebResponseMetadataPath `
        -Operations $operations
      $p4tSpec = New-BorrowingP4tProcessSpec -Root $rootInfo.CanonicalPath
      return [pscustomobject]@{
        Root = $rootInfo.CanonicalPath; Request = $Request; Skeleton = $skeleton
        TypedInput = $typedInput; Operations = $operations; P4tSpec = $p4tSpec
      }
    }
    'git' {
      $locator = ConvertTo-BorrowingGitLocator $Request.GitLocator
      $ref = ConvertTo-BorrowingGitRef $Request.GitRef
      $executable = Resolve-BorrowingGitExecutable
      $p4tSpec = New-BorrowingP4tProcessSpec -Root $rootInfo.CanonicalPath
      return [pscustomobject]@{
        Root = $rootInfo.CanonicalPath; Request = $Request; Skeleton = $skeleton
        CanonicalLocator = $locator; GitRef = $ref; GitExecutable = $executable
        P4tSpec = $p4tSpec
      }
    }
  }
  Throw-BorrowingFailure input invalid-parameters 'unsupported borrowing source type'
}

function global:New-BorrowingStagingDirectory {
  param($Prepared)
  return New-BorrowingOwnedStagingCore $Prepared
}

function global:New-BorrowingTypedCandidate {
  param($Prepared, $Staging, $Operations)
  [string]$stagingPath = $Staging.StagingPath
  switch ($Prepared.Request.SourceType) {
    'local' {
      return New-BorrowingLocalCandidate -Input $Prepared.TypedInput `
        -StagingPath $stagingPath -Operations $Operations
    }
    'web' {
      return Write-BorrowingWebCandidate -Input $Prepared.TypedInput `
        -StagingPath $stagingPath -Operations $Operations
    }
    'git' {
      Initialize-BorrowingOwnedGitDirectories $Staging
      $runner = New-BorrowingGitRunner $Prepared.GitExecutable.Path $stagingPath
      $runnerForClosure = $runner
      $runGit = {
        param([string[]]$Arguments, [string]$StdOutMode)
        Invoke-BorrowingGitRunner $runnerForClosure $Arguments $StdOutMode
      }.GetNewClosure()
      $candidate = Invoke-BorrowingGitCapture -StagingPath $stagingPath `
        -CanonicalLocator $Prepared.CanonicalLocator `
        -FullRef $Prepared.GitRef.FullRef -RefType $Prepared.GitRef.RefType `
        -RunGit $runGit -Operations $Operations
      Remove-BorrowingOwnedGitRunnerArtifacts $Staging $runner
      $candidate | Add-Member -NotePropertyName GitExecutablePath `
        -NotePropertyValue $Prepared.GitExecutable.Path -Force
      return $candidate
    }
  }
}

function global:Write-BorrowingNewAtomicFile {
  param([string]$Path, [byte[]]$Bytes, $Operations)
  if (Test-Path -LiteralPath $Path) {
    Throw-BorrowingFailure candidate candidate-invalid 'candidate metadata target already exists'
  }
  if ($null -ne $Operations -and $null -ne $Operations.WriteAllBytes) {
    try {
      $writeBytes = $Operations.WriteAllBytes
      & $writeBytes $Path $Bytes
      return
    }
    catch {
      if ($_.Exception.Data['BorrowingStage']) { throw }
      Throw-BorrowingFailure candidate candidate-invalid 'candidate metadata write failed'
    }
  }
  $temporary = Join-Path (Split-Path -Parent $Path) `
    ('.' + [IO.Path]::GetFileName($Path) + '.tmp-' + [guid]::NewGuid().ToString('N'))
  try {
    [IO.File]::WriteAllBytes($temporary, $Bytes)
    [IO.File]::Move($temporary, $Path)
  }
  catch {
    Throw-BorrowingFailure candidate candidate-invalid 'candidate metadata write failed'
  }
}

function global:Write-BorrowingCandidateMetadata {
  param($Prepared, $Candidate, [string]$StagingPath, $Operations)
  $artifact = New-BorrowingSourceCardArtifactCore -Skeleton $Prepared.Skeleton `
    -Candidate $Candidate -Permissions $Prepared.Request
  switch ($Prepared.Request.SourceType) {
    'local' { $stateInput = $Candidate }
    'web' { $stateInput = $Prepared.TypedInput }
    'git' { $stateInput = $Prepared.Request }
  }
  [byte[]]$stateBytes = New-BorrowingCaptureLocalStateBytes `
    -Input $stateInput -SourceType $Prepared.Request.SourceType
  Write-BorrowingNewAtomicFile (Join-Path $StagingPath '来源版本卡.md') `
    $artifact.Bytes $Operations
  Write-BorrowingNewAtomicFile (Join-Path $StagingPath 'capture.local.json') `
    $stateBytes $Operations
  return [pscustomobject]@{
    Artifact = $artifact; LocalStateBytes = $stateBytes; Candidate = $Candidate
  }
}
