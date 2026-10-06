# 第一课试学反馈修复

## Current task / 本轮任务
修复 Pat 指出的第 12–17 步头像、连线、缺失光猫与生硬文案，施工于 codex/lesson-feedback。

## Completed / 已完成
- 朋友头像移除向下偏移，姓名与头像同排，气泡位于姓名下方。
- HomeNetworkDiagram 先布局卡片，再测量边界画线；光纤改为清楚的深色实线，网线保持虚线，线路止于设备侧边或房间上边缘，不穿过文字。
- 普通路由器页显示入户光纤 → 光猫 → 网线 → 普通路由器 → 房间设备；新增可缺省的 opticalModemLabel，不新建专用播放器。
- 沿用已有中文表达修订，答后明确光猫路由一体机与不能直接换普通路由器的结论；FTTR 直接解释光纤到房间。
- 保留所有课程、步骤、答案 ID、正确选项和学习存储；更新已有 UI 文案断言，增加旧图示解码及独立光猫图示的 Core 测试。
- 候选版本提升为 0.12.0 build 27，原应用标识不变。原主工作区六项未提交修改不动。

## Decisions made / 本轮关键决策
保留卡片底色，连线测量可见边界；不以盖住线路模拟端点。姓名、设备与线路按真实布局测量，不强制压缩大字号。FTTR 例子仍限定为支持房间光纤组网的光猫，不推广为所有光猫。

## Not completed / 尚未完成
Core / Web / iPhone package 检查与 IPA 核验已完成。原生 UI、模拟器截图、VoiceOver、大字号与真机体验未执行；按已确认流程由 Pat 验收交互。

## Known issues / 已知问题
Windows 无本地 Swift / iOS 工具链；源码改动不能代表真机布局已通过。大字号、VoiceOver 与小屏仍需验收。

## Verification / 已做验证
本地 4 项 Web 测试通过；JSON 与相邻课程、场景原句、选项原句、稳定 ID、正确答案、配对映射及 31 个文档链接检查通过，git diff --check 通过。按实际顺序独立通读提示、反馈和答后讲解。主工作区六项文件已记录哈希，内容保持原状。手动 [package / 37544603801](https://github.com/perinchiang/wanggan-ios/actions/runs/37544603801) success，实际源码提交 06d8097bda075b9e1dfcd6f2011461cd4b6559db：77 Core、4 Web、iPhone Release 编译与包上传通过；原生 UI / 模拟器截图步骤实际 skipped。IPA ZIP 完整，0.12.0 / 27 / com.perinchiang.wanggan，iPhoneOS arm64；课程与 HTML 逐字节匹配该提交，Assets.car 存在。IPA 909928 bytes，SHA256 6788ebf0d0d9228be2a79af6075efe9689d3c9dc5b0120ef9beff8ebf4f997af。安装包、日志、核验记录与真机清单位于主工作区 artifacts/WangGan-0.12.0-build27。后续记录提交仅改文档，不将其当作 IPA 源码。

## Next recommended task / 推荐下一步
验收第 12 步头像姓名、第 14–16 步线条边界及第 14–17 步阅读与答案一致性，再决定后续课程迭代。
