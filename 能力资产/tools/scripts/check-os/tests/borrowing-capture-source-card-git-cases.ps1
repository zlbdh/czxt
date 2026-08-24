[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-source-card-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:SourceCardReady = $false
  Invoke-CzxtContract 'capture source-card renderer exists for Git golden' {
    Import-BorrowingSourceCardTestModules
    $script:SourceCardReady = $true
  }
  if ($script:SourceCardReady) {
    Invoke-CzxtContract 'Git source card matches the complete fixed-clock golden bytes' {
      $fingerprint = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      $candidate = [pscustomobject]@{
        SourceType = 'git'; CanonicalLocator = 'https://example.invalid/owner/repo.git'
        FingerprintAlgorithm = 'git-object'; Fingerprint = $fingerprint
        GitFacts = [pscustomobject]@{
          Ref = 'refs/heads/main'; RefType = 'branch'; ObjectFormat = 'sha1'
          Commit = $fingerprint; Tree = 'dddddddddddddddddddddddddddddddddddddddd'
          SubmoduleStatus = 'detected'; LfsStatus = 'not-detected'
        }
      }
      $expected = @'
---
schema: borrowing-source/v1
source_id: source-git
capture_id: git-20260719-aaaaaaaaaaaa
source_type: git
capture_status: ready
canonical_locator: https://example.invalid/owner/repo.git
fingerprint_algorithm: git-object
fingerprint: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
captured_at: 2026-07-19T01:02:03.456Z
rights_status: unverified
access_policy: source-read-only
reuse_scope: inspect-and-analyze-only
execution_policy: deny
network_policy: source-read-only
storage_policy: local-only
distribution_policy: deny
upstream_write_policy: deny
auto_refresh: false
---
# 来源版本卡

- 适用项目：`测试项目`
- 正式路径：`借鉴区/来源/source-git/git-20260719-aaaaaaaaaaaa/来源版本卡.md`
- 卡片只记录净化后的稳定身份与审计事实；绝对路径只进入同目录下被忽略的 `capture.local.json`，凭据不得写入。

## 权限授权

默认行的授权来源写 `default-policy`。任何偏离默认策略的生效值，都必须逐维填写 ISO 8601 授权时间、可审计来源和有限适用范围。

| 权限维度 | 生效值 | 授权时间 | 授权来源 | 适用范围 |
|---|---|---|---|---|
| rights_status | unverified | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| access_policy | source-read-only | 2026-07-19T01:00:00.000Z | approved-fixture | current-capture |
| reuse_scope | inspect-and-analyze-only | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| execution_policy | deny | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| network_policy | source-read-only | 2026-07-19T01:00:00.000Z | approved-fixture | current-capture |
| storage_policy | local-only | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| distribution_policy | deny | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| upstream_write_policy | deny | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| auto_refresh | false | 2026-07-19T01:02:03.456Z | default-policy | current-capture |

## Git 捕获事实

| ref | ref 类型 | object format | commit | tree | submodule 状态 | LFS 状态 |
|---|---|---|---|---|---|---|
| refs/heads/main | branch | sha1 | aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa | dddddddddddddddddddddddddddddddddddddddd | detected | not-detected |

## 本地捕获事实

| manifest 算法 | 文件数 | 字节数 | 排除项 | 失败项 |
|---|---:|---:|---|---|
| not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |

## 网页捕获事实

| 原始 URL | 最终 URL | 重定向 | 状态码 | MIME | charset | ETag | Last-Modified | 响应哈希 |
|---|---|---|---:|---|---|---|---|---|
| not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |

## 管理历史

正式卡只允许 `ready` 或 `retired`；ready 后身份与指纹字段不可改写。退役只能追加历史，且必须先确认没有活动事项引用。

| 时间 | 旧状态 | 新状态 | 原因 | 确认 |
|---|---|---|---|---|
| 2026-07-19T01:02:03.456Z | none | ready | initial-capture | capture-executor |
'@
      [void](Assert-BorrowingSourceCardGolden $expected `
          '286885319122f6398eabe17eceeaf62f44062f4534132a5983aa4a761b4a2dd0' `
          $candidate 'Git')
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
