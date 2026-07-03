---
name: spec-kit-init
description: |
  项目初始化与 SDD 规范一体化工具。替代默认的 /init，在一次初始化中同时完成：
  代码库分析生成项目指令文件（CLAUDE.md / AGENTS.md 等）+ Spec-Kit SDD 工作流搭建 + 经验沉淀机制初始化。

  触发场景（高优先级）：
  - 用户提到：初始化项目、init、initialize、项目初始化、新建项目
  - 用户提到：spec-kit、specify、SDD、规格驱动开发、spec-driven
  - 用户提到：初始化 SDD 规范、项目规范化、specify init
  - 用户提到："用 spec-kit 初始化"、"搭建 SDD 工作流"、"项目初始化规范文件"
  - 用户在一个新项目或已有项目中想要建立结构化的开发规范和工作流
  - 用户在空目录中开始新工作时

  当此 skill 触发时，不要调用内置的 /init 命令，因为本 skill 已包含其全部功能并在此基础上叠加 SDD 工作流。
---

# Spec-Kit 项目初始化（含代码库分析 + 经验沉淀机制）

## 核心职责

本 skill 是内置 `/init` 的增强替代版，一次完成三件事：

1. **代码库分析**（等同于 `/init`）→ 项目指令文件上半部分
2. **SDD 工作流搭建** → 项目指令文件下半部分（`<!-- SDD:START/END -->` 标记包裹）
3. **经验沉淀机制初始化** → `/retro` skill + `lessons.md` + 经验自动参考链路

**重要**：当本 skill 触发时，不要再调用内置 `/init`，本 skill 已包含其全部功能。

## 渐进式加载

先只阅读本文件。需要时再读取：

| 场景 | 文件 |
|------|------|
| 获取指令文件注入模板 | `references/agent-instructions-template.md` |
| 获取 /retro skill 模板 | `templates/retro-skill.md` |

按需读取，仅在执行对应阶段时才加载参考文件，避免提前占用上下文。

## SDD 核心理念

SDD（规格驱动开发）翻转传统开发流程：**规格是核心产出物，代码是规格的表达**。每个阶段都有对应的 `/speckit-*` 命令，命令内部已有完整指令，无需记忆细节。

关键原则：
- **先规格后代码**：新功能必须先写 spec.md，再写代码
- **只说做什么**：spec.md 只描述 WHAT 和 WHY，不涉及 HOW
- **规格驱动实现**：plan → tasks → implement 都从 spec 推导，不能跳步
- **宪章最高**：constitution.md 中的原则不可违反

## 使用前提

- Python 3.11+、[uv](https://docs.astral.sh/uv/)、Git

## 执行流程

### 阶段 1：分析 + 初始化

#### 1.1 环境检测

确认核心依赖就绪：

- Python 3.11+（`python3 --version`）
- Git（`git --version`）
- [uv](https://docs.astral.sh/uv/)（`uv --version`，如未安装引导用户安装）

> `specify-cli` 的检测和安装推迟到 1.4 步，仅在选择了 Claude Code 或 Codex 时执行。

#### 1.2 选择 AI 编码工具

询问用户当前使用哪个 AI 编码工具，后续所有路径和参数都根据选择确定：

```
当前项目使用哪个 AI 编码工具？
  1. Claude Code
  2. Codex
  3. GitHub Copilot
  4. Cursor
  5. 其他（自定义）→ 逐一配置 AGENT_FILE / AGENT_TITLE / AGENT_NAME / AGENT_SKILL_DIR / AGENT_SPECIFY
```

根据选择记录以下变量：

| 变量 | 用途 | Claude Code | Codex | Copilot | Cursor |
|------|------|------------|-------|---------|--------|
| `AGENT_FILE` | 指令文件路径 | `CLAUDE.md` | `AGENTS.md` | `.github/copilot-instructions.md` | `.cursor/rules/` |
| `AGENT_TITLE` | 文件 `#` 标题 | `# CLAUDE.md` | `# AGENTS.md` | `# Tips` | `# Rules` |
| `AGENT_NAME` | 展示名称 | `Claude Code` | `Codex` | `GitHub Copilot` | `Cursor` |
| `AGENT_SKILL_DIR` | skill 安装目录 | `.claude/skills` | `.agents/skills` | `.claude/skills`¹ | `.claude/skills`¹ |
| `AGENT_SPECIFY` | specify --integration 参数 | `claude` | `codex` | — | — |

如检测到项目中已有指令文件（如 CLAUDE.md、AGENTS.md），可跳过询问直接使用对应平台的变量。

> ¹ Copilot/Cursor 自身无标准 skill 系统，此处仅用于统一安装 retro skill（经验沉淀），speckit-* 系列命令将在后续步骤中自动跳过。

> **注意**：Copilot 和 Cursor 的 `specify` 支持有限，speckit-* 系列命令不可用，但 retro skill 和 lessons.md 经验沉淀机制不受影响，因为 `lessons.md` 是纯 Markdown 文件，与平台无关。

#### 1.2.1 配置确认

选择完成后，确认以下配置变量。后续所有阶段引用此配置，不再回溯：

```
AGENT_FILE      = 指令文件路径
AGENT_TITLE     = 文件标题
AGENT_NAME      = 展示名称
AGENT_SKILL_DIR = skill 安装目录
AGENT_SPECIFY   = specify --integration 参数（claude/codex/留空）
```

> 选择「其他」时，需逐一确认以上五项配置的取值。

#### 1.3 代码库分析（空目录跳过）

对已有项目，收集：
- 构建/开发命令（build、lint、test、单测运行）
- 高层架构（需要跨文件理解的核心设计）
- 现有配置（README.md、.cursor/rules/、.cursorrules、.github/copilot-instructions.md 等）
- 技术栈

分析结果用于生成 `{AGENT_FILE}` 的代码库文档部分，要求：
- 中文撰写
- 以 `{AGENT_TITLE}\n\n本文件为 {AGENT_NAME} 在本仓库中工作时提供指引。` 开头
- 聚焦"大图"，不列每个文件、不写通用实践、不编造内容

#### 1.4 执行 specify init

> 此步仅在选择了 Claude Code 或 Codex 时执行（`{AGENT_SPECIFY}` 有值）。Copilot/Cursor 跳过。

**开始前告知用户**：正在安装 specify-cli 并初始化 SDD 工作流，约需 1-2 分钟，请稍候。

检测并安装 `specify-cli`：

```bash
bash scripts/ensure-specify.sh
```

`ensure-specify.sh` 会自动检测 `uv` 和 `specify`，未安装时自动安装。失败时根据提示处理。

安装成功后执行 `specify init`。**注意事项**：

- `--force` 只跳过了文件覆盖确认，但未跳过内部的交互式选择步骤（选择 agent 集成、脚本类型）
- 在 agent/CI 等非交互式终端中，这些步骤会永久阻塞
- 必须通过管道发送空行，让交互式步骤使用默认选择

```bash
echo "" | PYTHONIOENCODING=utf-8 specify init --here --integration {AGENT_SPECIFY} --force --ignore-agent-tools
```

> 为什么不用 `yes "" |`？`echo "" |` 发送一个空行即可，因为交互式选择的默认选项无需修改。`yes "" |` 虽然更可靠（持续发送空行覆盖所有交互步骤），但 Git Bash 可能不支持 `yes` 命令。
>
> Windows 上保留 `PYTHONIOENCODING=utf-8` 以防 unicode 编码问题。
> `--no-git` 参数已在 v0.9.x 弃用，v0.10.0 后默认不再启用 git 扩展，故不再传入。

如 `--ignore-agent-tools` 不被当前版本识别，去掉该参数再试：

```bash
echo "" | PYTHONIOENCODING=utf-8 specify init --here --integration {AGENT_SPECIFY} --force
```

如已有 `.specify/` 目录，先询问用户是否覆盖。如果用户拒绝覆盖，跳过本步并告知用户 SDD 工作流结构已存在，后续注入将继续。
如所有尝试均失败，输出完整错误信息并终止，提示用户检查网络和 GitHub 访问。

这会创建完整的 SDD 工作流结构：
- `.specify/` — 配置和模板
- `{AGENT_SKILL_DIR}/speckit-*/` — 所有 `/speckit-*` 斜杠命令

#### 1.5 可选：初始化 Constitution

Constitution 是 SDD 的最高准则，不应由模型猜测是否需要。

**判断流程**：
- 用户明确说了"建立项目原则"/"写宪章"/"初始化 constitution"等 → 直接执行 `/speckit-constitution <项目描述>`
- 其他情况 → **主动询问用户**：

```
是否需要建立项目 Constitution（宪章）？
Constitution 定义项目的技术栈约束、架构边界、不可违反的规则，是后续所有 SDD 阶段的最高准则。
- 是 → 请描述项目的核心原则（如技术栈、架构约束、依赖限制等）
- 暂不需要 → 跳过，后续可随时通过 /speckit-constitution 建立
```

### 阶段 2：合并产出指令文件

读取 `references/agent-instructions-template.md` 获取注入模板。目标文件为阶段 1.2 选定的 `{AGENT_FILE}`。

合并规则：
- 有 `<!-- SDD:START -->` 标记 → 只替换标记间内容，保留其余
- 无标记，有文件 → 末尾追加标记包裹的 SDD 段落
- 无文件 → 新建（代码库文档 + 经验库优先段 + SDD 段）

关键点：
- **必须在 `{AGENT_FILE}` 顶部注入「经验库优先」段**：在 `{AGENT_TITLE}` 标题行之后、第一个 `##` 节之前，插入模板第 2 节内容
- SDD 段落使用模板第 1 节内容
- 确保 SDD 段中包含 `/retro` 行和「经验沉淀（Retro）」章节

### 阶段 3：经验沉淀机制初始化

这是本 skill 相比标准 `specify init` 的增强部分——在 SDD 工作流的基础上，建立从"写完代码"到"经验被复用"的完整闭环。

#### 3.1 创建经验文件骨架

> **设计意图**：放在 `.specify/memory/` 下，与 `constitution.md` 同目录，确保 speckit 生态内所有经验资产集中管理，便于 `/speckit-plan` 和 `/speckit-implement` 统一读取。

创建 `.specify/memory/lessons.md`（模板）：

```markdown
# 项目经验教训库（lessons.md）

> 由 `/retro` skill 维护。新条目追加到本文件顶部（最新在上）。
>
> **本文件存储仅对本仓库有效的实战经验**：踩过的坑、平台/版本兼容陷阱、有效的调试套路、性能写法、特殊接口的正确用法等。
>
> - 跨项目通用偏好 → 走 Claude Memory，不写这里
> - 高门槛的长期规则 → 在发布阶段注入对应 agent 的指令文件

## 条目格式

详见 `templates/retro-skill.md` 中「文件格式约定」章节，以 retro-skill 中的定义为准。

### Watch-List（去重索引 — 由 /retro 自动维护）

- YYYY-MM-DD · 根因关键词 · 简述

---

<!-- 新条目从这里向上追加 -->
```

#### 3.2 安装 /retro skill

> 如果 `{AGENT_SKILL_DIR}` 不可用或为 undefined（如自定义模式未指定），默认使用 `.claude/skills` 作为回退目录。

读取 `templates/retro-skill.md`，将其内容写入 `{AGENT_SKILL_DIR}/retro/SKILL.md`。

如已有此文件，跳过创建。

#### 3.3 改造 /speckit-plan（注入 lessons.md 必读）

> **设计意图**：经验按"稳定性"分层——constitution 管最高原则（不可违反）、lessons 管实战经验（灵活积累），避免同级混放导致后续查找困难。

> 仅在 `{AGENT_SKILL_DIR}/speckit-plan/SKILL.md` 存在时执行（Copilot/Cursor 无 speckit 命令，自动跳过）。

读取 `{AGENT_SKILL_DIR}/speckit-plan/SKILL.md`。

用语义正则定位到 "Load context" 相关步骤（匹配 `Load context`、`加载上下文` 或类似小节标题），在该步骤的读取列表中 `constitution.md` 之后追加一行：

```
   - **MUST** also read `.specify/memory/lessons.md`（项目级实战经验，如有相关条目须在方案中显式引用）
```

**正则匹配失败时的兜底**：在 `{AGENT_SKILL_DIR}/speckit-plan/SKILL.md` 文件末尾追加以下内容，并告知用户：

```
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 经验库注入（由 spec-kit-init 追加）

在执行 plan 前，**MUST** 读取 `.specify/memory/lessons.md`，如有与当前功能相关的经验条目须在技术方案中显式引用。
```

追加后明确告知用户："/speckit-plan 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

#### 3.4 改造 /speckit-implement（注入 lessons.md 必读 + 复盘询问）

> **设计意图**：在记忆最新鲜时捕捉经验——完成瞬间是复盘的最佳时机，而非事后再回忆。自动提示确保"做完一件事"和"留下经验"不会脱钩。

> 仅在 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md` 存在时执行（Copilot/Cursor 无 speckit 命令，自动跳过）。

读取 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md`。

**改动 A**：用语义正则定位到实现上下文读取步骤（匹配如 `Load and analyze`、`implementation context`、`加载实现上下文` 等模式），在 `constitution.md` 相关的读取行之前插入：

```
   - **REQUIRED**: Read `.specify/memory/lessons.md` for project-level lessons learned (skip if file doesn't exist)
```

**改动 B**：用语义正则定位到 "Completion validation" 或最后验证步骤之后、Extension hooks 之前的区域，插入复盘提示步骤：

```
10. **经验沉淀提示（Retrospective Prompt）**：

    实施全部完成、状态汇报输出之后，**主动询问用户是否进行复盘**，让本次实现中的踩坑、决策、验证结果有机会沉淀为长期资产。

    询问格式（中文，简洁）：
    ```
    本次实现已完成，是否现在做一次经验复盘？(/retro)
    - 是 → 调用 /retro 进入复盘流程（按 constitution.md / lessons.md 二路分流）
    - 稍后 → 跳过，你可以随时手动输 /retro
    - 否 → 跳过本次复盘
    ```

    判断准则：
    - **建议复盘**：本次实现踩过坑、做过非显然的决策、推翻了规格中的预设、发现宪章不够用
    - **可以跳过**：纯模板化代码、无新认知、用户已表达"不想复盘"

    用户回应"是"/"复盘"/"yes" → 调用 `/retro` skill 继续；用户选择跳过则正常结束。
```

并将原后续步骤重新编号。

**正则匹配失败时的兜底**：任一改动无法匹配时，在 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md` 文件末尾追加：

```
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 经验库注入（由 spec-kit-init 追加）

1. 实现开始前，**REQUIRED** 读取 `.specify/memory/lessons.md`（如存在）。
2. 实现完成后，**主动询问用户**是否执行 `/retro` 复盘。
```

追加后明确告知用户："/speckit-implement 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

#### 3.5 验证闭环完整性

确认以下链路连通：
- [ ] `{AGENT_SKILL_DIR}/retro/SKILL.md` 存在
- [ ] `.specify/memory/lessons.md` 存在
- [ ] `{AGENT_FILE}` 顶部有「经验库优先」段
- [ ] `/speckit-plan` 读到 lessons.md
- [ ] `/speckit-implement` 读到 lessons.md + 完成后询问复盘
- [ ] 复盘写入后，下次会话 `{AGENT_FILE}` 强制读 lessons.md → 经验被复用

### 阶段 4：汇报

按初始化操作顺序，逐一解释每个操作的作用和可选性，让用户理解 SDD 工作流的全貌：

```
本次初始化完成，以下按操作顺序说明每个环节的用途：

━━━━━━━━━━━━━━━━━━━━━━━━ 核心操作（不可跳过） ━━━━━━━━━━━━━━━━━━━━━━━━━

① 环境检测 ── 检查 Python 3.11+、uv、Git 是否就绪
   → 这些是后续所有 SDD 命令的运行基础

② 选择 AI 编码工具 ── 根据你使用的工具确定指令文件路径和命令格式
   → 决定了后续写入哪个文件（CLAUDE.md / AGENTS.md 等）

③ 执行 specify init ── 安装 SDD 工作流框架
   → 创建 .specify/ 配置目录和所有 /speckit-* 斜杠命令
   → 这些命令是 SDD 流程的操作入口

④ 合并产出指令文件 ── 将 SDD 工作流说明写入 AI 指令文件
   → 以后每次会话 AI 都会自动加载 SDD 上下文，知道该按什么流程走

⑤ 经验沉淀机制初始化 ── 建立复盘闭环
   → 安装 /retro 命令 + 创建 lessons.md 经验库
   → 改造 /speckit-plan 和 /speckit-implement → 每次写代码前自动参考经验，写完后自动询问复盘

━━━━━━━━━━━━━━━━━━━━━━━━ 可选操作 ━━━━━━━━━━━━━━━━━━━━━━━━━

⑥ 代码库分析（可选）── 分析已有项目结构，写入指令文件
   → 空目录或新项目跳过此步
   → 已有项目执行后可让 AI 在后续会话中了解项目架构

⑦ 初始化 Constitution（可选）── 定义项目的技术栈约束、架构边界、不可违反的规则
   → 通过 /speckit-constitution 随时建立或修改

━━━━━━━━━━━━━━━━━━━━━━━━ 可用的命令 ━━━━━━━━━━━━━━━━━━━━━━━━━

核心流程（按使用顺序）：
  /speckit-specify     → 编写功能规格（WHAT）
  /speckit-plan        → 制定技术方案（HOW）
  /speckit-tasks       → 拆解执行任务
  /speckit-implement   → 按任务实现编码（完成后自动提示复盘）
  /retro               → 经验复盘沉淀

增强命令（按需使用）：
  /speckit-constitution   → 建立/修订项目原则
  /speckit-clarify        → 结构化提问消除需求歧义
  /speckit-analyze        → 跨产物一致性检查
  /speckit-checklist      → 需求完备性检查
  /speckit-taskstoissues  → 任务转 GitHub Issue

━━━━━━━━━━━━━━━━━━━━━━━━ 关键产出路径 ━━━━━━━━━━━━━━━━━━━━━━━━━
  {AGENT_FILE}              ← AI 指令文件（含 SDD 工作流说明）
  .specify/memory/          ← Constitution + 经验库
  {AGENT_SKILL_DIR}/speckit-*/   ← SDD 命令
  {AGENT_SKILL_DIR}/retro/       ← 复盘命令

经验闭环：实现完成 → 复盘提示 → /retro 沉淀 → lessons.md 入库
           → 下次会话 {AGENT_FILE} 强制读 lessons.md → 经验被自动参考
```

> 以上说明已固化到 `{AGENT_FILE}` 的 SDD 章节中（含流程、命令清单、产出路径、经验沉淀），后续每次会话均可查阅。

## 约束

- 不删除用户已有文件，除非明确同意
- 注入 `{AGENT_FILE}` 用 `<!-- SDD:START -->` / `<!-- SDD:END -->` 标记
- 已有项目先展示变更摘要再执行：即将创建的文件清单（.specify/ 目录结构、{AGENT_SKILL_DIR}/speckit-*、{AGENT_FILE} 注入段）、即将修改的现有文件（{AGENT_FILE}、{AGENT_SKILL_DIR}/speckit-*）。用户确认后再执行
- 不再调用内置 `/init`
- 经验沉淀机制（/retro + lessons.md + speckit 改造）是初始化的一部分，不要跳过
- **错误处理原则**：未特别说明的步骤，失败即终止并报告原因，不得静默继续。关键步骤的失败处理已在各阶段中单独标注
- **回滚与恢复**：如果初始化在中间步骤失败，项目可能处于半初始化状态。按以下方式清理：
  - `specify init` 已完成但后续步骤失败 → `.specify/` 目录已创建，保留不变；`{AGENT_FILE}` 中若已注入 `<!-- SDD:...-->` 标记，手动删除标记段即可恢复
  - `specify init` 本身失败 → 没有任何文件变更，无需回滚
  - 经验沉淀步骤（阶段 3）已修改 `/speckit-plan` 或 `/speckit-implement` 但后续失败 → 在对应文件的 `<!-- ⚠ 自动追加...-->` 标记处删除注入内容即可恢复
  - **完整清理**：`rm -rf .specify/ {AGENT_SKILL_DIR}/speckit-* {AGENT_SKILL_DIR}/retro` + 从 `{AGENT_FILE}` 中移除 `<!-- SDD:START -->` 至 `<!-- SDD:END -->` 段
