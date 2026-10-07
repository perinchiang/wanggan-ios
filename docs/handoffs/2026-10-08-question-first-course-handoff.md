# 连续短题课程方向澄清

## Current task / 本轮任务

Patrick 指出此前方案仍像讲解加互动，进一步明确希望连续简单小题、教学少且自然融入，先确定章名与课名。

## Completed / 已完成

更新 PRODUCT / COURSE_GUIDE，同步 DESIGN / ARCHITECTURE / README 的相关引用与方向；重写 [编排草案](../first-learning-loop-draft.md)，撤下未经认可的 Wi-Fi 断线第一课候选。只改文档。

Patrick 确认短题方向后，补充《你家的网络》 / 《有线和无线》的候选命名、六道审稿样题与静态配图。图用系统符号和可复用矢量图元生成，保存在忽略目录 build/course-review；实际 App 内容与 UI 未改，题目和名称待 Patrick 审阅。

## Decisions made / 本轮关键决策

正式原则以所属文档为准：连续短题承担教学，常规题目标约 10 秒可答，章节与课程均明确命名，替换此前普通课程可省略课名的方向。具体章名、课名、题量及题型比例没有确认；旧题目案例不能当成已认可教案。

## Not completed / 尚未完成

完整课程名称清单与题序尚未确认；六道样题未接入 App，题目角色与错题队列尚未实现。Mac 工程与设备验收沿用本日 [迁移审计记录](2026-10-08-mac-takeover-handoff.md)，本轮没有重复运行。

## Known issues / 已知问题

现有两项 UI 失败仍未修复；仅剩一道错题的队尾间隔与章节通过率仍待实施前明确。

## Verification / 已做验证

33 个本地文档链接、尾部空白检查与 git diff --check 通过；确认当前正式文档已去除普通课程可不命名的旧规则，并区分正式方向与未确认草案。Sources、Resources、Tests、project.yml、Package.swift 仍无改动。本次只改文档，未运行 build / test，未修改 GitHub 或部署 App。

样题补稿后，本次两份文档的 7 个本地链接与空白检查通过，git diff --check 通过。使用 Mac 原生符号与矢量图元生成 2160 × 3060 静态 PNG，实际查看并修正图示：连接方式在链路上表达，网线端点接到设备边界；点选题限定手机 / 电脑目标。渲染脚本运行成功；不是 App 构建、UI 测试或教学体验验收。图与脚本均确认被 Git 忽略。

## Next recommended task / 推荐下一步

先审六道候选题与配图，根据反馈确定命名和编排，再按实际试学调整；未获认可前不写入课程资源。
