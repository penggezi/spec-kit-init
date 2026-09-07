# 注入文本参考

以下为各阶段向目标 SKILL.md 文件注入的精确文本。SKILL.md 中对应的阶段会引用此处的节号。

---

## 1. speckit-plan / speckit-implement 经验查阅与复盘（已迁移为原生 Hook）

> **机制变更（v0.13.0）**：plan/implement 的经验查阅与复盘**不再通过文本注入**实现，改为 spec-kit 原生 Hook（memory 扩展，见第 9.5 节）。
>
> - `before_plan` / `before_implement` → 强制触发 `speckit.memory.lookup` 命令（经验查阅）
> - `after_implement` → 可选触发 `retro`（复盘询问）
>
> 因此本文件删除了原 §1（PLAN-LESSONS）、§2（IMPLEMENT-LESSONS）、§3（IMPLEMENT-RETRO）的注入文本与对应锚点（§8.1 / §8.2）。这些标记仅在**存量旧版项目**中存在，升级（0.4）时会移除旧文本并确认 hook 就位。

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

> **plan/implement 锚点已废弃（v0.13.0）**：经验查阅/复盘不再注入这两个命令，原 §8.1（plan）与 §8.2（implement）锚点已删除。仅保留 Bug 链路锚点。

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
| `<!-- SPEC-KIT-INIT:BUG-ASSESS-LESSONS:START/END -->` | `/speckit.bug.assess` 经验库读取 | 5.2.1 |
| `<!-- SPEC-KIT-INIT:BUG-TEST-QUALITY-RETRO:START/END -->` | `/speckit.bug.test` 质量门禁与复盘联动 | 5.2.2 |
| `<!-- SPEC-KIT-INIT:KB-REFERENCE:START/END -->` | `{AGENT_FILE}` 外部知识库参考 | 阶段 2 |

> **已废弃（v0.13.0）**：`PLAN-LESSONS` / `IMPLEMENT-LESSONS` / `IMPLEMENT-RETRO` 三个标记随经验注入迁移为原生 Hook 而停用。存量旧版项目可能残留，升级（0.4）时移除。

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
    speckit_bug_assess_lessons:
      status: applied
      mode: anchored
      template_version: 1
    speckit_bug_test_quality_retro:
      status: applied
      mode: anchored
      template_version: 1
  extensions:                          # 安装的扩展记录（原生 Hook）
    memory:
      status: applied                  # applied / missing / overwritten / user_modified / skipped / failed
      version: "1.0.0"                 # memory 扩展版本
      installed_at: "2026-08-12"
      hooks:                           # 期望的 3 个 Hook 与配置
        before_plan: { command: "speckit.memory.lookup", optional: false }
        before_implement: { command: "speckit.memory.lookup", optional: false }
        after_implement: { command: "retro", optional: true }
```

> 注：`spec_kit_init.injections.speckit_plan_lessons` / `speckit_implement_lessons` / `speckit_implement_retro` 三个字段已随经验注入迁移而停用，不再写入。存量 config 中保留的旧字段视为遗留，升级（0.4）时删除。

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

### 9.5 memory 扩展 hooks 注册表（v0.13.0）

经验查阅与复盘通过 **spec-kit 原生 Hook** 触发，不再文本注入 speckit-plan / speckit-implement。Hook 声明在 `.specify/extensions.yml` 的 `hooks:` 键下（memory 扩展安装时自动合并），是**项目配置文件里的数据**——spec-kit 升级不会冲掉（与文本注入的对抗机制相反，这正是本次改造的收益）。

#### 9.5.1 三个 Hook 的 Schema

| 生命周期事件 | command | optional | prompt | 语义 |
|--------------|---------|----------|--------|------|
| `before_plan` | `speckit.memory.lookup` | `false`（强制） | — | 规划前强制查阅经验库 |
| `before_implement` | `speckit.memory.lookup` | `false`（强制） | — | 实现前强制查阅经验库 |
| `after_implement` | `retro` | `true`（可选） | 本次实现已完成，是否做一次经验复盘？(/retro) | 实现后询问是否复盘 |

> `command` 取值规则：`speckit.*` 命令渲染为 `/speckit-*`；非 `speckit.` 前缀裸命令（如 `retro`）在 Claude 下渲染为 `/{command}`。Codex `$` 模式渲染不完整——已知限制，接受。

#### 9.5.2 用户可关掉单个 Hook

`optional: true` 的钩子由 AI 在对应事件询问用户，用户拒绝即不执行。若用户想**彻底禁用**某钩子（连询问都不要），改 `.specify/extensions.yml` 中对应钩子的 `enabled: false`：

```yaml
hooks:
  after_implement:
    command: retro
    optional: true
    enabled: false        # 用户手动关闭：不再触发复盘询问
```

> spec-kit 的 `get_hooks_for_event` 会过滤 `enabled: false` 的钩子。**阶段 0 不自动改回**——用户显式关闭视为「user_modified」状态，仅在汇报中提示。

#### 9.5.3 配置记录与实际 Hook 交叉验证

同 9.4 的哲学：`.specify/config.yml` 的 `extensions.memory` 记录**不是** Hook 存在的事实来源——`specify extension remove`、手动编辑 `extensions.yml` 都可能改变实际 Hook。阶段 0 判定 Hook 状态时，读取 `extensions.memory.hooks` 记录并对照 `.specify/extensions.yml` 实际内容：

| 配置记录 | 实际 Hook | 判定 | 处理 |
|----------|-----------|------|------|
| 记录齐全 | 3 个 Hook 均在（且 `optional` 与记录一致） | ✅ 完成 | 无需处理 |
| 记录齐全 | 缺 `before_plan` / `before_implement` / `after_implement` 之一 | ⚠️ 被移除 | 回阶段 3.1 重装 memory 扩展（幂等） |
| 记录齐全 | Hook 在但 `enabled: false` | 用户显式关闭 | 不自动恢复，汇报提示 |
| 无记录 | 有 Hook | 存量 Hook（手动或其他来源） | 补写 `extensions.memory` 记录，不重复安装 |
| 无记录 | 无 Hook | 未安装 | 阶段 3.1 安装 memory 扩展 |

> **注意**：重装 memory 扩展会覆盖 `.specify/extensions.yml` 中**该扩展**的 hooks（`register_hooks` 只清理同 id 的旧记录），用户对其他扩展或同文件手写的 hooks 保留。若用户曾对 memory 钩子手动修改（`enabled: false` 等），重装会覆盖——此时应先询问是否保留自定义。