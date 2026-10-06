# 0.6.2：无题基础课与即时语义配对

## Current task / 本轮任务
Pat 要求删除「联系朋友 / 联系小林」等突兀题目，配对不画线；任一侧起选，选齐一对自动判定，正确绿，错误红并自动恢复，不能要求清空 / 重置或惩罚错选。此前已确认前三课轻松观察优先，13 用线性演示。

## Completed / 已完成
- 前三课实际 Step 编排只有观察与总结，移除预测、匹配、Challenge 门控；最后观察直接完成学习。
- 位演示逐步展示 0 → 8 → 12 → 13 → 9 → 255，计算式保留可访问描述；提供 Reduce Motion / 静态呈现。
- 五个既有课程使用不画线的即时配对；选中深色、正确绿色锁定、错误局部红色和轻微移动，自动恢复或直接改选，没有检查 / 清空按钮。
- Core 判定每对，只持久化正确项；新错选不计入 mistakes。原错误历史保留。
- 可选 observationCompleted 字段区别观察完成与答题通过；完成仍由 Core 验证并幂等结算。
- 升级 0.6.2 build 15。原主线 / 复习草稿结构、稳定 ID、历史 XP 保留。

## Decisions made / 本轮关键决策
- 旧 JSON 的前三课 question / matching / challenge 仅保留为现有内容结构的兼容数据，播放器不生成这些步骤，不展示朋友 / 小林配对。
- 旧基础草稿保留会话 ID 和观察进度；已看完观察的旧匹配 / Challenge 草稿转为总结并按同一 ID 结算，不伪造匹配 / Challenge 正确标记。
- 旧匹配草稿保留正确对、丢弃错误连线，不清除旧 mistakes。
- 新配对组件为 Pilot；不宣称所有后续课程都必须使用它。无题编排目前只用于 foundation 配置，尚未推广任意可选题 DSL。

## Not completed / 尚未完成
- 首两课完整新分镜（尤其地址字段二进制逐组展开）尚未实现；本轮保留既有观察图，修正标题 / 引入。
- 五个既有课程的题目适配仍需逐课教学评审，当前只改变配对行为。
- 真机试学、完整 VoiceOver、真实系统 Reduce Motion 切换待验收。

## Known issues / 已知问题
- App 当前仍强制浅色，不能宣称完整深色主题验收。
- 已查看最大字号静态截图：128 / 64 / 32 / 16 位值标签在八列图中竖向折行。流程与算式可见性通过，不代表图表的最大字号布局已验收；后续需要纵向替代布局。本轮交付的普通字号图表正常。
- 保持原短复习与历史课程兼容数据，不扩展 Mastery / 调度系统。

## Verification / 已做验证
- Windows：4 项 Web 测试通过，JSON 解析与 diff 检查通过；本机没有 Swift / iOS 工具链。
- 新 Core 用例覆盖即时判断、错选无惩罚、正确对保留 / 恢复、旧错误草稿迁移、无题完成与奖励幂等。
- 原生 foundation scope 包含前三课、Hop 双向即时配对 / 错选自动恢复 / 部分成功重启恢复，以及最大字号静态二进制演示；首轮 Actions 37433310553：56 Core、4 Web、device / simulator 编译通过，Hop 与前两课原生 UI 通过，二进制两项失败。实际可访问树把 Surface 的标识传播到子算式，覆盖 foundation-bit-equation；移除外层标识，保留算式自己标识后待复测。已查看首轮深色选中、红色反馈、绿色锁定与二进制开始阶段真实截图；正确卡片文字改为深色以改善可读性，五课提示去掉“连到”。

## Next recommended task / 推荐下一步
由 Pat 真机试学 0.6.2 build 15 的前三课与配对反馈，再决定第一 / 二课分镜是否继续调整；大字号图表后续提供纵向替代。

### 最终运行证据

- App 源码：`a1d565862a45e934302e0d77c03245b316900843`，0.6.2 build 15。
- [Actions 37435257801](https://github.com/perinchiang/wanggan-ios/actions/runs/37435257801) success：56 Core、4 Web、iPhone Release / simulator 编译、5 原生 UI 全部通过。
- 5 UI：前三课无题完成（第二课回看 / 重启恢复）、Hop 两侧起选 / 错配自动恢复 / 正确项部分恢复 / 自动完成、最大字号静态 13 演示流程。共 225.972 秒实际测试，不等于整个 CI 用时。未重跑其他课程 UI 全套。
- 已查看实际截图：深色起选、红色不匹配、绿色正确对、普通字号 8 + 4 + 1 = 13、最大字号静态算式。最大字号位值标签折行限制如上。
- IPA：`C:/Users/Administrator/Downloads/WangGan-0.6.2-build15-unsigned.ipa`（742770 bytes）；SHA256 `a04c7697b2bc77816ec581a55426cf51e991ff7c309864f39b2aea79269abe86`。已解析 Info.plist 确認 0.6.2 / 15 / com.perinchiang.wanggan，核对 lessons.json 与本轮源码一致及可执行文件、Web 资源、Assets.car。
- 日志与截图：`C:/Users/Administrator/Downloads/WangGan-0.6.2-build15-CI-37435257801/verification/`。首轮失败证据另保留在 `C:/Users/Administrator/Downloads/WangGan-0.6.2-CI-37433310553/verification/`。
- 实体 iPhone、完整 VoiceOver、真实系统 Reduce Motion 切换尚未验收；未把观察完成虚构为首次独立作答。
