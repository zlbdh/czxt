---
name: dev-role-legacy
scope: project
type: semantic
loaded: on-demand
description: 历史档案：Claude Code 写代码帽子（文件清单/9KB mount 限制/写入策略/QA 前自检），已吸收到新 9 PM playbook（开发PM-实施者）
---

# Dev Playbook · 开发角色

> 历史档案：当前开发 PM 真入口是 [`开发PM-实施者.md`](开发PM-实施者.md)。本文保留旧 Dev 帽子样本，不作为现行执行规则；文内命令和写入流程不可直接复制执行。

咪咪写代码时戴这顶帽子。目的：稳定、可验证地落地 PRD。

## 触发条件

PRD 条目状态从「设计中」→「实施中」时。

## 输入

- 一个 PRD 条目（带 AC 清单和受影响文件列表）
- 设计文档段落

## 输出

- 修改后的源文件
- 新增/更新的测试
- 历史样例：旧流程曾更新 CHANGELOG；当前开发 PM 不写 framework

## 标准步骤

### 步骤 1：历史样例 — 列文件清单（不可复制执行）

按受影响文件列表，逐个确认大小（避开 mount 写入坑）：
```bash
wc -lc src/features/xxx/Xxx.jsx src/shared/yyy.jsx
```

### 步骤 2：历史样例 — 旧写入策略（不可复制执行）

```
< 6 KB:    Write 直接到目标
6-8 KB:    Write 到 outputs/X.jsx, bash cp -f
> 8 KB:    Write 拆 part1+part2 到 outputs, cat 拼接到目标
小改动:    Python re.sub in-place（最稳）
```

### 步骤 3：写代码

- 先改数据层（database.js / defaults.js / 共享 helpers）
- 再改组件层（components.jsx）
- 最后改 feature（features/*.jsx）
- **每改一个文件立刻 `tail -3` + `wc -lc` 验证完整**

### 步骤 4：写测试

每个新增的纯函数都要有 vitest 测试。位置：与源同目录的 `*.test.js`。

模板：
```js
import { describe, expect, it } from 'vitest';
import { newFn } from './newFile.js';

describe('newFn', () => {
  it('handles happy path', () => {
    expect(newFn(input)).toEqual(expected);
  });
  it('handles edge: null/empty', () => {
    expect(newFn(null)).toBe(null);
  });
});
```

### 步骤 5：历史样例 — 旧 docs 同步（不可复制执行）

- CHANGELOG.md：旧流程会写；当前开发 PM 不写 framework CHANGELOG
- 受影响 README.md / docs 段落更新

## 反模式（不要这样）

- ❌ 一次改 5 个文件 不验证就跑测试
- ❌ 文件超 9KB 不察觉，直接 Write 截断
- ❌ 改逻辑不写测试
- ❌ 忽略 vite build warning

## 历史样例：旧 9KB 写入限制铁则（不可复制执行）

```
现象：Write/Edit 工具对 mount 路径有 ~9105 字节硬限制
报告"成功"但实际只写了一半，文件被截断在 UTF-8 边界
表现：tail 看末尾不完整 / 文件大小停在 9105

解决方案（按可靠性排序）：
1. Python re.sub in-place — 最稳，对小改动
2. Write 到 outputs/ + bash cp -f — outputs 也有限制但偶尔能过
3. Write 拆 part1+part2 + bash cat 拼接 — 大文件唯一可靠路
4. 直接 Write — 仅 < 6KB 文件
```

## 验证清单（步骤 5 之前）

- [ ] 所有改动文件 `tail -3` 显示合法 JS 结尾
- [ ] 无 8KB+ 文件被截断
- [ ] Python 脚本 in-place 修改后 grep 关键 marker 都在
- [ ] AC 中每条都有对应代码 / 测试
