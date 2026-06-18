# ADR-025 · Cowork mount stale 防御机制永久化（议题 BK v3 升级）

- **状态**：现行
- **日期**：2026-05-19
- **关联**：[ADR-023 议题 AJ PM 子类化](ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md) · [ADR-024 议题 P 永久化](ADR-024-议题P用户输入三态边界永久化.md) · [PROP-024 Phase 2 防御机制实施](../../../确认改动/已审批/已完成/PROP-024-2026-05-19-架构债治理v4-4包综合治理.md) · [codex-push 后防御当前真源](../../../能力资产/rules/codex-push后防御.md)
- **议题 BK 关闭条件**：实战 ≥3 次累积 + 0 业务事故 + 多维度症状识别完整 + 防御机制稳定有效 ✅ 达成

> ⚠️ **当前安全覆盖说明（2026-06-15）**：本文保留 2026-05 mount stale 证据，但“reset 预批路径”已被当前 B/C 边界取代。现在遇到疑似 stale/dirty，只能先做只读 verify；任何会改写工作区的恢复命令都必须按 [`能力资产/rules/codex-push后防御.md`](../../../能力资产/rules/codex-push后防御.md) 获取本次明确授权，不能照抄本文历史命令。

## 背景

议题 BK 从 Sprint-5 v3.6.1 Codex push 后首次暴露，跨 3 次实战累积**多维度症状**：

| 实战 | 时间 | 维度 | 症状 |
|---|---|---|---|
| #1 | 2026-05-19 12:00（v3.6.1）| working tree 假 dirty + git index 损坏 | 5 文件 modified（含 F-DEVIATION-3 真代码删除 143 行）+ `.git/index` `bad signature 0x00000000` |
| #2 | 2026-05-19 14:45（v3.6.2）| 文件截断假象 | Profile.jsx 删 7 行 + 末尾加空格 + 无 newline |
| #3 | 2026-05-19 17:00（v3.6.3）| 多模式同时 | 18 文件假 dirty + `alarmManager.js` 物理存在但 `no read permission` + `personaPrompts/` 首次 ls 缺 2/3 文件第二次自动刷新 |

**根因确认**（PROP-024 Phase 2 调查结论）：
- Cowork mount POSIX 权限模型 + cross-tool stale cache + 不同步刷新窗口
- **不是 bug**，是 mount 设计权衡（速度 vs 实时性）
- **不阻塞业务**：Codex 端 fresh fs 看真实状态，所有 push 始终正确 + GitHub 代码完整

**防御机制实战**：3 次都用 `git reset --hard HEAD` 一键恢复（前期 #1 还含 `rm .git/index + git reset`）+ 双 verify 全过 → **0 业务事故**。

## 决定

议题 BK **正式永久关闭**，纳入 framework「跨工具基础设施限制」类元规则永久化。

### 决定 1 — Codex push 后 PM 双 verify 硬规则（永久化）

每次 Codex 报告「push 完成 / working tree clean」后，Cowork PM **必须**执行：

```bash
# 1. push 后立即 verify
cd "$PROJECT_ROOT"
git status --short    # 看是否 dirty
git log --oneline -1  # 看 HEAD 是否对应 Codex 报告的 commit hash
```

若 `git status` 不 clean → 立即跳决定 2 恢复路径。

PM 任何 Edit / Write / mv 操作前，**必须**再 verify 一次（防 mount stale 自动刷新延迟污染后续操作）。

### 决定 2 — 历史恢复路径（已被当前安全边界取代）

2026-05 当时的恢复路径如下，仅作历史证据。**当前不再预批执行**：

```bash
cd "$PROJECT_ROOT"
git status --short              # 确认 dirty
git diff <file> | head -30      # 看是真代码删除还是 mount stale 假象（一般是 stale）
git reset --hard HEAD           # 恢复 working tree
git status                      # verify clean
```

⭐ **当前执行**：只读确认后，按 `codex-push后防御.md` 要求请求本次明确授权，再决定是否恢复工作区。

### 决定 3 — index 损坏特殊路径（历史记录 / 罕见）

若当时 `git reset` 报 `bad signature 0x00000000 / fatal: index file corrupt`（仅 #1 v3.6.1 实战出现），曾采用：

```bash
rm .git/index           # 删损坏 index
git reset               # 软 reset 重建 index from HEAD
git reset --hard HEAD   # 走基础恢复
```

### 决定 4 — 防御机制写入 framework（当前真源已迁移）

当前真源为 [`能力资产/rules/codex-push后防御.md`](../../../能力资产/rules/codex-push后防御.md)；历史 `agent/rules/` 路径不再作为执行入口。

### 决定 5 — 元规则池升级 8 → 9

`议题 BK 防御`（mount stale 双 verify + reset 预批）作为第 9 元规则进入永久化池（与 G/AT/AM/AO/BC/BE/AJ/P 并列），命名「**议题 BK · Cowork mount stale 防御**」。

未来「跨工具基础设施限制」类规则统一归入此类（如未来若发现 Codex 端 fresh fs 也有类似问题）。

## 后果

### 收益

1. **跨 Sprint 长期生效** — 每次 Codex push 后 PM 自动 verify，业务零事故保障
2. **PM 切对话不影响** — 任何新 PM 起手读本 ADR + `codex-push后防御.md` 即可上手
3. **3 次累积证据完整** — 不再需要每次解释「mount stale 是什么 / 为什么 reset」
4. **元规则永久化升级 8 → 9** — framework 资产巩固

### 代价

1. **每次 Codex push 后 PM 起手 +5 秒 verify**（成本极低）
2. **mount stale 根因未根治** — 取决于 Cowork mount 底层是否未来优化（议题 BK v4 候选保留）
3. **新对话 PM 必须读 ADR-025 + codex-push后防御.md** 才能避免被 mount stale 吓到

### 议题 BK 关闭后跨 Sprint 监控

- ✅ 不再标记「议题 BK 第 N 次实战」（每次 Codex push 都默认走 verify）
- ❌ 若未来发现**新维度**（如 Codex 端也出现 stale / GitHub Actions push 后 stale）→ 议题 BK **重开** + 起新 ADR 翻案
- ✅ 累积 ≥10 次 push 后 verify 0 触发 → 评估是否 mount 底层已改进（可降级到「监控级」规则）

## 翻案规则

如未来 Cowork mount stale 出现**未识别新维度**：**不修本 ADR**，新建 ADR-N 写明原因，本 ADR 标「被 ADR-N 部分替代」（按 ADR README 翻案铁律）。

## 关联文件

- [agent/rules/codex-push后防御.md](../../../agent/rules/codex-push后防御.md) — 防御机制具体实施（6 段 / 双 verify / 3 级恢复路径）
- [PROP-024 Phase 2 实施](../../../确认改动/已审批/已完成/PROP-024-2026-05-19-架构债治理v4-4包综合治理.md) — 防御机制首次 ship
- [RETRO-009 §议题 BK v3 升级](../../7-复盘/RETRO-009-2026-05.md) — 3 次实战完整记录 + ADR 决议
- [agent/rules/]/ — framework 元规则池（议题 BK 加入第 9 元规则）

## 议题 BK 关闭后里程碑

议题 BK 永久关闭 = **framework 9 元规则永久化池**：

| # | 议题 | ADR |
|---|---|---|
| 1 | 议题 G（hook 反应式）| 隐含 PROP-021 |
| 2 | 议题 AT（web API 信源）| 隐含 PROP-022 |
| 3 | 议题 AM（CHANGELOG header）| 隐含 PROP-018 |
| 4 | 议题 AO（PROP 状态字段语义）| 隐含 PROP-020 |
| 5 | 议题 BC（Capacitor plugin 静态 import）| 隐含 PROP-024 Phase 1 |
| 6 | 议题 BE（PM 起手必查速查表）| 隐含 PROP-023 |
| 7 | 议题 AJ（PM 子类化 + decision-checkpoint）| **ADR-023** |
| 8 | 议题 P（用户输入三态边界）| **ADR-024** |
| **9** | **议题 BK（Cowork mount stale 防御）** | **ADR-025（本）** |

---

## 2026-06-09 补录（PROP-043 / RETRO-016 教训3）— mount 防御打法 4 条

实战提炼的 Cowork mount stale/截断防御 4 条（与 ADR-033 大文件 mount 不可信同族，本条专注协作 git + 状态.md append 场景）：
1. **git show HEAD:<path>** 绕 mount 缓存读 committed 真值（diff/status 元数据可信，wc/Read 内容可能 stale）。
2. **wc/grep 大文件不可信**（stale chimera：读旧字节/函数体读不全）→ Read 工具直读 + 正向命中（grep 命中=新内容真在；stale 造不出新串）才可信。
3. **状态.md 等 append-only 文件用 `cat >> ` O_APPEND**，绝不 read-modify-write（会覆盖其他 PM 同期 append 的行）。
4. **build/vitest 真 shell 全绿 = 代码完整性 ground truth**（实施者真 shell 是基准；Cowork 侧 mount 读不全不代表代码缺失；Codex 真 shell 门禁兜底）。
