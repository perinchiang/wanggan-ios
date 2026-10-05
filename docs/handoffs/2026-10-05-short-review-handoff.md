# F：一题短复习与证据试点

## Current task / 本轮任务

继续 F，在网关 / DNS 两个知识点试点短复习；记录 Pat 关于独立子网掩码入门课的要求，暂不制作新课。

## Completed / 已完成

- 新增数据驱动 ReviewItem、ShortReviewSession、ReviewAttempt 和解释性证据状态。
- 网关 / DNS 各两种原创场景，每次一题；错误解释、提示、重试、退出恢复、完成后轮换。
- 复习页保留原整课入口；主线、整课复习、短复习草稿隔离，短 / 整课共用每日 +5 XP。
- ledger v1 添加可选字段，旧记录不凭空获得掌握证据；课程加载失败不清理历史。
- 9 项短复习 Core 回归、2 项新原生流程；手动 workflow 的 review 范围另含原完整学习 / 整课复习隔离回归。
- 项目候选版本 0.3.0 build 7，个人页从 Bundle 读取版本。
- COURSE_GUIDE 记录独立子网掩码入门课，原五课及 ID 保留。

## Decisions made / 本轮关键决策

一题试点先验证轻复习体验与证据，不扩展到全部知识点或复杂算法。旧整课草稿继续走原播放器，短复习不会覆盖它；无提示首次正确与提示 / 重试后正确分开。延迟证据需至少 24 小时并跨日且换场景族。

## Not completed / 尚未完成

完整 Mastery、所有课程短复习、新入门课、成就 / 主题扩展均未做。

## Known issues / 已知问题

Windows 没有 Swift / Xcode，本地内容检查不证明编译或 iOS 运行；真机、VoiceOver、大字号与后台恢复仍须分别验收。0.2.0 的运行证据不能用于本轮候选。

## Verification / 已做验证

课程 JSON 的 4 项短复习及原五课引用检查通过；git diff --check 通过。集中 macOS Core / iPhone / 原生 UI 验证待执行，未交付新 IPA。

## Next recommended task / 推荐下一步

通过集中验证后试学短复习，收集是否真的更轻及反馈是否清晰；再按 G 分批补基础课，优先解决掩码先修缺口，具体拆分不冻结 Draft 地图。
