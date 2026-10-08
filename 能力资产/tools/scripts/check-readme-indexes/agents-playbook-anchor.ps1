param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
. $common

Assert-Contains "操作系统\02_智能体\README.md" '(?:9 PM 不等于 9 个常驻自动运行 agent|Nine\ PMs\ do\ not\ imply\ nine\ permanent\ autonomous\ agents\.)' "Agent permanence boundary"
Assert-Contains "操作系统\02_智能体\README.md" '(?:主会话按当前 PM 帽子与白名单收口 `状态.md`|The\ main\ session\ finalizes\ the\ trace\ in\ `状态\.md`\ under\ its\ current\ PM\ role\ and\ allowlist)' "Single-source status finalization"

Assert-Contains "操作系统\02_智能体\项目PM-咪咪.md" '(?:可收口写 `状态.md` / 交接卡 / chat ①-⑦|finalize\ status,\ handoffs,\ and\ the\ seven\-part\ chat\ report)' "Project PM finalization authority"
Assert-Contains "操作系统\02_智能体\项目PM-咪咪.md" '(?:不会静默改写语义文档、交接卡、`状态.md` 或 PM 轨迹|It\ does\ not\ silently\ rewrite\ semantic\ documents,\ handoff\ cards,\ status,\ or\ PM\ traces\.)' "No silent semantic rewrites"

Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" '(?:单源由主会话按当前帽子落最后一笔|the\ main\ session\ makes\ the\ final\ single\-source\ write\ under\ its\ current\ role)' "Operating System PM single-source finalization"
Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" '(?:不自动移动；明确接收/完成后主会话流转|No\ automatic\ moves;\ main\ session\ transitions\ only\ after\ explicit\ receipt/completion)' "No automatic handoff moves"
Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" (([regex]::Escape('{{APP_REPO_DIR}}') + '/\.env\.local` baseUrl/model/apiKey') + '|baseUrl/model/apiKey\ in\ `\{\{APP_REPO_DIR\}\}/\.env\.local`') "Exact environment exception fields"

Assert-Contains "操作系统\02_智能体\沉淀PM-沉淀者.md" '(?:给项目 PM 主会话的 PM 轨迹自检报告|Trace\ self\-check\ report\ to\ Project\ PM;\ main\ session\ decides\ and\ finalizes\ status\ writes)' "Knowledge PM status-report boundary"
Assert-Contains "操作系统\02_智能体\沉淀PM-沉淀者.md" '(?:由项目 PM 按 Q7 派沉淀 PM explorer/worker|Project\ PM\ dispatches\ a\ Knowledge\ PM\ explorer\ or\ worker\ under\ Q7\.)' "Knowledge PM agent dispatch"
Assert-NotContains "操作系统\02_智能体\沉淀PM-沉淀者.md" '(?:当前常由主会话承载|Currently\ usually\ carried\ by\ the\ main\ session)' "Obsolete Knowledge PM runtime language"

Assert-Contains "操作系统\02_智能体\测试发布PM-闭环者.md" '(?:常规版本 tag/push tag|Ordinary\ version\ tags\ and\ tag\ pushes\ follow\ these\ six\ conditions\.)' "Ordinary release tags"
Assert-Contains "操作系统\02_智能体\测试发布PM-闭环者.md" '(?:删改移 tag|Deleting,\ rewriting,\ or\ moving\ tags)' "Class C tag restrictions"
Assert-Contains "操作系统\02_智能体\测试发布PM-闭环者.md" '(?:GitHub Release 与 APK 分发|GitHub\ Releases;\ APK\ distribution)' "Class C release and APK restrictions"
Assert-Contains "操作系统\02_智能体\开发PM-实施者.md" '(?:开发期本地自测|Local\ development\ vitest\ checks)' "Development PM local-test boundary"
Assert-Contains "操作系统\02_智能体\开发PM-实施者.md" '(?:不等于发布/ship gate|these\ do\ not\ constitute\ a\ release\ or\ ship\ gate)' "Local tests are not a ship gate"
Assert-Contains "操作系统\02_智能体\测试PM-质量门户.md" '(?:发布/ship gate 复核交给测试发布 PM|Test\ and\ Release\ PM\ rechecks\ release/ship\ gates\.)' "Test PM release-gate boundary"

Assert-Contains "操作系统\02_智能体\共享技能\INDEX.md" '(?:测试发布 PM 闭环前；开发 PM 仅交接自查引用|Before\ Test\ and\ Release\ PM\ completion;\ Development\ PM\ references\ it\ only\ for\ handoff\ self\-checks)' "Shared smoke-skill trigger owner"
Assert-Contains "操作系统\02_智能体\共享技能\INDEX.md" '(?:测试发布 PM / 项目 PM|Test\ and\ Release\ PM\ /\ Project\ PM)' "Shared smoke-skill owner"
Assert-NotContains "操作系统\02_智能体\共享技能\INDEX.md" '(?:测试 / 项目 PM|Test\ /\ Project\ PM)' "Obsolete shared-skill testing abbreviation"
Assert-Contains "操作系统\02_智能体\共享技能\真机smoke清单.md" '(?:执行 owner 是测试发布 PM「闭环者」|The\ execution\ owner\ is\ Test\ and\ Release\ PM\ “Closer\.”)' "Physical-device smoke execution owner"
Assert-Contains "操作系统\02_智能体\共享技能\真机smoke清单.md" '(?:不执行真机 smoke、commit、tag、APK 或发布闭环|it\ does\ not\ execute\ physical\-device\ smoke,\ commit,\ tag,\ APK,\ or\ release\ completion\.)' "Development PM does not execute device smoke"

Assert-Contains "操作系统\02_智能体\测试PM-质量门户-附录.md" '(?:先沉淀到自身 PM 工作区|Keep\ reusable\ strategy\ in\ the\ role''s\ own\ workspace\ first\.)' "Test PM private knowledge authority"
Assert-Contains "操作系统\02_智能体\测试PM-质量门户-附录.md" '(?:由项目 PM 路由操作系统 PM 落笔|Project\ PM\ routes\ the\ write\ to\ Operating\ System\ PM\.)' "Test strategy capability-asset boundary"
Assert-Contains "操作系统\02_智能体\测试PM-质量门户-附录.md" '(?:由项目 PM写入交接卡|Project\ PM,\ who\ records\ it\ in\ a\ handoff)' "Test PM does not write handoffs"

Assert-Contains "操作系统\02_智能体\运营PM-运营咪咪.md" '(?:唯一例外是 `交接区/分支间/运营咪咪→项目PM/待处理/`|The\ sole\ exception\ is\ `交接区/分支间/运营咪咪→项目PM/待处理/`\.)' "Operations PM cross-branch handoff exception"
Assert-Contains "操作系统\02_智能体\运营PM-运营咪咪.md" '(?:不写 tracked/project 文件|never\ write\ account\ passwords,\ financial\ data,\ or\ personal\ user\ data\ into\ memory\ or\ tracked/project\ files\.)' "Operations PM sensitive-data boundary"
Assert-NotContains "操作系统\02_智能体\运营PM-运营咪咪.md" '(?:除非 zlbdh 明示|unless\ zlbdh\ explicitly\ instructs\ otherwise)' "Obsolete sensitive-data authorization language"
Assert-Contains "操作系统\02_智能体\运营PM-运营咪咪-附录.md" '(?:项目 PM 只走分支间待处理卡|Project\ PM\ uses\ pending\ cross\-branch\ cards)' "Operations material-pool event flow"

Assert-Contains "操作系统\02_智能体\技术PM-修复决策者-附录.md" '(?:如需交接卡，交给项目 PM 写入|Project\ PM\ writes\ any\ needed\ handoff)' "Technical PM does not write handoffs"
Assert-Contains "操作系统\02_智能体\产品PM-需求拆解者.md" ([regex]::Escape('{{APP_REPO_DIR}}') + '/src/\*\*/__tests__/') "Product PM test-path write prohibition"
Assert-Contains "操作系统\02_智能体\产品PM-需求拆解者.md" '(?:PM 切角色硬检查协议|mandatory\ role\-switching\ protocol)' "Product PM checkpoint protocol"

Assert-Contains "操作系统\02_智能体\Dev-开发.md" '(?:历史样例 — 旧写入策略（不可复制执行）|Historical\ write\ strategy\ —\ do\ not\ copy\ into\ execution)' "Historical Dev write-strategy boundary"
Assert-Contains "操作系统\02_智能体\QA-测试.md" '(?:历史样例：3 层验证（不可复制执行）|Historical\ example:\ three\ verification\ layers\ —\ do\ not\ copy\ into\ execution)' "Historical QA execution boundary"
Assert-Contains "操作系统\02_智能体\PM-产品经理.md" '(?:历史旧路径样例|Historical\ path\ example)' "Legacy Product Manager path context"

Assert-Contains "操作系统\01_架构\角色边界.md" 'commit/push/tag' "Release tags in role boundaries"
Assert-Contains "操作系统\01_架构\角色边界.md" '项目只读；`PM工作区/运营PM-运营咪咪/` 写；分支间待处理卡例外|Read-only project access; write `PM工作区/运营PM-运营咪咪/`; exception for pending cross-branch cards' "Operations PM cross-branch exception in role boundaries"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ Agent playbook boundary anchors aligned" -ForegroundColor Green
exit 0
