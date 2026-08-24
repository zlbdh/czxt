[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-web-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:WebJsonReady = $false
  Invoke-CzxtContract 'capture strict Web JSON helper exists' {
    Import-BorrowingWebJsonTestModules
    $script:WebJsonReady = $true
  }
  if ($script:WebJsonReady) {
    Invoke-CzxtContract 'strict Web JSON normalizes URL and emits one canonical byte sequence' {
      $input = ConvertTo-BorrowingFixtureUtf8 (Get-BorrowingValidWebMetadataText)
      $metadata = Read-BorrowingStrictWebMetadata -Bytes $input
      Assert-CzxtEqual 'https://example.invalid/b' $metadata.OriginalUrl 'normalized original URL'
      Assert-CzxtEqual 'https://example.invalid/b' $metadata.FinalUrl 'normalized final URL'
      Assert-CzxtEqual 0 $metadata.RedirectChain.Count 'redirect count'
      $expected = '{"schema":"borrowing-web-response/v1","original_url":"https://example.invalid/b",' +
        '"final_url":"https://example.invalid/b","redirect_chain":[],"status_code":200,' +
        '"mime":"application/octet-stream","charset":null,"etag":null,"last_modified":null}' + "`n"
      $actual = ConvertTo-BorrowingCanonicalWebMetadataBytes -Metadata $metadata
      Assert-CzxtEqual $expected ([Text.Encoding]::UTF8.GetString($actual)) 'canonical metadata bytes'
    }

    Invoke-CzxtContract 'strict Web JSON accepts only integer number tokens in exact ranges' {
      foreach ($token in @('-200', '0200', '200.0', '2e2', '"200"', '+200', '600')) {
        $bytes = ConvertTo-BorrowingFixtureUtf8 `
          (Get-BorrowingValidWebMetadataText -StatusCode $token)
        Assert-BorrowingFailureCode {
          Read-BorrowingStrictWebMetadata -Bytes $bytes
        } 'input' 'source-boundary'
      }
      foreach ($token in @('299', '304', '400', '0301', '301.0', '3e2', '"301"')) {
        $chain = '[{"status_code":' + $token + ',"location_url":"https://example.invalid/final"}]'
        $bytes = ConvertTo-BorrowingFixtureUtf8 (Get-BorrowingValidWebMetadataText `
            -OriginalUrl 'https://example.invalid/start' `
            -FinalUrl 'https://example.invalid/final' -RedirectChain $chain)
        Assert-BorrowingFailureCode {
          Read-BorrowingStrictWebMetadata -Bytes $bytes
        } 'input' 'source-boundary'
      }
    }

    Invoke-CzxtContract 'strict Web JSON rejects BOM duplicate escaped keys trailing data and surrogates' {
      $valid = Get-BorrowingValidWebMetadataText
      $invalid = @(
        [byte[]]([byte[]](0xEF, 0xBB, 0xBF) + (ConvertTo-BorrowingFixtureUtf8 $valid)),
        (ConvertTo-BorrowingFixtureUtf8 ($valid.TrimEnd('}') + ',"status\u005fcode":201}')),
        (ConvertTo-BorrowingFixtureUtf8 ($valid + '{}')),
        (ConvertTo-BorrowingFixtureUtf8 ($valid.Replace('"etag":null', '"etag":"\uD800"'))),
        [byte[]](0x7B, 0xFF, 0x7D)
      )
      foreach ($bytes in $invalid) {
        Assert-BorrowingFailureCode {
          Read-BorrowingStrictWebMetadata -Bytes ([byte[]]$bytes)
        } 'input' 'source-boundary'
      }
    }

    Invoke-CzxtContract 'strict Web JSON keeps null distinct and canonicalizes Unicode scalars' {
      $text = Get-BorrowingValidWebMetadataText -Charset '"null"' `
        -Etag '"e\u0301|\u0085\u2028\uD83D\uDE00"'
      $metadata = Read-BorrowingStrictWebMetadata -Bytes (ConvertTo-BorrowingFixtureUtf8 $text)
      Assert-CzxtEqual 'null' $metadata.Charset 'string null value'
      Assert-CzxtTrue ($null -eq $metadata.LastModified) 'JSON null value'
      $canonical = [Text.Encoding]::UTF8.GetString(
        (ConvertTo-BorrowingCanonicalWebMetadataBytes $metadata)
      )
      Assert-CzxtTrue $canonical.Contains('"charset":"null"') 'string null projection'
      Assert-CzxtTrue $canonical.Contains('é\u007C\u0085\u2028😀') 'Unicode canonical projection'
    }

    Invoke-CzxtContract 'strict Web JSON enforces MIME URL redirect topology and fixed redirect limit' {
      foreach ($mime in @('Text/Plain', 'text/plain; charset=utf-8', ' text/plain', 'text/plain|x', 'text/plain`x')) {
        Assert-BorrowingFailureCode {
          Read-BorrowingStrictWebMetadata -Bytes (ConvertTo-BorrowingFixtureUtf8 `
              (Get-BorrowingValidWebMetadataText -Mime $mime))
        } 'input' 'source-boundary'
      }
      $chainItems = @()
      for ($index = 0; $index -lt 11; $index++) {
        $chainItems += '{"status_code":301,"location_url":"https://example.invalid/' + $index + '"}'
      }
      $bytes = ConvertTo-BorrowingFixtureUtf8 (Get-BorrowingValidWebMetadataText `
          -OriginalUrl 'https://example.invalid/start' -FinalUrl 'https://example.invalid/10' `
          -RedirectChain ('[' + ($chainItems -join ',') + ']'))
      Assert-BorrowingFailureCode {
        Read-BorrowingStrictWebMetadata -Bytes $bytes
      } 'input' 'resource-limit'
    }

    Invoke-CzxtContract 'strict Web JSON rejects credentials from every tracked text projection' {
      $token = 'glpat-1234567890abcdefghij'
      $credentialInputs = @(
        (Get-BorrowingValidWebMetadataText -OriginalUrl ('https://example.invalid/' + $token) `
          -FinalUrl ('https://example.invalid/' + $token)),
        (Get-BorrowingValidWebMetadataText -OriginalUrl 'https://example.invalid/start' `
          -FinalUrl ('https://example.invalid/' + $token) `
          -RedirectChain ('[{"status_code":301,"location_url":"https://example.invalid/' +
            $token + '"}]')),
        (Get-BorrowingValidWebMetadataText -Charset '"Bearer fixture-secret-token"'),
        (Get-BorrowingValidWebMetadataText -Charset '"X-API-Key: fixture-secret-value"'),
        (Get-BorrowingValidWebMetadataText `
          -Etag '"{\"api_key\":\"fixture-secret-value\"}"'),
        (Get-BorrowingValidWebMetadataText `
          -Etag '"{\"X-API-Key\":\"fixture-secret-value\"}"'),
        (Get-BorrowingValidWebMetadataText `
          -LastModified '"api_key%2525253Dfixture-secret-value"'),
        (Get-BorrowingValidWebMetadataText `
          -LastModified '"approved%252525253Dscope"'),
        (Get-BorrowingValidWebMetadataText -LastModified ('"' + $token + '"'))
      )
      foreach ($text in $credentialInputs) {
        Assert-BorrowingFailureCode {
          Read-BorrowingStrictWebMetadata -Bytes (ConvertTo-BorrowingFixtureUtf8 $text)
        } 'input' 'source-boundary'
      }
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
