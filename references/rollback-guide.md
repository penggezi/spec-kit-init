# 回滚与恢复指南

以下为初始化中途失败时的清理步骤。仅在初始化失败时按需读取。

---

## 核心原则

- **只撤销本次运行创建的 / 修改的内容**，绝不删除用户初始化前已有的内容
- 修改任何现有文件前必须先备份到本次运行的事务目录
- 禁止无条件 `rm -rf .specify/` 或通配符清理（可能误删用户资产）
- 所有注入内容带 `SPEC-KIT-INIT` 标记（见 `injection-texts.md` 第 9.1 节），是幂等判断和回滚的唯一依据

---

## 一、事务清单（初始化前建立）

在执行任何变更前，在 `{PROJECT_ROOT}/.specify/.spec-kit-init/transactions/<run-id>/` 下建立本次运行的事务目录（`<run-id>` 用「日期-时间」命名，如 `2026-08-12T14-32-00`），内含 `manifest.yml` 与 `backups/`：

```yaml
run_id: "2026-08-12T14-32-00"
status: in_progress

created:        # 本次运行新建的文件（回滚时删除）
  - .specify/sdd-workflow.md
  - .specify/memory/lessons-index.md
  - .specify/extensions/memory/          # memory 扩展（经验 Hook）
  - .claude/skills/speckit-memory-lookup/SKILL.md

modified:       # 本次运行修改的现有文件（回滚时从备份恢复）
  - path: CLAUDE.md
    backup: backups/CLAUDE.md
  - path: .claude/skills/speckit-implement/SKILL.md
    backup: backups/speckit-implement-SKILL.md
  - path: .specify/extensions.yml        # memory 扩展 hooks 合并处（回滚时恢复备份）
    backup: backups/extensions.yml

preexisting:    # 初始化前已存在、本次未触碰的文件（绝不删除）
  - .specify/memory/constitution.md
```

规则：

1. 修改现有文件前，先复制到 `backups/` 并在 `modified` 中记录；同一路径在一次运行中只备份一次（后续覆盖备份的是初始快照，不得覆盖）
2. 每执行一步，同步更新 `manifest.yml` 的 `status` 与清单；全部完成后标记 `status: completed`
3. 完成后将事务目录从 `.specify/` 移出或删除（仅在确认成功后）

---

## 二、失败场景与回滚方式

| 失败场景 | 回滚方式 |
|----------|----------|
| `specify init` 失败 | **不要假设无副作用**。重新扫描初始化前后的路径差异：只把本次新建的文件记入 `created` 删除；已存在且被修改的文件从备份恢复；其余不动 |
| `specify init` 已完成但后续步骤失败 | `.specify/` 中本次创建的结构保留，可按事务清单逐项回滚本次修改；`{AGENT_FILE}` 中本次注入的 `<!-- SDD:START/END -->` 段删除 |
| 阶段 0.5 迁移中途失败（已抽取 `.specify/sdd-workflow.md` 但未替换精简段） | 删除本次生成的 `.specify/sdd-workflow.md`，`{AGENT_FILE}` 中的完整 SDD 段保持不变（若此前已备份则从备份恢复） |
| 阶段 2 外部知识库注入后失败 | 删除 `{AGENT_FILE}` 中 `<!-- SPEC-KIT-INIT:KB-REFERENCE:START -->` 至 `<!-- SPEC-KIT-INIT:KB-REFERENCE:END -->` 之间的注入内容；外部知识库目录本身是只读外部资源，不在此事务范围内 |
| 阶段 3/4/5 注入后失败 | 删除目标文件中 `<!-- SPEC-KIT-INIT:...:START -->` 至 `<!-- SPEC-KIT-INIT:...:END -->` 之间的注入内容（兜底路径同时删除 `<!-- ⚠ 自动追加...-->` 标记块）；若文件整体被修改过，从 `modified` 的备份恢复 |
| 正则匹配成功路径的注入需要回滚 | 同样通过 `SPEC-KIT-INIT` 标记删除——**正常注入与兜底注入使用相同标记**，不依赖 `⚠ 自动追加` 标记 |
| Bug Extension 步骤（阶段 5）已安装但后续失败 | `.specify/extensions/bug/` 为本次新建时，运行 `specify extension remove bug` 清理；`.specify/bugs/` 目录为空时可删除（非本次创建则保留） |
| memory 扩展（经验 Hook）已安装但后续失败 | 运行 `specify extension remove memory --force`——自动反注册 3 个 Hook（恢复 `.specify/extensions.yml` 到未装前）并移除 `speckit-memory-lookup` skill；删除 config.yml 中 `spec_kit_init.extensions.memory` 记录。若卸载前存在旧版文本注入（存量项目 0.4 迁移路径），回滚时**恢复** speckit-plan/implement 中的 3 段旧注入文本（从中止前的备份恢复） |

---

## 三、回滚执行步骤

```text
1. 读取本次运行的事务目录，找到 manifest.yml
2. 对 modified 中的每个文件：确认其未被外部再次修改（hash 与备份写入时一致）→ 从 backups/ 恢复
   若已被外部修改 → 停止自动恢复，报告冲突，由用户决定
3. 对 created 中的每个文件：确认仍是本次生成内容（非空且符合本次创建特征）→ 删除
4. preexisting 中的路径一律不动
5. 将事务目录标记为 status: rolled_back
```

> 重复回滚是安全的：文件已恢复或已删除时，跳过对应条目，不会二次破坏。

---

## 四、完整卸载（用户主动请求，非自动回滚）

完整卸载本 Skill 生成的托管内容时：

1. 扫描 `.specify/`、`{AGENT_SKILL_DIR}` 下的 `SPEC-KIT-INIT` / `SPEC-KIT-INIT-MANAGED` 标记与事务清单
2. 展示准确清单：将删除的文件（可证明由本 Skill 创建）、将恢复的文件（从备份）、无法确认来源的文件
3. 对无法确认来源的文件（如无托管标记的 retro/SKILL.md），单独标出并询问用户
4. 用户明确确认后，只删除有据可依的内容；无 `SPEC-KIT-INIT-MANAGED` 标记的用户自建文件不删除
5. 从 `{AGENT_FILE}` 移除 `<!-- SDD:START -->` 至 `<!-- SDD:END -->` 段、「经验库优先」段与「外部知识库」段（含 `SPEC-KIT-INIT:KB-REFERENCE` 标记块）
6. 清理 `.specify/.spec-kit-init/` 事务目录

**禁止**使用以下形式的通配清理，除非用户确认清单后逐项执行：

```bash
# ❌ 危险示例（不要使用）
rm -rf .specify/ {AGENT_SKILL_DIR}/speckit-* {AGENT_SKILL_DIR}/retro {AGENT_SKILL_DIR}/speckit-quality
```
