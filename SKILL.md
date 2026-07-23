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
| 获取指令文件注入模板 | `references/agent-instructions-template.md` |
| 获取注入文本和兜底追加文本 | `references/injection-texts.md` |
| 获取经验文件骨架模板 | `references/lessons-templates.md` |
| 获取初始化失败回滚步骤 | `references/rollback-guide.md` |
| 获取 /retro skill 模板 | `templates/retro-skill.md` |
| 获取 /speckit-quality skill 模板 | `templates/quality-gate-skill.md` |
| 获取阶段 6 汇报模板 | `references/report-template.md` |

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

#### 0.2 判断逻辑

| 检查结果 | 处理方式 |
|----------|----------|
| 全部不存在 | 全新项目，完整执行阶段 1-6 |
| 部分存在（如只有 `.specify/` 但无 retro） | 告知用户当前状态，列出已完成和缺失的组件，询问：「检测到项目已部分初始化，是否仅补齐缺失组件？」 |
| 全部存在 | 告知用户项目已完成初始化，询问：「项目已完成初始化。是否强制重新初始化？（这会覆盖已有配置）」 |

#### 0.3 用户选择"补齐缺失组件"

根据检查结果，跳过已完成的阶段，仅执行缺失的步骤。例如：
- 已有 `.specify/` 和 speckit-* 命令 → 跳过阶段 1.4
- 缺少 retro skill → 仅执行阶段 3.2
- 缺少 quality gate → 仅执行阶段 4

#### 0.4 用户选择"强制重新初始化"

先展示将被覆盖/修改的文件清单，用户确认后完整执行阶段 1-6。

### 阶段 1：分析 + 初始化

#### 1.1 环境检测

确认核心依赖就绪：

- Python 3.11+（`python3 --version`）
- Git（`git --version`）
- [uv](https://docs.astral.sh/uv/)（`uv --version`，如未安装引导用户安装）

> `specify-cli` 的检测和安装推迟到 1.4 步，仅在选择了 Claude Code 或 Codex 时执行。

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

> 此步仅在选择了 Claude Code 或 Codex 时执行（`{AGENT_SPECIFY}` 为 `claude` 或 `codex`）。Copilot/Cursor 跳过。

**开始前告知用户**：正在安装 specify-cli 并初始化 SDD 工作流，约需 1-2 分钟，请稍候。

检测并安装 `specify-cli`：

```bash
bash scripts/ensure-specify.sh
```

`ensure-specify.sh` 会自动检测 `uv` 和 `specify`，未安装时自动安装。失败时根据提示处理。

安装成功后执行 `specify init`。由于 `--force` 不跳过内部交互式选择，在非交互式终端中须通过管道发送空行避免阻塞：

```bash
echo "" | PYTHONIOENCODING=utf-8 specify init --here --integration {AGENT_SPECIFY} --force --ignore-agent-tools
```

> `PYTHONIOENCODING=utf-8` 防止 Windows 上的 unicode 编码问题。

如 `--ignore-agent-tools` 不被当前版本识别，去掉该参数再试：

```bash
echo "" | PYTHONIOENCODING=utf-8 specify init --here --integration {AGENT_SPECIFY} --force
```

如已有 `.specify/` 目录，先询问用户是否覆盖。如果用户拒绝覆盖，跳过本步并告知用户 SDD 工作流结构已存在，后续注入将继续。
如所有尝试均失败，输出完整错误信息并终止，提示用户检查网络和 GitHub 访问。

这会创建完整的 SDD 工作流结构：

- `.specify/` — 配置和模板
- `{AGENT_SKILL_DIR}/speckit-*/` — 所有 `/speckit-*` 斜杠命令

*speckit-git-* 清理\*：`specify init` 可能仍会生成 `speckit-git-*` 相关 skill（git commit/tag/rebase 等工作流扩展），这些命令不在本 Skill 核心流程范围内，执行清理：

```bash
rm -rf {AGENT_SKILL_DIR}/speckit-git-*
```

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

#### 1.6 确认执行

在进入实际执行前，给出一句简洁的确认：

```
即将开始初始化 SDD 工作流，包括：
- 安装 SDD 命令框架（/speckit-*）
- 配置经验沉淀机制（/retro + lessons.md）
- 安装代码质量门禁（/speckit-quality）
- 安装 Bug 修复工作流

确认继续？(y/n)
```

如项目已有 `{AGENT_FILE}` 且会被修改，额外提示「将修改已有的 {AGENT_FILE}，原内容保留不变」。详细信息在初始化完成后（阶段 6）展示。

### 阶段 2：合并产出指令文件

读取 `references/agent-instructions-template.md` 获取注入模板。目标文件为阶段 1.2 选定的 `{AGENT_FILE}`。

合并规则：

- 有 `<!-- SDD:START -->` 标记 → 只替换标记间内容，保留其余
- 无标记，有文件 → 末尾追加标记包裹的 SDD 段落
- 无文件 → 新建（代码库文档 + 经验库优先段 + SDD 段）

关键点：

- **必须在** **`{AGENT_FILE}`** **顶部注入「经验库优先」段**：在 `{AGENT_TITLE}` 标题行之后、第一个 `##` 节之前，插入模板第 2 节内容
- SDD 段落使用模板第 1 节内容
- 确保 SDD 段中包含 `/retro` 行和「经验沉淀（Retro）」章节

### 阶段 3：经验沉淀机制初始化

这是本 skill 相比标准 `specify init` 的增强部分——在 SDD 工作流的基础上，建立从"写完代码"到"经验被复用"的完整闭环。

#### 3.1 创建经验文件骨架

> **设计意图**：放在 `.specify/memory/` 下，与 `constitution.md` 同目录，确保 speckit 生态内所有经验资产集中管理，便于 `/speckit-plan` 和 `/speckit-implement` 统一读取。

读取 `references/lessons-templates.md`，按其中的模板创建：
- `.specify/memory/lessons.md` — 经验正文（最新在上）
- `.specify/memory/lessons.idx` — 轻量去重索引（与正文物理隔离，append-only 写入）

#### 3.2 安装 /retro skill

> 如果 `{AGENT_SKILL_DIR}` 不可用或为 undefined（如自定义模式未指定），默认使用 `.claude/skills` 作为回退目录。

读取 `templates/retro-skill.md`，将其内容写入 `{AGENT_SKILL_DIR}/retro/SKILL.md`。

如已有此文件，跳过创建。

#### 3.2.1 安装 /retro 子代理审查模板

> retro skill 的对抗审查依赖两个独立的审查角色 prompt 模板。这些文件需要和 SKILL.md 一起部署到 retro skill 目录下。

将 `templates/retro-references/` 整个目录复制到 `{AGENT_SKILL_DIR}/retro/references/`：

```bash
cp -r templates/retro-references/ {AGENT_SKILL_DIR}/retro/references/
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

#### 3.3 改造 /speckit-plan（注入 lessons.md 必读）

> **设计意图**：经验按"稳定性"分层——constitution 管最高原则（不可违反）、lessons 管实战经验（灵活积累），避免同级混放导致后续查找困难。

> 仅在 `{AGENT_SKILL_DIR}/speckit-plan/SKILL.md` 存在时执行（Copilot/Cursor 无 speckit 命令，自动跳过）。

读取 `{AGENT_SKILL_DIR}/speckit-plan/SKILL.md`。

用语义正则定位到 "Load context" 相关步骤（匹配 `Load context`、`加载上下文` 或类似小节标题），在该步骤的读取列表中 `constitution.md` 之后追加一行。

读取 `references/injection-texts.md` 第 1 节，获取注入文本和兜底追加文本。

**正则匹配失败时**：使用第 1.2 节兜底追加文本，追加后明确告知用户："/speckit-plan 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit-plan` 字段，记录注入日期和内容摘要，供后续运行（阶段 0）跳过已完成注入。

#### 3.4 改造 /speckit-implement（注入 lessons.md 必读 + 复盘询问）

> **设计意图**：在记忆最新鲜时捕捉经验——完成瞬间是复盘的最佳时机，而非事后再回忆。自动提示确保"做完一件事"和"留下经验"不会脱钩。

> 仅在 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md` 存在时执行（Copilot/Cursor 无 speckit 命令，自动跳过）。

读取 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md`。

**改动 A**：用语义正则定位到实现上下文读取步骤（匹配如 `Load and analyze`、`implementation context`、`加载实现上下文` 等模式），在 `constitution.md` 相关的读取行之前插入。

读取 `references/injection-texts.md` 第 2 节获取注入文本。

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
- [ ] `{AGENT_FILE}` 顶部有「经验库优先」段（含纠正即捕获指令）
- [ ] `/speckit-plan` 读到 lessons.md
- [ ] `/speckit-implement` 读到 lessons.md + 完成后询问复盘
- [ ] 复盘写入后，下次会话 `{AGENT_FILE}` 强制读 lessons.md → 经验被复用

### 阶段 4：代码质量门禁初始化

> 此阶段仅在选择了 Claude Code 或 Codex 时执行（`{AGENT_SPECIFY}` 有值）。Copilot/Cursor 跳过。

> **设计意图**：在 SDD 工作流中增加代码质量检查环节，确保“写完代码”到“复盘沉淀”之间有一个质量门禁。默认检查 Git 变更文件及有证据的直接影响范围，避免无关存量诊断污染上下文；只有改动风险、影响边界或用户要求触发时才升级至模块级或全量检查。具体范围算法、技术栈命令与结果归因以 `templates/quality-gate-skill.md` 为唯一事实来源。

#### 4.1 安装 /speckit-quality skill

读取 `templates/quality-gate-skill.md`，将其内容写入 `{AGENT_SKILL_DIR}/speckit-quality/SKILL.md`。

如已有此文件，跳过创建。

确认安装后的文件结构：

```
{AGENT_SKILL_DIR}/speckit-quality/SKILL.md
```

#### 4.2 改造 /speckit-implement（注入代码质量门禁）

> 仅在 `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md` 存在时执行（Copilot/Cursor 无 speckit 命令，自动跳过）。

**前置检查**：确认阶段 3.4 的注入状态：
- 如果阶段 3.4 走的是正则匹配成功路径（复盘提示步骤在正确位置）→ 正常执行 4.2 正则匹配，定位到复盘提示之前
- 如果阶段 3.4 走的是兜底追加路径（文件末尾有 `<!-- ⚠ 自动追加，请人工确认位置是否正确 -->` 标记）→ 跳过正则匹配，直接在阶段 3.4 的兜底追加块之后追加质量门禁兜底内容，合并两个兜底块为一个整体

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

> **设计意图**：官方 Spec-Kit 提供 Bug Extension（`/speckit.bug.assess → /speckit.bug.fix → /speckit.bug.test`），为缺陷提供独立的评估、修复、验证流程。本阶段默认安装它，并接入本项目已有的经验库、质量门禁和复盘闭环。

> 此步仅在 `{AGENT_SPECIFY}` 有值时执行（Claude Code / Codex）。Copilot/Cursor 跳过。

#### 5.1 安装官方 Bug Extension

在完成阶段 4 后直接安装。开始前告知用户：正在安装官方 Spec-Kit Bug Extension，随后可使用三步缺陷修复流程（assess → fix → test）。

```bash
specify extension add bug
```

> Bug Extension 已随 `specify-cli` 打包，无需添加社区 catalog 或从网络下载。

> Bug Extension 的安装路径为 `.specify/extensions/bug/`，命令注册为 `/speckit.bug.assess`、`/speckit.bug.fix`、`/speckit.bug.test`。产物写入 `.specify/bugs/<slug>/` 目录。

如已安装，跳过安装步骤。

#### 5.2 验证安装完整性

确认以下命令可用：

- [ ] `/speckit.bug.assess` — 评估缺陷、定位根因路径、输出 assessment.md
- [ ] `/speckit.bug.fix` — 实施最小修复、输出 fix.md
- [ ] `/speckit.bug.test` — 验证修复并记录测试结果、输出 test.md

确认产物目录：

- [ ] `.specify/extensions/bug/` 存在
- [ ] `.specify/bugs/` 目录可写入

验证通过后，设置 `BUG_EXTENSION_INSTALLED=true`；若安装或验证失败，设置 `BUG_EXTENSION_INSTALLED=false` 并记录失败原因。

#### 5.3 注入增强：连接经验库 + 质量门禁 + 复盘

Bug Extension 的三步流程本身已完整，在此之上接入本项目已有的增强机制。

**前置检查**：读取阶段 5.2 设置的 `BUG_EXTENSION_INSTALLED` 变量：
- 若为 `false` → 跳过注入，告知用户"Bug Extension 未安装成功，注入已跳过。请先手动执行 `specify extension add bug`，然后重新运行本 Skill 的注入阶段。"
- 若为 `true` → 正常执行以下注入。

##### 5.3.1 改造 `/speckit.bug.assess`

读取 `{AGENT_SKILL_DIR}/speckit-bug-assess/SKILL.md`（或 `speckit.bug.assess`，取决于实际安装路径）。

用语义正则定位到评估步骤开始前（匹配 `Assess`、`评估`、`analyze the bug` 等模式），在上下文读取步骤中插入。

读取 `references/injection-texts.md` 第 5 节获取注入文本和兜底追加文本。

**正则匹配失败时**：使用第 5.2 节兜底追加文本，追加后明确告知用户："/speckit.bug.assess 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit-bug-assess` 字段。

##### 5.3.2 改造 `/speckit.bug.test`

读取 `{AGENT_SKILL_DIR}/speckit-bug-test/SKILL.md`（或 `speckit.bug.test`）。

用语义正则定位到验证步骤完成后（匹配 `test complete`、`verification done`、`验证完成` 等模式），插入。

读取 `references/injection-texts.md` 第 6 节获取注入文本和兜底追加文本。

**正则匹配失败时**：使用第 6.2 节兜底追加文本，追加后明确告知用户："/speckit.bug.test 自动注入未完全成功（模板结构已变化），已在文件末尾追加插桩，请人工确认并调整位置。"

**注入成功后**，在 `.specify/config.yml` 中追加或更新 `spec_kit_init.injections.speckit-bug-test` 字段。

> 注意：`specify extension` 重新安装或升级时可能覆盖注入内容，届时需重新执行注入。`.specify/config.yml` 中的注入记录可用于检测覆盖。

#### 5.4 复杂度升级规则

读取 `references/injection-texts.md` 第 7 节获取复杂度升级条件和建议格式。当满足任一条件时，告知用户需要升级到完整 SDD 规格链路。

### 阶段 6：汇报

按初始化操作顺序，逐一解释每个操作的作用和可选性，让用户理解 SDD 工作流的全貌。

读取 `references/report-template.md` 获取完整汇报模板，按模板格式输出。需要替换的变量：
- `{AGENT_FILE}` / `{AGENT_NAME}` / `{AGENT_SKILL_DIR}` — 来自阶段 1.2
- `{BUG_EXTENSION_INSTALLED}` — 来自阶段 5.2，若为 `false` 则替换第 ⑦ 项为失败原因和手动重试命令 `specify extension add bug`

> 以上说明已固化到 `{AGENT_FILE}` 的 SDD 章节中（含流程、命令清单、产出路径、经验沉淀），后续每次会话均可查阅。

## 约束

- 不删除用户已有文件，除非明确同意
- 注入 `{AGENT_FILE}` 用 `<!-- SDD:START -->` / `<!-- SDD:END -->` 标记
- 已有项目先展示变更摘要再执行：即将创建的文件清单（.specify/ 目录结构、{AGENT\_SKILL\_DIR}/speckit-*、{AGENT\_FILE} 注入段）、即将修改的现有文件（{AGENT\_FILE}、{AGENT\_SKILL\_DIR}/speckit-*）。用户确认后再执行
- 不再调用内置 `/init`
- 经验沉淀机制（/retro + lessons.md + speckit 改造）是初始化的一部分，不要跳过
- 代码质量门禁（/speckit-quality + implement 质量检查）是初始化的一部分，不要跳过（仅 Claude Code / Codex 平台）
- Bug 修复工作流（阶段 5）在 Claude Code / Codex 平台默认安装官方 Bug Extension；安装失败时必须报告原因和重试命令，不得静默跳过
- **错误处理原则**：未特别说明的步骤，失败即终止并报告原因，不得静默继续。关键步骤的失败处理已在各阶段中单独标注
- **回滚与恢复**：初始化中途失败时，读取 `references/rollback-guide.md` 按失败场景执行对应清理步骤

