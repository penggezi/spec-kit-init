# 阶段 3-5 并行编排方案

以下为阶段 3（经验沉淀）、阶段 4（质量门禁）、阶段 5（Bug 修复）内部的并行编排方案。

## 编排图

```
第一波（文件创建并行）：
  3.1 创建经验文件 → 3.2 安装 /retro（含 3.2.1）→ 4.1 安装 /speckit-quality

第二波（speckit 注入并行）：
  3.3 改造 /speckit-plan  ← 同时 →  3.4 改造 /speckit-implement
  （修改不同文件，无冲突）

第三波（质量门禁注入 || Bug Extension 验证）：
  4.2 改造 /speckit-implement（质量门禁）  ← 同时 →  5.1 验证 Bug Extension
  （4.2 依赖 3.4 的注入状态，5.1 依赖 1.5 的安装结果，两者之间无依赖）
  → 然后顺序执行 5.2（依赖 5.1）→ 5.3

收尾：
  3.5 验证经验闭环 → 4.3 验证质量门禁
```

## 详细说明

### 第一波：文件创建

这三个步骤互不依赖——它们各自创建/写入独立文件：

- **3.1 创建经验文件** → 写入 `.specify/memory/lessons.md` + `lessons.idx`
- **3.2 安装 /retro** → 写入 `{AGENT_SKILL_DIR}/retro/SKILL.md` + 复制审查模板
- **4.1 安装 /speckit-quality** → 写入 `{AGENT_SKILL_DIR}/speckit-quality/SKILL.md`

建议三个步骤同时执行，或者顺序执行均可——无依赖关系。

### 第二波：speckit 并行注入

3.3（改造 `/speckit-plan`）和 3.4（改造 `/speckit-implement`）修改的是**不同的物理文件**，不存在冲突：

- 3.3 → `{AGENT_SKILL_DIR}/speckit-plan/SKILL.md`
- 3.4 → `{AGENT_SKILL_DIR}/speckit-implement/SKILL.md`

可同时执行。

### 第三波：质量门禁注入 + Bug Extension 验证

**4.2（改造 speckit-implement 注入质量门禁）** 和 **5.1（验证 Bug Extension）** 互不依赖：

- 4.2 依赖 3.4 的注入结果（需要知道 speckit-implement 是否走兜底路径）
- 5.1 依赖阶段 1.5 的 `specify extension add bug` 安装结果

两者可以同时执行。完成后顺序执行：
- 5.2（依赖 5.1 的安装状态变量）
- 5.3（复杂度升级规则，无额外依赖）

### 收尾验证

3.5 和 4.3 是两个独立的验证步骤，可同时执行。

## 重要说明

> 以上并行编排是**执行建议**，非硬性约束。模型可根据实际工具能力调整执行方式，串行执行不会导致失败或内容缺失，仅总耗时增加。预计节省约 25-35% 初始化时间。

标注 `⚡` 的步骤在 SKILL.md 各阶段描述中按此编排对应。
