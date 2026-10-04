# Handoff: 阶段 D 最小学习引擎（第一步）— Core Step 引擎

日期：2026-10-05

## Current task / 本轮任务

阶段 D「最小学习引擎」第一步：在 Core 落地 Step 模型与步进门控，把旧 Lesson 通过适配器映射为等价步骤；暂不切换播放器。

## Completed / 已完成

- `Sources/Core/LessonPlan.swift`：`StepKind` / `StepPayload`（有类型 payload，自定义 Codable）、`LessonStep`、`Lesson.steps` 适配器（场景对话 → 问题 → 图示 → 讲解文本 → 连线 → 追问场景 → 追问 → 小结）、`LessonPlan`（步进门控 canAdvance / advance，提交与重试）、`StepSession`（stepIndex 光标 + 作答状态）。
- `Tests/CoreTests/StepPlanTests.swift` 新增 5 个用例：五课步骤推导一致性、gateway 全通关、追问答错需重试且计错、Step/StepSession 编解码往返、**新旧状态机等价对照**（同一作答脚本下 StepSession 与 stage 状态机的 mistakes / 完成状态一致）。
- `ARCHITECTURE.md`：当前实现表与目标模型段落同步。

## Decisions made / 本轮关键决策

- 阶段 D 拆两步：先 Core 引擎（本轮），再播放器迁移（下一步）。理由：Windows 无本地工具链，一次只迁一个可验证边界，播放器迁移时旧 stage 路径继续服务。
- 步骤推导不引入新内容：`Lesson.steps` 完全从现有五课内容派生，五课 ID 与 lessons.json 不变。
- StepSession 使用稳定 stepID 结构（`<lessonID>.<phase>[.<item>]`），为后续"会话按 stepID 保存位置"打基础；本轮不接入存储，不产生迁移。
- 门控语义与旧状态机逐条对齐：对话/图示/文本可推进；问题需已提交；连线需已解对；追问需解对后直接跳小结。

## Not completed / 尚未完成

- 播放器尚未切换到 StepSession / LessonPlan 路径（阶段 D 第二步）。
- StepSession 尚未接入草稿持久化与结算（迁移留到播放器切换时做）。
- HTMLVisualization 等 Step 类型未引入。

## Known issues / 已知问题

- 新旧状态机等价性目前只有 gateway 一课的对照用例；其余四课等价性可后续补（结构相同，风险低）。
- 其余基线风险不变（见 docs 基线 handoff）。

## Verification / 已做验证

- `git diff --check` 通过；静态推演新旧状态机 step 索引与 stage 转换逐段对齐。
- 推送 main 触发 GitHub Actions 运行 37241174964 通过：Core 测试（含 5 个新 StepPlan 用例）、真机无签名构建 + IPA、原生 UI 测试全部成功。首轮失败原因是测试脚本漏算 diagram 步骤的推进次数（step 模型比 stage 模型多一个图示步骤），已修正脚本并重跑通过；引擎代码本身无改动。

## Next recommended task / 推荐下一步

阶段 D 第二步——`LessonPlayer` 迁移到 LessonPlan / StepSession 路径（先 gateway 一课等价切换，保留全部 accessibility 标识符与 UI 测试），再按需接入草稿保存与结算。
