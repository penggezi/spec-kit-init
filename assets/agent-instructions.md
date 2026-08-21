# 项目指令文件注入模板

以下内容将被注入到项目级的 AI 指令文件中（取决于使用的 agent：Claude Code→CLAUDE.md、Codex→AGENTS.md 等），或写入 `.specify/sdd-workflow.md`。

**所有注入内容必须使用中文。**

**设计意图（渐进式加载）**：`{AGENT_FILE}` 每次会话都会被加载，因此 SDD 段落只保留精简摘要（命令速查表 + 完整文档指针），完整工作流说明写入 `.specify/sdd-workflow.md`，仅在开始 SDD 任务时读取。非 SDD 任务无需加载完整 SDD 文档，节省时间和 token。

---

## 1. 精简 SDD 段落（`<!-- SDD:START/END -->` 标记包裹，注入 `{AGENT_FILE}`）

```markdown
<!-- SDD:START -->
# SDD（规格驱动开发）

本项目使用 [Spec-Kit](https://github.com/github/spec-kit) 实践规格驱动开发（SDD）。**规格是核心产出物，代码是规格的表达**。命令名为 `/speckit-xxx`（连字符），与官方文档中 `/speckit.xxx`（点号）写法等价。

整体流程：constitution → specify → [clarify] → plan → [checklist] → tasks → [analyze] → implement → [quality] → retro（`[ ]` 为可选增强）

基础命令：
- `/speckit-constitution` — 建立/修订项目原则（首次或原则变更时）
- `/speckit-specify` — 编写功能规格（只讲 WHAT/WHY）
- `/speckit-plan` — 制定技术方案（HOW）
- `/speckit-tasks` — 拆解任务清单
- `/speckit-implement` — 执行实现（完成后自动执行质量门禁 + 询问复盘）
- `/speckit-quality` — 代码质量检查（默认检查 Git 变更 + 有证据的直接影响范围）
- `/retro` — 经验复盘沉淀

> **开始 SDD 任务前，先读取 `.specify/sdd-workflow.md`** 获取完整工作流说明（流程图、各命令详细用途与产出路径、可选增强命令、经验沉淀机制）。各 `/speckit-*` 命令的详细指令在其自身 skill 定义中，此处不重复。
<!-- SDD:END -->
```

---

## 2. 经验库优先段落（注入到指令文件顶部，SDD 标记之前）

这部分不在 SDD 标记范围内，应放在指令文件标题行和「项目概述」之间。

```markdown
## 经验库优先（每次会话必读）

在开始任何实质工作（写代码、改配置、规划方案）之前，**MUST** 先读一遍：
- `.specify/memory/constitution.md` — 项目原则（Constitution），不可违反
- `.specify/memory/lessons-index.md` — 极轻量经验索引，扫描是否有与当前任务相关的关键词
  - 有命中 → 读取 `lessons.md` 中对应的具体条目，在响应中显式引用（"参考 lessons.md 中 YYYY-MM-DD 条目..."），让用户知道经验被复用了
  - 无命中 → 告知用户"经验库中暂无本任务相关记录"，继续后续工作

> 两步读取的设计意图：`lessons-index.md` 是极轻量索引（每行一条 `日期 · 关键词 · 简述`），先扫索引判断相关性，命中后才读 `lessons.md` 正文。避免经验积累后每次会话都读取完整的 `lessons.md`，节省上下文。

### 纠正即捕获

当你被用户指出错误或偏好时（"不对"、"应该是 X"、"记住以后用 Y"、"这个做法有问题"），在修正当前问题之后，**主动判断这条纠正是否有复用价值**：

- **有价值**（非显然的坑、版本差异、项目特有的约定、隐蔽的陷阱）→ 按 `/retro` 的轻量捕获流程写入 `lessons.md`。非业务类经验可一句话告知后直接写入，无需等用户确认；业务类经验需先确认再写入。
- **无价值**（纯格式问题、拼写错误、一次性的临时失误）→ 改了就行，不启动复盘流程

这确保每次被纠正都是一次经验资产的积累，而不是同样的错反复犯。
```

---

## 2.5 外部知识库段落（可选，注入 `{AGENT_FILE}`，经验库优先段之后）

仅在初始化阶段 1.2.2 用户选择链接外部知识库时注入。位于「经验库优先」段之后、SDD 标记之前，用 `SPEC-KIT-INIT:KB-REFERENCE` 标记包裹。

**替换规则**：将 `{KB_PATHS}` 替换为通过校验的知识库路径列表，**每个路径一行**（保留原始字符串；Windows 路径建议写正斜杠形式，如 `D:/team-wiki`）。只把占位符换成路径，围栏内其余内容原样注入，**不得引入本段注解文字**。

```markdown
<!-- SPEC-KIT-INIT:KB-REFERENCE:START -->
## 外部知识库（按需参考）

已链接外部知识库：
- `{KB_PATHS}`

开始 SDD 任务或当前任务涉及知识库覆盖的领域时，**按需检索**其中与任务相关的内容，并在方案/实现中显式引用。知识库可能较大，**不要整体读取**，只读取与当前任务相关的文件/条目。
<!-- SPEC-KIT-INIT:KB-REFERENCE:END -->
```

> 设计意图：外部知识库是项目外的本地文档目录，AI 只在任务相关时按需参考，避免每次会话扫描整个目录浪费上下文——与「经验库优先」段的「必读」语义不同，本段是「按需」。

---

## 3. 完整 SDD 工作流文档（写入 `.specify/sdd-workflow.md`）

完整工作流说明不注入 `{AGENT_FILE}`，而是写入项目级的 `.specify/sdd-workflow.md`（与 constitution.md、lessons.md 同目录，平台无关），仅在开始 SDD 任务时按需读取。

- 内容模板见 `assets/sdd-workflow-doc.md`，写入时替换其中的 `{AGENT_FILE}` / `{AGENT_NAME}` / `{AGENT_SKILL_DIR}` 变量
- 若 `.specify/sdd-workflow.md` 已存在且非空 → 跳过写入，不覆盖（幂等）
- 迁移场景：旧版初始化已把完整 SDD 段注入 `{AGENT_FILE}` 的项目，由阶段 0.5 自动抽取到 `.specify/sdd-workflow.md` 并替换为精简段

> 注入逻辑见 spec-kit-init SKILL.md 阶段 2「合并产出指令文件」与阶段 0.5「迁移旧式完整 SDD 段」，以 SKILL.md 中的规则为准。
