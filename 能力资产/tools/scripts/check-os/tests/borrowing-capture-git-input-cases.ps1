[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-git-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:GitInputReady = $false
  Invoke-CzxtContract 'capture Git input helper exists' {
    Import-BorrowingGitInputTestModules
    $script:GitInputReady = $true
  }
  if ($script:GitInputReady) {
    Invoke-CzxtContract 'Git locator canonicalizes only safe literal HTTPS repository locators' {
      Assert-CzxtEqual 'https://example.invalid/Owner/Repo.git' `
        (ConvertTo-BorrowingGitLocator 'https://EXAMPLE.invalid:443/Owner/Repo.git') `
        'ASCII Git locator'
      Assert-CzxtEqual 'https://xn--fsqu00a.invalid/Owner/Repo.git' `
        (ConvertTo-BorrowingGitLocator 'https://例子.invalid/Owner/Repo.git') `
        'IDN Git locator'
    }

    Invoke-CzxtContract 'Git locator rejects every ambiguous credential and path form' {
      $tooLong = 'https://example.invalid/' + ('a' * 1010) + '.git'
      foreach ($value in @(
          'http://example.invalid/owner/repo.git',
          'file:///C:/repo.git', 'owner/repo.git', '\\server\repo.git',
          'https://user@example.invalid/owner/repo.git',
          'https://example.invalid/owner/repo.git?token=x',
          'https://example.invalid/owner/repo.git#main',
          'https://example.invalid:444/owner/repo.git',
          'https://example.invalid./owner/repo.git',
          'https://127.0.0.1/owner/repo.git', 'https://[::1]/owner/repo.git',
          'https://example.invalid/owner%2Frepo.git',
          'https://example.invalid\owner\repo.git',
          'https://example.invalid/owner repo.git',
          'https://example.invalid/owner/../repo.git',
          'https://example.invalid/owner//repo.git',
          'https://example.invalid/.owner/repo.git',
          'https://example.invalid/owner/repo',
          'https://example.invalid/所有者/repo.git', $tooLong
        )) {
        Assert-BorrowingFailureCode {
          ConvertTo-BorrowingGitLocator $value
        } 'input' 'invalid-parameters'
      }
    }

    Invoke-CzxtContract 'Git ref accepts only full branch and tag refs after real Git validation' {
      $branch = ConvertTo-BorrowingGitRef 'refs/heads/main'
      Assert-CzxtEqual 'refs/heads/main' $branch.FullRef 'branch full ref'
      Assert-CzxtEqual 'branch' $branch.RefType 'branch ref type'
      $tag = ConvertTo-BorrowingGitRef 'refs/tags/v1.0.0'
      Assert-CzxtEqual 'tag' $tag.RefType 'tag ref type'
      foreach ($value in @(
          'main', 'HEAD', 'refs/pull/1/head', 'refs/heads/a b',
          'refs/heads/a..b', 'refs/heads/a~b', 'refs/heads/a^b',
          'refs/heads/a@{b', 'refs/heads/a.lock', 'refs/heads/a|b',
          'refs/heads/a`b', "refs/heads/a`tb", 'refs/heads/中文',
          ('refs/heads/' + ('a' * 1015))
        )) {
        Assert-BorrowingFailureCode {
          ConvertTo-BorrowingGitRef $value
        } 'input' 'invalid-parameters'
      }
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
