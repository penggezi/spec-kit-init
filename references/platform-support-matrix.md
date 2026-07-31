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

> ¹ Copilot/Cursor 不支持 `/retro` skill 的斜杠命令调用，但 `lessons.md` 是纯 Markdown 文件，可手动参考。经验沉淀机制的核心价值（经验文件 + 纠正即捕获指令）不受平台影响。

**skill 安装目录**：Copilot/Cursor 自身无标准 skill 系统。安装时 retro skill 写入 `.claude/skills/retro/` 作为统一回退目录。

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
| 无 retro skill | 执行 3.2 + 3.2.1 | 无 |
| 无 speckit-quality skill | 执行 4.1 | 无 |
| 无 lessons.md | 执行 3.1 | 无 |
| speckit-plan 有但未注入 lessons | 执行 3.3 | speckit-plan SKILL.md 存在 |
| speckit-implement 有但未注入（经验）| 执行 3.4 | speckit-implement SKILL.md 存在 |
| speckit-implement 有但未注入（质量）| 执行 4.2 | 3.4 注入状态已知 |
| speckit-implement 缺少两项注入 | 先 3.4 → 后 4.2 | 顺序依赖 |
| spec-kit 有但 Bug Extension 缺失 | 执行 1.5 的 ext add → 5.1 → 5.2 | `{AGENT_SPECIFY}` 有值 |

> 当多个缺失组件之间无依赖时（如同时缺少 retro + quality skill），可并行补齐。
