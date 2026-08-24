$ErrorActionPreference = 'Stop'

function Assert-BorrowingContainsAll {
  param([string]$Text, [string[]]$Needles, [string]$Context)
  foreach ($needle in $Needles) {
    Assert-CzxtTrue ($Text.Contains($needle)) ("{0} missing: {1}" -f $Context, $needle)
  }
}

function Get-BorrowingByteSignature {
  param([string]$Path)
  $bytes = [IO.File]::ReadAllBytes($Path)
  $sha256 = [Security.Cryptography.SHA256]::Create()
  try {
    $hash = [BitConverter]::ToString($sha256.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()
  }
  finally { $sha256.Dispose() }
  return ('{0}:{1}' -f $bytes.Length, $hash)
}

function Assert-BorrowingGitIgnoreState {
  param([string]$TemplateRoot, [string]$RelativePath, [bool]$ExpectedIgnored)
  & git -C $TemplateRoot check-ignore --no-index --quiet -- $RelativePath
  $actualIgnored = $LASTEXITCODE -eq 0
  Assert-CzxtEqual $ExpectedIgnored $actualIgnored ("gitignore state for {0}" -f $RelativePath)
}

function New-BorrowingProtectedFixture {
  return @{
    '借鉴区\来源\existing\git-20260718-abcdef123456\来源版本卡.md' =
      [Text.Encoding]::UTF8.GetBytes("source={{PROJECT_NAME}}`nroot={{PROJECT_ROOT}}`n")
    '借鉴区\来源\existing\git-20260718-abcdef123456\capture.local.json' =
      [Text.Encoding]::UTF8.GetBytes('{"root":"{{PROJECT_ROOT}}"}')
    '借鉴区\来源\existing\git-20260718-abcdef123456\快照\payload.ps1' =
      $script:CzxtUtf8Bom.GetBytes("Write-Output '{{PROJECT_NAME}}'`n")
    '借鉴区\来源\existing\git-20260718-abcdef123456\快照\payload.json' =
      [Text.Encoding]::UTF8.GetBytes('{"name":"{{PROJECT_NAME}}"}')
    '借鉴区\来源\existing\git-20260718-abcdef123456\快照\payload.md' =
      [Text.Encoding]::UTF8.GetBytes("# {{PROJECT_NAME}}`n")
    '借鉴区\事项\borrow-20260718-existing\借鉴卡.md' =
      [Text.Encoding]::UTF8.GetBytes("item={{PROJECT_NAME}}`n")
    '借鉴区\事项\borrow-20260718-existing\证据\raw\page.md' =
      [Text.Encoding]::UTF8.GetBytes("raw={{PROJECT_ROOT}}`n")
  }
}
