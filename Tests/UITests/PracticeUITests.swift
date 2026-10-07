import XCTest

final class PracticeUITests: XCTestCase {
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
        for _ in 0..<8 {
            let footer = app.buttons["primary-action"]
            let answer = id.hasPrefix("practice-option-") || id == "practice-blank"
            if button.isHittable && (!answer || button.frame.midY < footer.frame.minY) { break }
            app.swipeUp()
        }
        XCTAssertTrue(button.isHittable, "Not hittable: \(id)")
        button.tap()
    }
    private func picture(_ name: String, footerTitle: String? = nil) {
        if let footerTitle {
            // Capture the new question after its action label has updated.
            expectation(for: NSPredicate(format: "label == %@", footerTitle),
                        evaluatedWith: app.buttons["primary-action"])
            waitForExpectations(timeout: 5)
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    private func start() {
        app.launch()
        tap("start-lesson")
        XCTAssertTrue(app.staticTexts["practice-prompt"].waitForExistence(timeout: 10))
    }
    private func answerBlank(_ option: String) {
        tap("practice-option-\(option)")
        tap("primary-action") // Check
        XCTAssertTrue(app.staticTexts["practice-result"].waitForExistence(timeout: 5))
        tap("primary-action") // Continue
    }
    private func finishFromWiredConnection() {
        for option in ["wired", "router", "ont", "service"] { answerBlank(option) }
        tap("practice-option-no")
        tap("primary-action")
    }
    private func relaunchKeepingProgress() {
        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
        tap("start-lesson")
    }

    func testEverydayQuestionFlowFillUndoAndRewardOnlyOnce() {
        start()
        picture("Q01-wireless-lan", footerTitle: "检查")
        tap("practice-option-wired-lan")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["practice-result"].label, "看看答案")
        picture("Q01-exploration-feedback")
        tap("primary-action")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        tap("practice-option-wifi")
        XCTAssertTrue(app.buttons["primary-action"].isEnabled)
        tap("practice-blank")
        XCTAssertFalse(app.buttons["primary-action"].isEnabled)
        answerBlank("wifi")
        answerBlank("wired")
        XCTAssertTrue(app.buttons["practice-option-router"].waitForExistence(timeout: 5))
        picture("Q04-router-and-three-options", footerTitle: "检查")
        answerBlank("router")
        picture("Q05-optical-modem", footerTitle: "检查")
        answerBlank("ont")
        picture("Q06-broadband-service", footerTitle: "检查")
        answerBlank("service")
        picture("Q07-wifi-and-internet")
        tap("practice-option-no")
        picture("Q07-feedback")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["completion-reward"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["completion-reward"].label, "+30 XP")
        XCTAssertEqual(app.staticTexts["completion-lesson-title"].label, "1-1")
        tap("continue-learning")
        tap("start-lesson")
        answerBlank("wlan")
        answerBlank("wifi")
        finishFromWiredConnection()
        XCTAssertEqual(app.staticTexts["completion-reward"].label, "这节已经完成过了")
    }

    func testInterruptedDraftKeepsFilledWordFeedbackAndMasteryRetry() {
        start()
        answerBlank("wlan")
        tap("practice-option-wifi")
        relaunchKeepingProgress()
        XCTAssertEqual(app.buttons["practice-blank"].label, "已填入Wi-Fi，点按撤回")
        XCTAssertFalse(app.staticTexts["practice-result"].exists)
        tap("practice-blank")
        tap("practice-option-bluetooth")
        tap("primary-action")
        relaunchKeepingProgress()
        XCTAssertEqual(app.staticTexts["practice-result"].label, "这题答错了")
        XCTAssertTrue(app.staticTexts["正确答案：Wi-Fi"].exists)
        picture("Q02-restored-wrong-answer")
        tap("primary-action")
        finishFromWiredConnection()
        XCTAssertFalse(app.staticTexts["completion-reward"].exists)
        XCTAssertTrue(app.buttons["practice-option-bluetooth"].exists)
        XCTAssertFalse(app.staticTexts["practice-result"].exists)
        answerBlank("wifi")
        XCTAssertEqual(app.staticTexts["completion-reward"].label, "+30 XP")
    }

    func testLargestTextStaticWrongFeedbackAndRouterQuestionRemainReadable() {
        app.launchArguments += ["--test-accessibility"]
        start()
        answerBlank("wlan")
        tap("practice-option-bluetooth")
        tap("primary-action")
        XCTAssertEqual(app.staticTexts["practice-result"].label, "这题答错了")
        XCTAssertTrue(app.buttons["primary-action"].isHittable)
        picture("Q02-largest-text-wrong-feedback")
        tap("primary-action")
        answerBlank("wired")
        XCTAssertTrue(app.buttons["practice-option-router"].waitForExistence(timeout: 5))
        picture("Q04-largest-text-router-question", footerTitle: "检查")
        answerBlank("router")
        XCTAssertTrue(app.buttons["practice-option-ont"].waitForExistence(timeout: 5))
    }

    func testCancelExitKeepsFilledAnswerAndConfirmedExitRestartsOnlyDraft() {
        start()
        answerBlank("wlan")
        tap("practice-option-wifi")
        tap("exit-lesson")
        XCTAssertTrue(app.buttons["取消"].waitForExistence(timeout: 5))
        app.buttons["取消"].tap()
        XCTAssertEqual(app.buttons["practice-blank"].label, "已填入Wi-Fi，点按撤回")
        tap("exit-lesson")
        app.buttons["确定退出"].tap()
        XCTAssertEqual(app.staticTexts["xp-badge"].label, "0 经验值")
        tap("start-lesson")
        XCTAssertTrue(app.buttons["practice-option-wlan"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["practice-blank"].label, "空位")
    }

    func testFeedbackKeepsOptionsInPlaceAndUserCanScrollToRevealThem() {
        start()
        let option = app.buttons["practice-option-wired-lan"]
        let original = option.frame
        tap("practice-option-wired-lan")
        // Let the word travel to the blank before measuring submission layout.
        let wordSettled = NSPredicate { _, _ in abs(option.frame.minY - original.minY) < 1 }
        expectation(for: wordSettled, evaluatedWith: option)
        waitForExpectations(timeout: 5)
        picture("Stable-fill-before-check")
        tap("primary-action")
        XCTAssertTrue(app.staticTexts["practice-result"].waitForExistence(timeout: 5))
        XCTAssertEqual(option.frame.minY, original.minY, accuracy: 1)
        picture("Stable-fill-after-feedback")
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertLessThan(option.frame.minY, original.minY - 20)
        XCTAssertTrue(app.buttons["primary-action"].isHittable)
        picture("Stable-fill-user-scroll")
        tap("primary-action")
        answerBlank("wifi")
        answerBlank("wired")
        answerBlank("router")
        answerBlank("ont")
        answerBlank("service")
        let yes = app.buttons["practice-option-yes"].frame
        let no = app.buttons["practice-option-no"].frame
        tap("practice-option-yes")
        XCTAssertTrue(app.staticTexts["practice-result"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["practice-option-yes"].frame.minY, yes.minY, accuracy: 1)
        XCTAssertEqual(app.buttons["practice-option-no"].frame.minY, no.minY, accuracy: 1)
        XCTAssertEqual(app.staticTexts["practice-result"].label, "看看答案")
    }
}
