# 网感 · WangGan

原生 SwiftUI 网络学习 App，以真实疑问、分步观察和迁移判断建立网络直觉。

## 当前版本

开发候选 **0.14.0（build 29）**。当前仅保留一节示例课：**宽带师傅为什么装了两个路由器？**（`home-two-boxes`）。

- 保留安装宽带的故事、分步拓扑与回看、视频数据流、一体机换机判断、答后房间接线和 FTTR 揭晓。
- 其余八节在目录中的旧课、两节归档试验课及四道短复习题已删除；专用教学页面与旧教案同步移除。
- 原学习记录、草稿、结算记录和 XP 保留。已删除课程不进入学习推荐、解锁或复习列表；示例课仍可重学。
- 通用 Core、参数化 Web 图示与历史解码类型保留为技术组件，不代表有其他可学习课程。测试使用中性结构数据，不保存旧课正文。
- 本轮验证范围与交付结果见 [交接记录](docs/handoffs/2026-10-07-single-example-handoff.md)。原生交互由 Pat 真机验收。
- iOS 17+、iPhone、简体中文、竖屏；本地存储，无登录、支付或云同步。

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

核心测试覆盖唯一示例课、错题重试、阶段门控、奖励幂等、复习日期、删课后的历史保留与进度序列化。iOS UI 测试为可选检查，仅在 Pat 明确要求时运行；默认 package 不启动模拟器。

SwiftUI 在 Windows 上不能本地编译预览。Actions 结果只证明对应 commit 的构建和测试状态；之后的未验证提交须另行标注，不把静态检查当成真机测试。

## 结构

- `Sources/Core`：课程结构、答题状态机、经验与复习规则。
- `Sources/App`：SwiftUI 界面和本地存储。
- `Resources/lessons.json`：可独立编辑的课程内容。
- `Tests`：核心测试和原生 UI 测试。
- `project.yml`：XcodeGen 工程定义。

## 开发文档

- [PRODUCT.md](PRODUCT.md)：产品定位、当前能力与暂缓范围。
- [COURSE_GUIDE.md](COURSE_GUIDE.md)：教学原则与未来故事地图（Draft）。第一课是唯一现有示例，未来课须重新设计与审读。
- [DESIGN.md](DESIGN.md)：视觉、动效与可访问性规范。
- [ARCHITECTURE.md](ARCHITECTURE.md)：系统边界、历史数据保护与测试矩阵。
- [AGENTS.md](AGENTS.md)：开发与交付约定。
