import XCTest
@testable import WangGanCore

final class SubnetMaskTests: XCTestCase {
    private func catalog() throws -> LessonCatalog {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
    }

    private var configuration: SubnetMaskIntroduction {
        SubnetMaskIntroduction(ip: "10.20.30.40", initialPrefix: 24, alternatePrefix: 16, practicePrefix: 8)
    }

    private func observed() -> SubnetMaskProgress {
        var progress = SubnetMaskProgress()
        progress.advance()
        progress.inspect(3, configuration: configuration)
        progress.inspect(4, configuration: configuration)
        progress.advance()
        progress.toggleCondition()
        progress.advance()
        return progress
    }

    func testMaskMathCoversEdgesAndNonByteBoundary() throws {
        XCTAssertEqual(PrefixMask(prefix: 0)?.decimal, "0.0.0.0")
        XCTAssertEqual(PrefixMask(prefix: 8)?.decimal, "255.0.0.0")
        XCTAssertEqual(PrefixMask(prefix: 16)?.decimal, "255.255.0.0")
        XCTAssertEqual(PrefixMask(prefix: 24)?.decimal, "255.255.255.0")
        XCTAssertEqual(PrefixMask(prefix: 26)?.decimal, "255.255.255.192")
        XCTAssertEqual(PrefixMask(prefix: 26)?.binaryOctet(4), "11000000")
        XCTAssertEqual(PrefixMask(prefix: 32)?.decimal, "255.255.255.255")
        XCTAssertEqual(PrefixMask(prefix: 26)?.hostBitCount, 6)
        XCTAssertNil(PrefixMask(prefix: -1))
        XCTAssertNil(PrefixMask(prefix: 33))
    }

    func testPilotAcceptsDifferentConfigurationsAndRejectsUnsupportedRanges() throws {
        XCTAssertTrue(configuration.isValid)
        let other = SubnetMaskIntroduction(ip: "172.18.3.9", initialPrefix: 16, alternatePrefix: 8, practicePrefix: 24)
        XCTAssertTrue(other.isValid)
        var progress = SubnetMaskProgress()
        progress.advance()
        progress.inspect(1, configuration: other)
        progress.inspect(3, configuration: other)
        progress.advance()
        progress.toggleCondition()
        XCTAssertEqual(other.prefix(for: progress), 8)
        progress.advance()
        progress.selectBoundary(3)
        XCTAssertEqual(progress.submitBoundary(configuration: other), true)
        for invalid in [
            SubnetMaskIntroduction(ip: "256.1.2.3", initialPrefix: 24, alternatePrefix: 16, practicePrefix: 8),
            SubnetMaskIntroduction(ip: "10.20.30.40", initialPrefix: 24, alternatePrefix: 24, practicePrefix: 8),
            SubnetMaskIntroduction(ip: "10.20.30.40", initialPrefix: 24, alternatePrefix: 26, practicePrefix: 8)
        ] { XCTAssertFalse(invalid.isValid) }
    }

    func testObservationGatesRejectOutOfStageActionsAndPreserveEvidence() throws {
        var progress = SubnetMaskProgress()
        progress.inspect(1, configuration: configuration)
        progress.toggleCondition()
        progress.selectBoundary(1)
        XCTAssertNil(progress.focusedOctet)
        XCTAssertNil(progress.selectedBoundary)
        XCTAssertFalse(progress.switchedCondition)
        progress.advance()
        progress.inspect(0, configuration: configuration)
        progress.inspect(5, configuration: configuration)
        progress.inspect(1, configuration: configuration)
        progress.advance()
        XCTAssertEqual(progress.stage, 1, "Both roles must be inspected")
        progress.inspect(4, configuration: configuration)
        progress.advance()
        progress.advance()
        XCTAssertEqual(progress.stage, 2, "Changing the condition is required")
        progress.toggleCondition()
        progress.previous()
        XCTAssertTrue(progress.inspectedNetwork)
        XCTAssertTrue(progress.inspectedHost)
        progress.advance()
        XCTAssertTrue(progress.usesAlternate)
        progress.advance()
        XCTAssertEqual(progress.highestStage, 3)
    }

    func testBoundaryRetryAndRepeatedSubmissionCannotCompleteOrCountTwice() throws {
        var progress = observed()
        XCTAssertNil(progress.submitBoundary(configuration: configuration))
        progress.selectBoundary(3)
        XCTAssertEqual(progress.submitBoundary(configuration: configuration), false)
        XCTAssertNil(progress.submitBoundary(configuration: configuration))
        progress.advance()
        XCTAssertFalse(progress.finished)
        progress.previous()
        progress.advance()
        XCTAssertEqual(progress.selectedBoundary, 3)
        XCTAssertTrue(progress.boundarySubmitted)
        progress.selectBoundary(1)
        XCTAssertFalse(progress.boundarySubmitted)
        XCTAssertEqual(progress.submitBoundary(configuration: configuration), true)
        progress.advance()
        progress.previous()
        progress.previous()
        XCTAssertTrue(progress.finished)
        XCTAssertTrue(progress.boundarySolved)
        XCTAssertEqual(progress.highestStage, 3)
    }

    func testEveryObservationAndWrongSubmissionRoundTripsWithOriginalAnswers() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "subnet-mask" })
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lessonID: lesson.id)
        for _ in 0..<plan.questionSceneCount { plan.advance(&session) }
        plan.submitAnswer("three", in: &session)
        plan.advance(&session)
        XCTAssertFalse(plan.canAdvance(session))
        var progress = SubnetMaskProgress()
        for stage in 0...3 {
            if stage == 1 {
                progress.inspect(2, configuration: configuration)
                progress.inspect(4, configuration: configuration)
            }
            if stage == 2 { progress.toggleCondition() }
            if stage == 3 {
                progress.selectBoundary(2)
                XCTAssertEqual(progress.submitBoundary(configuration: configuration), false)
                session.mistakes += 1
            }
            session.subnetMaskProgress = progress
            let saved = session.stageSession(lesson: lesson)
            let decoded = try JSONDecoder().decode(LessonSession.self, from: JSONEncoder().encode(saved))
            XCTAssertEqual(StepSession(lesson: lesson, from: decoded), session)
            XCTAssertEqual(session.selectedAnswer, "three")
            XCTAssertFalse(plan.canAdvance(session))
            if stage < 3 { progress.advance() }
        }
        progress.selectBoundary(1)
        XCTAssertEqual(progress.submitBoundary(configuration: configuration), true)
        progress.advance()
        session.subnetMaskProgress = progress
        plan.advance(&session)
        XCTAssertEqual(session.stepIndex, plan.matchingIndex)
        XCTAssertEqual(session.mistakes, 2)
        for (left, right) in lesson.matching.solution { plan.connect(left, to: right, in: &session) }
        plan.submitMatching(in: &session)
        plan.advance(&session)
        for _ in 0..<plan.challengeSceneCount { plan.advance(&session) }
        plan.submitChallenge("three", in: &session)
        XCTAssertFalse(plan.canAdvance(session))
        plan.retryChallenge(in: &session)
        plan.submitChallenge(lesson.challenge.correctID, in: &session)
        plan.advance(&session)
        var ledger = ProgressLedger()
        let finished = session.stageSession(lesson: lesson)
        XCTAssertEqual(ledger.complete(finished), 30)
        ledger.complete(finished)
        XCTAssertEqual(ledger.totalXP, 30)
    }

    func testAddingMaskLessonProtectsOlderMainReviewAndCompletedHistory() throws {
        let ids = try catalog().orderedLessonIDs
        let json = #"{"schemaVersion":1,"totalXP":30,"lessons":{"gateway":{"completedAt":812721600,"lastPracticedAt":812721600,"nextReviewAt":812764800,"reviewLevel":0,"lastMistakes":0}},"activityDays":[812678400],"settledSessions":[],"draft":{"id":"00000000-0000-0000-0000-000000000001","lessonID":"subnet","stage":1,"explanationIndex":0,"answerSubmitted":true,"matches":{},"matchingSubmitted":false,"matchingSolved":false,"challengeSubmitted":false,"challengeSolved":false,"mistakes":1}}"#
        var ledger = try JSONDecoder().decode(ProgressLedger.self, from: Data(json.utf8))
        let main = try XCTUnwrap(ledger.draft)
        XCTAssertNil(main.subnetMaskProgress)
        let history = ledger.lessons
        ledger.normalizeDrafts(in: ids)
        var review = LessonSession(lessonID: "gateway")
        review.questionSceneStep = 1
        ledger.saveDraft(review, in: ids)
        var earlier = LessonSession(lessonID: "subnet-mask")
        earlier.stage = .explanation
        earlier.subnetMaskProgress = observed()
        ledger.saveDraft(earlier, in: ids)
        var restored = try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger))
        restored.normalizeDrafts(in: ids)
        XCTAssertEqual(restored.session(for: "subnet"), main)
        XCTAssertEqual(restored.session(for: "gateway"), review)
        XCTAssertEqual(restored.session(for: "subnet-mask"), earlier)
        XCTAssertEqual(restored.recommendedLessonID(in: ids), "subnet")
        XCTAssertEqual(restored.lessons, history)
        XCTAssertEqual(restored.totalXP, 30)
        XCTAssertTrue(restored.isUnlocked("gateway", in: ids))
    }

    func testCatalogRejectsConflictingOrUnsupportedPilotPayload() throws {
        let content = try catalog()
        try content.validate()
        var data = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(content)) as? [String: Any])
        var lessons = try XCTUnwrap(data["lessons"] as? [[String: Any]])
        let index = try XCTUnwrap(lessons.firstIndex { $0["id"] as? String == "subnet-mask" })
        lessons[index]["subnetMaskIntroduction"] = ["ip": "10.20.30.40", "initialPrefix": 24, "alternatePrefix": 26, "practicePrefix": 8]
        data["lessons"] = lessons
        let invalid = try JSONDecoder().decode(LessonCatalog.self, from: JSONSerialization.data(withJSONObject: data))
        XCTAssertThrowsError(try invalid.validate())
    }
}
