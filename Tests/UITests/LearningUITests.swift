import XCTest

final class LearningUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 240
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-progress"]
        app.launch()
    }

    private func tap(_ id: String) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing \(id)")
        for _ in 0..<5 {
            if button.isHittable { break }
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

    func testFullLessonPersistenceAndResume() {
        XCTAssertTrue(app.buttons["start-lesson"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["start-lesson"].isHittable, "Start should be visible without scrolling")
        screenshot("01-learning-route")
        tap("start-lesson")
        tap("question-option-local")
        screenshot("02-selected-answer")
        tap("primary-action")
        tap("primary-action")
        screenshot("03-explanation")
        tap("primary-action")
        tap("primary-action")
        tap("primary-action")
        tap("match-left-nas")
        tap("match-right-host")
        tap("match-left-internet")
        tap("match-right-router")
        screenshot("04-matching")
        tap("primary-action")
        tap("primary-action")
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
        tap("question-option-different")
        tap("primary-action")
        tap("primary-action")
        tap("exit-lesson")
        app.buttons["保存进度并退出"].tap()
        tap("start-lesson")
        XCTAssertTrue(app.staticTexts["沿着数据走一遍，就清楚了。"].waitForExistence(timeout: 5))
    }

    func testWrongChoiceTeachesInsteadOfBlockingProgress() {
        tap("lesson-gateway")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        tap("question-option-all-fail")
        tap("primary-action")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["沿着数据走一遍，就清楚了。"].exists)
    }
}
