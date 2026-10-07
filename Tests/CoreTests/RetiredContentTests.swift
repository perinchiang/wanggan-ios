import XCTest
@testable import WangGanCore

final class RetiredContentTests: XCTestCase {
    private func finish(_ id: String) -> LessonSession {
        var session = LessonSession(lessonID: id)
        session.stage = .complete
        session.matchingSolved = true
        session.challengeSolved = true
        return session
    }

    func testOldV1DraftSurvivesContentRemovalAndRepeatedLaunch() throws {
        // Original v1 shape: no optional draft collections or new visual fields.
        let data = #"{"schemaVersion":1,"totalXP":30,"lessons":{"gateway":{"completedAt":812721600,"lastPracticedAt":812721600,"nextReviewAt":812764800,"reviewLevel":0,"lastMistakes":0}},"activityDays":[812678400],"settledSessions":[],"draft":{"id":"00000000-0000-0000-0000-000000000001","lessonID":"subnet","stage":1,"explanationIndex":1,"answerSubmitted":true,"matches":{},"matchingSubmitted":false,"matchingSolved":false,"challengeSubmitted":false,"challengeSolved":false,"mistakes":1}}"#
        var ledger = try JSONDecoder().decode(ProgressLedger.self, from: Data(data.utf8))
        let original = ledger
        let ids = try TestCatalog.shipped().orderedLessonIDs
        ledger.normalizeDrafts(in: ids)
        ledger = try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger))
        ledger.normalizeDrafts(in: ids)
        XCTAssertEqual(ledger, original)
        XCTAssertEqual(ledger.recommendedLessonID(in: ids), "home-two-boxes")
        XCTAssertFalse(ledger.isUnlocked("subnet", in: ids))
        XCTAssertFalse(ledger.isUnlocked("gateway", in: ids))
    }

    func testStartingExampleParksRetiredMainDraftWithoutLosingHistory() throws {
        let ids = try TestCatalog.shipped().orderedLessonIDs
        var ledger = ProgressLedger()
        let oldCompletion = finish("gateway")
        ledger.complete(oldCompletion)
        var main = LessonSession(lessonID: "subnet")
        main.stage = .explanation
        main.ipv4VisualPhase = 1
        main.ipv4SelectedOctet = 3
        ledger.saveDraft(main, in: ["gateway", "subnet"])
        let historicalLessons = ledger.lessons
        let example = LessonSession(lessonID: "home-two-boxes")
        ledger.normalizeDrafts(in: ids)
        ledger.saveDraft(example, in: ids)
        var restored = try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger))
        restored.normalizeDrafts(in: ids)
        XCTAssertEqual(restored.draft, example)
        XCTAssertEqual(restored.drafts[main.lessonID], main)
        XCTAssertEqual(restored.lessons, historicalLessons)
        XCTAssertEqual(restored.totalXP, 30)
        XCTAssertEqual(restored.settledSessions, ledger.settledSessions)
        let completion = finish(example.lessonID)
        XCTAssertEqual(restored.complete(completion), 30)
        XCTAssertEqual(restored.complete(completion), 30)
        XCTAssertEqual(restored.complete(oldCompletion), 30)
        XCTAssertEqual(restored.totalXP, 60)
        XCTAssertEqual(restored.drafts[main.lessonID], main)
        XCTAssertEqual(restored.lessons["gateway"], historicalLessons["gateway"])
    }

}
