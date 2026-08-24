[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-web-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:WebHelperReady = $false
  Invoke-CzxtContract 'capture Web artifact helper exists' {
    Import-BorrowingWebTestModules
    $script:WebHelperReady = $true
  }
  if ($script:WebHelperReady) {
    Invoke-CzxtContract 'Web candidate preserves arbitrary raw bytes and hashes only raw bytes' {
      $root = New-BorrowingFixtureRoot 'web-artifact-root' project
      $directory = Join-Path $script:BorrowingCaptureFixtureRoot 'web-artifact-input'
      [void](New-Item -ItemType Directory -Path $directory)
      $raw = Join-Path $directory 'response.bin'
      $metadata = Join-Path $directory 'response.json'
      $rawBytes = [byte[]](0x00, 0xFF, 0xC3, 0x28, 0x0A)
      Write-BorrowingFixtureBytes $raw $rawBytes
      Write-BorrowingFixtureBytes $metadata `
        (ConvertTo-BorrowingFixtureUtf8 (Get-BorrowingValidWebMetadataText))
      $ops = New-BorrowingProductionWebOperations
      $input = Open-BorrowingWebInput $root $raw $metadata $ops
      $staging = Join-Path $root '借鉴区\来源\web-source\.staging-web'
      [void](New-Item -ItemType Directory -Path $staging -Force)
      $candidate = Write-BorrowingWebCandidate -Input $input -StagingPath $staging -Operations $ops
      Assert-CzxtEqual '89c548e945ab5cc9f6a53640ae828da2b269e28b32eee4af86dbb8634d6a434c' `
        $candidate.Fingerprint 'Web raw fingerprint'
      $actualRaw = [IO.File]::ReadAllBytes((Join-Path $staging '快照\response.bin'))
      Assert-CzxtEqual ([Convert]::ToBase64String($rawBytes)) `
        ([Convert]::ToBase64String($actualRaw)) 'Web raw artifact bytes'
      $canonical = [IO.File]::ReadAllBytes((Join-Path $staging '快照\response.metadata.json'))
      Assert-CzxtEqual $candidate.CanonicalMetadataBytes.Length $canonical.Length `
        'Web canonical metadata length'
      Assert-CzxtEqual (Get-BorrowingSha256Hex $candidate.CanonicalMetadataBytes) `
        (Get-BorrowingSha256Hex $canonical) 'Web canonical metadata bytes'
    }

    Invoke-CzxtContract 'Web helper contains no network or external-process command' {
      $path = Join-Path $script:BorrowingCaptureModuleRoot 'web.ps1'
      $tokens = $null
      $errors = $null
      $ast = [Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
      Assert-CzxtEqual 0 $errors.Count 'Web helper parse errors'
      $commands = @($ast.FindAll({
            param($node)
            $node -is [Management.Automation.Language.CommandAst]
          }, $true) | ForEach-Object { $_.GetCommandName() })
      foreach ($forbidden in @(
          'Invoke-WebRequest', 'Invoke-RestMethod', 'Start-Process', 'curl', 'wget'
        )) {
        Assert-CzxtEqual 0 @($commands | Where-Object { $_ -ieq $forbidden }).Count `
          ('forbidden Web command ' + $forbidden)
      }
      $text = [IO.File]::ReadAllText($path)
      Assert-CzxtTrue ($text -notmatch '(?i)HttpClient|WebClient') `
        'forbidden Web network API'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
