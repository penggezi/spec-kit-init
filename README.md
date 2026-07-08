# spec-kit-init 🚀

项目初始化与 SDD 规范一体化工具——Claude Code Skill，替代内置 `/init` 命令，在一次初始化中同时完成三件事：

- **代码库分析** → 生成项目指令文件（CLAUDE.md / AGENTS.md 等）
- **SDD 工作流搭建** → 规格驱动开发（Spec-Driven Development）全流程
- **经验沉淀机制初始化** → 复盘 → 入库 → 自动复用的完整闭环

---

## 设计理念

### SDD（规格驱动开发）

翻转传统开发流程：**规格是核心产出物，代码是规格的表达**。每个阶段都有对应的 `/speckit-*` 命令，命令内部已有完整指令，无需记忆细节。

关键原则：
- **先规格后代码**：新功能必须先写 spec.md，再写代码
- **只说做什么**：spec.md 只描述 WHAT 和 WHY，不涉及 HOW
- **规格驱动实现**：plan → tasks → implement 都从 spec 推导，不能跳步
- **宪章最高**：constitution.md 中的原则不可违反

### 经验库优先

本项目在标准 SDD 工作流之上叠加了**经验沉淀与自动复用机制**，解决"踩过的坑反复踩"的问题：

```
实现完成 → 复盘提示 → /retro 沉淀 → lessons.md 入库
→ 下次会话 AI 强制读 lessons.md → 经验被自动参考
```

每次 `/speckit-implement` 完成后，AI 会主动询问是否复盘；用户指出 AI 错误时也会自动触发纠正捕获。经验通过 **5 层质量门禁 + 双角色对抗审查 + 去重** 后方可入库，确保 `lessons.md` 中每一条都值得下次会话阅读。

---

## 前置依赖

| 依赖 | 最低版本 | 用途 |
|------|----------|------|
| Python | 3.11+ | specify-cli 运行环境 |
| [uv](https://docs.astral.sh/uv/) | — | Python 包管理，安装 specify-cli |
| Git | — | 版本控制，specify-cli 通过 Git 安装 |

---

## 支持的 AI 编码工具

| 工具 | 指令文件 | Skill 目录 | SDD 命令 | 复盘机制 |
|------|----------|------------|----------|----------|
| **Claude Code** | `CLAUDE.md` | `.claude/skills` | ✅ 完整支持 | ✅ 完整支持 |
| **Codex** | `AGENTS.md` | `.agents/skills` | ✅ 完整支持 | ✅ 完整支持 |
| **GitHub Copilot** | `.github/copilot-instructions.md` | `.claude/skills` ¹ | ❌ 不支持 | ✅ 仅经验沉淀 |
| **Cursor** | `.cursor/rules/` | `.claude/skills` ¹ | ❌ 不支持 | ✅ 仅经验沉淀 |
| **其他（自定义）** | 逐一配置 | 逐一配置 | 按配置决定 | 按配置决定 |

> ¹ Copilot/Cursor 自身无标准 skill 系统，使用 `.claude/skills` 仅用于统一安装 retro skill。spec-kit 系列命令在这些平台上不可用，但 lessons.md 经验沉淀机制不受影响——它是纯 Markdown 文件，与平台无关。

---

## 项目结构

```
spec-kit-init/
├── SKILL.md                                   # ★ 主入口 — 全部逻辑的载体
├── CLAUDE.md                                  # 本项目 AI 指令文件
├── README.md                                  # 项目说明（即本文件）
├── VERSION.md                                 # 当前版本号
├── LICENSE                                    # MIT 许可证
│
├── scripts/
│   └── ensure-specify.sh                      # specify-cli 检测与安装脚本
│                                              #   · uv 环境检测
│                                              #   · specify 安装（含 3 次重试 + 超时保护）
│                                              #   · 跨平台颜色兼容
│
├── references/
│   └── agent-instructions-template.md         # 指令文件注入模板
│                                              #   第 1 节: SDD 段落（<!-- SDD:START/END -->）
│                                              #   第 2 节: 经验库优先段落（注入文件顶部）
│
└── templates/
    ├── retro-skill.md                         # /retro 复盘 Skill 完整定义
    │                                          #   · 3 种模式（标准/纠正捕获/焦点）
    │                                          #   · 5 层质量门禁
    │                                          #   · 参考源勘误驱动（非会话回顾）
    │                                          #   · lessons.idx 轻量去重索引
    │
    └── retro-references/                      # 复盘审查角色 prompt 模板
        ├── mechanism-auditor.md               # 机制审计员 — 审查经验是否揭示根因
        └── routing-auditor.md                 # 路由审核员 — 宪法级 vs 经验级分流
```

### 各文件职责详解

| 文件 | 角色 | 被读取时机 |
|------|------|-----------|
| `SKILL.md` | **主入口**，定义 4 个初始化阶段的完整流程 | 每次会话必读 |
| `scripts/ensure-specify.sh` | 在阶段 1.4 被调用，安装 specify-cli | 仅在 Claude Code / Codex 平台执行 |
| `references/agent-instructions-template.md` | 提供两个注入段落模板 | 阶段 2 按需读取 |
| `templates/retro-skill.md` | /retro 命令的完整定义，写入目标项目 | 阶段 3.2 按需读取 |
| `templates/retro-references/mechanism-auditor.md` | 对抗审查角色 1 的审查标准 | /retro 执行时由子代理读取 |
| `templates/retro-references/routing-auditor.md` | 对抗审查角色 2 的路由标准 | /retro 执行时由子代理读取 |

---

## 执行流程

初始化按 4 个阶段依次执行：

### 阶段 1：分析 + 初始化

```
1.1 环境检测 ──→ Python 3.11+ / uv / Git
1.2 选择 AI 编码工具 ──→ 确定 AGENT_FILE / AGENT_SKILL_DIR / AGENT_SPECIFY 等
1.3 代码库分析 ──→ 已有项目时分析架构/技术栈/构建命令（空目录跳过）
1.4 specify init ──→ 安装 SDD 工作流框架（仅 Claude Code / Codex）
     ├── 调用 ensure-specify.sh 安装 specify-cli
     ├── echo "" | specify init --here --integration <agent> --force --ignore-agent-tools
     └── 清理 speckit-git-* 无关 skill
1.5 Constitution 初始化 ──→ 可选，询问用户是否建立项目原则
```

### 阶段 2：合并产出指令文件

将 SDD 段落和「经验库优先」段注入目标项目的 AI 指令文件（`{AGENT_FILE}`）：

- **经验库优先段**：注入到标题行之后、第一个 `##` 节之前，确保 AI 每次会话先读经验库
- **SDD 段落**：用 `<!-- SDD:START -->` / `<!-- SDD:END -->` 标记包裹，包含完整的工作流说明
- 智能合并：已有标记 → 替换内容；无标记 → 末尾追加；无文件 → 新建

### 阶段 3：经验沉淀机制初始化

这是本 skill 相比标准 `specify init` 的核心增强：

```
3.1 创建经验文件骨架
     ├── .specify/memory/lessons.md  → 经验正文（最新在上）
     └── .specify/memory/lessons.idx → 轻量去重索引（与正文物理隔离）

3.2 安装 /retro skill
     ├── templates/retro-skill.md → {AGENT_SKILL_DIR}/retro/SKILL.md
     └── templates/retro-references/ → {AGENT_SKILL_DIR}/retro/references/

3.3 改造 /speckit-plan ──→ 注入 "MUST read lessons.md"

3.4 改造 /speckit-implement ──→ 注入 "REQUIRED read lessons.md" + 复盘询问

3.5 验证闭环完整性 ──→ 逐项确认所有文件存在、注入到位
```

### 阶段 4：汇报

按初始化操作顺序，逐一解释每个环节的用途（核心操作 vs 可选操作），展示可用命令清单和关键产出路径。汇报内容已固化到 `{AGENT_FILE}` 的 SDD 章节中，后续每次会话均可查阅。

---

## 关键设计决策

### 渐进式加载

SKILL.md 本身包含全部流程描述，`references/` 和 `templates/` 下的文件**按需读取**，仅在执行对应阶段时才加载，避免提前占用上下文。SKILL.md 中的表格明确标注了每个文件在何种场景下读取。

### 非交互式终端兼容

`specify init` 在 CI/agent 等非交互式终端中会永久阻塞（内部有交互式选择步骤）。解决方案：通过 `echo "" |` 管道发送空行，让交互式步骤使用默认选项。详见记忆 → [[specify-init-noninteractive-block]]。

### 回滚与恢复

每个阶段都明确了失败时的清理方式（见 SKILL.md 末尾「约束」章节），支持部分回滚：

| 失败场景 | 回滚方式 |
|----------|----------|
| `specify init` 失败 | 无文件变更，无需回滚 |
| `specify init` 成功但后续失败 | `.specify/` 保留；`{AGENT_FILE}` 中手动删除 `<!-- SDD:...-->` 段 |
| 阶段 3 部分失败 | 在 speckit-plan/implement 文件中删除 `<!-- ⚠ 自动追加...-->` 标记处的内容 |

### 物理隔离的轻量去重索引

传统做法是将去重信息嵌入 `lessons.md` 正文（如 frontmatter 中的 hash），但这会导致去重扫描成本随经验积累线性膨胀。本项目的方案是将索引与正文**物理隔离**——`lessons.idx` 只存一行摘要（`YYYY-MM-DD · 根因关键词 · 简述`），复盘时先读索引做关键词比对，命中后才读正文做精确比对。确保 O(n) 扫描成本恒定。

### 参考源勘误驱动的经验挖掘

与传统的"回顾会话记录"不同，本项目的复盘机制以**"本次工作参考了什么"**为线索——每条经验本质上是对某个参考文档/代码的"它没说清楚"或"它说错了"的记录。通过逐参考源回答 4 个问题（准确吗/完整吗/适用吗/费解吗），系统化地从参考源和实际行为之间的差距中挖掘经验。

---

## 经验闭环详解

### 5 层质量门禁

每条候选经验必须依次通过 5 关，**任何一关不过即丢弃**：

| 关卡 | 问题 | 丢弃什么 |
|------|------|----------|
| ① 可复用性 | 这条勘误/补充在未来类似场景中有用吗？ | 一次性场景 |
| ② 非平凡性 | 是需要实际踩坑才能发现的，还是显而易见的？ | 一眼能看出的笔误 |
| ③ 类型适配 | 能明确归到哪个分类？ | 说不清的模糊观察 |
| ④ 可验证性 | 参考源与实际的差距是否被实际验证过？ | 未证实的主观判断 |
| ⑤ 显著性阈值 | 这条经验丢了，下次会话会踩同样的坑吗？ | 丢了也无所谓的 |

### 双角色对抗审查

通过门禁后，每条经验经过两个独立角色审查：

| 角色 | 职责 | 判断标准 |
|------|------|----------|
| **机制审计员** | 经验是否揭示了根因机制（而非仅描述症状） | 读者能否举一反三？是否有因果链条？ |
| **路由审核员** | 经验应该进 constitution.md 还是 lessons.md | 违反后"破坏架构"→ 宪章；"多花时间"→ 经验库 |

两个角色都通过才放行。在 Claude Code 环境中通过独立子代理执行，确保判断独立性。

### 三种复盘模式

| 模式 | 触发方式 | 适用场景 |
|------|----------|----------|
| **标准复盘** | `/retro`（空参数） | `/speckit-implement` 完成后自动询问 |
| **纠正捕获** | `/retro capture` | 用户指出 AI 错误时自动触发 |
| **焦点复盘** | `/retro <范围描述>` | 针对特定 bug 或问题做定向复盘 |

---

## 可用命令速览

### 核心流程（按使用顺序）

| 命令 | 作用 | 产出 |
|------|------|------|
| `/speckit-constitution` | 建立/修订项目最高原则 | `.specify/memory/constitution.md` |
| `/speckit-specify` | 编写功能规格（WHAT + WHY） | `specs/<feature>/spec.md` |
| `/speckit-plan` | 制定技术方案（HOW） | `specs/<feature>/plan.md` |
| `/speckit-tasks` | 拆解可执行任务 | `specs/<feature>/tasks.md` |
| `/speckit-implement` | 按任务编码实现 | 实际代码 + 测试 |
| `/retro` | 经验复盘沉淀 | `lessons.md` / `constitution.md` 更新 |

### 增强命令（按需使用）

| 命令 | 用途 | 推荐时机 |
|------|------|----------|
| `/speckit-clarify` | 结构化提问消除规格歧义 | specify 之后、plan 之前 |
| `/speckit-analyze` | 跨产物一致性检查 | tasks 之后、implement 之前 |
| `/speckit-checklist` | 需求完备性检查清单 | plan 之后 |
| `/speckit-taskstoissues` | 任务转 GitHub Issue | 需要外部跟踪时 |

---

## 使用方式

在项目根目录打开 Claude Code，通过以下任一方式触发：

- 输入 `/init`（本 Skill 自动接管）
- 提到"初始化项目"、"初始化 SDD 规范"、"用 spec-kit 初始化"
- 在新项目或空目录中开始工作时的自然语言请求

Skill 触发后，按 4 个阶段依次执行，中间会在关键决策点（AI 工具选择、Constitution 初始化）与用户交互确认。

---

## 版本

当前版本见 [VERSION.md](VERSION.md)（本文件不重复维护版本号，避免每次发布都要同步两处）

---

## 许可证

[MIT](LICENSE)
