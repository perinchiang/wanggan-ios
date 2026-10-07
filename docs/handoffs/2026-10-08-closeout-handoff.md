# 0.17.0 第一课与 Mac 工作流收尾

## Current task / 本轮任务

Patrick 要求完成本日开发的 Git 收尾。整理已部署的七题第一课、短题播放器、进度兼容与 Mac 开发流程，提交代码、推送当前分支并提供草稿 PR。

## Completed / 已完成

- d60645d：Mac 环境检查脚本、优先复用已启动 Simulator、PR 的 Core / Web 与快速编译配置。
- af54882：连续短题播放器、七道生活化题目「1-1」、反馈覆盖布局、schema 3 与旧草稿兼容、测试与正式项目文档。
- README 标注版本与源码提交，七题交接同步收尾入口。当前分支为 codex/mac-workflow-audit，开发基线为 feature/home-network-native / 385a3bc。

## Decisions made / 本轮关键决策

手机上已安装的 0.17.0 build 34 对应功能提交 af54882；收尾只更新 Git 与文档，沿用已验证的源码和版本。安装的签名 App、备份、日志、截图与 xcresult 保留在忽略目录 build/；Git 提交包含源码和验证记录。

旧 handoff 保留各自施工时的事实，当前状态以本文件和七题交接为准。产品、课程、设计与架构规则继续由正式项目文档维护。

## Not completed / 尚未完成

Patrick 新版真机教学与手感验收、完整 VoiceOver；整体配色、动画和触感优化另待反馈。草稿 PR 的合并及远端 CI 验收不属于本地已完成的验证。

## Known issues / 已知问题

旧六题 revision 1 草稿保留，内容不兼容时需用户明确确认退出后开始新版；完成记录、其他草稿与 XP 保留。末尾单题队尾间隔继续沿用既有实现假设，详情见 COURSE_GUIDE。

## Verification / 已做验证

- 当前 build 34：86 项 Core 测试、两项针对性原生 UI 测试通过；复用单个 iPhone 17 Pro Simulator，禁用并行。日志与截图见 build/lesson-copy-cleanup/。build 33 的全量九项 UI 结果单独记在 [七题交接](2026-10-08-everyday-questions-handoff.md)，不视为本次重跑。
- 真机签名构建、签名与资源校验、Wi-Fi 覆盖安装和普通启动成功；340 XP、11 条完成、6 个草稿、52 条结算记录及原始备份保留，见 build/lesson-phone-update/。安装启动与教学体验验收分别记录。
- 本次收尾：doctor 默认检查 10 项通过；shell 语法与工作流 YAML 解析通过，选择脚本仍返回同一个已启动 Simulator。没有重新编译或重跑已通过的课程测试；本轮 Git 操作未改产品源码。
- 暂存内容检查、git diff --check 与文档本地链接检查通过；推送后的分支与 PR 状态以 GitHub 和本任务附件为准。

## Next recommended task / 推荐下一步

Patrick 试学手机上的「1-1」，据真实体验调整题目与填空手感，再确定课名。
