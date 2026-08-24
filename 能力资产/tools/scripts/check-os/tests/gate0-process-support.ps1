$ErrorActionPreference = 'Stop'

$script:CzxtProcessUtf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Quote-CzxtProcessArgument {
  param([string]$Value)
  return '"' + $Value.Replace('"', '\"') + '"'
}

function Receive-CzxtAsyncText {
  param([object]$Task, [string]$Name, [int]$TimeoutMilliseconds = 5000)
  try {
    if (-not $Task.Wait($TimeoutMilliseconds)) {
      throw ('{0} task did not finish within {1} ms' -f $Name, $TimeoutMilliseconds)
    }
    return $Task.GetAwaiter().GetResult()
  }
  catch {
    throw ('{0} task cleanup failed: {1}' -f $Name, $_.Exception.Message)
  }
}

function Stop-CzxtTimedOutProcessTree {
  param([Diagnostics.Process]$Process, [object]$StdOutTask, [object]$StdErrTask)
  $issues = New-Object 'Collections.Generic.List[string]'
  $targetPid = $Process.Id
  $taskkillPath = Join-Path $env:SystemRoot 'System32\taskkill.exe'
  $killer = $null
  try {
    if (-not (Test-Path -LiteralPath $taskkillPath -PathType Leaf)) {
      throw ('taskkill.exe is missing: {0}' -f $taskkillPath)
    }
    $killInfo = New-Object Diagnostics.ProcessStartInfo
    $killInfo.FileName = $taskkillPath
    $killInfo.Arguments = '/PID {0} /T /F' -f $targetPid
    $killInfo.UseShellExecute = $false
    $killInfo.CreateNoWindow = $true
    $killer = New-Object Diagnostics.Process
    $killer.StartInfo = $killInfo
    [void]$killer.Start()
    if (-not $killer.WaitForExit(10000)) {
      $issues.Add(('taskkill timed out for PID {0}' -f $targetPid))
      try {
        $killer.Kill()
        if (-not $killer.WaitForExit(2000)) { $issues.Add('taskkill process did not exit after Kill') }
      }
      catch { $issues.Add(('taskkill process cleanup failed: {0}' -f $_.Exception.Message)) }
    } elseif ($killer.ExitCode -ne 0) {
      $issues.Add(('taskkill exit {0} for PID {1}' -f $killer.ExitCode, $targetPid))
    }
  }
  catch { $issues.Add(('process-tree termination failed for PID {0}: {1}' -f $targetPid, $_.Exception.Message)) }
  finally { if ($null -ne $killer) { $killer.Dispose() } }

  try {
    if (-not $Process.WaitForExit(10000)) {
      $issues.Add(('target PID {0} remained alive after taskkill /T /F' -f $targetPid))
    }
  }
  catch { $issues.Add(('target PID {0} exit verification failed: {1}' -f $targetPid, $_.Exception.Message)) }
  foreach ($entry in @(@('stdout', $StdOutTask), @('stderr', $StdErrTask))) {
    try { [void](Receive-CzxtAsyncText -Task $entry[1] -Name $entry[0] -TimeoutMilliseconds 5000) }
    catch { $issues.Add($_.Exception.Message) }
  }
  return @($issues)
}

function Invoke-CzxtPowerShell {
  param(
    [string]$ScriptPath,
    [string[]]$ScriptArguments = @(),
    [int]$TimeoutMilliseconds = 120000
  )
  $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + $ScriptArguments
  $startInfo = New-Object Diagnostics.ProcessStartInfo
  $startInfo.FileName = 'powershell.exe'
  $startInfo.Arguments = (($arguments | ForEach-Object { Quote-CzxtProcessArgument ([string]$_) }) -join ' ')
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.StandardOutputEncoding = $script:CzxtProcessUtf8NoBom
  $startInfo.StandardErrorEncoding = $script:CzxtProcessUtf8NoBom
  $process = New-Object Diagnostics.Process
  $process.StartInfo = $startInfo
  try {
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutMilliseconds)) {
      $cleanupIssues = @(Stop-CzxtTimedOutProcessTree -Process $process `
        -StdOutTask $stdoutTask -StdErrTask $stderrTask)
      $cleanup = if ($cleanupIssues.Count -eq 0) { 'cleanup completed' } else {
        'cleanup failures: ' + ($cleanupIssues -join '; ')
      }
      throw ('process timed out after {0} ms: {1}; {2}' -f $TimeoutMilliseconds, $ScriptPath, $cleanup)
    }
    $stdout = Receive-CzxtAsyncText -Task $stdoutTask -Name 'stdout'
    $stderr = Receive-CzxtAsyncText -Task $stderrTask -Name 'stderr'
    $exitCode = $process.ExitCode
  }
  finally { $process.Dispose() }
  return [pscustomobject]@{ ExitCode = $exitCode; StdOut = $stdout; StdErr = $stderr }
}
