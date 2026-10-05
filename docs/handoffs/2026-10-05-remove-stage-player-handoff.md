# Handoff: 移除旧 Stage 播放器

日期：2026-10-05

## Current task / 本轮任务

用户确认 0.1.4 可以继续后，移除五课已不再使用的旧原生播放器和按 Lesson ID 分派的入口。

## Completed / 已完成

- 删除 `StageLessonPlayer` 所在的 `Sources/App/LessonPlayer.swift`。
- `RootView` 直接打开 `StepLessonPlayer`；删除 `StepLessonPlayer.swift` 顶部的分派包装层。
- 同步 PRODUCT 与 ARCHITECTURE 的当前实现和阶段 D 状态。

## Decisions made / 本轮关键决策

- 保留 Core 的 `LessonSession`、旧草稿格式与 stage↔step 适配器；它们仍承担历史进度恢复、持久化和结算职责，不随旧页面删除。
- 维持五个 Lesson ID、课程内容、bundle identifier、XP 规则与 `project.yml` 版本；下一次交付 IPA 前再按约定升版本。
- 按 Actions 额度约定，本次不单独触发 iOS 工作流或导出 IPA，和下个阶段的改动一起集中验证。

## Not completed / 尚未完成

- 本次删除后的 iPhone 构建和原生 UI 测试尚未运行；0.1.4 CI 通过结果只适用于先前提交。
- 阶段 E 的 `IPv4AddressVisual` 尚未开始。

## Known issues / 已知问题

- `LearningStore` 在课程加载失败时可能清草稿，未知 schema 的恢复路径不足；本次未改存储。

## Verification / 已做验证

- 源码中不再引用 `StageLessonPlayer` 或分派入口；`RootView` 直接使用 `StepLessonPlayer`。
- 检查 `StepSession` 与 `LessonSession` 的双向适配仍在，保存、完成仍经过现有 `LearningStore`；已有 Core 测试覆盖五课旧草稿往返，尚未在本提交运行。
- 本地 `git diff --check` 通过。Windows 环境无 Swift / Xcode 工具链，未执行编译或模拟器测试。

## Next recommended task / 推荐下一步

开始阶段 E：只为 `IPv4AddressVisual` 做本地 HTML / WKWebView 试点，先接入两组地址与前缀参数和一项实际教学交互；实现后先提升版本，再集中运行 Core、Web、原生 UI 与打包验证并导出下一份 IPA。
