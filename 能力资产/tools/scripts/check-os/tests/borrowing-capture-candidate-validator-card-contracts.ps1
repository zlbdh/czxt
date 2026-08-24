$ErrorActionPreference = 'Stop'

function Invoke-BcvStrictCardContracts {
  Invoke-CzxtContract 'frontmatter parser fixes all 18 keys and canonical bytes' {
    $capture = New-BcvCapture -Root (New-BcvRoot 'frontmatter') `
      -SourceType local -WithCache
    $card = Read-BorrowingFrontmatter `
      -Path (Join-Path $capture.CaptureDirectory '来源版本卡.md')
    Assert-CzxtEqual 18 @($card.FieldOrder).Count 'frontmatter field count'
    Assert-CzxtEqual 'schema' $card.FieldOrder[0] 'frontmatter first key'
    Assert-CzxtEqual 'auto_refresh' $card.FieldOrder[17] 'frontmatter last key'
    Assert-CzxtEqual 'borrowing-source/v1' $card.schema 'frontmatter schema'
  }

  foreach ($case in @(
      @{ Name = 'duplicate key'; Change = {
          param($text) $text -replace '(?m)^capture_id:.*$', 'source_id: duplicate'
        } },
      @{ Name = 'unknown key'; Change = {
          param($text) $text -replace '(?m)^capture_id:', 'unknown_id:'
        } },
      @{ Name = 'missing key'; Change = {
          param($text) $text -replace '(?m)^capture_id:.*\n', ''
        } },
      @{ Name = 'reordered keys'; Change = {
          param($text)
          $source = [regex]::Match($text, '(?m)^source_id:.*$').Value
          $capture = [regex]::Match($text, '(?m)^capture_id:.*$').Value
          ($text -replace [regex]::Escape($source), '__SOURCE__' `
            -replace [regex]::Escape($capture), $source) -replace '__SOURCE__', $capture
        } }
    )) {
    Invoke-CzxtContract ('frontmatter rejects ' + $case.Name) {
      $capture = New-BcvCapture -Root (New-BcvRoot ('fm-' + [guid]::NewGuid().ToString('N'))) `
        -SourceType local -WithCache
      Set-BcvCardText $capture $case.Change
      Assert-BcvCandidateInvalid $capture
    }
  }

  Invoke-CzxtContract 'frontmatter rejects BOM and CRLF encodings' {
    foreach ($mode in @('bom', 'crlf')) {
      $capture = New-BcvCapture -Root (New-BcvRoot ('encoding-' + $mode)) `
        -SourceType local -WithCache
      $path = Join-Path $capture.CaptureDirectory '来源版本卡.md'
      [byte[]]$bytes = [IO.File]::ReadAllBytes($path)
      if ($mode -eq 'bom') { $bytes = [byte[]](0xEF, 0xBB, 0xBF) + $bytes }
      else {
        $text = [Text.Encoding]::UTF8.GetString($bytes).Replace("`n", "`r`n")
        $bytes = [Text.Encoding]::UTF8.GetBytes($text)
      }
      [IO.File]::WriteAllBytes($path, $bytes)
      Assert-BcvCandidateInvalid $capture
    }
  }

  foreach ($case in @(
      @{ Name = 'static body mutation'; Type = 'local'; Change = {
          param($text) $text.Replace('# 来源版本卡', '# 非法版本卡')
        } },
      @{ Name = 'unknown status'; Type = 'local'; Change = {
          param($text) $text.Replace('capture_status: ready', 'capture_status: broken')
        } },
      @{ Name = 'permission mismatch'; Type = 'local'; Change = {
          param($text) $text.Replace('reuse_scope: inspect-and-analyze-only',
            'reuse_scope: adapt-internal-approved')
        } },
      @{ Name = 'Git object length mismatch'; Type = 'git'; Change = {
          param($text) $text.Replace('| refs/heads/main | branch | sha1 |',
            '| refs/heads/main | branch | sha256 |')
        } },
      @{ Name = 'Git non-full ref'; Type = 'git'; Change = {
          param($text) $text.Replace('| refs/heads/main | branch |', '| HEAD | branch |')
        } },
      @{ Name = 'Git credential locator'; Type = 'git'; Change = {
          param($text) $text.Replace(
            'canonical_locator: https://example.invalid/owner/repo.git',
            'canonical_locator: https://user@example.invalid/owner/repo.git')
        } },
      @{ Name = 'fingerprint field tampering'; Type = 'local'; Change = {
          param($text)
          $match = [regex]::Match($text, '(?m)^fingerprint: ([0-9a-f]{64})$')
          $replacement = $match.Groups[1].Value.Substring(0, 63) +
            $(if ($match.Groups[1].Value[63] -eq '0') { '1' } else { '0' })
          $text.Substring(0, $match.Groups[1].Index) + $replacement +
            $text.Substring($match.Groups[1].Index + 64)
        } },
      @{ Name = 'legacy Web algorithm'; Type = 'web'; Change = {
          param($text) $text.Replace('fingerprint_algorithm: sha256-raw-bytes-v1',
            'fingerprint_algorithm: sha256')
        } }
    )) {
    Invoke-CzxtContract ('source card rejects ' + $case.Name) {
      $capture = New-BcvCapture -Root (New-BcvRoot ('invalid-' + [guid]::NewGuid().ToString('N'))) `
        -SourceType $case.Type -WithCache:($case.Type -ne 'git')
      Set-BcvCardText $capture $case.Change
      Assert-BcvCandidateInvalid $capture
    }
  }
}
