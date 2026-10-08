[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot '../../installer-render-text.ps1')
$token = '{' + '{PROJECT_NAME}' + '}'

Invoke-CzxtContract 'JSON rendering preserves empty, single-item, and nested arrays and the null type' {
  $text = '{"name":"TOKEN","empty":[],"one":[1],"nested":[[1],[2]],"nil":null}'.Replace('TOKEN', $token)
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.json' @{ PROJECT_NAME='我的"项目' }
  $data = ConvertFrom-Json -InputObject $rendered
  Assert-CzxtEqual '我的"项目' $data.name 'JSON name was not preserved literally'
  Assert-CzxtTrue ($data.empty -is [Array]) 'Empty array became null'
  Assert-CzxtEqual 0 $data.empty.Count 'Empty array changed'
  Assert-CzxtTrue ($data.one -is [Array]) 'Single-item array became a scalar'
  Assert-CzxtTrue ($data.nested[0] -is [Array]) 'Nested array was flattened'
  Assert-CzxtEqual 1 $data.one[0] 'Numeric element became an object'
  Assert-CzxtTrue ($null -eq $data.nil) 'null changed'
}

Invoke-CzxtContract 'Top-level JSON arrays retain the array type' {
  $text = ('[{"name":"TOKEN"},[],[1]]').Replace('TOKEN', $token)
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.json' @{ PROJECT_NAME='数组项目' }
  $data = ConvertFrom-Json -InputObject $rendered
  Assert-CzxtTrue ($data -is [Array]) 'Top-level array became a property object'
  Assert-CzxtEqual 3 $data.Count 'Top-level array elements were lost'
  Assert-CzxtTrue ($data[1] -is [Array]) 'Empty array within a top-level array changed'
  foreach ($single in @('[{"name":"TOKEN"}]','[["TOKEN"]]')) {
    $result=ConvertTo-CzxtInstallerRenderedText ($single.Replace('TOKEN',$token)) '.json' @{PROJECT_NAME='数组项目'}
    Assert-CzxtTrue ($result.TrimStart().StartsWith('[')) 'Top-level single-item array lost its array boundary'
  }
}
Invoke-CzxtContract 'Blank JSON is rejected during rendering and final validation' {
  foreach ($blank in @('', ' ', "`r`n`t")) {
    $renderThrew=$false; $validateThrew=$false
    try { $null=ConvertTo-CzxtInstallerRenderedText $blank '.json' @{ PROJECT_NAME='x' } } catch { $renderThrew=$true }
    try { Assert-CzxtInstallerRenderedText $blank '.json' 'blank' } catch { $validateThrew=$true }
    Assert-CzxtTrue ($renderThrew -and $validateThrew) 'Blank JSON was not rejected at both rendering and final-validation boundaries'
  }
}
Invoke-CzxtContract 'JSON literal null remains valid' {
  $rendered=ConvertTo-CzxtInstallerRenderedText ' null ' '.json' @{ PROJECT_NAME='x' }
  Assert-CzxtTrue ($rendered.Trim() -ceq 'null') 'Valid JSON null was changed'
  Assert-CzxtInstallerRenderedText ' null ' '.json' 'null'
}

Invoke-CzxtContract 'A placeholder spanning nested tokens must not fall back to the outer expandable string' {
  $text = ('"$(TOKEN)"').Replace('TOKEN', $token)
  $threw=$false
  try { $null=ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME='1+2' } } catch { $threw=$true }
  Assert-CzxtTrue $threw 'A parameter in a subexpression was treated as executable code'
}

Invoke-CzxtContract 'Parameters adjacent to variables preserve variable boundaries and data values' {
  foreach ($template in @('"$baseTOKEN"', '"$base`TOKEN"', '"$script:renderBaseTOKEN"')) {
    $text = $template.Replace('TOKEN', $token)
    $rendered=ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME='foo' }
    $base='base'; $basefoo='wrong'; $script:renderBase='scope'; $script:renderBasefoo='wrong-scope'
    $actual=&([scriptblock]::Create($rendered))
    $expected=if($template.Contains('$base')){'basefoo'}else{'scopefoo'}
    Assert-CzxtEqual $expected $actual ('Variable boundary was lost: '+$template)
  }
}

Invoke-CzxtContract 'Parameters inside nested PowerShell expressions use the innermost string context' {
  $text = ('"前缀$(''TOKEN'')"').Replace('TOKEN', $token)
  $value = "我的'项目"
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$value }
  Assert-CzxtInstallerRenderedText $rendered '.ps1' 'nested'
  $actual = & ([scriptblock]::Create($rendered))
  Assert-CzxtEqual ('前缀' + $value) $actual 'Innermost single-quoted context was not escaped'
}

Invoke-CzxtContract 'Template backticks must not undo escaping of parameter dollar signs' {
  $text = ('"`TOKEN"').Replace('TOKEN', $token)
  $name = '$([int]::Parse("不是数字"))'
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$name }
  $actual = & ([scriptblock]::Create($rendered))
  Assert-CzxtEqual $name $actual 'Template backtick allowed a parameter to enter an expression'
}

Invoke-CzxtContract 'Parameters containing newlines and here-string terminators remain literal data' {
  $name = "行一`n'@`n`"@`n行二"
  $text = (@('@''', 'TOKEN', '''@') -join "`n").Replace('TOKEN', $token)
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$name }
  Assert-CzxtEqual $name (& ([scriptblock]::Create($rendered))) 'Single-quoted here-string value changed'
  $text = (@('@"', 'TOKEN', '"@') -join "`n").Replace('TOKEN', $token)
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$name }
  Assert-CzxtEqual $name (& ([scriptblock]::Create($rendered))) 'Double-quoted here-string value changed'
}

Invoke-CzxtContract 'Parameters must not escape block or line comments to execute code' {
  $name = "#>`nthrow '不得执行'"
  foreach ($template in @('<# TOKEN #>', '# TOKEN')) {
    $text = ($template + "`n'保留'").Replace('TOKEN', $token)
    $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$name }
    Assert-CzxtEqual '保留' (& ([scriptblock]::Create($rendered))) 'Parameter escaped its comment'
  }
}

Invoke-CzxtContract 'Smart quotes and backticks are preserved literally in both string types' {
  $name = '数据' + ([string][char]0x2018) + ([string][char]0x2019) + ([string][char]0x201C) + ([string][char]0x201D) + '`$'
  foreach ($template in @('''TOKEN''', '"TOKEN"')) {
    $rendered = ConvertTo-CzxtInstallerRenderedText ($template.Replace('TOKEN', $token)) '.ps1' @{ PROJECT_NAME=$name }
    Assert-CzxtEqual $name (& ([scriptblock]::Create($rendered))) 'Smart quotes were interpreted as syntax'
  }
}

Invoke-CzxtContract 'Placeholders in executable positions are rejected during rendering' {
  $threw = $false
  try { $null = ConvertTo-CzxtInstallerRenderedText $token '.ps1' @{ PROJECT_NAME='throw 1' } }
  catch { $threw = $true }
  Assert-CzxtTrue $threw 'Bare-expression placeholder was not rejected'
}

Invoke-CzxtContract 'P4b treats regex metacharacters in application paths as ordinary directory characters' {
  $path = Join-Path $PSScriptRoot '../p4b-size-classification.ps1'
  $text = ConvertTo-CzxtInstallerRenderedText ([IO.File]::ReadAllText($path)) '.ps1' @{ APP_REPO_DIR='frontend/app[1].v2' }
  . ([scriptblock]::Create($text))
  $meta = Get-AppSrcP4bMeta 'frontend\app[1].v2\src\features\editor\large.ts'
  Assert-CzxtEqual 'features/editor' $meta.Domain 'Regex metacharacters broke application-domain classification'
  $meta = Get-AppSrcP4bMeta 'frontend/app1Xv2/src/features/editor/large.ts'
  Assert-CzxtEqual 'src' $meta.Domain 'Regex incorrectly matched another directory'
  $stats=@{ Danger=0 }; $areas=@{ app=@{ Danger=0 } }
  $warnings=New-Object 'Collections.Generic.List[string]'
  $all=New-Object 'Collections.Generic.List[object]'
  $business=New-Object 'Collections.Generic.List[object]'
  foreach ($relative in @('frontend/app[1].v2/src/features/editor/large.ts', 'frontend/app1Xv2/src/features/editor/large.ts')) {
    Add-P4bSizeFinding $relative 8000 'app' $stats $areas $warnings $all $business
  }
  Assert-CzxtEqual 1 $business.Count 'Business-debt list incorrectly included or omitted directories'
  Assert-CzxtEqual 'features/editor' $business[0].Domain 'Business-debt list lost the application domain'
}
Invoke-CzxtContract 'Short project names must not rewrite template-owned regex operators' {
  $path = Join-Path $PSScriptRoot '../p4k-entry-anchor-patterns.ps1'
  $text = ConvertTo-CzxtInstallerRenderedText ([IO.File]::ReadAllText($path)) '.ps1' @{ PROJECT_NAME='?'; APP_REPO_DIR='a.b' }
  . ([scriptblock]::Create($text))
  $pattern = @(Get-P4kEntryAnchorChecks | Where-Object { ($_.Label -ceq 'git流程旧实操示例') -or ($_.Label -ceq 'Obsolete Git workflow example') })[0].Pattern
  Assert-CzxtTrue ([regex]::IsMatch('git add .', $pattern)) 'Parameter substitution broke the existing template (?m) rule'
}

Invoke-CzxtContract 'All P4k APP path rules treat brackets as literal data' {
  $path = Join-Path $PSScriptRoot '../p4k-entry-anchor-patterns.ps1'
  $text=ConvertTo-CzxtInstallerRenderedText ([IO.File]::ReadAllText($path)) '.ps1' @{ PROJECT_NAME='p'; APP_REPO_DIR='frontend/app[1]' }
  . ([scriptblock]::Create($text))
  foreach ($case in @(
      @{ Label='Obsolete role-boundary allowlist'; LegacyLabel='角色边界旧白名单'; Exact='`frontend/app[1]/**` 绝对硬护栏'; Near='`frontend/app1/**` 绝对硬护栏' },
      @{ Label='Obsolete Test and Release PM configuration guidance'; LegacyLabel='闭环者配置旧口径'; Exact='`frontend/app[1]/package.json` version 字段 / `frontend/app[1]/.gitattributes`'; Near='`frontend/app1/package.json` version 字段 / `frontend/app1/.gitattributes`' })) {
    $pattern=@(Get-P4kEntryAnchorChecks | Where-Object { ($_.Label -ceq $case.Label) -or ($_.Label -ceq $case.LegacyLabel) })[0].Pattern
    Assert-CzxtTrue ([regex]::IsMatch($case.Exact,$pattern)) ('Exact path did not match: '+$case.Label)
    Assert-CzxtTrue (-not [regex]::IsMatch($case.Near,$pattern)) ('Approximate path matched incorrectly: '+$case.Label)
  }
}
Complete-CzxtContracts
