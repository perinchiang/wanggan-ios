# Handoff: 阶段 A 文档基线 + 轻量交接机制

日期：2026-10-05

## Current task / 本轮任务

1. 审查现有 MVP（五课、学习/复习/奖励逻辑、视觉、CI），沉淀五份长期文档：`PRODUCT.md`、`DESIGN.md`、`COURSE_GUIDE.md`、`ARCHITECTURE.md`、`AGENTS.md`，并按需更新 `README.md`。
2. 建立轻量 Agent 交接机制（`docs/handoffs/` + AGENTS.md 规则）。

## Completed / 已完成

- 五份文档 + README 更新全部落盘：状态用语统一为「已实现 / 已确认原则 / 计划中 / Draft / 暂缓」。
- 9 章 42 节课程地图在 `COURSE_GUIDE.md` 明确为 Draft，编号不是持久 ID，不冻结数量与顺序。
- HTML 可视化长期架构保留，但第一版最小试点仅 `IPv4AddressVisual`，不建消息总线 / 插件系统。
- `DESIGN.md` 写入 Network-native Motion Language 完整语义表（Link/Activity、Up/Down、Packet Forward/Drop/Timeout、Broadcast、DNS Resolve、TCP Handshake 等）。
- `AGENTS.md` 删除个人交互偏好，只保留项目级约束；加入 handoff 规则。
- 仓库外旧版《下一季度开发路线》已删除，PRODUCT.md 中对其的引用已移除。
- 业务代码、课程 JSON、构建配置零改动。

## Decisions made / 本轮关键决策

- 演进路线定为 A–H 八个阶段（A 文档基线 → B 数据保护 → C 课程目录 → D 最小学习引擎 → E 可视化试点 → F 短复习与掌握证据 → G 分批补课 → H 成长体验），按完成条件推进，不按日历。
- 原五课是教学 vertical slice，可作为应用课移动，不得删除历史学习成果；五个稳定 Lesson ID 是兼容基线。
- 复习更新与奖励资格必须分离（阶段 B 的核心问题：复习记录更新目前绑定「本次是否获得 XP」）。

## Not completed / 尚未完成

- 阶段 B 之后的所有路线阶段均未开工。

## Known issues / 已知问题

- 复习记录更新绑定 XP 发放：同一天再次答错不更新复习安排；部分 Challenge 更接近即时回忆，迁移性不足。
- 整次 CI 最近一次显示 cancelled，但核心测试、真机编译、UI 测试和 IPA 导出步骤实际成功。
- Windows 本机无 Swift / iOS 工具链，运行验证依赖 macOS CI。

## Verification / 已做验证

- `git diff --check` 通过；文档链接、状态标注与 Draft 边界抽查通过。
- `git status` 确认改动仅限文档（业务代码、lessons.json、project.yml 未动）。

## Next recommended task / 推荐下一步

阶段 B 数据保护：分离「复习记录更新」与「当日奖励资格」，修复同一天再次答错不更新复习安排的问题；保留旧进度格式与迁移验证，确保原五课行为不回归。
