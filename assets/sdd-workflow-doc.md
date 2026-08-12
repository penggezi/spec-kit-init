# SDD 工作流指南（完整版）

> 本文件由 spec-kit-init 生成，是 SDD 完整工作流说明。`{AGENT_FILE}` 中的 SDD 段落是本文件的精简摘要（命令速查 + 指针），开始 SDD 任务前请阅读本文件。

本项目使用 [Spec-Kit](https://github.com/github/spec-kit) 实践规格驱动开发（SDD）。规格是核心产出物，代码是规格的表达。

> 注意：本项目使用的 Spec-Kit 安装的命令名为 `/speckit-xxx`（连字符），与官方文档中 `/speckit.xxx`（点号）写法等价，本仓库统一使用连字符形式。通过 `specify --version` 查看当前安装版本。

## 整体流程图

```
constitution → specify → [clarify] → plan → [checklist] → tasks → [analyze] → implement → [quality] → retro
   一次性          ↑────────────────── 每个新功能循环 ──────────────────↓        每次完成后
```

- **方括号** 内的步骤为可选增强，按需使用
- **constitution** 通常只在项目启动或原则变更时执行一次
- **specify → implement** 是每个新功能/迭代的标准循环
- **quality** 在每次实现完成后自动执行代码质量检查：默认检查 Git 变更及有证据的直接影响范围；仅在风险、影响边界或用户要求触发时扩大到模块或全量
- **retro** 在每次实现完成后沉淀经验，避免重复踩坑

## 关键产出路径

```
{AGENT_FILE}              ← AI 指令文件（含 SDD 精简摘要 + 本文件指针）
.specify/memory/          ← 项目原则（constitution.md）+ 实战经验库（lessons.md）
specs/<feature>/          ← 每个功能的规格链（spec.md → plan.md → tasks.md）
.specify/config.yml       ← SDD 配置
```

SDD 命令安装位置：`{AGENT_SKILL_DIR}/speckit-*/`（{AGENT_NAME} 斜杠命令）

## 基础命令（按使用顺序）

### 1. `/speckit-constitution` — 建立项目原则

**作用**：定义项目的基本原则、技术栈约束、不可违反的规则（架构边界、依赖限制、合规要求等）。这些原则会在后续所有阶段被引用，是 SDD 的最高准则。

**何时使用**：项目第一次初始化时；后续只在原则发生变化时才更新。

**产出**：`.specify/memory/constitution.md`

### 2. `/speckit-specify <功能描述>` — 编写功能规格

**作用**：把用户需求转化为结构化的功能规格，只描述 **WHAT**（要做什么）和 **WHY**（为什么），不涉及 **HOW**（怎么实现）。这是 SDD 的核心产出物。

**何时使用**：每开始一个新功能时。

**产出**：`specs/<feature>/spec.md`

### 3. `/speckit-plan <技术方案>` — 生成技术规划

**作用**：基于 spec.md 和 constitution.md，制定具体的技术实现方案——选用哪些组件、模块如何划分、与现有代码如何对接。这是从 WHAT 到 HOW 的转换。

**何时使用**：spec.md 完成且需求明确后。

**产出**：`specs/<feature>/plan.md`

### 4. `/speckit-tasks` — 拆解任务清单

**作用**：把 plan.md 拆解为可独立执行的任务列表，每个任务有明确边界和验收标准，便于按序执行或并行分派。

**何时使用**：plan.md 完成后。

**产出**：`specs/<feature>/tasks.md`

### 5. `/speckit-implement` — 执行实现

**作用**：按 tasks.md 顺序执行编码工作，逐项完成并标记进度。完成后自动执行代码质量门禁：默认只检查 Git 变更文件与有证据的直接影响范围；遇到公共契约、配置/依赖、跨模块或影响边界不明等情况才升级模块或全量检查。通过后主动询问是否进行 `/retro` 复盘。

**何时使用**：tasks.md 准备就绪后。

**产出**：实际代码 + 测试。

### 6. `/speckit-quality` — 代码质量检查

**作用**：自动检测项目技术栈，优先使用项目既有的质量工具与配置。空参数时检查 Git 变更文件及有证据的直接影响范围；可显式指定文件、模块或全量范围。报告会区分本次变更、关联存量和无法归因的问题，评估结果并只修复本次变更的阻塞性问题。

**何时使用**：任何时候需要检查代码质量时，或在 `/speckit-implement` 完成后质量门禁未通过时。

**范围用法**：

```bash
/speckit-quality                    # 默认：Git 变更 + 有证据的直接影响范围
/speckit-quality src/api/order.ts   # 显式检查文件
/speckit-quality module:services    # 显式检查模块
/speckit-quality --all              # 显式全量检查
```

删除文件只参与影响分析，不会直接传给 lint；无 Git 或没有初始提交时，命令会说明降级原因和实际范围。未修改区域的历史问题会单独汇报，不会被误称为本次改动引入。

**产出**：质量检查报告。

### 7. `/retro` — 经验复盘

**作用**：将本次会话中的踩坑、决策、反馈分流到二类长期资产（详见下方「经验沉淀」段）。

**何时使用**：每个 `/speckit-implement` 完成后，或随手做完小修复时。

## 快速开始

```bash
# 1. 建立项目原则（首次或调整原则时执行）
/speckit-constitution 本项目是一个 [项目类型]，遵循 [团队/平台规范]，核心关注 [关键质量属性]...

# 2. 描述要开发的功能
/speckit-specify 用户可以...

# 3. 指定技术方案并生成计划
/speckit-plan 在 service-base 模块新增 XxxFacadeServiceImpl，指标计算复用 IaBoundaryCalculatorFactory...

# 4. 拆解任务并执行
/speckit-tasks
/speckit-implement     # 实现完成后自动执行质量门禁
/speckit-quality       # 也可随时手动检查代码质量
```

## 可选增强命令

| 命令 | 用途 | 推荐时机 |
|------|------|----------|
| `/speckit-clarify` | 结构化提问消除规格歧义 | 在 `/speckit-plan` 之前 |
| `/speckit-analyze` | 跨产物一致性 & 对齐报告 | `/speckit-tasks` 之后、`/speckit-implement` 之前 |
| `/speckit-checklist` | 生成需求完备性、清晰度、一致性检查清单 | `/speckit-plan` 之后 |
| `/speckit-taskstoissues` | 将任务转换为 Issue | 需要外部跟踪时 |

## 按需扩展

```bash
specify extension search          # 浏览可用扩展
specify extension add <name>      # 添加扩展（如代码审查、诊断等）
specify preset search             # 浏览可用预设
specify preset add <name>         # 添加预设（如合规检查、敏捷流程等）
```

## 经验沉淀（Retro）

完成任务后通过 `/retro` 命令进行经验复盘，把会话中产生的踩坑、决策、反馈分流到二类长期资产中：

| 桶 | 写入位置 | 适用内容 |
|---|---|---|
| **A. constitution.md** | `.specify/memory/constitution.md` | 项目原则修订（新增/调整/废除），需标明"待评审" |
| **B. lessons.md** | `.specify/memory/lessons.md` | 实战经验、代码规范/约定、业务知识、调试套路 |

触发方式：
- **自动**：`/speckit-implement` 完成后会主动询问"是否复盘"
- **手动**：任何时候输入 `/retro` 即可立即进入复盘流程（适合做完小需求/小修复后随手沉淀）

复盘流程会先列出预览清单，等用户确认后再写入对应文件。
