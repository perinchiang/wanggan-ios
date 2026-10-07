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
- Core 新增内容移除后旧 v1 恢复、开始示例课与重复结算、旧复习证据保留三项回归；运行结果待本候选 package 检查。
- 第一课 JSON 与 b4bad457 逐字段比较、内容目录和文档链接检查、`git diff --check` 在提交前执行。

## Next recommended task / 推荐下一步

完成本候选 package 核验，交付 Pat 真机检查第一课；后续逐课重新设计，不恢复已删除教案。
