# 阶段 3-5 并行编排方案

以下为阶段 3（经验沉淀）、阶段 4（质量门禁）、阶段 5（Bug 修复）内部的并行编排方案。

## 编排图

```
第一波（扩展/文件创建并行）：
  3.1 校验 memory 扩展 + 创建经验文件 → 3.2 安装 /retro（含 3.2.1）→ 4.1 安装 /speckit-quality

第二波（speckit 钩子校验与验证并行）：
  3.3 校验 /speckit-plan 经验钩子  ← 同时 →  3.4 校验 /speckit-implement 经验/复盘钩子  ← 同时 →  5.1 验证 Bug Extension
  （3.3/3.4 均为只读校验 Hook，无文件修改冲突；5.1 只读验证，依赖阶段 1.5 的安装结果）

收尾（验证 + Bug 注入）：
  3.5 验证经验闭环 → 4.2 验证质量门禁（可并行）
  5.2 注入 Bug 增强（依赖 5.1）→ 5.3 复杂度升级规则
```

## 详细说明

### 第一波：扩展安装与文件创建

这些步骤互不依赖——各自创建/写入独立文件：

- **3.1 校验 memory 扩展 + 创建经验文件** → 先确认阶段 1.5 的 memory 扩展已装（`.specify/extensions.yml` 含 3 个 Hook）；缺则幂等重装（`specify extension add "{SKILL_ROOT}/assets/speckit-memory" --dev --force`）；再写入 `.specify/memory/lessons.md` + `lessons-index.md`
- **3.2 安装 /retro** → 写入 `{AGENT_SKILL_DIR}/retro/SKILL.md` + 复制审查模板
- **4.1 安装 /speckit-quality** → 写入 `{AGENT_SKILL_DIR}/speckit-quality/SKILL.md`

建议三个步骤同时执行，或者顺序执行均可——无依赖关系。

> **Hook 数据 vs retro skill 就位顺序**：memory 扩展的 `after_implement` 钩子仅声明 `command: retro`，运行时触发时才需要 `/retro` skill。扩展安装（3.1）与 /retro 安装（3.2）顺序无关，Hook 引用 retro 只是数据，不影响最终就位。

### 第二波：speckit 钩子校验 + Bug Extension 验证并行

3.3（校验 `/speckit-plan` 经验钩子）和 3.4（校验 `/speckit-implement` 经验/复盘钩子）**不再注入文本，只读校验 `.specify/extensions.yml` 的 `hooks:`**，不修改任何物理文件，无冲突：

- 3.3 → 确认 `hooks.before_plan` → `speckit.memory.lookup`（optional=false）
- 3.4 → 确认 `hooks.before_implement` → `speckit.memory.lookup`（optional=false）+ `hooks.after_implement` → `retro`（optional=true）

5.1（验证 Bug Extension）是只读验证，只依赖阶段 1.5 的 `specify extension add bug` 安装结果，与上述钩子校验互不干扰，可同时执行。

### 收尾：验证 + Bug 注入

3.5（验证经验闭环）和 4.2（验证质量门禁）是两个独立的验证步骤，可同时执行。完成后顺序执行：

- 5.2（依赖 5.1 的安装状态变量）
- 5.3（复杂度升级规则，无额外依赖）

## 重要说明

> 以上并行编排是**执行建议**，非硬性约束。模型可根据实际工具能力调整执行方式，串行执行不会导致失败或内容缺失，仅总耗时增加。预计节省约 25-35% 初始化时间。

标注 `⚡` 的步骤在 SKILL.md 各阶段描述中按此编排对应。
