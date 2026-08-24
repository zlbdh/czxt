[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-source-card-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  $script:SourceCardReady = $false
  Invoke-CzxtContract 'capture source-card renderer exists for Web golden' {
    Import-BorrowingSourceCardTestModules
    $script:SourceCardReady = $true
  }
  if ($script:SourceCardReady) {
    Invoke-CzxtContract 'Web source card matches the complete fixed-clock golden bytes' {
      $fingerprint = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
      $candidate = [pscustomobject]@{
        SourceType = 'web'; CanonicalLocator = 'https://example.invalid/final'
        FingerprintAlgorithm = 'sha256-raw-bytes-v1'; Fingerprint = $fingerprint
        WebFacts = [pscustomobject]@{
          OriginalUrl = 'https://example.invalid/start'
          FinalUrl = 'https://example.invalid/final'
          RedirectChain = '[{"status_code":301,"location_url":"https://example.invalid/final"}]'
          StatusCode = 200; Mime = 'text/plain'; Charset = '"null"'; Etag = 'null'
          LastModified = '"Sun, 19 Jul 2026 01:00:00 GMT"'; ResponseHash = $fingerprint
        }
      }
      $expected = @'
---
schema: borrowing-source/v1
source_id: source-web
capture_id: web-20260719-cccccccccccc
source_type: web
capture_status: ready
canonical_locator: https://example.invalid/final
fingerprint_algorithm: sha256-raw-bytes-v1
fingerprint: cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
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
- 正式路径：`借鉴区/来源/source-web/web-20260719-cccccccccccc/来源版本卡.md`
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
| not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |

## 本地捕获事实

| manifest 算法 | 文件数 | 字节数 | 排除项 | 失败项 |
|---|---:|---:|---|---|
| not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |

## 网页捕获事实

| 原始 URL | 最终 URL | 重定向 | 状态码 | MIME | charset | ETag | Last-Modified | 响应哈希 |
|---|---|---|---:|---|---|---|---|---|
| https://example.invalid/start | https://example.invalid/final | [{"status_code":301,"location_url":"https://example.invalid/final"}] | 200 | text/plain | "null" | null | "Sun, 19 Jul 2026 01:00:00 GMT" | cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc |

## 管理历史

正式卡只允许 `ready` 或 `retired`；ready 后身份与指纹字段不可改写。退役只能追加历史，且必须先确认没有活动事项引用。

| 时间 | 旧状态 | 新状态 | 原因 | 确认 |
|---|---|---|---|---|
| 2026-07-19T01:02:03.456Z | none | ready | initial-capture | capture-executor |
'@
      [void](Assert-BorrowingSourceCardGolden $expected `
          'bd6a300c6452b0138f512a8b1a6b2ef8f3cd2ff94af0bf5cf50c09017f3339fb' `
          $candidate 'Web')
    }

    Invoke-CzxtContract 'Web source card rejects credential-bearing tracked facts defensively' {
      $fingerprint = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
      $root = New-BorrowingGoldenRoot 'web-credential-defense'
      $skeleton = Get-BorrowingValidatedSourceCardSkeleton -Root $root
      $token = 'glpat-1234567890abcdefghij'
      foreach ($case in @(
          @{ Field = 'SourceId'; Value = $token },
          @{ Field = 'CanonicalLocator'; Value = ('https://example.invalid/' + $token) },
          @{ Field = 'OriginalUrl'; Value = ('https://example.invalid/' + $token) },
          @{ Field = 'FinalUrl'; Value = ('https://example.invalid/' + $token) },
          @{ Field = 'RedirectChain'; Value =
              ('[{"status_code":301,"location_url":"https://example.invalid/' + $token + '"}]') },
          @{ Field = 'Charset'; Value = '"Bearer fixture-secret-token"' },
          @{ Field = 'Charset'; Value = '"X-API-Key: fixture-secret-value"' },
          @{ Field = 'Charset'; Value = '"api key = fixture-secret-value"' },
          @{ Field = 'Etag'; Value = '"{\"api_key\":\"fixture-secret-value\"}"' },
          @{ Field = 'Etag'; Value = '"{\"X-API-Key\":\"fixture-secret-value\"}"' },
          @{ Field = 'LastModified'; Value =
              '"api_key%2525253Dfixture-secret-value"' },
          @{ Field = 'LastModified'; Value = '"approved%252525253Dscope"' },
          @{ Field = 'LastModified'; Value = ('"' + $token + '"') }
        )) {
        $candidate = [pscustomobject]@{
          SourceType = 'web'; CanonicalLocator = 'https://example.invalid/final'
          FingerprintAlgorithm = 'sha256-raw-bytes-v1'; Fingerprint = $fingerprint
          WebFacts = [pscustomobject]@{
            OriginalUrl = 'https://example.invalid/start'
            FinalUrl = 'https://example.invalid/final'; RedirectChain = '[]'
            StatusCode = 200; Mime = 'text/plain'; Charset = 'null'; Etag = 'null'
            LastModified = 'null'; ResponseHash = $fingerprint
          }
        }
        $permissions = New-BorrowingGoldenPermissions 'web'
        if ($case.Field -ceq 'SourceId') {
          $permissions.SourceId = $case.Value
        }
        elseif ($case.Field -ceq 'CanonicalLocator') {
          $candidate.CanonicalLocator = $case.Value
        }
        else { $candidate.WebFacts.($case.Field) = $case.Value }
        Assert-BorrowingFailureCode {
          New-BorrowingSourceCardArtifactCore -Skeleton $skeleton `
            -Candidate $candidate -Permissions $permissions `
            -UtcNow $script:BorrowingGoldenClock
        } 'candidate' 'candidate-invalid'
      }
    }

    Invoke-CzxtContract 'source-card renderer rejects a credential-bearing project line' {
      $root = New-BorrowingGoldenRoot 'web-project-credential-defense'
      $path = Join-Path $root '借鉴区\模板\来源版本卡.md'
      $text = [IO.File]::ReadAllText($path, (New-Object Text.UTF8Encoding($false, $true)))
      Write-CzxtNoBomText $path $text.Replace('`测试项目`', '`Bearer abc`')
      $skeleton = Get-BorrowingValidatedSourceCardSkeleton -Root $root
      $fingerprint = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
      $candidate = [pscustomobject]@{
        SourceType = 'web'; CanonicalLocator = 'https://example.invalid/final'
        FingerprintAlgorithm = 'sha256-raw-bytes-v1'; Fingerprint = $fingerprint
        WebFacts = [pscustomobject]@{
          OriginalUrl = 'https://example.invalid/start'; FinalUrl = 'https://example.invalid/final'
          RedirectChain = '[]'; StatusCode = 200; Mime = 'text/plain'; Charset = 'null'
          Etag = 'null'; LastModified = 'null'; ResponseHash = $fingerprint
        }
      }
      Assert-BorrowingFailureCode {
        New-BorrowingSourceCardArtifactCore -Skeleton $skeleton -Candidate $candidate `
          -Permissions (New-BorrowingGoldenPermissions 'web') `
          -UtcNow $script:BorrowingGoldenClock
      } 'candidate' 'candidate-invalid'
    }

    Invoke-CzxtContract 'source-card renderer rejects a whitespace-key project line' {
      $root = New-BorrowingGoldenRoot 'web-project-whitespace-key-defense'
      $path = Join-Path $root '借鉴区\模板\来源版本卡.md'
      $text = [IO.File]::ReadAllText($path, (New-Object Text.UTF8Encoding($false, $true)))
      Write-CzxtNoBomText $path `
        $text.Replace('`测试项目`', '`api key = fixture-secret-value`')
      $skeleton = Get-BorrowingValidatedSourceCardSkeleton -Root $root
      $fingerprint = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
      $candidate = [pscustomobject]@{
        SourceType = 'web'; CanonicalLocator = 'https://example.invalid/final'
        FingerprintAlgorithm = 'sha256-raw-bytes-v1'; Fingerprint = $fingerprint
        WebFacts = [pscustomobject]@{
          OriginalUrl = 'https://example.invalid/start'; FinalUrl = 'https://example.invalid/final'
          RedirectChain = '[]'; StatusCode = 200; Mime = 'text/plain'; Charset = 'null'
          Etag = 'null'; LastModified = 'null'; ResponseHash = $fingerprint
        }
      }
      Assert-BorrowingFailureCode {
        New-BorrowingSourceCardArtifactCore -Skeleton $skeleton -Candidate $candidate `
          -Permissions (New-BorrowingGoldenPermissions 'web') `
          -UtcNow $script:BorrowingGoldenClock
      } 'candidate' 'candidate-invalid'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
