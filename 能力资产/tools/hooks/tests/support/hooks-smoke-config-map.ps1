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

function Get-CodexHookDispatchName {
  param([string]$Command)
  $pattern = '\A(?:pwsh|powershell\.exe) -NoProfile -NonInteractive -ExecutionPolicy Bypass -OutputFormat Text -EncodedCommand ([A-Za-z0-9+/=]+)\z'
  if ($Command -cmatch $pattern) {
    try {
      $bootstrap = [Text.Encoding]::Unicode.GetString(
        [Convert]::FromBase64String($matches[1]))
    }
    catch { return "" }
    if ($bootstrap -cmatch '& \$dispatcher -Hook ''([a-z-]+)''') {
      return $matches[1]
    }
  }
  return ""
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
    [string]$DispatchName,
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

  if ($Runtime -eq "Codex") {
    Assert-True ($hook.command -and $hook.commandWindows) "$Label $Event should define command and commandWindows"
    foreach ($field in @("command", "commandWindows")) {
      $actualDispatch = Get-CodexHookDispatchName ([string]$hook.$field)
      Assert-True ($actualDispatch -ceq $DispatchName) `
        "$Label $Event $field dispatch drift: $actualDispatch != $DispatchName"
      Assert-True (-not ([string]$hook.$field).Contains('{{PROJECT_ROOT')) `
        "$Label $Event $field must not retain an unresolved project-root placeholder"
      Assert-True (-not ([string]$hook.$field).Contains('"')) `
        "$Label $Event $field must remain quote-free for the Windows cmd hook runner"
      Assert-True (-not ([string]$hook.$field).Contains('git ')) `
        "$Label $Event $field must not bind dispatch to a Git repository root"
    }
  } else {
    $expected = Normalize-HookPath $ExpectedScript
    $actual = Normalize-HookPath (Get-HookScriptPath $hook)
    Assert-True ($actual -eq $expected) "$Label $Event script drift: $actual != $expected"
    Assert-True ([string]$hook.command -match 'powershell(\.exe)?$') "$Label $Event command should be powershell.exe"
    Assert-True (@($hook.args) -contains "-File") "$Label $Event args should include -File"
  }
}
