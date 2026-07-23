# 注入文本参考

以下为各阶段向目标 SKILL.md 文件注入的精确文本。SKILL.md 中对应的阶段会引用此处的节号。

---

## 1. speckit-plan（阶段 3.3）

### 1.1 正则匹配成功时插入

```
   - **MUST** also read `.specify/memory/lessons.md`（项目级实战经验，如有相关条目须在方案中显式引用）
```

### 1.2 兜底追加

```
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 经验库注入（由 spec-kit-init 追加）

在执行 plan 前，**MUST** 读取 `.specify/memory/lessons.md`，如有与当前功能相关的经验条目须在技术方案中显式引用。
```

---

## 2. speckit-implement — lessons.md 必读（阶段 3.4 改动 A）

### 2.1 正则匹配成功时插入

```
   - **REQUIRED**: Read `.specify/memory/lessons.md` for project-level lessons learned (skip if file doesn't exist)
```

---

## 3. speckit-implement — 复盘询问（阶段 3.4 改动 B）

### 3.1 正则匹配成功时插入

````
10. **经验沉淀提示（Retrospective Prompt）**：

    实施全部完成、状态汇报输出之后，**主动询问用户是否进行复盘**，让本次实现中的踩坑、决策、验证结果有机会沉淀为长期资产。

    询问格式（中文，简洁）：
    ```
    本次实现已完成，是否现在做一次经验复盘？(/retro)
    - 是 → 调用 /retro 进入复盘流程（按 constitution.md / lessons.md 二路分流）
    - 稍后 → 跳过，你可以随时手动输 /retro
    - 否 → 跳过本次复盘
    ```

    判断准则：
    - **建议复盘**：本次实现踩过坑、做过非显然的决策、推翻了规格中的预设、发现宪章不够用
    - **可以跳过**：纯模板化代码、无新认知、用户已表达"不想复盘"

    用户回应"是"/"复盘"/"yes" → 调用 `/retro` skill 继续；用户选择跳过则正常结束。
````

### 3.2 兜底追加

```
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 经验库注入（由 spec-kit-init 追加）

1. 实现开始前，**REQUIRED** 读取 `.specify/memory/lessons.md`（如存在）。
2. 实现完成后，**主动询问用户**是否执行 `/retro` 复盘。
```

---

## 4. speckit-implement — 质量门禁（阶段 4.2）

### 4.1 正则匹配成功时插入

```
N. **代码质量门禁（Code Quality Gate）**：

    在全部实现任务标记完成之后、复盘提示之前，调用 `/speckit-quality` 执行统一质量门禁。

    a. **默认范围**：不传参数。`/speckit-quality` 自动收集 Git 中已暂存、未暂存和未追踪的变更文件，加入有证据的直接影响文件或测试；删除文件只用于影响分析，不直接传给静态分析工具。

    b. **范围升级**：修改模块入口、公共导出/类型、模块配置、路由/注册表，或发生删除/重命名且引用不明时升级为模块级；根依赖/锁文件、构建或质量配置、数据库迁移、跨模块公共契约、无法可靠划定影响边界时升级为全量。`/speckit-quality --all` 可显式要求全量。

    c. **结果归因**：报告必须区分本次变更问题、关联存量问题和无法归因问题。仅本次变更的 error，以及关键构建/类型/依赖失败，默认阻塞；未修改区域的存量问题只汇报，不要求顺带修复。

    d. **评估结果**：
       - ✅ 通过 → 继续到复盘提示
       - ❌ 阻塞（本次变更有错误级问题）→ 展示摘要 → 询问"是否自动修复阻塞问题" → 同意则只修复本次问题 → 用相同范围复检 → 通过后继续；拒绝则标记"质量门禁未通过"后继续
       - ⚠️ 警告（非阻塞、关联存量或可接受跳过）→ 展示摘要 → 不自动修复 → 将模式特征记录为复盘候选素材
       - ℹ️ 降级（无 Git/无基线/工具无法文件级检查）→ 展示原因、实际范围和剩余风险；不得把降级结果说成增量检查已通过

    e. **跳过条件**：用户可明确说"跳过质量检查"；连续 3 次阻塞且用户均选择不修复时不再重复提示。

    f. **与复盘联动**：将重复警告、存量模式、范围升级或降级原因传递给复盘步骤。范围规则和技术栈命令均以 `/speckit-quality` 自身定义为准，不在本命令中维护第二套映射表。
```

### 4.2 兜底追加

```
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 质量门禁注入（由 spec-kit-init 追加）

在全部实现任务标记完成之后、复盘提示之前，新增「代码质量门禁」步骤：调用 `/speckit-quality`，默认检查 Git 变更文件和有证据的直接影响范围；风险或范围不确定时升级模块/全量；区分本次变更、关联存量和无法归因的问题。
```

---

## 5. speckit-bug-assess（阶段 5.3.1）

### 5.1 正则匹配成功时插入

```
- **REQUIRED**: Read `.specify/memory/lessons.md` for project-level lessons learned; check for historical experience or known root-cause patterns related to the current bug (skip if file doesn't exist)
```

### 5.2 兜底追加

```
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 经验库注入（由 spec-kit-init 追加）

Before assessing the bug, **REQUIRED**: read `.specify/memory/lessons.md` and check for historical experience or known root-cause patterns related to the current bug.
```

---

## 6. speckit-bug-test（阶段 5.3.2）

### 6.1 正则匹配成功时插入

```
N. **Quality Gate & Retrospective Integration**:

    a. Run `/speckit-quality` to execute the code quality gate (default: Git change scope), ensuring the fix passes static checks.
    b. After the quality gate passes, determine whether a retrospective is needed:
       - L2/L3 escalated bugs (user impact, rollback/downgrade, data security risk)
       - Recurring issues of the same type (related entries already exist in lessons.md)
       - Non-obvious root causes or pitfalls discovered during the fix
       → If any condition is met, proactively ask the user whether to run `/retro`.
```

### 6.2 兜底追加

```
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 质量门禁与复盘联动（由 spec-kit-init 追加）

1. After verification is complete, run `/speckit-quality` to ensure the fix passes the quality gate.
2. For L2/L3 escalated bugs or recurring issues, ask the user whether to run `/retro`.
```

---

## 7. 复杂度升级规则（阶段 5.4）

Bug Extension 适用于可快速定位和修复的缺陷。当满足以下任一条件时，应告知用户需要升级到完整 SDD 规格链路：

| 条件 | 原因 |
|------|------|
| 修复会改变外部 API 契约、产品行为或用户可见流程 | 需要先确定 WHAT（规格） |
| 涉及跨服务、跨模块或复杂状态一致性 | 需要方案设计（plan） |
| 需要数据库迁移、数据修复或兼容性策略 | 需要完整评估影响范围 |
| 涉及权限、安全、支付、并发或重大性能风险 | 需要架构评审 |
| 根因表明原始需求或规格本身有缺陷 | 应先修复规格，再修代码 |
| 无法确定"正确行为"是什么 | 需要产品决策，而非技术修复 |

升级建议格式：

```
本次缺陷涉及的范围超出简单修复的边界，建议走完整 SDD 流程：
  /speckit-specify → /speckit-plan → /speckit-tasks → /speckit-implement
理由：{具体理由}
是否自动转为规格驱动流程？(y/n)
```