# 答后解析覆盖布局修复

## Current task / 本轮任务

Patrick 真机截图反馈：回答后选项被上移，要求保持原位，由用户自行滑动查看被遮住的内容。

## Completed / 已完成

PracticeLessonPlayer 仅将操作栏计入底部布局，解析单独覆盖在操作栏上方；题目视口不因解析变高而缩小。解析高度只增加题目末尾滚动空间，不自动滚动。DESIGN 同步交互规则，补选项坐标与手动滚动 UI 回归；版本 0.16.0 build 32 已覆盖安装并启动于 Pathos，保持原 bundle。工作区仍基于 385a3bc，未 commit / push / 导出 IPA。

## Decisions made / 本轮关键决策

只修反馈导致的页面重排，不改题目、判定、队列、存储或旧播放器。继续按钮固定；大字号解析保持内部滚动。填词移动动画完成后再测量提交布局，避免把正在运动的文字坐标作为选项基线。

## Not completed / 尚未完成

Patrick 修复版真机手感验收、完整 VoiceOver；本轮没有运行全量 UI、Core / Web 或远端 CI，没有将上轮结果当作本轮重新运行。

## Known issues / 已知问题

既有匹配正确对应展示与短题内容保持原实现；本轮针对解析面板挤动选择按钮的问题。未增加其他题型或课程。

## Verification / 已做验证

- Simulator build-for-testing 成功，复用 iPhone 17 Pro / iOS 26.5，禁用并行。首次覆盖方案使继续点击失败，三项失败记录保留在 build/stable-feedback/UI.xcresult；修为独立覆盖层后中断匹配恢复与最大字号两项通过（UI-fixed.xcresult）。同轮新坐标检查在填词动画未结束时取样失败，改为等待词移动结束；最终坐标 / 手动滚动用例通过（UI-position-final.xcresult），未放宽 1 pt 坐标容差。
- 实际查看 [答题前](../../build/stable-feedback/before.png)、[解析出现后](../../build/stable-feedback/after.png)、[用户上滑后](../../build/stable-feedback/user-scroll.png) 与最大字号截图。选择题答对 / 答错、填空提交后选项坐标保持；只有用户上滑才移动。继续与下一题可用，匹配恢复 / 第三次揭晓 / 队尾仍通过。
- 最新真机 Debug 签名构建、codesign 严格校验及课程资源核对成功。devicectl Wi-Fi 覆盖安装与普通无测试参数 launch 成功，版本 0.16.0 build 32 / PID 67266。更新前后 Preferences 对比确认 340 XP、11 条完成、7 个草稿、历史结算、学习日期及 pre-v2 / pre-v3 备份保留，见 build/stable-feedback/progress-verification.json。真机安装启动不代表本轮视觉已由 Patrick 验收。
- git diff --check 与本轮文档本地链接检查通过；日志、截图和设备备份在忽略目录 build/stable-feedback。

## Next recommended task / 推荐下一步

Patrick 继续真机试学，确认答后选项稳定和手动查看的体验。
