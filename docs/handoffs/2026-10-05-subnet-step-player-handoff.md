# Handoff: subnet 播放器迁移，等待集中验收

日期：2026-10-05

## Current task / 本轮任务

继续阶段 D 的逐课迁移：将 `subnet` 从旧 stage 播放器切换到 StepLessonPlayer，保留旧进度与课程内容；按用户要求暂不运行 GitHub Actions 或导出 IPA。

## Completed / 已完成

- 分派入口将 `subnet` 接到 StepLessonPlayer；`gateway` 路径不变，`arp`、`hop`、`dns` 仍走旧播放器。
- Core 测试扩展到 `subnet`，覆盖完整通关、追问答错重试、新旧状态机等价与旧草稿各位置往返。
- PRODUCT、ARCHITECTURE 更新当前迁移状态。

## Decisions made / 本轮关键决策

- 只切换播放路径，不改五课内容、稳定 ID、XP 规则或存储 schema；StepSession 仍经旧 LessonSession 格式保存。
- 先积累改动，阶段性验收时再手动触发一次完整 Actions；交付 IPA 前再提升版本号。

## Not completed / 尚未完成

- `subnet` 的 Core 测试、iOS 构建与原生 UI 测试尚未运行；新路径尚未真机验收。
- `gateway` 的答错反馈滚动修正也仍待运行验证。
- `arp`、`hop`、`dns` 尚未迁移；旧播放器及分派门仍保留。

## Known issues / 已知问题

- 课程加载失败可能清草稿、未知 schema 恢复路径缺失等既有风险未在本轮处理。

## Verification / 已做验证

- `git diff --check` 通过；`lessons.json` 的五个 Lesson ID 保持原顺序，课程内容未修改。
- Windows 本机无 Swift / iOS 工具链；本轮没有运行 Core、模拟器或真机测试，也没有新 IPA。

## Next recommended task / 推荐下一步

在阶段性集中验收时运行 Core 与原生 UI 测试，重点看 `gateway` 答错反馈可见性，以及 `subnet` 的答题、恢复、复习和结算。通过并在真机确认后，继续逐课迁移 `arp`、`hop`、`dns`。
