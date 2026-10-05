# Handoff: gateway 答题反馈可见性与按需运行 CI

日期：2026-10-05

## Current task / 本轮任务

根据真机反馈，让 gateway 提交答案后自动滚动到新出现的反馈；减少 GitHub Actions 额度消耗。

## Completed / 已完成

- `StepLessonPlayer` 在首题或追问提交后滚动到反馈卡片；练习重试后仍回到题目。
- UI 测试增加反馈正文位于固定按钮上方、无需手动滑动的断言与截图。
- iOS 工作流改为仅手动触发；AGENTS、README、ARCHITECTURE 同步说明阶段性验证规则。

## Decisions made / 本轮关键决策

- 日常提交积累改动，不自动构建或导出 IPA；阶段性验收或确有需要时手动运行完整流程。
- 尚未交付新 IPA，因此版本保持 0.1.3（build 4）；下次交付前再提升版本号。

## Not completed / 尚未完成

- 修正后的 UI 测试尚未运行；新的反馈滚动效果尚未通过模拟器截图或真机验收。
- 其余四课仍在旧播放器，等待 gateway 的真机验收后逐课迁移。

## Known issues / 已知问题

- 首次手动 CI 运行 37246052479 的新测试用了不唯一的辅助标识，同时匹配反馈标题和正文而失败。测试已改为定位正文；未立即重跑，以遵守 Actions 额度规则。
- 课程加载失败可能清草稿、未知 schema 恢复路径缺失等既有风险仍在。

## Verification / 已做验证

- `git diff --check` 通过；检查工作流仅含 `workflow_dispatch`。
- 首次手动 CI 的 Core 测试和 iPhone 无签名构建通过；三项 UI 测试中两项通过，一项因测试定位歧义失败。此结果不证明修正后提交通过；没有可交付的新 IPA。

## Next recommended task / 推荐下一步

积累后续独立改动；到阶段性验收时先提升版本号，再手动运行完整 CI，检查答错反馈截图并交付新 IPA 给真机验证。gateway 通过真机完整流程后，开始逐课迁移 subnet、arp、hop、dns。
