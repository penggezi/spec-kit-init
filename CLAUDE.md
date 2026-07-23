# CLAUDE.md

本文件为 Claude Code 在本仓库中工作时提供指引。

## 经验库优先（每次会话必读）

在开始任何实质工作之前，**MUST** 先读一遍：

- `SKILL.md` — Skill 定义，了解本项目的全部逻辑和执行流程

---

## 项目概述

`spec-kit-init` 是 Claude Code 的 Skill，用于替代内置 `/init` 命令。它一次完成四件事：

1. **代码库分析** → 生成项目指令文件（CLAUDE.md / AGENTS.md 等）
2. **SDD 工作流搭建** → 通过 `specify init` 安装 Spec-Kit 框架
3. **经验沉淀机制初始化** → `/retro` skill + `lessons.md` + 经验自动参考链路
4. **代码质量门禁初始化** → `/speckit-quality` skill + implement 质量检查注入

## 架构要点

本项目**不是传统代码项目**，而是一个 Markdown 驱动的 Skill 定义。核心逻辑全部在 `SKILL.md` 中以分阶段流程描述，没有可执行的代码文件（除了一个 bash 辅助脚本）。

### 关键文件及职责

| 文件 | 用途 |
|------|------|
| `SKILL.md` | **主入口**。定义 6 个初始化阶段（环境检测 → SDD 安装 → 经验沉淀 → **质量门禁** → **Bug 修复工作流** → 汇报），是全部逻辑的载体 |
| `scripts/ensure-specify.sh` | bash 脚本，检测并安装 `specify-cli`（带网络重试和超时保护） |
| `references/agent-instructions-template.md` | SDD 段落模板 + 经验库优先段模板，注入到目标项目的 AI 指令文件中 |
| `templates/retro-skill.md` | `/retro` 复盘 Skill 的完整定义模板，含 3 种模式 + 5 层经验质量筛选 + 双角色对抗审查 + 去重机制 |
| `templates/retro-references/mechanism-auditor.md` | 机制审计员审查 prompt 模板（判断经验是否揭示根因机制） |
| `templates/retro-references/routing-auditor.md` | 路由审核员审查 prompt 模板（判断经验归入 constitution.md 还是 lessons.md） |
| `templates/quality-gate-skill.md` | `/speckit-quality` 质量门禁命令的完整定义模板，含技术栈自动检测和工具映射 |

### SKILL.md 的 6 个阶段

```
阶段 1：分析 + 初始化
  ├── 1.1 环境检测（Python 3.11+、uv、Git）
  ├── 1.2 选择 AI 编码工具（Claude Code / Codex / Copilot / Cursor / 自定义）
  ├── 1.3 代码库分析（已有项目时）
  ├── 1.4 执行 specify init（安装 SDD 工作流）
  └── 1.5 可选：初始化 Constitution

阶段 2：合并产出指令文件 → 将 SDD 段注入目标项目指令文件

阶段 3：经验沉淀机制初始化
  ├── 3.1 创建 lessons.md + lessons.idx 骨架（物理隔离的轻量去重索引）
  ├── 3.2 安装 /retro skill
  ├── 3.2.1 安装 /retro 子代理审查模板（mechanism-auditor + routing-auditor）
  ├── 3.3 改造 /speckit-plan（注入 lessons.md 必读）
  ├── 3.4 改造 /speckit-implement（注入 lessons.md + 复盘询问）
  └── 3.5 验证闭环完整性（逐项确认所有文件存在、注入到位）

阶段 4：代码质量门禁初始化
  ├── 4.1 安装 /speckit-quality skill
  ├── 4.2 改造 /speckit-implement（注入代码质量门禁步骤）
  └── 4.3 验证质量门禁完整性

阶段 5：Bug 修复工作流初始化
  ├── 5.1 安装官方 Bug Extension（specify extension add bug）
  ├── 5.2 验证安装完整性
  ├── 5.3 注入增强（连接 lessons.md + 质量门禁 + 复盘）
  ├── 5.4 复杂度升级规则（何时升级到完整 SDD 链路）
  └── 5.5 记录安装状态

阶段 6：汇报（原阶段 5）
  └── 展示初始化结果和可用命令（含 /speckit-quality 和 /speckit.bug.*）
```

### 关键设计决策

- **非交互式终端兼容**：`specify init` 在 CI/agent 环境中会永久阻塞，需通过 `echo "" |` 管道发送空行让交互步骤使用默认选项
- **渐进式加载**：SKILL.md 本身包含全部流程描述，`references/` 和 `templates/` 下的文件按需读取，避免提前占用上下文
- **回滚与恢复**：每个阶段都明确了失败时的清理方式（见 SKILL.md 末尾"约束"章节）
- **物理隔离的轻量去重索引**：`lessons.idx` 与 `lessons.md` 分离，去重时先读索引（O(n) 恒定成本），命中后才读正文精确比对，避免扫描成本随经验积累膨胀
- **双角色对抗审查**：每条经验经 mechanism-auditor（审查是否揭示根因机制）和 routing-auditor（审查归入 constitution 还是 lessons）独立审查，两个角色都通过才放行
- **参考源勘误驱动**：经验挖掘不再依赖"回顾会话记录"，而是以"本次工作参考了什么"为线索，逐参考源回答"准确吗/完整吗/适用吗/费解吗"四个问题
- **支持多平台**：Claude Code、Codex、GitHub Copilot、Cursor 各有不同的指令文件路径和配置参数

## Git 推送规范

### 版本号管理（强制）

每次推送到 GitHub **之前**，必须按以下流程更新版本号：

1. **判断变更级别**（参考 [Semantic Versioning](https://semver.org/lang/zh-CN/)）：
   - **major**：重大架构变更、不向后兼容的 Skill 行为变更
   - **minor**：新增功能（如新增初始化阶段、新增支持的平台）
   - **patch**：Bug 修复、文档修正、脚本调整等不改变外部行为的改动

2. **更新版本号**：
   - 更新 `VERSION.md`：写入 `v<major>.<minor>.<patch>`
   - 创建新的 git tag：`git tag v<major>.<minor>.<patch>`

3. **在提交信息中标注版本号**：合并到上一次提交或单独做版本提交

### 文档同步检查（每次推送前必做）

推送前检查以下文档是否与当前代码一致：

| 文档 | 触发更新的条件 |
|------|---------------|
| `VERSION.md` | **每次推送必更新**（版本号同步） |
| `README.md` | Skill 描述变更、新增/移除支持的平台、流程步骤变更、前置依赖变更 |
| `SKILL.md` 的阶段数量 | CLAUDE.md 中「SKILL.md 的 N 个阶段」描述需同步 |
| `LICENSE` | 作者/年份变更 |

**检查流程**：
1. 回顾本次变更涉及的改动
2. 逐项对照上表判断是否需要更新
3. 如发现文档滞后，先更新文档再推送
4. 更新文档的改动合并到版本号提交中一起推送
