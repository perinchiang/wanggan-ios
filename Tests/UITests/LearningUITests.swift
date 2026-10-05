import XCTest

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
            let isChoice = id.contains("-option-")
            let aboveFooter = !isChoice || button.frame.midY < app.buttons["primary-action"].frame.minY
            if button.isHittable && aboveFooter { break }
            app.swipeUp()
        }
        XCTAssertTrue(button.isHittable, "Not hittable: \(id)")
        button.tap()
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

    func testFullLessonPersistenceAndResume() {
        app.launch()
        XCTAssertTrue(app.buttons["start-lesson"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["start-lesson"].isHittable, "Start should be visible without scrolling")
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
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "30 经验值")
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
        tap("exit-lesson")
        app.buttons["保存进度并退出"].tap()
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "谁才是我的邻居？")
        app.tabBars.buttons["复习"].tap()
        tap("review-gateway")
        tap("primary-action")
        tap("exit-lesson")
        app.buttons["保存进度并退出"].tap()
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
        tap("primary-action")
        revealScene(option: "challenge-option-yes")
        tap("challenge-option-yes")
        tap("primary-action")
        tap("primary-action")
        XCTAssertTrue(app.buttons["continue-learning"].waitForExistence(timeout: 5))
        tap("continue-learning")
        XCTAssertTrue(app.staticTexts["沿着数据走一遍，就清楚了。"].waitForExistence(timeout: 5))
        tap("exit-lesson")
        app.buttons["保存进度并退出"].tap()
        app.tabBars.buttons["学习"].tap()
        XCTAssertEqual(app.staticTexts["recommended-lesson-title"].label, "谁才是我的邻居？")
        tap("start-lesson")
        XCTAssertTrue(app.staticTexts["沿着数据走一遍，就清楚了。"].waitForExistence(timeout: 5))
    }

    func testWrongChoiceTeachesInsteadOfBlockingProgress() {
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
        XCTAssertTrue(app.staticTexts["沿着数据走一遍，就清楚了。"].exists)
    }

    func testSubnetResumesAndCompletesOnStepPlayer() {
        verifyFlow(LessonFlow(id: "subnet", question: "different", challenge: "yes",
                              matches: [("24", "three"), ("16", "two")], expectedXP: 60))
    }

    func testARPResumesAndCompletesOnStepPlayer() {
        verifyFlow(LessonFlow(id: "arp", question: "gateway", challenge: "no",
                              matches: [("local", "nasip"), ("remote", "gwip")], expectedXP: 90))
    }

    func testHopResumesAndCompletesOnStepPlayer() {
        verifyFlow(LessonFlow(id: "hop", question: "frame", challenge: "no",
                              matches: [("ip", "final"), ("mac", "next")], expectedXP: 120))
    }

    func testDNSResumesAndCompletesOnStepPlayer() {
        verifyFlow(LessonFlow(id: "dns", question: "dns", challenge: "no",
                              matches: [("name", "resolve"), ("service", "connect")], expectedXP: 150))
    }

    private func verifyFlow(_ flow: LessonFlow) {
        app.launchArguments = ["--uitesting", "--reset-progress", "--seed-before-\(flow.id)"]
        app.launch()
        tap("lesson-\(flow.id)")
        revealScene(option: "question-option-\(flow.question)")
        tap("question-option-\(flow.question)")
        tap("primary-action")
        tap("exit-lesson")
        app.buttons["保存进度并退出"].tap()

        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
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
            tap("exit-lesson")
            app.buttons["保存进度并退出"].tap()
            app.terminate()
            app.launchArguments = ["--uitesting"]
            app.launch()
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
        for (left, right) in flow.matches {
            tap("match-left-\(left)")
            tap("match-right-\(right)")
        }
        tap("primary-action")
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
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing IPv4 byte \(octet) in WebView")
        for _ in 0..<5 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.isHittable)
        button.tap()
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: app.buttons["primary-action"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
    }

    func testSceneRevealsOneMessageAtATimeAndResumesAfterRelaunch() {
        app.launch()
        tap("start-lesson")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-home"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["question-scene-wiring"].exists)
        XCTAssertFalse(app.buttons["question-option-local"].exists)
        tap("primary-action")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-wiring"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["question-scene-change"].exists)
        tap("exit-lesson")
        app.buttons["保存进度并退出"].tap()
        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
        tap("start-lesson")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-wiring"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["question-scene-change"].exists)
        XCTAssertFalse(app.buttons["question-option-local"].exists)
        tap("primary-action")
        XCTAssertTrue(app.descendants(matching: .any)["question-scene-change"].exists)
    }
}
