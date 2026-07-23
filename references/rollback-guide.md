# 回滚与恢复指南

以下为初始化中途失败时的清理步骤。仅在初始化失败时按需读取。

---

## 失败场景与回滚方式

| 失败场景 | 回滚方式 |
|----------|----------|
| `specify init` 已完成但后续步骤失败 | `.specify/` 目录已创建，保留不变；`{AGENT_FILE}` 中若已注入 `<!-- SDD:...-->` 标记，手动删除标记段即可恢复 |
| `specify init` 本身失败 | 没有任何文件变更，无需回滚 |
| 经验沉淀步骤（阶段 3）已修改 `/speckit-plan` 或 `/speckit-implement` 但后续失败 | 在对应文件的 `<!-- ⚠ 自动追加...-->` 标记处删除注入内容即可恢复 |
| 质量门禁步骤（阶段 4）已修改 `/speckit-implement` 但后续失败 | 在对应文件的 `<!-- ⚠ 自动追加...-->` 标记处删除质量门禁注入内容即可恢复 |
| Bug Extension 步骤（阶段 5）已安装但后续失败 | `.specify/extensions/bug/` 已创建，运行 `specify extension remove bug` 清理；`.specify/bugs/` 目录为空时可直接删除 |

## 完整清理

```bash
rm -rf .specify/ {AGENT_SKILL_DIR}/speckit-* {AGENT_SKILL_DIR}/retro {AGENT_SKILL_DIR}/speckit-quality
specify extension remove bug
# 从 {AGENT_FILE} 中移除 <!-- SDD:START --> 至 <!-- SDD:END --> 段
```