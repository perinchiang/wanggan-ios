# 只保留第一节示例课

## Current task / 本轮任务

Pat 要求删除之前实现的其他课程，以正确的第一节课作为唯一示例，避免旧教案影响后续创作。MacBook 测试脚本 PR 不在本轮范围。

## Completed / 已完成

- 从已合并第一课修正的 b4bad457 创建独立 worktree / `codex/first-lesson-only`，未修改当前主工作区的 `feature/doctor-script`。
- 目录 revision 6 仅保留 `home-two-boxes`；移除其他八节活动课、两节归档课、四道短复习题。第一课内容保持与 b4bad457 一致。
- 移除旧专用 SwiftUI 教学页面、硬编码教案、对应 UI 测试、过时教案及施工交接；正式文档删除保留五课等旧约束。未来故事地图仍为 Draft。
- Core 和通用 Web 图示保留为技术组件，旧存档类型继续解码。回归测试改用无旧课正文的中性结构夹具，不打入 App。
- 修正正常删课时归一化丢弃未知课程草稿的问题；推荐 / 解锁按当前目录过滤，历史 XP、完成记录、草稿与奖励结算保留。
- 候选版本 0.14.0 build 29；bundle ID、存储键、schemaVersion 和第一课稳定 ID 不变。

## Decisions made / 本轮关键决策

第一课采用成人日常疑问「宽带师傅为什么装了两个路由器？」；维持自然的观察与揭晓，不增加官方式限定句。保留已确认的一体机换机与 FTTR 答后故事。删除内容与删除用户记录分别处理；不新增存储迁移框架。

## Not completed / 尚未完成

原生 UI、VoiceOver、大字号、Reduce Motion、意外中断和主动退出的实际设备体验由 Pat 验收；本轮不跑模拟器或原生 UI。

## Known issues / 已知问题

Windows 无 Swift / Xcode 工具链；Core 与 iPhone 编译通过本候选 macOS CI 验证。保留的 Web 技术组件当前未接入示例课，不宣称本轮验证过 WKWebView 运行交互。

## Verification / 已做验证

- 本地 4 项 Web 测试通过。
- 首轮 CI 37608418147：86 Core 中 83 通过；中性测试夹具清理误改了 DNS 配对的 `name` 键对应值，导致三项目录校验失败。第一课与三项历史保留测试通过；已修复夹具映射。该轮未进入打包，无 IPA。
- 最终应用源码 `f56476a74ff0daf35bcf3bbf3cbde8be240ce8a7` 的 [package CI 37608652456](https://github.com/perinchiang/wanggan-ios/actions/runs/37608652456) 成功，耗时 1 分 48 秒：86 Core、4 Web、iPhone Release 编译及资源打包。包含三项删课后历史保留回归。原生 UI / 模拟器 / 截图均 skipped。
- 下载 0.14.0 build 29 未签名 IPA，核对 Info.plist、bundle ID、图标与 Web 资源；包内 lessons.json 与 f56476a Git 对象字节一致，仅有 `home-two-boxes`，归档和短复习列表为空，未包含测试夹具。
- 本地包位于本 worktree 的 `artifacts/WangGan-0.14.0-build29-f56476a/WangGan-unsigned.ipa`（777,992 字节）；SHA-256：`78486825be62654499feb06d66a5f2b56defd4791f75c032ed2fea1a1987d077`。
- 第一课 JSON 与 b4bad457 逐字段一致；目录检查、文档本地链接、`git diff --check` 通过。主工作区仍为干净的 feature/doctor-script，未处理其脚本或 PR。
- 最后的交付记录提交仅修改文档；IPA 与运行检查对应 f56476a，不为记录结果重复消耗构建额度。

## Next recommended task / 推荐下一步

Pat 真机检查：路线只有第一课；讲解回看与中断恢复；主动退出重来；一体机换机与 FTTR 图解；完成后显示 1 / 1，重学不重复发首次奖励。旧安装更新时确认已有 XP 仍在。后续逐课重新设计，不恢复已删除教案。
