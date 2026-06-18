---
name: verify-checklist-handoff
description: PM 起 handoff/ship 卡 7 项 verify（议题 CD 候选元规则 / 4 次 PM 自纠 #51-54 累积）
trigger: 写 handoff/ship 卡前 / 起 PROP 前
loaded: 条件加载
---

# PM 起卡 verify checklist（议题 CD 候选元规则）

## 触发历史

4 次 PM 自纠累积：
- #51 AC2 字数 50→100（主观拍数值 → AC 实证修订）
- #52 AC7 用户控制权（v3.0 哲学 §22）
- #53 MiMo thinking max_tokens 空回复（运行时后处理）
- #54 handoff Step 8 + AC2 内部矛盾（未 verify caller import 风格）

## 7 项 verify checklist

写 handoff/ship/PROP 前 1 分钟必跑：

- [ ] **真实代码 grep verify**（caller import 风格 / 模块入口 / Tab 配置 / 路径风格）
- [ ] **AC 数值有实证基础**（避免主观拍 < N 字 / < N 分钟 / 议题 CC AC 实证驱动）
- [ ] **内部一致性 cross-validate**（Step 流程 + AC 硬约束 + 警戒事项三者不矛盾）
- [ ] **分支名 main 不写 master**（GitHub 2020 后默认）
- [ ] **APK 历史大小有参考值**（不靠估）
- [ ] **提示词 ≤ 10 行**（反思 3 极简模板）
- [ ] **v3.0 哲学新功能必加 settings 开关**（用户控制权 / 铁律 25）

## 升级状态

议题 CD 仍在元规则候选池，RETRO-013 后继续保留；当前真源见 [`元规则池-候选.md`](../../01_架构/元规则池-候选.md)。

## 真知识源

- `操作系统/05_记忆/INDEX.md` §二反思 4
- RETRO-011 §PM 自纠 #54 案例研究
- `PM工作区/项目PM-咪咪/PM自纠/INDEX.md` + `PM自纠-54.md` / `PM自纠-58.md` / `PM自纠-59.md` / `PM自纠-60.md` / `PM自纠-61.md`
