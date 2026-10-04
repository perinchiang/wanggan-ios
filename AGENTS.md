# 网感：项目开发约定

## 修改前阅读

先阅读 [README.md](README.md) 了解当前实现，再阅读 [PRODUCT.md](PRODUCT.md)、[COURSE_GUIDE.md](COURSE_GUIDE.md)、[DESIGN.md](DESIGN.md)、[ARCHITECTURE.md](ARCHITECTURE.md)，然后检查任务相关源码、内容和测试。

文档职责各有归属，规则在所属文件维护，其他文件链接引用。明确区分已实现、已确认原则、计划中、Draft、暂缓；文档中的目标类型不代表当前已有 API。发现文档与实现不一致，应指出差异并在任务范围内修正文档，不能默默扩大为业务重构。

## Agent 交接

- 开始较大开发任务前，先阅读 `docs/handoffs/` 中最新且与当前任务相关的 handoff。
- 较大开发任务完成后，在 `docs/handoffs/` 新建 `YYYY-MM-DD-<task>-handoff.md`，例如 `2026-10-05-course-catalog-handoff.md`。每份 handoff 只记录当前施工现场，简洁包含以下栏目：
  - Current task / 本轮任务
  - Completed / 已完成
  - Decisions made / 本轮关键决策
  - Not completed / 尚未完成
  - Known issues / 已知问题
  - Verification / 已做验证
  - Next recommended task / 推荐下一步
- handoff 不重复 `PRODUCT.md`、`DESIGN.md`、`COURSE_GUIDE.md`、`ARCHITECTURE.md` 中的长期规范；长期产品和架构决策仍以这些正式项目文档为准。
- Git diff / commit 用于确认实际改动；handoff 用于说明上下文、未完成事项和下一步。
- 小型文案、样式或独立 bug 修复不强制创建 handoff。

## 产品与教学

- 遵守 PRODUCT 的定位和范围，以网络直觉和迁移能力服务学习，不能擅自改成认证题库或刷分产品。
- 先保持完整小节可用，再扩展能力；不以架构整齐为由重写可用 MVP。
- 五个既有 Lesson 及稳定 ID 是兼容基线。移动、拆分或合并课程时，必须说明历史进度与草稿处理。
- 9 章 42 节只是 COURSE_GUIDE 的 Draft 内容地图；不冻结顺序、数量或 Lesson 划分，不把这些数量写成永久测试约束。
- 题目、错误选项、前提、迁移与来源遵守 COURSE_GUIDE；场景与文字原创，不复制考试题库或教材。
- 不自动加入 PRODUCT 标为暂缓的系统；新增范围需要明确产品决策。

## 架构与数据保护

- SwiftUI 负责 App Shell、导航和常规交互；Core 负责学习规则；复杂教学可视化可使用本地 HTML / WKWebView；课程内容尽量数据驱动。
- 优先复用现有组件与 Core。新课优先改内容、选组件、传参数；不按 Lesson ID 复制专用页面。确需新交互时增加最小可复用能力。
- Core 不依赖 SwiftUI、WebKit 或具体存储 API；View 与 JS 不直接发 XP、改掌握度或解锁课程。
- 遵守 ARCHITECTURE 对 XP、Mastery、Review 的职责划分；奖励为零不等于学习证据无效。
- 主线与复习分别保存；更新内容和架构不能静默清空历史、重新锁定已完成课程或重复发奖。
- 改存储格式、稳定 ID 或会话结构必须有明确迁移与旧格式验证。课程加载失败不能触发历史清理。
- 首个 HTML 试点仅满足 IPv4AddressVisual 的实际复用需要；不要预建消息总线、复杂去重、通用插件系统或无需求的多层抽象。长期桥接方向不是第一版实现清单。
- 保持 bundle identifier 稳定；产品改名不自动修改应用标识、课程 ID 或持久化键。数据重置应是明确的用户操作。
- 不将密码、令牌、签名证书或其他凭据写入仓库。

## 设计与可访问性

- 遵循 DESIGN 的米白 / 黑 / 荧光黄绿和 Packet 视觉方向，以及 Network-native Motion Language。
- 动效只表达真实状态或明确的产品隐喻；机制教学必须保持技术含义，不用网络隐喻制造虚假故障或能力判断。
- 新交互考虑 Dynamic Type、VoiceOver、Reduce Motion、深浅主题和可关闭的声音 / 触感。未实现、未验收的主题或反馈不得宣称已支持。
- 不把常规 UI 搬进 Web；不把组件试点扩大为视觉系统整体重写。

## 验证与交付

按 ARCHITECTURE 的测试矩阵选择与变更风险相匹配的验证：

- 仅改文档：检查链接、状态与规则一致性、变更范围，执行 `git diff --check`；无需完整 iOS 构建。
- 改课程、学习状态、奖励、复习、迁移：运行 `swift test` 并补充能证明目标行为的测试，保护既有回归用例。
- 改界面交互：运行对应原生 UI 测试；动效、主题与布局做截图及必要的可访问性验证。
- 改 Web：验证组件与直接通信，再验证实际 WKWebView；确认资源进入 App 安装包。
- 无本地 Swift / iOS 工具链时，通过可用的 macOS CI 或 Mac 验证，并明确未执行项；不能用静态分析代替运行证据。

每次变更围绕一个可验证目标，规则变化同步更新所属文档。避免同时迁移播放器、存储、全部课程和视觉系统。

每次对外交付 IPA 前，先在 `project.yml` 提升版本号（`MARKETING_VERSION` 与 `CURRENT_PROJECT_VERSION`）：任何代码改动都要至少 +1 build 号，产品行为变化 +1 小版本；同一版本号不得对应两份内容不同的 IPA。交付说明中标注版本号与对应 commit。

完成后说明改了什么、验证了什么、尚未验证什么。区分源码检查、CI、模拟器截图和实体设备反馈；不把未编译源码、设计图或文档计划称为可运行能力。只报告实际执行与观察到的结果。
