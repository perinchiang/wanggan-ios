# Mac 接管、教学原则与工作流审计

## Current task / 本轮任务

Patrick 从 Windows + GitHub Actions 迁到 Mac 本地开发。先确认真实基线、整理新教学原则、验证 CLI 工具链；不新增课程、改第一课或开发 UI 功能。

## Completed / 已完成

- Clone 到 `/Users/patrickchiang/Documents/wanggang-ios`，新建本地 `codex/mac-workflow-audit`；改动留在工作区，未 commit / push / merge。
- 读取六份根目录规范、最新删课 / 删除复习交接、文案与图示修复记录、project.yml、全部现有脚本与唯一工作流；核对课程、播放器、进度和四项 UI 用例。无独立 ROADMAP，演进阶段在 PRODUCT，候选地图在 COURSE_GUIDE。
- 更新 PRODUCT / COURSE_GUIDE：新教学方向与现有实现分开；第一课改为未获认可的试验，旧地图标为需重审的候选。DESIGN 补低压力反馈与路径；ARCHITECTURE 列实现差距和后续职责。长期原则以这些正式文档为准。
- README 改为 Mac 默认入口；[DEVELOPMENT](../DEVELOPMENT.md) 集中维护命令行、Simulator、签名、Wi-Fi、日志和 CI 流程。AGENTS 删除过时的强制故事、禁止简单复习、默认不验 UI 和云端唯一构建路径等规则，以链接引用详细流程。
- 原样复用 PR #3 的 doctor.sh，不合并它较旧的全部分支。选择 Simulator 的脚本只增加优先复用 booted iPhone；CI 原有无设备时的 iPhone 15 Pro 选择保留。
- 保留 CI 的所有手动 scopes；只给代码 / 资源 / 脚本 / 构建配置 PR 增加 Core / Web + 快速编译，显式限制 UI / 截图步骤仅手动运行。不增加 push 构建。
- Sources、Resources、Tests、project.yml、Package.swift 和所有版本 / 稳定 ID 未修改。
- Patrick 登录 Xcode 后，补完签名 build、Wi-Fi 覆盖安装与启动，手机已更新为 0.15.0 build 30；实际 v1 → v2 迁移保留原有 XP、完成记录与草稿。新增 [第一节体验草案](../first-learning-loop-draft.md)，仅供讨论，未实现或改写正式原则。

## Decisions made / 本轮关键决策

### 真实基线（本轮远端读取）

| 位置 | 状态 |
| --- | --- |
| `main` | `aaeb299`，0.3.0 旧短复习版本；比开发基线少 59 个提交 |
| [PR #2](https://github.com/perinchiang/wanggan-ios/pull/2) | OPEN，`feature/home-network-native` → main，head `385a3bc21522f99c00f19aa9c2eeedf49b475504`；应从这里继续 |
| [PR #3](https://github.com/perinchiang/wanggan-ios/pull/3) | OPEN，`feature/doctor-script` → feature/home-network-native，head `4edadcf`；分叉点 `62b3d4e`，只增加环境脚本 |
| PR #1 / 漫画分支 | 已关闭 / 被替代，不作为开发基线 |
| App | 0.15.0 build 30；最后应用逻辑提交 `df11024`，`385a3bc` 仅补交付记录 |

PR #2 的旧标题 / 描述仍提到 0.7.0，与最新代码不一致，不能据此判断版本。本轮只读取 / 附加该 PR，未修改 GitHub 元数据或分支保护。

上次 [CI 37612194179](https://github.com/perinchiang/wanggan-ios/actions/runs/37612194179) 对 df11024 的 package 成功，UI / Simulator 全部 skipped；不是本轮修改的云端验收。本轮未消耗 Actions 构建额度。新 PR 触发配置尚未 push、未在 Actions 上执行，远端 required check 状态未确认（查询遇到 TLS timeout）。

教学变更范围、替代规则和实现差距见正式文档。本轮没有自行决定章节挑战通过率（TBD）、课表、题量、商业化价格或课程包边界。

## Not completed / 尚未完成

- 第一课重新设计、新题目角色、错题队列、历史错题复习和章节挑战均未实现；未来再按正式原则安排。
- 教学用时、压力感、全流程 VoiceOver 和真机效果没有完成用户验收。本轮不修改课程或 UI 来消除审计发现。

## Known issues / 已知问题

- 本地原生 UI 全量 4 项中 2 项失败：`testConfirmedExitRestartsExample` 的确认框在 iOS 26.5 是 popover，AX 和实际截图有“确定退出”，没有“取消”按钮；`testHomeTeachingBacktrackAndInterruptedResume` 在首次点击首页后仍留在首页，未找到 primary-action。单独复跑该恢复用例仍失败，这次发生在重启后的首页点击，没有进入 topology-stage，需区分点击 / 呈现时序和 App 问题。失败原始记录保留，未弱化断言。
- 随后用 XcodeBuildMCP 实际点击同一模拟器的“继续探索”，成功恢复到观察 1 / 5，再验证 1 → 2 → 上一步回到 1；证明保存的阶段可恢复，但不把手动成功当成失败 UI 测试已修复。退出 popover 问题也经独立操作与截图确认。新教学体验与这些现有问题另行处理，本轮不动 App 源码。
- 现有首页仍逐课显示长标题，含固定“约 3 分钟 / 4 段探索”文案；没有真实用时证据。第一课同时涵盖多项认知，与新节奏的差距见 COURSE_GUIDE；本轮不改 UI。
- Homebrew Python 3.14.5 的 plistlib / pyexpat 因 libexpat 符号缺失无法导入；Xcode 随附 Python 3.9.6 能正常读取 plist。现有 json / subprocess 脚本可运行，未进行全局 Python 修复。doctor 默认只检查版本，不覆盖此问题。

## Verification / 已做验证

本机 macOS 26.2 / arm64，开发目录 `/Applications/Xcode.app/Contents/Developer`，Xcode 26.6（17F113）、iOS SDK 26.5、Swift 6.3.3、XcodeGen 2.44.1、Node 22.22.0；iOS 26.2 与 26.5 runtime 可用。仅 boot 已有 iPhone 17 Pro / iOS 26.5（`76B992FF-D005-4880-9784-F71DF4015DE7`），没有同时启动第二个 Simulator。

| 实际命令 / 检查 | 结果 |
| --- | --- |
| git log / branch -r / gh repo / pr list / run list | 确认上述远端状态与候选基线 |
| xcode-select -p / xcodebuild -version / -showsdks / -checkFirstLaunchStatus | 工具链与初始化可用 |
| `./scripts/doctor.sh` / `bash -n` | 10 PASS、0 WARN、0 FAIL；脚本语法通过。未另跑 --full |
| `swift test` | 74 项通过，0 失败 |
| `node --test scripts/test_ipv4_visual.cjs` | 4 项通过，0 失败；不代表 WKWebView 集成验收 |
| `swift scripts/generate_icon.swift` / `xcodegen generate` | 图标和工程生成成功，生成物被忽略 |
| `xcodebuild ... -sdk iphonesimulator ... build` | Debug Simulator build 成功 |
| `simctl boot / bootstatus / open -a Simulator / install / launch` | Simulator 启动，App 安装与启动成功，首页 PNG 已查看 |
| `simctl spawn ... log show` / `xcresulttool export attachments` | 可读取日志与测试证据；App 自身日志查询无条目，生命周期查询有 1236 行 |
| `xcodebuild ... build-for-testing` / WebKit helper | UI runner 编译成功，当前工具链不需旧 WebKit workaround |
| `xcodebuild ... test-without-building -parallel-testing-enabled NO` | 全部 4 项实际运行，2 PASS / 2 FAIL；完整学习与大字号通过，失败见上文 |
| 同命令加 `-only-testing:WangGanUITests/LearningUITests/testHomeTeachingBacktrackAndInterruptedResume` | 聚焦复跑 1 项仍失败，测试证据在 UIResumeFocused.xcresult；没有重跑已通过用例 |
| `xcodebuild ... -sdk iphoneos -configuration Release CODE_SIGNING_ALLOWED=NO build` | 真机目标编译成功，包内课程 JSON 与源码一致，Web / Assets.car 存在 |
| `devicectl list / info details` / xcodebuild -showdestinations | Pathos iPhone 15 Pro，报告 iOS 27.0、paired、Developer Mode enabled、localNetwork / connected，真实 Wi-Fi 可见且是有效 destination |
| `security find-identity` / 证书 subject | 有开发 identity，证书 OU 的 Team 是 4DB63U52PY，不能用 CN 括号中的 ID 代替 |
| `devicectl info apps / copy from ... Library/Preferences` | 旧 App 为 0.14.0 build 29，实际 ID `com.perinchiang.wanggan.4DB63U52PY`；备份成功，v1 进度 340 XP / 11 条课程记录 |
| 首次 `xcodebuild ... CODE_SIGNING_ALLOWED=YES CODE_SIGN_STYLE=Automatic ... -allowProvisioningUpdates` | 登录前失败：No Accounts / 当前 bundle 无开发 profile；后续已补完，见下两行 |
| 登录后同命令，加 `-allowProvisioningDeviceRegistration` / `codesign --verify --deep --strict` | 签名 build 与验证成功，沿用 Team 4DB63U52PY 和旧实际 bundle；profile 包含该 UDID，有效期到 2026-10-14 17:21:30 UTC |
| `devicectl install app` / 普通 `process launch --terminate-existing` / info apps、details、processes | 全部成功，安装后为 0.15.0 build 30，WangGan PID 66912，transportType localNetwork / tunnel connected；没有卸载旧 App，也未传测试 / 重置参数 |
| 更新前后 `copy from ... Library/Preferences` / Xcode Python 比较存档 | active schema 1 → 2，原始备份与更新前字节相同；340 XP、11 条 completedAt / lastMistakes、6 个草稿全部字段、48 个原结算记录与历史学习日保留。更新后快照另有一个 0 XP 结算和一个学习日，本轮不推断其交互来源 |
| 登录前 `devicectl device process launch ... --terminate-existing --console` / 普通 launch 复核 | 旧版 App 无线启动成功，console 等待可用；Ctrl-C 后确认 App terminated due to signal 2。旧版进程确认 PID 66854；新版启动另见上行 |
| workflow YAML / 6 种 event-scope 路由 | PR 只编译、手动 scopes 保持原职责；本地静态检查通过，未称云端执行成功 |

主要命令的完整参数在 DEVELOPMENT，实际日志、xcresult、导出截图和设备备份在忽略目录 `build/audit/`。初次普通真机 launch 返回 10004（无法取得 PID），后续 console 与普通启动均成功；不从这次临时错误推断 App 崩溃原因。34 个修改文档的本地链接、git diff --check、脚本语法均通过；doctor.sh 的 blob hash 与 PR #3 完全一致。结束前 ls-remote 复核三个远端分支仍为上表 SHA。

登录后补验日志为 `signing-after-login.log`、`device-install-after-login.json`、`device-launch-after-login.json`；进度比较摘要为 `device-migration-after-login-summary.json`，均在 build/audit。加入体验草案后，40 个本地链接与 git diff --check 通过，App 源码、内容、测试和版本文件仍无改动；本次没有重复运行前述 Core / Web / UI 用例。

本轮没有打开 Xcode 工程或点击 GUI build / test，但 Xcode GUI 在任务开始时已运行；未擅自关闭用户已有窗口。因此这里证明 CLI 路径可执行，不声称做过“关闭 Xcode 进程”的对照实验。首次账户 / profile 配置仍可能需要 GUI，Simulator、日常 build / test、配对后的 devicectl 不需要工程窗口。

## Next recommended task / 推荐下一步

先处理本轮发现的退出和首页进入 / 恢复问题。参考第一节体验草案，通过试学调整候选脚本，再逐步实现这一课所需的题目角色和队列；不把草案当作已确认课表。仅剩一道错题时如何避免即时连续重试，需要在队列实施前明确。章节挑战实现前由 Patrick 定通过率；本轮保持 TBD。
