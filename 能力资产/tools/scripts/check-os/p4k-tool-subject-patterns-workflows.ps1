$script:P4kToolSubjectWorkflowChecks = @(
    @{ Path = "能力资产/tools/依赖矩阵.md"; Pattern = 'Claude Code 实施|Codex ship'; Label = "依赖矩阵仍用工具名定义新增依赖实施/ship 阶段" },
    @{ Path = "操作系统/01_架构/三类行为铁律-附录.md"; Pattern = '仅允许绑定 Codex 发布闭环'; Label = "三类行为铁律附录仍把版本 tag 责任绑定到工具而非测试发布 PM" },
    @{ Path = "操作系统/07_完整工作流/decision-checkpoint-附录.md"; Pattern = '外部工具战场'; Label = "decision-checkpoint 附录仍使用外部工具战场口径" },
    @{ Path = "操作系统/02_智能体/项目PM-咪咪.md"; Pattern = '外部工具回流|给外部工具|写交接卡给 Claude Code|写交接卡给 Codex|仍现行.*Claude Code|Claude Code/Codex 该怎么跑测试'; Label = "项目 PM playbook 仍把工具当交接对象或现行责任真源" },
    @{ Path = "操作系统/02_智能体/项目PM-咪咪-附录.md"; Pattern = '外部工具回流|给外部工具|写交接卡给 Claude Code|写交接卡给 Codex|仍现行.*Claude Code|Claude Code/Codex 该怎么跑测试'; Label = "项目 PM 附录仍把工具当交接对象或现行责任真源" },
    @{ Path = "操作系统/02_智能体/技术PM-修复决策者.md"; Pattern = '路由外部工具|手术 = Claude Code|写交接卡给 Claude Code|受众 = Claude Code|→ Claude Code（外部）|Claude Code 按|Claude Code 实施规范'; Label = "技术 PM playbook 仍把工具当实施主体或受众" },
    @{ Path = "操作系统/02_智能体/技术PM-修复决策者-附录.md"; Pattern = '路由外部工具|手术 = Claude Code|写交接卡给 Claude Code|受众 = Claude Code|→ Claude Code（外部）|Claude Code 按|Claude Code 实施规范'; Label = "技术 PM 附录仍把工具当实施主体或受众" },
    @{ Path = "操作系统/02_智能体/共享技能/INDEX.md"; Pattern = 'Codex 闭环前|Claude Code 完成代码后'; Label = "共享技能索引仍按工具阶段触发" },
    @{ Path = "操作系统/02_智能体/共享技能/真机smoke清单.md"; Pattern = 'Codex 闭环前|Claude Code 完成代码后|HEAD hash 与 Codex 报告一致'; Label = "真机 smoke 清单仍按工具阶段触发或绑定 Codex 报告" },
    @{ Path = "操作系统/02_智能体/共享技能/mount-stale防御.md"; Pattern = 'Codex push 后起手|Codex 报告 push 成功|HEAD hash 与 Codex 报告一致'; Label = "mount stale 防御仍绑定 Codex 报告主语" },
    @{ Path = "操作系统/02_智能体/共享技能/PM自纠-trigger.md"; Pattern = '状态\.md 末尾 PM 切换轨迹加一行'; Label = "PM 自纠共享技能仍让任意 PM 直接写状态轨迹" },
    @{ Path = "操作系统/02_智能体/开发PM-实施者.md"; Pattern = '{{APP_REPO_DIR}}/src/__tests__/\*\.test\.js'; Label = "开发 PM 测试路径白名单仍过窄" },
    @{ Path = "操作系统/02_智能体/项目PM-咪咪.md"; Pattern = '切产品 PM 写 PRD，再派开发 PM'; Label = "项目 PM playbook 仍把修 bug/已有实施项强行路由产品 PM" },
    @{ Path = "操作系统/02_智能体/README.md"; Pattern = '按角色边界白名单动手 → 状态\.md 留痕'; Label = "智能体 README 状态留痕缺落笔主体" }
)
