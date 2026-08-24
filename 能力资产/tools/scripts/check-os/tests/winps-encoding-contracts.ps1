[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$script:Passed = 0
$script:Failed = 0
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:Utf8Bom = New-Object System.Text.UTF8Encoding($true)
$gatePath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\check-winps-encoding.ps1'))
$fixtureParent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-winps-encoding-tests'))
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
. (Join-Path $PSScriptRoot 'winps-encoding-contract-support.ps1')

if (-not (Test-Path -LiteralPath $gatePath -PathType Leaf)) {
    Write-Output ("[FAIL] gate script exists: missing {0}" -f $gatePath)
    Write-Output 'contracts: 0 passed, 1 failed'
    exit 10
}

Initialize-WinpsContractFixture

try {
    Invoke-Contract 'illegal Root exits 10' {
        $missing = Join-Path $fixtureRoot 'missing-root'
        $missingResult = Invoke-Gate -Root $missing
        Assert-Equal 10 $missingResult.ExitCode 'missing Root exit code'

        $fileRoot = Write-ScriptFile -Root $fixtureRoot -RelativePath 'root-is-file.txt' -Content 'x' -WithBom $false
        $fileResult = Invoke-Gate -Root $fileRoot -ListOnly
        Assert-Equal 10 $fileResult.ExitCode 'file Root exit code'
    }

    Invoke-Contract 'empty Root succeeds and ListOnly is empty' {
        $root = New-CaseRoot 'empty'
        $normal = Invoke-Gate -Root $root
        $listed = Invoke-Gate -Root $root -ListOnly
        Assert-Equal 0 $normal.ExitCode 'empty normal exit code'
        Assert-Equal 0 $listed.ExitCode 'empty ListOnly exit code'
        Assert-Equal '' $listed.StdOut 'empty ListOnly stdout'
        Assert-Equal '' $listed.StdErr 'empty ListOnly stderr'
    }

    Invoke-Contract 'ListOnly discovers, excludes, sorts, and de-duplicates paths' {
        $root = New-CaseRoot 'discovery'
        [void](Write-ScriptFile $root '实例化项目.ps1' '$x = 1' $false)
        [void](Write-ScriptFile $root '.claude\Z.ps1' '$x =' $false)
        [void](Write-ScriptFile $root '.claude\a\A.ps1' '$x = 1' $false)
        [void](Write-ScriptFile $root '.codex\m.ps1' '$x = 1' $false)
        [void](Write-ScriptFile $root '能力资产\nested\n.ps1' '$x = 1' $false)
        [void](Write-ScriptFile $root '项目区\本地实例\demo\能力资产\skip.ps1' '$x =' $false)
        [void](Write-ScriptFile $root '借鉴区\来源\sample\快照\skip.ps1' '$x =' $false)
        [void](Write-ScriptFile $root '其他\outside.ps1' '$x =' $false)

        $previousOutputEncoding = [Console]::OutputEncoding
        try {
            [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(437)
            $result = Invoke-Gate -Root $root -ListOnly
        }
        finally { [Console]::OutputEncoding = $previousOutputEncoding }
        Assert-Equal 0 $result.ExitCode 'ListOnly exit code'
        Assert-Equal '' $result.StdErr 'ListOnly stderr'
        $actual = @(Get-OutputLines $result.StdOut)
        [string[]]$expected = @(
            '.claude/a/A.ps1', '.claude/Z.ps1', '.codex/m.ps1',
            '实例化项目.ps1', '能力资产/nested/n.ps1'
        )
        Assert-OutputLines -Expected $expected -Actual $actual -Message 'ListOnly path'
    }

    Invoke-Contract 'ASCII without BOM fails the BOM policy' {
        $root = New-CaseRoot 'ascii-no-bom'
        [void](Write-ScriptFile $root '.codex\ascii.ps1' 'Write-Output ok' $false)
        $result = Invoke-Gate -Root $root
        Assert-Equal 10 $result.ExitCode 'ASCII no-BOM exit code'
        $all = $result.StdOut + $result.StdErr
        Assert-Contains $all '.codex/ascii.ps1' 'ASCII failure path'
        Assert-Contains $all 'UTF-8 BOM' 'ASCII failure reason'
    }

    Invoke-Contract 'Chinese without BOM fails the BOM policy' {
        $root = New-CaseRoot 'chinese-no-bom'
        [void](Write-ScriptFile $root '能力资产\中文.ps1' "Write-Output '中文'" $false)
        $result = Invoke-Gate -Root $root
        Assert-Equal 10 $result.ExitCode 'Chinese no-BOM exit code'
        Assert-Contains ($result.StdOut + $result.StdErr) '能力资产/中文.ps1' 'Chinese failure path'
    }

    Invoke-Contract 'large stderr is drained concurrently within the watchdog' {
        $root = New-CaseRoot 'large-stderr'
        New-NoBomScriptRange -Root $root -Count 500
        $result = Invoke-Gate -Root $root
        $errors = @(Get-OutputLines $result.StdErr)
        Assert-Equal 10 $result.ExitCode 'large stderr exit code'
        Assert-True ($result.ElapsedMilliseconds -lt 30000) 'large stderr exceeded the watchdog'
        Assert-Equal 500 $errors.Count 'large stderr line count'
        Assert-Contains $result.StdErr '能力资产/bulk/script-000.ps1' 'large stderr first path'
        Assert-Contains $result.StdErr '能力资产/bulk/script-499.ps1' 'large stderr last path'
    }

    Invoke-Contract 'valid UTF-8 BOM script succeeds' {
        $root = New-CaseRoot 'valid-bom'
        [void](Write-ScriptFile $root '.claude\合法.ps1' "Write-Output '中文'" $true)
        $result = Invoke-Gate -Root $root
        Assert-Equal 0 $result.ExitCode 'valid BOM exit code'
    }

    Invoke-Contract 'BOM script with parser error fails' {
        $root = New-CaseRoot 'parser-error'
        [void](Write-ScriptFile $root '.codex\broken.ps1' '$value =' $true)
        $result = Invoke-Gate -Root $root
        Assert-Equal 10 $result.ExitCode 'parser error exit code'
        $all = $result.StdOut + $result.StdErr
        Assert-Contains $all '.codex/broken.ps1' 'parser error path'
        Assert-Contains $all '语法错误' 'parser error reason'
    }

    Invoke-Contract 'locked script reports a read error' {
        $root = New-CaseRoot 'locked-file'
        $path = Write-ScriptFile $root '.claude\locked.ps1' '$value = 1' $true
        $lock = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try { $result = Invoke-Gate -Root $root }
        finally { $lock.Dispose() }
        Assert-Equal 10 $result.ExitCode 'locked file exit code'
        $all = $result.StdOut + $result.StdErr
        Assert-Contains $all '.claude/locked.ps1' 'locked file path'
        Assert-Contains $all '读取失败' 'locked file reason'
    }

    Invoke-Contract 'normal and ListOnly modes are read-only' {
        $root = New-CaseRoot 'read-only'
        $valid = Write-ScriptFile $root '.codex\valid.ps1' '$value = 1' $true
        $invalid = Write-ScriptFile $root '能力资产\invalid.ps1' '$value = 2' $false
        $beforeValid = Get-FileSnapshot $valid
        $beforeInvalid = Get-FileSnapshot $invalid
        [void](Invoke-Gate -Root $root)
        [void](Invoke-Gate -Root $root -ListOnly)
        $afterValid = Get-FileSnapshot $valid
        $afterInvalid = Get-FileSnapshot $invalid
        Assert-Equal $beforeValid.Hash $afterValid.Hash 'valid file hash changed'
        Assert-Equal $beforeValid.LastWriteTimeUtc $afterValid.LastWriteTimeUtc 'valid file mtime changed'
        Assert-Equal $beforeInvalid.Hash $afterInvalid.Hash 'invalid file hash changed'
        Assert-Equal $beforeInvalid.LastWriteTimeUtc $afterInvalid.LastWriteTimeUtc 'invalid file mtime changed'
    }
}
finally {
    Remove-WinpsContractFixture
}

Complete-WinpsContracts
