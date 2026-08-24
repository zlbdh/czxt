[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function New-BorrowingRequestMap {
  param([string]$SourceType = 'Local')
  $map = @{
    Root = 'C:\fixture'; SourceType = $SourceType; SourceId = 'safe-source'
  }
  switch ($SourceType.ToLowerInvariant()) {
    'local' {
      $map.LocalPath = 'C:\fixture-source'
      $map.LocalDisplayName = 'fixture-source'
    }
    'git' {
      $map.GitLocator = 'https://example.invalid/owner/repo.git'
      $map.GitRef = 'refs/heads/main'
      $map.AccessPolicy = 'source-read-only'
      $map.NetworkPolicy = 'source-read-only'
      $map.AuthorizationTime = '2026-07-19T08:00:00+08:00'
      $map.AuthorizationSource = 'approved-fixture'
      $map.AuthorizationScope = 'current-capture'
    }
    'web' {
      $map.WebRawBytesPath = 'C:\fixture-response.bin'
      $map.WebResponseMetadataPath = 'C:\fixture-response.json'
      $map.AccessPolicy = 'source-read-only'
      $map.NetworkPolicy = 'source-read-only'
      $map.AuthorizationTime = '2026-07-19T08:00:00+08:00'
      $map.AuthorizationSource = 'approved-fixture'
      $map.AuthorizationScope = 'current-capture'
    }
  }
  return $map
}

Initialize-BorrowingCaptureFixture
try {
  $script:CommonHelperReady = $false
  Invoke-CzxtContract 'capture common helper exists with request and identifier primitives' {
    Import-BorrowingCaptureModules @('common')
    foreach ($name in @(
        'Assert-BorrowingSafeIdentifier', 'Resolve-BorrowingCaptureRequest',
        'Get-BorrowingSha256Hex', 'ConvertTo-BorrowingCanonicalJsonString',
        'Get-BorrowingCredentialInspectionVariants', 'Test-BorrowingCredentialMaterial'
      )) { Assert-BorrowingCommandExists $name }
    $script:CommonHelperReady = $true
  }

  if ($script:CommonHelperReady) {
    Invoke-CzxtContract 'identifier validator accepts only the exact Windows-safe 1-to-128 grammar' {
      foreach ($value in @('a', 'a_b', 'a-b.c', ('a' + ('x' * 126) + 'z'))) {
        Assert-CzxtEqual $value (Assert-BorrowingSafeIdentifier -Value $value -FieldName 'SourceId') `
          ('valid identifier ' + $value.Length)
      }
      foreach ($value in @(
          '', ' A', 'UPPER', '.hidden', '-leading', 'trailing.', 'trailing ',
          'con', 'CON.txt', 'prn.data', 'aux', 'nul', 'com1.log', 'COM9',
          'lpt1.txt', 'LPT9', ('a' + ('x' * 128)), "a`nb", '中文'
        )) {
        Assert-BorrowingFailureCode {
          Assert-BorrowingSafeIdentifier -Value $value -FieldName 'SourceId'
        } 'input' 'invalid-parameters'
      }
    }

    Invoke-CzxtContract 'request resolver applies the exact three-source matrix without trimming' {
      foreach ($entry in @(@('Local', 'local'), @('gIt', 'git'), @('WEB', 'web'))) {
        $request = Resolve-BorrowingCaptureRequest -BoundParameters `
          (New-BorrowingRequestMap $entry[0])
        Assert-CzxtEqual $entry[1] $request.SourceType 'normalized source type'
        Assert-CzxtEqual 'safe-source' $request.SourceId 'normalized source id'
      }
      foreach ($invalidType in @(' Local', 'Local ', 'ftp', '')) {
        Assert-BorrowingFailureCode {
          Resolve-BorrowingCaptureRequest -BoundParameters `
            (New-BorrowingRequestMap $invalidType)
        } 'input' 'invalid-parameters'
      }
      $forbidden = New-BorrowingRequestMap 'Local'
      $forbidden.GitLocator = $null
      Assert-BorrowingFailureCode {
        Resolve-BorrowingCaptureRequest -BoundParameters $forbidden
      } 'input' 'invalid-parameters'
      $missing = New-BorrowingRequestMap 'Web'
      [void]$missing.Remove('WebRawBytesPath')
      Assert-BorrowingFailureCode {
        Resolve-BorrowingCaptureRequest -BoundParameters $missing
      } 'input' 'invalid-parameters'
    }

    Invoke-CzxtContract 'request resolver keeps nine permission dimensions independent' {
      $local = Resolve-BorrowingCaptureRequest -BoundParameters (New-BorrowingRequestMap 'Local')
      $expected = @{
        RightsStatus = 'unverified'; AccessPolicy = 'local-read-only'
        ReuseScope = 'inspect-and-analyze-only'; ExecutionPolicy = 'deny'
        NetworkPolicy = 'deny'; StoragePolicy = 'local-only'
        DistributionPolicy = 'deny'; UpstreamWritePolicy = 'deny'; AutoRefresh = 'false'
      }
      foreach ($key in $expected.Keys) {
        Assert-CzxtEqual $expected[$key] $local.$key ('Local default ' + $key)
      }

      $git = Resolve-BorrowingCaptureRequest -BoundParameters (New-BorrowingRequestMap 'Git')
      Assert-CzxtEqual 'source-read-only' $git.AccessPolicy 'Git read access'
      Assert-CzxtEqual 'source-read-only' $git.NetworkPolicy 'Git read network'
      Assert-CzxtEqual 'deny' $git.ExecutionPolicy 'Git execution remains denied'
      Assert-CzxtEqual 'deny' $git.UpstreamWritePolicy 'Git upstream write remains denied'

      $missingEvidence = New-BorrowingRequestMap 'Git'
      [void]$missingEvidence.Remove('AuthorizationScope')
      Assert-BorrowingFailureCode {
        Resolve-BorrowingCaptureRequest -BoundParameters $missingEvidence
      } 'input' 'invalid-permissions'

      $unneededEvidence = New-BorrowingRequestMap 'Local'
      $unneededEvidence.AuthorizationTime = '2026-07-19T00:00:00Z'
      $unneededEvidence.AuthorizationSource = 'fixture'
      $unneededEvidence.AuthorizationScope = 'current-capture'
      Assert-BorrowingFailureCode {
        Resolve-BorrowingCaptureRequest -BoundParameters $unneededEvidence
      } 'input' 'invalid-permissions'

      $deviation = New-BorrowingRequestMap 'Local'
      $deviation.StoragePolicy = 'tracked-content-approved'
      Assert-BorrowingFailureCode {
        Resolve-BorrowingCaptureRequest -BoundParameters $deviation
      } 'input' 'invalid-permissions'
    }

    Invoke-CzxtContract 'credential detector inspects the value produced by the fourth URL decode' {
      $variants = @(Get-BorrowingCredentialInspectionVariants `
          'api_key%2525253Dfixture-secret-value')
      Assert-CzxtTrue ($variants -ccontains 'api_key=fixture-secret-value') `
        'fourth URL decode output is absent from inspection variants'
      Assert-CzxtTrue `
        (Test-BorrowingCredentialMaterial 'api_key%2525253Dfixture-secret-value') `
        'four-layer encoded credential reached the tracked-value guard'
    }

    Invoke-CzxtContract 'credential detector fails closed when URL decoding does not stabilize' {
      $overLimit = 'approved=scope'
      for ($depth = 0; $depth -lt 5; $depth++) {
        $overLimit = [Uri]::EscapeDataString($overLimit)
      }
      Assert-CzxtTrue (Test-BorrowingCredentialMaterial $overLimit) `
        'over-limit encoded value reached the tracked-value guard'
    }

    Invoke-CzxtContract 'credential detector rejects X-API-Key assignment and quoted JSON forms' {
      foreach ($value in @(
          'X-API-Key: fixture-secret-value',
          '{"x-api-key":"fixture-secret-value"}',
          '{\"X-API-Key\":\"fixture-secret-value\"}'
        )) {
        Assert-CzxtTrue (Test-BorrowingCredentialMaterial $value) `
          ('X-API-Key credential reached the tracked-value guard: ' + $value)
      }
    }

    Invoke-CzxtContract 'credential detector rejects whitespace-separated sensitive keys' {
      foreach ($value in @(
          'api key = fixture-secret-value',
          '{"api key":"fixture-secret-value"}',
          'x api key: fixture-secret-value',
          'aws access key id = fixture-secret-value',
          'secret access key = fixture-secret-value',
          'api key%3Dfixture-secret-value',
          'api%20key%3Dfixture-secret-value',
          'api+key%3Dfixture-secret-value',
          '{"api\u0020key":"fixture-secret-value"}'
        )) {
        Assert-CzxtTrue (Test-BorrowingCredentialMaterial $value) `
          ('whitespace-separated credential key was allowed: ' + $value)
      }
    }

    Invoke-CzxtContract 'credential detector rejects nonempty explicit values starting with punctuation' {
      foreach ($value in @(
          '{"api_key":"?fixture-secret-value"}',
          '{"password":"#fixture-secret-value"}',
          'api_key=&fixture-secret-value',
          'password=;fixture-secret-value',
          'token=,fixture-secret-value'
        )) {
        Assert-CzxtTrue (Test-BorrowingCredentialMaterial $value) `
          ('punctuation-prefixed credential was allowed: ' + $value)
      }
    }

    Invoke-CzxtContract 'credential detector decodes JSON Unicode keys and valid surrogate pairs' {
      $encoded = '{"note":"\uD83D\uDE00","x-api\u002dkey":"fixture-secret-value"}'
      $pair = [string]::Concat([char]0xD83D, [char]0xDE00)
      $decoded = '{"note":"' + $pair + '","x-api-key":"fixture-secret-value"}'
      $variants = @(Get-BorrowingCredentialInspectionVariants $encoded)
      Assert-CzxtTrue ($variants -ccontains $decoded) `
        'valid surrogate pair and Unicode key were not decoded together'
      foreach ($value in @(
          $encoded,
          '{"api\u005fkey":"fixture-secret-value"}'
        )) {
        Assert-CzxtTrue (Test-BorrowingCredentialMaterial $value) `
          ('Unicode-escaped JSON credential reached the tracked-value guard: ' + $value)
      }
    }

    Invoke-CzxtContract 'credential detector fails closed on malformed JSON Unicode escapes' {
      foreach ($value in @(
          '{"api\u00G0key":"fixture-secret-value"}',
          '{"note":"\uD83D\u0041"}',
          '{"note":"\uDE00"}'
        )) {
        Assert-CzxtTrue (Test-BorrowingCredentialMaterial $value) `
          ('malformed JSON Unicode escape was allowed: ' + $value)
      }
    }

    Invoke-CzxtContract 'credential detector rejects embedded and JSON-escaped URI userinfo' {
      foreach ($value in @(
          '//user:fixture-secret@example.invalid/path',
          '{"url":"https://user:fixture-secret@example.invalid/path"}',
          'prefix https://user:fixture-secret@example.invalid/path suffix',
          '{"url":"https:\/\/user:fixture-secret@example.invalid/path"}'
        )) {
        Assert-CzxtTrue (Test-BorrowingCredentialMaterial $value) `
          ('URI userinfo reached the tracked-value guard: ' + $value)
      }
    }

    Invoke-CzxtContract 'authorization detector allows exact Basic and Bearer prose words' {
      foreach ($value in @(
          'Basic authentication disabled', 'Bearer authentication disabled',
          'Basic authorization disabled', 'Bearer authorization disabled',
          'Bearer authentication-enabled', 'Bearer authentication-enabled.',
          'Bearer authorization-based flow', 'Basic authorization-disabled.'
        )) {
        Assert-CzxtTrue (-not (Test-BorrowingCredentialMaterial $value)) `
          ('authorization prose was mistaken for a credential: ' + $value)
      }
    }

    Invoke-CzxtContract 'authorization detector rejects decodable Basic credentials containing colon' {
      foreach ($value in @(
          'Basic dXNlcjpwYXNz', 'Basic YTpi', 'Basic Og==',
          '(Basic YTpi)', 'Basic dXNlcjpwYXNz==='
        )) {
        Assert-CzxtTrue (Test-BorrowingCredentialMaterial $value) `
          ('real Basic credential was allowed: ' + $value)
      }
    }

    Invoke-CzxtContract 'authorization detector rejects opaque Bearer tokens including lowercase-only' {
      foreach ($value in @(
          'Bearer fixture-secret-token', 'Bearer abc', '(Bearer abcdef)',
          'Bearer abc===', 'Bearer abcdefghijklmnop',
          'Bearer eyJhbGciOiJIUzI1NiJ9.fixture.signature'
        )) {
        Assert-CzxtTrue (Test-BorrowingCredentialMaterial $value) `
          ('real Bearer credential was allowed: ' + $value)
      }
    }

    Invoke-CzxtContract 'request resolver rejects credential material before card creation' {
      $credentialCases = @(
        @{ Field = 'AuthorizationSource'; Value =
            'https://user:fixture-secret@example.invalid/approval' },
        @{ Field = 'AuthorizationScope'; Value =
            'https%3A%2F%2Fuser%3Afixture-secret%40example.invalid%2Fapproval' },
        @{ Field = 'AuthorizationSource'; Value = 'Bearer fixture-secret-token' },
        @{ Field = 'AuthorizationScope'; Value = 'api_key=fixture-secret-value' },
        @{ Field = 'AuthorizationSource'; Value =
            'api_key%2525253Dfixture-secret-value' },
        @{ Field = 'AuthorizationScope'; Value =
            'X-API-Key: fixture-secret-value' },
        @{ Field = 'AuthorizationSource'; Value =
            '{"api_key":"fixture-secret-value"}' },
        @{ Field = 'AuthorizationScope'; Value =
            '{\"X-API-Key\":\"fixture-secret-value\"}' },
        @{ Field = 'AuthorizationScope'; Value =
            '{"aws_access_key_id":"ASIAABCDEFGHIJKLMNOP"}' },
        @{ Field = 'AuthorizationSource'; Value =
            '{"aws_secret_access_key":"fixtureSecretKey0123456789/ABCDEFGHIJKLM"}' },
        @{ Field = 'AuthorizationScope'; Value =
            'glpat-1234567890abcdefghij' },
        @{ Field = 'AuthorizationSource'; Value =
            (('s' + 'k-') + 'fixture1234567890') }
      )
      foreach ($credentialCase in $credentialCases) {
        $map = New-BorrowingRequestMap 'Web'
        $map[$credentialCase.Field] = $credentialCase.Value
        Assert-BorrowingFailureCode {
          Resolve-BorrowingCaptureRequest -BoundParameters $map
        } 'input' 'invalid-permissions'
      }
      $identifierToken = 'glpat-1234567890abcdefghij'
      $sourceIdMap = New-BorrowingRequestMap 'Web'
      $sourceIdMap.SourceId = $identifierToken
      Assert-BorrowingFailureCode {
        Resolve-BorrowingCaptureRequest -BoundParameters $sourceIdMap
      } 'input' 'invalid-parameters'
      $displayNameMap = New-BorrowingRequestMap 'Local'
      $displayNameMap.LocalDisplayName = $identifierToken
      Assert-BorrowingFailureCode {
        Resolve-BorrowingCaptureRequest -BoundParameters $displayNameMap
      } 'input' 'invalid-parameters'
    }

    Invoke-CzxtContract 'common canonical bytes use lowercase SHA-256 and exact JSON escaping' {
      $bytes = [Text.Encoding]::UTF8.GetBytes('abc')
      Assert-CzxtEqual `
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' `
        (Get-BorrowingSha256Hex -Bytes $bytes) 'SHA-256 bytes'
      Assert-CzxtEqual '"a\"b\\c\u007C\u0085\u2028😀"' `
        (ConvertTo-BorrowingCanonicalJsonString "a`"b\c|$([char]0x85)$([char]0x2028)😀") `
        'canonical JSON string'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
