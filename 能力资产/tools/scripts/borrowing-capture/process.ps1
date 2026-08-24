function global:ConvertTo-BorrowingWindowsArgument {
  param([AllowEmptyString()][string]$Value)
  if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') { return $Value }

  $builder = New-Object Text.StringBuilder
  [void]$builder.Append('"')
  $slashes = 0
  foreach ($character in $Value.ToCharArray()) {
    if ($character -eq '\') { $slashes++; continue }
    if ($character -eq '"') {
      [void]$builder.Append(('\' * (($slashes * 2) + 1)))
    }
    else { [void]$builder.Append(('\' * $slashes)) }
    [void]$builder.Append($character)
    $slashes = 0
  }
  [void]$builder.Append(('\' * ($slashes * 2)))
  [void]$builder.Append('"')
  return $builder.ToString()
}

$processModuleRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $processModuleRoot 'process-encoding.ps1')

function global:New-BorrowingProcessEnvironment {
  param([string[]]$RemovePrefixes = @(), [string[]]$RemoveNames = @(),
    [Collections.IDictionary]$Overrides = @{})
  $result = New-Object 'Collections.Generic.Dictionary[string,string]' `
    ([StringComparer]::OrdinalIgnoreCase)
  $inherited = [Environment]::GetEnvironmentVariables()
  foreach ($entry in $inherited.GetEnumerator()) {
    $name = [string]$entry.Key
    $remove = $false
    foreach ($prefix in $RemovePrefixes) {
      if ($name.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        $remove = $true; break
      }
    }
    if (-not $remove) {
      foreach ($blockedName in $RemoveNames) {
        if ([string]::Equals($name, $blockedName,
            [StringComparison]::OrdinalIgnoreCase)) { $remove = $true; break }
      }
    }
    if (-not $remove) { $result[$name] = [string]$entry.Value }
  }
  foreach ($entry in $Overrides.GetEnumerator()) {
    $result[[string]$entry.Key] = [string]$entry.Value
  }
  return $result
}

function global:New-BorrowingReadState {
  param([IO.Stream]$Stream, [int]$LimitBytes)
  $chunk = New-Object byte[] 8192
  return [pscustomobject]@{
    Stream = $Stream; Limit = $LimitBytes; Store = New-Object IO.MemoryStream
    Chunk = $chunk; Task = $Stream.ReadAsync($chunk, 0, $chunk.Length)
    Done = $false; Discard = $false
  }
}

function global:Update-BorrowingReadState {
  param($State)
  while (-not $State.Done -and $State.Task.IsCompleted) {
    try { $count = [int]$State.Task.Result }
    catch { $State.Done = $true; return 'read-failed' }
    if ($count -eq 0) { $State.Done = $true; return '' }
    if (-not $State.Discard) {
      if (($State.Store.Length + $count) -gt $State.Limit) {
        $State.Discard = $true
        $signal = 'overflow'
      }
      else { $State.Store.Write($State.Chunk, 0, $count) }
    }
    $State.Task = $State.Stream.ReadAsync($State.Chunk, 0, $State.Chunk.Length)
    if ($signal -eq 'overflow') { return $signal }
  }
  return ''
}

function global:Stop-BorrowingProcessTree {
  param([Diagnostics.Process]$Process)
  try {
    $taskkill = Join-Path $env:SystemRoot 'System32\taskkill.exe'
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $taskkill
    $info.Arguments = '/PID {0} /T /F' -f $Process.Id
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $killer = New-Object Diagnostics.Process
    $killer.StartInfo = $info
    if (-not $killer.Start()) { return $false }
    $outTask = $killer.StandardOutput.ReadToEndAsync()
    $errTask = $killer.StandardError.ReadToEndAsync()
    if (-not $killer.WaitForExit(10000)) {
      try { $killer.Kill() } catch {}
      return $false
    }
    [void]$outTask.Result
    [void]$errTask.Result
    return ($killer.ExitCode -eq 0 -or $Process.HasExited)
  }
  catch { return $false }
  finally {
    if ($null -ne $killer) { $killer.Dispose() }
  }
}

function global:Invoke-BorrowingBoundedProcess {
  param(
    [string]$Executable,
    [string[]]$ArgumentList = @(),
    [string]$WorkingDirectory, [Collections.IDictionary]$EnvironmentVariables,
    [int]$TimeoutMilliseconds, [int]$StdOutLimitBytes, [int]$StdErrLimitBytes,
    [switch]$AllowStdOutNul,
    [string]$Stage, [string]$TimeoutReasonCode, [string]$FailureReasonCode
  )
  if ($TimeoutMilliseconds -le 0 -or $StdOutLimitBytes -lt 0 -or `
      $StdErrLimitBytes -lt 0) {
    Throw-BorrowingFailure -Stage $Stage -ReasonCode $FailureReasonCode `
      -Reason 'process parameters are invalid'
  }

  $process = $null
  $failureCode = ''
  $processStarted = $false
  $processTimedOut = $false
  try {
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $Executable
    $info.Arguments = (($ArgumentList | ForEach-Object {
          ConvertTo-BorrowingWindowsArgument ([string]$_)
        }) -join ' ')
    $info.WorkingDirectory = $WorkingDirectory
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.EnvironmentVariables.Clear()
    foreach ($entry in $EnvironmentVariables.GetEnumerator()) {
      $info.EnvironmentVariables[[string]$entry.Key] = [string]$entry.Value
    }

    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    if (-not $process.Start()) { throw 'start returned false' }
    $processStarted = $true
    $process.StandardInput.Close()
    $outState = New-BorrowingReadState $process.StandardOutput.BaseStream $StdOutLimitBytes
    $errState = New-BorrowingReadState $process.StandardError.BaseStream $StdErrLimitBytes
    $cleanupDeadline = [DateTime]::MaxValue

    while ($true) {
      $outSignal = Update-BorrowingReadState $outState
      $errSignal = Update-BorrowingReadState $errState
      if ([string]::IsNullOrEmpty($failureCode)) {
        if ($outSignal -eq 'overflow' -or $errSignal -eq 'overflow') {
          $failureCode = $TimeoutReasonCode
        }
        elseif ($outSignal -eq 'read-failed' -or $errSignal -eq 'read-failed') {
          $failureCode = $FailureReasonCode
        }
        elseif ([DateTime]::UtcNow -ge $deadline) {
          $failureCode = $TimeoutReasonCode
          $processTimedOut = $true
        }
        if (-not [string]::IsNullOrEmpty($failureCode)) {
          if (-not (Stop-BorrowingProcessTree $process)) {
            $failureCode = $FailureReasonCode
          }
          $cleanupDeadline = [DateTime]::UtcNow.AddSeconds(10)
        }
      }

      $exited = $process.HasExited
      if ($exited -and $outState.Done -and $errState.Done) { break }
      if ([DateTime]::UtcNow -ge $cleanupDeadline) {
        try { if (-not $process.HasExited) { $process.Kill() } } catch {}
        $failureCode = $FailureReasonCode
        break
      }
      Start-Sleep -Milliseconds 5
    }
    if ($process.HasExited) { [void]$process.WaitForExit(10000) }
  }
  catch {
    if ([string]::IsNullOrEmpty($failureCode)) {
      $failureCode = $FailureReasonCode
      if ($null -ne $process) { [void](Stop-BorrowingProcessTree $process) }
    }
  }

  if (-not [string]::IsNullOrEmpty($failureCode)) {
    if ($null -ne $process) { $process.Dispose() }
    $exception = New-BorrowingFailureException -Stage $Stage `
      -ReasonCode $failureCode -Reason 'bounded process failed'
    $exception.Data['BorrowingProcessProjection'] = if (-not $processStarted) {
      'start-failed'
    }
    elseif ($processTimedOut) { 'timeout' }
    else { 'start-failed' }
    throw $exception
  }
  $exitCode = $process.ExitCode
  $process.Dispose()
  $outBytes = [byte[]]$outState.Store.ToArray()
  $errBytes = [byte[]]$errState.Store.ToArray()
  $stdout = ConvertFrom-BorrowingStrictUtf8 $outBytes $AllowStdOutNul.IsPresent `
    $Stage $FailureReasonCode
  $stderr = ConvertFrom-BorrowingStrictUtf8 $errBytes $false $Stage $FailureReasonCode
  return [pscustomobject][ordered]@{ ExitCode = $exitCode; StdOutBytes = $outBytes
    StdErrBytes = $errBytes; StdOut = $stdout; StdErr = $stderr }
}
