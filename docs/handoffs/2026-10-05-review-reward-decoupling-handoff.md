# Handoff: 阶段 B 数据保护 — 复习更新与奖励资格分离

日期：2026-10-05

## Current task / 本轮任务

修复 `ProgressLedger.complete` 中复习状态更新绑定「当天是否发放 XP」的问题：同日零奖励的错误作答不更新复习调度（ARCHITECTURE.md 原基线风险第一条）。

## Completed / 已完成

- `Sources/Core/ProgressLedger.swift`：复习状态（lastPracticedAt / lastMistakes / reviewLevel / nextReviewAt）在每次有效完成后独立更新，不再依赖 `reward > 0`。
- `Tests/CoreTests/LearningTests.swift` 新增 3 个用例：同日零奖励错误仍重置调度、同日重复正确不能连续推进阶梯、先错后对同日保持最短间隔。
- `ARCHITECTURE.md`：「当前复习」段落更新为新行为；「已识别的基线风险」移除已修复条目。

## Decisions made / 本轮关键决策

- 奖励规则不变：首次 +30，每本地自然日首次练习 +5，同日重复 0，会话幂等结算不变。
- 复习阶梯每个本地自然日最多推进一级（首次练习且无错误时）；同日多次正确不重复升级。
- 错误（无论当天是否已发奖）立即重置 reviewLevel 为 0、nextReviewAt 为次日。
- 先错后对的同日重练不立即恢复间隔，保持次日到期（不跳到最长间隔）。
- `lastPracticedAt` 语义扩展为「最近一次有效练习」，奖励的同日判定结果不变；存储 schema 仍为 v1，无需迁移。

## Not completed / 尚未完成

- 本机无 Swift / iOS 工具链，`swift test` 与 UI 测试未运行，需 macOS CI 验证。
- PRODUCT.md 阶段 B 完成状态未标记（等 CI 通过后再更新）。

## Known issues / 已知问题

- 静态推演确认现有 13 个 Core 测试与 3 个 UI 测试应无回归，但这不是运行证据。
- 其余基线风险仍在：`LearningStore` 课程加载失败时可能清草稿；未知 schema 缺少受保护恢复路径；数组前驱解锁不适合课程重排。

## Verification / 已做验证

- `git diff --check` 通过；逐用例推演现有测试与新增测试的行为（静态，未运行）。

## Next recommended task / 推荐下一步

push main 触发 GitHub Actions：确认 Core 测试、UI 测试与 IPA 导出通过后，把 PRODUCT.md 阶段 B 标记为完成，再进入阶段 C 课程目录。
