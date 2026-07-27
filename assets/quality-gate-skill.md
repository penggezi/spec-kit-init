---
name: "speckit-quality"
description: "代码质量门禁。默认检查 Git 变更文件及有证据的直接影响范围；按风险升级到模块或全量检查，并区分本次变更与存量问题。"
argument-hint: "留空=Git变更+直接影响范围；文件路径=指定文件；module:<路径>=指定模块；--all=全量检查"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
ARGUMENTS
```

## 执行原则

- 默认目标是验证**本次改动**，不是审计整个仓库；普通变更不得因为未修改区域的历史问题而被阻塞。
- 先使用项目已有的 lint、format、类型检查和测试脚本；仅在项目没有对应脚本时使用本模板的工具命令。
- 所有报告必须列出：实际检查范围、范围来源、直接影响证据、升级/降级原因、工具结果，以及本次变更/存量/无法归因问题的分类。
- 不把未实际执行的检查称为通过；工具不可用、范围不可得或命令失败必须如实报告。

## 执行流程

### 1. 确定检查模式

按以下优先级解析 `ARGUMENTS`：

| 输入 | 模式 | 范围 |
|------|------|------|
| 文件路径 | `explicit-files` | 仅指定文件；必要时采用工具要求的最小安全模块范围 |
| `module:<路径>` | `explicit-module` | 指定模块或包 |
| `--all` 或 `all` | `full` | 全项目/全部相关模块 |
| 空 | `git-impact` | Git 变更文件 + 有证据的直接影响范围 |

用户显式范围优先于自动推导，**但不能覆盖第 4 节的强制升级条件**。显式文件或模块与根配置、依赖、数据库迁移、跨模块契约等强制升级条件冲突时，先展示扩大范围的原因；用户确认后执行升级范围，用户拒绝时标记“范围不足，未完成完整质量验证”。用户说“跳过”时跳过，但必须输出跳过原因。

### 2. 收集 Git 变更集（仅 `git-impact`）

先判断当前目录是否属于 Git 工作树：

```bash
git rev-parse --show-toplevel
```

再判断是否存在初始提交：

```bash
git rev-parse --verify HEAD
```

#### 2.1 存在 `HEAD`

分别收集已跟踪和未追踪文件，再去重：

```bash
# 已暂存、未暂存、删除、重命名等相对 HEAD 的变更；--find-copies 可识别复制目标路径
git diff --name-status --find-renames --find-copies HEAD

# 尚未 git add 的新文件
git ls-files --others --exclude-standard
```

- 新增、修改、复制、重命名后的新路径、类型变化、未合并文件：加入候选检查文件。
- 删除文件和重命名的旧路径：**不得**作为 lint 或格式化命令参数；仅用于影响分析。
- 忽略纯文档、图片和二进制变更，除非它们是构建、代码生成、配置或质量规则的输入。
- 候选代码文件为空时，不运行静态分析，也不得因空参数退化为全量命令；输出“未发现可检查的代码变更”。仅用户显式 `--all` 或第 4 节的强制升级条件才允许全量检查。

#### 2.2 无 `HEAD`（初始提交前）

分别收集暂存、未暂存与未追踪文件，再去重；不要执行 `git diff HEAD`：

```bash
# 已暂存文件
git diff --cached --name-status --find-renames --find-copies

# 未暂存的已跟踪文件
git diff --name-status --find-renames --find-copies

# 未追踪文件
git ls-files --others --exclude-standard
```

按 2.1 的新增/修改/删除/重命名规则筛选候选。无 `HEAD` 时不能做基于行的精确归因；若没有可识别的源文件：

- 提示用户指定文件、模块或 `--all`；
- 自动流程无法获得用户输入时，执行最小可确定模块检查；若连模块也无法确定，才降级为全量，并明确说明原因。

#### 2.3 非 Git 工作区

不伪造 Git 增量结果。优先按显式文件或模块执行；没有显式范围时，从当前任务已明确的修改文件推导。若仍无法确定范围，要求用户指定范围；自动流程无法询问时执行全量，并标记为“因无可靠范围而降级”。

### 3. 推导直接影响范围

候选范围首先包含新增、修改、未追踪的源文件和测试文件。只在找到**可说明证据**时加入直接影响项：

1. 同模块中直接 `import`、`require`、`include`、使用或导出的引用者；
2. 明确的路由、注册表、依赖注入、代码生成或构建 source-set 关联；
3. 项目既有且可验证的源文件—测试文件映射；
4. 已变更公共文件的直接消费者。

通过搜索结果记录证据，例如：`src/controller/UserController.ts 直接导入 src/service/UserService.ts`。目录名相似、语言相同或“可能相关”都不是加入文件的证据。

#### 删除与重命名文件

删除或重命名文件需要检查其所属模块、直接引用者、模块入口和注册关系；若引用关系不能可靠确认，升级为模块级检查。删除的路径不传给静态分析工具。

### 4. 决定文件、模块或全量范围

默认采用文件级范围。触发条件如下：

| 触发条件 | 执行范围 |
|----------|----------|
| 普通源文件、局部测试、可证据化的少量直接引用 | 文件级 + 对应测试 |
| 修改模块入口、公共导出/类型/基类、模块构建配置、路由/注册表；删除或重命名且引用不明；工具不支持文件级检查 | 所属模块 |
| 根构建/依赖/锁文件、根 lint/formatter/CI 配置、数据库 schema/迁移、序列化协议、跨模块公共契约、代码生成规则、无法可靠划分影响边界 | 全量或全部受影响模块 |
| 用户传入 `--all` | 全量 |

变更跨多个模块或影响文件明显过多时，也可升级；报告必须给出实际原因和范围，不能静默扩大扫描。

### 5. 自动检测技术栈与运行工具

读取根目录和已确定模块内的配置文件，识别技术栈。多模块项目只检查受影响模块；全量模式才遍历全部模块。

| 配置特征 | 技术栈 | 文件级（优先） | 模块级 | 全量 |
|---------|--------|----------------|--------|------|
| package.json + .ts/.tsx | TypeScript | `npx eslint --max-warnings 0 -- file1.ts file2.ts` | `npx eslint --max-warnings 0 module/` | `npx eslint --max-warnings 0 .` 或项目脚本 |
| package.json（无 TS） | JavaScript | `npx eslint --max-warnings 0 -- file1.js` | `npx eslint --max-warnings 0 module/` | `npx eslint --max-warnings 0 .` 或项目脚本 |
| pyproject.toml / requirements.txt | Python | `ruff check file1.py file2.py` | `ruff check module/` | `ruff check .` |
| pom.xml / build.gradle | Java | 工具支持 include 时按文件；否则使用模块 | `mvn -pl module checkstyle:check` 或模块 Gradle task | 项目既有 Maven/Gradle 脚本；无脚本时 `mvn verify` 或已配置的 Checkstyle/SpotBugs 目标 / `gradle check` |
| go.mod | Go | 不强制单文件，按包 | `golangci-lint run ./path/to/package/...` | `golangci-lint run ./...` |
| Cargo.toml | Rust | 不强制单文件，按 crate | `cargo clippy -p <crate> -- -D warnings` | `cargo clippy --workspace --all-targets -- -D warnings` |
| build.gradle.kts / .kt | Kotlin | 按模块 task | `./gradlew :module:check` | `./gradlew check` |
| composer.json | PHP | `vendor/bin/phpstan analyse file.php`（工具支持时） | `vendor/bin/phpstan analyse module/` | `vendor/bin/phpstan analyse` |
| Gemfile / .rb | Ruby | `bundle exec rubocop file.rb` | `bundle exec rubocop module/` | `bundle exec rubocop` |
| Package.swift / .swift | Swift | 工具支持时传文件 | 所属 package | `swiftlint` |
| pubspec.yaml | Dart/Flutter | 工具支持时传文件 | `dart analyze module/` | `dart analyze` |
| CMakeLists.txt / C/C++ | C/C++ | `clang-tidy file.cpp -- <compile flags>` | 所属编译单元 | 项目既有 clang-tidy 命令 |
| .csproj / .sln | .NET | `dotnet format project.csproj --verify-no-changes` | 指定 .csproj | 指定 .sln 或所有项目 |

- 路径必须逐项传参；支持 `--` 的工具使用它分隔选项与文件路径。
- 文件级工具不可安全使用时，选择所属模块，说明原因；不得为了方便直接改为全仓库。
- 工具不存在时，展示原因和安装引导后跳过该工具，不阻塞其他可运行工具。

### 6. 区分本次变更与存量问题

对可定位到文件和行号的诊断，使用零上下文 diff 辅助归因：

```bash
git diff --unified=0 HEAD -- <file>
```

将问题分为：

| 分类 | 判定 | 默认处理 |
|------|------|----------|
| 本次变更问题 | 落在新增/修改行，或工具明确由本次变更触发 | error 阻塞；warning 汇总 |
| 关联存量问题 | 在检查范围内但不在本次修改行，无法证明由本次引入 | 单独报告，不归因于本次改动 |
| 无法归因问题 | 工具只给出模块/全局失败，无法映射文件或行 | 明示不确定性；关键构建、类型、依赖失败默认阻塞 |

工具没有行号或没有可靠 Git 基线时，不得声称完成精确归因。

### 7. 评估并汇报结果

| 级别 | 标准 | 处理 |
|------|------|------|
| 通过 | 选定范围内没有本次变更的阻塞问题 | 输出范围和结果，继续 |
| 警告 | 仅 warning、关联存量问题或可接受的跳过项 | 汇总展示，不自动修复，作为复盘候选 |
| 阻塞 | 本次变更 error，或关键构建/类型/依赖检查失败 | 展示摘要，询问是否修复 |
| 降级 | 无法获得理想范围，已使用模块/全量或跳过 | 说明原因、实际范围和剩余风险 |

报告至少包括：

```text
检查模式：{git-impact / explicit-files / explicit-module / full}
直接修改文件：{列表}
直接影响文件/模块：{列表与证据}
实际执行范围：{文件/模块/全量}
范围变化：{无 / 升级或降级原因}
本次变更问题：{数量与摘要}
关联存量问题：{数量与摘要}
无法归因问题：{数量与摘要}
工具结果：{命令、状态、跳过原因}
```

#### 阻塞修复流程

用户同意后，仅处理本次变更问题或用户明确指定的问题：

```text
对每个 error 问题：
  读取对应代码位置
  按工具提示修复
  标记已修复

全部修复后，重新运行相同范围的检查
循环直到阻塞归零，或用户跳过
```

- 机械问题（缩进、命名、未用变量）可直接修复。
- 架构、API 误用、影响范围扩大等需判断的问题，先展示差异并确认。
- 关联存量问题不纳入本次修复，除非用户明确要求做存量治理。
- 连续 3 次阻塞且用户均跳过，不再重复提示。

### 8. 与复盘联动

将重复的警告、存量模式或范围升级原因输出为 `/retro` 候选素材：

```text
## 质量检查候选素材（供 /retro 参考）

- {规则类型}：{次数} 次（涉及：{文件列表}）
  分类：本次变更 / 关联存量 / 无法归因
  范围：文件级 / 模块级 / 全量；{升级或降级原因}
  → 建议沉淀 / 建议不处理
```

同一规则跨多个文件出现、反复触发模块/全量升级，或暴露项目级约束缺失时，优先建议复盘。

---

## 调用边界

- 不修改与质量修复无关的代码。
- 不将警告直接写入 `lessons.md`，只作为复盘素材传递。
- 用户说“跳过”就跳过，不坚持。
- 不把删除文件传给静态分析工具。
- 不把未追踪源文件和测试文件遗漏出检查范围。
- 不把存量问题描述为本次改动引入的问题。
