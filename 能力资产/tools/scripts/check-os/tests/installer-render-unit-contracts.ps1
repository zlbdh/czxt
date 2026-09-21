[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot '../../installer-render-text.ps1')
$token = '{' + '{PROJECT_NAME}' + '}'

Invoke-CzxtContract 'JSON渲染保留空数组、单项数组、嵌套数组和null的类型' {
  $text = '{"name":"TOKEN","empty":[],"one":[1],"nested":[[1],[2]],"nil":null}'.Replace('TOKEN', $token)
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.json' @{ PROJECT_NAME='我的"项目' }
  $data = ConvertFrom-Json -InputObject $rendered
  Assert-CzxtEqual '我的"项目' $data.name 'JSON名称未逐字保存'
  Assert-CzxtTrue ($data.empty -is [Array]) '空数组变成null'
  Assert-CzxtEqual 0 $data.empty.Count '空数组改变'
  Assert-CzxtTrue ($data.one -is [Array]) '单项数组变成标量'
  Assert-CzxtTrue ($data.nested[0] -is [Array]) '嵌套数组被展平'
  Assert-CzxtEqual 1 $data.one[0] '数字元素变成对象'
  Assert-CzxtTrue ($null -eq $data.nil) 'null改变'
}

Invoke-CzxtContract 'JSON顶层数组保持数组类型' {
  $text = ('[{"name":"TOKEN"},[],[1]]').Replace('TOKEN', $token)
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.json' @{ PROJECT_NAME='数组项目' }
  $data = ConvertFrom-Json -InputObject $rendered
  Assert-CzxtTrue ($data -is [Array]) '顶层数组变成属性对象'
  Assert-CzxtEqual 3 $data.Count '顶层数组元素丢失'
  Assert-CzxtTrue ($data[1] -is [Array]) '顶层数组内的空数组改变'
  foreach ($single in @('[{"name":"TOKEN"}]','[["TOKEN"]]')) {
    $result=ConvertTo-CzxtInstallerRenderedText ($single.Replace('TOKEN',$token)) '.json' @{PROJECT_NAME='数组项目'}
    Assert-CzxtTrue ($result.TrimStart().StartsWith('[')) '顶层单项数组丢失数组边界'
  }
}
Invoke-CzxtContract '空白JSON在渲染和终验拒绝' {
  foreach ($blank in @('', ' ', "`r`n`t")) {
    $renderThrew=$false; $validateThrew=$false
    try { $null=ConvertTo-CzxtInstallerRenderedText $blank '.json' @{ PROJECT_NAME='x' } } catch { $renderThrew=$true }
    try { Assert-CzxtInstallerRenderedText $blank '.json' 'blank' } catch { $validateThrew=$true }
    Assert-CzxtTrue ($renderThrew -and $validateThrew) '空白JSON未在渲染与终验双边界拒绝'
  }
}
Invoke-CzxtContract 'JSON literal null保持合法' {
  $rendered=ConvertTo-CzxtInstallerRenderedText ' null ' '.json' @{ PROJECT_NAME='x' }
  Assert-CzxtTrue ($rendered.Trim() -ceq 'null') '合法JSON null被改变'
  Assert-CzxtInstallerRenderedText ' null ' '.json' 'null'
}

Invoke-CzxtContract '跨nested token的占位符不能回退到外层可展开字符串' {
  $text = ('"$(TOKEN)"').Replace('TOKEN', $token)
  $threw=$false
  try { $null=ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME='1+2' } } catch { $threw=$true }
  Assert-CzxtTrue $threw '子表达式中的参数被当可执行代码'
}

Invoke-CzxtContract '紧邻变量的参数保留变量边界和数据值' {
  foreach ($template in @('"$baseTOKEN"', '"$base`TOKEN"', '"$script:renderBaseTOKEN"')) {
    $text = $template.Replace('TOKEN', $token)
    $rendered=ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME='foo' }
    $base='base'; $basefoo='wrong'; $script:renderBase='scope'; $script:renderBasefoo='wrong-scope'
    $actual=&([scriptblock]::Create($rendered))
    $expected=if($template.Contains('$base')){'basefoo'}else{'scopefoo'}
    Assert-CzxtEqual $expected $actual ('变量边界被吞: '+$template)
  }
}

Invoke-CzxtContract '嵌套PowerShell表达式内的参数按最内层字符串上下文处理' {
  $text = ('"前缀$(''TOKEN'')"').Replace('TOKEN', $token)
  $value = "我的'项目"
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$value }
  Assert-CzxtInstallerRenderedText $rendered '.ps1' 'nested'
  $actual = & ([scriptblock]::Create($rendered))
  Assert-CzxtEqual ('前缀' + $value) $actual '最内层单引号上下文未转义'
}

Invoke-CzxtContract '模板反引号不能解除参数美元符号转义' {
  $text = ('"`TOKEN"').Replace('TOKEN', $token)
  $name = '$([int]::Parse("不是数字"))'
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$name }
  $actual = & ([scriptblock]::Create($rendered))
  Assert-CzxtEqual $name $actual '模板反引号使参数进入表达式'
}

Invoke-CzxtContract '含换行和here-string结束符的参数仍为逐字数据' {
  $name = "行一`n'@`n`"@`n行二"
  $text = (@('@''', 'TOKEN', '''@') -join "`n").Replace('TOKEN', $token)
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$name }
  Assert-CzxtEqual $name (& ([scriptblock]::Create($rendered))) '单引号here-string值改变'
  $text = (@('@"', 'TOKEN', '"@') -join "`n").Replace('TOKEN', $token)
  $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$name }
  Assert-CzxtEqual $name (& ([scriptblock]::Create($rendered))) '双引号here-string值改变'
}

Invoke-CzxtContract '参数不能逃出块注释或行注释执行代码' {
  $name = "#>`nthrow '不得执行'"
  foreach ($template in @('<# TOKEN #>', '# TOKEN')) {
    $text = ($template + "`n'保留'").Replace('TOKEN', $token)
    $rendered = ConvertTo-CzxtInstallerRenderedText $text '.ps1' @{ PROJECT_NAME=$name }
    Assert-CzxtEqual '保留' (& ([scriptblock]::Create($rendered))) '参数逃逸注释'
  }
}

Invoke-CzxtContract '智能引号和反引号在两类字符串中逐字保留' {
  $name = '数据' + ([string][char]0x2018) + ([string][char]0x2019) + ([string][char]0x201C) + ([string][char]0x201D) + '`$'
  foreach ($template in @('''TOKEN''', '"TOKEN"')) {
    $rendered = ConvertTo-CzxtInstallerRenderedText ($template.Replace('TOKEN', $token)) '.ps1' @{ PROJECT_NAME=$name }
    Assert-CzxtEqual $name (& ([scriptblock]::Create($rendered))) '智能引号被解释为语法'
  }
}

Invoke-CzxtContract '可执行位置的占位符在渲染阶段拒绝' {
  $threw = $false
  try { $null = ConvertTo-CzxtInstallerRenderedText $token '.ps1' @{ PROJECT_NAME='throw 1' } }
  catch { $threw = $true }
  Assert-CzxtTrue $threw '裸表达式占位符未拒绝'
}

Invoke-CzxtContract 'P4b将业务路径中的正则元字符视为普通目录字符' {
  $path = Join-Path $PSScriptRoot '../p4b-size-classification.ps1'
  $text = ConvertTo-CzxtInstallerRenderedText ([IO.File]::ReadAllText($path)) '.ps1' @{ APP_REPO_DIR='frontend/app[1].v2' }
  . ([scriptblock]::Create($text))
  $meta = Get-AppSrcP4bMeta 'frontend\app[1].v2\src\features\editor\large.ts'
  Assert-CzxtEqual 'features/editor' $meta.Domain '正则元字符破坏业务域归类'
  $meta = Get-AppSrcP4bMeta 'frontend/app1Xv2/src/features/editor/large.ts'
  Assert-CzxtEqual 'src' $meta.Domain '正则误匹配了另一个目录'
  $stats=@{ Danger=0 }; $areas=@{ app=@{ Danger=0 } }
  $warnings=New-Object 'Collections.Generic.List[string]'
  $all=New-Object 'Collections.Generic.List[object]'
  $business=New-Object 'Collections.Generic.List[object]'
  foreach ($relative in @('frontend/app[1].v2/src/features/editor/large.ts', 'frontend/app1Xv2/src/features/editor/large.ts')) {
    Add-P4bSizeFinding $relative 8000 'app' $stats $areas $warnings $all $business
  }
  Assert-CzxtEqual 1 $business.Count '业务债列表错误接纳或遗漏目录'
  Assert-CzxtEqual 'features/editor' $business[0].Domain '业务债列表丢失业务域'
}
Invoke-CzxtContract '短项目名不能改写模板自有正则运算符' {
  $path = Join-Path $PSScriptRoot '../p4k-entry-anchor-patterns.ps1'
  $text = ConvertTo-CzxtInstallerRenderedText ([IO.File]::ReadAllText($path)) '.ps1' @{ PROJECT_NAME='?'; APP_REPO_DIR='a.b' }
  . ([scriptblock]::Create($text))
  $pattern = @(Get-P4kEntryAnchorChecks | Where-Object { $_.Label -ceq 'git流程旧实操示例' })[0].Pattern
  Assert-CzxtTrue ([regex]::IsMatch('git add .', $pattern)) '参数替换破坏了模板原有(?m)规则'
}

Invoke-CzxtContract 'P4k全部APP路径规则把方括号视为字面数据' {
  $path = Join-Path $PSScriptRoot '../p4k-entry-anchor-patterns.ps1'
  $text=ConvertTo-CzxtInstallerRenderedText ([IO.File]::ReadAllText($path)) '.ps1' @{ PROJECT_NAME='p'; APP_REPO_DIR='frontend/app[1]' }
  . ([scriptblock]::Create($text))
  foreach ($case in @(
      @{ Label='角色边界旧白名单'; Exact='`frontend/app[1]/**` 绝对硬护栏'; Near='`frontend/app1/**` 绝对硬护栏' },
      @{ Label='闭环者配置旧口径'; Exact='`frontend/app[1]/package.json` version 字段 / `frontend/app[1]/.gitattributes`'; Near='`frontend/app1/package.json` version 字段 / `frontend/app1/.gitattributes`' })) {
    $pattern=@(Get-P4kEntryAnchorChecks | Where-Object { $_.Label -ceq $case.Label })[0].Pattern
    Assert-CzxtTrue ([regex]::IsMatch($case.Exact,$pattern)) ('精确路径未命中: '+$case.Label)
    Assert-CzxtTrue (-not [regex]::IsMatch($case.Near,$pattern)) ('近似路径被误命中: '+$case.Label)
  }
}
Complete-CzxtContracts
