# 网感 · WangGan

黑白与荧光黄绿的原生 SwiftUI 网络学习 App。每个小节：做出判断 → 分步解惑 → 连线练习 → 场景追问 → 经验结算。

## 当前版本

- 当前试学候选 **0.10.0（build 25）**：朋友对白与联系运营商的回复按 Pat 原句调整，补上「后来你去朋友家玩」，答题后新增一体机、普通路由器、FTTR 三页接口拓扑图解。全部对话气泡统一左右 10 pt 内边距，正文按完整宽度换行。仅计划运行 Core / Web 和快速 iPhone package；编译与安装包待验证，交互由 Pat 真机验收。

- 上一候选 **0.8.1（build 22）**：收窄用户气泡两侧留白，沿用 0.8.0 的退出、故事题、原位替换讲解和完成页修正。按 Pat 明确要求只做 Core / Web 和快速 iPhone 打包，原生交互由 Pat 真机检查；[package 构建](https://github.com/perinchiang/wanggan-ios/actions/runs/37513241703) 通过（源码 `1b4f169`，1 分 56 秒，67 Core / 4 Web、iPhone Release 与安装包核验）；未跑原生 UI。

- 反馈修正版候选 **0.8.0（build 21）**：主动确认退出丢弃当前草稿；用户气泡文字左对齐；设备图讲解气泡逐步替换；朋友换机场景与完成页文案重做。已完成历史与 XP 保留，后台意外中断仍可恢复。[package #49](https://github.com/perinchiang/wanggan-ios/actions/runs/37508868129) 已通过（源码 `0da10ed`，1 分 46 秒，67 Core / 4 Web、iPhone Release 及安装包核验）；原生 smoke 四项通过；故事课定位断言修正后的专项因模拟器无输出超时未完成。结果见 [反馈修正交接](docs/handoffs/2026-10-07-exit-and-story-feedback-handoff.md)，不能沿用 build 20 的 CI 结果。

- 快速试学候选 **0.7.0（build 20）**，源码 `ab8bc71`：[手动 package 构建](https://github.com/perinchiang/wanggan-ios/actions/runs/37505413864) 已通过，触发至完成 1 分 28 秒，62 Core / 4 Web、iPhone Release 编译、IPA 上传及本地安装包核验通过。家庭网络故事课沿用 build 19 的生活对话、稳定滚动、拓扑焦点高亮和跳过配对；本轮只新增快速打包模式及提高 build 号。详见 [快速试学包交接](docs/handoffs/2026-10-07-quick-trial-ipa-handoff.md)。本次没有运行原生 UI / 模拟器截图，真机试学待 Pat 反馈。

- 历史开发候选 0.4.0（build 8）：新增「IPv4 地址为什么写成四段？」基础课，复用本地 IPv4 图示，点选一段 → 8 位 → 0 / 255 → 完整 32 位，支持课内四个观察步骤回看与退出恢复。新用户从基础课开始；既有主线草稿优先续学，提前补基础课另存草稿。运行验证待本次集中 CI，不沿用下列发布结果。

- 0.3.0（build 7），应用代码提交 `4696e2e`；手动 Actions [37302355235](https://github.com/perinchiang/wanggan-ios/actions/runs/37302355235) 通过并导出 iPhone 未签名 IPA。网关 / DNS 各两场景、一题短复习；可使用提示、答错重试、退出恢复，保留整课重学，分别保存草稿且共用每日 +5 XP。
- 本轮 36 项 Core、2 项 Web、3 项原生 UI 通过（网关短复习、DNS 短复习、原整课学习 / 复习隔离回归），未重跑其余课 UI 全套。已检查短复习实际模拟器截图，错误反馈完整露出；真机、VoiceOver、大字号与后台体验待验收。详见 [短复习交接](docs/handoffs/2026-10-05-short-review-handoff.md)。

- 上一版 0.2.0（build 6），对应代码提交 `92b2dac`；记录见手动 Actions [37294516851](https://github.com/perinchiang/wanggan-ios/actions/runs/37294516851)。
- 子网课已加入离线 IPv4 地址拆解和分界练习。27 项 Core、2 项 Web 测试及 1 项子网原生流程测试通过，包含实际 WKWebView、答错改选、退出恢复与经验结算；本轮未运行其余四课 UI 全套。VoiceOver、大字号和后台切换的完整真机体验仍待验收。详见 [发布交接](docs/handoffs/2026-10-05-ipv4-visual-0-2-0-release-handoff.md)。
- iOS 17+，iPhone，简体中文，竖屏。
- 9 个小节：故事课「两个盒子」、三节 IPv4 基础课，以及网关、子网、ARP、逐跳转发、DNS；每节附知识来源。另有两节旧试验课已归档，不占用学习路线。
- 原生路线图、分阶段揭示的拓扑示意图、数据包角色、触感反馈、连接曲线、通关与经验动画。
- 场景按对话逐条出现，点击继续推进；完整交代条件后再显示选项。子网题始终在答题区域展示两台电脑的地址与掩码。
- 本地进度、意外中断续学、主动退出重来、复习安排、经验等级、每周学习统计。
- 主线续学与各节复习分别保存；复习不会把学习路线拉回旧课。复习完成后可继续主线最远的位置。
- 首次完成 +30 XP；后续每个小节每日首次复习 +5 XP；同日重学不重复发奖。
- 无账号、无广告、无远程模型调用、无服务器。付费与同步尚未加入。

## Windows → iPhone

1. 手动触发 GitHub Actions 的 `Build and test iOS` 工作流。快速拿包试学选 `ui_scope=package`：运行 Core / Web 检查并构建 iPhone IPA，不启动模拟器、不运行原生 UI。当前原生交互由 Pat 真机验收，Agent 不主动运行；若 Pat 明确要求自动化完整验收，再选 `full` 运行全部原生 UI 与截图。`quick` 仅编译检查，`smoke` / 专项 scope 仅运行相应 UI，都不导出 IPA。普通提交不会自动触发；验证范围由 [ARCHITECTURE.md](ARCHITECTURE.md) 维护。
2. 运行成功后下载 `WangGan-iPhone-unsigned` artifact，解压得到 `WangGan-unsigned.ipa`。
3. 从 <https://sideloadly.io/> 安装 Windows 版 Sideloadly，并按官网要求准备 Apple 设备驱动。
4. 首次用数据线连接 iPhone，解锁并信任电脑。将 IPA 放进 Sideloadly，使用自己的 Apple 账户签名安装。
5. 根据手机提示信任开发者；iOS 16+ 开启“设置 → 隐私与安全性 → 开发者模式”。

普通账户签名有效期为 7 天，需要刷新。账户密码仅在你的本机安装工具中输入，不要写进代码、GitHub Secrets 或聊天。这个 IPA 是**真机未签名包**，不能直接点开安装，也不能通过 TestFlight 安装。

更新时保持同一 Apple 账户及应用标识，不要先卸载；卸载会删除本地进度。免费签名无法代替未来的 App Store 分发或内购测试。

## Mac 到手之后

安装 Xcode 和 XcodeGen，然后在项目目录运行：

```sh
brew install xcodegen
swift scripts/generate_icon.swift
xcodegen generate
open WangGan.xcodeproj
```

模拟器可直接运行。需要 Xcode 真机运行时，在项目配置中把 `CODE_SIGNING_ALLOWED` 改为 `YES`，并在 Signing & Capabilities 选择自己的 Team、启用自动签名。源代码不需要重写。

## 测试

```sh
swift test
node --test scripts/test_ipv4_visual.cjs
```

核心测试覆盖课程完整性、错题重试、连线一对一关系、阶段门控、奖励幂等、复习日期和进度序列化。GitHub Actions 另外运行 iOS UI 测试，验证实际小节完成、进度持久化、意外中断恢复与主动退出重来，并导出模拟器截图。

SwiftUI 在 Windows 上不能本地编译预览。Actions 结果只证明对应 commit 的构建和测试状态；之后的未验证提交须另行标注，不把静态检查当成真机测试。

## 结构

- `Sources/Core`：课程结构、答题状态机、经验与复习规则。
- `Sources/App`：SwiftUI 界面和本地存储。
- `Resources/lessons.json`：可独立编辑的课程内容。
- `Tests`：核心测试和原生 UI 测试。
- `project.yml`：XcodeGen 工程定义。

## 开发文档

最新优先级修订见 [教学与互动需求交接](docs/handoffs/2026-10-05-teaching-priority-revision-handoff.md)：先基础课与分步教学，复习体系进一步开发暂缓。这里只记录规划，0.3.0 的界面和安装包未改变。

本 README 描述当前 MVP；下列文档分别标注已实现、计划中、Draft 与暂缓内容，不代表未来能力已经上线。

- [PRODUCT.md](PRODUCT.md)：产品定位、功能边界与演进阶段。
- [DESIGN.md](DESIGN.md)：视觉规范、网络原生动效语言、声音与触感、Dark Mode 方向。
- [COURSE_GUIDE.md](COURSE_GUIDE.md)：教学与题目规范、可调整的课程内容地图（Draft）。
- [ARCHITECTURE.md](ARCHITECTURE.md)：系统边界、最小 Web 可视化试点、学习记录、迁移与测试。
- [AGENTS.md](AGENTS.md)：项目开发与 AI 协作约定。

## 内容约定

题干给完整场景与前提，选项预测结果；每个错误选项针对一种误解。解释机制后，再只改变少量条件做迁移判断。引用 RFC 作为机制依据，场景与文字自行编写。经验不等同于专业能力认证。

当前不含登录、推送、排行榜、支付、跨设备同步或真实设备实验。第一版优先验证一个小节的学习体验。
