import XCTest
@testable import WangGanCore

final class AnswerExplanationTests: XCTestCase {
    private func homeLesson() throws -> Lesson {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let catalog = try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
        try catalog.validate()
        return try XCTUnwrap(catalog.lessons.first { $0.id == "home-two-boxes" })
    }

    private func solvedDraft(_ lesson: Lesson) -> LessonSession {
        var draft = LessonSession(lessonID: lesson.id)
        draft.stage = .challenge
        draft.answerSubmitted = true
        draft.selectedAnswer = lesson.question.correctID
        draft.matchingSubmitted = true
        draft.matchingSolved = true
        draft.challengeAnswer = lesson.challenge.correctID
        draft.challengeSubmitted = true
        draft.challengeSolved = true
        draft.mistakes = 2
        return draft
    }

    func testAnswerExplanationMustFinishBeforeCompletionAndAwardOnlyOnce() throws {
        let lesson = try homeLesson()
        let plan = LessonPlan(lesson: lesson)
        let pages = try XCTUnwrap(lesson.challenge.answerExplanation)
        var session = StepSession(lesson: lesson, from: solvedDraft(lesson))
        var legacy = solvedDraft(lesson)
        var ledger = ProgressLedger()
        for page in pages {
            plan.advance(&session)
            legacy.advance(lesson: lesson)
            XCTAssertEqual(legacy.challengeExplanationID, page.id)
            XCTAssertEqual(legacy.stage, .challenge)
            XCTAssertEqual(plan.answerExplanation(at: session.stepIndex)?.id, page.id)
            XCTAssertFalse(plan.isComplete(session))
            XCTAssertEqual(session.stageSession(lesson: lesson).stage, .challenge)
            XCTAssertEqual(ledger.complete(session.stageSession(lesson: lesson)), 0)
            XCTAssertTrue(ledger.lessons.isEmpty)
        }
        plan.advance(&session)
        legacy.advance(lesson: lesson)
        XCTAssertEqual(legacy.stage, .complete)
        XCTAssertTrue(plan.isComplete(session))
        let completed = session.stageSession(lesson: lesson)
        XCTAssertEqual(completed.stage, .complete)
        XCTAssertNil(completed.challengeExplanationID)
        XCTAssertEqual(ledger.complete(completed), 30)
        XCTAssertEqual(ledger.complete(completed), 30, "Repeated settlement returns its recorded reward")
        XCTAssertEqual(ledger.totalXP, 30)
    }

    func testEachPageRoundTripsThroughPersistedDraftWithoutResettingAnswer() throws {
        let lesson = try homeLesson()
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lesson: lesson, from: solvedDraft(lesson))
        for page in lesson.challenge.answerExplanation ?? [] {
            plan.advance(&session)
            let data = try JSONEncoder().encode(session.stageSession(lesson: lesson))
            let saved = try JSONDecoder().decode(LessonSession.self, from: data)
            let restored = StepSession(lesson: lesson, from: saved)
            XCTAssertEqual(restored, session)
            XCTAssertEqual(saved.challengeExplanationID, page.id)
            XCTAssertEqual(restored.mistakes, 2)
            XCTAssertTrue(restored.challengeSolved)
        }
    }

    func testOldDraftAndOldCompletionDoNotLosePositionIdentityOrHistory() throws {
        let lesson = try homeLesson()
        let plan = LessonPlan(lesson: lesson)
        let old = solvedDraft(lesson)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
        json.removeValue(forKey: "challengeExplanationID")
        let saved = try JSONDecoder().decode(LessonSession.self, from: JSONSerialization.data(withJSONObject: json))
        let restored = StepSession(lesson: lesson, from: saved)
        XCTAssertEqual(restored.id, old.id)
        XCTAssertEqual(restored.stepIndex, plan.challengeIndex)
        XCTAssertTrue(restored.challengeSolved)
        var completed = saved
        completed.stage = .complete
        let oldCompletion = StepSession(lesson: lesson, from: completed)
        XCTAssertTrue(plan.isComplete(oldCompletion), "New reading must not reopen completed courses")
        XCTAssertEqual(oldCompletion.id, completed.id)
    }

    func testUnsolvedAnswerCannotEnterOrAdvancePostAnswerReading() throws {
        let lesson = try homeLesson()
        let plan = LessonPlan(lesson: lesson)
        var old = solvedDraft(lesson)
        old.challengeSolved = false
        old.challengeExplanationID = lesson.challenge.answerExplanation?.last?.id
        var session = StepSession(lesson: lesson, from: old)
        XCTAssertEqual(session.stepIndex, plan.challengeIndex)
        plan.advance(&session)
        XCTAssertEqual(session.stepIndex, plan.challengeIndex)
        session.stepIndex += 1
        XCTAssertFalse(plan.canAdvance(session))
        XCTAssertFalse(plan.isComplete(session))
    }

    func testDiagramRejectsDuplicateConnectorsAndOpticalBranchesWithoutDownstreamPort() {
        let power = DevicePortConnection(id: "power", label: "电源口", medium: .power, destination: "电源")
        let fiber = DevicePortConnection(id: "pon", label: "光纤口", medium: .fiber, destination: "入户光纤")
        XCTAssertTrue(DevicePortsSpec(title: "一体机", ports: [power, fiber], fiberRooms: nil, note: "示意").isValid)
        XCTAssertFalse(DevicePortsSpec(title: "一体机", ports: [power, power, fiber], fiberRooms: nil, note: "示意").isValid)
        XCTAssertFalse(DevicePortsSpec(title: "FTTR", ports: [power, fiber], fiberRooms: ["房间一"], note: "示意").isValid)
    }
}
