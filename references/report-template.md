# 阶段 6 汇报模板

以下模板用于向用户展示初始化完成的汇总信息。模板中的 `{变量}` 来自阶段 1.2 和阶段 5.5 的配置。

> 当 `BUG_EXTENSION_INSTALLED` 为 `false` 时，将第 ⑦ 项替换为失败原因和手动重试命令；第 ⑩ 项替换为具体的失败信息。

---

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

⑥ 代码质量门禁初始化 ── 安装质量检查命令 + 注入 implement 质量门禁
   → 安装 /speckit-quality 命令，随时手动运行质量检查
   → 改造 /speckit-implement → 实现完成后自动执行质量门禁，通过后方提示复盘

⑦ Bug 修复工作流初始化 ── 安装官方 Bug Extension
   → 提供 /speckit.bug.assess → fix → test 三步缺陷修复流程
   → 接入 lessons.md 经验库 + 质量门禁 + 复盘，形成修复闭环

━━━━━━━━━━━━━━━━━━━━━━━━ 可选操作 ━━━━━━━━━━━━━━━━━━━━━━━━━

⑧ 代码库分析（可选）── 分析已有项目结构，写入指令文件
   → 空目录或新项目跳过此步
   → 已有项目执行后可让 AI 在后续会话中了解项目架构

⑨ 初始化 Constitution（可选）── 定义项目的技术栈约束、架构边界、不可违反的规则
   → 通过 /speckit-constitution 随时建立或修改

⑩ Bug Extension 安装失败（需处理）── 请使用以下命令重试：
   → specify extension add bug

━━━━━━━━━━━━━━━━━━━━━━━━ 可用的命令 ━━━━━━━━━━━━━━━━━━━━━━━━━

核心流程（按使用顺序）：
  /speckit-specify     → 编写功能规格（WHAT）
  /speckit-plan        → 制定技术方案（HOW）
  /speckit-tasks       → 拆解执行任务
  /speckit-implement   → 按任务实现编码（完成后执行质量门禁，通过后方提示复盘）
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
  {AGENT_FILE}              ← AI 指令文件（含 SDD 工作流说明）
  .specify/memory/          ← Constitution + 经验库
  {AGENT_SKILL_DIR}/speckit-*/   ← SDD 命令
  {AGENT_SKILL_DIR}/retro/       ← 复盘命令
  {AGENT_SKILL_DIR}/speckit-quality/ ← 质量门禁命令
  .specify/extensions/bug/      ← Bug Extension 命令
  .specify/bugs/                ← 缺陷评估/修复/验证产物

经验闭环：实现完成 → 质量门禁 → 复盘提示 → /retro 沉淀 → lessons.md 入库
           → 下次会话 {AGENT_FILE} 强制读 lessons.md → 经验被自动参考
```

> 以上说明已固化到 `{AGENT_FILE}` 的 SDD 章节中（含流程、命令清单、产出路径、经验沉淀），后续每次会话均可查阅。