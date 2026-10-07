# 2026-10-06 家用网络故事课原生重做 Handoff

> 历史记录：文案方案与样板课建议已由 [2026-10-07 中文表达修复](2026-10-07-chinese-copy-root-cause-handoff.md) 更新，不作为当前语言范本。原工程验证仅适用于原提交；未完成的图示与布局修复仍保留。

## Current task / 本轮任务

Pat 对 0.7.0 漫画方向 PR #1（`codex/comic-home-network`，7.8MB AI 插画 + 复制粘贴的死题目内容）不满意，拍板：关闭 PR、放弃 AI 生图路线、用苹果原生平面图（SwiftUI + SF Symbols）重做第一课「宽带师傅为什么装了两个盒子」，并把它做成符合完整教学闭环的样板课。

## Completed / 已完成

- **关闭 PR #1**；从 `codex/ipv4-introduction`（6f06436）拉出新分支 `feature/home-network-native`，漫画机制与插画资产不进主线。
- **Core：`Sources/Core/Topology.swift`** —— `TopologySpec` / `TopologyNode` / `TopologyLink` 数据模型与校验（id 唯一、link 引用完整、flow ≥ 2 节点且唯一、accessibilitySummary 非空）；`maxStage` / `flowStage` / 按阶段过滤 helper。
- **Lesson 集成**：`Lesson.topology` 可选字段；目录校验要求 topology 与 ipv4Foundation / ipv4Visual / ipv4Introduction / subnetMaskIntroduction 互斥、explanation 非空、`maxStage ≤ explanation 段数 + 1`（防图文脱节）。
- **App：`Sources/App/TopologyDiagram.swift`** —— 数据驱动原生拓扑图：网格布局、节点（SF Symbol + 标签 + paper 底色）、连线（实线有线 / 虚线 + Wi-Fi 记号无线）、折线数据包流动画（trim 描线 + 圆点行进，重复 2 次）；按 stage 渐进揭示（opacity + 缩放过渡）；Reduce Motion 直接切静态完成态；VoiceOver 合并为单元素朗读 `accessibilitySummary`。
- **接线**：`ConceptIllustration` 新增 topology 分支（新增 `stage` 参数，默认全显）；`StepLessonPlayer` 讲解阶段传入 `visibleTextCount + 1`，实现「一段讲解出一个节点」的节奏。
- **课程内容 `Resources/lessons.json`**：新增第 1 章「故事 · 家里的网络从哪里来」与 `home-two-boxes` 课——3 条场景 → 初始预测（三个选项分别对应「备用冗余 / 接入vs组网分工 / 路由器只是天线」三个真实误解）→ 拓扑图 5 段渐进揭示（光纤→光猫→路由器→手机电脑，全部出现后数据包沿 光纤→光猫→路由器→手机 流动）→ 连线练习（工作↔盒子）→ 迁移判断（朋友家只有一个盒子 → 一体机）→ 总结。无插画资产，无 reviewItems。
- **测试**：
  - `Tests/CoreTests/TopologyTests.swift`：spec 校验（合法/重复 id/悬空 link/flow 缺节点/空 flow/空 summary/自环）、stage 预算、flowStage 跟随 flow 节点、新课标准步骤完整走通（含 questionIndex / matchingIndex / challengeIndex 断言）、目录拒绝超预算 stage（JSON 变异后 validate 抛错）。
  - `LearningTests.testAllShippedLessonsAreConsistent` 加入 `home-two-boxes`；`StepPlanTests.testMigratedLessonsPlayThroughToCompletion` 同步。
  - UI 测试：新增 `testHomeTwoBoxesFlow`（完整流程 + 拓扑图分阶段截图证据 H01–H04 + 30 XP + 下一课推荐）；所有种子测试的 XP 预期随新课插入整体 +30（role 60 / format 90 / binary 120 / subnet 180 / arp 210 / hop 240 / dns 270 / seed-completed-course 270）。
- **文档**：DESIGN.md 用「原生拓扑示意图系统」整节替换「手绘分层教学系统」（记录路线决定与理由）；COURSE_GUIDE.md 第 1 章标记已实现形态；ARCHITECTURE.md 登记 Topology 文件；README.md 更新为 9 节主线 + 2 节归档。
- **版本**：`project.yml` 0.6.2/15 → **0.7.0 build 17**（PR #1 的 0.7.0/16 IPA 从未交付，版本号不冲突）。

## Decisions made / 本轮关键决策

1. **原生组件取代 AI 生图**：示意图是教学内容（要分阶段、跟随讲解、承载数据流），位图做不到；改 JSON 即改布局，Dynamic Type / VoiceOver / Reduce Motion 全部免费继承。DESIGN.md 已固化为规范：位图 / AI 插画不进入课程页面。
2. **渐进揭示节奏**：节点 `stage = 讲解段落序号 + 1`，图示与文字共享推进节奏，无需改步骤引擎——纯视觉层参数。
3. **课程内容设计**：错误选项对应三个真实误解（冗余备份 / 职责按「上网 vs Wi-Fi」切分 / 数量≠完整性）；迁移判断换条件（朋友家单盒子 → 一体机），直接测试 takeaway 的「可以分工，也可以合在一起」。
4. **此前误报修正**：`ipv4-address` / `subnet-mask` 两课并非孤儿——它们经 `course.archivedLessonIDs` 正式归档（草稿保留、不进推荐与解锁），无需清理。
5. **PR #1 的教训写进 DESIGN.md**：agent 把图一股脑塞进页面而不设计课程，根因是生产工具（AI 生图）绑架了课程设计。

## Not completed / 尚未完成

- 第 1 章后续两课（测速 / 公网 IP、NAT「出去以后看到谁」）尚未设计实现。
- 归档的 `subnet-mask` 试验课内容未来可回收进第 2 章后续，未动。
- 旧 `ci/comic-0.7.0-build16` 远端分支未删除（留给 Pat 决定）。
- CI 已运行两轮：第一轮因旧课程顺序断言失败，第二轮 Core / Web / iPhone 编译均通过，UI 剩两个按钮文案断言失败。已对齐「完成本课」文案，最终全套复验与 IPA 导出待本轮完成。

## Known issues / 已知问题

- 拓扑图固定高度 200pt，超大 Dynamic Type 下标签靠 `minimumScaleFactor(0.6)` 兜底，未做专门的大字号布局验收（与 NetworkDiagram 现状一致）。
- `TopologySpec` 的 column / row 为自由网格坐标，恶意数据可画出重叠节点；当前由内容评审保证，校验只查引用与预算。
- 远程仅 `main` 与本分支时，`git fetch` 默认 refspec 曾漏拉其他分支；如需在本地看全部分支需显式 `git fetch origin <branch>`。

## Verification / 已做验证

- **JSON 全量校验（Node 模拟 Swift 校验规则）**：目录 ID 覆盖（archived + ordered == lessons）、topology 全部约束、question / challenge correctID、matching solution 双向吻合、scene id 唯一、sources https——全部通过。
- **静态走查**：对照 `LessonPlan` 逐步核对 Core 测试推进序列与 UI 测试点击序列（提交反馈 / 「看看为什么」推进 / matchPair 即时锁定 / challenge 两击完成 / +30 XP 结算）；修正了上轮遗留的 4 处问题——TopologyTests 差一步 advance（`submitChallenge` stepIndex 守卫会静默失效）、3 处 UI 测试 XP 断言未偏移、H02 截图时机在提交反馈而非图示步。
- **第一轮 CI（`fc7a2f7`，[37475768340](https://github.com/perinchiang/wanggan-ios/actions/runs/37475768340)）**：62 项 Core 中 11 个断言失败，集中在 4 个仍假设 IPv4 基础课为路线首课的用例。`541bf11` 已修正课程选择与推荐预期。
- **第二轮 CI（`541bf11`，[37478002587](https://github.com/perinchiang/wanggan-ios/actions/runs/37478002587)）**：Core、Web、iPhone 目标编译通过；17 项 UI 用例中 12 项通过、3 项旧归档试验课跳过、2 项失败。`testHomeTwoBoxesFlow` 完整流程通过；失败均来自共享 helper 期待「完成探索」，实际基础课按钮为「完成本课」。本轮仅对齐该测试文案，不改应用代码、课程、版本或存储。
- **截图复核发现的新问题**：第二轮 H02 只有「光纤入户」标签而没有图标，模拟器日志明确记录 `No symbol named 'cableconnector'`；H03 实际在配对页，不构成完整拓扑证据。已改用有效系统符号 `cable.connector`，增加当前可见节点的可访问值、逐阶段 UI 断言、运行时符号存在性检查，并在讲解页拍完整拓扑。因课程资源与 App 可访问属性改变，候选升为 **0.7.0 build 18**。
- **第三轮（`04858b0`）**：发现上述问题后主动取消，避免继续花额度验证已经过期的 build 17 候选。修复合并后再运行一次全套。
- **尚待验证**：build 18 全套 UI 复验与 IPA 上传；真机试学、完整 VoiceOver 和拓扑图大字号验收未执行。

## Next recommended task / 推荐下一步

1. Agent 在本分支继续触发完整 iOS 工作流（0.7.0 build 18），复验两个基础课用例、有效符号、拓扑渐进呈现与全套流程，成功后下载 IPA 和截图。
2. CI 通过后合并进主线并真机试学，重点验收：拓扑图渐进揭示节奏、数据流动画时机（第 3 段讲解起跑）、VoiceOver 整图朗读。
3. 试学满意后，以本课为样板设计第 1 章第 2 课（测速 / 公网 IP），复用 TopologyDiagram。
