# 双向连线集中 CI 验证

## Current task / 本轮任务

Pat 指出 AGENTS 要求界面改动通过 macOS / GitHub Actions 编译与原生 UI 验证。本轮补齐上轮双向连线源码的运行证据。

## Completed / 已完成

- 候选提交 `e58f1375df6e392ed382452437184f074a193ba1` 已 push 到 `codex/ipv4-introduction`。
- 提交只含 MatchingView、原生 UI 测试、project.yml、iOS 工作流四个文件；已有课程规划 / 文档未提交改动继续保留。
- 连线两侧起选、改配、取消、清空与正确后锁定均加入代表性原生测试；点击助手对匹配按钮也避开固定页脚遮挡。
- 工作流恢复仅 `workflow_dispatch`，移除上批临时 push 触发，遵守 AGENTS 集中手动验证的策略。
- 候选版本 **0.6.1（build 13）**，避免导出内容不同但版本相同的 IPA。
- 已手动触发 [GitHub Actions 37429619985](https://github.com/perinchiang/wanggan-ios/actions/runs/37429619985)，UI scope 为 foundation（前三课与 Hop）。
- 本次运行已完成，最终结果 **success**；52 Core、4 Web、iPhone Release 编译与 4 项原生 UI 全部通过。
- unsigned IPA 与验证日志 / 模拟器截图已下载到 Windows，并核对安装包实际版本、bundle ID 和资源。

## Decisions made / 本轮关键决策

本轮验证双向连线小修复，前三课零题目线性教学仍是待实现教案，不混称已上线。日常可积累小改动；本次用户明确要求补齐阶段性运行验证，因此集中执行一次完整流程。

## Not completed / 尚未完成

- 实体 iPhone、完整 VoiceOver / 最大字号专项验收。
- 无题课程编排与新版前三课线性动画。

## Known issues / 已知问题

本地 Windows 没有 Swift / iOS 工具链，原生证据来自本次 macOS Actions；不能沿用 build 12 的旧结果。本机 GitHub CLI 当前可用，已通过仓库 API 和实际 dispatch 验证，与旧 handoff 认证失效记录有变化。

## Verification / 已做验证

- `git diff --check` 通过；核对候选只有上述四个实现 / 验证文件。
- macOS Actions 的本次提交日志：52 Core tests / 0 failures；4 Web tests / 0 fail；device 日志含 BUILD SUCCEEDED，模拟器编译含 TEST BUILD SUCCEEDED。
- 4 原生 UI / 0 failures：`testHopResumesAndCompletesOnStepPlayer`、`testIPv4FoundationAddressRoleFlow`、`testIPv4FoundationFormatBacktrackingResumeAndCompletion`、`testIPv4FoundationOctetBinaryFlow`。地址作用课确实执行双向起选、同侧换选 / 取消、两端冲突改配、错误后修正、清空及答对锁定断言。
- 已查看实际 iPhone 15 Pro 模拟器的双向连线截图与完成截图。匹配卡片、连接、双向起选提示和检查按钮正常可见；不是 VoiceOver 全流程或最大字号专项证据。
- IPA 内 `CFBundleShortVersionString=0.6.1`、`CFBundleVersion=13`、`CFBundleIdentifier=com.perinchiang.wanggan`；lessons.json、ipv4-address-visual.html、Assets.car 均存在。
- 本地 IPA：`C:\Users\Administrator\Downloads\WangGan-0.6.1-build13-unsigned.ipa`。
- 本地证据：`C:\Users\Administrator\Downloads\WangGan-0.6.1-build13-CI-37429619985\verification\`。
- IPA SHA256：`f8a269dec5dafbb00d606130733b23f83564c7a22798d48ba92c8041401835fc`。

## Next recommended task / 推荐下一步

本次连线集中验证已完成。Pat 可按需覆盖安装 0.6.1 build 13 验证双向连线；实际 iPhone 体验仍未验收。之后按 ROADMAP 推进无题课程编排及线性演示，不进入 Lesson 4–5。本轮源码证据对应 e58f137，后续仅文档提交不要求再跑一轮 IPA。
