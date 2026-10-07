import XCTest
import UIKit

final class LearningUITests: XCTestCase {
    private var app: XCUIApplication!

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
            let isChoice = id.contains("-option-") || id.hasPrefix("match-")
            let footer = app.buttons["primary-action"]
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

    func testHomeTwoBoxesFlow() {
        app.launch()
        XCTAssertEqual(app.tabBars.buttons.count, 2)
        XCTAssertTrue(app.tabBars.buttons["学习"].exists)
        XCTAssertTrue(app.tabBars.buttons["我的"].exists)
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
            "师傅指着弱电箱：“这台叫光猫。”门外来的光纤接在它上面，家里的设备要通过它连上运营商的网络。原来，第一台还真不是你以为的路由器。",
            "顺着这根网线看，另一头才是客厅的家用路由器。它连着家里的设备，也把家里的网络接向光猫。",
            "手机用 Wi-Fi，电脑用网线，都能接到这台路由器上。原来 Wi-Fi 只是连接方式之一，这台设备还照顾着用网线的电脑。",
            "现在点开一个视频。传回手机的数据先经过光猫，再经过路由器，最后通过 Wi-Fi 到达手机。你刚才认成“两台路由器”的，其实是一台光猫和一台家用路由器。"
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
        XCTAssertFalse(app.staticTexts["光猫连接运营商的光纤网络，家用路由器通过光猫上网，并让手机、电脑通过 Wi-Fi 或网线接入家庭网络。有些设备集成了光猫和路由器的功能。"].exists)
        screenshot("H04-completion")
        tap("finish-session")
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "30 经验值")
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "宽带师傅为什么装了两个路由器？")
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
        app.launchArguments += ["--test-accessibility"]
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

    func testConfirmedExitRestartsExample() {
        app.launch()
        tap("start-lesson")
        tap("primary-action")
        tap("primary-action")
        tap("exit-lesson")
        XCTAssertTrue(app.buttons["确定退出"].waitForExistence(timeout: 5))
        app.buttons["取消"].tap()
        XCTAssertEqual(app.staticTexts["scene-progress"].label, "3 / 4 条消息")
        tap("exit-lesson")
        app.buttons["确定退出"].tap()
        relaunchKeepingProgress()
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "0 经验值")
        tap("start-lesson")
        XCTAssertEqual(app.staticTexts["scene-progress"].label, "1 / 4 条消息")
    }
}
