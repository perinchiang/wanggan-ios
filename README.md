# 网感 · WangGan

黑白与荧光黄绿的原生 SwiftUI 网络学习 App。每个小节：做出判断 → 分步解惑 → 连线练习 → 场景追问 → 经验结算。

## 当前版本

- 开发候选 0.4.0（build 8）：新增「IPv4 地址为什么写成四段？」基础课，复用本地 IPv4 图示，点选一段 → 8 位 → 0 / 255 → 完整 32 位，支持课内四个观察步骤回看与退出恢复。新用户从基础课开始；既有主线草稿优先续学，提前补基础课另存草稿。运行验证待本次集中 CI，不沿用下列发布结果。

- 0.3.0（build 7），应用代码提交 `4696e2e`；手动 Actions [37302355235](https://github.com/perinchiang/wanggan-ios/actions/runs/37302355235) 通过并导出 iPhone 未签名 IPA。网关 / DNS 各两场景、一题短复习；可使用提示、答错重试、退出恢复，保留整课重学，分别保存草稿且共用每日 +5 XP。
- 本轮 36 项 Core、2 项 Web、3 项原生 UI 通过（网关短复习、DNS 短复习、原整课学习 / 复习隔离回归），未重跑其余课 UI 全套。已检查短复习实际模拟器截图，错误反馈完整露出；真机、VoiceOver、大字号与后台体验待验收。详见 [短复习交接](docs/handoffs/2026-10-05-short-review-handoff.md)。

- 上一版 0.2.0（build 6），对应代码提交 `92b2dac`；记录见手动 Actions [37294516851](https://github.com/perinchiang/wanggan-ios/actions/runs/37294516851)。
- 子网课已加入离线 IPv4 地址拆解和分界练习。27 项 Core、2 项 Web 测试及 1 项子网原生流程测试通过，包含实际 WKWebView、答错改选、退出恢复与经验结算；本轮未运行其余四课 UI 全套。VoiceOver、大字号和后台切换的完整真机体验仍待验收。详见 [发布交接](docs/handoffs/2026-10-05-ipv4-visual-0-2-0-release-handoff.md)。
- iOS 17+，iPhone，简体中文，竖屏。
- 5 个原创小节：网关、子网、ARP、逐跳转发、DNS；每节附知识来源。
- 原生路线图、数据包角色、触感反馈、连接曲线、通关与经验动画。
- 场景按对话逐条出现，点击继续推进；完整交代条件后再显示选项。子网题始终在答题区域展示两台电脑的地址与掩码。
- 本地进度、退出续学、复习安排、经验等级、每周学习统计。
- 主线续学与各节复习分别保存；复习不会把学习路线拉回旧课。复习完成后可继续主线最远的位置。
- 首次完成 +30 XP；后续每个小节每日首次复习 +5 XP；同日重学不重复发奖。
- 无账号、无广告、无远程模型调用、无服务器。付费与同步尚未加入。

## Windows → iPhone

1. 阶段性验收或需要交付新安装包时，手动触发 GitHub Actions 的 `Build and test iOS` 工作流；它会在 macOS 上运行核心测试、原生 UI 测试并构建 iPhone App。普通提交不会自动触发。
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

核心测试覆盖课程完整性、错题重试、连线一对一关系、阶段门控、奖励幂等、复习日期和进度序列化。GitHub Actions 另外运行 iOS UI 测试，验证实际小节完成、进度持久化与退出续学，并导出模拟器截图。

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
