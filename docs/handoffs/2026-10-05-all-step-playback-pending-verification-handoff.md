# Handoff: 五课播放器切换已落盘，等待集中验收

日期：2026-10-05

## Current task / 本轮任务

按课将 `subnet`、`arp`、`hop`、`dns` 切换到 StepLessonPlayer，积累提交后再手动运行一次 Actions；本轮不导出 IPA。

## Completed / 已完成

- 五个现有 Lesson 均分派到 StepLessonPlayer；旧播放器暂留作验收前回退路径。
- Core 用例扩展为五课逐一覆盖完整通关、追问答错重试、新旧状态机等价与旧草稿各位置往返。
- PRODUCT 与 ARCHITECTURE 同步当前代码和待验证状态。

## Decisions made / 本轮关键决策

- 每课单独提交，保持课程内容、Lesson ID、XP 规则和持久化格式不变。
- 按用户额度偏好，本批不自动运行 Actions；交付 IPA 前再提升版本号。
- 旧播放器和分派逻辑须等集中验证通过后才移除。

## Not completed / 尚未完成

- 本批改动的 Core 测试、iPhone 构建、原生 UI 测试和真机验收均待执行；不能把此前的 CI 结果用于本批代码。
- `gateway` 答错反馈自动滚动的修正也待验证。
- 旧播放器尚未移除，阶段 E 可视化试点尚未开始。

## Known issues / 已知问题

- ARP、hop、DNS 目前没有对应的原生 UI 回归用例；集中验收至少要补代表性流程或真机逐课检查。
- 课程加载失败可能清草稿、未知 schema 恢复路径缺失等既有风险未在本轮处理。

## Verification / 已做验证

- `git diff --check` 通过；课程 JSON 与五个稳定 Lesson ID 未修改；Windows 本机无 Swift / iOS 工具链。
- 本轮未运行 Actions，未生成或交付新版 IPA。

## Next recommended task / 推荐下一步

在下一次阶段性验收中提升版本号并手动运行完整 Actions，一次验证本批 Core 与原生 UI 测试；检查 `gateway` 反馈截图及 `subnet` 续学，再由用户真机走完五课关键路径。通过后移除旧播放器，然后进入阶段 E 的 IPv4AddressVisual 试点。
