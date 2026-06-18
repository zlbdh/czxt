param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
. $common

Assert-Contains "操作系统\02_智能体\README.md" '9 PM 不等于 9 个常驻自动运行 agent' "02 README agent 常驻边界"
Assert-Contains "操作系统\02_智能体\README.md" '主会话按当前 PM 帽子与白名单收口 `状态.md`' "02 README 状态单源收口"

Assert-Contains "操作系统\02_智能体\项目PM-咪咪.md" '可收口写 `状态.md` / 交接卡 / chat ①-⑦' "项目 PM 收口写权"
Assert-Contains "操作系统\02_智能体\项目PM-咪咪.md" '不会静默改写语义文档、交接卡、`状态.md` 或 PM 轨迹' "自动化不静默改写"

Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" '单源由主会话按当前帽子落最后一笔' "操作系统 PM 单源落笔"
Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" '不自动移动；明确接收/完成后主会话流转' "交接区不自动移动"
Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" '{{APP_REPO_DIR}}/\.env\.local` baseUrl/model/apiKey' "env 例外精确字段"

Assert-Contains "操作系统\02_智能体\沉淀PM-沉淀者.md" '给项目 PM 主会话的 PM 轨迹自检报告' "沉淀 PM 状态报告边界"
Assert-Contains "操作系统\02_智能体\沉淀PM-沉淀者.md" '由项目 PM 按 Q7 派沉淀 PM explorer/worker' "沉淀 PM agent 实例化"
Assert-NotContains "操作系统\02_智能体\沉淀PM-沉淀者.md" '当前常由主会话承载' "沉淀 PM 旧载体口径"

Assert-Contains "操作系统\02_智能体\测试发布PM-闭环者.md" '常规版本 tag/push tag' "测试发布 PM 常规 tag"
Assert-Contains "操作系统\02_智能体\测试发布PM-闭环者.md" '删改移 tag' "测试发布 PM tag C 类"
Assert-Contains "操作系统\02_智能体\测试发布PM-闭环者.md" 'GitHub Release 与 APK 分发' "测试发布 PM Release/APK C 类"
Assert-Contains "操作系统\02_智能体\开发PM-实施者.md" '开发期本地自测' "开发 PM 本地自测边界"
Assert-Contains "操作系统\02_智能体\开发PM-实施者.md" '不等于发布/ship gate' "开发 PM 自测非 ship gate"
Assert-Contains "操作系统\02_智能体\测试PM-质量门户.md" '发布/ship gate 复核交给测试发布 PM' "测试 PM gate 边界"

Assert-Contains "操作系统\02_智能体\共享技能\INDEX.md" '测试发布 PM 闭环前；开发 PM 仅交接自查引用' "共享技能 smoke owner trigger"
Assert-Contains "操作系统\02_智能体\共享技能\INDEX.md" '测试发布 PM / 项目 PM' "共享技能 smoke owner"
Assert-NotContains "操作系统\02_智能体\共享技能\INDEX.md" '测试 / 项目 PM' "共享技能旧测试简称"
Assert-Contains "操作系统\02_智能体\共享技能\真机smoke清单.md" '执行 owner 是测试发布 PM「闭环者」' "真机 smoke 执行 owner"
Assert-Contains "操作系统\02_智能体\共享技能\真机smoke清单.md" '不执行真机 smoke、commit、tag、APK 或发布闭环' "开发 PM 不执行 smoke"

Assert-Contains "操作系统\02_智能体\测试PM-质量门户-附录.md" '先沉淀到自身 PM 工作区' "测试 PM 沉淀写权"
Assert-Contains "操作系统\02_智能体\测试PM-质量门户-附录.md" '由项目 PM 路由操作系统 PM 落笔' "测试策略进能力资产边界"
Assert-Contains "操作系统\02_智能体\测试PM-质量门户-附录.md" '由项目 PM写入交接卡' "测试 PM 不写交接卡"

Assert-Contains "操作系统\02_智能体\运营PM-运营咪咪.md" '唯一例外是 `交接区/分支间/运营咪咪→项目PM/待处理/`' "运营 PM 分支间交接例外"
Assert-Contains "操作系统\02_智能体\运营PM-运营咪咪.md" '不写 tracked/project 文件' "运营 PM 敏感信息边界"
Assert-NotContains "操作系统\02_智能体\运营PM-运营咪咪.md" '除非 zlbdh 明示' "运营 PM 旧敏感授权口径"
Assert-Contains "操作系统\02_智能体\运营PM-运营咪咪-附录.md" '项目 PM 只走分支间待处理卡' "运营素材池事件流"

Assert-Contains "操作系统\02_智能体\技术PM-修复决策者-附录.md" '如需交接卡，交给项目 PM 写入' "技术 PM 不写交接卡"
Assert-Contains "操作系统\02_智能体\产品PM-需求拆解者.md" '{{APP_REPO_DIR}}/src/\*\*/__tests__/' "产品 PM 测试路径禁写"
Assert-Contains "操作系统\02_智能体\产品PM-需求拆解者.md" 'PM 切角色硬检查协议' "产品 PM decision-checkpoint 口径"

Assert-Contains "操作系统\02_智能体\Dev-开发.md" '历史样例 — 旧写入策略（不可复制执行）' "Dev 历史写入策略边界"
Assert-Contains "操作系统\02_智能体\QA-测试.md" '历史样例：3 层验证（不可复制执行）' "QA 历史执行边界"
Assert-Contains "操作系统\02_智能体\PM-产品经理.md" '历史旧路径样例' "历史产品经理旧路径边界"

Assert-Contains "操作系统\01_架构\角色边界.md" 'commit/push/tag' "角色边界发布 tag"
Assert-Contains "操作系统\01_架构\角色边界.md" '项目只读；`PM工作区/运营PM-运营咪咪/` 写；分支间待处理卡例外' "角色边界运营 PM 分支例外"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 02_智能体 playbook 边界锚点对齐" -ForegroundColor Green
exit 0
