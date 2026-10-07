# Mac 命令行开发与验证

日常流程：Agent / 编辑器 → 本地检查与 build → 单个 Simulator → 必要的真机验证。Xcode 提供工具链，日常不需要打开工程或保持 Xcode GUI 运行。首次账户、签名或配对配置可以使用 GUI。当前机器的实际结果和限制见 [迁移审计交接](handoffs/2026-10-08-mac-takeover-handoff.md)，这里维护可复用流程。

## 首次准备

安装完整 Xcode，而非只有 Command Line Tools；选择正确开发目录并完成许可 / 组件初始化。缺组件时再执行对应命令，不必每次 build 重做：

```sh
xcode-select -p
xcodebuild -version
xcodebuild -checkFirstLaunchStatus
# 如目录错误或尚未初始化：
# sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
# sudo xcodebuild -license accept
# xcodebuild -runFirstLaunch
```

项目使用 XcodeGen，不提交生成的 xcodeproj。需要 XcodeGen、支持 `node --test` 的 Node、Python 3；Swift / xcrun 随 Xcode 提供。`brew install xcodegen node` 仅在缺少时使用。诊断脚本复用 PR #3 的实现：

```sh
./scripts/doctor.sh
```

默认只读，不 boot、安装或改系统。`--full` 运行 Core / Web、图标生成、XcodeGen 和通用 Simulator 编译；不代表已运行 Simulator、UI 测试或真机部署。

若 Homebrew Python 的标准库 / dylib 有兼容问题，可使用 `xcrun python3`。本机 Python 3.14.5 的 `plistlib` 导入失败，Xcode 随附 Python 3.9.6 可正常读取 plist；现有 json / subprocess 脚本仍可用，本轮未改系统 Python。doctor 默认检查版本，不检测所有标准库模块。

## 日常检查与生成工程

```sh
swift test
node --test scripts/test_ipv4_visual.cjs
swift scripts/generate_icon.swift
xcodegen generate
```

Core 通过独立 Swift Package 测试；Xcode scheme 的测试目标是原生 UI，不包含这套 Core 测试。图标首次生成，修改绘图脚本后再生成；project.yml 变化后重新运行 XcodeGen。generated project、build、日志和 xcresult 都已被 gitignore 排除。

无需启动 Simulator 的快速 SwiftUI 编译：

```sh
xcodebuild -project WangGan.xcodeproj -scheme WangGan \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/simulator CODE_SIGNING_ALLOWED=NO build
```

保留 project.yml 的 `CODE_SIGNING_ALLOWED=NO`，适用于 Simulator 和未签名 CI。真机签名通过命令行覆盖，不修改共享工程，也不把本机账户设置提交到仓库。`options.xcodeVersion: 16.0` 是工程生成配置，不要求日常必须启动 Xcode 16 GUI；以当前工具链的实际编译结果为准。

## 单个 Simulator 的安装、启动与日志

```sh
xcrun simctl list runtimes
xcrun simctl list devices booted
SIMULATOR_ID="$(python3 scripts/select_simulator.py | sed -n 's/^id=//p')"
```

选择脚本优先复用已 boot 的 iPhone；没有时沿用 CI 的 iPhone 15 Pro 选择 / 创建逻辑。不要同时 boot 第二个设备。若缺 runtime，先安装合适的 iOS runtime：可使用 `xcodebuild -downloadPlatform iOS`，或一次性在 Xcode 的组件设置中安装；这不是日常 build 依赖 GUI。

以下命令在同一 shell 中使用上面的 SIMULATOR_ID：

```sh
# 已 boot 的设备跳过 boot；bootstatus -b 等待可用。
if ! xcrun simctl list devices booted | rg -q "$SIMULATOR_ID"; then
  xcrun simctl boot "$SIMULATOR_ID"
fi
xcrun simctl bootstatus "$SIMULATOR_ID" -b
open -a Simulator --args -CurrentDeviceUDID "$SIMULATOR_ID"
xcrun simctl install "$SIMULATOR_ID" \
  build/simulator/Build/Products/Debug-iphonesimulator/WangGan.app
xcrun simctl launch "$SIMULATOR_ID" com.perinchiang.wanggan
```

`open -a Simulator` 打开模拟器窗口，未打开 Xcode 工程。日志与截图：

```sh
mkdir -p build/screenshots
xcrun simctl io "$SIMULATOR_ID" screenshot build/screenshots/current.png
xcrun simctl spawn "$SIMULATOR_ID" log show --last 5m --style compact \
  --predicate 'process == "WangGan"' > build/simulator-runtime.log
# 实时日志，结束时 Ctrl-C：
xcrun simctl spawn "$SIMULATOR_ID" log stream --style compact \
  --predicate 'process == "WangGan"'
```

普通运行不传测试参数，不重置进度。UI 测试会使用 `wanggan.uitests` 独立 UserDefaults suite，并重置该 suite；不能把测试参数用于验证用户真实进度迁移。

## 现有原生 UI 测试

继续复用 CI 的 build-for-testing → test-without-building 和 watchdog；同一 Simulator、禁用并行：

```sh
python3 scripts/run_command_with_timeout.py --log build/ui-build.log \
  --idle-timeout 180 --wall-timeout 600 -- \
  xcodebuild -project WangGan.xcodeproj -scheme WangGan -configuration Debug \
  -sdk iphonesimulator -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath build/simulator CODE_SIGNING_ALLOWED=NO build-for-testing

python3 scripts/prepare_simulator_webkit.py --device "$SIMULATOR_ID" \
  --products build/simulator/Build/Products/Debug-iphonesimulator

UI_RESULT="build/UITests-$(date +%Y%m%d-%H%M%S).xcresult"
python3 scripts/run_command_with_timeout.py --log build/ui-tests.log \
  --idle-timeout 180 --wall-timeout 1200 -- \
  xcodebuild -project WangGan.xcodeproj -scheme WangGan -configuration Debug \
  -sdk iphonesimulator -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 300 \
  -derivedDataPath build/simulator -resultBundlePath "$UI_RESULT" \
  CODE_SIGNING_ALLOWED=NO test-without-building
```

当前第一课包括 PracticeUITests 五项短题用例和 LearningUITests 四项旧播放器兼容用例，覆盖七题流程、答后选项坐标 / 手动滚动、填空撤回、掌握题队尾、完成、草稿恢复、大字号与退出。匹配题机制继续由 Core 中性夹具保护，当前新版课程没有匹配题。需要聚焦时在测试命令中加 `-only-testing:WangGanUITests/LearningUITests/testHomeTwoBoxesFlow` 等。xcresult 路径必须未存在。截图附件可用 `xcrun xcresulttool export attachments --path "$UI_RESULT" --output-path build/screenshots` 导出。

2026-10-08 初次审计四项中两项失败；短题实现轮保留这些回归用例，全部八项通过，最终布局调整后另有两项针对性复测通过，详情见 [短题实现交接](handoffs/2026-10-08-short-question-player-handoff.md)。这些运行结果对应本地工作区，不能用于证明后续改动已通过。

WebKit helper 仅处理 Xcode 16.4 / iOS 18.4–18.5 的已知问题，当前 Xcode 26.6 会跳过；不要手工把 workaround 的 dylib 塞进真机 App。Web 单元测试通过不代表当前未接入课程的 WKWebView 已做集成验收。

## 真机：一次性配置与日常部署

首次通常用 USB 连接并在 iPhone 上 Trust，开启 Developer Mode；必要时在 Xcode 的设备管理中完成配对 / 网络连接。在 Xcode → Settings → Accounts 添加自己的 Apple 账户，获取开发签名与描述文件。不要把账户密码、证书私钥或会话凭据发给 Agent 或写入仓库。已有证书不等于有当前 App 的有效 profile。

配对、账户与 profile 可用后，日常先检查工具和真实连接：

```sh
xcrun devicectl list devices
xcrun devicectl device info details --device '<devicectl 的设备 ID>'
xcodebuild -project WangGan.xcodeproj -scheme WangGan -showdestinations
security find-identity -v -p codesigning
```

`paired`、`developerModeStatus: enabled`、`transportType: localNetwork` 和 connected tunnel 可证明无线连接条件；“设备可见”仍不等于 build / install / launch 已成功。使用 devicectl 的 `--json-output <path>` 做自动化解析，stdout 只用于阅读。

在本地 shell 设置（不提交）：

```sh
DEVICE_ID='<devicectl 的设备 ID>'
DEVICE_UDID='<xcodebuild -showdestinations 中的真机 UDID>'
DEVELOPMENT_TEAM_ID='<开发证书 OU / Team ID>'
DEVICE_BUNDLE_ID='com.perinchiang.wanggan'
```

如果手机原先用 Sideloadly 安装，先用 `xcrun devicectl device info apps --device "$DEVICE_ID"` 核对实际 bundle ID。它可能有账户后缀，覆盖更新时将 DEVICE_BUNDLE_ID 设为已安装的值，并使用原签名 Team；不得先卸载或当作全新 App 安装来声称保留了历史。证书名称括号中的 ID 不一定是 Team ID，不能猜。可先备份 App 的 Preferences：

```sh
xcrun devicectl device copy from --device "$DEVICE_ID" \
  --domain-type appDataContainer --domain-identifier "$DEVICE_BUNDLE_ID" \
  --source Library/Preferences --destination build/device-preferences-backup
```

本地签名构建和部署（顺序执行，任何一步失败就停止后续安装）：

```sh
(
set -e
xcodebuild -project WangGan.xcodeproj -scheme WangGan -configuration Debug \
  -sdk iphoneos -destination "id=$DEVICE_UDID" \
  -derivedDataPath build/device-local CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$DEVICE_BUNDLE_ID" \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration build

codesign --verify --deep --strict \
  build/device-local/Build/Products/Debug-iphoneos/WangGan.app
xcrun devicectl device install app --device "$DEVICE_ID" \
  build/device-local/Build/Products/Debug-iphoneos/WangGan.app
xcrun devicectl device process launch --device "$DEVICE_ID" "$DEVICE_BUNDLE_ID"
)
```

同一组命令可以用已配对、可达的 Wi-Fi 设备，不要求每次插线或开 Xcode GUI。手机需要可用且解锁；账户 / profile 过期或设备重新配对时再处理设置。免费账户的签名限制仍适用，不因迁到 Mac 消失。

2026-10-08 本机实际验证：Patrick 登录 Xcode 后，签名构建、签名校验、Wi-Fi 覆盖安装与启动全部成功；随后短题试学版将 Pathos 从 0.15.0 build 30 更新到 0.16.0 build 31。更新前后 Preferences 比较确认 340 XP、11 条完成记录、6 个旧草稿及旧结算历史保留，schema 2 → 3 的 pre-v3 原始备份与更新前字节相同。实际应用标识沿用 com.perinchiang.wanggan.4DB63U52PY，未卸载、未传重置参数。随后 build 32 修复答后选项上移，三个针对性 UI 检查通过并再次 Wi-Fi 覆盖安装 / 启动；本次 7 个草稿及既有记录保留，见 [反馈布局修复交接](handoffs/2026-10-08-feedback-overlay-handoff.md)。当前 profile 有效期到北京时间 2026-10-15 01:21:30，需要时重新签名部署。

随后按 Patrick 要求将七题「1-1」及精简题内提示的 0.17.0 build 34 通过 Wi-Fi 覆盖安装并启动于同一 iPhone；更新前后 340 XP、11 条完成记录、6 个草稿及 52 条结算记录保留，见 [七题更新交接](handoffs/2026-10-08-everyday-questions-handoff.md)。沿用原 bundle ID，不导出 IPA，不传测试或重置参数。

当前工具支持 console 连接：

```sh
xcrun devicectl device process launch --device "$DEVICE_ID" \
  --terminate-existing --console "$DEVICE_BUNDLE_ID"
```

console 等待 App 退出，Ctrl-C 的信号会转给 App；它提供标准输出 / 错误，不是完整统一系统日志。需要系统日志或崩溃诊断时，可用 Console.app、诊断工具或一次性的 Xcode 调试。build / install / launch 与用户看见的交互效果分别记录。

出现 `No Accounts` / `No profiles` 时先完成首次账户与 profile 配置，不能靠 `CODE_SIGNING_ALLOWED=NO` 安装未签名 App。仍可独立验证真机目标编译：

```sh
xcodebuild -project WangGan.xcodeproj -scheme WangGan -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/device-unsigned CODE_SIGNING_ALLOWED=NO build
```

该结果只证明编译能力。本项目无额外 capability 配置；将来增加 capability 才按需配置签名。日常部署直接安装签名 `.app`，无需为了验证小改动导出 / 下载 IPA。

## GitHub Actions 的职责

保留现有 `.github/workflows/ios.yml` 和 scopes。相关代码、资源、脚本与构建配置的 PR 运行 Core / Web + Simulator 编译；push 不自动运行，纯文档 PR 不占 macOS build。手动 quick 为编译，package 为未签名 IPA，home / smoke 为短题与旧播放器兼容 UI，full 为全部现有 UI + IPA。CI 是干净环境回归与交付保险，本地负责高频反馈。PR 检查是否 required 由仓库分支保护另行配置，本轮未修改远端设置。

不触发云端工作流来代替已能执行的本地检查。若需要最终 artifact，手动选择真实候选分支，并记录 commit、版本和执行范围；不能把前一提交的 CI 当作新提交验证。对外交付 IPA 的版本规则继续见 AGENTS。

依据：[Apple 命令行工具](https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference)、[Apple 无线真机连接](https://help.apple.com/xcode/mac/current/en.lproj/dev3e2f4ee6d.html)。具体 flags 以当前 Mac 的 `xcrun devicectl help`、`xcrun simctl help` 与实际命令结果为准。
