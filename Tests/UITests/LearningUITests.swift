import XCTest

final class LearningUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-progress"]
        app.launch()
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
        tap("lesson-gateway")
        revealScene(option: "question-option-all-fail")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        tap("question-option-all-fail")
        tap("primary-action")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["沿着数据走一遍，就清楚了。"].exists)
    }

    func testSceneRevealsOneMessageAtATimeAndResumesAfterRelaunch() {
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
