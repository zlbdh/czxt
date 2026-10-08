function Get-OsCheckPlan {
  @(
    [PSCustomObject]@{
      Title = "【P4a】 Checking required file integrity..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4a-basic-integrity.ps1"; Failure = "P4a required file integrity"; Args = "P4aPasses" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4b】 Checking byte sizes by tool tier..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4b-file-size.ps1"; Failure = "P4b byte-size check"; Args = "Warnings" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4c】 Checking framework reference frequency (操作系统/ + 能力资产/)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4c-framework-references.ps1"; Failure = "P4c framework reference frequency"; Args = "Failures" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4d】 Checking 状态.md freshness (30-day threshold)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4d-state-freshness.ps1"; Failure = "P4d 状态.md freshness"; Warning = "P4d 状态.md stale"; After = "StateStale" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4e】 Mount-cache reminder (issue D, PROP-018 P2, ten recorded incidents)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4e-mount-cache-reminder.ps1"; Failure = "P4e mount-cache reminder" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4f】 Checking PM transition traces (safeguard after nine issue AJ recurrences)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4f-pm-tracking.ps1"; Failure = "P4f PM transition trace check"; Warning = "PM trace failure alert: risk of issue AJ recurring for the tenth time or more" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4g】 Checking README list consistency (ADR-032 v2 decision 6)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4g-readme-list-consistency.ps1"; Failure = "P4g README list consistency"; Warning = "P4g README list consistency warning" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4h】 Checking current version/Sprint anchors (README/AGENTS/ledgers vs package.json + 状态.md)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4h-version-sprint-anchor.ps1"; Failure = "P4h current version/Sprint anchor consistency" },
        [PSCustomObject]@{ Script = "check-os\p4h-ledger-anchor.ps1"; Failure = "P4h ledger version/Sprint anchor consistency" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4i】 Checking governance count anchors (README ADR/RETRO/PROP counts vs actual files)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4i-governance-count-anchor.ps1"; Failure = "P4i governance count anchor consistency" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4j】 Checking current workflows for obsolete language (decision-checkpoint Q1-Q7)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4j-workflow-legacy.ps1"; Failure = "P4j current workflow obsolete-language guard" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4k】 Checking collaboration and specifications for obsolete language (roles, completed documents, and entry anchors)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4k-entry-anchor-legacy.ps1"; Failure = "P4k entry-anchor obsolete-language guard" },
        [PSCustomObject]@{ Script = "check-os\p4k-role-boundary-legacy.ps1"; Failure = "P4k role-boundary obsolete-language guard" },
        [PSCustomObject]@{ Script = "check-os\p4k-tool-subject-legacy.ps1"; Failure = "P4k tool-subject obsolete-language guard" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4l】 Checking Git/release branch-policy consistency (single main branch)..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4l-git-branch.ps1"; Failure = "P4l Git/release branch-policy consistency" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4m】 Checking skill command examples for currency..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4m-skills-command.ps1"; Failure = "P4m skill command currency guard" },
        [PSCustomObject]@{ Script = "check-os\p4m-rules-command.ps1"; Failure = "P4m rule/skill command usability guard" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4n】 Checking workspace entries against the nine PM roles..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4n-pm-workspace.ps1"; Failure = "P4n workspace and nine-PM alignment guard" },
        [PSCustomObject]@{ Script = "check-os\p4n-playbook-workspace.ps1"; Failure = "P4n PM playbook private-workspace entry guard" },
        [PSCustomObject]@{ Script = "check-os\p4n-frontmatter.ps1"; Failure = "P4n PM workspace frontmatter semantics guard" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4o】 Checking active Markdown relative links and anchors..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4o-markdown-links.ps1"; Failure = "P4o active Markdown relative-link and anchor guard" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4p】 Checking remaining capability assets for obsolete language..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4p-capability-assets.ps1"; Failure = "P4p capability-asset obsolete-language guard" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4q】 Checking governance semantic anchors..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4q-governance-semantics.ps1"; Failure = "P4q governance semantics" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4r】 Checking hooks configuration and runtime anchors..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4r-hooks-config.ps1"; Failure = "P4r hooks configuration and runtime anchors"; Warning = "P4r hooks scheduled/watch reminder" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4s】 Checking template neutrality..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4s-template-cleanliness.ps1"; Failure = "P4s template-neutrality guard" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4t】 Checking borrowing completion consistency..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4t-borrowing-consistency.ps1"; Failure = "P4t borrowing completion consistency"; Warning = "P4t borrowing completion warning" }
      )
    }
  )
}
