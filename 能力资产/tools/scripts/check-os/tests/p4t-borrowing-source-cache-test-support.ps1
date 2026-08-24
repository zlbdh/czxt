$ErrorActionPreference = 'Stop'

$script:P4tCaptureModuleRoot = [IO.Path]::GetFullPath((
    Join-Path $PSScriptRoot '..\..\borrowing-capture'))
. (Join-Path $script:P4tCaptureModuleRoot 'common.ps1')
. (Join-Path $script:P4tCaptureModuleRoot 'source-card-skeleton.ps1')

function Write-P4tCaptureLocalState {
  param([string]$CapturePath, [string]$SourceType)
  $input = [pscustomobject]@{ SourceType = $SourceType }
  if ($SourceType -eq 'local') {
    Add-Member -InputObject $input -NotePropertyName LocalSourcePath `
      -NotePropertyValue (Join-Path $script:P4tFixtureRoot 'original-local-source')
  }
  elseif ($SourceType -eq 'web') {
    Add-Member -InputObject $input -NotePropertyName WebRawBytesPath `
      -NotePropertyValue (Join-Path $script:P4tFixtureRoot 'original-response.bin')
    Add-Member -InputObject $input -NotePropertyName WebResponseMetadataPath `
      -NotePropertyValue (Join-Path $script:P4tFixtureRoot 'original-response.metadata.json')
  }
  [byte[]]$bytes = New-BorrowingCaptureLocalStateBytes -Input $input -SourceType $SourceType
  [IO.File]::WriteAllBytes((Join-Path $CapturePath 'capture.local.json'), $bytes)
}

function Get-P4tSha256Hex {
  param([byte[]]$Bytes)
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}

function Invoke-P4tFixtureGit {
  param([string[]]$Arguments, [string]$Context)
  $oldPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $output = @(& git @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
  }
  finally { $ErrorActionPreference = $oldPreference }
  if ($exitCode -ne 0) {
    throw ('fixture git failed ({0}, exit {1}): {2}' -f $Context, $exitCode, ($output -join "`n"))
  }
  return (($output | ForEach-Object { [string]$_ }) -join "`n").Trim()
}

function ConvertTo-P4tCanonicalGitCache {
  param([string]$Repository, [string]$Commit)
  foreach ($name in @('hooks', 'info', 'description', 'packed-refs')) {
    $path = Join-Path $Repository $name
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
  }
  $config = @(
    '[core]', "`trepositoryformatversion = 0", "`tfilemode = false",
    "`tbare = true", "`tsymlinks = false", "`tignorecase = true"
  ) -join "`n"
  Write-P4tUtf8 (Join-Path $Repository 'config') ($config + "`n")
  Write-P4tUtf8 (Join-Path $Repository 'HEAD') ($Commit + "`n")
  $captureRef = Join-Path $Repository 'refs\czxt\capture'
  [void](New-Item -ItemType Directory -Path (Split-Path -Parent $captureRef) -Force)
  Write-P4tUtf8 $captureRef ($Commit + "`n")
}

function New-P4tGitCacheFacts {
  param([string]$CapturePath, [string]$PayloadText)
  $work = Join-Path $script:P4tFixtureRoot ('gw-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
  [void](New-Item -ItemType Directory -Path $work)
  [void](Invoke-P4tFixtureGit @('init', '--quiet', $work) 'init')
  [void](Invoke-P4tFixtureGit @('-C', $work, 'symbolic-ref', 'HEAD', 'refs/heads/main') 'branch')
  [void](Invoke-P4tFixtureGit @('-C', $work, 'config', 'user.name', 'P4t Fixture') 'user.name')
  [void](Invoke-P4tFixtureGit @('-C', $work, 'config', 'user.email', 'p4t@example.invalid') 'user.email')
  [void](Invoke-P4tFixtureGit @('-C', $work, 'config', 'commit.gpgsign', 'false') 'gpg')
  [void](Invoke-P4tFixtureGit @('-C', $work, 'config', 'core.hooksPath', 'NUL') 'hooks')
  [void](Invoke-P4tFixtureGit @('-C', $work, 'config', 'core.autocrlf', 'false') 'autocrlf')
  Write-P4tUtf8 (Join-Path $work 'payload.txt') ($PayloadText + "`n")
  [void](Invoke-P4tFixtureGit @('-C', $work, 'add', '--', 'payload.txt') 'add')
  [void](Invoke-P4tFixtureGit @('-C', $work, 'commit', '--quiet', '--no-gpg-sign', '-m', 'fixture') 'commit')
  $commit = Invoke-P4tFixtureGit @('-C', $work, 'rev-parse', 'HEAD') 'commit id'
  $tree = Invoke-P4tFixtureGit @('-C', $work, 'rev-parse', 'HEAD^{tree}') 'tree id'
  $snapshot = Join-Path $CapturePath '快照'
  [void](New-Item -ItemType Directory -Path $snapshot -Force)
  [void](Invoke-P4tFixtureGit @('clone', '--quiet', '--bare', '--no-local', $work,
      (Join-Path $snapshot 'repository.git')) 'bare clone')
  ConvertTo-P4tCanonicalGitCache -Repository (Join-Path $snapshot 'repository.git') `
    -Commit $commit
  Write-P4tCaptureLocalState -CapturePath $CapturePath -SourceType git
  Remove-Item -LiteralPath $work -Recurse -Force
  return [pscustomobject]@{ Fingerprint = $commit; Tree = $tree; ObjectFormat = 'sha1' }
}

function New-P4tLocalCacheFacts {
  param([string]$CapturePath, [string]$PayloadText)
  $content = Join-Path $CapturePath '快照\内容'
  [void](New-Item -ItemType Directory -Path $content -Force)
  $payload = [Text.Encoding]::UTF8.GetBytes($PayloadText + "`n")
  [IO.File]::WriteAllBytes((Join-Path $content 'payload.txt'), $payload)
  $payloadHash = Get-P4tSha256Hex $payload
  $manifestText = "{0}`t{1}`tpayload.txt`n" -f $payloadHash, $payload.Length
  $manifestBytes = [Text.Encoding]::UTF8.GetBytes($manifestText)
  [IO.File]::WriteAllBytes((Join-Path $CapturePath '快照\manifest.tsv'), $manifestBytes)
  Write-P4tCaptureLocalState -CapturePath $CapturePath -SourceType local
  return [pscustomobject]@{
    Fingerprint = Get-P4tSha256Hex $manifestBytes
    FileCount = 1
    TotalBytes = $payload.Length
  }
}

function New-P4tWebCacheFacts {
  param([string]$CapturePath, [string]$PayloadText)
  $snapshot = Join-Path $CapturePath '快照'
  [void](New-Item -ItemType Directory -Path $snapshot -Force)
  $raw = [Text.Encoding]::UTF8.GetBytes($PayloadText)
  [IO.File]::WriteAllBytes((Join-Path $snapshot 'response.bin'), $raw)
  $metadata = '{"schema":"borrowing-web-response/v1","original_url":"https://example.invalid/start","final_url":"https://example.invalid/final","redirect_chain":[{"status_code":301,"location_url":"https://example.invalid/final"}],"status_code":200,"mime":"text/plain","charset":"utf-8","etag":null,"last_modified":null}' + "`n"
  [IO.File]::WriteAllBytes((Join-Path $snapshot 'response.metadata.json'),
    [Text.Encoding]::UTF8.GetBytes($metadata))
  Write-P4tCaptureLocalState -CapturePath $CapturePath -SourceType web
  return [pscustomobject]@{ Fingerprint = Get-P4tSha256Hex $raw }
}
