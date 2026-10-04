# Handoff: 阶段 D 最小学习引擎（第二步）— gateway 播放器迁移

日期：2026-10-05

## Current task / 本轮任务

阶段 D 第二步：把 `gateway` 的播放路径从 stage 状态机迁移到 LessonPlan / StepSession，其余四课继续走旧路径；保留全部 accessibility 标识符与 UI 测试等价通过。

## Completed / 已完成

- `Sources/Core/LessonPlan.swift`：`StepSession` 增加稳定 `id`（与 LessonSession 共享同一 UUID）；新增 stage↔step 双向适配器（`StepSession(lesson:from:)` / `stageSession(lesson:)`），覆盖全部草稿位置。
- `Sources/Core/LessonSession.swift`：`init` 支持传入 id（默认新建），保证转换前后会话身份不变，结算幂等与草稿清理继续按原 UUID 工作。
- `Sources/App/MatchingView.swift`：改为绑定式 API（matches / matchingSubmitted / matchingSolved），两个播放器共用。
- `Sources/App/StepLessonPlayer.swift`（新）：按 step kind 渲染（场景对话 / 问题 / 图示+讲解 / 连线 / 追问 / 小结 / 结算），进度条按步骤数显示，保留 primary-action、question/challenge-option-*、match-left/right-*、exit-lesson、finish-session、continue-learning、scene-progress、answer-feedback 等标识符与反馈文案。
- `Sources/App/LessonPlayer.swift`：原播放器改名 `StageLessonPlayer`，新增 `LessonPlayer` 分派入口——gateway 走新路径，其余走旧路径。
- `Tests/UITests/LearningUITests.swift`：两处"固定次数点击讲解"改为"点击到连线出现为止"（新路径比旧路径多一个图示步骤，点击次数是实现细节，断言不变）。
- `Tests/CoreTests/StepPlanTests.swift`：新增适配器往返等价用例，覆盖 8 种草稿位置（全新 / 场景中 / 已作答 / 讲解中 / 连线完成 / 追问场景中 / 追问答错 / 完成），断言 id 保持与语义等价。
- `ARCHITECTURE.md`：当前实现表与渐进实施方法同步，写明迁移门与移除条件。

## Decisions made / 本轮关键决策

- 存储零迁移：StepSession 只在播放器内存中使用，持久化仍写 LessonSession（双向适配保证无损往返），草稿、结算、复习全部沿用原逻辑。
- 迁移门按 lesson ID 分派是临时措施，移除条件已写入 ARCHITECTURE（gateway 全绿后逐一迁移其余四课，最后删除旧播放器）。
- 旧 UI 测试的固定点击次数是旧状态机的实现细节，改为条件到达断言，标识符与行为断言不变。
- 图示是独立步骤，比旧状态机多一次推进；恢复时"图示步"映射回旧格式的解释开始位置（与旧播放器视觉一致）。

## Not completed / 尚未完成

- 其余四课（subnet / arp / hop / dns）仍在旧路径，待真机试用后逐一迁移。
- StepSession 尚未直接持久化；旧 stage 状态机与迁移门的移除待全部课程迁移完成。

## Known issues / 已知问题

- 其余三课（arp / hop / dns）无 UI 覆盖（旧路径回归风险低）。

## Verification / 已做验证

- `git diff --check` 通过；静态推演 UI 测试全流程在新路径下的标识符与门控。
- 推送 main 触发 GitHub Actions 运行 37243191142 通过：Core 测试（含适配器往返 8 个位置用例）、真机无签名构建 + IPA、原生 UI 测试（gateway 主课 / 复习 / 退出恢复 / 结算全流程走新播放器）全部成功。
- 首轮失败是测试断言把非讲解阶段的 stale `explanationIndex` 也纳入比较，已改为仅在讲解阶段比较；适配器与播放器代码未改动。
- PRODUCT.md 阶段 D 已标记完成（2026-10-05）。

## Next recommended task / 推荐下一步

真机试用 gateway 完整流程确认体验无差异后，按同样方式迁移 subnet → arp → hop → dns，最后删除 StageLessonPlayer 与分派门，进入阶段 E 可视化试点。
