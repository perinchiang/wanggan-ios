# 第一课连续短题播放器

## Current task / 本轮任务

Patrick 同意《你家的网络》 / 《有线和无线》六道样题，确认全宽选项、单选即时判定、填空可撤回、底部融合反馈、匹配三次试错，并同意开始实施。

## Completed / 已完成

同一 home-two-boxes ID 接入数据驱动短题，原生连接简图、单选、选词填空、任意侧起选匹配、三次错误预算、整题反馈与队尾。Core 管判定与队列，SwiftUI 管表现。候选版本 0.16.0 build 31，没有提交、push 或交付 IPA。

旧故事字段与 Step 播放器仅为已有旧草稿续读保留；schema 3 新增可选短题状态，加载 v1 / v2 保留历史，首次写回前备份原始 pre-v3。稳定应用、课程 ID 和存储键不变，同课旧完成记录不重复发奖。

正式规则更新 PRODUCT / COURSE_GUIDE / DESIGN / ARCHITECTURE，README 与开发工作流同步当前能力，AGENTS 仅调整第一课状态。旧 UI 回归保留，新测试加入 CI 的 home / smoke 范围。

## Decisions made / 本轮关键决策

匹配整题共享三次错误机会，第三次错误前完成算正确；耗尽才揭晓、锁定，日常掌握题回队尾。中断不重置预算，队尾回来为新轮。没有不知道入口，不把试错后成功算失败；未来挑战同规则，当前未实现挑战。

第 4 题微调为“哪台设备用了 Wi-Fi 连接？”以适配下方全宽选择；图与答案不变。末尾只剩一道错题暂穿插已答对掌握题；这是向 Patrick 提问后采用的实现假设，尚无单独回复，可调整。

## Not completed / 尚未完成

Patrick 真机试学反馈、实际用时与教学节奏；多选、连线、历史复习、章节挑战 / 跳章。通过率 TBD；连线试错次数没有自动沿用匹配规则。新版本已部署真机，未触发云端 CI。

## Known issues / 已知问题

内容 revision / ID 不兼容时保留草稿并提示，不自动重置；当前没有跨修订的题目映射界面。旧草稿先续读旧故事，完成后再开课可进入新题。

## Verification / 已做验证

- swift test：84 项通过（含原有 74 项与新增 10 项），见 build/question-loop/core.log。
- node --test scripts/test_ipv4_visual.cjs：4 项通过，见 web.log；不代表未接入的 WKWebView 已验收。
- xcodegen generate 成功；Simulator build-for-testing、iPhone Release 未签名编译成功。最终 build-final.log / device-build.log，无签名、安装或真机交互声明。
- 同一 iPhone 17 Pro / iOS 26.5，禁用并行，首轮全部 8 项 UI 通过，UI-first.xcresult。旧退出对话框改为 alert，取消按钮可访问，旧退出与恢复回归本轮通过。
- 首轮截图实际查看，发现半透明反馈透出下层选项；修为不透明底板、长解析内部滚动、继续按钮固定，且最终匹配列按正确对应展示。修正后四项短题 UI 又通过（UI-final.xcresult）。后续把常规字号面板收紧、最大字号面板滚动，并在静态模式关闭子视图动画；曾误用只读系统环境值导致编译失败，相关测试立即终止、不计通过。已修复并重新编译成功，最终两项布局复测通过（UI-layout-final.xcresult），实际查看普通匹配错误与最大字号解析截图：不透明底板消除透字，普通字号紧凑，最大字号解析滚动、继续固定可点。静态模式使用局部 transaction.disablesAnimations，不修改系统设置。
- 最终 build_run_sim 成功，App 已安装并启动；实际查看 standalone.png，停在《你家的网络》学习首页，可点击“开始探索”试学。启动使用 --uitesting --reset-progress 的独立测试数据，不重置正常用户进度。
- Patrick 随后要求推到手机：重新检查 Pathos iPhone 15 Pro，Wi-Fi / paired / Developer Mode 可用；沿用旧 Team 与实际 bundle，本地签名 Debug build、codesign 严格校验、课程资源核对通过。devicectl 覆盖安装、无测试参数启动成功，版本 0.16.0 build 31，进程 67172。没有打开 Xcode 工程或卸载 App；源码为 385a3bc 上的未提交工作区，没有交付 IPA。
- 真机更新前备份 Preferences；首次启动立即读取仍为 schema 2，稍后快照确认已写 schema 3，pre-v3 与更新前原始字节一致。340 XP、11 条完成记录、6 个旧草稿全部字段、学习日期和原结算记录保留；新增 home-two-boxes 草稿，不推断其交互来源。实际签名 / 安装 / 启动日志、快照与 progress-verification.json 在 build/device-preview。真机启动和数据保留不代表教学体验已验收。
- git diff --check 通过；当前 9 份文档的 43 个本地链接无缺失。日志、截图与 xcresult 都在忽略目录 build/question-loop。实际截图：[第一题](../../build/question-loop/first-question.png)、[匹配错误反馈](../../build/question-loop/matching-error.png)、[最大字号反馈](../../build/question-loop/large-text-feedback.png)。

教学用时、娱乐性、VoiceOver 真机、声音与 Dark Mode 未验收。Xcode 的 AppIntents 无依赖元数据提示、旧 LessonPlan 未使用局部变量警告不属于本轮新增机制，不以这些编译提示扩展重构。

## Next recommended task / 推荐下一步

Patrick 试学第一课，反馈图示、词移动、选项手感、解析与重复题的节奏；按真实反馈调整，再安排后续内容。
