# 删除复习系统

## Current task / 本轮任务

Pat 认为现有复习设计不适合继续开发，要求整套删除。沿用上一轮仅保留第一节示例课的 663fd5e 基线，在已有独立 worktree 施工。

## Completed / 已完成

- 删除复习选项卡、ReviewView、ShortReviewPlayer、Core 短会话 / 作答证据 / 状态类型和全部复习调度方法。
- 移除 ReviewItem、目录复习字段、测试夹具与旧复习规则测试。官方文档删除旧系统的后续设计与职责，不把它列为待恢复的基线。
- 首次完成仍 +30 XP；此后普通阅读在同日或跨日均不加分。保留当前学习页再次阅读课程的能力。
- schemaVersion 2：统一 drafts / mainLessonID；v1 的整课草稿合并进普通课程草稿，旧 XP、首次完成、活动日和结算记录保留。旧到期、间隔级别、短会话与证据字段不再参与运行或写入。
- 第一次转换保留原 v1 字节备份，后续不覆盖；未知版本和坏数据禁止普通写入，明确重置才解除。第一课内容逐字段核对；试学版本 0.15.0 build 30，源码提交 df11024af60c81572e88df02b2be084751f45d33 已推送 feature/home-network-native。
- 原工作区仍在 feature/doctor-script 的 4edadcf，MacBook 环境脚本及其 PR 未改动。

## Decisions made / 本轮关键决策

保留普通课程阅读和首次完成激励；再次阅读不属于独立复习系统，没有到期安排、独立会话类型或奖励资格。课程草稿统一存储，同时保护未完成主线位置。只保留必要的旧格式字段名用于转换；不保留旧业务模型和算法。

## Not completed / 尚未完成

原生 UI / 模拟器截图不运行；「学习 / 我的」双入口、再读和实际设备更新由 Pat 真机验收。没有新增替代的复习系统。

## Known issues / 已知问题

Windows 没有 Swift / Xcode；本版本的 Core 与 iPhone 编译已通过 macOS package CI 验证。旧原始备份仅用于数据恢复，不参与新运行模型；覆盖安装后的实际 UserDefaults 转换仍待真机验证。

## Verification / 已做验证

- 本地 4 Web 测试通过；检查第一课内容、文档链接、源码引用和 git diff --check。
- [package CI 37612194179](https://github.com/perinchiang/wanggan-ios/actions/runs/37612194179) 对源码 df11024 运行成功：74 项 Core、4 项 Web 测试及真机目标编译 / IPA 打包通过；job 用时 1 分 34 秒。原生 UI、模拟器截图未运行。
- Core 覆盖普通课程门控、奖励幂等、课间草稿、退出和恢复回归；新增 v1 全字段转换、旧已完成课主线草稿归位、同日 / 跨日阅读零奖励、未知 / 损坏格式拒绝四项用例均通过。
- 已下载并核验 `artifacts/WangGan-0.15.0-build30-df11024/WangGan-unsigned.ipa`：版本 0.15.0 / build 30，bundle identifier 保持 com.perinchiang.wanggan；包内课程 JSON 与该源码提交逐字节一致，仅有 home-two-boxes、无 reviewItems、归档列表为空；图标及本地 Web 资源在包内，无测试夹具。包大小 680694 字节，SHA-256 为 `138dd663e2a1109c12e9dd897ad7310bd3bccc23f95eaf8f9c00aa6b76d880b9`，核验信息同目录 verification.json。
- CI 后仅补充 README 与本交接的验证结果，不改变安装包源码，不重复触发构建。

## Next recommended task / 推荐下一步

Pat 覆盖安装 0.15.0 build 30 试学，确认只显示学习和我的、已有 XP 与完成记录保留、再读不发奖，并检查第一课的 WKWebView 与交互。后续专注课程内容与教学交互。
