# 2026-10-07 快速试学 IPA

## Current task / 本轮任务

Pat 希望快速获得新版第一课 IPA，由 Agent 提供试学清单、Pat 真机体验后反馈问题。

## Completed / 已完成

- 从远端 `fde8717` 的 build 19 建立隔离分支 `codex/quick-trial-ipa`，原工作区六项未提交修改保留。
- 新增手动 `package` 模式：Core / Web 检查、iPhone Release 编译与 IPA 上传；跳过模拟器 / 原生 UI / 截图。
- 保留 `quick`、`smoke`、专项 scope 与 `full`；完整验收仍使用 `full`。
- 候选为 0.7.0 build 20，bundle ID 不变；应用源码和课程资源逐项沿用 `fde8717`。
- README 提供手动入口，验证范围由 ARCHITECTURE 维护。
- 源码候选 `ab8bc71c3995b0236fffd2efa8e78c18114550fc` 已 push 到 `feature/home-network-native`，手动 package 构建成功；IPA 和试学清单已下载 / 编写到 `C:/Users/Administrator/Documents/wanggan/outputs/WangGan-0.7.0-build20/`。

## Decisions made / 本轮关键决策

快速包服务真机试学，不把省略 UI 测试称作完整验收。只改工作流、build 号及相关文档，不修改故事课实现或学习数据。

## Not completed / 尚未完成

- Pat 真机反馈：故事连贯性、滚动稳定、当前设备高亮、退出恢复及历史进度保护。
- 本候选原生 UI、模拟器截图及完整回归没有运行。

## Known issues / 已知问题

本包不含当前候选的原生 UI / 模拟器截图证据；最大字号拓扑与完整 VoiceOver 仍待体验。本地 Windows 无 Swift / iOS 工具链。

## Verification / 已做验证

- 本地 YAML 解析、8 个 scope × 7 个步骤的 56 项路由检查、版本号、修改文档链接及 `git diff --check` 通过；4 项 Web 回归通过。
- 与 `fde8717` 比较：`Sources/`、`Resources/` 没有改动。
- [Actions 37505413864 / #48](https://github.com/perinchiang/wanggan-ios/actions/runs/37505413864) success，源码 `ab8bc71`；触发 17:40:50 UTC，完成 17:42:18 UTC，总计 1 分 28 秒。62 Core / 4 Web 测试通过，iPhone Release 编译 / IPA 上传成功，模拟器 / 原生 UI / 截图步骤确实跳过。
- 本地核验：ZIP 完整、Info.plist 为 0.7.0 / 20 / `com.perinchiang.wanggan`、iPhoneOS arm64 可执行文件有效；lessons.json 与候选内容一致，新屋对话 / `matchingEnabled=false` 存在；离线 HTML 与源码一致，Assets.car 随包存在。
- IPA：`WangGan-0.7.0-build20-unsigned.ipa`，793106 bytes；SHA256 `464d98e49a5791bcfe15d5aba2f0773058d01bbdd46715da24c93bc486efd520`。日志、`ci-run.json`、`verification-summary.json` 与试学清单同目录保存。
- 原工作区六项未提交修改仍保留；随后只补记文档，不将文档提交冒称为本次 IPA 的源码 commit。

## Next recommended task / 推荐下一步

交付 IPA 和试学清单，收集 Pat 的具体步骤 / 现象 / 预期，再按问题做小范围修正；阶段性使用完整验收。
