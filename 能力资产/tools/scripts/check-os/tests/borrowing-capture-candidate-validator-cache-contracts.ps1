$ErrorActionPreference = 'Stop'

function Invoke-BcvCacheContracts {
  Invoke-CzxtContract 'local-state writer rejects credential material in persisted paths' {
    foreach ($secretPath in @(
        'C:\fixture\X-API-Key=fixture-secret-value\payload.bin',
        'C:\safe\(api_key=fixture-secret-value)\payload.bin',
        'C:\safe\password=#fixture-secret-value\payload.bin'
      )) {
      $state = [pscustomobject]@{ SourceType = 'local'; LocalSourcePath = $secretPath }
      Assert-BorrowingFailureCode {
        New-BorrowingCaptureLocalStateBytes -Input $state
      } 'candidate' 'candidate-invalid'
    }
  }

  Invoke-CzxtContract 'local-state reader rejects credential material in persisted paths' {
    $capture = New-BcvCapture -Root (New-BcvRoot 'cache-path-credential') `
      -SourceType local -WithCache
    foreach ($secretPath in @(
        'C:\fixture\X-API-Key=fixture-secret-value\payload.bin',
        'C:\safe\(api_key=fixture-secret-value)\payload.bin',
        'C:\safe\password=#fixture-secret-value\payload.bin'
      )) {
      $json = '{"schema":"borrowing-capture-local-state/v1","source_type":"local",' +
        '"local_source_path":' + (ConvertTo-BorrowingCanonicalJsonString $secretPath) +
        ',"web_raw_bytes_path":null,"web_response_metadata_path":null}' + "`n"
      $statePath = Join-Path $capture.CaptureDirectory 'capture.local.json'
      Write-BorrowingFixtureBytes $statePath ([Text.Encoding]::UTF8.GetBytes($json))
      Assert-CzxtTrue (-not (Test-BcvCaptureLocalState $statePath local)) `
        'credential-bearing local state was accepted by the direct reader'
      Assert-CzxtEqual 'Conflict' `
        (Get-BorrowingIgnoredCacheState $capture.CaptureDirectory local).State `
        'credential-bearing local state was accepted by cache validation'
    }
  }

  Invoke-CzxtContract 'ignored cache reports AllMissing Healthy and Conflict exactly' {
    $missing = New-BcvCapture -Root (New-BcvRoot 'cache-missing') -SourceType git
    $healthy = New-BcvCapture -Root (New-BcvRoot 'cache-healthy') `
      -SourceType local -WithCache
    Assert-CzxtEqual 'AllMissing' `
      (Get-BorrowingIgnoredCacheState $missing.CaptureDirectory git).State `
      'all cache members absent'
    Assert-CzxtEqual 'Healthy' `
      (Get-BorrowingIgnoredCacheState $healthy.CaptureDirectory local).State `
      'all cache members healthy'
    Remove-Item -LiteralPath (Join-Path $healthy.CaptureDirectory 'capture.local.json')
    Assert-CzxtEqual 'Conflict' `
      (Get-BorrowingIgnoredCacheState $healthy.CaptureDirectory local).State `
      'partial cache is conflict'
    $empty = New-BcvCapture -Root (New-BcvRoot 'cache-empty-parent') -SourceType web
    [void](New-Item -ItemType Directory -Path (Join-Path $empty.CaptureDirectory '快照'))
    Assert-CzxtEqual 'Conflict' `
      (Get-BorrowingIgnoredCacheState $empty.CaptureDirectory web).State `
      'existing empty snapshot is conflict'
    $driveRoot = New-BcvCapture -Root (New-BcvRoot 'cache-drive-root') `
      -SourceType local -WithCache
    $rootState = [pscustomobject]@{ SourceType = 'local'; LocalSourcePath = 'C:\' }
    Write-BorrowingFixtureBytes `
      (Join-Path $driveRoot.CaptureDirectory 'capture.local.json') `
      (New-BorrowingCaptureLocalStateBytes -Input $rootState)
    Assert-CzxtEqual 'Healthy' `
      (Get-BorrowingIgnoredCacheState $driveRoot.CaptureDirectory local).State `
      'canonical fixed-drive root local state is valid'
    [IO.File]::WriteAllText(
      (Join-Path $driveRoot.CaptureDirectory 'capture.local.json'), '{}')
    Assert-CzxtEqual 'Conflict' `
      (Get-BorrowingIgnoredCacheState $driveRoot.CaptureDirectory local).State `
      'damaged local state is conflict'
  }

  Invoke-CzxtContract 'ignored cache rejects unknown Local and Web structural members' {
    foreach ($fixture in @(
        @{ Name = 'local-extra-file'; Type = 'local'; Relative = '快照\unexpected.bin';
          Directory = $false },
        @{ Name = 'local-extra-directory'; Type = 'local'; Relative = '快照\unexpected';
          Directory = $true },
        @{ Name = 'web-extra-file'; Type = 'web'; Relative = '快照\unexpected.bin';
          Directory = $false },
        @{ Name = 'web-extra-directory'; Type = 'web'; Relative = '快照\unexpected';
          Directory = $true }
      )) {
      $capture = New-BcvCapture -Root (New-BcvRoot $fixture.Name) `
        -SourceType $fixture.Type -WithCache
      $extraPath = Join-Path $capture.CaptureDirectory $fixture.Relative
      if ($fixture.Directory) {
        [void](New-Item -ItemType Directory -Path $extraPath)
      }
      else { Write-BorrowingFixtureBytes $extraPath ([byte[]](0x78)) }
      Assert-CzxtEqual 'Conflict' `
        (Get-BorrowingIgnoredCacheState $capture.CaptureDirectory $fixture.Type).State `
        $fixture.Name
      Assert-BcvCandidateInvalid $capture
    }
  }

  Invoke-CzxtContract 'Local stored fingerprint covers manifest and content bytes' {
    $content = New-BcvCapture -Root (New-BcvRoot 'local-content-fingerprint') `
      -SourceType local -WithCache
    Assert-CzxtTrue (Test-BorrowingLocalStoredFingerprint `
        $content.CaptureDirectory $content.Artifact.Fingerprint) 'Local fingerprint valid'
    [IO.File]::AppendAllText((Join-Path $content.CaptureDirectory '快照\内容\a.txt'), 'x')
    Assert-CzxtTrue (-not (Test-BorrowingLocalStoredFingerprint `
          $content.CaptureDirectory $content.Artifact.Fingerprint)) `
      'Local content tampering rejected'
    $manifest = New-BcvCapture -Root (New-BcvRoot 'local-manifest-fingerprint') `
      -SourceType local -WithCache
    [IO.File]::AppendAllText((Join-Path $manifest.CaptureDirectory '快照\manifest.tsv'), 'x')
    Assert-CzxtTrue (-not (Test-BorrowingLocalStoredFingerprint `
          $manifest.CaptureDirectory $manifest.Artifact.Fingerprint)) `
      'Local manifest tampering rejected'
  }

  Invoke-CzxtContract 'Web stored fingerprint covers raw metadata and projected facts' {
    $broken = New-BcvCapture -Root (New-BcvRoot 'web-broken-metadata') `
      -SourceType web -WithCache
    Assert-CzxtTrue (Test-BorrowingWebStoredFingerprint `
        $broken.CaptureDirectory $broken.Artifact.Fingerprint) 'Web fingerprint valid'
    [IO.File]::WriteAllText(
      (Join-Path $broken.CaptureDirectory '快照\response.metadata.json'), '{broken')
    Assert-CzxtTrue (-not (Test-BorrowingWebStoredFingerprint `
          $broken.CaptureDirectory $broken.Artifact.Fingerprint)) `
      'Web metadata corruption rejected'

    $facts = New-BcvCapture -Root (New-BcvRoot 'web-fact-mismatch') `
      -SourceType web -WithCache
    $validated = Get-BorrowingValidatedSourceCandidate $facts.CaptureDirectory
    $metadataPath = Join-Path $facts.CaptureDirectory '快照\response.metadata.json'
    $metadataText = [IO.File]::ReadAllText($metadataPath).Replace(
      '"status_code":200', '"status_code":201')
    [IO.File]::WriteAllText(
      $metadataPath, $metadataText, (New-Object Text.UTF8Encoding($false)))
    Assert-CzxtTrue (Test-BorrowingWebStoredFingerprint `
        $facts.CaptureDirectory $facts.Artifact.Fingerprint) `
      'Web raw fingerprint remains valid after canonical metadata fact change'
    Assert-CzxtTrue (-not (Test-BorrowingStoredCaptureFingerprint $validated).IsValid) `
      'Web metadata facts must still match the card projection'
  }

  Invoke-CzxtContract 'full candidate validation rejects healthy-shaped damaged cache' {
    $capture = New-BcvCapture -Root (New-BcvRoot 'cache-damaged') `
      -SourceType local -WithCache
    [IO.File]::AppendAllText((Join-Path $capture.CaptureDirectory '快照\manifest.tsv'), 'x')
    Assert-BcvCandidateInvalid $capture
  }
}
