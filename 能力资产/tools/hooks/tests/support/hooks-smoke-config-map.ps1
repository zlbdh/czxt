$ErrorActionPreference = "Stop"

function Get-HookScriptPath {
  param([object]$Hook)

  if ($Hook.args) {
    $args = @($Hook.args)
    for ($i = 0; $i -lt $args.Count - 1; $i++) {
      if ([string]$args[$i] -eq "-File") { return [string]$args[$i + 1] }
    }
  }
  foreach ($field in @("commandWindows", "command")) {
    $path = Get-HookScriptPathFromCommand ([string]$Hook.$field)
    if ($path) { return $path }
  }
  return $null
}

function Get-HookScriptPathFromCommand {
  param([string]$Command)
  if ($Command -match '-File\s+"([^"]+\.ps1)"') { return $matches[1] }
  return $null
}

function Normalize-HookPath {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
  if ($script:HooksSmokeRoot) {
    $rootWin = [System.IO.Path]::GetFullPath($script:HooksSmokeRoot)
    $rootPosix = $rootWin -replace '\\','/'
    $Path = $Path.Replace("{{PROJECT_ROOT_POSIX}}", $rootPosix).Replace("{{PROJECT_ROOT}}", $rootWin)
  }
  return ([System.IO.Path]::GetFullPath(($Path -replace '/', '\'))).ToLowerInvariant()
}

function Assert-HookMapsTo {
  param(
    [object]$Hooks,
    [string]$Event,
    [string]$ExpectedScript,
    [string]$Label,
    [string]$Matcher = "",
    [int]$Timeout,
    [string]$StatusMessage,
    [ValidateSet("Codex", "Claude")]
    [string]$Runtime
  )

  $prop = $Hooks.PSObject.Properties[$Event]
  Assert-True ($null -ne $prop) "$Label missing event $Event"
  $entries = @($prop.Value)
  Assert-True ($entries.Count -eq 1) "$Label $Event should have exactly one matcher entry"
  $entry = $entries[0]
  if ($Matcher) {
    Assert-True ([string]$entry.matcher -eq $Matcher) "$Label $Event matcher drift"
  } else {
    Assert-True ([string]::IsNullOrWhiteSpace([string]$entry.matcher)) "$Label $Event should not declare matcher"
  }
  $hooks = @($entry.hooks)
  Assert-True ($hooks.Count -eq 1) "$Label $Event should have exactly one command hook"
  $hook = $hooks[0]
  Assert-True ([string]$hook.type -eq "command") "$Label $Event hook type drift"
  Assert-True ([int]$hook.timeout -eq $Timeout) "$Label $Event timeout drift"
  Assert-True ([string]$hook.statusMessage -eq $StatusMessage) "$Label $Event statusMessage drift"

  $expected = Normalize-HookPath $ExpectedScript
  $actual = Normalize-HookPath (Get-HookScriptPath $hook)
  Assert-True ($actual -eq $expected) "$Label $Event script drift: $actual != $expected"

  if ($Runtime -eq "Codex") {
    Assert-True ($hook.command -and $hook.commandWindows) "$Label $Event should define command and commandWindows"
    foreach ($field in @("command", "commandWindows")) {
      $fieldActual = Normalize-HookPath (Get-HookScriptPathFromCommand ([string]$hook.$field))
      Assert-True ($fieldActual -eq $expected) "$Label $Event $field script drift: $fieldActual != $expected"
    }
  } else {
    Assert-True ([string]$hook.command -match 'powershell(\.exe)?$') "$Label $Event command should be powershell.exe"
    Assert-True (@($hook.args) -contains "-File") "$Label $Event args should include -File"
  }
}
