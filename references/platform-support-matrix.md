# 平台支持矩阵与组件依赖

## 一、平台支持矩阵

各 AI 编码工具对本 Skill 的功能支持程度：

| 功能 | Claude Code | Codex | GitHub Copilot | Cursor |
|------|-------------|-------|----------------|--------|
| **SDD 工作流**（`/speckit-*` 命令） | ✅ 完整 | ✅ 完整 | ❌ 不支持 | ❌ 不支持 |
| **Bug 修复工作流**（`/speckit.bug.*`） | ✅ 完整 | ✅ 完整 | ❌ 不支持 | ❌ 不支持 |
| **代码质量门禁**（`/speckit-quality`） | ✅ 完整 | ✅ 完整 | ❌ 不支持 | ❌ 不支持 |
| **经验沉淀机制**（`/retro` + `lessons.md`） | ✅ 完整 | ✅ 完整 | ⚠️ 部分¹ | ⚠️ 部分¹ |
| **Constitution 管理** | ✅ 完整 | ✅ 完整 | ❌ 不支持 | ❌ 不支持 |

> ¹ Copilot/Cursor 不支持 `/retro` skill 的斜杠命令调用。经验沉淀机制在这些平台上**只保留「经验文件读取 + 纠正即捕获 + 自然语言复盘」能力**：`lessons.md` 是纯 Markdown 文件，与平台无关；指令注入段中涉及「调用 /retro」的表述替换为「按项目指令文件中的复盘流程执行」。不应宣称 `/retro` 或 `/speckit-*` 命令在这些平台可调用。

**skill 安装目录**：Copilot/Cursor 自身无标准 skill 系统。安装时 retro skill 写入 `.claude/skills/retro/` 作为统一回退目录。

**Cursor 指令文件**：`AGENT_FILE` 为具体文件 `.cursor/rules/spec-kit-init.mdc`（带 frontmatter：`description` + `alwaysApply: true`），而非 `.cursor/rules/` 目录。写入时不修改用户已有其他规则文件；项目只有旧版 `.cursorrules` 时新建 `.mdc`，不覆盖旧文件。

---

## 二、组件依赖矩阵

用于阶段 0「补齐缺失组件」时判断步骤间的执行顺序。`→` 表示"依赖"。

### 文件级依赖

```
lessons.md + lessons-index.md (3.1)           ← 独立，无依赖
retro skill (3.2 + 3.2.1)               ← 独立，无依赖
speckit-quality skill (4.1)             ← 独立，无依赖
```

### 注入级依赖

```
speckit-plan 注入 (3.3)                 ← 依赖：speckit-plan SKILL.md 存在
speckit-implement 经验注入 (3.4)        ← 依赖：speckit-implement SKILL.md 存在
speckit-implement 质量门禁注入 (4.2)    ← 依赖：3.4 注入状态已知 + speckit-implement SKILL.md 存在
                                         → 4.2 需要知道 3.4 走的是正则匹配还是兜底追加路径
Bug Extension 验证 (5.1)               ← 依赖：1.5 specify extension add bug 执行结果
Bug Extension 注入 (5.2)               ← 依赖：5.1 BUG_EXTENSION_INSTALLED=true
```

### 验证级依赖

```
经验闭环验证 (3.5)                       ← 依赖：3.1-3.4 完成
质量门禁验证 (4.3)                       ← 依赖：4.1-4.2 完成
```

---

## 三、补齐场景决策表

| 缺失组件 | 需执行的步骤 | 前置条件检查 |
|----------|-------------|-------------|
| 无 `.specify/` | 执行阶段 1.5 → 1.6 → 2 | 无 |
| 无 `.specify/sdd-workflow.md`（完整 SDD 文档缺失） | 执行阶段 2 的写入步骤（读取 `{SKILL_ROOT}/assets/sdd-workflow-doc.md` 写入） | `{AGENT_FILE}` 存在或即将创建 |
| 无 retro skill | 执行 3.2 + 3.2.1 | 无 |
| 无 speckit-quality skill | 执行 4.1 | 无 |
| 无 lessons.md / 无 lessons-index.md | 执行 3.1（逐文件处理；仅索引缺失时从正文重建，不覆盖正文） | 无 |
| speckit-plan 有但未注入 lessons（无 `SPEC-KIT-INIT:PLAN-LESSONS` 标记） | 执行 3.3 | speckit-plan SKILL.md 存在 |
| speckit-implement 有但未注入（经验，无 `IMPLEMENT-LESSONS`/`IMPLEMENT-RETRO` 标记）| 执行 3.4 | speckit-implement SKILL.md 存在 |
| speckit-implement 有但未注入（质量，无 `IMPLEMENT-QUALITY` 标记）| 执行 4.2 | 3.4 注入状态已知 |
| speckit-implement 缺少两项注入 | 先 3.4 → 后 4.2 | 顺序依赖 |
| 配置有记录但实际无标记（注入被 spec-kit 升级覆盖） | 仅重新注入对应项（3.3/3.4/4.2/5.2.x） | 对应文件存在 |
| spec-kit 有但 Bug Extension 缺失 | 执行 1.5 的 ext add → 5.1 → 5.2 | `{AGENT_SPECIFY}` 有值 |

> 当多个缺失组件之间无依赖时（如同时缺少 retro + quality skill），可并行补齐。
>
> 三种运行模式：**补齐（repair）**＝只补缺失、恢复被覆盖注入，不动用户已有内容；**升级（upgrade）**＝把托管且未被用户修改的 retro/quality 更新到当前模板；**重建（reset）**＝展示覆盖清单并确认后重建托管内容。默认推荐 repair，检测到模板版本落后时推荐 upgrade。
