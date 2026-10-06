# 2026-10-07 快速试学 IPA

## Current task / 本轮任务

Pat 希望快速获得新版第一课 IPA，由 Agent 提供试学清单、Pat 真机体验后反馈问题。

## Completed / 已完成

- 从远端 `fde8717` 的 build 19 建立隔离分支 `codex/quick-trial-ipa`，原工作区六项未提交修改保留。
- 新增手动 `package` 模式：Core / Web 检查、iPhone Release 编译与 IPA 上传；跳过模拟器 / 原生 UI / 截图。
- 保留 `quick`、`smoke`、专项 scope 与 `full`；完整验收仍使用 `full`。
- 候选为 0.7.0 build 20，bundle ID 不变；应用源码和课程资源逐项沿用 `fde8717`。
- README 提供手动入口，验证范围由 ARCHITECTURE 维护。

## Decisions made / 本轮关键决策

快速包服务真机试学，不把省略 UI 测试称作完整验收。只改工作流、build 号及相关文档，不修改故事课实现或学习数据。

## Not completed / 尚未完成

- 本候选 CI / IPA 核验正在准备，尚不称作已通过。
- Pat 真机反馈：故事连贯性、滚动稳定、当前设备高亮、退出恢复及历史进度保护。

## Known issues / 已知问题

本包不含当前候选的原生 UI / 模拟器截图证据；最大字号拓扑与完整 VoiceOver 仍待体验。本地 Windows 无 Swift / iOS 工具链。

## Verification / 已做验证

- 本地 YAML 解析、8 个 scope × 7 个步骤的 56 项路由检查、版本号、修改文档链接及 `git diff --check` 通过；4 项 Web 回归通过。
- 与 `fde8717` 比较：`Sources/`、`Resources/` 没有改动。
- 候选会正常 push 到 `feature/home-network-native` 并手动触发 `package`；运行结果与安装包核验在 CI 完成后补记。此前 build 19 的测试不代表本候选已通过。

## Next recommended task / 推荐下一步

交付 IPA 和试学清单，收集 Pat 的具体步骤 / 现象 / 预期，再按问题做小范围修正；阶段性使用完整验收。
