[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-source-card-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:SourceCardReady = $false
  Invoke-CzxtContract 'capture source-card renderer exists for Local golden' {
    Import-BorrowingSourceCardTestModules
    $script:SourceCardReady = $true
  }
  if ($script:SourceCardReady) {
    Invoke-CzxtContract 'Local source card matches the complete fixed-clock golden bytes' {
      $fingerprint = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
      $candidate = [pscustomobject]@{
        SourceType = 'local'; CanonicalLocator = 'local:fixture-local'
        FingerprintAlgorithm = 'sha256-manifest-v1'; Fingerprint = $fingerprint
        LocalFacts = [pscustomobject]@{
          ManifestAlgorithm = 'sha256-manifest-v1'; FileCount = 2; TotalBytes = 4
          Exclusions = '无'; Failures = '无'
        }
      }
      $expected = @'
---
schema: borrowing-source/v1
source_id: source-local
capture_id: local-20260719-bbbbbbbbbbbb
source_type: local
capture_status: ready
canonical_locator: local:fixture-local
fingerprint_algorithm: sha256-manifest-v1
fingerprint: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
captured_at: 2026-07-19T01:02:03.456Z
rights_status: unverified
access_policy: local-read-only
reuse_scope: inspect-and-analyze-only
execution_policy: deny
network_policy: deny
storage_policy: local-only
distribution_policy: deny
upstream_write_policy: deny
auto_refresh: false
---
# 来源版本卡

- 适用项目：`测试项目`
- 正式路径：`借鉴区/来源/source-local/local-20260719-bbbbbbbbbbbb/来源版本卡.md`
- 卡片只记录净化后的稳定身份与审计事实；绝对路径只进入同目录下被忽略的 `capture.local.json`，凭据不得写入。

## 权限授权

默认行的授权来源写 `default-policy`。任何偏离默认策略的生效值，都必须逐维填写 ISO 8601 授权时间、可审计来源和有限适用范围。

| 权限维度 | 生效值 | 授权时间 | 授权来源 | 适用范围 |
|---|---|---|---|---|
| rights_status | unverified | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| access_policy | local-read-only | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| reuse_scope | inspect-and-analyze-only | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| execution_policy | deny | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| network_policy | deny | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| storage_policy | local-only | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| distribution_policy | deny | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| upstream_write_policy | deny | 2026-07-19T01:02:03.456Z | default-policy | current-capture |
| auto_refresh | false | 2026-07-19T01:02:03.456Z | default-policy | current-capture |

## Git 捕获事实

| ref | ref 类型 | object format | commit | tree | submodule 状态 | LFS 状态 |
|---|---|---|---|---|---|---|
| not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |

## 本地捕获事实

| manifest 算法 | 文件数 | 字节数 | 排除项 | 失败项 |
|---|---:|---:|---|---|
| sha256-manifest-v1 | 2 | 4 | 无 | 无 |

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
          '767f6f07f63309306350a66bf643c609558050cb327922117eb5654226b99330' `
          $candidate 'Local')
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
