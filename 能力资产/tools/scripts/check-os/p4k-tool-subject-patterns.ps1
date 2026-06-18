$script:P4kToolSubjectChecks = @(
    @{ Path = "能力资产/tools/README.md"; Pattern = 'Codex/CC\s*战场|Codex\s*战场|Claude Code\s*战场'; Label = "tools README 仍用工具战场表述责任边界" },
    @{ Path = "能力资产/tools/构建脚本.md"; Pattern = 'Codex\s*战场|Claude Code\s*战场|PM / framework\s*战场'; Label = "构建脚本文档仍用工具战场表述责任边界" },
    @{ Path = "操作系统/02_智能体/操作系统PM-框架管家.md"; Pattern = '测试代码 = Claude Code|构建配置 = Codex / Claude Code|给 Claude Code|Codex\s*战场|`tools/\*\*`|业务 ignore 留 Claude Code|让 Claude Code 改 CHANGELOG|实际 commit 由 Codex 顺手带|外部工具战场|→ Claude Code|→ Codex'; Label = "操作系统 PM playbook 仍用工具名当责任主体或旧 tools 路径" },
    @{ Path = "操作系统/02_智能体/操作系统PM-框架管家-附录.md"; Pattern = '测试代码 = Claude Code|构建配置 = Codex / Claude Code|给 Claude Code|Codex\s*战场|`tools/\*\*`|业务 ignore 留 Claude Code|让 Claude Code 改 CHANGELOG|实际 commit 由 Codex 顺手带|外部工具战场|→ Claude Code|→ Codex'; Label = "操作系统 PM 附录仍用工具名当责任主体或旧 tools 路径" },
    @{ Path = "操作系统/02_智能体/产品PM-需求拆解者.md"; Pattern = 'Docs/2-技术文档|Claude Code\s*战场|Codex\s*战场|操作系统 PM\s*战场|`tools/\*\*`|{{APP_REPO_DIR}}/__tests__|→ Claude Code（外部）|Claude Code 实施|执行载体当前为 Claude Code|当前执行载体：Claude Code'; Label = "产品 PM playbook 仍有旧路径或工具战场责任表述" },
    @{ Path = "操作系统/02_智能体/产品PM-需求拆解者-附录.md"; Pattern = 'Docs/2-技术文档|Claude Code\s*战场|Codex\s*战场|操作系统 PM\s*战场|`tools/\*\*`|{{APP_REPO_DIR}}/__tests__|→ Claude Code（外部）|Claude Code 实施|执行载体当前为 Claude Code|当前执行载体：Claude Code'; Label = "产品 PM 附录仍有旧路径或工具战场责任表述" },
    @{ Path = "操作系统/02_智能体/开发PM-实施者.md"; Pattern = '跨工具可换'; Label = "开发 PM playbook 应写工具载体可换，不写跨工具可换" },
    @{ Path = "操作系统/02_智能体/测试PM-质量门户.md"; Pattern = '给 Claude Code|Claude Code 或 Codex\s*战场|Codex\s*战场|Claude Code / Codex 该怎么跑测试|执行 = Claude Code / Codex|P4 Codex|Codex 闭环|→ Claude Code（外部）|→ Codex（外部）|受众 = Claude Code / Codex|Codex 跑真机 smoke|Claude Code 按 QA|Codex 按 QA|Claude Code / Codex 测试执行规范|Claude Code 写测试代码风格'; Label = "测试 PM playbook 仍用工具战场表述执行边界" },
    @{ Path = "操作系统/02_智能体/测试PM-质量门户-附录.md"; Pattern = '给 Claude Code|Claude Code 或 Codex\s*战场|Codex\s*战场|Claude Code / Codex 该怎么跑测试|执行 = Claude Code / Codex|P4 Codex|Codex 闭环|→ Claude Code（外部）|→ Codex（外部）|受众 = Claude Code / Codex|Codex 跑真机 smoke|Claude Code 按 QA|Codex 按 QA|Claude Code / Codex 测试执行规范|Claude Code 写测试代码风格'; Label = "测试 PM 附录仍用工具战场表述执行边界" },
    @{ Path = "操作系统/02_智能体/测试发布PM-闭环者.md"; Pattern = '跨工具可换'; Label = "测试发布 PM playbook 应写工具载体可换，不写跨工具可换" },
    @{ Path = "操作系统/01_架构/三类行为铁律.md"; Pattern = '仅允许绑定 Codex 发布闭环'; Label = "三类行为铁律仍把版本 tag 责任绑定到工具而非测试发布 PM" },
    @{ Path = "操作系统/07_完整工作流/git流程.md"; Pattern = '由 Codex 端 push|Claude Code 写完代码|Codex 出 APK|Codex 发布闭环'; Label = "git 流程仍用工具名当发布/实施责任主体" },
    @{ Path = "操作系统/07_完整工作流/实施循环.md"; Pattern = 'Codex / zlbdh 在 Windows|Cowork 端 DoD|Claude Code 端 DoD|Codex 端 DoD'; Label = "实施循环仍按工具端定义 DoD 责任" },
    @{ Path = "操作系统/07_完整工作流/实施循环-附录.md"; Pattern = 'Codex / zlbdh 在 Windows|Cowork 端 DoD|Claude Code 端 DoD|Codex 端 DoD'; Label = "实施循环附录仍按工具端定义 DoD 责任" },
    @{ Path = "操作系统/07_完整工作流/发布流程.md"; Pattern = 'Codex / zlbdh 装机跑'; Label = "发布流程仍把 smoke 主责写成 Codex" },
    @{ Path = "操作系统/07_完整工作流/decision-checkpoint-判定细则.md"; Pattern = '外部工具战场|Codex\s*战场|Claude Code\s*战场|交接卡给\s*(Claude Code|Codex)'; Label = "decision-checkpoint 判定细则仍用工具名当责任主体" },
    @{ Path = "操作系统/01_架构/工具载体矩阵.md"; Pattern = '跨工具铁律'; Label = "工具载体矩阵仍把元规则池写成跨工具铁律" }
)
