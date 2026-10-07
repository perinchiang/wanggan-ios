# 网感：系统架构与渐进迁移

状态：职责边界与数据保护原则已确认；当前只提供第一节示例课。通用组件和历史解码能力保留，其余目标模型仍是计划。运行证据见当前交接。

## 文档职责

本文件维护系统职责、模型方向、状态更新、持久化、迁移与测试。产品范围和阶段顺序见 [PRODUCT.md](PRODUCT.md)，课程内容见 [COURSE_GUIDE.md](COURSE_GUIDE.md)，视觉、网络动效与主题见 [DESIGN.md](DESIGN.md)，执行要求见 [AGENTS.md](AGENTS.md)。

## 当前实现：已实现

| 位置 | 当前职责 |
| --- | --- |
| `Sources/Core/Lesson.swift` | Course（id / revision / title）与 Chapter（id / title / orderedLessonIDs）目录模型；Lesson 固定包含 question / explanation / matching / challenge；课程与章节覆盖校验 |
| `Sources/Core/LessonSession.swift` | question → explanation → matching → challenge → complete；课内状态、重试和累计错误数 |
| `Sources/Core/LessonPlan.swift` | Step 类型与 payload（conversation / question / diagram / text / matching / summary）、Lesson→steps 适配、LessonPlan 步进门控、StepSession 及 stage↔step 双向适配 |
| `Sources/Core/ProgressLedger.swift` | 完成记录、XP / 等级、复习日期、活动日、结算会话、主线 draft 与 reviewDrafts |
| `Sources/App/StepLessonPlayer.swift` | 当前示例课走 `StepLessonPlayer`（LessonPlan / StepSession）；旧原生播放器与按 Lesson ID 分派的入口已移除 |
| `Sources/Core/IPv4AddressVisual.swift` / `Sources/App/IPv4AddressVisualWebView.swift` / `Resources/ipv4-address-visual.html` | 参数化 IPv4 校验、网络地址计算与本地 Web 图示；保留为技术组件，当前示例课未接入 |
| `Sources/App/AppStore.swift` | 加载课程、UserDefaults 编解码、解锁与推荐、保存及重置 |
| `Sources/Core/Topology.swift` / `Sources/App/TopologyDiagram.swift` | 数据驱动拓扑示意图：TopologySpec（nodes / links / flow / accessibilitySummary）在 Core 校验（id 唯一、引用完整、flow ≥ 2、maxStage ≤ explanation 段数 + 1），App 层按 stage 分阶段渲染节点、连线与数据包流动画；Lesson 可选 `topology` 字段，替代插画位图路线 |
| `Sources/App` 其余文件 | SwiftUI 导航、页面、原生题型和图示 |
| `Resources/lessons.json` | 仅第一节示例课内容与来源，无归档课程和短复习题 |
| `Package.swift` / `Tests` | 独立 Core 测试和 iOS 原生 UI 测试 |
| `project.yml` / `.github/workflows/ios.yml` | XcodeGen、macOS 构建、测试、截图和 IPA 导出 |

当前奖励规则：首次完成一课 +30 XP；已完成课之后每个本地自然日首次复习 +5 XP；首次完成当天重复学习不追加奖励；会话重复结算不重复加分。等级为 `totalXP / 100 + 1`。

当前复习：首次完成后次日复习，后续使用 1 / 3 / 7 / 14 天，错误可重置间隔级别。复习状态在每次有效完成后独立更新，不依赖当天是否发奖励：同日零奖励的错误仍重置级别并提前到次日，同日多次正确不能连续推进阶梯。

当前 schemaVersion 为 1，存储键为 `wanggan.progress.v1`。部分可选字段支持旧草稿解码，另有旧复习草稿归位逻辑；这不是完整的版本迁移框架。

## 网络词典与文本匹配（后期计划，非现有 API）

词典先以本地数据提供稳定词条 ID、名称、缩写 / 别名、简短释义与来源；Core 或独立纯函数按这些别名匹配文本，输出命中范围和词条 ID，原生界面负责波浪下划线、点词与释义小窗。匹配规则需处理大小写、词边界、重叠别名与标点，支持 IS-IS / ISIS 这类约定写法，避免简单子串替换造成误标。没有匹配项时保持普通文本。

独立词典入口和课内释义共享数据，不为两个入口维护两份解释。查词仅影响展示，不推进 Step、解锁课程或发 XP；打开 / 关闭小窗不修改答案和草稿。若某题的释义提供了影响独立作答的帮助，应在后续证据设计中按帮助处理，不能默认为独立掌握；复习体系暂缓期间不提前实现新的调度系统。词条与未来 API 形状仍是计划，不在本轮新增存储 schema、Web 消息或通用富文本框架。

## 已确认架构边界

继续一个 App 与一个可独立测试的 Core。先用普通结构体、枚举、纯函数与清楚的目录组织，不为每个系统创建独立 Package、服务框架或全局事件总线。

```text
课程 JSON → 加载与校验 → Core 学习状态与规则 → 持久化
                              ↕ 用户动作 / 结果
                       SwiftUI 页面与原生 Step
                              ↕ 直接宿主接口
                       本地 WKWebView 可视化
```

| 系统 | 负责 | 不负责 |
| --- | --- | --- |
| 课程 / 章节 | 内容组织、先修、解锁策略、推荐 | 用 XP 推断知识掌握 |
| Lesson 引擎 | 步骤、动作门控、恢复、完成条件 | 直接访问具体存储 |
| 可视化 | 参数化展示、动画与交互结果 | 发奖、判定课程解锁、保存业务账本 |
| 练习 | 答案校验、反馈、作答证据 | 将重试成功伪装成独立掌握 |
| KnowledgePoint / Mastery | 聚合知识点证据、可解释状态 | 从 XP 或观看时长推断能力 |
| 复习 | 内容选择、日期与薄弱项优先级 | 覆盖主线续学位置 |
| XP / 等级 | 奖励资格、幂等结算、等级 | 阻止零奖励学习更新证据 |
| 头衔 / 成就 | 按明确条件授予成果 | 改写学习证据或隐式阻塞课程 |
| 统计 / 打卡 | 聚合有效学习日期和活动 | 将打开 App 当作学习 |
| 本地进度 / 迁移 | 保存、备份、恢复、版本转换 | 因内容加载失败清理历史 |

SwiftUI 持有界面状态并发送动作，Core 持有学习规则；Web 只负责教学表现和局部交互。`LearningStore` 可继续作为页面使用的协调入口，逐步移出规则，不要求先替换状态管理方案。

## 目标数据模型：计划中，按需要引入

```text
Course: id, revision, title, chapters, progressionPolicy
Chapter: id, title, orderedLessonIDs, prerequisiteChapterIDs
Lesson: id, revision, objective, prerequisites, knowledgePointIDs, steps, reviewItemIDs, sources
Step: id, kind, typedPayload, completionRule
KnowledgePoint: id, objective, prerequisiteIDs, misconceptionIDs
ReviewItem: id, lessonID, knowledgePointIDs, scenarioFamilyID, steps
```

这是模型职责草案，不是要求一次添加所有字段。KnowledgePoint 独立定义并由多课引用；稳定 ID 不使用显示名称或章节序号。内容版本、Lesson 修订、存储 schema 与 Web 协议版本各自解决不同兼容问题。

Step 使用有类型的 payload，不把所有内容放入无约束字典。`conversation`、`question`、`diagram`、`text`、`matching`、`summary` 已在 Core 落地（`LessonPlan` / `LessonStep`），`Lesson.steps` 适配器把旧 Lesson 映射为等价步骤；当前示例课使用 step 路径。Sorting、PathChoice 等有真实课程需求后再增加。当前 IPv4 试点通过 `diagram` 步骤读取可选的 `IPv4VisualLesson` 参数，尚无通用 HTMLVisualization 类型。

Challenge 是练习角色 / 组合，不必复制一套专用答案状态。会话最终按稳定 stepID 保存位置，而不是只依赖枚举序号；兼容适配器先把旧 Lesson 映射为等价步骤。不要为验证播放器而同时重写全部内容。

### 课程进度

访问权、完成记录、推荐位置与掌握状态分别表达。第一阶段仍线性解锁，但规则位于 Core 策略而非 SwiftUI 数组索引。未来可配置章内线性、章间满足先修条件后半开放；暂不实现技能树。

已完成课保持可回看。插入基础课可以改变推荐建议，不能撤销旧成果或使旧课重新锁定。主线和复习有明确会话用途与独立草稿；先保留当前隔离行为，再按真实需求扩展多课程状态。

## 学习证据、Mastery、Review、XP：计划规则

实施状态：复习体系迭代暂缓。旧短复习题已移除，保留通用规则和历史证据；当前只可重学示例课，不据此扩展调度系统。

### 保留的通用短复习逻辑（当前无题目）

- `ReviewItem` 带独立 revision、所属 Lesson、知识点与场景族；当前 `lessons.json` 的 reviewItems 为空。通用逻辑支持一次一题；新会话轮换，未完成会话按 itemID / revision 恢复。内容修订不拿旧答案给新题结算，未知草稿不在启动时清除。
- `ShortReviewSession` 保存选择、提示使用及提交列表。`ReviewAttempt` 记录 UUID、会话、题目修订、Lesson / 知识点 / 场景族、时间和时区、所选选项、正确性、首次提交及提示；所选错误选项的稳定 ID 对应针对性反馈，不收集滑动或点击流水。
- ledger v1 新增可选 `shortReviewDrafts` / `reviewEvidence`。主线 draft、原整课 reviewDrafts、短复习草稿分别保存；旧格式缺少新字段正常解码，旧完成不迁移出掌握证据。课程加载失败时不规范化或清理历史草稿。
- 有效提交立即保存证据；同一 attemptID 不重复追加。错误立即把所属课调回次日，不必等完成或有 XP。提示后 / 重试后答对为「在帮助下完成」，不增长复习间隔。短复习与整课共用每课每日首次 +5，完成日无额外奖励，按 sessionID 幂等结算；有效学习日仍以完成会话为口径。
- 试点显示最新证据「还没有短复习记录 / 这次需要再巩固 / 这次在帮助下完成 / 独立答对过 / 隔天换场景也答对」。延迟证据要求首次无提示正确，且此前同知识点另一场景族有独立正确记录，至少相隔 24 小时并跨本地日期；同场景反复正确不升级为延迟证据。这些是可解释试点口径，不是完整 Mastery 算法或能力认证。
- 原整课重学仍可用，不把旧预测题或 Challenge 追溯成知识点证据。复习页按近期错误、到期日期、课序排列；不另建知识点队列或复杂记忆算法。

### 主动丢弃与中断恢复（0.8.0 候选）

- Core 的 `discardDraft` / `discardShortDraft` 只移除 lessonID 与 sessionID 同时匹配的草稿；旧会话不能清除同课的新会话。存储格式保持 ledger v1，不重置历史或奖励。
- 确认退出由播放器调用上述动作并持久化；退出期间停止该页面的自动保存，避免草稿被重新写回。取消退出不改变会话；后台与意外终止继续按原规则保存 / 恢复。
- 已提交短复习证据、复习日期、完成记录、settledSessions、XP 及其他课程草稿不撤回。
- 故事课移除的旧选项若出现在未完成草稿中，恢复为同会话 / 同阶段的未作答状态，保留错误次数与其他进度。稳定 Lesson ID、正确选项 ID 和持久化键不变。

### 最小证据

记录有效提交，包含 attemptID、lessonID / stepID / itemID、knowledgePointIDs、contentRevision、时间、场景族、正确性、是否首次提交、是否使用提示与误区。不要记录每一帧、每次滑动或全部点击历史。

保存相同作答不能重复产生学习证据。先由会话和提交动作本身保证单次处理，不为此预建分布式事件系统。

### Mastery

首版状态建议为「尚无证据」「正在建立」「能独立判断」「延迟后仍能判断」，另外标注近期需要巩固及相关误区，不提供缺乏依据的精确百分比。

看完讲解不自动掌握；首题预测与学后作答区分；提示后正确记录为在帮助下完成。同场景重复正确不能无限提高状态，延迟的新场景证据更有价值。具体状态阈值和衰减参数保持 Draft，在短复习试点中验证，不提前引入复杂记忆算法。

旧完成记录只证明完成，不能迁移出不存在的独立 / 延迟掌握证据。知识型成就条件与 Mastery 证据有关，具体阈值在功能实现时确定。

### Review

保留 1 / 3 / 7 / 14 天为基础阶梯。合格的独立正确复习可推进一级；错误缩短间隔、提高近期出现优先级。同日后续错误仍更新证据与调度；同日多次正确不能连续推进阶梯。先错后反复练对，不立即跳到最长间隔。

首版可按 Lesson 形成复习组，结合相关知识点的错误、掌握证据和上次复习时间选择 ReviewItem。不要同时搭建两套互相争夺调度权的知识点 / 题目队列。当前按课序展示的复习页不等于已经实现上述优先级系统。

复习会话可以更短，主动重学整课仍可用；二者都不修改主线位置。近期重现的具体次数和同日间距保持 Draft，避免机械重复形成负担。

### XP 与统计

先保留当前 +30 / 每课每日 +5 规则。短复习内多个 ReviewItem 共用所属 Lesson 的奖励资格，不能因拆题变成每题 +5；首次完成当天不额外获得复习奖励。结算重试返回原结果，不重复增加总 XP。

一次有效操作分别计算学习证据、复习、奖励与统计，再保存一致快照。奖励为零不阻止其他更新。未来跨课复习在引入前明确奖励归属，不能临时按题累加。

当前 activityDays 由完成会话产生；未来统计可增加有效练习事件，但必须先明确口径，不能把页面曝光算学习。记录事件时间和发生时的本地日期语境，避免跨时区后把历史热力图任意挪动；这属于未来 schema 设计，现有 Date 记录不能凭空恢复原时区。

## HTML / WKWebView：最小试点优先

### 第一版必须只满足 IPv4AddressVisual

IPv4AddressVisual 保留为参数化技术组件与 Web 测试对象；当前第一课完全使用原生图示，旧 IPv4 专用教案和播放器分支已删除。后续接入新课须重新设计交互并验证实际 WKWebView，不能沿用旧课验收结论。

建议仅有：一个本地 HTML 入口、一个 IPv4 组件、一个 SwiftUI WKWebView 宿主和直接通信方法。先用普通 JS / CSS / SVG，不为试点引入完整前端应用框架、插件加载器或构建平台。

最小输入：`ip`、`prefix`、教学阶段、讲解 / 练习模式、主题、字号与 Reduce Motion 配置。最小命令：初始化 / 更新、播放、暂停、重播、必要的单步及恢复语义状态。最小回调：ready、用户提交或必要状态变化、error；嵌入尺寸确实需要时再加高度回调。

上述播放命令是现有组件的内部能力；后续面向学习者的动作与分步界面遵守 DESIGN / COURSE_GUIDE，不要求把命令逐项做成可见控件。教学阶段推进与回看由 Core / 原生会话管理，Web 接收当前语义阶段并呈现；普通阶段按钮保持原生，具体图中操作留在组件内。0.13.0 候选在原生拓扑讲解与答后阅读序列内提供上一步；只移动当前阅读位置，保留答案、错误数与会话 ID，不回到已提交的题目、不从结算页倒退。答后页仍须读到最后才结算；重看动画不修改学习状态。不预建完整时间线编辑器。

原生图示的初始步骤以 `explanationIndex = -1` 保存；旧草稿的 0 仍表示第一段讲解，低于 -1 的无效值收敛到初始图示。IPv4 Web 练习继续用原有 phase / finished 字段，保留 explanationIndex 0，避免破坏旧草稿等价恢复。存储键与 schema 不变。TopologySpec 新增可缺省 flowStartStage；缺省仍等路径节点和连线出现后播放。旧内容与旧格式由 Core 用例验证。

可以用一个清楚的命令入口和一个消息 handler，通过直接枚举 / switch 分发。消息必须校验类型与参数，宿主只处理当前实例的回调；提交期间阻止重复点击，销毁时移除 handler。这是基本生命周期保护，不需要消息总线。

**第一版不实现**通用事件路由、持久事件队列、复杂事件 ID 去重、ACK / 重传协议、全局订阅中心、动态组件下载、多 WebView 池、能力协商或跨版本热加载。版本先使用明确的本地契约常量即可；只有遇到多个组件或兼容问题时再扩展。

### 最小权责与恢复

- Web 提交用户选择，例如所选网络位，不直接提交可信的「已掌握 / 已解锁」。Core 校验练习答案。
- 纯讲解可由用户点击继续，不要求动画完整播放；练习按实际提交门控。
- 保存当前教学阶段与选择等语义状态，不保存动画毫秒或 DOM。
- 宿主重建 / Web 进程恢复时重送参数与语义状态；视图普通刷新不反复重载页面。
- 后台暂停，前台保留阶段；暂停、重播不产生 XP 或额外作答。
- 不在本地 HTML 放整节课程导航或业务账本，学习数据由 Swift 一侧保存。
- 主题和可访问性遵守 DESIGN；练习必须能通过等价的非拖拽方式完成。

### 资源与失败处理

资源随 App 本地打包，不依赖 CDN。只允许本地受控资源；使用 WKWebView 本地加载时限制读取目录，知识来源链接交给系统浏览器。Swift 传参使用结构化参数或可靠序列化，不拼接未经转义的课程文本作为可执行 JS。

校验 IPv4、前缀与阶段等参数；非法内容给出明确错误，不静默生成假答案。加载失败提供重试与静态 / 文字替代；交互题的替代方式遵守相同判定，不跳过必需练习。XcodeGen 打包必须保留 Web 资源需要的目录关系，CI 检查实际安装包内容。

### 试点验收

至少用两组地址 / 前缀配置复用同一组件，不复制 HTML、不按 lessonID 分支。验证输入计算、讲解与提交、内部暂停 / 恢复和必要重播能力、离开返回、大字号、Reduce Motion、VoiceOver 及计划中的深浅主题表现；后续分步教案还需验证按钮 / 手势推进与回看、阶段恢复及奖励不重复。Web 测试通过不等于 WKWebView 集成通过，必须补 iOS 侧验证。

### 长期方向：计划中，按复用需求扩展

可扩展为共享 runtime 与组件注册表：IPv4AddressVisual、SubnetMaskVisual、ARPVisual、SwitchForwardingVisual、RoutingVisual、NATVisual、DNSResolutionVisual、TCPHandshakeVisual、PacketJourneyVisual。

各组件接收参数、阶段与交互模式；PacketJourney 组织有限教学过程，不成为万能网络模拟器。原生和 Web 共享视觉语义与计算测试样例。出现多组件之后，再考虑独立协议版本、stepID / 实例标识与更严格的异步消息隔离；只有实际重复投递问题才引入额外去重机制。长期方向不得反过来扩大第一个试点。

## 本地持久化与迁移

先为现有 UserDefaults 增加清楚的进度仓库边界，不同时更换数据库。数据规模和查询确有需要时，再选择原子 JSON 文件或数据库；不能因为引入 Mastery 就自动引入 SwiftData / 后端。

迁移流程：保留旧原始数据 → 明确版本转换 → 验证新结构与关键记录 → 写入并读回确认 → 切换有效版本。失败保留旧数据并进入恢复状态；重复迁移不产生额外奖励或重复活动。

schemaVersion、课程内容版本、Lesson revision、Web 契约版本独立管理。未知更高存储版本不得被旧代码静默覆盖。不要用新增必填字段的默认值假设旧 JSON 一定能解码；用真实旧格式 fixtures 验证。

迁移至少保护 XP、完成日期、学习日期、复习日期、有效会话和奖励幂等依据。备份不能在重复启动时被新的空进度覆盖。历史结算记录的增长以后按安全策略处理，裁剪前保证不会重新发奖；不因担心未来规模先建事件仓库。

### 答后图解与术语揭晓（0.11.0 引入，0.12.0 修正）

Challenge 可附加可选 `answerExplanation` 图解页，包含稳定页 ID、正文与可选 `DevicePortsSpec` 接口数据、`HomeNetworkSpec` 房间连接图或 `TermIntroduction` 名称卡片。至少有一种呈现，存在的内容均通过 Core 校验；旧接口页可缺省新增字段。Core 将其放在 Challenge 与 summary 之间；正确作答后逐页推进，读完再完成与结算。SwiftUI 复用 `HomeNetworkDiagram` / `TermIntroductionCard`，有接口数据时用默认折叠的 `DevicePortsDiagram` 作为详情；不按 Lesson ID 分派。名称卡片独立可复用，数据包含 name / englishName / chineseName，卡片统一加英文括号。旧课程缺省此字段时路径不变。HomeNetworkSpec 新增可选 opticalModemLabel：存在时入户光纤先接光猫，再用网线接独立路由器；缺省时仍展示原单设备结构。该字段只用于课程图示，不改变存储 schema 或学习会话。旧字段缺省解码与新图示结构有 Core 回归用例，运行结果见本轮交接。

`LessonSession.challengeExplanationID` 是可缺省的当前页标识；stage 仍为 challenge，转换器用稳定页 ID 恢复。旧已答草稿停留在原答题位置，旧 complete 直接映射新 summary，不重开课程、不重复奖励；未知 / 删除页 ID 回到已答题位置。存储键与 ledger 格式不变。主动退出仍丢弃当前草稿，后台中断保存该页。新增 Core 用例保护读完前不发奖、页恢复、旧 JSON、已完成记录与错误答案门控。

### 课程移除与历史草稿

当前目录 revision 6，仅含 `home-two-boxes`。移除旧课程内容、归档目录与短复习题，既有 schemaVersion 1、存储键和第一课稳定 ID 不变。

`normalizeDrafts` 不因课程缺失清除草稿。有效旧主线草稿可保留在 draft；开始示例课时转存 earlierDrafts。有效复习草稿、短复习草稿、学习证据、完成日期、活动日、XP 和结算幂等记录保留。推荐、解锁、完成数量和到期列表仅依据当前目录，不显示已删除课程。

主线 / 复习隔离与完成会话清理仍按已有规则执行；启动旧版本数据、重复归一化、保存新课后重启与重复结算均由 Core 回归验证。历史 payload 类型保留用于解码，测试夹具只有中性文字和结构参数，不保存旧教学内容。

### 已识别的基线风险：待修复

- 课程加载失败时 `LearningStore` 已跳过归一化；本轮另外修正正常删课时丢失未知课程草稿的问题。
- 未知 schema 当前备份后使用新进度，缺少受保护的恢复 / 迁移路径。

这些是后续小范围修复候选，不表示本轮文档变更已修复业务代码。

## 渐进实施方法

整体阶段由 PRODUCT 维护。工程上每次只迁一个可验证边界：先保护现有规则与存储，再包裹课程目录，然后适配一课为 Step，最后接入一个 Web 组件。其他课继续原路径，待等价行为通过再迁移。

当前使用 StepLessonPlayer；stage↔step 适配器与旧 payload 类型服务历史存档兼容。旧课内容、专用教学页面与 UI 用例已移除。

不要把播放器、存储、课程内容和整个视觉系统放在一次重写里。兼容适配器有明确用途和移除条件；不是长期维护两套独立课程来源。课程拆分为多个文件与引入目录模型也不必发生在同一次变更。

## 测试策略与验证范围

当前 Core 测试覆盖唯一示例课、移除内容后的数据保留，以及中性结构夹具上的门控、恢复、主线 / 复习隔离与奖励规则。原生 UI 用例仅保留第一课，可按 Pat 明确要求运行。

| 变更 | 必要检查 |
| --- | --- |
| 仅文档 | 本地链接、状态标注、规则一致性、变更范围、`git diff --check` |
| 课程内容 | JSON 解码与校验、ID / 引用 / 正确答案、先修关系、资源存在；代表性学习流程；另按 COURSE_GUIDE 独立审读中文，机器检查不代表语言合格 |
| Step / Core | 门控、重试、恢复、完成、主线与复习隔离，运行 `swift test` |
| 奖励 / Mastery / Review | 同日零奖励错误、同日多次正确、重复结算、提示与独立证据、日期 / 时区边界 |
| 迁移 | 真实旧格式、未知版本、损坏数据、课程重排、重复迁移、恢复失败保护 |
| UI / 动效 / 主题 | 当前试学由 Pat 真机验收，附对应清单；仅 Pat 明确要求时跑原生 UI / 模拟器截图。大字号、VoiceOver、Reduce Motion 等未验收项如实记录 |
| Web | 组件参数和计算样例、直接通信、错误与恢复、生命周期；WKWebView 内集成验收 |
| 打包 | 真机目标编译，确认课程、图标和 Web 文件实际随包存在，离线加载 |

当前交付验收明确检查只有第一节示例课；未来获准新增课程时同步调整此验收边界，不把当前一课或 Draft 数量作为永久规则。未来缺失或循环先修引用应在内容校验中发现。

当前 iOS 工作流仅通过 workflow_dispatch 手动触发，以节省 GitHub Actions 额度；日常提交先积累，在阶段性验收、较大版本交付或风险需要时运行完整构建、测试与 IPA 导出。采用 PR 协作后再评估是否增加轻量检查。Windows 上不能执行的 Swift / iOS 检查，应明确交由 macOS CI 或 Mac，报告未执行项，不能把静态检查称作模拟器或真机验证。文档变更不必为了形式重复完整 iOS 构建。

2026-10-07 新增快速试学路径（Pat 已确认）：`ui_scope=package` 运行 Core / Web 测试、iPhone Release 编译、资源检查与未签名 IPA 上传，不启动模拟器、不运行原生 UI 或生成模拟器截图；包交付时附本次变更的真机试学清单并收集反馈。Pat 随后明确要求原生交互由本人验收：Agent 默认使用 package 交包，不主动运行原生 UI / 模拟器截图。`full` 保留完整 UI 与 IPA，原生自动化仅在 Pat 明确要求时使用；Core / Web 与真实 iPhone 编译检查继续执行。`quick` 是不出包的编译检查，`smoke` / 专项 scope 是不出包的对应 UI 检查。快速包的“构建成功”不等于 UI 已验收；每份交付按实际 commit 记录已执行 / 未执行项，不沿用旧提交的测试结果。

故事课专项 `home` / `smoke` scope 运行第一课完成、回看恢复、大字号与主动退出四项用例，不导出 IPA；可在其他 smoke 流程已通过、仅修正本课 UI 断言时复核故事课，避免重复全部流程。运行范围必须随交付结果注明。
