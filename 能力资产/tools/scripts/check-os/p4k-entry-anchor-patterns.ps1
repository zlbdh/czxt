$script:EntryAnchorPatternRows = @'
状态.md§项目真相：`Docs/1-需求文档/Sprint-1需求清单\.md`§状态旧 Sprint-1 真相锚
TASKS.md§5KB\s*/\s*8KB 红区|trainingFixtures\.js 14\.7KB|Chat\.jsx 11827B§TASKS 旧 P4b/业务债口径
操作系统/00_变更记录/CHANGELOG.md§(?m)^# agent/ 演进日志|开发操作系统.*agent/ \+ framework§CHANGELOG 旧 agent/ 命名
能力资产/skills/项目体检.md§(?:当前|覆盖)\s+P4a[-–]P4[imnop]|P4a/P4b/P4c/P4d/P4e\s*自动覆盖§项目体检旧 P4
能力资产/skills/项目体检-检查项-7-8.md§当前\s+P4a[-–]P4[imnop]|P4a[-–]P4p§项目体检 7-8 旧 P4
操作系统/06_工具治理/framework体检.md§当前\s+P4a[-–]P4[imnop]|P4a[-–]P4[op] 自动守卫§framework体检旧 P4
操作系统/01_架构/子agent调度机制.md§当前\s+P4a[-–]P4[imnop]|P4a[-–]P4p§调度机制旧 P4
操作系统/01_架构/子agent调度机制-附录.md§当前\s+P4a[-–]P4[imnop]|P4a[-–]P4p§调度附录旧 P4
操作系统/07_完整工作流/hooks-运行SOP-附录.md§按\s+P4a[-–]P4[imnop]|P4a[-–]P4p§hooks SOP 旧 P4
操作系统/07_完整工作流/git流程.md§并删分支§git流程诱导删分支
操作系统/07_完整工作流/发布流程.md§v3\.0 release 发布|git tag -a v3\.0|git push origin v3\.0|GitHub 上发 Release|npm run test:run§发布流程旧版本/release/测试命令
操作系统/07_完整工作流/git流程.md§(?m)^\s*git add \.\s*$|utf8NoBOM|```bash\s*\r?\ncd D:\\WGKJ\\{{PROJECT_NAME}}\\{{APP_REPO_DIR}}§git流程旧实操示例
操作系统/07_完整工作流/审批与归档.md§(?s)ls 确认改动/.*grep "PROP-"§审批归档旧 bash/grep 查询
操作系统/07_完整工作流/实施循环-附录.md§出 dev APK \| ❌ \| ✅ build-apk\.bat|Codex（CLI）[^\r\n]*✅ build-apk\.bat§实施循环端能力旧 APK 命令
操作系统/07_完整工作流/实施循环-DoD.md§核心\s*5\s*项|旧\s*33\+\s*测试§DoD 旧核心/旧测试数
操作系统/07_完整工作流/decision-checkpoint-判定细则.md§接手后移\s*`已接手/`§交接卡过早移动
操作系统/07_完整工作流/实施循环-附录.md§TaskUpdate§旧工具名 TaskUpdate
操作系统/03_交接/交接卡格式.md§79/79§交接卡旧测试数
操作系统/02_智能体/开发PM-实施者.md§⑥-⑦§开发 PM 旧 chat 段
操作系统/01_架构/角色边界.md§全部 Read \+ 调度其他 8 PM|`{{APP_REPO_DIR}}/\*\*` 绝对硬护栏|单源禁并行文件：[^。]*`角色边界\.md`。§角色边界旧白名单
操作系统/01_架构/子agent调度机制.md§单源禁并行文件：[^。]*`角色边界\.md`。|禁并行写：[^。]*`角色边界\.md`。§调度漏自身单源
操作系统/02_智能体/沉淀PM-沉淀者.md§写入 `元规则池\.md`§沉淀直写元规则池
操作系统/02_智能体/测试发布PM-闭环者.md§`{{APP_REPO_DIR}}/package\.json` version 字段 / `{{APP_REPO_DIR}}/\.gitattributes`§闭环者配置旧口径
操作系统/01_架构/状态机.md§单人单 PM§状态机旧单 PM
操作系统/01_架构/README设计规范.md§远端 latest tag|31 README|## 六、关联§README 设计规范旧锚
操作系统/05_记忆/scope-schema.md§Sprint-10 PROP-039 集成 Mem0 后§scope-schema 旧排期
操作系统/01_架构/角色边界.md§不动手\s*\+\s*编排§角色边界旧不动手
操作系统/01_架构/工具载体矩阵.md§决策\s*\+\s*编排（不动手）§载体矩阵旧不动手
操作系统/02_智能体/README.md§不动手\s*\+\s*编排|默认考虑开 worker|可开 explorer§智能体 README 旧派发
确认改动/README.md§Claude Code\s*(正在做|干完|实施)§PROP 工具主语
PM工作区/项目PM-咪咪/README.md§每次新 session|议题backlog/|角色切换轨迹/§项目PM 工作区旧入口
PM工作区/沉淀PM-沉淀者/README.md§待 Sprint-8 启动后实战累积|速查表（待累积）|decision-checkpoint Q1-Q6§沉淀PM 旧占位
PM工作区/测试发布PM-闭环者/README.md§待 Sprint-8 启动后实战累积|新建占位§闭环者旧占位
操作系统/04_台账/项目沉淀/README.md§落地占位|v3\.8\.2|占位 / Sprint-8|loaded:\s*项目级元记忆§项目沉淀旧锚
能力资产/shared/品牌词典.md§待 zlbdh 确认（待补）§品牌词典待补
能力资产/shared/咪咪人设统一基准.md§v0 — 待完善§人设待完善
操作系统/05_记忆/INDEX.md§Cowork\s*↔\s*Codex\s*↔\s*Claude Code\s*三角协作§记忆工具三角
操作系统/05_记忆/INDEX.md§>6KB\s*/\s*>8KB§记忆阈值旧口径
操作系统/05_记忆/行为反思.md§Cowork\s*↔\s*Codex\s*↔\s*Claude Code\s*三角协作|Claude\s*起手必读§行为反思旧工具入口
操作系统/05_记忆/行为反思.md§文件\s*>6KB\s*必须用更稳§行为反思旧大小口径
操作系统/07_完整工作流/README.md§git流程\.md\)\s*\|\s*提交规范（占位\s*—\s*待补）§git流程旧占位
操作系统/02_智能体/运营PM-运营咪咪.md§首跑\s*ToDo|第一次启动\s*ToDo§运营主文旧 ToDo
操作系统/02_智能体/运营PM-运营咪咪-附录.md§首跑\s*ToDo|第一次启动\s*ToDo§运营附录旧 ToDo
能力资产/skills/状态推断.md§占位文件主动监控§状态推断旧名称
能力资产/skills/状态推断-跨session监控.md§该填实\s+(git流程\.md|安全与隐私\.md|mcp/README\.md)|占位文件主动监控§状态推断旧动作
能力资产/skills/状态推断-跨session监控-附录.md§该填实\s+(git流程\.md|安全与隐私\.md|mcp/README\.md)|占位文件主动监控§状态推断附录旧动作
'@
