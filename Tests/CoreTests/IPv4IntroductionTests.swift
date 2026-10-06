import XCTest
@testable import WangGanCore

final class IPv4IntroductionTests: XCTestCase {
    private func catalog() throws -> LessonCatalog {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
    }

    private func finished(_ id: String) -> LessonSession {
        var session = LessonSession(lessonID: id)
        session.stage = .complete
        session.matchingSolved = true
        session.challengeSolved = true
        return session
    }

    func testObservationGatesAndBacktrackingPreserveEvidence() throws {
        var progress = IPv4IntroductionProgress()
        progress.previous()
        progress.advance()
        progress.selectOctet(0)
        progress.selectOctet(5)
        progress.toggleRange()
        XCTAssertFalse(progress.canAdvance)
        XCTAssertFalse(progress.inspectedRange)
        progress.selectOctet(4)
        progress.advance()
        progress.selectOctet(2)
        XCTAssertEqual(progress.selectedOctet, 4, "Only the selection step accepts a byte selection")
        progress.advance()
        XCTAssertEqual(progress.stage, 2)
        progress.advance()
        XCTAssertEqual(progress.stage, 2, "Observe both endpoints before moving on")
        progress.toggleRange()
        XCTAssertEqual(progress.rangeValue, 255)
        progress.advance()
        progress.advance()
        XCTAssertTrue(progress.finished)
        progress.previous()
        progress.previous()
        progress.previous()
        XCTAssertEqual(progress.stage, 0)
        XCTAssertEqual(progress.highestStage, 3)
        XCTAssertTrue(progress.finished)
        XCTAssertTrue(progress.inspectedRange)
        XCTAssertEqual(progress.selectedOctet, 4)
        let restored = try JSONDecoder().decode(IPv4IntroductionProgress.self, from: JSONEncoder().encode(progress))
        XCTAssertEqual(restored, progress)
    }

    func testIntroductionResumesEveryObservationAndCompletesOnlyOnce() throws {
        let content = try catalog()
        try content.validate()
        let lesson = try XCTUnwrap(content.lessons.first { $0.id == "ipv4-address" })
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lessonID: lesson.id)
        for _ in 0..<plan.questionSceneCount { plan.advance(&session) }
        plan.submitAnswer("devices", in: &session)
        plan.advance(&session)
        XCTAssertFalse(plan.canAdvance(session))
        var observation = IPv4IntroductionProgress()
        observation.selectOctet(3)
        for stage in 0...3 {
            if stage == 2 { observation.toggleRange() }
            session.ipv4IntroductionProgress = observation
            let draft = session.stageSession(lesson: lesson)
            let restored = try JSONDecoder().decode(LessonSession.self, from: JSONEncoder().encode(draft))
            XCTAssertEqual(StepSession(lesson: lesson, from: restored), session)
            XCTAssertEqual(session.mistakes, 1)
            XCTAssertFalse(plan.canAdvance(session))
            observation.advance()
        }
        session.ipv4IntroductionProgress = observation
        plan.advance(&session)
        XCTAssertEqual(session.stepIndex, plan.matchingIndex)
        for (left, right) in lesson.matching.solution { plan.connect(left, to: right, in: &session) }
        plan.submitMatching(in: &session)
        plan.advance(&session)
        for _ in 0..<plan.challengeSceneCount { plan.advance(&session) }
        plan.submitChallenge("four", in: &session)
        XCTAssertFalse(plan.canAdvance(session))
        plan.retryChallenge(in: &session)
        plan.submitChallenge(lesson.challenge.correctID, in: &session)
        plan.advance(&session)
        XCTAssertTrue(plan.isComplete(session))
        var ledger = ProgressLedger()
        let completed = session.stageSession(lesson: lesson)
        XCTAssertEqual(ledger.complete(completed), 30)
        ledger.complete(completed)
        XCTAssertEqual(ledger.totalXP, 30)
        // Completing an archived pilot must not move the main-route frontier.
        XCTAssertEqual(ledger.recommendedLessonID(in: content.orderedLessonIDs),
                       try XCTUnwrap(content.orderedLessonIDs.first))
    }

    func testInsertedLessonKeepsOldMainAndIndependentEarlierDraftAfterRelaunch() throws {
        let ids = try catalog().allLessonIDs
        var ledger = ProgressLedger()
        ledger.complete(finished("gateway"))
        let oldProgress = ledger.lessons
        var main = LessonSession(lessonID: "subnet")
        main.stage = .explanation
        main.ipv4VisualPhase = 1
        main.ipv4SelectedOctet = 3
        ledger.saveDraft(main, in: ids)
        var earlier = LessonSession(lessonID: "ipv4-address")
        earlier.stage = .explanation
        var observation = IPv4IntroductionProgress()
        observation.selectOctet(2)
        observation.advance()
        earlier.ipv4IntroductionProgress = observation
        ledger.saveDraft(earlier, in: ids)
        var restored = try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger))
        restored.normalizeDrafts(in: ids)
        XCTAssertEqual(restored.recommendedLessonID(in: try catalog().orderedLessonIDs), "subnet")
        XCTAssertEqual(restored.session(for: "subnet"), main)
        XCTAssertEqual(restored.session(for: "ipv4-address"), earlier)
        XCTAssertEqual(restored.lessons, oldProgress)
        XCTAssertEqual(restored.totalXP, 30)
        earlier.stage = .complete
        earlier.matchingSolved = true
        earlier.challengeSolved = true
        restored.complete(earlier)
        XCTAssertEqual(restored.session(for: "subnet"), main)
        XCTAssertEqual(restored.recommendedLessonID(in: try catalog().orderedLessonIDs), "subnet")
        XCTAssertEqual(restored.totalXP, 60)
        XCTAssertNil(restored.earlierDrafts?["ipv4-address"])
    }

    func testSwitchingFromInsertedLessonToOldUnlockedLessonKeepsBothDrafts() throws {
        let ids = try catalog().allLessonIDs
        var ledger = ProgressLedger()
        ledger.complete(finished("gateway"))
        var earlier = LessonSession(lessonID: "ipv4-address")
        earlier.questionSceneStep = 1
        ledger.saveDraft(earlier, in: ids)
        let main = LessonSession(lessonID: "subnet")
        ledger.saveDraft(main, in: ids)
        XCTAssertEqual(ledger.session(for: "ipv4-address"), earlier)
        XCTAssertEqual(ledger.session(for: "subnet"), main)
    }

    func testRealLegacyFormatRetainsUnlockedMainDraftWithoutNewFields() throws {
        let json = #"{"schemaVersion":1,"totalXP":0,"lessons":{},"activityDays":[],"settledSessions":[],"draft":{"id":"00000000-0000-0000-0000-000000000001","lessonID":"gateway","stage":0,"explanationIndex":0,"answerSubmitted":false,"matches":{},"matchingSubmitted":false,"matchingSolved":false,"challengeSubmitted":false,"challengeSolved":false,"mistakes":0}}"#
        var ledger = try JSONDecoder().decode(ProgressLedger.self, from: Data(json.utf8))
        let ids = try catalog().allLessonIDs
        ledger.normalizeDrafts(in: ids)
        XCTAssertEqual(ledger.recommendedLessonID(in: try catalog().orderedLessonIDs), "gateway")
        XCTAssertTrue(ledger.isUnlocked("gateway", in: try catalog().orderedLessonIDs))
        XCTAssertNil(ledger.earlierDrafts)
        XCTAssertNil(ledger.draft?.ipv4IntroductionProgress)
        // A fresh ledger recommends the first lesson of the active route.
        XCTAssertEqual(ProgressLedger().recommendedLessonID(in: try catalog().orderedLessonIDs),
                       try XCTUnwrap(try catalog().orderedLessonIDs.first))
    }
}
