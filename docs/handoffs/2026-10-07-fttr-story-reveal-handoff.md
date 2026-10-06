# FTTR 故事与术语卡交接

## Current task / 本轮任务

按 Pat 真机反馈，把朋友名移到气泡上方、收拢短气泡，重做混乱的 FTTR 接口图与生硬定义。追加正式圆角名称卡和英文括号，突出 FTTR。

## Completed / 已完成

- 气泡按最长排版行收拢背景；朋友名独立在白色气泡上方，正文左右留 10 pt。
- 四段答后阅读：一体机 / 普通路由器接线区别 → 另一位朋友房间里的细线 → 确认是光纤 → FTTR 名称卡。保留前三段稳定页 ID，新增 fttr-reveal。
- 新增数据驱动 HomeNetworkDiagram：紧凑三房间布局、连线抵达设备图标，光纤 / 网线有实虚线与文字区别；原接口详情默认折叠。
- TermIntroductionCard 复用名称 / 英文全称 / 中文名，FTTR 默认 48 pt 粗体，英文显示 (Fiber to the Room)，全部支持系统字号。
- 0.11.0 build 26；原 worktree 与分支继续使用，原工作区六项未提交修改保留。

## Decisions made / 本轮关键决策

比较覆盖故障、接口清单、细线观察钩子，选择细线，沿着「线到了哪里」揭晓名称。FTTR 是光纤到房间；不以黄线颜色认定光纤，不称为最新新发明。主图简化光纤分配，接口与供电细节仍可展开查看。

新增 homeNetwork / termIntroduction 字段可缺省，diagram 改可选；旧接口 JSON 仍解码。新页面沿用 Core 的已答后阅读门控、稳定页 ID 恢复与读完后结算；旧 complete 不重开、不重复加奖。名称卡也能独立呈现，不要求配套接口图。

## Not completed / 尚未完成

原生交互、短气泡布局与真实房间图由 Pat 验收；本轮不跑原生 UI 或模拟器截图。

## Known issues / 已知问题

Windows 无本地 Swift / iOS 工具链；大字号、小屏、VoiceOver 尚未真机验收。

## Verification / 已做验证

本地相邻课程与稳定 ID、前三页不提前出现 FTTR 名称、原句保留、文档链接、JSON / YAML 与 diff 检查通过；原工作区六项未提交修改保持原状。Core 补充卡片独立页、缺省字段与非法电源链路校验。

- [package / 37520749808](https://github.com/perinchiang/wanggan-ios/actions/runs/37520749808) success，IPA 源码 `eafe40378707c069c8e1e1d7e6abb6a8e934c258`，1 分 55 秒。74 Core / 4 Web、iPhone Release 与上传通过；原生 UI / 模拟器截图实际 skipped。
- IPA ZIP 完整，0.11.0 / 26 / 原 bundle ID，iPhoneOS arm64；课程 / HTML 与候选源码一致，Assets.car 存在。895618 bytes，SHA256 `34a157b9c74f43d0ce2bd3ed9eba92afccc4e717d23462120ca6d447508b89ac`。
- IPA、试学清单、日志和核验记录位于 `C:/Users/Administrator/Documents/wanggan/outputs/WangGan-0.11.0-build26/`。以下仅补记文档，不将文档 commit 当作 IPA 源码。

## Next recommended task / 推荐下一步

交付已核验 IPA 与留白 / 故事节奏 / FTTR 名称卡试学清单，由 Pat 真机反馈；根据实际阅读结果继续小范围调整。
