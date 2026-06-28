---
name: pm-specialized-mode-capability-layer
scope: project
type: semantic
loaded: on-demand
description: 9 PM 不扩编时承载需求/设计/前端/后端/硬件等专业方向的 mode、plugin、worker 分层规则
---

# PM 专业 mode / 能力层

> 最优口径：**PM 管责任边界，mode 管专业视角，plugin / worker 管执行能力**。
> 只有新的责任边界才升级成 PM；只是专业技能时，先挂到现有 PM 的 mode、插件或 worker。

## 一、当前不扩编

保持 9 PM 主体，不新增“需求 PM / 设计 PM / 前端 PM / 后端 PM / 硬件 PM”。

| 专业方向 | 当前承载 | 落地口径 |
|---|---|---|
| 需求 PM | 产品 PM「需求拆解者」· 需求拆解 mode | 写 PRD、需求边界、验收口径 |
| 设计 PM | 产品 PM「需求拆解者」· 体验设计 mode | 可调用 `product-design` 插件做体验、信息架构、原型和视觉探索 |
| 前端 PM | 开发 PM「实施者」worker + 技术 PM explorer | 前端实现归开发；复杂方案先技术诊断 |
| 后端 PM | 开发 PM「实施者」worker + 技术 PM explorer | 后端实现归开发；架构/接口/数据风险先技术诊断 |
| 硬件 PM | 技术 PM sub-mode + 开发 PM worker | 仅真实进入设备/固件/BOM/量产测试链路后评估扩编 |

## 二、产品 PM 双 mode

产品 PM「需求拆解者」默认含两个 mode：

| mode | 触发 | 输出 |
|---|---|---|
| 需求拆解 mode | “我要/能不能/这里不好用/加一个功能” | PRD 条目、AC、优先级、边界情况 |
| 体验设计 mode | “界面怎么做/信息架构/原型/视觉/交互体验” | 体验方案、IA、原型说明、设计探索结论 |

调用 `product-design` 插件不改变写入白名单；插件只是产品 PM 的能力工具，不自动生成新 PM，也不自动派 agent。

## 三、扩编触发

任何专业方向想升格为独立 PM，仍必须回到 [`演化哲学.md`](演化哲学.md) 的扩编三问：

1. 同类边界冲突或错向有不少于 3 次实证。
2. 频次达到每周至少 1 次。
3. 现有 PM 的 sub-mode / plugin / worker / explorer 已经覆盖不了。

任一不满足：不加 PM，先沉淀为 mode、插件能力或 worker brief 模板。

## 四、一句话

> **9 PM 是骨架，专业 mode 是视角，plugin 是工具，worker/explorer 是一次性执行实例。**
