# 网感：系统架构与渐进迁移

状态：职责边界与数据保护原则已确认；目标模型、短复习及 Web 试点尚未实现。下面出现的目标类型不是当前代码 API。
基线：0.1.3（build 4），提交 `4ed6b49`。

## 文档职责

本文件维护系统职责、模型方向、状态更新、持久化、迁移与测试。产品范围和阶段顺序见 [PRODUCT.md](PRODUCT.md)，课程内容见 [COURSE_GUIDE.md](COURSE_GUIDE.md)，视觉、网络动效与主题见 [DESIGN.md](DESIGN.md)，执行要求见 [AGENTS.md](AGENTS.md)。

## 当前实现：已实现

| 位置 | 当前职责 |
| --- | --- |
| `Sources/Core/Lesson.swift` | Course（id / revision / title）与 Chapter（id / title / orderedLessonIDs）目录模型；Lesson 固定包含 question / explanation / matching / challenge；课程与章节覆盖校验 |
| `Sources/Core/LessonSession.swift` | question → explanation → matching → challenge → complete；课内状态、重试和累计错误数 |
| `Sources/Core/LessonPlan.swift` | Step 类型与 payload（conversation / question / diagram / text / matching / summary）、Lesson→steps 适配、LessonPlan 步进门控、StepSession 及 stage↔step 双向适配 |
| `Sources/Core/ProgressLedger.swift` | 完成记录、XP / 等级、复习日期、活动日、结算会话、主线 draft 与 reviewDrafts |
| `Sources/App/StepLessonPlayer.swift` | 分派入口：五个现有 Lesson 均走 `StepLessonPlayer`（LessonPlan / StepSession）；`StageLessonPlayer` 暂留作验收前的回退路径，集中验证后再移除 |
| `Sources/App/AppStore.swift` | 加载课程、UserDefaults 编解码、解锁与推荐、保存及重置 |
| `Sources/App` 其余文件 | SwiftUI 导航、页面、原生题型和图示 |
| `Resources/lessons.json` | 当前五课内容与来源 |
| `Package.swift` / `Tests` | 独立 Core 测试和 iOS 原生 UI 测试 |
| `project.yml` / `.github/workflows/ios.yml` | XcodeGen、macOS 构建、测试、截图和 IPA 导出 |

当前奖励规则：首次完成一课 +30 XP；已完成课之后每个本地自然日首次复习 +5 XP；首次完成当天重复学习不追加奖励；会话重复结算不重复加分。等级为 `totalXP / 100 + 1`。

当前复习：首次完成后次日复习，后续使用 1 / 3 / 7 / 14 天，错误可重置间隔级别。复习状态在每次有效完成后独立更新，不依赖当天是否发奖励：同日零奖励的错误仍重置级别并提前到次日，同日多次正确不能连续推进阶梯。

当前 schemaVersion 为 1，存储键为 `wanggan.progress.v1`。部分可选字段支持旧草稿解码，另有旧复习草稿归位逻辑；这不是完整的版本迁移框架。

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

Step 使用有类型的 payload，不把所有内容放入无约束字典。`conversation`、`question`、`diagram`、`text`、`matching`、`summary` 已在 Core 落地（`LessonPlan` / `LessonStep`），`Lesson.steps` 适配器把旧 Lesson 映射为等价步骤；播放器尚未切换到 step 路径。Sorting、PathChoice 等有真实课程需求后再增加。HTMLVisualization 留待可视化试点接入。

Challenge 是练习角色 / 组合，不必复制一套专用答案状态。会话最终按稳定 stepID 保存位置，而不是只依赖枚举序号；兼容适配器先把旧 Lesson 映射为等价步骤。不要把五课同时改写来验证新播放器。

### 课程进度

访问权、完成记录、推荐位置与掌握状态分别表达。第一阶段仍线性解锁，但规则位于 Core 策略而非 SwiftUI 数组索引。未来可配置章内线性、章间满足先修条件后半开放；暂不实现技能树。

已完成课保持可回看。插入基础课可以改变推荐建议，不能撤销旧成果或使旧课重新锁定。主线和复习有明确会话用途与独立草稿；先保留当前隔离行为，再按真实需求扩展多课程状态。

## 学习证据、Mastery、Review、XP：计划规则

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

第一版目标是验证一个组件能够用不同参数用于至少两处内容，并支持讲解与一个必要的练习交互。不是建设通用可视化平台。

建议仅有：一个本地 HTML 入口、一个 IPv4 组件、一个 SwiftUI WKWebView 宿主和直接通信方法。先用普通 JS / CSS / SVG，不为试点引入完整前端应用框架、插件加载器或构建平台。

最小输入：`ip`、`prefix`、教学阶段、讲解 / 练习模式、主题、字号与 Reduce Motion 配置。最小命令：初始化 / 更新、播放、暂停、重播、必要的单步及恢复语义状态。最小回调：ready、用户提交或必要状态变化、error；嵌入尺寸确实需要时再加高度回调。

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

至少用两组地址 / 前缀配置复用同一组件，不复制 HTML、不按 lessonID 分支。验证输入计算、讲解与提交、暂停 / 重播、离开返回、恢复、大字号、Reduce Motion、VoiceOver 及计划中的深浅主题表现。Web 测试通过不等于 WKWebView 集成通过，必须补 iOS 侧验证。

### 长期方向：计划中，按复用需求扩展

可扩展为共享 runtime 与组件注册表：IPv4AddressVisual、SubnetMaskVisual、ARPVisual、SwitchForwardingVisual、RoutingVisual、NATVisual、DNSResolutionVisual、TCPHandshakeVisual、PacketJourneyVisual。

各组件接收参数、阶段与交互模式；PacketJourney 组织有限教学过程，不成为万能网络模拟器。原生和 Web 共享视觉语义与计算测试样例。出现多组件之后，再考虑独立协议版本、stepID / 实例标识与更严格的异步消息隔离；只有实际重复投递问题才引入额外去重机制。长期方向不得反过来扩大第一个试点。

## 本地持久化与迁移

先为现有 UserDefaults 增加清楚的进度仓库边界，不同时更换数据库。数据规模和查询确有需要时，再选择原子 JSON 文件或数据库；不能因为引入 Mastery 就自动引入 SwiftData / 后端。

迁移流程：保留旧原始数据 → 明确版本转换 → 验证新结构与关键记录 → 写入并读回确认 → 切换有效版本。失败保留旧数据并进入恢复状态；重复迁移不产生额外奖励或重复活动。

schemaVersion、课程内容版本、Lesson revision、Web 契约版本独立管理。未知更高存储版本不得被旧代码静默覆盖。不要用新增必填字段的默认值假设旧 JSON 一定能解码；用真实旧格式 fixtures 验证。

迁移至少保护 XP、完成日期、学习日期、复习日期、有效会话和奖励幂等依据。备份不能在重复启动时被新的空进度覆盖。历史结算记录的增长以后按安全策略处理，裁剪前保证不会重新发奖；不因担心未来规模先建事件仓库。

### 五课重排与草稿

稳定保留 `gateway`、`subnet`、`arp`、`hop`、`dns`。章内位置不是记录主键；新增基础课不删除旧成果或重发首次奖励。保留可映射的原主线 / 复习草稿。

旧 stage 与新 stepID 通过明确映射转换。无法映射时仅重启该课的安全步骤并说明原因，不清空其他课、XP 或历史。课程暂时缺失的记录保留，待内容恢复后再关联，不自动判为无效历史。

### 已识别的基线风险：待修复

- `LearningStore` 在课程加载失败时仍可能以空课程列表归一化并保存草稿，存在清除草稿风险。
- 未知 schema 当前备份后使用新进度，缺少受保护的恢复 / 迁移路径。

这些是后续小范围修复候选，不表示本轮文档变更已修复业务代码。

## 渐进实施方法

整体阶段由 PRODUCT 维护。工程上每次只迁一个可验证边界：先保护现有规则与存储，再包裹课程目录，然后适配一课为 Step，最后接入一个 Web 组件。其他课继续原路径，待等价行为通过再迁移。

当前迁移门：五课均已切换到 StepLessonPlayer，0.1.4（build 5）的 Core、iPhone 构建与 7 项原生 UI 测试已通过，包含答错反馈可见性及五课代表性完成流程；本版本仍待用户真机验收。每课仅切换播放路径，内容与 ID 不变。真机验收后删除 StageLessonPlayer 与分派逻辑。期间两个播放器共享 QuestionConversation、MatchingView、CompletionView 等原生组件。

不要把播放器、存储、课程内容和整个视觉系统放在一次重写里。兼容适配器有明确用途和移除条件；不是长期维护两套独立课程来源。课程拆分为多个文件与引入目录模型也不必发生在同一次变更。

## 测试策略与验证范围

当前 Core 测试包含五课的 Step 通关、错误重试、新旧状态机及草稿转换对照；7 项原生 UI 测试覆盖五课代表性完成流程、续学、主线 / 复习隔离与 gateway 答错反馈。通过模拟器不代表所有字号、设备或真机体验均已验收。

| 变更 | 必要检查 |
| --- | --- |
| 仅文档 | 本地链接、状态标注、规则一致性、变更范围、`git diff --check` |
| 课程内容 | JSON 解码与校验、ID / 引用 / 正确答案、先修关系、资源存在；代表性学习流程 |
| Step / Core | 门控、重试、恢复、完成、主线与复习隔离，运行 `swift test` |
| 奖励 / Mastery / Review | 同日零奖励错误、同日多次正确、重复结算、提示与独立证据、日期 / 时区边界 |
| 迁移 | 真实旧格式、未知版本、损坏数据、课程重排、重复迁移、恢复失败保护 |
| UI / 动效 / 主题 | 对应原生 UI 测试，截图；大字号、VoiceOver、Reduce Motion、深浅色及关闭声音 / 触感 |
| Web | 组件参数和计算样例、直接通信、错误与恢复、生命周期；WKWebView 内集成验收 |
| 打包 | 真机目标编译，确认课程、图标和 Web 文件实际随包存在，离线加载 |

现有五课必须继续存在，但新增内容后不再将课程总数固定为 5；不得改为断言 Draft 总数 42。未来缺失或循环先修引用应在内容校验中发现。

当前 iOS 工作流仅通过 workflow_dispatch 手动触发，以节省 GitHub Actions 额度；日常提交先积累，在阶段性验收、较大版本交付或风险需要时运行完整构建、测试与 IPA 导出。采用 PR 协作后再评估是否增加轻量检查。Windows 上不能执行的 Swift / iOS 检查，应明确交由 macOS CI 或 Mac，报告未执行项，不能把静态检查称作模拟器或真机验证。文档变更不必为了形式重复完整 iOS 构建。
