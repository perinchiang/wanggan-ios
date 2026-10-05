# Handoff: IPv4 可视化 0.2.0 交付

日期：2026-10-05

## Current task / 本轮任务

完成阶段 E 的原生验证，并导出 0.2.0（build 6）供 iPhone 覆盖安装。

## Completed / 已完成

- 子网课离线图示讲解 `/24`，随后点选 `/16` 的网络分界；Core 判定，答错可改选，练习状态随草稿保存。
- 定位启动失败：Xcode 16.4 / iOS 18.5 模拟器的 WebKit 运行库路径问题。按 Apple 工程师提供的方式，在模拟器构建目录链接 runtime 中的库；真机 IPA 不含此补丁库。
- 根据失败 snapshot 修正原生测试的控件查询，使用 WebView 内的可访问标签找到带 `aria-pressed` 的选择控件。
- 核对实际模拟器讲解、练习成功与完成截图；练习反馈完整显示在底部按钮上方。
- 下载并检查 IPA：0.2.0 / build 6，bundle identifier 为 `com.perinchiang.wanggan`，五课 ID 和离线资源完整。

## Decisions made / 本轮关键决策

- 用户授权后仓库已公开，公开构建正常启动。仍采用手动、阶段性构建，普通 commit 不触发 Actions。
- 不提升最低 iOS 17 支持版本，不绕过真实 WKWebView，不清空旧进度。
- 新增可选草稿字段保留旧格式；已有讲解草稿从原位置继续，不强制重做新练习。

## Not completed / 尚未完成

- 真机覆盖安装、VoiceOver、大字号、后台返回和网页失败替代流程仍需实体设备验收。
- 本轮仅跑子网原生流程；其余四课最近的原生 UI 验收属于 0.1.4，不记为本轮全套通过。

## Known issues / 已知问题

- App 当前仍强制浅色；组件深色参数不代表完整 App Dark Mode 已交付。
- 既有课程加载失败时的草稿清理及未知 schema 恢复风险未在本轮扩大处理。
- 模拟器运行库补丁限于 Xcode 16.4 / iOS 18.4-18.5；换工具链后会跳过，升级时须检查对应运行环境。

## Verification / 已做验证

- IPA 对应提交：`92b2dac22f27a704426e6800888af0dca78173a4`。
- 手动运行：[37294516851](https://github.com/perinchiang/wanggan-ios/actions/runs/37294516851)，成功。
- 27 项 Core、2 项 Web 测试通过；子网原生流程通过（98.648 秒），覆盖首题恢复、实际 WKWebView、选错第三字节、退出重启恢复、改选第二字节、连线 / 挑战、首次 +30 XP 与累计 60 XP。
- 本地 Chromium 检查 16 组宽度 / 字号组合，以及重播、暂停、单步和 Reduce Motion。此浏览器检查不能代替完整真机可访问性验收。
- IPA 检查包含 `lessons.json`、`ipv4-address-visual.html`、`Assets.car`；包内 HTML 与已测试源码完全一致；不含模拟器 `libswiftWebKit`。
- SHA-256：`fd9d3a970d2209ca77736e32230eb4cca85215946483974dd0068b3974864788`。
- 本地 IPA：`../WangGan-0.2.0-build6/WangGan-iPhone-unsigned/WangGan-unsigned.ipa`（仓库目录之外）。
- 日志 / 截图：`../WangGan-0.2.0-build6/verification-37294516851/`；易读截图为同目录上级的 `IPv4-explanation.png` 与 `IPv4-practice.png`。

## Next recommended task / 推荐下一步

先覆盖安装验收本版：在「复习」打开「谁才是我的邻居？」走到讲解，测试点选、改选、退出恢复；若恢复到旧草稿后半段，完成后再进入新一轮。使用同一安装身份与应用标识，不先卸载，以保留本地数据。验收后推进 F：少数知识点的短复习与掌握证据，让复习不必每次重做整节课。
