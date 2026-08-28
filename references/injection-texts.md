# 注入文本参考

以下为各阶段向目标 SKILL.md 文件注入的精确文本。SKILL.md 中对应的阶段会引用此处的节号。

---

## 1. speckit-plan（阶段 3.3）

### 1.1 正则匹配成功时插入

````
<!-- SPEC-KIT-INIT:PLAN-LESSONS:START -->
   - **MUST** also read `.specify/memory/lessons.md`（项目级实战经验，如有相关条目须在方案中显式引用）：
     1. 先读取 `.specify/memory/lessons-index.md`，扫描是否有与当前功能相关的关键词
     2. 有命中 → 读取 `lessons.md` 中对应的具体条目，在方案中显式引用
     3. 无命中 → 告知用户"lessons.md 中暂无本功能相关经验"，继续后续步骤
<!-- SPEC-KIT-INIT:PLAN-LESSONS:END -->
````

### 1.2 兜底追加

````
<!-- SPEC-KIT-INIT:PLAN-LESSONS:START -->
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 经验库注入（由 spec-kit-init 追加）

在执行 plan 前，**MUST** 按以下步骤读取经验库：
1. 先读取 `.specify/memory/lessons-index.md`（极轻量索引），扫描是否有与当前功能相关的关键词
2. 有命中 → 读取 `lessons.md` 中对应的具体条目，在方案中显式引用
3. 无命中 → 告知用户"暂无相关经验"，继续后续步骤
<!-- SPEC-KIT-INIT:PLAN-LESSONS:END -->
````

---

## 2. speckit-implement — lessons.md 必读（阶段 3.4 改动 A）

### 2.1 正则匹配成功时插入

````
<!-- SPEC-KIT-INIT:IMPLEMENT-LESSONS:START -->
   - **必须** 读取 `.specify/memory/lessons-index.md`（极轻量索引），扫描是否有与当前实现相关的关键词：
     1. 有命中 → 读取 `lessons.md` 中对应的具体条目，在实现中遵循
     2. 无命中 → 继续后续步骤，无需读取完整 `lessons.md`
<!-- SPEC-KIT-INIT:IMPLEMENT-LESSONS:END -->
````

---

## 3. speckit-implement — 复盘询问（阶段 3.4 改动 B）

### 3.1 正则匹配成功时插入

````
<!-- SPEC-KIT-INIT:IMPLEMENT-RETRO:START -->
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
<!-- SPEC-KIT-INIT:IMPLEMENT-RETRO:END -->
````

### 3.2 兜底追加

````
<!-- SPEC-KIT-INIT:IMPLEMENT-LESSONS:START -->
<!-- SPEC-KIT-INIT:IMPLEMENT-RETRO:START -->
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 经验库注入（由 spec-kit-init 追加）

1. 实现开始前，**必须** 按以下步骤读取经验库：
   - 先读取 `.specify/memory/lessons-index.md`，扫描是否有与当前实现相关的关键词
   - 有命中 → 读取 `lessons.md` 中对应的具体条目
   - 无命中 → 继续后续步骤
2. 实现完成后，**主动询问用户**是否执行 `/retro` 复盘。
<!-- SPEC-KIT-INIT:IMPLEMENT-LESSONS:END -->
<!-- SPEC-KIT-INIT:IMPLEMENT-RETRO:END -->
````

---

## 5. speckit-bug-assess（阶段 5.2.1）

### 5.1 正则匹配成功时插入

````
<!-- SPEC-KIT-INIT:BUG-ASSESS-LESSONS:START -->
- **必须** 读取项目经验库：
  1. 先读取 `.specify/memory/lessons-index.md`，扫描是否有与当前缺陷相关的关键词（同类缺陷、已知根因模式）
  2. 有命中 → 读取 `lessons.md` 中对应的具体条目，在评估中显式引用
  3. 无命中 → 告知用户"经验库中暂无本缺陷相关记录"，继续评估
<!-- SPEC-KIT-INIT:BUG-ASSESS-LESSONS:END -->
````

### 5.2 兜底追加

````
<!-- SPEC-KIT-INIT:BUG-ASSESS-LESSONS:START -->
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 经验库注入（由 spec-kit-init 追加）

在评估缺陷之前，**必须** 按以下步骤读取经验库：
1. 先读取 `.specify/memory/lessons-index.md`，扫描是否有与当前缺陷相关的关键词
2. 有命中 → 读取 `lessons.md` 中对应的具体条目，在评估中引用
3. 无命中 → 继续评估
<!-- SPEC-KIT-INIT:BUG-ASSESS-LESSONS:END -->
````

---

## 6. speckit-bug-test（阶段 5.2.2）

### 6.1 正则匹配成功时插入

````
<!-- SPEC-KIT-INIT:BUG-TEST-QUALITY-RETRO:START -->
N. **质量门禁与复盘联动**：

    a. 调用 `/speckit-quality` 执行代码质量门禁（默认范围：Git 变更），确保修复通过静态检查。
    b. 质量门禁通过后，判断是否需要复盘：
       - L2/L3 升级缺陷（用户影响、回滚/降级、数据安全风险）
       - 同类型反复出现的缺陷（lessons.md 中已有相关条目）
       - 修复过程中发现的非显然根因或陷阱
       → 满足任一条件时，主动询问用户是否执行 `/retro`。
<!-- SPEC-KIT-INIT:BUG-TEST-QUALITY-RETRO:END -->
````

### 6.2 兜底追加

````
<!-- SPEC-KIT-INIT:BUG-TEST-QUALITY-RETRO:START -->
<!-- ⚠ 自动追加，请人工确认位置是否正确 -->
## ⚠ 质量门禁与复盘联动（由 spec-kit-init 追加）

1. 验证完成后，调用 `/speckit-quality` 执行代码质量门禁，确保修复通过静态检查。
2. 对于 L2/L3 升级缺陷或同类型反复出现的缺陷，主动询问用户是否执行 `/retro`。
<!-- SPEC-KIT-INIT:BUG-TEST-QUALITY-RETRO:END -->
````

---

## 7. 复杂度升级规则（阶段 5.3）

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

---

## 8. 注入兼容性锚点定义

以下为各 spec-kit skill 文件中用于结构匹配的**锚点标题列表**。在注入前，读取目标文件，统计以下锚点在该文件中的命中率，判断结构兼容性。

### 8.1 speckit-plan 锚点（阶段 3.3）

用于定位「Load context」步骤的锚点：

```
Load context, Load IMPL_PLAN, constitution.md, FEATURE_SPEC, Fill Constitution Check
```

> 匹配率 = 命中的锚点数 / 总锚点数（5 个）。匹配率 ≥ 60%（3/5）时正常注入；< 60% 时走兜底。

### 8.2 speckit-implement 锚点（阶段 3.4）

用于定位「实现上下文读取」步骤的锚点：

```
Load and analyze, implementation context, Read tasks.md, Read plan.md, Read data-model.md
```

用于定位「Completion validation」步骤的锚点：

```
Completion validation, Verify all required tasks, Check that implemented features, Validate that tests pass, Confirm the implementation follows
```

> 匹配率为两组锚点分别计算。任一组匹配率 < 50% 时，该改动走兜底。

### 8.3 speckit-bug-assess 锚点（阶段 5.2.1）

用于定位「评估步骤」的锚点：

```
Assess merit, Locate the suspected, Propose a remediation, Write the assessment file, Assess
```

> 匹配率 = 命中的锚点数 / 总锚点数（5 个）。匹配率 ≥ 60%（3/5）时正常注入。

### 8.4 speckit-bug-test 锚点（阶段 5.2.2）

用于定位「验证完成步骤」的锚点：

```
Judge the outcome, Write the verification report, verification report, Mark the fix as, BUG_DIR/test.md
```

> 匹配率 = 命中的锚点数 / 总锚点数（5 个）。匹配率 ≥ 60%（3/5）时正常注入。

### 8.5 已知兼容版本

本 Skill 开发时 spec-kit 的兼容版本范围为 `>=0.0.22`。锚点列表已于 v0.8.2 针对 `0.13.5` 模板措辞更新。版本号通过阶段 1.5 的 `specify --version` 获取。

> **版本判断以注入锚点检测为最终依据**，`specify --version` 仅作参考提示：版本落在已验证范围之外的，只在阶段 1.5 输出警告，不阻断流程；注入阶段的锚点匹配率才是实际兼容性的判定标准。

---

## 9. 托管注入标记与配置记录 Schema

以下约定供阶段 0 幂等检查、阶段 3-5 注入、回滚恢复共同使用。

### 9.1 注入标记注册表

每处注入内容（无论正则匹配成功还是兜底追加）必须以 `SPEC-KIT-INIT` 标记包裹，标记名不可更改。阶段 0 通过标记判断注入是否存在，回滚通过标记删除注入。

| 标记 | 注入对象 | 阶段 |
|------|----------|------|
| `<!-- SPEC-KIT-INIT:PLAN-LESSONS:START/END -->` | `/speckit-plan` 经验库读取 | 3.3 |
| `<!-- SPEC-KIT-INIT:IMPLEMENT-LESSONS:START/END -->` | `/speckit-implement` 经验库读取 | 3.4 改动 A |
| `<!-- SPEC-KIT-INIT:IMPLEMENT-RETRO:START/END -->` | `/speckit-implement` 复盘询问 | 3.4 改动 B |
| `<!-- SPEC-KIT-INIT:BUG-ASSESS-LESSONS:START/END -->` | `/speckit.bug.assess` 经验库读取 | 5.2.1 |
| `<!-- SPEC-KIT-INIT:BUG-TEST-QUALITY-RETRO:START/END -->` | `/speckit.bug.test` 质量门禁与复盘联动 | 5.2.2 |
| `<!-- SPEC-KIT-INIT:KB-REFERENCE:START/END -->` | `{AGENT_FILE}` 外部知识库参考 | 阶段 2 |

规则：

- 正则匹配成功路径与兜底追加路径**必须使用相同标记**，保证阶段 0 和回滚对两条路径一视同仁
- 兜底追加块保留 `<!-- ⚠ 自动追加，请人工确认位置是否正确 -->` 作为面向用户的提示，但机器判断只认 `SPEC-KIT-INIT` 标记
- 同一文件出现重复 START 标记时，视为注入异常，阶段 0 报告「重复注入」并提示人工清理

### 9.2 托管文件标记（retro / quality skill）

由本 Skill 部署的完整 skill 文件（非注入段）在文件顶部 YAML frontmatter 之后写入托管标记：

```
<!-- SPEC-KIT-INIT-MANAGED
component: retro|speckit-quality
template-version: 1
source-version: 0.11.0
-->
```

- `template-version`：模板结构版本，模板结构变化时递增（独立于本 Skill 的发布版本）
- `source-version`：生成时的本 Skill 版本
- 无此标记的文件视为用户自建或非本 Skill 生成，**不自动覆盖**

### 9.3 `.specify/config.yml` 注入记录 Schema

注入成功后在 `.specify/config.yml` 中追加或更新 `spec_kit_init` 字段。Schema 固定如下，新增字段时向后兼容：

```yaml
spec_kit_init:
  version: "0.11.0"                    # 记录写入时本 Skill 的版本
  initialized_at: "2026-08-12"         # 首次初始化的日期
  platform: "claude"                   # 1.2 选择的平台：claude / codex / copilot / cursor / custom
  knowledge_base:                      # 外部知识库（可选，阶段 1.2.2 配置）
    enabled: true
    paths:
      - "D:/team-wiki"
  assets:                              # 部署的完整 skill 文件版本记录（P0-6 使用）
    retro:
      template_version: 1
      content_hash: "<sha256>"
    quality_gate:
      template_version: 1
      content_hash: "<sha256>"
  injections:                          # 每处注入的状态记录
    agent_instructions:
      status: applied
      mode: anchored
      template_version: 1
    knowledge_base_reference:
      status: applied
      mode: anchored
      template_version: 1
    speckit_plan_lessons:
      status: applied
      mode: anchored
      template_version: 1
    speckit_implement_lessons:
      status: applied
      mode: anchored
      template_version: 1
    speckit_implement_retro:
      status: applied
      mode: anchored
      template_version: 1
    speckit_bug_assess_lessons:
      status: applied
      mode: anchored
      template_version: 1
    speckit_bug_test_quality_retro:
      status: applied
      mode: anchored
      template_version: 1
```

**状态枚举**：

| 状态 | 含义 |
|------|------|
| `applied` | 正则匹配成功注入，标记就位 |
| `fallback` | 走兜底追加路径，标记就位但位置需人工确认 |
| `missing` | 配置有记录但文件中无对应标记（被覆盖/删除） |
| `overwritten` | 检测到 spec-kit 升级覆盖了注入内容 |
| `user_modified` | 目标文件内容与安装时 hash 不一致（用户改过） |
| `skipped` | 平台不支持或条件不满足，跳过注入 |
| `failed` | 注入失败 |

**mode 枚举**：`anchored`（正则锚点注入）/ `appended`（末尾兜底追加）。

### 9.4 配置记录与实际文件交叉验证

配置记录**不是**注入存在的事实来源——`specify` 重新安装或升级可能覆盖注入内容。阶段 0 判定某处注入状态时，必须同时读取配置记录和扫描目标文件中的 `SPEC-KIT-INIT` 标记：

| 配置记录 | 实际标记 | 判定 | 处理 |
|----------|----------|------|------|
| 有 `applied/fallback` | 有 | ✅ 完成 | 无需处理 |
| 有 | 无 | ⚠️ 被覆盖/删除 | 走补齐流程恢复注入 |
| 无 | 有 | 存量注入（旧版） | 补写配置记录，不重复注入 |
| 无 | 无 | 未注入 | 执行注入 |