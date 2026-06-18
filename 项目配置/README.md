---
name: project-config-index
scope: template
type: semantic
loaded: on-demand
description: 项目配置入口 — 项目卡模板；具体项目卡默认留在本机实例
---

# 项目配置

这里保留项目卡模板，服务于“一个操作系统模板，多项目实例”的长期产品化形态。具体项目卡默认留在本机项目目录或 `项目区/本地实例/<项目>/`，不随模板仓库提交。

## 文件约定

```json
{
  "projectName": "项目名",
  "projectRoot": "D:\\WGKJ\\项目名",
  "appRepoDir": "app",
  "currentVersion": "v0.1.0",
  "currentSprint": "Sprint-1",
  "notes": []
}
```

## 使用方式

- `项目配置/_模板.project.json` 是新项目样例。
- 真实项目卡默认不进入模板仓库；复制 `_模板.project.json` 后，放在本机项目目录或 `项目区/本地实例/<项目>/` 内维护。
- 若确实需要把某个项目卡作为公开样例，必须先完成审批并脱敏，避免模板仓库带入具体项目残留。

当前 `实例化项目.ps1` 仍接收显式参数；后续若进入安装器/CLI 阶段，再把项目卡片读取逻辑产品化。
