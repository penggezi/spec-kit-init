---
name: "speckit-quality"
description: "代码质量门禁。自动检测项目技术栈，运行对应的静态分析工具，评估结果并修复阻塞性问题。"
argument-hint: "留空=全量检查；指定文件路径=仅检查指定文件"
user-invocable: false
disable-model-invocation: false
---

## User Input

```text
ARGUMENTS
```

## 执行流程

### 1. 确定检查范围

根据 ARGUMENTS 决定检查范围：

| 输入 | 范围 |
|------|------|
| 空 | 全量检查（自动检测所有源文件） |
| 文件路径 | 仅检查指定文件（如 `src/controller.ts src/model.ts`） |

### 2. 自动检测技术栈

读取项目根目录的配置文件，确定技术栈：

| 配置文件 | 技术栈 | 主工具 |
|---------|--------|--------|
| pom.xml 或 build.gradle | Java | mvn checkstyle:check 或 gradle check |
| package.json + .ts/.tsx | TypeScript | npx eslint src/ --max-warnings 0 |
| package.json（无 TypeScript） | JavaScript | npx eslint src/ --max-warnings 0 |
| pyproject.toml 或 requirements.txt | Python | ruff check . |
| go.mod | Go | golangci-lint run |
| Cargo.toml | Rust | cargo clippy -- -D warnings |
| .csproj 或 .sln | .NET | dotnet format --verify-no-changes |
| 多个特征同时存在 | 多模块 | 逐技术栈运行 |
| 无匹配 | 未知 | 跳过检查 |

**检测方式**：使用 ls 或 glob 检测项目根目录下的配置文件。多模块项目时检测所有子模块。

### 3. 运行静态分析

根据技术栈运行对应工具。如果 ARGUMENTS 包含文件路径，将检查范围限定到指定文件。

**全量命令示例**：
- Java: `mvn checkstyle:check` 或 `gradle check`
- TypeScript/JS: `npx eslint src/ --max-warnings 0`
- Python: `ruff check .`
- Go: `golangci-lint run ./...`
- Rust: `cargo clippy -- -D warnings`

**限定文件命令示例**：
- ESLint: `npx eslint --no-ignore --max-warnings 0 file1.ts file2.ts`
- Ruff: `ruff check file1.py file2.py`
- Checkstyle: `mvn checkstyle:check -Dcheckstyle.includes=**/File.java`

> 工具命令不存在时，展示失败原因后跳过检查，不阻塞流程。

### 4. 评估结果

将结果分为三级：

| 级别 | 标准 | 处理 |
|------|------|------|
| 通过 | 无错误警告 | 输出结果，继续 |
| 警告 | 仅有 warning 级，无 error | 按规则类型汇总展示，**不修复**，记录到复盘候选素材 |
| 阻塞 | 有 error 级问题 | 展示摘要，询问是否自动修复 |

#### 阻塞修复流程

用户同意后逐问题处理：

```
对每个 error 问题：
  读取对应代码位置
  按工具提示修复
  标记已修复

全部修复后重新运行检查
循环直到阻塞归零，或用户跳过
```

**修复原则**：
- 机械问题（缩进、命名、未用变量）→ 直接修复
- 需判断的问题（架构、API 误用）→ 展示差异，用户确认后再改
- 连续 3 次阻塞且用户均跳过 → 不再提示

### 5. 与复盘联动

将警告模式输出为复盘候选素材：

```text
## 质量检查候选素材（供 /retro 参考）

- {规则类型}：{次数} 次（涉及：{文件列表}）
  → 建议沉淀 / 建议不处理
```

**判断指引**：
- 同一规则多文件出现 → 值得沉淀（项目级习惯）
- 单文件多次同一规则 → 按需沉淀
- 一次性无规律问题 → 不沉淀

---

## 调用边界

- 不修改与质量修复无关的代码
- 不将警告直接写入 lessons.md（只作为复盘素材传递）
- 用户说"跳过"就跳过，不坚持
- 连续跳过多次后不再提示
