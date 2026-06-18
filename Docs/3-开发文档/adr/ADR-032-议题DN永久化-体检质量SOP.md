---
name: adr-032
scope: project
type: semantic
loaded: on-demand
description: ADR-032 议题 DN 体检质量 SOP 永久化（第 15 元规则）— 治 PM 自纠 #88/#89/#90 三次体检盲区
---

# ADR-032 · 议题 DN 永久化：Framework 体检质量 SOP（第 15 元规则）

- **状态**：现行
- **日期**：2026-05-28
- **关联**：[RETRO-013](../../7-复盘/RETRO-013-2026-05.md) · [PM 自纠 #88+#89 批次](../../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-88+89-体检盲区-批次.md) · [PM 自纠 #90](../../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-90.md) · [README 设计规范](../../../操作系统/01_架构/README设计规范.md) · [PROP-042](../../../确认改动/已审批/已完成/PROP-042-2026-05-28-大文件红区拆分清单.md)
- **议题 DN 关闭条件**：4 次同模式累积（PM 自纠 #88/#89/#90 + **#91 ADR README 长期过时**）+ 防御 SOP 已实战 ✅ 达成
- **v2 升级（task #124 / 2026-05-28）**：加决定 6「列表类 README 一致性核查」+ 修订决定 4（3 套档案→4 套）

## 背景

2026-05-28 Sprint-10 治理 sprint 中,Framework 体检**连续 3 次出盲区**:

| # | 错向 | 暴露任务 |
|---|---|---|
| #88 | 体检判 `PM-产品经理.md` 为"该删的残留",**没看文件内 ADR-007 保留说明** → 差点违反历史档案铁律 | task #117 启动 PROP-042 时 |
| #89 | 体检红区**只看字节数 >8KB**,没看"可拆性 vs 核心性" → 强拆核心损害高频体验 | task #118 PROP-042 第 2-3 棒撤回时 |
| #90 | 体检**只 `find -name README.md`**,漏 `00_总入口.md` `AGENTS.md` `INDEX*` 等入口 → 议题 BE 起手必查崩塌 | task #121 起手入口核查时 |

三次同模式 = 体检 SOP 系统性缺位 → 升 ADR-032。

## 决定

议题 DN **正式永久关闭**,作为**第 15 元规则**进入永久化池。

### 决定 1 — 入口类文件扩展定义（治 #90）

Framework 体检的"入口类文件" **不只 README**,完整定义:

```bash
find . \( -name "README.md" \
       -o -name "AGENTS.md" \
       -o -name "00_总入口*" \
       -o -name "总入口*" \
       -o -name "INDEX.md" \) \
   -not -path "*/.git/*" \
   -not -path "*/node_modules/*" \
   -not -path "*/已接手/*" \
   -not -path "*/状态-archive/*"
```

任一入口类文件含以下关键词**必核 vs 当前 v4.0 终态**:
- "5 PM" / "6 PM" / "8 PM" / "10 PM" → 应为 "9 PM × 4 层"
- "PM-产品经理" / "Dev-开发" / "QA-测试" → 旧 PM 命名（ADR-007 历史档案豁免除外）
- "v2.x" / "v3.x" 等版本号 → 检查是否对齐 {{APP_REPO_DIR}}/package.json + 远端 latest tag

### 决定 2 — 大文件红区判定 v2（治 #89）

>8KB 标红时**必跟"可拆性 vs 核心性"判定**:

1. 先 `awk` 统计段字节分布（每个 `## ` 二级标题段）
2. 评估每段:**长尾**（案例/历史/参考 / 按需读）vs **核心**（高频判定 / 必读）
3. **只对"长尾段 ≥30% 文件大小"建议拆**
4. 全核心文件 → **接受软警戒 / 不强拆**（8KB 是工程审美建议非硬规则 / AGENTS.md 明文）

实战参考:
- ✅ `decision-checkpoint.md` 18KB → 失败案例/留痕示例/AJ 关闭历史/关联 ~5KB 长尾 → 拆附录成功（task #117）
- ❌ `INDEX.md` 14.8KB → 6 节都核心,唯一历史段只 728B → 不拆（task #118 撤回）
- ❌ `角色边界.md` 13.6KB → 全核心 9 PM 矩阵 → 不拆（task #118 撤回）

### 决定 3 — 历史档案豁免必看文件内说明（治 #88）

体检判"该删/该废"前**必读文件内是否有**:
- "**保留作历史档案**"
- "**ADR-007 不动历史档案铁律**"
- "**吸收并替代**...保留旧文件"
- "**历史档案 / 已被 X 取代**"

任一存在 → **该文件是有意保留 / 不删 / 议题 AY 豁免**。

### 决定 4 — 体检前必查 4 套档案（永久化 / v2 升级 / 加第 4 套）

```
1. 全工程入口类文件清单（决定 1 find 命令）
2. 全工程 >8KB 大文件清单（find -size +8192c）
3. 全工程 frontmatter 缺失清单（grep -L "^---")
🆕 4. 列表类 README/.md 一致性核查（决定 6）
```

→ 形成体检前置 SOP,**任何 framework 体检任务必跑此 4 套**。

### 🆕 决定 6 — 列表类 README 一致性核查（v2 / PM 自纠 #91 治理）

任何"索引 / 列表 / 汇总"类 README/.md **必跟实际文件数同步**:

| 列表类文件 | 一致性核对 |
|---|---|
| `Docs/3-开发文档/adr/README.md` 表格 | vs `ls Docs/3-开发文档/adr/ADR-*.md \| wc -l` |
| `操作系统/04_台账/议题全景.md` "永久关闭 ADR 现行表" | vs ADR 文件中议题永久化类数 |
| `操作系统/01_架构/元规则池.md` "v3.X / N 永久" 字段 | vs 二表行数 |

**bash 一键核查**（集成 `能力资产/tools/scripts/check-operating-system.ps1` Sprint-11 候选）:
```bash
adr_files=$(ls Docs/3-开发文档/adr/ADR-*.md | wc -l)
adr_readme=$(grep -c "^| ADR-" Docs/3-开发文档/adr/README.md)
[ "$adr_files" = "$adr_readme" ] || echo "🔴 不一致 / 文件 $adr_files vs README $adr_readme"

panorama_adr=$(grep -cE "^\| \*\*🆕? ADR-|^\| \*\*ADR-" 操作系统/04_台账/议题全景.md)
echo "议题全景 ADR 永久表行数: $panorama_adr"

pool_rows=$(sed -n '/## 二、/,/## 三、/p' 操作系统/01_架构/元规则池.md | grep -cE '^\| \*\*')
echo "元规则池二表行数: $pool_rows"
```

**双复核责任**:
- **操作系统 PM「框架管家」起 ADR 时**:立刻同步 3 处（ADR README + 议题全景 + 元规则池）/ 不可只更新 ADR 文件本身
- **沉淀 PM「沉淀者」每周**:跑 bash 三处一致性核查 / 不一致触发修复

**自动化路径**（终极防御）:
- 集成 `check-operating-system.ps1` P4? 段一键核查（Sprint-11 候选）
- PROP-038 Hooks GA 后 file watch on ADR 目录 → 自动更新 README（Sprint-9+）

### 决定 5 — 元规则池升级 14 → 15（永久化第 15 元规则）

```
G / AT / AM / AO / BC / BE(ADR-029) / AJ(ADR-023) / P(ADR-024)
BK(ADR-025) / CT(ADR-026) / CU+DD(ADR-027) / CW(ADR-028)
CC(ADR-030) / DH+DK+DF(ADR-031)
🆕 DN 体检质量 SOP → ADR-032 本 ADR
```

## 后果

### 收益
- ✅ 体检盲区不再复发（#88/#89/#90 三类已防御）
- ✅ Framework 体检 SOP 系统化（不再"我以为查了 README 就够"）
- ✅ 历史档案 + 红区 + 入口三个维度统一治理

### 风险与缓解
| 风险 | 缓解 |
|---|---|
| SOP 执行成本（3 套 find 每次都跑） | 集成到 `能力资产/tools/scripts/check-operating-system.ps1` P4? 段 / 一键跑 |
| "长尾段 ≥30%" 判定主观 | 提供实战参考（decision-checkpoint vs INDEX 对比）/ 沉淀 PM 经验持续累积 |

### 验证
| 维度 | 结果 |
|---|---|
| 决定 1 落地 | task #121 用 find 多入口扫,发现 2 个新过时点 ✅ |
| 决定 2 落地 | task #117 拆 decision-checkpoint ✅ / task #118 撤回 INDEX/角色边界 ✅ |
| 决定 3 落地 | task #117 PM 自纠 #88 撤回删 PM-产品经理.md ✅ |

## 实施清单（追溯 + 后续）

- ✅ PM 自纠 #88+#89 批次 artifact 化（task #118）
- ✅ PM 自纠 #90 独立 artifact（task #121）
- ✅ README 设计规范.md 新建（task #120 / 议题 DN 雏形）
- ✅ 本 ADR 起稿（task #122）
- ⏳ check-operating-system.ps1 集成 3 套 SOP（Sprint-11+ 候选）
- ⏳ 沉淀 PM 速查表 D 类规则更新（加 #90 教训）

## 引用决议
- PM 自纠 #88: PM-产品经理.md 误判（ADR-007 历史档案）
- PM 自纠 #89: 字节数盲区（PROP-042 第 2-3 棒撤回）
- PM 自纠 #90: 入口类文件遗漏（00_总入口/INDEX 等）
- 🆕 PM 自纠 #91: ADR README 长期过时（停 ADR-025 缺 7 个 / 列表类一致性失守 / v2 触发）
- 议题 BE 起手必查（ADR-029）— 入口文件过时 = BE 崩塌
- 议题 AY 大文件治理 — 软警戒非硬规则

---

⭐ **ADR-032 永久现行 / 第 15 元规则 / 体检质量 SOP 系统化**
