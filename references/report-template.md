# 阶段 6 汇报模板

以下模板用于向用户展示初始化完成的汇总信息。模板中的 `{变量}` 来自阶段 1.2 和阶段 5.1 的配置。

> 模板中的标签（如 `[核心-环境检测]`）为描述性标记，**运行时根据实际执行情况动态编号**。跳过的步骤（如空目录不执行代码分析、Bug Extension 未安装等）从列表中移除，不留空位编号。

> 当 `BUG_EXTENSION_INSTALLED` 为 `false` 时，将 `[核心-Bug修复]` 替换为失败原因和手动重试命令。

---

```
本次初始化完成，以下按操作顺序说明每个环节的用途：

━━━━━━━━━━━━━━━━━━━━━━━━ 核心操作（不可跳过） ━━━━━━━━━━━━━━━━━━━━━━━━━

[核心-环境检测] 环境检测 ── 检查 Python 3.11+、uv、Git 是否就绪
   → 这些是后续所有 SDD 命令的运行基础

[核心-选择工具] 选择 AI 编码工具 ── 根据你使用的工具确定指令文件路径和命令格式
   → 决定了后续写入哪个文件（CLAUDE.md / AGENTS.md 等）

[核心-specify] 执行 specify init ── 安装 SDD 工作流框架
   → 创建 .specify/ 配置目录和所有 /speckit-* 斜杠命令
   → 这些命令是 SDD 流程的操作入口

[核心-指令文件] 合并产出指令文件 ── 将 SDD 精简摘要写入 AI 指令文件，完整工作流说明写入 .specify/sdd-workflow.md
   → 每次会话 AI 自动加载精简的 SDD 上下文（命令速查 + 指针），完整流程在开始 SDD 任务时按需读取

[核心-经验沉淀] 经验沉淀机制初始化 ── 建立复盘闭环
   → 安装 /retro 命令 + 创建 lessons.md 经验库
   → 改造 /speckit-plan 和 /speckit-implement → 每次写代码前自动参考经验，写完后自动询问复盘

[核心-质量门禁] 代码质量门禁初始化 ── 安装质量检查命令
   → 安装 /speckit-quality 命令，随时手动运行质量检查

[核心-Bug修复] Bug 修复工作流初始化 ── 安装官方 Bug Extension
   → 提供 /speckit.bug.assess → fix → test 三步缺陷修复流程
   → 接入 lessons.md 经验库 + 质量门禁 + 复盘，形成修复闭环

[核心-宪章] 自动初始化基本宪章 ── 写入项目基本准则
   → 自动生成 .specify/memory/constitution.md，包含项目名、技术栈、核心原则
   → 后续可通过 /speckit-constitution 随时修订

━━━━━━━━━━━━━━━━━━━━━━━━ 可选操作 ━━━━━━━━━━━━━━━━━━━━━━━━━

[可选-代码分析] 代码库分析（可选）── 分析已有项目结构，写入指令文件
   → 空目录或新项目跳过此步
   → 已有项目执行后可让 AI 在后续会话中了解项目架构

[可选-知识库] 外部知识库链接（可选）── 链接本地文档目录供 AI 按需参考
   → 已在 {AGENT_FILE} 注入「外部知识库（按需参考）」段，路径：{KB_PATHS}
   → AI 开始 SDD 任务或涉及相关领域时按需检索，不整体读取

[可选-Bug重试] Bug Extension 安装失败（需处理）── 请使用以下命令重试：
   → specify extension add bug --force

━━━━━━━━━━━━━━━━━━━━━━━━ 可用的命令 ━━━━━━━━━━━━━━━━━━━━━━━━━

核心流程（按使用顺序）：
  /speckit-specify     → 编写功能规格（WHAT）
  /speckit-plan        → 制定技术方案（HOW）
  /speckit-tasks       → 拆解执行任务
  /speckit-implement   → 按任务实现编码（完成后询问复盘）
  /speckit-quality     → 代码质量检查（自动检测技术栈并运行静态分析）
  /retro               → 经验复盘沉淀

缺陷修复流程：
  /speckit.bug.assess  → 评估缺陷、定位根因代码路径
  /speckit.bug.fix     → 实施最小修复
  /speckit.bug.test    → 验证修复并记录测试结果

增强命令（按需使用）：
  /speckit-constitution   → 建立/修订项目原则
  /speckit-clarify        → 结构化提问消除需求歧义
  /speckit-analyze        → 跨产物一致性检查
  /speckit-checklist      → 需求完备性检查
  /speckit-taskstoissues  → 任务转 GitHub Issue

━━━━━━━━━━━━━━━━━━━━━━━━ 关键产出路径 ━━━━━━━━━━━━━━━━━━━━━━━━━
  {AGENT_FILE}              ← AI 指令文件（含 SDD 精简摘要 + 指针）
  .specify/sdd-workflow.md  ← 完整 SDD 工作流指南（SDD 任务时按需读取）
  .specify/memory/          ← Constitution + 经验库
  {AGENT_SKILL_DIR}/speckit-*/   ← SDD 命令
  {AGENT_SKILL_DIR}/retro/       ← 复盘命令
  {AGENT_SKILL_DIR}/speckit-quality/ ← 质量门禁命令
  .specify/extensions/bug/      ← Bug Extension 命令
  .specify/bugs/                ← 缺陷评估/修复/验证产物

经验闭环：实现完成 → 复盘提示 → /retro 沉淀 → lessons.md 入库
           → 下次会话 {AGENT_FILE} 强制读 lessons.md → 经验被自动参考
```

> 以上说明已固化到 `.specify/sdd-workflow.md`（完整工作流指南）与 `{AGENT_FILE}` 的 SDD 精简段落（命令速查 + 指针）中，后续每次会话均可查阅。

## 动态编号规则

阶段 6 执行时，按以下逻辑生成最终编号：

1. 列出 `[核心-*]` 标签中**实际执行**的项目，按顺序赋予 ①、②、③...
2. 列出 `[可选-*]` 标签中**实际执行**的项目（非跳过的），接着核心编号继续赋予
3. **不保留空位**：跳过的标签从列表中完全移除，不显示编号
4. 移除条件：
   - `[可选-代码分析]`：空目录或新项目时移除
   - `[可选-知识库]`：`KB_ENABLED=false` 时移除
   - `[可选-Bug重试]`：`BUG_EXTENSION_INSTALLED=true` 时移除
   - `[核心-Bug修复]`：`BUG_EXTENSION_INSTALLED=false` 时替换为失败原因和重试命令
   - `[核心-宪章]`：Copilot/Cursor 或已有宪章时替换为「宪章已存在，跳过自动初始化」