# Handoff: 五课 Step 播放器集中验收与 0.1.4 安装包

日期：2026-10-05

## Current task / 本轮任务

为五课播放器迁移补原生 UI 验证，集中运行一次 macOS CI，导出 0.1.4（build 5）供 iPhone 试用。

## Completed / 已完成

- UI 测试增加 `subnet`、`arp`、`hop`、`dns` 的答题后退出恢复、连线、追问和首次结算流程；`gateway` 原有完整流程与答错反馈可见性测试保留。
- 仅在 UI 测试启动参数下预置前置课程完成记录，缩短测试时长；普通运行不触发。
- `project.yml` 升为 0.1.4（build 5），bundle identifier 保持 `com.perinchiang.wanggan`。
- 运行 37248112960 通过，下载未签名 IPA 及验证截图。

## Decisions made / 本轮关键决策

- 本版先保留旧 StageLessonPlayer 作为回退路径，真机验收后再移除。
- 本轮 Actions 仅手动触发一次；后续普通提交仍不自动构建或导出 IPA。

## Not completed / 尚未完成

- iPhone 实际安装、答错反馈滚动观感、五课旧进度保留与完整流程，仍待用户真机试用。
- 阶段 E 的 IPv4AddressVisual 尚未开始。

## Known issues / 已知问题

- 已交付的 0.1.4 IPA 在“我的”页仍写着 0.1.3；安装包自身 Info.plist 是 0.1.4。源码现已改为读取安装包版本，需随下一次 IPA 发布后才会在手机上生效。
- 课程加载失败可能清草稿、未知 schema 恢复路径缺失等既有风险未在本轮处理。

## Verification / 已做验证

- 提交 `8982dd3` 的 Actions 运行 37248112960：Core 测试、真机目标无签名构建和 7 项 iPhone 15 Pro 模拟器原生 UI 测试均通过；截图包含答错反馈及四课结算。
- 下载的 `WangGan-unsigned.ipa` 内 Info.plist 为 0.1.4 / build 5，bundle identifier 未变；`lessons.json` 与 `Assets.car` 存在。
- 本地 `git diff --check` 通过。模拟器和包检查不等于真机验收。

## Next recommended task / 推荐下一步

用户在 iPhone 上以同一签名账户覆盖安装，重点确认既有 150 XP 与五课完成记录仍在、gateway 答错反馈会进入视野、各课可退出续学和完成。通过后移除旧播放器及分派门，再进入阶段 E 可视化试点。
