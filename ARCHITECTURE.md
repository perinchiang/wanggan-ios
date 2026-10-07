# 网感：系统架构与渐进迁移

状态：职责边界与数据保护原则已确认；当前新开课提供第一节短题，旧草稿保留原播放器恢复路径。其余目标模型仍是计划，运行证据见当前交接。

## 文档职责

本文件维护系统职责、模型方向、状态更新、持久化、迁移与测试。产品范围和阶段顺序见 [PRODUCT.md](PRODUCT.md)，课程内容见 [COURSE_GUIDE.md](COURSE_GUIDE.md)，视觉、网络动效与主题见 [DESIGN.md](DESIGN.md)，执行要求见 [AGENTS.md](AGENTS.md)。

## 当前实现：已实现

| 位置 | 当前职责 |
| --- | --- |
| `Sources/Core/Lesson.swift` | Course（id / revision / title）与 Chapter（id / title / orderedLessonIDs）目录模型；Lesson 固定包含 question / explanation / matching / challenge；课程与章节覆盖校验 |
| `Sources/Core/LessonSession.swift` | question → explanation → matching → challenge → complete；课内状态、重试和累计错误数 |
| `Sources/Core/LessonPlan.swift` | Step 类型与 payload（conversation / question / diagram / text / matching / summary）、Lesson→steps 适配、LessonPlan 步进门控、StepSession 及 stage↔step 双向适配 |
| `Sources/Core/ProgressLedger.swift` | 首次完成记录、XP / 等级、活动日、结算会话、统一 drafts 与 mainLessonID |
| `Sources/App/PracticeLessonPlayer.swift` / `StepLessonPlayer.swift` | 新开课走短题播放器；没有短题状态的旧故事草稿按原 Step 恢复，不按 Lesson ID 复制专用页面 |
| `Sources/Core/IPv4AddressVisual.swift` / `Sources/App/IPv4AddressVisualWebView.swift` / `Resources/ipv4-address-visual.html` | 参数化 IPv4 校验、网络地址计算与本地 Web 图示；保留为技术组件，当前示例课未接入 |
| `Sources/Core/ProgressPersistence.swift` / `Sources/App/AppStore.swift` | v1 → v2 转换、加载课程、UserDefaults 保存与备份、解锁与推荐、重置 |
| `Sources/Core/Topology.swift` / `Sources/App/TopologyDiagram.swift` | 数据驱动拓扑示意图：TopologySpec（nodes / links / flow / accessibilitySummary）在 Core 校验（id 唯一、引用完整、flow ≥ 2、maxStage ≤ explanation 段数 + 1），App 层按 stage 分阶段渲染节点、连线与数据包流动画；Lesson 可选 `topology` 字段，替代插画位图路线 |
| `Sources/App` 其余文件 | SwiftUI 导航、页面、原生题型和图示 |
| `Resources/lessons.json` | 仅第一节短题、来源和旧草稿所需的兼容载荷，无其他归档课程或复习内容 |
| `Package.swift` / `Tests` | 独立 Core 测试和 iOS 原生 UI 测试 |
| `project.yml` / `.github/workflows/ios.yml` | XcodeGen、macOS 构建、测试、截图和 IPA 导出 |

当前奖励规则：首次完整完成一课 +30 XP；之后重新阅读该课不发奖，包括隔天或以后完成。同一会话重复结算返回原值，不重复增加总 XP。等级为 `totalXP / 100 + 1`，不代表知识掌握。

当前只提供「学习 / 我的」入口。复习系统已完整删除：无到期计算、间隔阶梯、短复习、证据状态或每日 +5 XP。完成记录包含首次 completedAt 与 lastMistakes；再次阅读不改写首次成果。

当前 schemaVersion 3，沿用存储键 `wanggan.progress.v1`。所有整课草稿统一按 Lesson ID 存入 drafts，mainLessonID 记录未完成主线位置；不设独立复习会话或草稿类型。v1 / v2 转换与原始备份规则见下方。

## 连续短题与兼容（2026-10-08 已实现，验证见交接）

`Sources/Core/PracticeLesson.swift` 定义稳定题目 ID、探索 / 掌握角色、choice / fillBlank / matching、原生连接图参数与短解释。`Lesson.practice` 可选，当前第一课使用；多选、连线与章节挑战未实现，挑战通过率 TBD。题数不冻结。

Core 的 PracticeAttempt 管单选即时判定、填空选择 / 撤回 / 提交、每对匹配判定与整题三次错误预算。次数与正确配对是可恢复业务状态，临时端点选中、词移动和反馈动画在 SwiftUI，不能消耗次数或发奖。

PracticeSession 保存内容 revision、待作答 ID 队列、当前尝试、完成 ID 和累计整题错误数。错误反馈期间保留原题，按继续才把普通掌握题放到队尾；探索题不累计。末尾单题的穿插假设见 COURSE_GUIDE，不增加奖励。历史错题复习未实现，不从累计错误数反推逐题历史或恢复旧调度。

新开课走 PracticeLessonPlayer。没有 practice 且已有旧路径进度的草稿仍走 StepLessonPlayer；不把故事阶段强映射成新题、不静默重置旧草稿。旧 question / explanation / challenge 等字段仅供恢复路径使用；章节显示名为《你家的网络》，课程暂名「1-1」，Lesson ID 仍为 home-two-boxes。当前 practice revision 2 使用生活化短题；旧六题 revision 1 的队列不映射到新题。revision 或 ID 不兼容时保留草稿并明确告知，用户可点左上角退出并确认后开始新版，不自动重开。

LessonSession.practice 为可缺省字段。存储升级 schema 3，防止旧 App 丢掉不认识的队列字段。v1 / v2 解码保留原记录；App 首次写回前保留原始 wanggan.progress.pre-v3，重复启动不覆盖；v1 的 pre-v2 备份保留。存储键仍为 wanggan.progress.v1，没有改 bundle identifier。

结算先校验当前课程下的完成队列，再由 Core 按 stage complete 与队列完成门控，沿用首次 +30 XP 和会话幂等。同课再做新题不重新发奖，不改旧完成日期或其他草稿。UI 测试仍使用独立 suite；--legacy-lesson 仅与 --uitesting 同时出现时强制兼容路径，保留旧 UI 回归。

## 网络词典与文本匹配（后期计划，非现有 API）

词典先以本地数据提供稳定词条 ID、名称、缩写 / 别名、简短释义与来源；Core 或独立纯函数按这些别名匹配文本，输出命中范围和词条 ID，原生界面负责波浪下划线、点词与释义小窗。匹配规则需处理大小写、词边界、重叠别名与标点，支持 IS-IS / ISIS 这类约定写法，避免简单子串替换造成误标。没有匹配项时保持普通文本。

独立词典入口和课内释义共享数据，不为两个入口维护两份解释。词条可通过稳定 ID 关联类别、知识点和学习节点，关系独立于用户错题记录；不是掌握模型或复习调度。查词不推进 Step、解锁课程或发 XP，打开 / 关闭小窗不修改答案和草稿；直接给出答案后的完成不能作为本轮错题的独立正确作答。词条与未来 API 形状仍是计划，不在本轮新增存储 schema、Web 消息、关系数据库或通用富文本框架。

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
| XP / 等级 | 奖励资格、幂等结算、等级 | 阻止零奖励学习更新证据 |
| 头衔 / 成就 | 按明确条件授予成果 | 改写学习证据或隐式阻塞课程 |
| 统计 / 打卡 | 聚合有效学习日期和活动 | 将打开 App 当作学习 |
| 本地进度 / 迁移 | 保存、备份、恢复、版本转换 | 因内容加载失败清理历史 |

SwiftUI 持有界面状态并发送动作，Core 持有学习规则；Web 只负责教学表现和局部交互。`LearningStore` 可继续作为页面使用的协调入口，逐步移出规则，不要求先替换状态管理方案。

## 目标数据模型：计划中，按需要引入

```text
Course: id, revision, title, chapters, progressionPolicy
Chapter: id, title, orderedLessonIDs, prerequisiteChapterIDs
Lesson: id, revision, title, objective, prerequisites, knowledgePointIDs, steps, sources
Step: id, kind, typedPayload, completionRule
KnowledgePoint: id, objective, prerequisiteIDs, misconceptionIDs
```

这是模型职责草案，不是要求一次添加所有字段。KnowledgePoint 独立定义并由多课引用；稳定 ID 不使用显示名称或章节序号。内容版本、Lesson 修订、存储 schema 与 Web 协议版本各自解决不同兼容问题。

Step 使用有类型的 payload，不把所有内容放入无约束字典。`conversation`、`question`、`diagram`、`text`、`matching`、`summary` 已在 Core 落地（`LessonPlan` / `LessonStep`），适配器把旧 Lesson 映射为等价步骤；现用于旧草稿兼容。新开课按 PracticeQuestion 队列，不复制旧独立讲解结构。Sorting、PathChoice 等有需求后再增加；尚无通用 HTMLVisualization 类型。

课内迁移题不必复制一套判题能力；章节挑战另有通过 / 失败及跳章职责，不能与现有 `Lesson.challenge` 混同。会话最终按稳定 stepID 保存位置，而不是只依赖枚举序号；兼容适配器先把旧 Lesson 映射为等价步骤。不要为验证播放器而同时重写全部内容。

### 课程进度

访问权、完成记录、推荐位置和章节挑战结果分别表达。当前线性解锁规则在 Core；未来保持固定主路径，已有基础通过同一章节挑战跳过整章，不根据作答生成新课程树或章间半开放路线。入口差异不形成两套课程。

已完成课保持可回看。插入基础课可以改变推荐建议，不能撤销旧成果或使旧课重新锁定。各课普通草稿独立保存；再次阅读其他课程不改变未完成主线的推荐位置。

## 完成、奖励与学习日期

Core 验证课程完成门槛后结算。首次完成记录与奖励幂等依据分别保存；同一会话重试不会重复发奖。重新打开已完成课是普通课程阅读，继续使用原 LessonPlan 和 LessonSession，不创建独立复习路径。

activityDays 以完成会话的本地自然日记账；重复完成可以记录当天学习，但不加 XP，不重写首次完成日期或错误数。是否通过不等于稳定掌握，不从 XP 推断专业能力。

### 主动丢弃与中断恢复

`discardDraft` 只移除 lessonID 与 sessionID 同时匹配的草稿；旧会话不能清除同课的新会话。确认退出后持久化并停止该页自动保存，取消保留页面；后台与意外终止保存当前阅读阶段。首次完成记录、settledSessions、XP 和其他课程草稿不撤回。

故事课移除的选项若出现在未完成草稿中，恢复为同会话、同阶段的未作答状态，保留错误次数与其他进度。第一课正文与稳定 ID 不因本轮删除系统而改变。

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

先为现有 UserDefaults 增加清楚的进度仓库边界，不同时更换数据库。数据规模和查询确有需要时，再选择原子 JSON 文件或数据库；不能因为整理进度就自动引入 SwiftData / 后端。

迁移流程：保留旧原始数据 → 明确版本转换 → 验证新结构与关键记录 → 写入并读回确认 → 切换有效版本。失败保留旧数据并进入恢复状态；重复迁移不产生额外奖励或重复活动。

schemaVersion、课程内容版本、Lesson revision、Web 契约版本独立管理。未知更高存储版本不得被旧代码静默覆盖。不要用新增必填字段的默认值假设旧 JSON 一定能解码；用真实旧格式 fixtures 验证。

迁移至少保护 XP、首次完成日期、学习日期、整课草稿和奖励幂等依据。备份不能在重复启动时被新的空进度覆盖。历史结算记录的增长以后按安全策略处理，裁剪前保证不会重新发奖；不因担心未来规模先建事件仓库。

### 答后图解与术语揭晓（0.11.0 引入，0.12.0 修正）

Challenge 可附加可选 `answerExplanation` 图解页，包含稳定页 ID、正文与可选 `DevicePortsSpec` 接口数据、`HomeNetworkSpec` 房间连接图或 `TermIntroduction` 名称卡片。至少有一种呈现，存在的内容均通过 Core 校验；旧接口页可缺省新增字段。Core 将其放在 Challenge 与 summary 之间；正确作答后逐页推进，读完再完成与结算。SwiftUI 复用 `HomeNetworkDiagram` / `TermIntroductionCard`，有接口数据时用默认折叠的 `DevicePortsDiagram` 作为详情；不按 Lesson ID 分派。名称卡片独立可复用，数据包含 name / englishName / chineseName，卡片统一加英文括号。旧课程缺省此字段时路径不变。HomeNetworkSpec 新增可选 opticalModemLabel：存在时入户光纤先接光猫，再用网线接独立路由器；缺省时仍展示原单设备结构。该字段只用于课程图示，不改变存储 schema 或学习会话。旧字段缺省解码与新图示结构有 Core 回归用例，运行结果见本轮交接。

`LessonSession.challengeExplanationID` 是可缺省的当前页标识；stage 仍为 challenge，转换器用稳定页 ID 恢复。旧已答草稿停留在原答题位置，旧 complete 直接映射新 summary，不重开课程、不重复奖励；未知 / 删除页 ID 回到已答题位置。存储键与 ledger 格式不变。主动退出仍丢弃当前草稿，后台中断保存该页。新增 Core 用例保护读完前不发奖、页恢复、旧 JSON、已完成记录与错误答案门控。

### v1 → v2：移除旧系统（历史转换，当前统一写回 v3）

`ProgressPersistence` 读取真实 v1 数据；忽略已删除的到期时间、间隔级别、短会话与作答证据字段，不加载旧系统类型。旧 draft、earlierDrafts 和 reviewDrafts 中的整课会话合并进统一 drafts，保留 UUID、作答、错误数、图示位置和答后页 ID。未完成旧主线映射 mainLessonID；旧已完成课的阅读草稿不作为主线位置。

XP、completedAt、lastMistakes、activityDays、settledSessions 保留；历史领取的 +5 XP 不扣回。新 v2 只编码当前字段，不写回旧调度或短会话。重复加载 / 转换 / 结算必须幂等。

App 在首次转换前将原 v1 字节存入 `wanggan.progress.pre-v2`，仅首次写入，不用后续快照覆盖。转换后沿用原活动存储键写 v2；这是数据恢复副本，不参与运行规则。课程加载失败跳过归一化与保存。未知版本或损坏数据保留原始内容并禁止普通写入，只有用户明确重置才重新启用并清除备份。

当前目录 revision 9 仅含 `home-two-boxes`。内容缺失不清除普通整课草稿和完成记录；推荐、解锁、显示完成数量只依据当前目录。历史 payload 类型和中性结构夹具服务必要的存档兼容，旧复习模型、调度和测试已删除。

## 渐进实施方法

整体阶段由 PRODUCT 维护。工程上每次只迁一个可验证边界：先保护现有规则与存储，再包裹课程目录，然后适配一课为 Step，最后接入一个 Web 组件。其他课继续原路径，待等价行为通过再迁移。

新开课使用 PracticeLessonPlayer，已有旧故事草稿继续使用 StepLessonPlayer；stage↔step 与旧 payload 服务历史兼容。其他已删除课程的专用页面与 UI 用例不恢复。

不要把播放器、存储、课程内容和整个视觉系统放在一次重写里。兼容适配器有明确用途和移除条件；不是长期维护两套独立课程来源。课程拆分为多个文件与引入目录模型也不必发生在同一次变更。

## 测试策略与验证范围

当前 Core 覆盖短题角色、三次匹配、队列、旧格式恢复与奖励，并保留移除内容后的历史和中性夹具回归。原生 UI 有 PracticeUITests 五项短题用例和 LearningUITests 四项旧播放器兼容用例；实际结果见最新交接，不以用例存在宣称已通过。

| 变更 | 必要检查 |
| --- | --- |
| 仅文档 | 本地链接、状态标注、规则一致性、变更范围、`git diff --check` |
| 课程内容 | JSON 解码与校验、ID / 引用 / 正确答案、先修关系、资源存在；代表性学习流程；另按 COURSE_GUIDE 独立审读中文，机器检查不代表语言合格 |
| Step / Core | 门控、重试、恢复、完成、多课草稿与主线位置保护，运行 `swift test` |
| 奖励 / 统计 | 仅首次完成发奖、同日与跨日再读不发奖、重复结算、日期 / 时区边界 |
| 迁移 | 真实旧格式、未知版本、损坏数据、课程重排、重复迁移、恢复失败保护 |
| UI / 动效 / 主题 | 对应本地原生 UI 用例、必要截图与交互检查；教学节奏和真机效果需 Patrick 试学。大字号、VoiceOver、Reduce Motion 未验收项如实记录 |
| 新题目角色 / 队列 / 章节挑战（实现时） | 探索错误不追踪；掌握错题队尾顺序、再次独立正确移出、恢复；固定阈值通过 / 失败与整章跳过、旧进度保护 |
| Web | 组件参数和计算样例、直接通信、错误与恢复、生命周期；WKWebView 内集成验收 |
| 打包 | 真机目标编译，确认课程、图标和 Web 文件实际随包存在，离线加载 |

当前交付验收明确检查只有第一节示例课；未来获准新增课程时同步调整此验收边界，不把当前一课或 Draft 数量作为永久规则。未来缺失或循环先修引用应在内容校验中发现。

Mac 日常开发用命令行完成 Core / Web、iOS build、Simulator / 原生 UI 与必要真机验证；操作入口和首次签名配置见 [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)。文档变更通常不需完整 iOS 构建，本轮迁移审计按 Patrick 要求另做实际验证。

GitHub Actions 保留为干净环境 CI：相关代码 / 构建文件的 PR 自动运行 Core / Web 和 Simulator 编译，不启动模拟器、不导出 IPA。手动 workflow_dispatch 保留 quick / package / smoke / home / full，完整回归与 artifact 服务阶段性交付。是否把 PR 检查配置成 GitHub required check 属于仓库设置，存在检查不等于已启用分支保护。

`package` 运行 Core / Web、iPhone Release 编译、资源检查和未签名 IPA；`full` 加全部现有 UI；`quick` 只编译，`home` / `smoke` 运行第一课短题与旧播放器兼容 UI、不导出 IPA。快速包构建成功不等于交互或教学验收。每次按实际 commit 与范围报告，不沿用旧提交测试结果，不为每个小改动触发完整云端 IPA 流程。
