$ErrorActionPreference = 'Stop'

function New-CzxtInstallerTokenPattern {
  param([Collections.IDictionary]$Values)
  $names = @($Values.Keys | ForEach-Object { [regex]::Escape([string]$_) })
  return [regex]::new(('\{\{(?<name>' + ($names -join '|') + ')\}\}'))
}

function Expand-CzxtInstallerDataTokens {
  param([string]$Text, [Collections.IDictionary]$Values, [regex]$Pattern,
    [scriptblock]$EncodeValue)
  return $Pattern.Replace($Text, [Text.RegularExpressions.MatchEvaluator]{
    param($match)
    $value = [string]$Values[$match.Groups['name'].Value]
    if ($null -ne $EncodeValue) { return (& $EncodeValue $value) }
    return $value
  })
}

function ConvertTo-CzxtInstallerJsonData {
  param($Node, [Collections.IDictionary]$Values, [regex]$Pattern)
  if ($null -eq $Node) { return $null }
  if ($Node -is [string]) { return Expand-CzxtInstallerDataTokens $Node $Values $Pattern }
  if ($Node -is [Collections.IEnumerable] -and -not ($Node -is [Collections.IDictionary])) {
    $items = New-Object 'Collections.Generic.List[object]'
    foreach ($child in $Node) { $items.Add((ConvertTo-CzxtInstallerJsonData $child $Values $Pattern)) }
    return ,$items.ToArray()
  }
  if ($Node -is [Collections.IDictionary] -or $Node -is [pscustomobject]) {
    $result = [ordered]@{}
    $properties = if ($Node -is [Collections.IDictionary]) { $Node.Keys } else { $Node.PSObject.Properties.Name }
    foreach ($name in $properties) {
      $key = Expand-CzxtInstallerDataTokens ([string]$name) $Values $Pattern
      if ($result.Contains($key)) { throw ('JSON参数渲染后出现重复字段：' + $key) }
      if ($Node -is [Collections.IDictionary]) { $child = $Node[$name] }
      else { $child = $Node.$name }
      $result[$key] = ConvertTo-CzxtInstallerJsonData $child $Values $Pattern
    }
    return $result
  }
  return $Node
}

function ConvertTo-CzxtInstallerPsLiteral {
  param([string]$Value)
  $value = $Value.Replace("'", "''")
  foreach ($code in @(0x2018, 0x2019)) {
    $quote = [string][char]$code
    $value = $value.Replace($quote, ($quote + $quote))
  }
  return ("'" + $value + "'")
}

function ConvertTo-CzxtInstallerPsExpandableData {
  param([string]$Value)
  $escaped = $Value.Replace('`', '``').Replace('$', '`$').Replace('"', '`"')
  foreach ($code in @(0x201C, 0x201D)) {
    $quote = [string][char]$code
    $escaped = $escaped.Replace($quote, ('`' + $quote))
  }
  return $escaped.Replace("`r", '`r').Replace("`n", '`n')
}

function ConvertTo-CzxtInstallerPsText {
  param([string]$Text, [Collections.IDictionary]$Values, [regex]$Pattern)
  $tokens = $null; $errors = $null
  $null = [Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$errors)
  if (@($errors).Count -gt 0) { throw 'PowerShell模板语法无效，拒绝渲染。' }
  $allTokens = New-Object 'Collections.Generic.List[object]'
  foreach ($token in $tokens) { $allTokens.Add($token) }
  for ($i=0; $i -lt $allTokens.Count; $i++) {
    $nested = $allTokens[$i].PSObject.Properties['NestedTokens']
    if ($null -ne $nested) { foreach ($child in $nested.Value) { $allTokens.Add($child) } }
  }
  $edits = @{}
  $wholeTokens = @{}
  foreach ($match in $Pattern.Matches($Text)) {
    $owner = @($allTokens | Where-Object {
      $_.Extent.StartOffset -le $match.Index -and $_.Extent.EndOffset -ge ($match.Index + $match.Length)
    } | Sort-Object { $_.Extent.EndOffset - $_.Extent.StartOffset } | Select-Object -First 1)
    if ($owner.Count -ne 1) { throw 'PowerShell占位符位于可执行语法中，拒绝渲染。' }
    $token = $owner[0]
    $crossing = @($allTokens | Where-Object {
      $_ -ne $token -and $_.Extent.StartOffset -ge $token.Extent.StartOffset -and
      $_.Extent.EndOffset -le $token.Extent.EndOffset -and
      $_.Extent.StartOffset -lt ($match.Index + $match.Length) -and $_.Extent.EndOffset -gt $match.Index
    })
    if ($crossing.Count -gt 0) { throw 'PowerShell占位符跨越 nested token，拒绝作为外层字符串渲染。' }
    if ($wholeTokens.Contains($token.Extent.StartOffset)) { continue }
    $value = [string]$Values[$match.Groups['name'].Value]
    $start = $match.Index
    $length = $match.Length
    $rendered = switch ([string]$token.Kind) {
      'HereStringLiteral' {
        $start = $token.Extent.StartOffset
        $length = $token.Extent.EndOffset - $start
        $wholeTokens[$start] = $true
        ConvertTo-CzxtInstallerPsLiteral (Expand-CzxtInstallerDataTokens $token.Value $Values $Pattern)
        break
      }
      'StringLiteral' {
        $literal = ConvertTo-CzxtInstallerPsLiteral $value
        $literal.Substring(1, $literal.Length - 2)
        break
      }
      { $_ -in @('StringExpandable', 'HereStringExpandable') } {
        # 模板反引号原来只转义占位符的左花括号，不能抵消参数自身的转义。
        $backticks = 0
        for ($j=$start-1; $j -ge $token.Extent.StartOffset -and $Text[$j] -eq '`'; $j--) { $backticks++ }
        if (($backticks % 2) -eq 1) {
          $start--
          $length++
        }
        $variable = @($allTokens | Where-Object {
          $_.Kind -eq 'Variable' -and $_.Extent.EndOffset -eq $start
        } | Select-Object -First 1)
        if ($variable.Count -eq 1 -and -not $variable[0].Text.StartsWith('${')) {
          $variableText = $variable[0].Text.Substring(1)
          $edits[$variable[0].Extent.StartOffset] = [pscustomobject]@{
            Start=$variable[0].Extent.StartOffset; Length=$variable[0].Text.Length
            Text=('${' + $variableText + '}')
          }
        }
        ConvertTo-CzxtInstallerPsExpandableData $value
        break
      }
      'Comment' {
        $value.Replace("`r", '\r').Replace("`n", '\n').Replace('#>', '# >')
        break
      }
      default { throw ('PowerShell占位符不在字符串或注释内：' + $token.Kind) }
    }
    $edits[$start] = [pscustomobject]@{ Start=$start; Length=$length; Text=$rendered }
  }
  foreach ($edit in $edits.Values | Sort-Object Start -Descending) {
    $Text = $Text.Remove($edit.Start, $edit.Length).Insert($edit.Start, $edit.Text)
  }
  return $Text
}

function ConvertTo-CzxtInstallerRenderedText {
  param([string]$Text, [string]$Extension, [Collections.IDictionary]$Values)
  if ($Extension.Equals('.json', [StringComparison]::OrdinalIgnoreCase) -and
      [string]::IsNullOrWhiteSpace($Text)) { throw 'JSON模板不能为空或全空白。' }
  $pattern = New-CzxtInstallerTokenPattern $Values
  if (-not $pattern.IsMatch($Text)) { return $Text }
  switch ($Extension.ToLowerInvariant()) {
    '.json' {
      $data = ConvertFrom-Json -InputObject $Text -ErrorAction Stop
      return ConvertTo-Json -InputObject (ConvertTo-CzxtInstallerJsonData $data $Values $pattern) -Depth 100
    }
    '.ps1' { return ConvertTo-CzxtInstallerPsText $Text $Values $pattern }
    default { return Expand-CzxtInstallerDataTokens $Text $Values $pattern }
  }
}

function Assert-CzxtInstallerRenderedText {
  param([string]$Text, [string]$Extension, [string]$Path)
  switch ($Extension.ToLowerInvariant()) {
    '.json' {
      if ([string]::IsNullOrWhiteSpace($Text)) { throw ('实例化受管 JSON 为空：' + $Path) }
      try { $null = ConvertFrom-Json -InputObject $Text -ErrorAction Stop }
      catch { throw ('实例化受管 JSON 无效：' + $Path) }
    }
    '.ps1' {
      $tokens=$null; $errors=$null
      $null = [Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$errors)
      if (@($errors).Count -gt 0) { throw ('实例化受管 PowerShell 语法无效：' + $Path) }
    }
  }
}
