import XCTest
import UIKit

final class LearningUITests: XCTestCase {
    private var app: XCUIApplication!

    private struct LessonFlow {
        let id: String
        let question: String
        let challenge: String
        let matches: [(String, String)]
        let expectedXP: Int
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-progress"]
    }

    private func tap(_ id: String) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing \(id)")
        for _ in 0..<5 {
            let isChoice = id.contains("-option-") || id.hasPrefix("mask-") || id.hasPrefix("match-")
            let footer = app.buttons["short-primary"].exists ? app.buttons["short-primary"] : app.buttons["primary-action"]
            let aboveFooter = !isChoice || button.frame.midY < footer.frame.minY
            // A row with a tiny visible edge can be "hittable" while its tap point
            // sits behind the fixed recommendation panel. Scroll the full row in.
            let recommendation = app.staticTexts["recommended-lesson-title"]
            let visibleRouteRow = !id.hasPrefix("lesson-") || !recommendation.exists ||
                button.frame.maxY < recommendation.frame.minY - 14
            if button.isHittable && aboveFooter && visibleRouteRow { break }
            if button.frame.maxY < 100 { app.swipeDown() }
            else { app.swipeUp() }
        }
        XCTAssertTrue(button.isHittable, "Not hittable: \(id)")
        if id.hasPrefix("lesson-"), app.staticTexts["recommended-lesson-title"].exists {
            XCTAssertLessThan(button.frame.maxY, app.staticTexts["recommended-lesson-title"].frame.minY - 14)
        }
        button.tap()
    }

    // Unexpected interruption restores drafts; explicit exit has separate tests below.
    private func relaunchKeepingProgress() {
        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
        XCTAssertTrue(app.buttons["start-lesson"].waitForExistence(timeout: 10))
    }

    private func screenshot(_ name: String) {
        // Give short native transitions time to finish before exporting evidence.
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func revealScene(option: String) {
        for _ in 0..<8 {
            if app.buttons[option].exists { break }
            tap("primary-action")
        }
        XCTAssertTrue(app.buttons[option].exists, "Choices appear after the conversation")
    }

    private func assertObservationOnly() {
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'question-option-' OR identifier BEGINSWITH 'match-' OR identifier BEGINSWITH 'challenge-option-' ")).firstMatch.exists)
    }

    private func completeFoundationLesson(expectedTitle: String, stages: Int, expectedXP: Int,
                                          expectedNextTitle: String, evidencePrefix: String) {
        XCTAssertTrue(app.staticTexts["recommended-lesson-title"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, expectedTitle)
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["foundation-stage"].label, "观察 1 / \(stages)")
        assertObservationOnly()
        screenshot("\(evidencePrefix)-01-start")
        for stage in 2...stages {
            tap("primary-action")
            XCTAssertEqual(app.staticTexts["foundation-stage"].label, "观察 \(stage) / \(stages)")
            assertObservationOnly()
            if stages == 6 && stage == 4 {
                XCTAssertEqual(app.staticTexts["foundation-bit-equation"].label, "8 + 4 + 1 = 13")
                screenshot("N03-binary-13-demonstration")
            }
        }
        screenshot("\(evidencePrefix)-02-final-stage")
        XCTAssertEqual(app.buttons["primary-action"].label, "完成本课")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["+30 XP"].waitForExistence(timeout: 5))
        screenshot("\(evidencePrefix)-03-complete")
        tap("finish-session")
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "\(expectedXP) 经验值")
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, expectedNextTitle)
    }

    func testHomeTwoBoxesFlow() {
        app.launch()
        XCTAssertTrue(app.staticTexts["recommended-lesson-title"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "宽带师傅为什么装了两个路由器？")
        tap("start-lesson")
        tap("primary-action")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["scene-progress"].label, "3 / 4 条消息")
        screenshot("H01-user-bubble")
        revealScene(option: "question-option-split")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-you-ask"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-technician"].exists)
        screenshot("H01-question-options")
        tap("question-option-split")
        tap("primary-action") // submit the prediction and read the feedback
        tap("primary-action") // advance to the diagram step (stage 1: the fiber node)
        XCTAssertNotNil(UIImage(systemName: "cable.connector"), "The fiber symbol must exist on this iOS runtime")
        let topology = app.descendants(matching: .any)["topology-diagram"].firstMatch
        XCTAssertTrue(topology.waitForExistence(timeout: 5))
        XCTAssertEqual(topology.value as? String, "当前显示：光纤入户")
        screenshot("H02-topology-first-node")
        XCTAssertFalse(topology.label.contains("光猫"), "VoiceOver must not reveal the next device")
        let paragraphs = [
            "师傅指着弱电箱：“这台叫光猫。门外来的光纤先接到它，再由它把连接交给网线。”原来，你认成路由器的第一台设备，另有名字。",
            "顺着这根网线看，另一头才是客厅的家用路由器。它连着家里的设备，也把家里的网络接向光猫。",
            "手机用 Wi-Fi，电脑用网线，都能接到这台路由器上。原来 Wi-Fi 只是连接方式之一，这台设备还照顾着用网线的电脑。",
            "现在点开一个视频。传回手机的数据先经过光猫，再经过路由器，最后通过 Wi-Fi 到达手机。师傅装的不是两台重复的路由器：这一路上，它们各负责一段。"
        ]
        let stages = ["光纤入户、光猫", "光纤入户、光猫、路由器",
                      "光纤入户、光猫、路由器、手机、电脑", "光纤入户、光猫、路由器、手机、电脑"]
        for (index, expectedNodes) in stages.enumerated() {
            tap("primary-action")
            XCTAssertEqual(topology.value as? String, "当前显示：" + expectedNodes)
            let bubble = app.descendants(matching: .any)["topology-explanation-text"].firstMatch
            XCTAssertTrue(bubble.waitForExistence(timeout: 5))
            XCTAssertTrue(bubble.label.contains(paragraphs[index]))
            if index > 0 {
                XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", paragraphs[index - 1])).firstMatch.exists, "Previous explanation is replaced")
            }
            XCTAssertEqual(app.staticTexts["topology-stage"].label, "观察 \(index + 2) / 5")
            XCTAssertEqual(app.buttons["topology-replay"].exists, index == 3,
                           "The journey is introduced with the video paragraph")
            for _ in 0..<5 {
                if bubble.frame.maxY < app.buttons["primary-action"].frame.minY { break }
                app.swipeUp()
            }
            XCTAssertTrue(bubble.isHittable)
            XCTAssertLessThan(bubble.frame.maxY, app.buttons["primary-action"].frame.minY)
            screenshot("H02-explanation-\(index + 1)")
        }
        tap("topology-replay")
        tap("teaching-previous")
        XCTAssertEqual(app.staticTexts["topology-stage"].label, "观察 4 / 5")
        XCTAssertFalse(app.buttons["topology-replay"].exists)
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["topology-stage"].label, "观察 5 / 5")
        screenshot("H03-topology-full")
        revealScene(option: "challenge-option-allinone")
        XCTAssertFalse(app.descendants(matching: .any)["challenge-scene-you-recall"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["challenge-scene-friend-home"].firstMatch.label.contains("后来你去朋友家玩，发现他们家只有一台网络设备。"))
        screenshot("H03-transfer-question")
        tap("challenge-option-allinone")
        tap("primary-action")
        tap("primary-action")
        for pageID in ["integrated-ports", "router-ports", "fttr-rooms", "fttr-reveal"] {
            XCTAssertTrue(app.descendants(matching: .any)["answer-explanation-\(pageID)"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.staticTexts["+30 XP"].exists)
            tap("primary-action")
        }
        XCTAssertTrue(app.staticTexts["+30 XP"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["completion-lesson-title"].label, "宽带师傅为什么装了两个路由器？")
        XCTAssertFalse(app.staticTexts["光猫负责接入光纤网络；家用路由器负责家里的组网和出口。看起来像两个路由器，其实是两份不同的工作，也可以合到一台设备里。"].exists)
        screenshot("H04-completion")
        tap("finish-session")
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "30 经验值")
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "IP 地址是拿来做什么的？")
    }

    func testHomeTeachingBacktrackAndInterruptedResume() {
        app.launch()
        tap("start-lesson")
        revealScene(option: "question-option-coverage")
        tap("question-option-coverage")
        tap("primary-action")
        tap("primary-action")
        relaunchKeepingProgress()
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["topology-stage"].label, "观察 1 / 5")
        XCTAssertFalse(app.buttons["teaching-previous"].exists)
        tap("primary-action")
        tap("teaching-previous")
        XCTAssertEqual(app.staticTexts["topology-stage"].label, "观察 1 / 5")
        tap("primary-action")
        relaunchKeepingProgress()
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["topology-stage"].label, "观察 2 / 5")
        XCTAssertFalse(app.staticTexts["+30 XP"].exists)
    }

    func testHomeLargestTextStaticTeaching() {
        app.launchArguments += ["--test-mask-accessibility"]
        app.launch()
        tap("start-lesson")
        revealScene(option: "question-option-split")
        tap("question-option-split")
        tap("primary-action")
        tap("primary-action")
        for _ in 0..<4 { tap("primary-action") }
        let topology = app.descendants(matching: .any)["topology-diagram"].firstMatch
        XCTAssertTrue(topology.exists)
        XCTAssertTrue(topology.label.contains("数据依次经过"))
        tap("topology-replay")
        tap("teaching-previous")
        XCTAssertEqual(app.staticTexts["topology-stage"].label, "观察 4 / 5")
        screenshot("H05-accessibility-static-topology")
    }

    func testConfirmedExitRestartsLessonAndPreservesMainProgress() {
        app.launchArguments += ["--seed-before-ipv4-address-format"]
        app.launch()
        tap("start-lesson")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["foundation-stage"].label, "观察 2 / 4")
        relaunchKeepingProgress()
        tap("lesson-home-two-boxes")
        tap("primary-action")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["scene-progress"].label, "3 / 4 条消息")
        tap("exit-lesson")
        XCTAssertTrue(app.buttons["确定退出"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["保存进度并退出"].exists)
        screenshot("E01-exit-confirmation")
        app.buttons["取消"].tap()
        XCTAssertEqual(app.staticTexts["scene-progress"].label, "3 / 4 条消息")
        tap("exit-lesson")
        app.buttons["确定退出"].tap()
        XCTAssertTrue(app.buttons["start-lesson"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "60 经验值")
        tap("lesson-home-two-boxes")
        XCTAssertEqual(app.staticTexts["scene-progress"].label, "1 / 4 条消息")
        screenshot("E02-review-restarts")
        tap("exit-lesson")
        app.buttons["确定退出"].tap()
        relaunchKeepingProgress()
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["foundation-stage"].label, "观察 2 / 4")
        screenshot("E03-other-main-draft-preserved")
        tap("exit-lesson")
        app.buttons["确定退出"].tap()
        relaunchKeepingProgress()
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "60 经验值")
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["foundation-stage"].label, "观察 1 / 4")
        screenshot("E04-main-restarts")
    }

    func testShortReviewConfirmedExitStartsFreshAndPreservesXP() {
        app.launchArguments += ["--seed-before-subnet"]
        app.launch()
        let startingXP = app.staticTexts["xp-badge"].label
        app.tabBars.buttons["复习"].tap()
        tap("short-review-gateway")
        tap("short-option-all-fail")
        tap("short-primary")
        XCTAssertTrue(app.staticTexts["这里值得再想想"].waitForExistence(timeout: 5))
        tap("exit-short-review")
        XCTAssertTrue(app.buttons["确定退出"].waitForExistence(timeout: 5))
        app.buttons["取消"].tap()
        XCTAssertTrue(app.staticTexts["这里值得再想想"].exists)
        tap("exit-short-review")
        app.buttons["确定退出"].tap()
        tap("short-review-gateway")
        XCTAssertTrue(app.buttons["short-primary"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["short-primary"].isEnabled)
        XCTAssertFalse(app.staticTexts["这里值得再想想"].exists)
        screenshot("E05-short-review-restarts")
        tap("exit-short-review")
        app.buttons["确定退出"].tap()
        app.tabBars.buttons["学习"].tap()
        XCTAssertEqual(app.staticTexts["xp-badge"].label, startingXP)
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "谁才是我的邻居？")
    }

    func testIPv4FoundationAddressRoleFlow() {
        app.launchArguments += ["--seed-before-ipv4-address-role"]
        app.launch()
        completeFoundationLesson(expectedTitle: "IP 地址是拿来做什么的？", stages: 4, expectedXP: 60,
                                 expectedNextTitle: "这串地址，电脑怎么看？", evidencePrefix: "N01-role")
    }

    func testIPv4FoundationFormatBacktrackingResumeAndCompletion() {
        app.launchArguments += ["--seed-before-ipv4-address-format"]
        app.launch()
        tap("start-lesson")
        assertObservationOnly()
        tap("primary-action")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["foundation-stage"].label, "观察 3 / 4")
        tap("foundation-previous")
        XCTAssertEqual(app.staticTexts["foundation-stage"].label, "观察 2 / 4")
        screenshot("N02-format-backtrack")
        relaunchKeepingProgress()
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["foundation-stage"].label, "观察 2 / 4")
        assertObservationOnly()
        tap("primary-action")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["foundation-stage"].label, "观察 4 / 4")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["+30 XP"].waitForExistence(timeout: 5))
        screenshot("N02-format-complete")
        tap("finish-session")
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "90 经验值")
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "八个开关，能装下多大的数？")
    }

    func testIPv4FoundationOctetBinaryFlow() {
        app.launchArguments += ["--seed-before-ipv4-octet-binary"]
        app.launch()
        completeFoundationLesson(expectedTitle: "八个开关，能装下多大的数？", stages: 6, expectedXP: 120,
                                 expectedNextTitle: "网关填错会怎样？", evidencePrefix: "N03-binary")
    }

    func testFoundationBinaryLargestTextStaticPresentation() {
        app.launchArguments += ["--seed-before-ipv4-octet-binary", "--test-mask-accessibility"]
        app.launch()
        tap("start-lesson")
        for _ in 0..<3 { tap("primary-action") }
        let equation = app.staticTexts["foundation-bit-equation"]
        XCTAssertEqual(equation.label, "8 + 4 + 1 = 13")
        for _ in 0..<5 {
            if equation.isHittable && equation.frame.maxY < app.buttons["primary-action"].frame.minY { break }
            app.swipeUp()
        }
        XCTAssertTrue(equation.isHittable)
        XCTAssertLessThan(equation.frame.maxY, app.buttons["primary-action"].frame.minY)
        screenshot("N03-largest-text-static-13")
        tap("primary-action")
        tap("primary-action")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["+30 XP"].waitForExistence(timeout: 5))
    }

    private func verifyImmediateMatching(_ pairs: [(String, String)]) {
        let leftA = "match-left-\(pairs[0].0)"
        let rightA = "match-right-\(pairs[0].1)"
        let leftB = "match-left-\(pairs[1].0)"
        let rightB = "match-right-\(pairs[1].1)"
        func value(_ id: String) -> String { app.buttons[id].value as? String ?? "" }
        XCTAssertFalse(app.buttons["clear-matches"].exists)
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        tap(rightA)
        XCTAssertTrue(value(rightA).contains("已选中"))
        screenshot("pair-right-selected-dark")
        tap(rightA)
        XCTAssertEqual(value(rightA), "未选择")
        tap(leftA)
        tap(rightB) // Wrong: no check or reset button is needed.
        XCTAssertTrue(app.buttons[leftA].isEnabled)
        XCTAssertTrue(app.buttons[rightB].isEnabled)
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "pair-mismatch-feedback"
        attachment.lifetime = .keepAlways
        add(attachment)
        let reset = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "未选择"), object: app.buttons[leftA])
        XCTAssertEqual(XCTWaiter.wait(for: [reset], timeout: 5), .completed)
        tap(rightA)
        tap(leftA) // Right-first succeeds immediately.
        let matched = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == false"), object: app.buttons[leftA])
        XCTAssertEqual(XCTWaiter.wait(for: [matched], timeout: 5), .completed)
        XCTAssertTrue(value(leftA).contains("配对正确"))
        screenshot("pair-correct-green")
        relaunchKeepingProgress()
        tap("start-lesson")
        XCTAssertFalse(app.buttons[leftA].isEnabled)
        XCTAssertFalse(app.buttons[rightA].isEnabled)
        tap(leftB)
        tap(rightB) // Left-first also succeeds; prior success stays locked.
        let completed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: app.buttons["primary-action"])
        XCTAssertEqual(XCTWaiter.wait(for: [completed], timeout: 5), .completed)
        XCTAssertFalse(app.buttons[leftB].isEnabled)
        XCTAssertFalse(app.buttons[rightB].isEnabled)
        screenshot("pair-all-correct-no-lines")
    }

    func testSubnetMaskObservationRetryBacktrackingResumeAndCompletion() throws {
        throw XCTSkip("旧 subnet-mask Pilot 已归档，不再出现在学习路线")
        app.launchArguments += ["--seed-before-subnet-mask"]
        app.launch()
        tap("start-lesson")
        revealScene(option: "question-option-three")
        tap("question-option-three")
        tap("primary-action")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["mask-stage"].label, "观察 1 / 4")
        XCTAssertFalse(app.staticTexts["mask-decimal"].exists)
        tap("primary-action")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        tap("mask-octet-3")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        tap("mask-octet-4")
        XCTAssertTrue(app.buttons["primary-action"].isEnabled)
        screenshot("M01-mask-decompose")
        tap("primary-action")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        tap("mask-condition-toggle")
        XCTAssertEqual(app.staticTexts["mask-prefix"].label, "前缀 /16")
        XCTAssertTrue(app.staticTexts["地址没有变。当前 /16 标记 16 个网络位，其余 16 位属于主机部分。分界由掩码决定。"].exists)
        tap("mask-condition-toggle")
        XCTAssertEqual(app.staticTexts["mask-prefix"].label, "前缀 /24")
        XCTAssertTrue(app.staticTexts["地址没有变。当前 /24 标记 24 个网络位，其余 8 位属于主机部分。分界由掩码决定。"].exists)
        tap("mask-condition-toggle")
        screenshot("M02-mask-condition")
        tap("mask-previous")
        XCTAssertEqual(app.staticTexts["mask-stage"].label, "观察 2 / 4")
        relaunchKeepingProgress()
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["mask-stage"].label, "观察 2 / 4")
        XCTAssertTrue(app.buttons["primary-action"].isEnabled)
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["mask-prefix"].label, "前缀 /16")
        let heading = app.staticTexts["地址不动，只换分界规则"]
        for _ in 0..<4 where !heading.isHittable { app.swipeDown() }
        heading.swipeLeft()
        XCTAssertEqual(app.staticTexts["mask-stage"].label, "观察 2 / 4")
        tap("primary-action")
        tap("primary-action")
        XCTAssertFalse(app.staticTexts["mask-decimal"].exists, "Practice does not expose the answer mask")
        XCTAssertFalse(app.staticTexts["mask-partition"].exists)
        tap("mask-octet-3")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["再数一数网络位"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        relaunchKeepingProgress()
        app.terminate()
        app.launch()
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["mask-stage"].label, "观察 4 / 4")
        XCTAssertTrue(app.staticTexts["再数一数网络位"].exists)
        tap("mask-octet-1")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["分界找对了"].exists)
        screenshot("M03-mask-practice")
        tap("primary-action")
        for (left, right) in [("one", "network"), ("zero", "host")] {
            tap("match-left-\(left)")
            tap("match-right-\(right)")
        }
        tap("primary-action")
        tap("primary-action")
        revealScene(option: "challenge-option-three")
        tap("challenge-option-three")
        tap("primary-action")
        tap("primary-action")
        tap("challenge-option-same")
        tap("primary-action")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["+30 XP"].waitForExistence(timeout: 5))
        tap("finish-session")
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "60 经验值")
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "网关填错会怎样？")
    }

    func testSubnetMaskAtLargestTextSizeWithStaticPresentation() throws {
        throw XCTSkip("旧 subnet-mask Pilot 已归档，不再出现在学习路线")
        app.launchArguments += ["--seed-before-subnet-mask", "--test-mask-accessibility"]
        app.launch()
        tap("start-lesson")
        revealScene(option: "question-option-mask")
        tap("question-option-mask")
        tap("primary-action")
        tap("primary-action")
        tap("primary-action")
        tap("mask-octet-1")
        tap("mask-octet-4")
        XCTAssertTrue(app.buttons["primary-action"].isEnabled)
        screenshot("M04-mask-largest-text-static")
        tap("primary-action")
        tap("mask-condition-toggle")
        tap("primary-action")
        tap("mask-octet-1")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["分界找对了"].exists)
        screenshot("M05-mask-largest-text-result")
    }

    func testIPv4IntroductionObservationBacktrackingResumeAndCompletion() throws {
        throw XCTSkip("旧 ipv4-address Pilot 已归档，由新的三节基础课取代")
        app.launchArguments = ["--uitesting", "--reset-progress"]
        app.launch()
        XCTAssertTrue(app.staticTexts["recommended-lesson-title"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "IPv4 地址为什么写成四段？")
        tap("start-lesson")
        revealScene(option: "question-option-devices")
        tap("question-option-devices")
        tap("primary-action")
        tap("primary-action")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        let octet = app.webViews.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "第 4 段，10，点选")
        ).firstMatch
        tapWebControl(octet, evidence: "G00-intro-before-select")
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: app.buttons["primary-action"])
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
        screenshot("G01-intro-select")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["intro-stage"].label, "观察 2 / 4")
        screenshot("G02-intro-eight-bits")
        tap("primary-action")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        tap("intro-range-toggle")
        XCTAssertTrue(app.buttons["primary-action"].isEnabled)
        screenshot("G03-intro-range")
        tap("intro-previous")
        XCTAssertEqual(app.staticTexts["intro-stage"].label, "观察 2 / 4")
        relaunchKeepingProgress()
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["intro-stage"].label, "观察 2 / 4")
        tap("primary-action")
        XCTAssertTrue(app.buttons["primary-action"].isEnabled, "Observed range survives backtracking and relaunch")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["intro-stage"].label, "观察 4 / 4")
        screenshot("G04-intro-whole-address")
        // The gesture is deliberately limited to the teaching text, away from the WebView.
        let heading = app.staticTexts["四段，合起来是 32 位"]
        XCTAssertTrue(heading.waitForExistence(timeout: 5))
        for _ in 0..<4 where !heading.isHittable { app.swipeDown() }
        heading.swipeLeft()
        XCTAssertEqual(app.staticTexts["intro-stage"].label, "观察 3 / 4")
        tap("primary-action")
        tap("primary-action")
        for (left, right) in [("bit", "zeroone"), ("octet", "eight"), ("address", "thirtytwo")] {
            tap("match-left-\(left)")
            tap("match-right-\(right)")
        }
        tap("primary-action")
        tap("primary-action")
        revealScene(option: "challenge-option-four")
        tap("challenge-option-four")
        tap("primary-action")
        tap("primary-action")
        tap("challenge-option-no")
        tap("primary-action")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["+30 XP"].waitForExistence(timeout: 5))
        tap("finish-session")
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "30 经验值")
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "子网掩码怎样划分地址？")
    }

    func testShortReviewResumesWithoutReplacingMainOrDuplicatingXP() {
        app.launchArguments += ["--seed-before-subnet"]
        app.launch()
        XCTAssertTrue(app.staticTexts["xp-badge"].waitForExistence(timeout: 10))
        let startingXP = app.staticTexts["xp-badge"].label
        tap("start-lesson")
        tap("primary-action")
        relaunchKeepingProgress()
        app.tabBars.buttons["复习"].tap()
        tap("short-review-gateway")
        XCTAssertTrue(app.buttons["short-primary"].waitForExistence(timeout: 10), "Short review should finish presenting before assertions")
        XCTAssertFalse(app.buttons["short-primary"].isEnabled)
        tap("short-option-all-fail")
        tap("short-primary")
        XCTAssertTrue(app.staticTexts["这里值得再想想"].waitForExistence(timeout: 5))
        let feedback = app.staticTexts["你把网关当成了所有通信的必经之路。同一子网内，电脑可以直接把数据交给打印机。"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(feedback.isHittable)
        XCTAssertLessThan(feedback.frame.maxY, app.buttons["short-primary"].frame.minY)
        screenshot("F01-short-review-wrong-feedback")
        relaunchKeepingProgress()
        XCTAssertTrue(app.staticTexts["recommended-lesson-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "谁才是我的邻居？")
        app.tabBars.buttons["复习"].tap()
        tap("short-review-gateway")
        XCTAssertTrue(app.staticTexts["这里值得再想想"].waitForExistence(timeout: 5))
        tap("short-primary")
        tap("short-option-local")
        tap("short-primary")
        XCTAssertTrue(app.staticTexts["这次在帮助下完成，下次换个场景再试。"].waitForExistence(timeout: 5))
        tap("short-primary")
        XCTAssertEqual(app.staticTexts["short-evidence"].label, "这次在帮助下完成")
        XCTAssertEqual(app.staticTexts["short-reward"].label, "今天这节课的经验已领取，判断记录仍会更新。")
        screenshot("F02-short-review-completion")
        tap("short-primary")
        tap("short-review-gateway")
        XCTAssertTrue(app.staticTexts["这次本地投影还能连接吗？"].waitForExistence(timeout: 5))
        tap("short-option-local")
        tap("short-primary")
        tap("short-primary")
        XCTAssertEqual(app.staticTexts["short-evidence"].label, "独立答对过")
        tap("short-primary")
        app.tabBars.buttons["学习"].tap()
        XCTAssertEqual(app.staticTexts["xp-badge"].label, startingXP)
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "谁才是我的邻居？")
        tap("start-lesson")
        XCTAssertFalse(app.buttons["question-option-different"].exists)
        revealScene(option: "question-option-different")
    }

    func testDNSShortReviewHintAndNextScenario() {
        app.launchArguments += ["--seed-completed-course"]
        app.launch()
        app.tabBars.buttons["复习"].tap()
        tap("short-review-dns")
        tap("short-hint")
        tap("short-option-ip")
        tap("short-primary")
        tap("short-primary")
        XCTAssertEqual(app.staticTexts["short-evidence"].label, "这次在帮助下完成")
        tap("short-primary")
        tap("short-review-dns")
        XCTAssertTrue(app.staticTexts["这个已缓存的网站此刻还能打开吗？"].waitForExistence(timeout: 5))
        screenshot("F03-dns-cached-scene")
        tap("short-option-cached")
        tap("short-primary")
        tap("short-primary")
        XCTAssertEqual(app.staticTexts["short-evidence"].label, "独立答对过")
        tap("short-primary")
        app.tabBars.buttons["学习"].tap()
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "270 经验值")
    }

    func testFullLessonPersistenceAndResume() {
        app.launchArguments += ["--seed-before-gateway"]
        app.launch()
        XCTAssertTrue(app.buttons["start-lesson"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["start-lesson"].isHittable, "Start should be visible without scrolling")
        let startingXP = Int(app.staticTexts["xp-badge"].label.split(separator: " ").first ?? "") ?? -1
        XCTAssertGreaterThanOrEqual(startingXP, 0)
        screenshot("01-learning-route")
        tap("start-lesson")
        XCTAssertFalse(app.buttons["question-option-local"].exists)
        screenshot("06-first-message")
        tap("primary-action")
        screenshot("07-scenario-conversation")
        revealScene(option: "question-option-local")
        tap("question-option-local")
        screenshot("02-selected-answer")
        tap("primary-action")
        tap("primary-action")
        screenshot("03-explanation")
        for _ in 0..<8 {
            if app.buttons["match-left-nas"].exists { break }
            tap("primary-action")
        }
        XCTAssertTrue(app.buttons["match-left-nas"].exists, "Matching appears after explanation")
        tap("match-left-nas")
        tap("match-right-host")
        tap("match-left-internet")
        tap("match-right-router")
        screenshot("04-matching")
        tap("primary-action")
        tap("primary-action")
        revealScene(option: "challenge-option-no")
        tap("challenge-option-no")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["这里值得再想想"].exists)
        tap("primary-action")
        tap("challenge-option-yes")
        tap("primary-action")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["+30 XP"].waitForExistence(timeout: 5))
        screenshot("05-completion")
        tap("finish-session")

        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
        XCTAssertTrue(app.staticTexts["xp-badge"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "\(startingXP + 30) 经验值")
        tap("lesson-subnet")
        revealScene(option: "question-option-different")
        let firstAddress = app.descendants(matching: .any)["question-answer-addresses-a"]
        let secondAddress = app.descendants(matching: .any)["question-answer-addresses-b"]
        XCTAssertTrue(firstAddress.isHittable)
        XCTAssertTrue(secondAddress.isHittable)
        XCTAssertTrue(firstAddress.label.contains("192.168.1.10"))
        XCTAssertTrue(secondAddress.label.contains("192.168.2.20"))
        XCTAssertTrue(app.buttons["question-option-different"].isHittable)
        XCTAssertLessThan(app.buttons["question-option-different"].frame.midY, app.buttons["primary-action"].frame.minY)
        screenshot("08-subnet-comparison")
        tap("question-option-different")
        XCTAssertTrue(app.buttons["primary-action"].isEnabled)
        tap("primary-action")
        tap("primary-action")
        relaunchKeepingProgress()
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "谁才是我的邻居？")
        app.tabBars.buttons["复习"].tap()
        tap("review-gateway")
        tap("primary-action")
        relaunchKeepingProgress()
        app.tabBars.buttons["学习"].tap()
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "谁才是我的邻居？")
        screenshot("09-review-keeps-main-progress")
        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
        XCTAssertTrue(app.staticTexts["recommended-lesson-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "谁才是我的邻居？")
        app.tabBars.buttons["复习"].tap()
        tap("review-gateway")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-wiring"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["question-scene-change"].exists)
        revealScene(option: "question-option-local")
        tap("question-option-local")
        tap("primary-action")
        tap("primary-action")
        for _ in 0..<8 {
            if app.buttons["match-left-nas"].exists { break }
            tap("primary-action")
        }
        XCTAssertTrue(app.buttons["match-left-nas"].exists, "Matching appears after explanation")
        tap("match-left-nas")
        tap("match-right-host")
        tap("match-left-internet")
        tap("match-right-router")
        tap("primary-action")
        revealScene(option: "challenge-option-yes")
        tap("challenge-option-yes")
        tap("primary-action")
        tap("primary-action")
        XCTAssertTrue(app.buttons["continue-learning"].waitForExistence(timeout: 5))
        tap("continue-learning")
        XCTAssertTrue(app.buttons["explanation-sources"].waitForExistence(timeout: 5))
        relaunchKeepingProgress()
        app.tabBars.buttons["学习"].tap()
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "谁才是我的邻居？")
        tap("start-lesson")
        XCTAssertTrue(app.buttons["explanation-sources"].waitForExistence(timeout: 5))
    }

    func testWrongChoiceTeachesInsteadOfBlockingProgress() {
        app.launchArguments += ["--seed-before-gateway"]
        app.launch()
        tap("lesson-gateway")
        revealScene(option: "question-option-all-fail")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        tap("question-option-all-fail")
        tap("primary-action")
        let feedback = app.staticTexts["你把网关当成了所有通信的必经之路。先看看：目标就在本地时，需要它转交吗？"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        let footer = app.buttons["primary-action"]
        let deadline = Date().addingTimeInterval(5)
        while feedback.frame.maxY > footer.frame.minY + 2 && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertLessThanOrEqual(feedback.frame.maxY, footer.frame.minY + 2,
                                 "Answer feedback should be visible above the fixed action button")
        XCTAssertTrue(feedback.isHittable, "Answer feedback should be on screen without a manual swipe")
        screenshot("10-wrong-answer-feedback")
        tap("primary-action")
        XCTAssertTrue(app.buttons["explanation-sources"].exists)
    }

    func testSubnetResumesAndCompletesOnStepPlayer() {
        verifyFlow(LessonFlow(id: "subnet", question: "different", challenge: "yes",
                              matches: [("24", "three"), ("16", "two")], expectedXP: 180))
    }

    func testARPResumesAndCompletesOnStepPlayer() {
        verifyFlow(LessonFlow(id: "arp", question: "gateway", challenge: "no",
                              matches: [("local", "nasip"), ("remote", "gwip")], expectedXP: 210))
    }

    func testHopResumesAndCompletesOnStepPlayer() {
        verifyFlow(LessonFlow(id: "hop", question: "frame", challenge: "no",
                              matches: [("ip", "final"), ("mac", "next")], expectedXP: 240))
    }

    func testDNSResumesAndCompletesOnStepPlayer() {
        verifyFlow(LessonFlow(id: "dns", question: "dns", challenge: "no",
                              matches: [("name", "resolve"), ("service", "connect")], expectedXP: 270))
    }

    private func verifyFlow(_ flow: LessonFlow) {
        app.launchArguments = ["--uitesting", "--reset-progress", "--seed-before-\(flow.id)"]
        app.launch()
        tap("lesson-\(flow.id)")
        revealScene(option: "question-option-\(flow.question)")
        tap("question-option-\(flow.question)")
        tap("primary-action")
        relaunchKeepingProgress()
        tap("start-lesson")
        XCTAssertTrue(app.buttons["question-option-\(flow.question)"].exists)
        XCTAssertEqual(app.buttons["primary-action"].label, "看看为什么")
        tap("primary-action")

        if flow.id == "subnet" {
            let web = app.webViews.firstMatch
            XCTAssertTrue(web.waitForExistence(timeout: 10), "The local IPv4 visual should load inside the lesson")
            XCTAssertTrue(web.staticTexts["192.168.1.10/24"].waitForExistence(timeout: 10))
            XCTAssertEqual(app.buttons["primary-action"].label, "换一条试试")
            screenshot("12-ipv4-explanation")
            tap("primary-action")
            XCTAssertFalse(app.buttons["primary-action"].isEnabled)
            tapIPv4Boundary(3)
            tap("primary-action")
            XCTAssertTrue(app.staticTexts["再数一数网络位"].exists)
            relaunchKeepingProgress()
            tap("start-lesson")
            XCTAssertEqual(app.buttons["primary-action"].label, "检查分界")
            XCTAssertTrue(app.staticTexts["再数一数网络位"].exists)
            tapIPv4Boundary(2)
            tap("primary-action")
            XCTAssertTrue(app.staticTexts["分界找对了"].exists)
            screenshot("13-ipv4-practice")
            tap("primary-action")
        }

        for _ in 0..<8 {
            if app.buttons["match-left-\(flow.matches[0].0)"].exists { break }
            tap("primary-action")
        }
        XCTAssertTrue(app.buttons["match-left-\(flow.matches[0].0)"].exists)
        if flow.id == "hop" {
            verifyImmediateMatching(flow.matches)
        } else {
            for (left, right) in flow.matches {
                tap("match-left-\(left)")
                tap("match-right-\(right)")
            }
        }
        tap("primary-action")
        revealScene(option: "challenge-option-\(flow.challenge)")
        tap("challenge-option-\(flow.challenge)")
        tap("primary-action")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["+30 XP"].waitForExistence(timeout: 5))
        screenshot("11-\(flow.id)-completion")
        tap("finish-session")
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "\(flow.expectedXP) 经验值")
    }

    private func tapIPv4Boundary(_ octet: Int) {
        // WebKit exposes aria-pressed buttons as a selectable native element.
        let button = app.webViews.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "第 \(octet) 个字节")
        ).firstMatch
        tapWebControl(button, evidence: "ipv4-before-boundary-\(octet)")
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: app.buttons["primary-action"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
    }

    private func tapWebControl(_ control: XCUIElement, evidence: String) {
        XCTAssertTrue(control.waitForExistence(timeout: 10), "Missing Web control")
        let footer = app.buttons["primary-action"]
        for _ in 0..<5 {
            if control.isHittable && control.frame.minY > 100 && control.frame.maxY < footer.frame.minY { break }
            if control.frame.minY < 100 { app.swipeDown() }
            else { app.swipeUp() }
        }
        // WebKit can expose its accessibility tree before the resized native
        // frame and rendered content settle. Observe stable geometry before tapping.
        let deadline = Date().addingTimeInterval(5)
        var previous = control.frame
        var stableSamples = 0
        while stableSamples < 4 && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.25)
            let current = control.frame
            stableSamples = current == previous ? stableSamples + 1 : 0
            previous = current
        }
        XCTAssertEqual(stableSamples, 4, "Web control geometry did not settle")
        XCTAssertTrue(control.isHittable)
        XCTAssertGreaterThan(control.frame.minY, 100)
        XCTAssertLessThan(control.frame.maxY, footer.frame.minY)
        screenshot(evidence)
        // aria-pressed is exposed as a Switch. Use the visible card center,
        // so the event tests the HTML hit target rather than a native Switch action.
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func testSceneRevealsOneMessageAtATimeAndResumesAfterRelaunch() {
        app.launchArguments += ["--seed-before-gateway"]
        app.launch()
        tap("start-lesson")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-home"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["question-scene-wiring"].exists)
        XCTAssertFalse(app.buttons["question-option-local"].exists)
        tap("primary-action")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-wiring"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["question-scene-change"].exists)
        relaunchKeepingProgress()
        tap("start-lesson")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-wiring"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["question-scene-change"].exists)
        XCTAssertFalse(app.buttons["question-option-local"].exists)
        tap("primary-action")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-change"].exists)
    }
}
