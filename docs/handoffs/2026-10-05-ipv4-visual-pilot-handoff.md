# Handoff: 阶段 E IPv4 地址可视化试点

日期：2026-10-05

状态：后续修复与定向验收已完成，0.2.0 build 6 IPA 已导出。最终交付信息见 [发布交接](2026-10-05-ipv4-visual-0-2-0-release-handoff.md)；下文保留本轮诊断经过。

## Current task / 本轮任务

在子网课接入一个本地 IPv4 地址图示，复用同一组件讲解 `/24` 并练习 `/16`，保持既有五课进度和奖励。

## Completed / 已完成

- 新增离线 HTML 图示：按字节展示十进制与二进制，用网络位 / 主机位颜色和文字说明边界；同一入口接收 `192.168.1.10/24` 与 `10.20.30.40/16` 两组参数。
- 子网课先展示讲解示例，再让用户点选练习地址的网络边界；网页只回传所选字节，Core 校验，答对才可继续。答错可重选，不提前展示练习答案。
- 通过本地 WKWebView 加载；提供暂停 / 重播 / 单步、后台暂停、动态字号、Reduce Motion、深浅色参数、可访问的按钮与网页失败时的原生文字替代。
- 练习阶段、所选字节与结果写进现有可选草稿字段；旧草稿仍可解码。更新 Core、Web 与原生 UI 检查，并把候选版本升至 0.2.0（build 6）。
- 修正大字号下二进制超出卡片的问题：列数随字号与可用宽度调整，在手机常见内容宽度下自动改为一列。

## Decisions made / 本轮关键决策

- 只给确有教学用途的子网课配置可视化参数，播放器依据可选内容配置显示，不按 Lesson ID 复制页面或 HTML。
- 原有 `LessonSession` 存储键与 schemaVersion 不变；新增字段可选，旧版子网课草稿从原讲解位置继续，不强制重做新练习。
- 图示失效时，原生文字替代提供同一选择和 Core 判定，不能跳过必要练习。

## Not completed / 尚未完成

- iPhone 实际安装、VoiceOver 与大字号体验仍需真机验收；浏览器截图不能代替 WKWebView 验收。

## Known issues / 已知问题

- `LearningStore` 课程加载失败时可能清草稿、未知 schema 恢复路径不足的既有风险未在本轮改动。
- App 当前强制浅色；图示具备深色参数和样式，但完整 App Dark Mode 尚未交付。
- 首次 CI 在第一项 ARP 测试的第二次 App 启动处停滞，未进入 IPv4 流程，35 分钟后任务自动取消；没有 UI 断言结果或有效 xcresult。已移除四课流程测试之前的冗余 App 启动，具体停滞原因未确认。
- 定向补跑 37284825668 在首次启动后找不到 `lesson-subnet`，失败录像和最终截图只见模拟器桌面，没有进入新图示。尚不能区分 App 启动失败与自动化问题；下一次检查先独立安装启动，收集启动画面、运行日志及崩溃记录。
- 诊断运行 [37287085627](https://github.com/perinchiang/wanggan-ios/actions/runs/37287085627)（提交 `4595302`）未开始执行任何步骤；GitHub 注明最近账户付款失败或需要提高支出限额。已停止触发 Actions，不能断言只是免费分钟用尽。
- 用户已授权将 `perinchiang/wanggan-ios` 公开，现已确认 PUBLIC；公开后的运行 37290140620 正常启动，不再受此前账单拦截。
- 运行 37290140620 的两份 `.ips` 确认启动中止原因：Xcode 16.4 / iOS 18.5 模拟器缺少可见的 `libswiftWebKit.dylib`，属于 [WebKit 293831 的已知问题与 Apple 工程师提供的修复方式](https://developer.apple.com/forums/thread/785964)。新增仅用于模拟器的运行库链接脚本；真机包不加入这份库、不改变 iOS 17 最低支持版本。补跑验收前不宣称修复已通过。
- 运行 37292246799 已证实运行库修复生效，App 启动、首题续学和实际 WKWebView 讲解显示通过。练习选择检查失败于测试查询：snapshot 中四个 `aria-pressed` 控件的 native elementType 是 40，而普通 Button 是 9，原 `.buttons` 查询漏掉它们。已改成 WebView 内按同一可访问标签查找控件；尚待补跑完整子网流程。

## Verification / 已做验证

- 本地 Node 测试覆盖两组地址、非整字节前缀、非法输入、练习提交前隐藏答案和网页选择回调。
- 在 Chromium 本地预览浅色讲解及大字号深色练习，检查四个可点击边界、文字换行与不提前显示答案。
- 提交 `9a49185` 的手动运行 37280539186：Core 测试、Web 测试、iPhone 构建和 HTML 入包检查通过；模拟器 App 和 UI 测试源码也编译完成，但首项 ARP 测试在启动 App 时停滞后超时。不能记为 UI 通过。
- 增加 UI 检查范围 `full` / `ipv4` 和输出停滞限时保护；本地验证保护脚本的正常退出、失败退出与静默超时路径。
- 提交 `7920957` 的定向运行 37284825668：Core、Web、iPhone 编译与 HTML 入包再次通过，子网原生测试在课程入口之前失败，不能记为 WKWebView 通过。诊断材料保存在工作区 `WangGan-0.2.0-build6/verification-37284825668`。
- 最新 HTML 大字号布局在 Chromium 检查了 276 / 320 / 350 / 386 像素宽度与 1 / 1.3 / 1.65 / 2.2 字号倍率共 16 组，页面及二进制无横向溢出；再次执行两项 Node 测试通过。此布局改动尚未进入 iOS 构建。
- `git diff --check` 通过；Windows 无 Swift / Xcode 工具链，本地运行检查仍只有 Web 和保护脚本。
- 提交 `3ba57a7` 的运行 37290140620：Core、Web、iPhone 包编译通过，模拟器 App / UI 编译通过；独立启动与 XCTest 启动均因 DYLD Library missing 中止。资料位于工作区 `WangGan-0.2.0-build6/verification-37290140620`。
- 运行库脚本本地用临时路径检查了选中 runtime、库链接、重复执行和其他工具链跳过逻辑，尚待真实 macOS 执行。
- 提交 `291788a` 的运行 37292246799：Core、Web、iPhone 编译及模拟器启动通过；实际讲解截图 `12-ipv4-explanation` 与失败 snapshot / 录像中的练习画面均已检查。子网完整流程仍未通过，尚无交付 IPA。
- 在 Chromium 验证重播、暂停后位数不再增长、单步增加一位和 Reduce Motion 直接显示完整分界。
- 最终提交 `92b2dac` 的运行 [37294516851](https://github.com/perinchiang/wanggan-ios/actions/runs/37294516851) 成功：27 项 Core、2 项 Web 与 1 项子网原生流程通过，确认真实 WKWebView、错误改选、退出恢复、完成与累计 XP 60。IPA 版本 / 资源与实际讲解、练习、完成截图已核对；本轮未重跑其余四课 UI。

## Next recommended task / 推荐下一步

使用 0.2.0（build 6）覆盖安装做真机及可访问性验收，验收后按 PRODUCT 推进 F 短复习与掌握证据。公开后仍保持仅手动构建，不因普通 commit 自动跑 IPA。
