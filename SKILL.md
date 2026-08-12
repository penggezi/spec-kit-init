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
4. **代码质量门禁初始化** → `/speckit-quality` skill + implement 质量检查注入
5. **Bug 修复工作流** → 自动安装官方 Bug Extension（`/speckit.bug.assess→fix→test`）

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

## 执行流程

### 阶段 0：初始化前检查

在开始任何实际变更之前，先检查项目是否已被本 Skill 初始化过，避免重复注入。

#### 0.1 检查项

1. 检查 `.specify/` 目录是否存在
2. 检查 `{AGENT_FILE}` 中是否有 `<!-- SDD:START -->` 标记
3. 检查 `{AGENT_SKILL_DIR}/retro/SKILL.md` 是否存在
4. 检查 `{AGENT_SKILL_DIR}/speckit-quality/SKILL.md` 是否存在
5. 检查 `.specify/extensions/bug/` 目录是否存在
6. 检查 `.specify/sdd-workflow.md` 是否存在
7. 检查 `{AGENT_FILE}` 中 SDD 段是否为精简版（特征：含 `.specify/sdd-workflow.md` 指针；完整版特征：含 `## 基础命令` 等二级标题但无指针）

#### 0.2 判断逻辑

| 检查结果 | 处理方式 |
|----------|----------|
| 全部不存在 | 全新项目，完整执行阶段 1-6 |
| 部分存在（如只有 `.specify/` 但无 retro） | 告知用户当前状态，列出已完成和缺失的组件，询问：「检测到项目已部分初始化，是否仅补齐缺失组件？」 |
| `{AGENT_FILE}` 有 `<!-- SDD:START -->` 标记且 SDD 段为完整版（无 `.specify/sdd-workflow.md` 指针）+ `.specify/sdd-workflow.md` 不存在 | 自动迁移（阶段 0.5）：抽取完整 SDD 段到 `.specify/sdd-workflow.md`，替换为精简版。迁移完成后按其余检查项继续判断 |
| 全部存在 | 告知用户项目已完成初始化，询问：「项目已完成初始化。是否强制重新初始化？（这会覆盖已有配置）」 |

#### 0.3 用户选择"补齐缺失组件"

根据检查结果，跳过已完成的阶段，仅执行缺失的步骤。

**判断依赖关系**：补齐时需考虑组件间的依赖顺序。读取 `references/platform-support-matrix.md` 中的「组件依赖矩阵」和「补齐场景决策表」，按依赖关系确定执行顺序。例如：
- 已有 `.specify/` 和 speckit-* 命令 → 跳过阶段 1.5
- 缺少 retro skill → 仅执行阶段 3.2
- 缺少 quality gate → 仅执行阶段 4
- speckit-implement 缺少两项注入 → 先执行 3.4（经验注入）再执行 4.2（质量门禁注入），因为 4.2 需要知道 3.4 的注入路径

#### 0.4 用户选择"强制重新初始化"

先展示将被覆盖/修改的文件清单，用户确认后完整执行阶段 1-6。

#### 0.5 自动迁移旧式完整 SDD 段

> **设计意图**：旧版初始化把完整 SDD 工作流说明（~150 行）直接注入 `{AGENT_FILE}`，导致非 SDD 任务的每次会话都加载完整文档。本步骤将旧式完整 SDD 段抽取到 `.specify/sdd-workflow.md`，并把 `{AGENT_FILE}` 中的段落替换为精简版（命令速查表 + 指针），一次补齐存量项目。

**触发条件**：`{AGENT_FILE}` 有 `<!-- SDD:START -->` 标记且 SDD 段为完整版（不含 `.specify/sdd-workflow.md` 指针，含 `## 基础命令` 等二级标题）+ `.specify/sdd-workflow.md` 不存在。

**执行步骤**：

1. 读取 `{AGENT_FILE}` 中 `<!-- SDD:START -->` 与 `<!-- SDD:END -->` 之间的完整内容
2. 将该内容写入 `.specify/sdd-workflow.md`：
   - 去掉 `<!-- SDD:START -->` / `<!-- SDD:END -->` 标记行
   - 首行标题改为 `# SDD 工作流指南（完整版）`，并在标题下补一行 `> 本文件由 spec-kit-init 从 {AGENT_FILE} 迁移生成，是 SDD 完整工作流说明。`
   - 其余内容原样保留（其中的 `{AGENT_FILE}` 等占位符已被此前注入替换为实际值）
3. 将 `{AGENT_FILE}` 中的 SDD 段整体替换为精简版（`assets/agent-instructions.md` 第 1 节内容）
4. 告知用户：「已将 {AGENT_FILE} 中的完整 SDD 说明迁移到 `.specify/sdd-workflow.md`，{AGENT_FILE} 已替换为精简摘要（命令速查 + 指针），非 SDD 任务不再加载完整 SDD 文档。」

**边界处理**：
- `.specify/sdd-workflow.md` 已存在且非空 → 跳过抽取，仅将 `{AGENT_FILE}` 的 SDD 段替换为精简版（避免覆盖用户已有内容）
- `{AGENT_FILE}` 中无 SDD 标记但 `.specify/sdd-workflow.md` 缺失 → 归入阶段 0.3 补齐流程，执行阶段 2 的写入步骤

### 阶段 1：分析 + 初始化

#### 1.1 环境检测

确认核心依赖就绪：

- Python 3.11+（`python3 --version`）
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
| `.cursor/rules/` 目录 | Cursor | 4 |

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
| `AGENT_FILE`      | 指令文件路径                   | `CLAUDE.md`      | `AGENTS.md`      | `.github/copilot-instructions.md` | `.cursor/rules/`  |
| `AGENT_TITLE`     | 文件 `#` 标题                | `# CLAUDE.md`    | `# AGENTS.md`    | `# Tips`                          | `# Rules`         |
| `AGENT_NAME`      | 展示名称                     | `Claude Code`    | `Codex`          | `GitHub Copilot`                  | `Cursor`          |
| `AGENT_SKILL_DIR` | skill 安装目录               | `.claude/skills` | `.agents/skills` | `.claude/skills`¹                 | `.claude/skills`¹ |
| `AGENT_SPECIFY`   | specify --integration 参数 | `claude`         | `codex`          | `N/A`                             | `N/A`             |

如检测到项目中已有指令文件（如 CLAUDE.md、AGENTS.md），可跳过询问直接使用对应平台的变量。

> ¹ Copilot/Cursor 自身无标准 skill 系统，此处仅用于统一安装 retro skill（经验沉淀），speckit-\* 系列命令将在后续步骤中自动跳过。

> **注意**：Copilot 和 Cursor 的 `specify` 支持有限，speckit-\* 系列命令不可用，但 retro skill 和 lessons.md 经验沉淀机制不受影响，因为 `lessons.md` 是纯 Markdown 文件，与平台无关。

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

#### 1.3 确认执行

在进入实际执行前，展示摘要并确认：

```
即将开始初始化 SDD 工作流，包括：
- 安装 SDD 命令框架（/speckit-*）+ Bug 修复工作流（/speckit.bug.*）
- 配置经验沉淀机制（/retro + lessons.md）
- 安装代码质量门禁（/speckit-quality）
- 自动初始化基本宪章（后续可通过 /speckit-constitution 修订）

确认继续？(y/n)
```

如项目已有 `{AGENT_FILE}` 且会被修改，额外提示「将修改已有的 {AGENT_FILE}，原内容保留不变」。详细信息在初始化完成后（阶段 6）展示。

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
bash scripts/ensure-specify.sh
```

`ensure-specify.sh` 会自动检测 `uv` 和 `specify`，未安装时自动安装。失败时根据提示处理。

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

如已有 `.specify/` 目录，先询问用户是否覆盖。如果用户拒绝覆盖，跳过本步并告知用户 SDD 工作流结构已存在，后续注入将继续。
如 `specify init` 失败，输出完整错误信息并终止，提示用户检查网络和 GitHub 访问。如 `specify init` 成功但 `specify extension add bug` 失败，记录失败原因，后续阶段 5 注入将跳过。

这会创建完整的 SDD 工作流结构：

- `.specify/` — 配置和模板
- `{AGENT_SKILL_DIR}/speckit-*/` — 所有 `/speckit-*` 斜杠命令
- `.specify/extensions/bug/` — Bug 修复工作流（assess → fix → test）

**版本兼容性检查**：`specify init` 成功后，执行 `specify --version` 获取版本号。与本 Skill 的已知兼容版本列表（见 `references/injection-texts.md` 锚点定义节）比对：

- 版本匹配 → 正常继续
- 版本不匹配 → 输出警告「spec-kit 版本 {当前版本} 可能与本 Skill 注入锚点不完全兼容，建议关注后续阶段的注入结果」，但**继续执行**（因为 spec-kit 的变更日志未知，无法预先断定不兼容）。注入阶段（3/4/5）的兼容性预检会进一步判断

*speckit-git-* 清理\*：`specify init` 可能仍会生成 `speckit-git-*` 相关 skill（git commit/tag/rebase 等工作流扩展），这些命令不在本 Skill 核心流程范围内，执行清理：

```bash
rm -rf {AGENT_SKILL_DIR}/speckit-git-*
```

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

1. **`{AGENT_FILE}`** — 注入「经验库优先」段 + **精简** SDD 段落（命令速查表 + `.specify/sdd-workflow.md` 指针）
2. **`.specify/sdd-workflow.md`** — 完整 SDD 工作流文档（读取 `assets/sdd-workflow-doc.md`，替换其中的 `{AGENT_FILE}` / `{AGENT_NAME}` / `{AGENT_SKILL_DIR}` 变量后写入；已存在且非空则跳过，不覆盖）

`{AGENT_FILE}` 的合并规则：

- 有 `<!-- SDD:START -->` 标记 → 只替换标记间内容，保留其余
- 无标记，有文件 → 末尾追加标记包裹的精简 SDD 段落
- 无文件 → 新建（代码库文档 + 经验库优先段 + 精简 SDD 段）

关键点：

- **必须在** **`{AGENT_FILE}`** **顶部注入「经验库优先」段**：在 `{AGENT_TITLE}` 标题行之后、第一个 `##` 节之前，插入模板第 2 节内容
- 精简 SDD 段落使用模板第 1 节内容（只含命令速查表 + 指针，**不**含完整命令说明）
- 完整工作流文档写入 `.specify/sdd-workflow.md`（读取 `assets/sdd-workflow-doc.md`），确保包含 `/retro` 行和「经验沉淀（Retro）」章节
- 写入后确认两份文件均存在且非空

### 阶段 3-5 并行编排

阶段 3（经验沉淀）、阶段 4（质量门禁）、阶段 5（Bug 修复）中有多个步骤互不依赖。详细编排方案（含依赖图和每波说明）见 `references/parallel-orchestration.md`，以下为摘要：

- **第一波**：3.1 创建经验文件 ⚡ 3.2 安装 /retro ⚡ 4.1 安装 /speckit-quality（三个文件创建操作，互不依赖）
- **第二波**：3.3 改造 specit-plan ⚡ 3.4 改造 specit-implement（修改不同文件，无冲突）
- **第三波**：4.2 质量门禁注入 ⚡ 5.1 验证 Bug Extension（互不依赖），然后顺序执行 5.2 → 5.3
- **收尾**：3.5 验证经验闭环 + 4.3 验证质量门禁

> 并行编排是执行建议，非硬性约束。串行执行不会导致失败或内容缺失，仅总耗时增加。

### 阶段 3：经验沉淀机制初始化

这是本 skill 相比标准 `specify init` 的增强部分——在 SDD 工作流的基础上，建立从"写完代码"到"经验被复用"的完整闭环。

#### 3.1 创建经验文件骨架 ⚡第一波

> **设计意图**：放在 `.specify/memory/` 下，与 `constitution.md` 同目录，确保 speckit 生态内所有经验资产集中管理，便于 `/speckit-plan` 和 `/speckit-implement` 统一读取。

读取 `assets/lessons-skeleton.md`，按其中的模板创建：
- `.specify/memory/lessons.md` — 经验正文（最新在上）
- `.specify/memory/lessons-index.md` — 轻量去重索引（与正文物理隔离，append-only 写入）

#### 3.2 安装 /retro skill ⚡第一波

> 如果 `{AGENT_SKILL_DIR}` 不可用或为 undefined（如自定义模式未指定），默认使用 `.claude/skills` 作为回退目录。

读取 `assets/retro-skill.md`，将其内容写入 `{AGENT_SKILL_DIR}/retro/SKILL.md`。

如已有此文件，跳过创建。

#### 3.2.1 安装 /retro 子代理审查模板

> retro skill 的对抗审查依赖两个独立的审查角色 prompt 模板。这些文件需要和 SKILL.md 一起部署到 retro skill 目录下。

将 `assets/retro-references/` 整个目录复制到 `{AGENT_SKILL_DIR}/retro/references/`：

```bash
cp -r assets/retro-references/ {AGENT_SKILL_DIR}/retro/references/
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

#### 3.3 改造 /speckit-plan（注入 lessons.md 必读）⚡第二波

> **设计意图**：经验按"稳定性"分层——constitution 管最高原则（不可违反）、lessons 管实战经验（灵活积累），避免同级混放导致后续查找困难。

> 仅在 `{AGENT_SKILL_DIR}/speckit-plan/SKILL.md` 存在时执行（Copilot/Cursor 无 speckit 命令，自动跳过）。

**兼容性预检**：注入前先读取目标文件，对照 `references/injection-texts.md` 第 8.1 节中的锚点列表进行匹配：

- 匹配率 ≥ 60%（≥3/5 个锚点命中）→ 正常执行以下正则匹配
- 匹配率 < 60% → **警告用户**「speckit-plan 文件结构变化较大（锚点匹配率 {X}/5），注入已降级为文件末尾追加，请人工确认位置」→ 跳过正则匹配，直接使用第 1.2 节兜底追加文本

读取 `{AGENT_SKILL_DIR}/speckit-plan/SKILL.md`。

用语义正则定位到 "Load context" 相关步骤（匹配 `Load context`、`加载上下文` 或类似小节标题），在该步骤的读取列表中 `constitution.md` 之后追加一行。

读取 `references/injection-texts.md` 第 1 节，获取注入文本和兜底追加文本。注入内容使用**两步读取**模式：先扫 `lessons-index.md` 判断相关性，命中后才读 `lessons.md` 具体条目。

**正则匹配失败时**：使用第 1.2 节兜底追加文本，追加后明确告知用户："/speckit-plan 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit-plan` 字段，记录注入日期和内容摘要，供后续运行（阶段 0）跳过已完成注入。

#### 3.4 改造 /speckit-implement（注入 lessons.md 必读 + 复盘询问）⚡第二波

> **设计意图**：在记忆最新鲜时捕捉经验——完成瞬间是复盘的最佳时机，而非事后再回忆。自动提示确保"做完一件事"和"留下经验"不会脱钩。

> 仅在 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md` 存在时执行（Copilot/Cursor 无 speckit 命令，自动跳过）。

**兼容性预检**：注入前先读取目标文件，对照 `references/injection-texts.md` 第 8.2 节中的两组锚点分别匹配：

- 两组锚点各自的匹配率均 ≥ 50% → 正常执行以下正则匹配
- 任一组匹配率 < 50% → **警告用户**「speckit-implement 文件结构变化较大，注入已降级为文件末尾追加，请人工确认位置」，跳过正则匹配，使用第 3.2 节兜底追加文本

读取 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md`。

**改动 A**：用语义正则定位到实现上下文读取步骤（匹配如 `Load and analyze`、`implementation context`、`加载实现上下文` 等模式），在 `constitution.md` 相关的读取行之前插入。

读取 `references/injection-texts.md` 第 2 节获取注入文本。注入内容使用**两步读取**模式：先扫 `lessons-index.md` 判断相关性，命中后才读 `lessons.md` 具体条目。

**改动 B**：用语义正则定位到 "Completion validation" 或最后验证步骤之后、Extension hooks 之前的区域，插入复盘提示步骤。

读取 `references/injection-texts.md` 第 3 节获取注入文本。并将原后续步骤重新编号。

**正则匹配失败时的兜底**：任一改动无法匹配时，使用第 3.2 节兜底追加文本。追加后明确告知用户："/speckit-implement 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit-implement` 字段，记录注入日期和内容摘要，供后续运行（阶段 0）跳过已完成注入。

#### 3.5 验证闭环完整性

确认以下链路连通：

- [ ] `{AGENT_SKILL_DIR}/retro/SKILL.md` 存在
- [ ] `{AGENT_SKILL_DIR}/retro/references/mechanism-auditor.md` 存在
- [ ] `{AGENT_SKILL_DIR}/retro/references/routing-auditor.md` 存在
- [ ] `.specify/memory/lessons.md` 存在
- [ ] `.specify/sdd-workflow.md` 存在且非空（精简 SDD 段引用的完整工作流文档）
- [ ] `{AGENT_FILE}` 顶部有「经验库优先」段（含纠正即捕获指令）
- [ ] `/speckit-plan` 读到 lessons.md
- [ ] `/speckit-implement` 读到 lessons.md + 完成后询问复盘
- [ ] 复盘写入后，下次会话 `{AGENT_FILE}` 强制读 lessons.md → 经验被复用

### 阶段 4：代码质量门禁初始化

> 此阶段仅在选择了 Claude Code 或 Codex 时执行（`{AGENT_SPECIFY}` 有值）。Copilot/Cursor 跳过。

> **设计意图**：在 SDD 工作流中增加代码质量检查环节，确保”写完代码”到”复盘沉淀”之间有一个质量门禁。默认检查 Git 变更文件及有证据的直接影响范围，避免无关存量诊断污染上下文；只有改动风险、影响边界或用户要求触发时才升级至模块级或全量检查。具体范围算法、技术栈命令与结果归因以 `assets/quality-gate-skill.md` 为唯一事实来源。

#### 4.1 安装 /speckit-quality skill ⚡第一波

读取 `assets/quality-gate-skill.md`，将其内容写入 `{AGENT_SKILL_DIR}/speckit-quality/SKILL.md`。

如已有此文件，跳过创建。

确认安装后的文件结构：

```
{AGENT_SKILL_DIR}/speckit-quality/SKILL.md
```

#### 4.2 改造 /speckit-implement（注入代码质量门禁）⚡第三波

> 仅在 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md` 存在时执行（Copilot/Cursor 无 speckit 命令，自动跳过）。

**前置检查**：确认阶段 3.4 的注入状态：
- 如果阶段 3.4 走的是正则匹配成功路径（复盘提示步骤在正确位置）→ 正常执行以下兼容性预检和正则匹配
- 如果阶段 3.4 走的是兜底追加路径（文件末尾有 `<!-- ⚠ 自动追加，请人工确认位置是否正确 -->` 标记）→ 跳过正则匹配，直接在阶段 3.4 的兜底追加块之后追加质量门禁兜底内容，合并两个兜底块为一个整体

**兼容性预检**（仅当 3.4 正则成功时执行）：对照 `references/injection-texts.md` 第 8.2 节中「Completion validation」组锚点匹配目标文件：

- 匹配率 ≥ 50% → 正常执行以下正则匹配
- 匹配率 < 50% → **警告用户**，跳过正则匹配，使用第 4.2 节兜底追加文本

读取 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md`。

用语义正则定位到 “Completion validation” 或最后验证步骤之后、”Retrospective Prompt”/复盘提示步骤之前的区域，插入质量门禁步骤。

读取 `references/injection-texts.md` 第 4 节获取注入文本。并将原后续步骤重新编号。

**正则匹配失败时的兜底**：使用第 4.2 节兜底追加文本。追加后明确告知用户：”/speckit-implement 质量门禁注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。”

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit-implement-quality` 字段，记录注入日期和内容摘要，供后续运行（阶段 0）跳过已完成注入。

#### 4.3 验证质量门禁完整性

确认以下链路连通：

- [ ] `{AGENT_SKILL_DIR}/speckit-quality/SKILL.md` 存在
- [ ] `/speckit-implement` 中存在代码质量门禁步骤（完成验证之后、复盘提示之前）
- [ ] 空参数默认检查 Git 变更文件与有证据的直接影响范围，而不是全量扫描
- [ ] 已暂存、未暂存、未追踪、删除和重命名文件都有明确处理；删除文件不作为 lint 参数
- [ ] 范围规则定义了文件级、模块级、全量升级条件，以及无 Git/无初始提交的降级行为
- [ ] 质量报告区分本次变更、关联存量和无法归因的问题
- [ ] `/speckit-implement` 注入内容只调用 `/speckit-quality`，不重复维护技术栈命令映射

### 阶段 5：Bug 修复工作流初始化

> **设计意图**：Bug Extension（`/speckit.bug.assess → /speckit.bug.fix → /speckit.bug.test`）已在阶段 1.5 随 `specify init` 一同安装。本阶段负责验证安装完整性，并将缺陷修复流程接入本项目已有的经验库、质量门禁和复盘闭环。

> 此步仅在 `{AGENT_SPECIFY}` 有值时执行（Claude Code / Codex）。Copilot/Cursor 跳过。

#### 5.1 验证安装完整性 ⚡第三波

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

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit-bug-assess` 字段。

##### 5.2.2 改造 `/speckit.bug.test`

读取 `{AGENT_SKILL_DIR}/speckit-bug-test/SKILL.md`（或 `speckit.bug.test`）。

**兼容性预检**：对照 `references/injection-texts.md` 第 8.4 节中的锚点列表匹配目标文件：

- 匹配率 ≥ 60%（≥3/5 个锚点命中）→ 正常执行以下正则匹配
- 匹配率 < 60% → **警告用户**「speckit-bug-test 文件结构变化较大（锚点匹配率 {X}/5），注入已降级为文件末尾追加，请人工确认位置」→ 跳过正则匹配，使用第 6.2 节兜底追加文本

用语义正则定位到验证步骤完成后（匹配 `test complete`、`verification done`、`验证完成` 等模式），插入。

读取 `references/injection-texts.md` 第 6 节获取注入文本和兜底追加文本。

**正则匹配失败时**：使用第 6.2 节兜底追加文本，追加后明确告知用户："/speckit.bug.test 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit-bug-test` 字段。

> 注意：`specify extension` 重新安装或升级时可能覆盖注入内容，届时需重新执行注入。`.specify/config.yml` 中的注入记录可用于检测覆盖。

#### 5.3 复杂度升级规则

读取 `references/injection-texts.md` 第 7 节获取复杂度升级条件和建议格式。当满足任一条件时，告知用户需要升级到完整 SDD 规格链路。

### 阶段 6：汇报

按初始化操作顺序，逐一解释每个操作的作用和可选性，让用户理解 SDD 工作流的全貌。

读取 `references/report-template.md` 获取完整汇报模板。按模板中的「动态编号规则」，根据实际执行情况生成编号（跳过未执行的步骤，不留空位）。需要替换的变量：
- `{AGENT_FILE}` / `{AGENT_NAME}` / `{AGENT_SKILL_DIR}` — 来自阶段 1.2
- `{BUG_EXTENSION_INSTALLED}` — 来自阶段 5.1，若为 `false` 则将 `[核心-Bug修复]` 项替换为失败原因和手动重试命令 `specify extension add bug --force`，并移除 `[可选-Bug重试]`
- `[核心-宪章]`：若 1.6 跳过（Copilot/Cursor 或已有宪章），将此项替换为「宪章已存在，跳过自动初始化」

> 以上说明已固化到 `.specify/sdd-workflow.md`（完整工作流指南）与 `{AGENT_FILE}` 的 SDD 精简段落（命令速查 + 指针）中，后续每次会话均可查阅。

## 约束

- 不删除用户已有文件，除非明确同意
- 注入 `{AGENT_FILE}` 用 `<!-- SDD:START -->` / `<!-- SDD:END -->` 标记
- 已有项目先展示变更摘要再执行：即将创建的文件清单（.specify/ 目录结构、{AGENT\_SKILL\_DIR}/speckit-*、{AGENT\_FILE} 注入段）、即将修改的现有文件（{AGENT\_FILE}、{AGENT\_SKILL\_DIR}/speckit-*）。用户确认后再执行
- 不再调用内置 `/init`
- 经验沉淀机制（/retro + lessons.md + speckit 改造）是初始化的一部分，不要跳过
- 代码质量门禁（/speckit-quality + implement 质量检查）是初始化的一部分，不要跳过（仅 Claude Code / Codex 平台）
- Bug 修复工作流（阶段 5）在 Claude Code / Codex 平台默认安装官方 Bug Extension；安装失败时必须报告原因和重试命令，不得静默跳过
- **错误处理原则**：未特别说明的步骤，失败即终止并报告原因，不得静默继续。关键步骤的失败处理已在各阶段中单独标注。本 Skill 采用三级错误处理策略：

| 级别 | 定义 | 处理方式 | 典型场景 |
|------|------|----------|----------|
| **致命** | 核心 SDD 框架安装失败，后续阶段无法执行 | 终止并报告，引导用户检查环境 | `specify init` 失败 |
| **可降级** | 增强组件安装失败，不影响核心 SDD 流程 | 记录失败原因，后续关联步骤跳过，最终汇报中展示 | `specify extension add bug` 失败 |
| **可恢复** | 注入匹配失败，但可走兜底追加路径 | 执行兜底方案，明确告知用户需人工确认位置 | 正则匹配失败时追加到文件末尾 |

> 各阶段步骤的失败级别在其描述中标注（如「失败即终止」= 致命，「失败记录原因，后续跳过」= 可降级，「走兜底追加」= 可恢复）
- **回滚与恢复**：初始化中途失败时，读取 `references/rollback-guide.md` 按失败场景执行对应清理步骤

