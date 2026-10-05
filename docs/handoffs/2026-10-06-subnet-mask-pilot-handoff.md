# 子网掩码入门 Pilot

## Current task / 本轮任务

Pat 于 2026-10-06 明确确认 0.4.0 IPv4 入门试学通过，要求继续子网掩码课。按 ROADMAP 推进独立基础 Lesson 与 Teaching Interaction Kit 首次真实 Pilot。

## Completed / 已完成

- 新增 `subnet-mask`，紧接 `ipv4-address`；目录 revision 3，试学候选 0.5.0 build 11 / `7eebd0c`。原六课及短复习内容、原内容数组顺序保持。
- [Lesson 设计稿](../course/subnet-mask-lesson-design.md) 记录主要知识原点、最小先修解释、原创场景、误区、迁移题与来源核对。
- 参数化原生掩码面板：同一地址 → 点网络 / 主机字节拆解 1 / 0 → 切 `/24` / `/16` → 独立选择 `/8` 分界。练习提交前隐藏答案分区，Core 核对选择，错可改选。
- 四阶段按钮 / 说明区左滑回看，观察与练习语义状态保存；可选 `subnetMaskProgress` 经 stage↔step 双向转换保留。旧 JSON、较远主线 / 补课 / 复习草稿兼容检查已补充。
- 保留原五课、IPv4 Web 图示、存储键、schemaVersion 1、XP 与每日奖励规则。
- 核对 0.4.0 修正后 CI 已通过，补记原交接与本地 verification-summary；没有复用其结果来证明新版本。

## Decisions made / 本轮关键决策

- `focus-annotation`、`decompose-compose`、`condition-toggle` 由本课原生视图组合为首次 Pilot；不新增通用注册表，不按 Lesson ID 分支，不为了统一重写既有 Web 组件。
- 参数只支持三种不同的字节边界 8 / 16 / 24；一般前缀计算覆盖 0～32，数学支持不等于全部教学覆盖。两组配置 Core 验证不构成第二节真实复用。
- 新课提供当前路径缺少的前缀 / 网络主机角色最小解释，暂不实现网络地址按位与、主机数或通信推理。随后再改造原 `subnet` 应用课。
- 保留来源内容数组的旧顺序，显示顺序由章节目录决定；涉及网关专有选项的旧回归 fixture 改用稳定 ID。

## Not completed / 尚未完成

- Pat 对新课的实际试学、学习时长、完整 VoiceOver / 真机与后台验收。
- 原 `subnet` 内容改造、完整基础课程、交互模板第二次真实复用与 Reusable / Stable 升级。
- 开始本轮时已有一组未提交文档修改；它们保留在工作区，本轮代码候选提交不顺带提交这些旧改动。

## Known issues / 已知问题

- App 整体仍强制浅色，没有教学声音系统。
- 独立前缀 / 网络主机课尚未展开，本课只提供其必要最小解释；是否拆分依试学调整。
- 中文教材 §1.2.1 纸书 pp.27–28 / PDF pp.52–53 已视觉核对，Top-Down §4.3.2 已定向查阅；技术事实以 RFC 4632 §3.1 为主。书文件 / 页图不纳入交付物。

## Verification / 已做验证

- 本地 4 项 Web 回归通过；JSON / 章节引用、原六课与 4 条短复习逐项一致，36 条本地文档链接与 `git diff --check` 通过。
- 首轮 [37373715707](https://github.com/perinchiang/wanggan-ios/actions/runs/37373715707)，`e361453`：新 7 项 Core 通过，但旧测试按数组首项取网关导致 7 个断言失败，流程停在 Core、没有导出 IPA。
- `d9fa874` / [37374010824](https://github.com/perinchiang/wanggan-ios/actions/runs/37374010824)：48 Core 与 4 Web 通过；iPhone 编译发现测试入口试图覆盖只读 accessibilityReduceMotion 环境值，未导出 IPA。
- `949903b` / [37374372103](https://github.com/perinchiang/wanggan-ios/actions/runs/37374372103)：48 Core、4 Web、iPhone 编译通过；新课完整流程、最大字号 / 静态呈现与旧子网 UI 通过，旧 IPv4 入门首次 Web 点选后未启用继续按钮，未上传 IPA。已检查新课真实模拟器截图。正式使用读取系统 Reduce Motion，测试使用显式静态参数；静态分支自动测试不等于实体设备切换系统 Reduce Motion 已验收。
- `23d1918` / [37376691523](https://github.com/perinchiang/wanggan-ios/actions/runs/37376691523)：候选 build 10 在最终复核发现双向切换文字问题后主动提前停止。旧 Web 控件点击等待布局稳定、保存点击前截图并点击可见卡片中心，不重复点击绕过断言；增加主线续学与短复习隔离回归。此 run 不作为交付通过证据。
- `7eebd0c` / [37376881904](https://github.com/perinchiang/wanggan-ios/actions/runs/37376881904)：候选 build 11 已通过。48 Core、4 Web、iPhone 编译、6 项原生 UI 全部通过：掩码完整流程 / 双向切换、最大字号 / 显式静态呈现、原 IPv4 入门、原子网、整课主线 / 复习隔离、短复习隔离与奖励幂等。没有重跑其余 6 项 UI。旧 Web 点选回归通过；等待稳定布局与可见卡片中心点击是测试修正，首次失败的单一原因未被独立证实。
- 已检查本轮实际模拟器截图：切换后的角色与说明一致，正确练习结果和底部动作可见；最大字号的长内容使用纵向滚动。
- 安装包核对：`0.5.0` / `11` / `com.perinchiang.wanggan`、7 课目录、HTML 与 Assets 均存在且与候选内容一致；没有参考书 PDF。SHA-256：`3d18107613eb30fedcff6e0356efa23aa79d401521f656a152b2d443f1aa044c`。
- 本地输出位于 `../WangGan-0.5.0-build11/`（相对仓库根）：`WangGan-0.5.0-build11-unsigned.ipa`、`verification-summary.json`、`workflow.log`、`verification/`、`screenshots/`。用原 Apple 账户 / 应用标识覆盖安装，不先卸载；实体设备结果仍待 Pat。
- Windows 无 Swift / iOS 本地工具链；不把本地静态检查当作 iOS 运行验证。

## Next recommended task / 推荐下一步

候选运行验证、安装包与实际模拟器截图已完成，由 Pat 试学路线中的「子网掩码怎样划分地址？」。重点反馈 1 / 0 与前缀衔接、条件切换是否清楚、回看 / 续学和整体时长。ROADMAP NOW 仍是本 Pilot 验收，不自行越过试学去改造 `subnet`；反馈通过后再提升下一项。
