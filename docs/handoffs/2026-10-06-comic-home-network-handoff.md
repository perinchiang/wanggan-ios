# 漫画首课候选 0.7.0 build 16

## Current task / 本轮任务
按 Pat 确认的设备插画和工装师傅安装场景，将首课做成底部按钮驱动、累计展开的漫画阅读。

## Completed / 已完成
- 基于 codex/ipv4-introduction 的 6f06436；新增 home-two-boxes 与十格分镜。
- 两张无字安装场景、六张用户提供的设备素材接入 Asset Catalog。
- 可复用 ComicStory / ComicStoryPanel、逐格追加、滚到新格、原生对白、进度与续读。
- 原课程与记录保留，版本 0.7.0 build 16。

## Decisions made / 本轮关键决策
- 风格以用户附件为准，设备不拟人；先前生成的带笑脸和展示产品素材不采用。
- 保留高清位图，未将 PNG 伪装为 SVG。漫画文字由 App 绘制。
- 先交付第一课，完整故事课程地图继续分批实现。

## Not completed / 尚未完成
- 当前环境无 Swift / Xcode；Core 与原生 UI 运行需 macOS Actions。
- 真机试学、VoiceOver 实机焦点与最大字号验收。
- 后续公网地址故事尚未实现；首课之后仍是旧基础课程。

## Known issues / 已知问题
- App 沿用浅色主题；两张用户 JPEG 设备素材为白底。
- 既有 UI 测试含旧目录及 XP 假设，首课候选使用 comic 范围；未宣称全套 UI 已通过。

## Verification / 已做验证
- 4 项既有 Web 回归通过，git diff --check 通过。
- 新增三个 Core 测试及一个原生漫画流程测试；运行结果待 CI 更新。

## Next recommended task / 推荐下一步
运行 Build and test iOS，选择当前分支、ui_scope=comic；检查真实模拟器附件与 IPA，再由 Pat 试学。
