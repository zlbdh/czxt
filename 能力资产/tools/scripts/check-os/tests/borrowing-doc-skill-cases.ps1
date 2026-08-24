$ErrorActionPreference = 'Stop'

function Invoke-BorrowingDocSkillCases {
  param([string]$Root)
  $skillRelative = '能力资产/skills/借鉴.md'
  $appendixRelative = '能力资产/skills/借鉴-命令附录.md'
  $indexRelative = '能力资产/skills/README.md'

  Invoke-CzxtContract 'borrowing Skill document exists' {
    Assert-CzxtTrue (Test-BorrowingDocFile $Root $skillRelative) ("missing file: {0}" -f $skillRelative)
  }
  Invoke-CzxtContract 'borrowing command appendix exists' {
    Assert-CzxtTrue (Test-BorrowingDocFile $Root $appendixRelative) ("missing file: {0}" -f $appendixRelative)
  }

  if (Test-BorrowingDocFile $Root $skillRelative) {
    Invoke-BorrowingSkillMainCases -Text (Get-BorrowingDocText $Root $skillRelative)
  }
  if (Test-BorrowingDocFile $Root $appendixRelative) {
    Invoke-BorrowingCommandAppendixCases -Text (Get-BorrowingDocText $Root $appendixRelative)
  }

  Invoke-CzxtContract 'skills index lists only the main borrowing Skill once' {
    $index = Get-BorrowingDocText $Root $indexRelative
    Assert-BorrowingIndexLink $index '主入口清单' '借鉴.md' '借鉴.md' 1
    Assert-BorrowingDocMatchCount $index '\[借鉴\.md\]\(借鉴\.md\)' 1 'skills index main Skill count'
    Assert-BorrowingDocMatchCount $index '借鉴-命令附录\.md' 0 'skills index must not list command appendix'
  }
}
