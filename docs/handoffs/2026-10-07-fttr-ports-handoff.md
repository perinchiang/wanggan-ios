# 接口与 FTTR 答后图解交接

> 历史记录：文案方案与样板课建议已由 [2026-10-07 中文表达修复](2026-10-07-chinese-copy-root-cause-handoff.md) 更新，不作为当前语言范本。原工程验证仅适用于原提交；未完成的图示与布局修复仍保留。

## Current task / 本轮任务

按 Pat 真机反馈修复气泡留白、替换朋友对白与运营商回复，并补上主语「你」；正确作答后讲清一体机、普通路由器和 FTTR 的区别。

## Completed / 已完成

- 三页数据驱动接口图：电源 / PON 光纤口 / LAN 到房间一、房间二、客厅；普通路由器改由 WAN 连上游光猫；FTTR 下行光口经分光器连各房间子设备，子设备提供 WiFi / LAN。
- 正文复用按完整宽度测量的 UILabel，关闭平衡短行；所有对话气泡左右内边距 10 pt。保留正文 / 提问字号层级，跟随系统字号缩放。
- 正确答案之后逐页替换图与气泡，读完才完成 / 发奖；旧完成记录仍完成，新页支持后台恢复。
- 项目版本 0.10.0 build 25；原工作区的六项未提交修改保留，施工在既有 quick-trial-ipa 托管 worktree。

## Decisions made / 本轮关键决策

- Pat 已确认本轮讲 FTTR（光纤到房间），不使用 FTTO 名称。光口一体机不等于已部署 FTTR，不能从朋友对白直接推断。
- 展示 LAN 连房间的网线示例和 FTTR 光纤分支两种结构，避免把 LAN 网口误画成光纤口。接口数 / 排列 / 分光方式为示例，主从设备需要供电。
- 保留课程 / 场景 / 答案稳定 ID；可选 answerExplanation 与可缺省 challengeExplanationID 向后兼容，不改 ledger 存储键。未知页 ID 回到已答题位置，旧 complete 不被重新锁定。

## Not completed / 尚未完成

原生交互由 Pat 真机验收；本轮不运行原生 UI 或模拟器截图。

## Known issues / 已知问题

Windows 无 Swift / iOS 工具链；大字号、小屏与 VoiceOver 尚未真机验收。

## Verification / 已做验证

本地 JSON / YAML 解析、文案精确比对、相邻课程与稳定 ID 比较、文档链接、diff 检查通过；原工作区六项未提交修改保持原状。

- 首次 package `37517654029` 的新增五项 Core 用例及其他回归通过；一处旧讲解数断言仍假设仅有答题前四段而失败。修正为分别检查前后讲解，不调整产品代码，不交付失败候选。
- [package / 37517976435](https://github.com/perinchiang/wanggan-ios/actions/runs/37517976435) success，IPA 源码 `da1406c98eb1d5acdf6b22fb7322220b4cdd9d30`，2 分 18 秒。72 项 Core / 4 项 Web、iPhone Release 编译、上传通过；原生 UI / 模拟器截图明确 skipped。
- IPA ZIP 完整，0.10.0 / 25 / 原 bundle ID，iPhoneOS arm64 可执行文件；lessons.json / 离线 HTML 与候选源码一致，Assets.car 存在。853959 bytes，SHA256 `b850bd5907f98c5d1b394e30089693fe6cde0099d0e95e2878d55b1eddcb150e`。
- IPA、试学清单、完整日志与核验记录位于 `C:/Users/Administrator/Documents/wanggan/outputs/WangGan-0.10.0-build25/`。以下仅补记文档，不把文档 commit 当作 IPA 源码。

## Next recommended task / 推荐下一步

交付已核验的 IPA 与三页图解 / 留白的真机清单，由 Pat 验收换行、接口连线、原位替换与中断恢复。
