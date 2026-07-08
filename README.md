# spec-kit-init 🚀

项目初始化与 SDD 规范一体化工具。替代内置 `/init`，在一次初始化中同时完成：

- **代码库分析** → 生成项目指令文件（CLAUDE.md / AGENTS.md 等）
- **SDD 工作流搭建** → 规格驱动开发（Spec-Driven Development）全流程
- **经验沉淀机制初始化** → 复盘 → 入库 → 自动复用的完整闭环

---

## 概述

`spec-kit-init` 是 Claude Code 的 Skill，专为需要在项目中建立结构化开发规范和工作流的团队设计。

它翻转传统开发流程：**规格是核心产出物，代码是规格的表达**。每个阶段都有对应的 `/speckit-*` 命令，命令内部已有完整指令，无需记忆细节。

## 核心流程

```
/speckit-specify     → 编写功能规格（WHAT）
/speckit-plan        → 制定技术方案（HOW）
/speckit-tasks       → 拆解执行任务
/speckit-implement   → 按任务实现编码（完成后自动提示复盘）
/retro               → 经验复盘沉淀
```

## 前置依赖

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) — Python 包管理器
- Git

## 支持的 AI 编码工具

| 工具 | 指令文件 | Skill 目录 |
|------|----------|------------|
| Claude Code | `CLAUDE.md` | `.claude/skills` |
| Codex | `AGENTS.md` | `.agents/skills` |
| GitHub Copilot | `.github/copilot-instructions.md` | — |
| Cursor | `.cursor/rules/` | — |
| 其他 | 自定义配置 | 自定义 |

## 使用方式

在项目根目录运行 Claude Code，触发 `/init` 时本 Skill 将自动接管，或手动执行与 `/init` 等效的触发词。

### 初始化内容

1. **环境检测** — Python 3.11+、uv、Git 就绪检查
2. **选择 AI 编码工具** — 根据使用的工具确定指令文件路径
3. **执行 `specify init`** — 安装 SDD 工作流框架（`.specify/` + `/speckit-*` 命令）
4. **合并指令文件** — 将 SDD 工作流说明写入 AI 指令文件
5. **经验沉淀机制** — 安装 `/retro` 命令 + `lessons.md` 经验库
6. **代码库分析**（可选）— 分析已有项目写入指令文件
7. **Constitution 初始化**（可选）— 定义项目最高原则

### 经验闭环

```
实现完成 → 复盘提示 → /retro 沉淀 → lessons.md 入库
→ 下次会话强制读 lessons.md → 经验被自动参考
```

## 项目结构

```
├── SKILL.md                              # Skill 定义（主入口）
├── CLAUDE.md                             # 本项目的 AI 指令文件
├── README.md                             # 项目说明文档
├── VERSION.md                            # 当前版本号
├── LICENSE                               # MIT 许可证
├── scripts/
│   └── ensure-specify.sh                 # specify-cli 安装脚本
├── references/
│   └── agent-instructions-template.md    # 指令文件注入模板
└── templates/
    ├── retro-skill.md                    # /retro 复盘 Skill 模板
    └── retro-references/                 # 复盘审查角色 prompt 模板
        ├── mechanism-auditor.md
        └── routing-auditor.md
```

## 许可证

MIT
