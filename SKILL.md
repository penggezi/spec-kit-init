---
name: spec-kit-init
description: |
  项目初始化与 SDD 规范一体化工具。替代默认的 /init，在一次初始化中同时完成：
  代码库分析 → SDD 工作流搭建 → 经验沉淀机制 → 代码质量门禁 → Bug 修复工作流。

  触发场景（高优先级）：
  - 用户提到：初始化项目、init、initialize、项目初始化、新建项目
  - 用户提到：spec-kit、specify、SDD、规格驱动开发、spec-driven
  - 用户提到：初始化 SDD 规范、项目规范化、specify init
  - 用户提到："用 spec-kit 初始化"、"搭建 SDD 工作流"、"项目初始化规范文件"
  - 用户想要为项目建立结构化的开发规范和工作流
  - 用户在空目录中开始新工作时

  当此 skill 触发时，不要调用内置的 /init 命令，因为本 skill 已包含其全部功能并在此基础上叠加 SDD 工作流。
---

# Spec-Kit 项目初始化（含代码库分析 + 经验沉淀机制）

## 核心职责

本 skill 是内置 `/init` 的增强替代版，一次完成五件事：

1. **代码库分析**（等同于 `/init`）→ 项目指令文件上半部分
2. **SDD 工作流搭建** → 项目指令文件下半部分（`<!-- SDD:START/END -->` 标记包裹）
3. **经验沉淀机制初始化** → `/retro` skill + `lessons.md` + 经验自动参考链路
4. **代码质量门禁初始化** → `/speckit-quality` skill（手动质量检查命令）
5. **Bug 修复工作流** → 自动安装官方 Bug Extension（`/speckit.bug.assess→fix→test`）

> **可选增强**：初始化时询问用户是否链接外部知识库（本地文档目录）。链接后注入 `{AGENT_FILE}`，AI 开发时按需参考——让 SDD 流程不局限于项目内已有信息。

**重要**：当本 skill 触发时，不要再调用内置 `/init`，本 skill 已包含其全部功能。

## 渐进式加载

先只阅读本文件。需要时再读取：

| 场景 | 文件 |
|------|------|
| 获取指令文件注入模板 | `assets/agent-instructions.md` |
| 获取完整 SDD 工作流文档模板（写入 `.specify/sdd-workflow.md`） | `assets/sdd-workflow-doc.md` |
| 获取注入文本和兜底追加文本 | `references/injection-texts.md` |
| 获取经验文件骨架模板 | `assets/lessons-skeleton.md` |
| 获取初始化失败回滚步骤 | `references/rollback-guide.md` |
| 获取 /retro skill 模板 | `assets/retro-skill.md` |
| 获取 /speckit-quality skill 模板 | `assets/quality-gate-skill.md` |
| 获取阶段 6 汇报模板 | `references/report-template.md` |
| 获取阶段 3-5 并行编排方案 | `references/parallel-orchestration.md` |
| 获取平台支持矩阵与组件依赖 | `references/platform-support-matrix.md` |

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

## 执行环境与路径约定

在执行任何文件操作之前，先解析并记录两个根目录。本 Skill 内所有路径都以它们为基准，**不得使用相对路径**——本 Skill 被调用时的工作目录是目标项目（PROJECT_ROOT），而不是本 Skill 所在目录。

| 变量 | 含义 | 管理哪些路径 |
|------|------|--------------|
| `SKILL_ROOT` | 本 Skill（spec-kit-init）所在目录的绝对路径，即当前 SKILL.md 的父目录 | `assets/`、`references/`、`scripts/` 下的资源文件 |
| `PROJECT_ROOT` | 用户调用本 Skill 时的项目根目录 | `.specify/`、`{AGENT_FILE}`、`{AGENT_SKILL_DIR}/...` |

路径规则：

- 读取 Skill 资源（`assets/*`、`references/*`、`scripts/*`）时，一律使用 `{SKILL_ROOT}/` 前缀，例如 `{SKILL_ROOT}/assets/agent-instructions.md`
- 写入或修改目标项目文件时，一律使用 `{PROJECT_ROOT}/` 前缀，例如 `{PROJECT_ROOT}/{AGENT_FILE}`
- 若无法确定 `SKILL_ROOT`（例如资源文件缺失），终止并报告「Skill 安装不完整，缺少 {文件}」，不要猜测路径继续执行
- 阶段 0 开始时校验以下资源存在，全部就绪才进入流程：
  - `{SKILL_ROOT}/SKILL.md`、`{SKILL_ROOT}/scripts/ensure-specify.sh`
  - `{SKILL_ROOT}/assets/agent-instructions.md`、`{SKILL_ROOT}/assets/sdd-workflow-doc.md`、`{SKILL_ROOT}/assets/lessons-skeleton.md`
  - `{SKILL_ROOT}/assets/retro-skill.md`、`{SKILL_ROOT}/assets/retro-references/`（目录）
  - `{SKILL_ROOT}/assets/quality-gate-skill.md`
  - `{SKILL_ROOT}/assets/speckit-memory/extension.yml`、`{SKILL_ROOT}/assets/speckit-memory/commands/speckit.memory.lookup.md`
  - `{SKILL_ROOT}/references/injection-texts.md`、`{SKILL_ROOT}/references/rollback-guide.md`

> 文档为简洁省略了 `{SKILL_ROOT}/` / `{PROJECT_ROOT}/` 前缀，但在实际执行时必须带上。

## 执行流程

### 阶段 0：初始化前检查

在开始任何实际变更之前，先检查项目是否已被本 Skill 初始化过，避免重复注入。

#### 0.1 检查项（分级检查）

> 所有检查路径均以 `{PROJECT_ROOT}` 为基准；资源文件校验见「执行环境与路径约定」。检查结果汇总为结构化状态，供 0.2 交叉验证和判定使用。

**A. 基础结构**

1. `.specify/` 目录是否存在
2. `.specify/config.yml` 是否存在（本 Skill 注入记录所在，见 `references/injection-texts.md` 第 9 节）
3. `.specify/sdd-workflow.md` 是否存在且非空
4. `{AGENT_FILE}` 是否存在；其中是否有 `<!-- SDD:START -->` 标记；SDD 段是否为精简版（特征：含 `.specify/sdd-workflow.md` 指针；完整版特征：含 `## 基础命令` 等二级标题但无指针）
5. `{AGENT_FILE}` 顶部是否已有「经验库优先」段（特征：含「纠正即捕获」标题）

**B. 增强资产**

6. `.specify/memory/lessons.md` 是否存在
7. `.specify/memory/lessons-index.md` 是否存在
8. `{AGENT_SKILL_DIR}/retro/SKILL.md` 是否存在，且含 `SPEC-KIT-INIT-MANAGED` 托管标记（区分新旧版本）
9. `{AGENT_SKILL_DIR}/retro/references/mechanism-auditor.md` 与 `routing-auditor.md` 是否存在
10. `{AGENT_SKILL_DIR}/speckit-quality/SKILL.md` 是否存在，且含 `SPEC-KIT-INIT-MANAGED` 托管标记
11. `.specify/extensions/bug/` 目录是否存在（Bug Extension）

**C. 注入完整性**（每条对照 `references/injection-texts.md` 第 9.1 节标记注册表，扫描目标文件中的 `SPEC-KIT-INIT` 标记；仅剩 Bug 链路与外部知识库两类注入，plan/implement 的经验注入已迁移为原生 Hook，见 D）

12. `/speckit.bug.assess` 中 `SPEC-KIT-INIT:BUG-ASSESS-LESSONS` 标记是否存在（若 Bug Extension 存在）
13. `/speckit.bug.test` 中 `SPEC-KIT-INIT:BUG-TEST-QUALITY-RETRO` 标记是否存在（若 Bug Extension 存在）
14. `{AGENT_FILE}` 中 `SPEC-KIT-INIT:KB-REFERENCE` 标记是否存在（若 `.specify/config.yml` 的 `knowledge_base.enabled=true`，Schema 见 `references/injection-texts.md` 第 9.3 节）

**D. 原生 Hook（memory 扩展，经验查阅 + 沉淀）**（读取 `.specify/extensions.yml` 的 `hooks:` 键，Schema 见 `references/injection-texts.md` 第 9.5 节）

15. `hooks.before_plan` 存在且指向 `speckit.memory.lookup`（`optional=false`）
16. `hooks.before_implement` 存在且指向 `speckit.memory.lookup`
17. `hooks.after_implement` 存在且指向 `retro`（`optional=true`）
18. `{AGENT_SKILL_DIR}/speckit-memory-lookup/SKILL.md` 是否存在（memory 扩展命令）

> **存量标记识别（旧版遗留）**：`/speckit-plan` 或 `/speckit-implement` 中仍存在 `SPEC-KIT-INIT:PLAN-LESSONS` / `IMPLEMENT-LESSONS` / `IMPLEMENT-RETRO` 标记 → 判定为旧版文本注入项目，升级（0.4）时移除旧文本并确认 hook 就位（见 0.4 升级说明）。

#### 0.2 交叉验证与状态判定

**配置记录 vs 实际状态**：读取 `.specify/config.yml` 中 `spec_kit_init.injections.*` 记录，与 0.1 扫描到的实际标记交叉验证（规则见 `references/injection-texts.md` 第 9.4 节）。`extensions.memory` 记录与 0.1 扫描到的实际 Hook 交叉验证（规则见第 9.5 节）。配置记录不是事实来源，`specify` 升级可能覆盖注入内容，必须两者同时读取。

**状态汇总**：将 0.1 的结果归类为「完成 / 缺失 / 被覆盖 / 需要人工确认」。

| 判定 | 条件 | 处理方式 |
|------|------|----------|
| 全新项目 | A、B、C 全部不存在 | 完整执行阶段 1-6 |
| 部分初始化 | 至少一个组件存在，但存在缺失或「配置有记录但实际无标记」的不一致 | 列出「完成 / 缺失 / 被覆盖」清单，询问用户走哪种模式：补齐（0.3）/ 升级（0.4） |
| 完整初始化 | A、B、C 全部就位，且无配置与实际不一致 | 告知用户已完成初始化，询问是否升级（0.4）或重建（0.4.2） |
| 旧式完整 SDD 段 | `{AGENT_FILE}` 有 `<!-- SDD:START -->` 且为完整版 + `.specify/sdd-workflow.md` 不存在 | 先执行阶段 0.5 自动迁移，迁移完成后按其余检查项继续判断 |

> **外部知识库为可选组件**：`knowledge_base.enabled=false` 或未配置时，检查项 18 视为「跳过」，不判缺失；配置为 `true` 但 `{AGENT_FILE}` 无 `SPEC-KIT-INIT:KB-REFERENCE` 标记时，按「被覆盖/缺失」处理，走 0.3 补齐。

#### 0.3 补齐模式（repair）

> 目标：只补齐缺失或恢复被覆盖的组件，**不覆盖用户已有的任何内容**。

根据检查结果，跳过已完成的步骤，仅执行缺失的部分。**补齐前先备份将修改的现有文件**（见 `references/rollback-guide.md` 事务清单）。

**判断依赖关系**：补齐时需考虑组件间的依赖顺序。读取 `references/platform-support-matrix.md` 中的「组件依赖矩阵」和「补齐场景决策表」，按依赖关系确定执行顺序。例如：
- 已有 `.specify/` 和 speckit-* 命令 → 跳过阶段 1.5
- 缺少 retro skill → 仅执行阶段 3.2（含 3.2.1）
- 缺少 quality gate → 仅执行阶段 4
- 缺少 memory hook（`hooks.before_plan` / `before_implement` / `after_implement` 任一缺失）→ 回阶段 3.1 重装 memory 扩展
- 配置有记录但实际无标记（被覆盖）→ 仅重新注入对应项，不重建其他组件
- 只有 `lessons-index.md` 缺失 → 从现有 `lessons.md` 正文重建索引（见 3.1 边界处理），不覆盖正文
- `knowledge_base.enabled=true` 但 `{AGENT_FILE}` 无 `SPEC-KIT-INIT:KB-REFERENCE` 标记 → 仅重新注入外部知识库段（阶段 2 的 KB 注入步骤），不重复询问路径（沿用 config.yml 中已记录的路径）

**修补失败路径**：注入被覆盖且锚点匹配率仍低时，该注入标记为 `overwritten`，走兜底追加并提示人工确认位置。Hook 无兜底追加概念——重装 memory 扩展即恢复（`specify extension add ... --dev --force` 幂等）。

#### 0.4 升级 / 重建模式

> 旧版「强制重新初始化」语义模糊，现拆分为两种模式：**升级**（默认推荐）和**重建**。

##### 0.4.1 升级（upgrade）

> 目标：把本 Skill 托管且**未被用户修改**的内容更新到当前模板版本；用户改过的内容不动。

判定与处理：

| 目标文件状态 | 处理 |
|--------------|------|
| 无 `SPEC-KIT-INIT-MANAGED` 标记 | 视为用户自建，跳过，不覆盖 |
| 有标记，`template-version` 与当前一致 | 跳过 |
| 有标记，`template-version` 落后，内容与安装时一致（hash 匹配） | 自动升级到当前模板 |
| 有标记，内容与安装时不一致（hash 不匹配，用户改过） | 展示差异，询问用户：覆盖 / 保留 / 合并 |

处理完成后，更新 `.specify/config.yml` 中对应 `assets.*` 的 `template-version` 与 `content_hash`。若同时检测到注入标记被覆盖（`overwritten`），顺带恢复注入。

**存量经验注入迁移（旧版文本 → 原生 Hook）**：若 0.1 检测到 `/speckit-plan` 或 `/speckit-implement` 中残留旧版 `SPEC-KIT-INIT:PLAN-LESSONS` / `IMPLEMENT-LESSONS` / `IMPLEMENT-RETRO` 标记文本，说明项目由旧版本 Skill 初始化。升级时执行迁移：

1. 安装 memory 扩展（若 hook 已就位则跳过）：`specify extension add "{SKILL_ROOT}/assets/speckit-memory" --dev --force`
2. **移除** speckit-plan / speckit-implement 中的旧注入文本（`SPEC-KIT-INIT:*-LESSONS` / `*-RETRO` 标记包裹的段落——本 Skill 托管内容，被 hook 取代，安全删除；若用户改过该段落，先展示差异再确认）
3. 更新 `.specify/config.yml`：删 `injections.speckit_plan_lessons` / `speckit_implement_lessons` / `speckit_implement_retro`，改记 `extensions.memory`（Schema 见 `references/injection-texts.md` 第 9.5 节）

> **迁移后行为等价**：`before_plan` / `before_implement` 钩子强制触发 `speckit.memory.lookup` 查阅经验（原"MUST 读"）；`after_implement` 钩子可选询问复盘（原"完成后询问"）。bug-assess / bug-test 两处注入不受影响，保留标记。

##### 0.4.2 重建（reset，原「强制重新初始化」）

先展示将被覆盖/修改的文件完整清单（含托管标记判断出的用户改动项），**明确说明哪些是用户内容会被覆盖**，用户确认后完整执行阶段 1-6。重建前对所有将修改的现有文件做事务备份，失败时按 `references/rollback-guide.md` 恢复。

#### 0.5 自动迁移旧式完整 SDD 段

> **设计意图**：旧版初始化把完整 SDD 工作流说明（~150 行）直接注入 `{AGENT_FILE}`，导致非 SDD 任务的每次会话都加载完整文档。本步骤将旧式完整 SDD 段抽取到 `.specify/sdd-workflow.md`，并把 `{AGENT_FILE}` 中的段落替换为精简版（命令速查表 + 指针），一次补齐存量项目。

**触发条件**：`{AGENT_FILE}` 有 `<!-- SDD:START -->` 标记且 SDD 段为完整版（不含 `.specify/sdd-workflow.md` 指针，含 `## 基础命令` 等二级标题）+ `.specify/sdd-workflow.md` 不存在。

**执行步骤**：

1. 读取 `{AGENT_FILE}` 中 `<!-- SDD:START -->` 与 `<!-- SDD:END -->` 之间的完整内容
2. 将该内容写入 `.specify/sdd-workflow.md`：
   - 去掉 `<!-- SDD:START -->` / `<!-- SDD:END -->` 标记行
   - 首行标题改为 `# SDD 工作流指南（完整版）`，并在标题下补一行 `> 本文件由 spec-kit-init 从 {AGENT_FILE} 迁移生成，是 SDD 完整工作流说明。`
   - 其余内容原样保留（其中的 `{AGENT_FILE}` 等占位符已被此前注入替换为实际值）
3. 将 `{AGENT_FILE}` 中的 SDD 段整体替换为精简版（`{SKILL_ROOT}/assets/agent-instructions.md` 第 1 节内容）
4. 告知用户：「已将 {AGENT_FILE} 中的完整 SDD 说明迁移到 `.specify/sdd-workflow.md`，{AGENT_FILE} 已替换为精简摘要（命令速查 + 指针），非 SDD 任务不再加载完整 SDD 文档。」

**边界处理**：
- `.specify/sdd-workflow.md` 已存在且非空 → 跳过抽取，仅将 `{AGENT_FILE}` 的 SDD 段替换为精简版（避免覆盖用户已有内容）
- `{AGENT_FILE}` 中无 SDD 标记但 `.specify/sdd-workflow.md` 缺失 → 归入阶段 0.3 补齐流程，执行阶段 2 的写入步骤

### 阶段 1：分析 + 初始化

#### 1.1 环境检测

确认核心依赖就绪：

- Python 3.11+：依次尝试 `python3 --version` → `python --version` → `py -3 --version`（Windows 常见只有 `python` 或 `py`），取第一个成功且版本号 ≥ 3.11 的命令；版本不足时引导用户升级
- Git（`git --version`）
- [uv](https://docs.astral.sh/uv/)（`uv --version`，如未安装引导用户安装）

> `specify-cli` 的检测和安装推迟到 1.5 步，仅在选择了 Claude Code 或 Codex 时执行。

#### 1.2 选择 AI 编码工具

**优先自动检测**，按以下顺序检查项目根目录中是否存在对应平台的指令文件：

| 检测文件 | 对应平台 | 优先级 |
|----------|----------|--------|
| `CLAUDE.md` | Claude Code | 1（最高） |
| `AGENTS.md` | Codex | 2 |
| `.github/copilot-instructions.md` | GitHub Copilot | 3 |
| `.cursor/rules/` 目录（含 `.mdc` / `.md`）或 `.cursorrules` | Cursor | 4 |

**检测逻辑**：
- 恰好命中一个 → 直接使用，告知用户"检测到项目使用 {AGENT_NAME}，自动配置"
- 命中多个（如同时有 CLAUDE.md 和 AGENTS.md）→ 列出检测到的平台，询问用户选择
- 未命中任何 → 询问用户选择：

```
当前项目使用哪个 AI 编码工具？
  1. Claude Code
  2. Codex
  3. GitHub Copilot
  4. Cursor
  5. 其他（自定义）→ 逐一配置 AGENT_FILE / AGENT_TITLE / AGENT_NAME / AGENT_SKILL_DIR / AGENT_SPECIFY
```

根据选择记录以下变量：

| 变量                | 用途                       | Claude Code      | Codex            | Copilot                           | Cursor            |
| ----------------- | ------------------------ | ---------------- | ---------------- | --------------------------------- | ----------------- |
| `AGENT_FILE`      | 指令文件路径                   | `CLAUDE.md`      | `AGENTS.md`      | `.github/copilot-instructions.md` | `.cursor/rules/spec-kit-init.mdc` ² |
| `AGENT_TITLE`     | 文件 `#` 标题                | `# CLAUDE.md`    | `# AGENTS.md`    | `# Tips`                          | `# Spec-Kit 项目规则` |
| `AGENT_NAME`      | 展示名称                     | `Claude Code`    | `Codex`          | `GitHub Copilot`                  | `Cursor`          |
| `AGENT_SKILL_DIR` | skill 安装目录               | `.claude/skills` | `.agents/skills` | `.claude/skills`¹                 | `.claude/skills`¹ |
| `AGENT_SPECIFY`   | specify --integration 参数 | `claude`         | `codex`          | `N/A`                             | `N/A`             |

如检测到项目中已有指令文件（如 CLAUDE.md、AGENTS.md），可跳过询问直接使用对应平台的变量。

> ¹ Copilot/Cursor 自身无标准 skill 系统，此处仅用于统一安装 retro skill（经验沉淀），speckit-\* 系列命令将在后续步骤中自动跳过。
>
> ² Cursor 的 `AGENT_FILE` 是**具体文件**而非目录：`.cursor/rules/` 是规则目录，本 Skill 写入独立的 `.cursor/rules/spec-kit-init.mdc`，不修改用户已有的其他规则文件。文件需带 `.mdc` frontmatter（`description` + `alwaysApply: true`）。若项目只有旧版 `.cursorrules`，仍创建新的 `.cursor/rules/spec-kit-init.mdc`，不覆盖旧文件。

> **注意**：Copilot 和 Cursor 的 `specify` 支持有限，speckit-\* 系列命令与 `/retro` 斜杠命令**不可用**。经验沉淀机制在这些平台上仅保留「经验文件读取 + 纠正即捕获 + 自然语言复盘」能力：`lessons.md` 是纯 Markdown 文件，与平台无关；指令注入段中涉及 `调用 /retro` 的表述，在这些平台替换为「按项目指令文件中的复盘流程执行」。

#### 1.2.1 配置确认

选择完成后，确认以下配置变量。后续所有阶段引用此配置，不再回溯：

```
AGENT_FILE      = 指令文件路径
AGENT_TITLE     = 文件标题
AGENT_NAME      = 展示名称
AGENT_SKILL_DIR = skill 安装目录
AGENT_SPECIFY   = specify --integration 参数（claude/codex/N/A）
```

> 选择「其他」时，需逐一确认以上五项配置的取值。

#### 1.2.2 询问外部知识库（可选）

> **设计意图**：外部知识库是项目外的本地文档目录（如团队 wiki、历史项目资料）。链接后 AI 在开发时按需参考，让 SDD 流程不局限于项目内已有信息。这是**可选增强**，不配置也不影响初始化。

询问用户：

```
是否链接外部知识库（本地文档目录）供 AI 开发时按需参考？(y/n)
- 是 → 请输入知识库目录路径（支持多个，用空格分隔；建议使用绝对路径）
- 否 → 跳过，后续可在 {AGENT_FILE} 中手动添加
```

**路径校验**：对每个路径执行 `test -d "{路径}"`，存在且为目录才接受；不存在的路径列出并重新询问（Windows 路径在 Git Bash 下可用正斜杠或转义形式）。

选择后记录变量：
- `KB_ENABLED` = true / false
- `KB_PATHS` = 通过校验的绝对路径列表（如 `D:/team-wiki D:/proj-docs`）

知识库是**只读外部资源**：后续任何阶段只读取、绝不写入或修改知识库目录。

#### 1.3 确认执行

在进入实际执行前，展示摘要并确认：

```
即将开始初始化 SDD 工作流，包括：
- 安装 SDD 命令框架（/speckit-*）+ Bug 修复工作流（/speckit.bug.*）
- 配置经验沉淀机制（/retro + lessons.md）
- 安装代码质量门禁（/speckit-quality）
- 自动初始化基本宪章（后续可通过 /speckit-constitution 修订）
{若 KB_ENABLED=true 追加：- 链接外部知识库（{KB_PATHS}），AI 开发时按需参考}

确认继续？(y/n)
```

如 `KB_ENABLED=true`，在摘要中追加外部知识库行，并提示「知识库为只读参考，不会被修改」。如项目已有 `{AGENT_FILE}` 且会被修改，额外提示「将修改已有的 {AGENT_FILE}，原内容保留不变」。详细信息在初始化完成后（阶段 6）展示。

#### 1.4 代码库分析（空目录跳过）

对已有项目，收集：

- 构建/开发命令（build、lint、test、单测运行）
- 高层架构（需要跨文件理解的核心设计）
- 现有配置（README.md、.cursor/rules/、.cursorrules、.github/copilot-instructions.md 等）
- 已有约束配置（`.editorconfig`、`eslint`/`prettier` 配置、构建脚本中的质量门禁，提取 1-2 条已有约束供初始宪章使用）
- 技术栈

分析结果用于生成 `{AGENT_FILE}` 的代码库文档部分，要求：

- 中文撰写
- 以 `{AGENT_TITLE}\n\n本文件为 {AGENT_NAME} 在本仓库中工作时提供指引。` 开头
- 聚焦"大图"，不列每个文件、不写通用实践、不编造内容

#### 1.5 执行 specify init（含 Bug Extension 安装）

> 此步仅在选择了 Claude Code 或 Codex 时执行（`{AGENT_SPECIFY}` 为 `claude` 或 `codex`）。Copilot/Cursor 跳过。
>
> ⚡ **并行提示**：此步骤与 1.4（代码库分析）互不依赖，可并行执行。优先使用后台任务模式启动本步骤，在等待期间执行 1.4 的代码分析，最后等待本步骤完成。

**开始前告知用户**：正在安装 specify-cli、初始化 SDD 工作流并安装 Bug Extension，约需 1-2 分钟，请稍候。

检测并安装 `specify-cli`：

```bash
bash "{SKILL_ROOT}/scripts/ensure-specify.sh"
```

`ensure-specify.sh` 会自动检测 `uv` 和 `specify`，未安装时自动安装。脚本带安装后硬校验（确认 `specify` 可执行而非仅安装命令退出码为 0），失败时根据提示处理。

安装成功后执行 `specify init`。由于 `--force` 不跳过内部交互式选择，在非交互式终端中须通过管道发送空行避免阻塞：

```bash
echo "" | PYTHONIOENCODING=utf-8 specify init --here --integration {AGENT_SPECIFY} --force --ignore-agent-tools && specify extension add bug --force
```

> `PYTHONIOENCODING=utf-8` 防止 Windows 上的 unicode 编码问题。
> Bug Extension（`/speckit.bug.assess → /speckit.bug.fix → /speckit.bug.test`）已随 `specify-cli` 打包，安装无需网络，直接链在 `specify init` 后一步完成。

如 `--ignore-agent-tools` 不被当前版本识别，去掉该参数再试：

```bash
echo "" | PYTHONIOENCODING=utf-8 specify init --here --integration {AGENT_SPECIFY} --force && specify extension add bug --force
```

**安装 memory 扩展（经验查阅 + 沉淀钩子）**：`specify init` 与 Bug Extension 安装后，安装本 Skill 自带的 memory 扩展。它会自动注册 `speckit.memory.lookup` 命令与 3 个原生 Hook（`before_plan` / `before_implement` 触发经验查阅，`after_implement` 触发复盘询问），由 spec-kit 模板内建逻辑读取，**无需任何文本注入**：

```bash
specify extension add "{SKILL_ROOT}/assets/speckit-memory" --dev --force
```

> `--dev` 表示从本地目录安装（`specify extension add` 支持把路径作为参数）。安装后 `.specify/extensions.yml` 的 `hooks:` 键会出现这 3 个 Hook，speckit-plan / speckit-implement 模板会在对应生命周期节点自动读取并触发（`before_` 强制执行，`after_` 可选询问）。Hook 是项目配置文件里的数据，spec-kit 升级不覆盖，天然抗升级。
>
> memory 扩展安装失败**不阻断**初始化——标记为「可降级」，阶段 0 补齐模式下可重装。

如已有 `.specify/` 目录，先询问用户是否覆盖。如果用户拒绝覆盖，跳过本步并告知用户 SDD 工作流结构已存在，后续注入将继续。
如 `specify init` 失败，输出完整错误信息并终止，提示用户检查网络和 GitHub 访问。如 `specify init` 成功但 `specify extension add bug` 失败，记录失败原因，后续阶段 5 注入将跳过。

这会创建完整的 SDD 工作流结构：

- `.specify/` — 配置和模板
- `{AGENT_SKILL_DIR}/speckit-*/` — 所有 `/speckit-*` 斜杠命令
- `.specify/extensions/bug/` — Bug 修复工作流（assess → fix → test）

**版本兼容性检查**：`specify init` 成功后，执行 `specify --version` 获取版本号。与本 Skill 的已知兼容版本列表（见 `references/injection-texts.md` 锚点定义节）比对：

- 版本匹配 → 正常继续
- 版本不匹配 → 输出警告「spec-kit 版本 {当前版本} 可能与本 Skill 注入锚点不完全兼容，建议关注后续阶段的注入结果」，但**继续执行**（因为 spec-kit 的变更日志未知，无法预先断定不兼容）。注入阶段（3/5）的兼容性预检会进一步判断

*speckit-git-* 清理\*：`specify init` 可能仍会生成 `speckit-git-*` 相关 skill（git commit/tag/rebase 等工作流扩展），这些命令不在本 Skill 核心流程范围内。**清理前先确认**：

1. 在 `specify init` 执行前，记录 `{PROJECT_ROOT}/{AGENT_SKILL_DIR}/` 下已有的 `speckit-git-*` 目录清单（防止误删用户原有内容）
2. `specify init` 执行后，只清理**本次新增**的 `speckit-git-*` 目录；若无法区分新旧，列出清单询问用户确认后再删除

```bash
rm -rf "{PROJECT_ROOT}/{AGENT_SKILL_DIR}"/speckit-git-*
```

> 使用 `{PROJECT_ROOT}/{AGENT_SKILL_DIR}` 前缀，确保删除发生在目标项目而非 Skill 目录。

#### 1.6 自动写入基本宪章

> 仅在 1.5（specify init）成功执行后执行。Copilot/Cursor 跳过。

Constitution 是 SDD 的最高准则。初始化时自动写入一份基本宪章作为起点，后续用户可通过 `/speckit-constitution` 修订。

检查 `.specify/memory/constitution.md` 是否已存在且非空：
- 已有内容 → 跳过，不覆盖用户已有的宪章
- 不存在或为空 → 自动写入基本宪章

```markdown
# Constitution

## 项目基本信息
- 项目名称：{从 1.4 代码库分析中推断}
- 项目描述：{从 1.4 代码库分析中推断}
- 技术栈：{从 1.4 代码库分析中推断}

## 核心原则
1. **代码质量**：所有代码须通过 lint 和测试后方可提交
2. **规格驱动**：新功能必须先写 spec.md，再写代码
3. **经验复用**：每次实现完成后进行复盘，经验写入 lessons.md
4. **渐进式变更**：优先最小化修改，避免不必要的重构

## 技术约束
- 遵循项目已有的技术栈和架构模式
- 新增依赖需评估必要性和兼容性

## 评审与修订
本宪章为初始化时自动生成的基本框架。如需修订，请使用 `/speckit-constitution` 命令。
```

> 以上内容为基本模板，具体项目名、描述和技术栈从 1.4 代码库分析结果中填充。

### 阶段 2：合并产出指令文件

读取 `assets/agent-instructions.md` 获取注入模板。目标文件为阶段 1.2 选定的 `{AGENT_FILE}`。本阶段产出两份文件：

1. **`{AGENT_FILE}`** — 注入「经验库优先」段 + 外部知识库段（若启用）+ **精简** SDD 段落（命令速查表 + `.specify/sdd-workflow.md` 指针）
2. **`.specify/sdd-workflow.md`** — 完整 SDD 工作流文档（读取 `assets/sdd-workflow-doc.md`，替换其中的 `{AGENT_FILE}` / `{AGENT_NAME}` / `{AGENT_SKILL_DIR}` 变量后写入；已存在且非空则跳过，不覆盖）

`{AGENT_FILE}` 的合并规则：

- 有 `<!-- SDD:START -->` 标记 → 只替换标记间内容，保留其余
- 无标记，有文件 → 末尾追加标记包裹的精简 SDD 段落
- 无文件 → 新建（代码库文档 + 经验库优先段 + 外部知识库段（若启用）+ 精简 SDD 段）

关键点：

- **必须在** **`{AGENT_FILE}`** **顶部注入「经验库优先」段**：在 `{AGENT_TITLE}` 标题行之后、第一个 `##` 节之前，插入模板第 2 节内容。带 YAML frontmatter 的目标文件（如 Cursor 的 `.mdc`）先跳过 frontmatter，在 `---` 结束之后、一级标题之后插入
- 若 `KB_ENABLED=true`，在「经验库优先」段之后、精简 SDD 段之前，插入「外部知识库」段（模板见 `assets/agent-instructions.md` 第 2.5 节）：将 `{KB_PATHS}` 替换为实际路径列表（**每个路径一行**，只替换占位符，不引入模板注解文字）。注入成功后记录 `spec_kit_init.injections.knowledge_base_reference`（`status: applied`，Schema 见 `references/injection-texts.md` 第 9.3 节）
- 精简 SDD 段落使用模板第 1 节内容（只含命令速查表 + 指针，**不**含完整命令说明）
- 完整工作流文档写入 `.specify/sdd-workflow.md`（读取 `{SKILL_ROOT}/assets/sdd-workflow-doc.md`），确保包含 `/retro` 行和「经验沉淀（Retro）」章节
- 写入后确认两份文件均存在且非空
- 注入完成后，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.agent_instructions` 字段（`status: applied`，Schema 见 `references/injection-texts.md` 第 9.3 节）

### 阶段 3-5 并行编排

阶段 3（经验沉淀）、阶段 4（质量门禁）、阶段 5（Bug 修复）中有多个步骤互不依赖。详细编排方案（含依赖图和每波说明）见 `references/parallel-orchestration.md`，以下为摘要：

- **第一波**：3.1 校验 memory 扩展 + 创建经验文件 ⚡ 3.2 安装 /retro（含 3.2.1）⚡ 4.1 安装 /speckit-quality（三个文件创建操作，互不依赖；3.1 依赖 1.5 已安装 memory 扩展，如缺失则顺带重装）
- **第二波**：3.3 校验 /speckit-plan 经验查阅钩子 ⚡ 3.4 校验 /speckit-implement 经验查阅 + 复盘钩子 ⚡ 5.1 验证 Bug Extension（均为只读验证，无文件冲突；5.1 依赖 1.5 安装结果）
- **收尾**：3.5 验证经验闭环 ⚡ 4.2 验证质量门禁，然后顺序执行 5.2（依赖 5.1）→ 5.3

> 并行编排是执行建议，非硬性约束。串行执行不会导致失败或内容缺失，仅总耗时增加。

### 阶段 3：经验沉淀机制初始化

这是本 skill 相比标准 `specify init` 的增强部分——在 SDD 工作流的基础上，建立从"写完代码"到"经验被复用"的完整闭环。

#### 3.1 校验 memory 扩展 + 创建经验文件骨架 ⚡第一波

> **设计意图**：经验资产的"接入"通过 spec-kit **原生 Hook** 实现，不再向 speckit-* 命令注入文本。memory 扩展已在阶段 1.5 随 `specify extension add memory` 安装，本步校验其就位；如 1.5 被跳过或缺钩子（补齐场景），在此重装。经验文件放在 `.specify/memory/` 下，与 `constitution.md` 同目录，供 `speckit.memory.lookup` 命令与 `/retro` 统一读取。

**校验 & 补齐 memory 扩展**（经验查阅 / 复盘钩子）：

1. 读取 `.specify/extensions.yml`，确认 `hooks.before_plan`、`hooks.before_implement`（均指向 `speckit.memory.lookup`）与 `hooks.after_implement`（指向 `retro`）三个钩子存在
2. 任一缺失，或 `{AGENT_SKILL_DIR}/speckit-memory-lookup/SKILL.md` 不存在 → 重装：

   ```bash
   specify extension add "{SKILL_ROOT}/assets/speckit-memory" --dev --force
   ```

   > spec-kit 模板内建读取 `hooks.before_plan / before_implement / after_implement`（原生能力），无需向 speckit-plan / speckit-implement 注入任何文本。钩子引用 `retro` 只是数据——运行时 `retro` skill 已由 3.2 就位，安装顺序不影响。重装仅影响本 Skill 托管内容，不会触碰用户对 extensions.yml 的其他修改。

3. 在 `.specify/config.yml` 中记录 `spec_kit_init.extensions.memory` 状态（Schema 见 `references/injection-texts.md` 第 9.5 节）。

**创建经验文件骨架**：读取 `{SKILL_ROOT}/assets/lessons-skeleton.md`，按其中的模板创建两个文件。**两个文件逐文件独立处理，不得用模板整体覆盖已有文件**：

| 文件状态 | 处理 |
|----------|------|
| 不存在 | 按模板创建 |
| 存在且非空 | 保留，不覆盖 |
| 存在但为空 | 询问用户后再按模板补齐 |

**边界处理（单文件缺失）**：
- 仅 `lessons-index.md` 缺失 → 从现有 `lessons.md` 正文重建索引（逐条提取 `## YYYY-MM-DD · 标题` 生成 `YYYY-MM-DD · 根因关键词 · 简述`），不要创建空索引
- 仅 `lessons.md` 缺失 → 保留 `lessons-index.md`，创建正文骨架，并提示索引中可能存在悬空记录
- 两文件均为空内容（如刚初始化）→ 正常按模板创建

产出文件（均在 `{PROJECT_ROOT}/.specify/memory/` 下）：
- `.specify/memory/lessons.md` — 经验正文（最新在上）
- `.specify/memory/lessons-index.md` — 轻量去重索引（与正文物理隔离，append-only 写入）

#### 3.2 安装 /retro skill ⚡第一波

> 如果 `{AGENT_SKILL_DIR}` 不可用或为 undefined（如自定义模式未指定），默认使用 `.claude/skills` 作为回退目录。

读取 `{SKILL_ROOT}/assets/retro-skill.md`，部署到 `{PROJECT_ROOT}/{AGENT_SKILL_DIR}/retro/SKILL.md`。部署判定（模板含 `SPEC-KIT-INIT-MANAGED` 托管标记，见 `references/injection-texts.md` 第 9.2 节）：

| 目标文件状态 | 处理 |
|--------------|------|
| 不存在 | 直接写入当前模板 |
| 含托管标记，`template-version` 与当前一致 | 跳过（幂等） |
| 含托管标记，`template-version` 落后且内容与安装时一致 | 自动升级到当前模板 |
| 含托管标记，内容与安装时不一致（用户改过） | 展示差异，询问用户：覆盖 / 保留 / 合并 |
| 无托管标记 | 视为用户自建文件，跳过并在汇报中说明 |

部署完成后，在 `.specify/config.yml` 中记录/更新 `spec_kit_init.assets.retro.template_version` 与 `content_hash`（计算已部署文件的 sha256）。

#### 3.2.1 安装 /retro 子代理审查模板

> retro skill 的对抗审查依赖两个独立的审查角色 prompt 模板。这些文件需要和 SKILL.md 一起部署到 retro skill 目录下。

将 `{SKILL_ROOT}/assets/retro-references/` 整个目录复制到 `{PROJECT_ROOT}/{AGENT_SKILL_DIR}/retro/references/`（注意源目录以 `.` 结尾，避免产生嵌套的 `references/retro-references/` 目录）：

```bash
mkdir -p "{PROJECT_ROOT}/{AGENT_SKILL_DIR}/retro/references"
cp -r "{SKILL_ROOT}/assets/retro-references/." "{PROJECT_ROOT}/{AGENT_SKILL_DIR}/retro/references/"
```

确认部署后的文件结构：

```
{AGENT_SKILL_DIR}/retro/
├── SKILL.md
└── references/
    ├── mechanism-auditor.md
    └── routing-auditor.md
```

如 references/ 已存在，仅覆盖同名文件，不删除其他已有文件。

#### 3.3 校验 /speckit-plan 经验查阅钩子 ⚡第二波

> **设计意图**：经验按"稳定性"分层——constitution 管最高原则（不可违反）、lessons 管实战经验（灵活积累），避免同级混放导致后续查找困难。
>
> **机制变更**：经验查阅已从"向 /speckit-plan 注入 MUST 读文本"改为 **spec-kit 原生 `before_plan` Hook**（memory 扩展，阶段 1.5/3.1 安装）。spec-kit 模板内建读取 `hooks.before_plan`，自动触发 `speckit.memory.lookup` 命令做两步查阅——**不再修改 speckit-plan 文件**。

> 仅在 `{AGENT_SPECIFY}` 有值时执行（Claude Code / Codex；Copilot/Cursor 无 speckit 命令，自动跳过）。

**验证**：读取 `.specify/extensions.yml`，确认 `hooks.before_plan` 存在且指向 `speckit.memory.lookup`，`optional=false`。

- 存在 → 通过（不做任何文件注入）
- 缺失 → 回阶段 3.1 补齐 memory 扩展

> **存量迁移**：旧版已注入 `SPEC-KIT-INIT:PLAN-LESSONS` 标记文本的项目，升级（0.4）时会移除该段旧文本（被 hook 取代），见 0.4 升级说明。

#### 3.4 校验 /speckit-implement 经验查阅 + 复盘钩子 ⚡第二波

> **设计意图**：在记忆最新鲜时捕捉经验——完成瞬间是复盘的最佳时机，而非事后再回忆。
>
> **机制变更**：经验查阅 + 复盘询问已从"注入 implement 两段文本"改为 **spec-kit 原生 Hook**——`before_implement` 触发 `speckit.memory.lookup`（查阅），`after_implement` 触发 `retro`（可选复盘询问）。**不再修改 speckit-implement 文件**。

> 仅在 `{AGENT_SPECIFY}` 有值时执行（Claude Code / Codex；Copilot/Cursor 自动跳过）。

**验证**：读取 `.specify/extensions.yml`，确认：

- `hooks.before_implement` 存在且指向 `speckit.memory.lookup`（查阅）
- `hooks.after_implement` 存在且指向 `retro`，`optional=true`（复盘询问，无价值场景由 /retro 自行跳过）

任一项缺失 → 回阶段 3.1 补齐 memory 扩展。

> **存量迁移**：旧版已注入 `IMPLEMENT-LESSONS` / `IMPLEMENT-RETRO` 标记文本的项目，升级（0.4）时会移除该段旧文本（被 hook 取代），见 0.4 升级说明。

#### 3.5 验证闭环完整性

确认以下链路连通：

- [ ] `{AGENT_SKILL_DIR}/retro/SKILL.md` 存在
- [ ] `{AGENT_SKILL_DIR}/retro/references/mechanism-auditor.md` 存在
- [ ] `{AGENT_SKILL_DIR}/retro/references/routing-auditor.md` 存在
- [ ] `.specify/memory/lessons.md` 存在
- [ ] `{AGENT_SKILL_DIR}/speckit-memory-lookup/SKILL.md` 存在（memory 扩展命令）
- [ ] `.specify/extensions.yml` 的 hooks 含 `before_plan` / `before_implement`（→ lookup）与 `after_implement`（→ retro）
- [ ] `.specify/sdd-workflow.md` 存在且非空（精简 SDD 段引用的完整工作流文档）
- [ ] `{AGENT_FILE}` 顶部有「经验库优先」段（含纠正即捕获指令）
- [ ] `/speckit-plan` 前 `before_plan` 钩子触发 `speckit.memory.lookup` 查阅经验
- [ ] `/speckit-implement` 前 `before_implement` 钩子查阅经验；完成后 `after_implement` 钩子询问复盘
- [ ] 复盘写入后，下次会话 `{AGENT_FILE}` 强制读 lessons.md → 经验被复用

### 阶段 4：代码质量门禁初始化

> 此阶段仅在选择了 Claude Code 或 Codex 时执行（`{AGENT_SPECIFY}` 有值）。Copilot/Cursor 跳过。

> **设计意图**：提供独立的 `/speckit-quality` 代码质量检查命令，供需要时手动执行（默认检查 Git 变更文件及有证据的直接影响范围，避免无关存量诊断污染上下文；只有改动风险、影响边界或用户要求触发时才升级至模块级或全量检查）。不再注入到 `/speckit-implement` 自动执行——实现完成后直接询问复盘，需要质量检查时手动调用。具体范围算法、技术栈命令与结果归因以 `assets/quality-gate-skill.md` 为唯一事实来源。

#### 4.1 安装 /speckit-quality skill ⚡第一波

读取 `{SKILL_ROOT}/assets/quality-gate-skill.md`，部署到 `{PROJECT_ROOT}/{AGENT_SKILL_DIR}/speckit-quality/SKILL.md`。部署判定与 3.2 相同（基于 `SPEC-KIT-INIT-MANAGED` 托管标记与 hash 比对）：

| 目标文件状态 | 处理 |
|--------------|------|
| 不存在 | 直接写入当前模板 |
| 含托管标记，`template-version` 与当前一致 | 跳过（幂等） |
| 含托管标记，`template-version` 落后且内容与安装时一致 | 自动升级到当前模板 |
| 含托管标记，内容与安装时不一致（用户改过） | 展示差异，询问用户：覆盖 / 保留 / 合并 |
| 无托管标记 | 视为用户自建文件，跳过并在汇报中说明 |

部署完成后，在 `.specify/config.yml` 中记录/更新 `spec_kit_init.assets.quality_gate.template_version` 与 `content_hash`。

确认安装后的文件结构：

```
{AGENT_SKILL_DIR}/speckit-quality/SKILL.md
```

#### 4.2 验证质量门禁完整性

确认以下链路连通：

- [ ] `{AGENT_SKILL_DIR}/speckit-quality/SKILL.md` 存在
- [ ] 空参数默认检查 Git 变更文件与有证据的直接影响范围，而不是全量扫描
- [ ] 已暂存、未暂存、未追踪、删除和重命名文件都有明确处理；删除文件不作为 lint 参数
- [ ] 范围规则定义了文件级、模块级、全量升级条件，以及无 Git/无初始提交的降级行为
- [ ] 质量报告区分本次变更、关联存量和无法归因的问题

### 阶段 5：Bug 修复工作流初始化

> **设计意图**：Bug Extension（`/speckit.bug.assess → /speckit.bug.fix → /speckit.bug.test`）已在阶段 1.5 随 `specify init` 一同安装。本阶段负责验证安装完整性，并将缺陷修复流程接入本项目已有的经验库、质量门禁和复盘闭环。

> 此步仅在 `{AGENT_SPECIFY}` 有值时执行（Claude Code / Codex）。Copilot/Cursor 跳过。

#### 5.1 验证安装完整性 ⚡第二波

确认以下命令可用：

- [ ] `/speckit.bug.assess` — 评估缺陷、定位根因路径、输出 assessment.md
- [ ] `/speckit.bug.fix` — 实施最小修复、输出 fix.md
- [ ] `/speckit.bug.test` — 验证修复并记录测试结果、输出 test.md

确认产物目录：

- [ ] `.specify/extensions/bug/` 存在
- [ ] `.specify/bugs/` 目录可写入

验证通过后，设置 `BUG_EXTENSION_INSTALLED=true`；若验证失败，设置 `BUG_EXTENSION_INSTALLED=false` 并记录失败原因（如阶段 1.5 中 `specify extension add bug` 已失败，直接沿用其失败原因）。

#### 5.2 注入增强：连接经验库 + 质量门禁 + 复盘

Bug Extension 的三步流程本身已完整，在此之上接入本项目已有的增强机制。

**前置检查**：读取阶段 5.1 设置的 `BUG_EXTENSION_INSTALLED` 变量：
- 若为 `false` → 跳过注入，告知用户"Bug Extension 未安装成功，注入已跳过。请先手动执行 `specify extension add bug`，然后重新运行本 Skill 的注入阶段。"
- 若为 `true` → 正常执行以下注入。

##### 5.2.1 改造 `/speckit.bug.assess`

读取 `{AGENT_SKILL_DIR}/speckit-bug-assess/SKILL.md`（或 `speckit.bug.assess`，取决于实际安装路径）。

**兼容性预检**：对照 `references/injection-texts.md` 第 8.3 节中的锚点列表匹配目标文件：

- 匹配率 ≥ 60%（≥3/5 个锚点命中）→ 正常执行以下正则匹配
- 匹配率 < 60% → **警告用户**「speckit-bug-assess 文件结构变化较大（锚点匹配率 {X}/5），注入已降级为文件末尾追加，请人工确认位置」→ 跳过正则匹配，使用第 5.2 节兜底追加文本

用语义正则定位到评估步骤开始前（匹配 `Assess`、`评估`、`analyze the bug` 等模式），在上下文读取步骤中插入。

读取 `references/injection-texts.md` 第 5 节获取注入文本和兜底追加文本。注入内容使用**两步读取**模式：先扫 `lessons-index.md` 判断相关性，命中后才读 `lessons.md` 具体条目。

**正则匹配失败时**：使用第 5.2 节兜底追加文本，追加后明确告知用户："/speckit.bug.assess 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit_bug_assess_lessons` 字段（Schema 见 `references/injection-texts.md` 第 9.3 节）。

##### 5.2.2 改造 `/speckit.bug.test`

读取 `{AGENT_SKILL_DIR}/speckit-bug-test/SKILL.md`（或 `speckit.bug.test`）。

**兼容性预检**：对照 `references/injection-texts.md` 第 8.4 节中的锚点列表匹配目标文件：

- 匹配率 ≥ 60%（≥3/5 个锚点命中）→ 正常执行以下正则匹配
- 匹配率 < 60% → **警告用户**「speckit-bug-test 文件结构变化较大（锚点匹配率 {X}/5），注入已降级为文件末尾追加，请人工确认位置」→ 跳过正则匹配，使用第 6.2 节兜底追加文本

用语义正则定位到验证步骤完成后（匹配 `test complete`、`verification done`、`验证完成` 等模式），插入。

读取 `references/injection-texts.md` 第 6 节获取注入文本和兜底追加文本。

**正则匹配失败时**：使用第 6.2 节兜底追加文本，追加后明确告知用户："/speckit.bug.test 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit_bug_test_quality_retro` 字段（Schema 见 `references/injection-texts.md` 第 9.3 节）。

> 注意：`specify extension` 重新安装或升级时可能覆盖注入内容，届时需重新执行注入。`.specify/config.yml` 中的注入记录可用于检测覆盖。

#### 5.3 复杂度升级规则

读取 `references/injection-texts.md` 第 7 节获取复杂度升级条件和建议格式。当满足任一条件时，告知用户需要升级到完整 SDD 规格链路。

### 阶段 6：汇报

按初始化操作顺序，逐一解释每个操作的作用和可选性，让用户理解 SDD 工作流的全貌。

读取 `references/report-template.md` 获取完整汇报模板。按模板中的「动态编号规则」，根据实际执行情况生成编号（跳过未执行的步骤，不留空位）。需要替换的变量：
- `{AGENT_FILE}` / `{AGENT_NAME}` / `{AGENT_SKILL_DIR}` — 来自阶段 1.2
- `{BUG_EXTENSION_INSTALLED}` — 来自阶段 5.1，若为 `false` 则将 `[核心-Bug修复]` 项替换为失败原因和手动重试命令 `specify extension add bug --force`，并移除 `[可选-Bug重试]`
- `{KB_ENABLED}` / `{KB_PATHS}` — 来自阶段 1.2.2，若 `KB_ENABLED=false` 则移除 `[可选-知识库]` 项
- `[核心-宪章]`：若 1.6 跳过（Copilot/Cursor 或已有宪章），将此项替换为「宪章已存在，跳过自动初始化」

> 以上说明已固化到 `.specify/sdd-workflow.md`（完整工作流指南）与 `{AGENT_FILE}` 的 SDD 精简段落（命令速查 + 指针）中，后续每次会话均可查阅。

## 约束

- 不删除用户已有文件，除非明确同意
- 注入 `{AGENT_FILE}` 用 `<!-- SDD:START -->` / `<!-- SDD:END -->` 标记；注入 speckit-* 命令用 `<!-- SPEC-KIT-INIT:<组件>:START/END -->` 标记（注册表见 `references/injection-texts.md` 第 9.1 节）。**经验查阅/复盘不再注入 speckit-* 命令**，由 memory 扩展的 spec-kit 原生 Hook 承担（注册表见 `references/injection-texts.md` 第 9.5 节）
- 已有项目先展示变更摘要再执行：即将创建的文件清单（.specify/ 目录结构、{AGENT\_SKILL\_DIR}/speckit-*、{AGENT\_FILE} 注入段）、即将修改的现有文件（{AGENT\_FILE}、{AGENT\_SKILL\_DIR}/speckit-*）。用户确认后再执行
- 不再调用内置 `/init`
- 经验沉淀机制（/retro + lessons.md + speckit 改造）是初始化的一部分，不要跳过
- 代码质量门禁（/speckit-quality 命令）是初始化的一部分，不要跳过（仅 Claude Code / Codex 平台）
- Bug 修复工作流（阶段 5）在 Claude Code / Codex 平台默认安装官方 Bug Extension；安装失败时必须报告原因和重试命令，不得静默跳过
- 外部知识库目录为**只读外部资源**：任何阶段不得写入或修改知识库目录内的文件；如检测到知识库路径不可访问，仅提示用户检查路径，不阻塞初始化
- **错误处理原则**：未特别说明的步骤，失败即终止并报告原因，不得静默继续。关键步骤的失败处理已在各阶段中单独标注。本 Skill 采用三级错误处理策略：

| 级别 | 定义 | 处理方式 | 典型场景 |
|------|------|----------|----------|
| **致命** | 核心 SDD 框架安装失败，后续阶段无法执行 | 终止并报告，引导用户检查环境 | `specify init` 失败 |
| **可降级** | 增强组件安装失败，不影响核心 SDD 流程 | 记录失败原因，后续关联步骤跳过，最终汇报中展示 | `specify extension add bug` 失败 |
| **可恢复** | 注入匹配失败，但可走兜底追加路径 | 执行兜底方案，明确告知用户需人工确认位置 | 正则匹配失败时追加到文件末尾 |

> 各阶段步骤的失败级别在其描述中标注（如「失败即终止」= 致命，「失败记录原因，后续跳过」= 可降级，「走兜底追加」= 可恢复）
- **事务与回滚**：执行任何变更前，在 `.specify/.spec-kit-init/transactions/<run-id>/` 建立事务清单（含备份与 manifest），修改现有文件前必须先备份。初始化中途失败时，读取 `references/rollback-guide.md` 按事务清单精确回滚——**只撤销本次运行创建/修改的内容，禁止无条件 `rm -rf` 或通配符清理**

