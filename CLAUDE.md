# CLAUDE.md

本文件为 Claude Code 在本仓库中工作时提供指引。

## 经验库优先（每次会话必读）

在开始任何实质工作之前，**MUST** 先读一遍：

- `SKILL.md` — Skill 定义，了解本项目的全部逻辑和执行流程

---

## 项目概述

`spec-kit-init` 是 Claude Code 的 Skill，用于替代内置 `/init` 命令。它一次完成三件事：

1. **代码库分析** → 生成项目指令文件（CLAUDE.md / AGENTS.md 等）
2. **SDD 工作流搭建** → 通过 `specify init` 安装 Spec-Kit 框架
3. **经验沉淀机制初始化** → `/retro` skill + `lessons.md` + 经验自动参考链路

## 架构要点

本项目**不是传统代码项目**，而是一个 Markdown 驱动的 Skill 定义。核心逻辑全部在 `SKILL.md` 中以分阶段流程描述，没有可执行的代码文件（除了一个 bash 辅助脚本）。

### 关键文件及职责

| 文件 | 用途 |
|------|------|
| `SKILL.md` | **主入口**。定义 4 个初始化阶段（环境检测 → SDD 安装 → 经验沉淀 → 汇报），是全部逻辑的载体 |
| `scripts/ensure-specify.sh` | bash 脚本，检测并安装 `specify-cli`（带网络重试和超时保护） |
| `references/agent-instructions-template.md` | SDD 段落模板 + 经验库优先段模板，注入到目标项目的 AI 指令文件中 |
| `templates/retro-skill.md` | `/retro` 复盘 Skill 的完整定义模板，含 5 层质量门禁 + 对抗审查 + 去重机制 |

### SKILL.md 的 4 个阶段

```
阶段 1：分析 + 初始化
  ├── 1.1 环境检测（Python 3.11+、uv、Git）
  ├── 1.2 选择 AI 编码工具（Claude Code / Codex / Copilot / Cursor / 自定义）
  ├── 1.3 代码库分析（已有项目时）
  ├── 1.4 执行 specify init（安装 SDD 工作流）
  └── 1.5 可选：初始化 Constitution

阶段 2：合并产出指令文件 → 将 SDD 段注入目标项目指令文件

阶段 3：经验沉淀机制初始化
  ├── 3.1 创建 lessons.md 骨架
  ├── 3.2 安装 /retro skill
  ├── 3.3 改造 /speckit-plan（注入 lessons.md 必读）
  └── 3.4 改造 /speckit-implement（注入 lessons.md + 复盘询问）

阶段 4：汇报 → 展示初始化结果和可用命令
```

### 关键设计决策

- **非交互式终端兼容**：`specify init` 在 CI/agent 环境中会永久阻塞，需通过 `echo "" |` 管道发送空行让交互步骤使用默认选项
- **渐进式加载**：SKILL.md 本身包含全部流程描述，`references/` 和 `templates/` 下的文件按需读取，避免提前占用上下文
- **回滚与恢复**：每个阶段都明确了失败时的清理方式（见 SKILL.md 末尾"约束"章节）
- **支持多平台**：Claude Code、Codex、GitHub Copilot、Cursor 各有不同的指令文件路径和配置参数
