[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot '..\p4o-markdown-link-utils.ps1')

Invoke-CzxtContract 'P4o strips single-backtick inline code before link scanning' {
  $input = 'before `[a-z][missing]` after [visible][target]'
  $actual = Remove-CodeFences $input
  Assert-CzxtTrue (-not $actual.Contains('[a-z][missing]')) 'single inline code survived'
  Assert-CzxtTrue $actual.Contains('[visible][target]') 'visible reference was removed'
}

Invoke-CzxtContract 'P4o strips matching multi-backtick inline code only' {
  $input = 'before ``x ` [hidden][missing]`` after [visible](target.md)'
  $actual = Remove-CodeFences $input
  Assert-CzxtTrue (-not $actual.Contains('[hidden][missing]')) 'multi inline code survived'
  Assert-CzxtTrue $actual.Contains('[visible](target.md)') 'visible inline link was removed'
}

Invoke-CzxtContract 'P4o keeps unmatched backticks as ordinary text' {
  $input = 'unclosed ` marker [visible][target]'
  $actual = Remove-CodeFences $input
  Assert-CzxtTrue $actual.Contains('[visible][target]') 'unmatched delimiter hid visible link'
}

Invoke-CzxtContract 'P4o does not treat an escaped backtick as a code opener' {
  $input = 'escaped ' + [char]0x5C + [char]0x60 + ' marker [visible][target] ` tail'
  $actual = Remove-CodeFences $input
  Assert-CzxtTrue $actual.Contains('[visible][target]') 'escaped delimiter hid visible link'
}

Complete-CzxtContracts
