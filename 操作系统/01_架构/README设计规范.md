---
name: readme-design-spec
scope: project
type: semantic
loaded: on-demand
description: README 体系设计规范（议题 DN / task #120）— 必含 3 段 + frontmatter + 更新触发 + 议题 BE 起手必查防御
---

# README 设计 + 更新规范（议题 DN / Sprint-10 沉淀）

> ⭐ **背景**：Sprint-10 体检发现 31 个 README 中 3 个严重过时（项目根写 v2.3 实际 v3.10.0 / 02_智能体 还列旧 PM-产品经理 / PM工作区写 6 PM 实际 9 PM）。这些 README 是议题 BE 起手必查的真威胁 —— 新会话读到过时版会带偏判断。
> ⭐ **依据**：PROP-040 task #120 + PM 自纠 #88（误判 ADR-007 历史档案）/ PM 自纠 #89（体检字节盲区）

---

## 一、必含 3 段（任何 README 不可缺）

```markdown
---
name: <kebab-case-slug>
scope: project | agent | session
type: semantic | procedural
loaded: always | on-demand | triggered
description: <一句话 ≤120 字 / 含核心范围>
---

# <目录名> — <一句话定位>

## 这一组讲什么（30 秒读懂）

## 文件清单（表格 / 每行 ≤80 字）

## 跟其他分组的区别（防混淆）
```

可选第 4 段「关联」/ 第 5 段「速记」(<500B 才加 / 议题 CO 极简)。

---

## 二、按 scope 分类设计

| 路径 | scope | type | loaded | 典型 |
|---|---|---|---|---|
| 项目根 `README.md` | project | semantic | always | 含"AI 新会话第一动作" |
| `操作系统/*/README.md` | project | semantic | on-demand | framework 子分组入口 |
| `能力资产/*/README.md` | project | semantic/procedural | on-demand | 执行能力子分组 |
| `PM工作区/<PM>/README.md` | **agent** | semantic | on-demand | 私人工作区入口 / `agent: <PM 名>` |
| `Docs/*/README.md` | project | semantic | on-demand | 文档分组（ADR/RETRO 列表）|

---

## 三、更新触发（谁负责更新）

| 触发场景 | 必更 README | 责任 PM |
|---|---|---|
| 业务新版本 ship | 项目根 README "当前最新 vX.Y.Z" | 项目 PM ship 收档时 |
| 9 PM 矩阵升级（如 v3→v4 / 加新 PM） | `操作系统/02_智能体/README` + `PM工作区/README` + 项目根 README 9 PM 速记 | 操作系统 PM |
| 新增 ADR | `Docs/3-开发文档/adr/README` | 操作系统 PM 起 ADR 时 |
| Sprint 末 | 各 PM 工作区 README 速查表清单更新 | 沉淀 PM 体检维护 |
| 新建/重命名/合并目录 | 父级 README 文件清单 | 操作系统 PM |

---

## 四、议题 DN 体检 SOP（PM 自纠 #88 + #89 教训永久化）

体检 README 时**必跑 3 步**:

1. **看版本号**:项目根 README "当前最新 vX.Y.Z" 是否等于 `{{APP_REPO_DIR}}/package.json` version？
2. **看架构号**:涉及 9 PM 矩阵的 README 是否含 "v4.0" / "9 PM × 4 层" 关键词？
3. **看历史档案**:大文件 >8KB 判"该拆"前**必看文件内是否有"保留作历史档案" / ADR-007 类说明**（PM 自纠 #88 教训）

体检大文件 >8KB 必跟"可拆性 vs 核心性"判定（PM 自纠 #89 教训）:
- 先 `awk` 段字节分布
- 评估每段是"案例/历史长尾"还是"必要核心"
- 只对"长尾段 ≥30% 文件大小"建议拆

---

## 五、🆕 列表类 README 一致性核查（ADR-032 v2 决定 6）

任何"索引 / 列表 / 汇总"类 README/.md **必跟实际文件数同步**:

| 列表类文件 | 一致性核对 |
|---|---|
| `Docs/3-开发文档/adr/README.md` 表格 | vs `ls Docs/3-开发文档/adr/ADR-*.md \| wc -l` |
| `操作系统/04_台账/议题全景.md` ADR 永久现行表 | vs ADR 文件中议题永久化类数 |
| `操作系统/01_架构/元规则池.md` "v3.X / N 永久" 字段 | vs 二表行数 |

历史快照只作追溯抽检，不作为当前计数单一信息源；需要当前数字时回到活入口与自动守卫。

**操作系统 PM 起 ADR 时必须同步索引；只有“元规则类 ADR”才改元规则池**：
1. ADR-XXX 文件新建
2. ADR README 表格 +1 行
3. 议题全景 ADR 表 +1 行
4. 若 ADR 永久化协作铁律：元规则池 v3.X→v3.(X+1) + 二表 +1 行；普通 ADR 不强行写入元规则池

→ PM 自纠 #91 教训:软规则失守 = 列表类 README 长期过时 / 必双复核 + 终极自动化（PROP-038 Hooks）

## 六、议题 BE 起手必查防御

README 是 always-loaded 高频入口。**过时 README = 议题 BE 起手必查崩塌**。

必查清单（每月一次 / 沉淀 PM 主导）:
- [ ] 项目根 README 版本号对齐 {{APP_REPO_DIR}}/package.json
- [ ] 操作系统/02_智能体/README 9 PM 清单对齐 [`角色边界.md`](角色边界.md)
- [ ] PM工作区/README 9 PM 清单对齐
- [ ] README frontmatter 覆盖与 P4g 输出一致（当前以 `check-operating-system.ps1` 为准）

---

## 七、关联

- PM 自纠 #88+#89 批次：[`../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-88+89-体检盲区-批次.md`](../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-88+89-体检盲区-批次.md)
- PROP-042 大文件治理：[`../../确认改动/已审批/已完成/PROP-042-2026-05-28-大文件红区拆分清单.md`](../../确认改动/已审批/已完成/PROP-042-2026-05-28-大文件红区拆分清单.md)
- 议题 CW scope schema：[`../05_记忆/scope-schema.md`](../05_记忆/scope-schema.md)
- 议题 BE 起手必查：ADR-029
- 沉淀 PM 速查表 D 类规则 9：[`../../PM工作区/沉淀PM-沉淀者/速查表/INDEX.md`](../../PM工作区/沉淀PM-沉淀者/速查表/INDEX.md)

---

⭐ **本规范已由 ADR-032 / ADR-032 v2 永久化；后续只维护当前口径，不再按候选状态处理。**
