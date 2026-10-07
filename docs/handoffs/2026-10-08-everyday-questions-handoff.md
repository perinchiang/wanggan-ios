# 第一课七道生活化短题

## Current task / 本轮任务

Patrick 同意把讨论中的七题接入第一课。课程先用「1-1」，题目稳定后再定名；按生活直觉与题目之间的关联推进。

## Completed / 已完成

`home-two-boxes` 接入无线局域网 → Wi-Fi → 有线连接 → 路由器 → 光猫 → 宽带服务 → Wi-Fi 与互联网可用性的七题序列，前六题选词填空、末题单选。按 Patrick 后续反馈，去掉「猜一下也没关系」及第 4 题的开场说明，第 5 题去掉「在这种接法中」后直接进入问题。第 2 题使用已出现的 Wi-Fi 名称作为掌握题，其余首次引入关系的题允许猜。

暂名「1-1」，practice revision 2、目录 revision 9；版本候选 0.17.0 build 34，已按 Patrick 要求覆盖安装并启动于 Pathos。PRODUCT / COURSE_GUIDE 同步先编题再定名与直觉优先原则，第一课审稿、README、架构和开发说明同步现状。底部反馈继续覆盖展开，复用现有交互。提示精简仅改题干与展示文案，沿用题目 ID、答案、角色与 revision。

## Decisions made / 本轮关键决策

新题采用新语义 ID，不将旧六题的答案映射到新版。沿用现有不兼容保护：保留旧短题草稿并显示更新提示，用户点左上角退出并确认后再开课进入新版；提示补充这个具体入口。旧故事载荷与播放器继续服务已有草稿。稳定 Lesson ID、存储键、schema 3 与 XP 规则不变。

匹配机制回归改用中性 Core 夹具，课程改题后仍保护三次预算、恢复与队尾，不为题型覆盖加入匹配题。实施与真机部署时使用 385a3bc 上的未提交工作区，没有导出 IPA。Patrick 随后要求收尾，功能代码提交为 af54882，Git 交付记录见 [收尾交接](2026-10-08-closeout-handoff.md)。真机覆盖部署沿用原应用标识和签名 Team，无卸载、无测试或重置参数。

## Not completed / 尚未完成

新版 Patrick 真机试学、实际用时与教学效果；整体交互、动画、配色、触感优化；完整 VoiceOver。iPhone 已更新到 0.17.0 build 34，安装与启动成功不代表教学体验验收。本轮没有运行 Web 或远端 CI。

## Known issues / 已知问题

旧六题的未完成草稿保留但不能继续按新题判定，需用户明确确认退出后开始新版。此行为沿用现有 revision 保护，不自动重置或影响其他草稿、完成记录、XP。末尾单题的穿插机制继续沿用既有实现假设。

## Verification / 已做验证

以下七题初次接入的运行结果对应 0.17.0 build 33；提示精简后的 build 34 验证另记在下方，不将旧结果视为本次重跑。

- swift test：86 项通过，含新版探索 / 掌握重答、旧 revision 草稿 / 完成记录 / 340 XP 保留与同课奖励幂等；日志在 build/lesson-1-1/core.log。
- XcodeGen 与单个已启动 iPhone 17 Pro / iOS 26.5 的 build-for-testing 成功；禁用并行。编译资源中的「1-1」、practice revision 2 与候选版本核对通过。
- 原生 UI：同一 Simulator、禁用并行，9 项全部通过（4 项旧故事兼容 + 5 项新版短题），见 build/lesson-1-1/UI.xcresult 与 ui-tests.log。覆盖七题完成、填空撤回、探索错误、掌握题队尾、中断恢复、重复完成不发奖、确认退出、选项坐标稳定 / 手动滚动与最大字号静态呈现。
- 实际查看第 1、4、5、6、7 题和大字号反馈 / 第 4 题截图。第 5、6 题初次截图抓到切题时的旧按钮标签，补充按「检查」标签等待的截图屏障，重新 build-for-testing 并只复测完整短题流程通过，见 UI-stable-capture.xcresult。未改产品判定或动效；重取截图已核对。代表截图：[第 4 题前提](../../build/lesson-1-1/Q04-router-premise-and-three-options.png)、[第 5 题](../../build/lesson-1-1/Q05-optical-modem.png)、[第 6 题](../../build/lesson-1-1/Q06-broadband-service.png)、[最大字号前提](../../build/lesson-1-1/Q04-largest-text-router-premise.png)。大字号需滚动阅读，按钮可操作；完整 VoiceOver 未验收。
- 最终 Simulator 编译成功，App 中 lessons.json 与当前源文件完全一致，版本 0.17.0 build 33、题目 ID 与 revision 核对通过，见 bundle-verification.json。没有真机编译、安装或交互声明。
- git diff --check 与本轮文档本地链接检查通过，未提交修改保留。
- 题干、选项与反馈按实际阅读顺序独立通读，记录在 build/lesson-1-1/reading-order.txt。核对 Cisco、ASUS、Ofcom、Apple 的对应机制；旧 IMDA PDF 入口本轮触发访问验证，第 6 题改用可读取的 Ofcom 来源。来源和适用范围见第一课审稿。

提示精简后（0.17.0 build 34）的新增验证：

- swift test 重新运行 86 项通过，XcodeGen / build-for-testing 成功；安装包的 lessons.json 与源文件完全一致，版本与 revision 核对通过。日志与 bundle-verification.json 在 build/lesson-copy-cleanup/。
- 复用同一个已启动 Simulator，禁用并行，两项针对性原生 UI 测试通过：七题完整作答 / 撤回 / 重复完成不重复发奖，以及最大字号静态反馈 / 第 4 题作答。见 build/lesson-copy-cleanup/UI.xcresult。其余 UI 测试本次未重跑。
- 实际检查[第 1 题](../../build/lesson-copy-cleanup/Q01-wireless-lan.png)、[第 4 题](../../build/lesson-copy-cleanup/Q04-router-and-three-options.png)、[第 5 题](../../build/lesson-copy-cleanup/Q05-optical-modem.png)与[大字号第 4 题](../../build/lesson-copy-cleanup/Q04-largest-text-router-question.png)截图，删除的提示不再显示。大字号需滚动，作答测试通过；完整 VoiceOver 和真机体验仍未验收。git diff --check 与更新文档本地链接检查通过。

Patrick 要求推送手机后的部署验证（同一 0.17.0 build 34，无新增产品代码）：

- 真机 Debug 签名构建、codesign 严格校验通过；App 中课程与源文件完全一致，七题 / practice revision 2 / 图标与本地 Web 资源核对通过。沿用 com.perinchiang.wanggan.4DB63U52PY 与原签名 Team，基于 385a3bc 加未提交工作区修改；见 build/lesson-phone-update/bundle-verification.json。
- Pathos / iPhone 15 Pro 通过 localNetwork 覆盖安装，由 0.16.0 build 32 更新到 0.17.0 build 34；无测试参数 launch 成功，PID 67617。安装后应用清单独立确认版本，见 apps-after.json / launch.json。
- 更新前后 Preferences 已备份并比较：340 XP、11 条完成记录、6 个草稿、52 条结算记录、活动日期、触感偏好与 pre-v2 / pre-v3 原始备份保留。结算记录按 Swift 的 UUID 键字典比较，编码时键值对顺序变化，内容相同；其余账本字段逐项一致。见 build/lesson-phone-update/progress-verification.json。真机交互与教学体验仍待 Patrick 试学。

## Next recommended task / 推荐下一步

Patrick 试学七题，重点观察第 4～7 题是否自然承接前题、题干是否直接易懂，以及填空的手感；据反馈调整后再定课名。
