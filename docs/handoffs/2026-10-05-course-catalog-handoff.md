# Handoff: 阶段 C 课程目录 — Course / Chapter 包装

日期：2026-10-05

## Current task / 本轮任务

引入 Course / Chapter 目录模型，解锁与推荐从 SwiftUI 数组下标迁移到 Core 的稳定 ID 策略；为后续按 Draft 地图新增课程做准备，不撤销原有成果。

## Completed / 已完成

- `Sources/Core/Lesson.swift`：新增 `Chapter`（id / title / orderedLessonIDs）与 `Course`（id / revision / title / chapters）；`LessonCatalog` 改为 course + lessons 结构，提供 `orderedLessonIDs` 与 `lessons(in:)`，校验章节恰好覆盖每一课、ID 唯一。
- `Sources/Core/ProgressLedger.swift`：新增 `isUnlocked(_:in:)`——完成记录优先（已完成的课保持可回看），否则线性前驱解锁。
- `Resources/lessons.json`：重构为 course（id `wanggan-network-intuition`、revision 1）单章 `first-look`（"第一章 · 数据如何出发"），五课 ID 与内容不变。
- `Sources/App/AppStore.swift`：解锁 / 推荐 / 草稿归一化全部改用 `orderedLessonIDs`；暴露 `chapters` 与 `lessons(in:)`。
- `Sources/App/RootView.swift`：学习路线按章节分区渲染，进度条保留。
- `.github/workflows/ios.yml`：push 增加 paths 过滤（Sources / Tests / Resources / 工程文件 / workflow 自身），纯文档提交不再触发 CI；仍可 workflow_dispatch 手动触发。
- 测试：新增目录覆盖校验、线性解锁链、插入新课后已完成课保持解锁 + 推荐前移 3 个用例。
- `ARCHITECTURE.md` 当前实现表与 CI 描述同步；移除"数组前驱解锁不适合重排"风险条目。README 补充 CI 触发说明。

## Decisions made / 本轮关键决策

- 单章起步：模型支持多章节，但本轮内容仍是一个章节，不按 Draft 地图拆章（地图是 Draft，不冻结）。
- 解锁策略进 Core：完成记录优先于线性前驱，插入基础课只改变推荐建议，不重新锁定已完成课。
- 存储零迁移：ProgressLedger 只按 Lesson ID 存储，目录结构变化不影响已有进度；schemaVersion 仍为 1。
- 为省 CI 额度，纯文档变更不触发构建；代码 / 资源 / 工程文件变更或手动触发才跑。

## Not completed / 尚未完成

- `prerequisiteChapterIDs`、`progressionPolicy` 等 Draft 字段未引入（按需再加）。
- 多章节拆分、插入新课未做——等阶段 G 分批补课时使用。

## Known issues / 已知问题

- `LearningStore` 课程加载失败时可能清草稿、未知 schema 恢复路径等基线风险仍待后续处理。

## Verification / 已做验证

- `git diff --check` 通过；JSON 重构经 python 往返解析确认五课 ID 与内容未变。
- 推送 main 触发 GitHub Actions 运行 37239205507 通过：Core 测试（含新增 3 个用例）、真机无签名构建 + IPA、原生 UI 测试全部成功。首轮曾因测试断言写反失败（subnet 在插入后应保持解锁），已修正断言并重跑通过。
- PRODUCT.md 阶段 C 已标记完成（2026-10-05）。

## Next recommended task / 推荐下一步

进入阶段 D 最小学习引擎：先适配一课为 Step，复用现有原生组件，新内容不必复制专用页面。
