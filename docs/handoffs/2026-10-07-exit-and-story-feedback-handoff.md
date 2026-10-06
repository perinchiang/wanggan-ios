# 2026-10-07 退出与故事课试学反馈

## Current task / 本轮任务

处理 Pat 的截图反馈：主动退出不保存本次进度、用户气泡左对齐、朋友家场景重写、完成页简化，以及固定设备图下只展示当前讲解气泡。

## Completed / 已完成

- 确认退出定向清除当前会话草稿，取消保留进度；后台 / 意外中断继续恢复。主线、提前补课、整课复习、短复习均保护其他草稿及历史 / XP。
- 用户气泡位置仍靠右，内部左对齐；拓扑图下用当前气泡替换前一条。
- 朋友场景采用 Pat 指定开场，删除用户内心旁白；改成朋友询问能否直接换普通家用路由器。
- 完成页显示「你已完成」和课程名；版本 0.8.0 build 21，bundle ID 不变。
- 增加 5 项 Core 回归，增加主线 / 整课重学及短复习退出 UI 测试；旧续学用例改为意外终止恢复。smoke 合并运行 5 项流程。
- PRODUCT / ARCHITECTURE / DESIGN / COURSE_GUIDE 同步所属规则。

## Decisions made / 本轮关键决策

- 主动退出代表放弃本次未完成会话；既有成果不是本次草稿，不回滚。
- 比较了“数盒子识别角色”、Wi-Fi 故障和换机决策三种钩子；换机能自然检验功能分工，避免重问前面的数量题或扩大到排障课。
- 保留 home-two-boxes 与正确选项 allinone；旧草稿若选了被删的 ont-only，恢复为同阶段未作答，保留 UUID / 错误次数。不改变 ledger 格式。
- 复用播放器和气泡，不为本课复制页面。普通屏幕固定图位与单气泡，大字号仍可滚动；不宣称完整可访问性已验收。

## Not completed / 尚未完成

原生 smoke 中四项退出 / 恢复 / IPv4 流程通过；故事课定位断言修正后使用 home 专项复核中。Pat 真机体验待反馈。

## Known issues / 已知问题

Windows 无 Swift / iOS 工具链。VoiceOver、最大字号及小屏真机尚未验收；完整 UI 套件本轮不计划重复运行。原工作区六项未提交修改保持原状，施工在已有托管 worktree。

## Verification / 已做验证

本地 JSON / YAML 解析、修改文档链接和 `git diff --check` 通过；4 项 Web 回归通过。课程数据比较确认只有 home-two-boxes 内容变更，其他小节及目录 / 短复习资源保持一致。
- [package #49 / 37508868129](https://github.com/perinchiang/wanggan-ios/actions/runs/37508868129) success，源码 `0da10edcf24047782fa9c3e819aa3a751d572d9b`；触发到完成 1 分 46 秒，67 Core / 4 Web、iPhone Release 编译与 IPA 上传通过。
- IPA 核验：ZIP 完整、0.8.0 / 21 / 原 bundle ID、iPhoneOS arm64 可执行文件、lessons.json / 离线 HTML 与候选源码一致、Assets.car 存在。包为 799046 bytes，SHA256 `dfc4c08f2f6ca287058b51c500a6cf70aef81077aaa99cfe515ef840162e9ae4`。
- IPA、试学清单及日志在 `C:/Users/Administrator/Documents/wanggan/outputs/WangGan-0.8.0-build21/`；[smoke 37509234078](https://github.com/perinchiang/wanggan-ios/actions/runs/37509234078) 在同一源码上执行 5 项检查，4 项通过，故事课图位断言失败：新增上 / 下两行设备扩展了可访问性包围框，minY 不等于固定容器位置。截图确认前两条气泡替换、光纤 / 光猫位置不变；测试改为比较图形中心及气泡顶部位置（不放宽原位替换要求），用 home 专项继续检查未到达的追问 / 完成页。应用源码 / 资源未再修改，不再导出内容相同的 IPA。

## Next recommended task / 推荐下一步

集中运行 package 获得 IPA，再运行 smoke 与检查截图；交给 Pat 按确认退出 / 设备讲解 / 朋友换机 / 完成页清单体验。
