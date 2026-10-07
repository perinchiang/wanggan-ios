# 网感 · WangGan

原生 SwiftUI 网络学习 App，以轻互动、低压力的判断与反馈逐步建立网络直觉。

## 当前版本

当前版本 **0.17.0（build 34）**，源码提交 [af54882](https://github.com/perinchiang/wanggan-ios/commit/af54882)，接入七题新版「1-1」并精简题内提示。已通过 Wi-Fi 覆盖安装并启动于 Patrick 的 iPhone，340 XP、11 条完成记录和 6 个草稿保留，验证与限制见 [七题更新交接](docs/handoffs/2026-10-08-everyday-questions-handoff.md)。收尾记录见 [提交交接](docs/handoffs/2026-10-08-closeout-handoff.md)；当前分支为 codex/mac-workflow-audit，基于 feature/home-network-native / 385a3bc。本轮直接安装签名 App，上次导出的 IPA 为 0.15.0 build 30 / df11024。

当前只提供《你家的网络》中的「1-1」，沿用 home-two-boxes ID。Patrick 同意七道生活化短题接入；先编题、后定名，实际节奏与娱乐性仍需试学，不冻结题数。

- 单选点选即判定；选词填空可撤回、检查；匹配任意侧先选，共享三次错误机会，耗尽才揭晓。底部操作区融合反馈与继续，不自动跳题。
- 探索题不追踪；掌握题整题错误后回队尾，之后通过退出。末尾单题的穿插处理暂为实现假设，见 COURSE_GUIDE。
- 旧故事仅为已有草稿保留原播放器，不重置旧草稿、完成或 XP。旧六题草稿不套用新题答案；内容不兼容时保留并提示，确认退出后再开课进入新版。同课再做新题不重新发奖；队列存档升级 schema 3，保留旧原始数据备份。
- 仍只有学习 / 我的。历史错题复习、章节挑战 / 跳章、多选与连线未实现；挑战通过率 TBD，不恢复旧调度与删除课程。
- iOS 17+、iPhone、简体中文、竖屏，本地存储；无登录、支付或云同步。Dark Mode 和声音未实现。
- 本轮运行结果以 [七题更新交接](docs/handoffs/2026-10-08-everyday-questions-handoff.md) 为准；旧 CI / 真机结果不代表新候选验证通过。

## Mac 本地开发（默认）

已安装完整 Xcode、XcodeGen、Node 和 Python 3 后，在仓库根目录运行：

```sh
./scripts/doctor.sh
swift test
node --test scripts/test_ipv4_visual.cjs
swift scripts/generate_icon.swift
xcodegen generate
xcodebuild -project WangGan.xcodeproj -scheme WangGan -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/simulator CODE_SIGNING_ALLOWED=NO build
```

无需日常打开 Xcode 工程。Simulator 的 boot / install / launch / 日志、原生 UI 测试、真机签名与 Wi-Fi 部署的命令集中在 [开发工作流](docs/DEVELOPMENT.md)。真机只在首次账户 / 配对 / 签名配置时可能需要 Xcode GUI；Simulator 不需要签名。

项目以 `project.yml` 为工程来源，生成的 xcodeproj 与 build 均不提交；共享配置保持未签名，真机命令覆盖本机 Team 和实际 bundle ID。不要为本地开发改掉正式应用标识或卸载旧 App。

2026-10-08 已实际完成本地签名构建、Wi-Fi 覆盖安装与启动，真机更新到 0.16.0 build 32。答后解析覆盖展开，不再挤动选择按钮，用户可自行滑动查看。更新前后 340 XP、11 条完成记录和 7 个草稿保留；该轮三个针对性 UI 检查通过，见 [反馈布局修复交接](docs/handoffs/2026-10-08-feedback-overlay-handoff.md)。真实教学体验继续由 Patrick 试学。

## GitHub Actions 与 Windows 备用流程

Mac 本地负责高频 build、Simulator、测试与真机快速验证。Actions 保留干净环境 CI：相关文件 PR 的 Core / Web + 快速编译，手动阶段性回归与 IPA artifact；不再要求每个小改动 push 后等 IPA。没有增加 push 自动打包。

1. Windows 需要包时，手动触发 `Build and test iOS`。`ui_scope=package` 运行 Core / Web 并构建 iPhone 未签名 IPA，不跑 UI；`full` 运行现有全部 UI 与截图并出包。`quick` 只编译，`smoke` / `home` 只跑现有短题与旧播放器兼容 UI、不出 IPA。验证范围由 [ARCHITECTURE.md](ARCHITECTURE.md) 维护。
2. 运行成功后下载 `WangGan-iPhone-unsigned` artifact，解压得到 `WangGan-unsigned.ipa`。
3. 从 <https://sideloadly.io/> 安装 Windows 版 Sideloadly，并按官网要求准备 Apple 设备驱动。
4. 首次用数据线连接 iPhone，解锁并信任电脑。将 IPA 放进 Sideloadly，使用自己的 Apple 账户签名安装。
5. 根据手机提示信任开发者；iOS 16+ 开启“设置 → 隐私与安全性 → 开发者模式”。

普通账户签名有效期为 7 天，需要刷新。账户密码仅在你的本机安装工具中输入，不要写进代码、GitHub Secrets 或聊天。这个 IPA 是**真机未签名包**，不能直接点开安装，也不能通过 TestFlight 安装。

更新时保持同一 Apple 账户及应用标识，不要先卸载；卸载会删除本地进度。免费签名无法代替未来的 App Store 分发或内购测试。

## 测试

```sh
swift test
node --test scripts/test_ipv4_visual.cjs
```

Core 覆盖短题角色、三次匹配、队列、草稿与奖励，并保留旧播放器门控、迁移和删课历史回归。UI 测试通过 xcodebuild 在单个 Simulator 上运行，按变更选择范围；package 仍不启动模拟器。

SwiftUI 在 Windows 上不能本地编译预览。Actions 结果只证明对应 commit 的构建和测试状态；之后的未验证提交须另行标注，不把静态检查当成真机测试。

## 结构

- `Sources/Core`：课程结构、答题状态机、首次完成奖励与学习进度。
- `Sources/App`：SwiftUI 界面和本地存储。
- `Resources/lessons.json`：可独立编辑的课程内容。
- `Tests`：核心测试和原生 UI 测试。
- `project.yml`：XcodeGen 工程定义。

## 开发文档

- [PRODUCT.md](PRODUCT.md)：产品定位、当前能力与暂缓范围。
- [COURSE_GUIDE.md](COURSE_GUIDE.md)：新教学原则与需重审的候选内容地图（Draft）。
- [DESIGN.md](DESIGN.md)：视觉、动效与可访问性规范。
- [ARCHITECTURE.md](ARCHITECTURE.md)：系统边界、历史数据保护与测试矩阵。
- [AGENTS.md](AGENTS.md)：开发与交付约定。
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)：Mac 命令行、Simulator、真机与 CI 的标准流程。
- [题目课程编排草案](docs/first-learning-loop-draft.md)：第一课已获同意的样题与实现范围；后续课表和实际试学节奏仍 Draft。
- [docs/handoffs](docs/handoffs)：历次施工记录，以最新正式文档为产品规则；仓库没有独立 ROADMAP，候选地图与演进方向分别在 COURSE_GUIDE / PRODUCT。
