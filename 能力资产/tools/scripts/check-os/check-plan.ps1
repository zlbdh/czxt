function Get-OsCheckPlan {
  @(
    [PSCustomObject]@{
      Title = "【P4a】基础文件完整性检查..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4a-basic-integrity.ps1"; Failure = "P4a 基础文件完整性"; Args = "P4aPasses" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4b】字节大小体检（按工具分层）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4b-file-size.ps1"; Failure = "P4b 字节大小体检"; Args = "Warnings" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4c】framework 引用频率体检（操作系统/ + 能力资产/）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4c-framework-references.ps1"; Failure = "P4c framework 引用频率"; Args = "Failures" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4d】状态.md 新鲜度（30 天阈值）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4d-state-freshness.ps1"; Failure = "P4d 状态.md 新鲜度"; Warning = "P4d 状态.md stale"; After = "StateStale" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4e】Mount 缓存陷阱提醒（议题 D，PROP-018 P2，累计 10 次实战）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4e-mount-cache-reminder.ps1"; Failure = "P4e mount 缓存陷阱提醒" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4f】PM 切换轨迹自动检查（议题 AJ 留痕崩塌 9 次复发后防御）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4f-pm-tracking.ps1"; Failure = "P4f PM 切换轨迹自动检查"; Warning = "PM 轨迹崩塌警报 — 议题 AJ 第 10+ 次复发风险" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4g】列表类 README 一致性核查（ADR-032 v2 决定 6）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4g-readme-list-consistency.ps1"; Failure = "P4g 列表类 README 一致性核查"; Warning = "P4g 列表类 README 一致性软警告" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4h】当前版本/Sprint 锚点一致性（README/AGENTS/台账 vs package.json + 状态.md）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4h-version-sprint-anchor.ps1"; Failure = "P4h 当前版本/Sprint 锚点一致性" },
        [PSCustomObject]@{ Script = "check-os\p4h-ledger-anchor.ps1"; Failure = "P4h 台账版本/Sprint 锚点一致性" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4i】治理计数锚点一致性（README ADR/RETRO/PROP 计数 vs 真实文件）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4i-governance-count-anchor.ps1"; Failure = "P4i 治理计数锚点一致性" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4j】现行工作流旧口径守卫（decision-checkpoint Q1-Q7）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4j-workflow-legacy.ps1"; Failure = "P4j 现行工作流旧口径守卫" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4k】现行协作/规范旧口径守卫（跨角色 + 已填实文档 + 入口锚点）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4k-entry-anchor-legacy.ps1"; Failure = "P4k 入口锚点旧口径守卫" },
        [PSCustomObject]@{ Script = "check-os\p4k-role-boundary-legacy.ps1"; Failure = "P4k 角色边界旧口径守卫" },
        [PSCustomObject]@{ Script = "check-os\p4k-tool-subject-legacy.ps1"; Failure = "P4k 工具主语旧口径守卫" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4l】git/发布分支策略一致性（单 main）..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4l-git-branch.ps1"; Failure = "P4l git/发布分支策略一致性" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4m】skills 可复制命令新鲜度守卫..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4m-skills-command.ps1"; Failure = "P4m skills 可复制命令新鲜度守卫" },
        [PSCustomObject]@{ Script = "check-os\p4m-rules-command.ps1"; Failure = "P4m rules/skills 可复制性守卫" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4n】PM 工作区入口与 9 PM 对齐守卫..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4n-pm-workspace.ps1"; Failure = "P4n PM 工作区入口与 9 PM 对齐守卫" },
        [PSCustomObject]@{ Script = "check-os\p4n-playbook-workspace.ps1"; Failure = "P4n PM playbook 私人工作区入口守卫" },
        [PSCustomObject]@{ Script = "check-os\p4n-frontmatter.ps1"; Failure = "P4n PM 工作区 frontmatter 语义守卫" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4o】活跃 Markdown 相对链接/锚点守卫..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4o-markdown-links.ps1"; Failure = "P4o 活跃 Markdown 相对链接/锚点守卫" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4p】能力资产剩余区旧口径..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4p-capability-assets.ps1"; Failure = "P4p 能力资产旧口径" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4q】治理语义锚点..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4q-governance-semantics.ps1"; Failure = "P4q 治理语义" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4r】hooks 配置与运行态锚点..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4r-hooks-config.ps1"; Failure = "P4r hooks 配置与运行态锚点"; Warning = "P4r hooks scheduled/watch 软提醒" }
      )
    },
    [PSCustomObject]@{
      Title = "【P4s】模板纯净度守卫..."
      Checks = @(
        [PSCustomObject]@{ Script = "check-os\p4s-template-cleanliness.ps1"; Failure = "P4s 模板纯净度守卫" }
      )
    }
  )
}
