import XCTest
@testable import WangGanCore

final class ShortReviewTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return value
    }
    private var today: Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 12))! }
    private func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today)! }

    private func catalog() throws -> LessonCatalog {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
    }
    private func completed(_ id: String = "gateway") -> LessonSession {
        var session = LessonSession(lessonID: id)
        session.stage = .complete
        session.matchingSolved = true
        session.challengeSolved = true
        return session
    }
    private func correct(_ item: ReviewItem, at date: Date) -> ShortReviewSession {
        var session = ShortReviewSession(item: item)
        session.select(item.correctID, item: item)
        session.submit(item: item, now: date, calendar: calendar)
        return session
    }

    func testLockedOrUnansweredReviewCannotAwardOrUnlock() throws {
        let items = try XCTUnwrap(catalog().reviewItems)
        var ledger = ProgressLedger()
        XCTAssertNil(ledger.shortSession(for: "gateway", items: items))
        let solved = correct(items[0], at: today)
        XCTAssertEqual(ledger.completeShortReview(solved, items: items, now: today, calendar: calendar), 0)
        XCTAssertTrue(ledger.lessons.isEmpty)
        ledger.complete(completed(), now: today, calendar: calendar)
        XCTAssertEqual(ledger.completeShortReview(ShortReviewSession(item: items[0]), items: items, now: day(1), calendar: calendar), 0)
        XCTAssertEqual(ledger.totalXP, 30)
    }

    func testShortAndFullReviewsShareDailyRewardAndSettlementIsIdempotent() throws {
        let items = try XCTUnwrap(catalog().reviewItems)
        var ledger = ProgressLedger()
        ledger.complete(completed(), now: today, calendar: calendar)
        XCTAssertEqual(ledger.completeShortReview(correct(items[0], at: today), items: items, now: today, calendar: calendar), 0)
        let session = correct(items[1], at: day(1))
        XCTAssertEqual(ledger.completeShortReview(session, items: items, now: day(1), calendar: calendar), 5)
        XCTAssertEqual(ledger.completeShortReview(session, items: items, now: day(1), calendar: calendar), 5)
        XCTAssertEqual(ledger.complete(completed(), now: day(1), calendar: calendar), 0)
        XCTAssertEqual(ledger.completeShortReview(correct(items[0], at: day(1)), items: items, now: day(1), calendar: calendar), 0)
        XCTAssertEqual(ledger.totalXP, 35)
        XCTAssertEqual(ledger.lessons["gateway"]?.reviewLevel, 1)
        XCTAssertEqual(ledger.activityDays.count, 2)
    }

    func testWrongSubmissionImmediatelyUpdatesEvidenceWithoutRewardAndRetryIsAssisted() throws {
        let items = try XCTUnwrap(catalog().reviewItems)
        var ledger = ProgressLedger()
        ledger.complete(completed(), now: today, calendar: calendar)
        ledger.complete(completed(), now: day(1), calendar: calendar)
        var session = ShortReviewSession(item: items[0])
        session.select("all-fail", item: items[0])
        XCTAssertNotNil(session.submit(item: items[0], now: day(1), calendar: calendar))
        XCTAssertNil(session.submit(item: items[0], now: day(1), calendar: calendar))
        ledger.saveShortDraft(session, items: items, calendar: calendar)
        ledger.saveShortDraft(session, items: items, calendar: calendar)
        XCTAssertEqual(ledger.reviewEvidence?.count, 1)
        XCTAssertEqual(ledger.evidenceStatus(for: items[0].knowledgePointID), .needsPractice)
        XCTAssertEqual(ledger.lessons["gateway"]?.reviewLevel, 0)
        XCTAssertEqual(ledger.lessons["gateway"]?.nextReviewAt, calendar.startOfDay(for: day(2)))
        XCTAssertEqual(ledger.totalXP, 35)
        session.retry()
        session.select(items[0].correctID, item: items[0])
        session.submit(item: items[0], now: day(1), calendar: calendar)
        XCTAssertFalse(session.independent)
        XCTAssertEqual(ledger.completeShortReview(session, items: items, now: day(1), calendar: calendar), 0)
        XCTAssertEqual(ledger.evidenceStatus(for: items[0].knowledgePointID), .building)
        XCTAssertEqual(ledger.reviewEvidence?.count, 2)
    }

    func testHintedCorrectCannotLengthenReviewInterval() throws {
        let items = try XCTUnwrap(catalog().reviewItems)
        var ledger = ProgressLedger()
        ledger.complete(completed(), now: today, calendar: calendar)
        var session = ShortReviewSession(item: items[0])
        session.usedHint = true
        session.select(items[0].correctID, item: items[0])
        session.submit(item: items[0], now: day(1), calendar: calendar)
        XCTAssertEqual(ledger.completeShortReview(session, items: items, now: day(1), calendar: calendar), 5)
        XCTAssertEqual(ledger.evidenceStatus(for: items[0].knowledgePointID), .building)
        XCTAssertEqual(ledger.lessons["gateway"]?.reviewLevel, 0)
        XCTAssertEqual(ledger.lessons["gateway"]?.nextReviewAt, calendar.startOfDay(for: day(2)))
    }

    func testAbandonedWrongReviewThenSameDayIndependentCorrectKeepsShortInterval() throws {
        let items = try XCTUnwrap(catalog().reviewItems)
        var ledger = ProgressLedger()
        ledger.complete(completed(), now: today, calendar: calendar)
        var wrong = ShortReviewSession(item: items[0])
        wrong.select("all-fail", item: items[0])
        wrong.submit(item: items[0], now: day(1), calendar: calendar)
        ledger.saveShortDraft(wrong, items: items, calendar: calendar)
        ledger.completeShortReview(correct(items[1], at: day(1)), items: items, now: day(1), calendar: calendar)
        XCTAssertEqual(ledger.totalXP, 35)
        XCTAssertEqual(ledger.lessons["gateway"]?.reviewLevel, 0)
        XCTAssertEqual(ledger.lessons["gateway"]?.nextReviewAt, calendar.startOfDay(for: day(2)))
    }

    func testDelayedEvidenceNeedsIndependentCorrectDifferentSceneAndAtLeastADay() throws {
        let items = try XCTUnwrap(catalog().reviewItems)
        let first = try XCTUnwrap(correct(items[0], at: today).attempts.first)
        let repeated = try XCTUnwrap(correct(items[0], at: day(2)).attempts.first)
        let sameDay = try XCTUnwrap(correct(items[1], at: today.addingTimeInterval(3600)).attempts.first)
        let afterMidnight = try XCTUnwrap(correct(items[1], at: calendar.date(byAdding: .hour, value: 13, to: today)!).attempts.first)
        let delayed = try XCTUnwrap(correct(items[1], at: day(2)).attempts.first)
        XCTAssertEqual(ReviewEvidenceStatus.summarize([first, repeated], calendar: calendar), .independent)
        XCTAssertEqual(ReviewEvidenceStatus.summarize([first, sameDay], calendar: calendar), .independent)
        XCTAssertEqual(ReviewEvidenceStatus.summarize([first, afterMidnight], calendar: calendar), .independent)
        XCTAssertEqual(ReviewEvidenceStatus.summarize([first, delayed], calendar: calendar), .delayed)
    }

    func testShortDraftResumeDoesNotOverwriteMainOrFullReviewDraftAndRotatesAfterFinish() throws {
        let content = try catalog()
        let items = try XCTUnwrap(content.reviewItems)
        var ledger = ProgressLedger()
        ledger.complete(completed(), now: today, calendar: calendar)
        var main = LessonSession(lessonID: "subnet")
        main.stage = .explanation
        ledger.saveDraft(main, in: content.orderedLessonIDs)
        let full = LessonSession(lessonID: "gateway")
        ledger.saveDraft(full, in: content.orderedLessonIDs)
        var short = try XCTUnwrap(ledger.shortSession(for: "gateway", items: items))
        short.usedHint = true
        short.select("all-fail", item: items[0])
        ledger.saveShortDraft(short, items: items)
        var restored = try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger))
        XCTAssertEqual(restored.shortSession(for: "gateway", items: items), short)
        XCTAssertEqual(restored.draft, main)
        XCTAssertEqual(restored.reviewDrafts?["gateway"], full)
        short.select("local", item: items[0])
        short.submit(item: items[0], now: today, calendar: calendar)
        restored.completeShortReview(short, items: items, now: today, calendar: calendar)
        restored.saveShortDraft(short, items: items)
        XCTAssertNil(restored.shortReviewDrafts?["gateway"])
        XCTAssertEqual(restored.shortSession(for: "gateway", items: items)?.itemID, items[1].id)
        XCTAssertEqual(restored.draft, main)
        XCTAssertEqual(restored.reviewDrafts?["gateway"], full)
        XCTAssertEqual(restored.recommendedLessonID(in: content.orderedLessonIDs), "subnet")
    }

    func testOldV1LedgerDecodesWithoutInventingMasteryOrLosingHistory() throws {
        // Literal original format, without any short-review fields.
        let old = """
        {"schemaVersion":1,"totalXP":30,"lessons":{"gateway":{"completedAt":812721600,"lastPracticedAt":812721600,"nextReviewAt":812764800,"reviewLevel":0,"lastMistakes":0}},"activityDays":[812678400],"settledSessions":[]}
        """
        var ledger = try JSONDecoder().decode(ProgressLedger.self, from: Data(old.utf8))
        ledger.normalizeDrafts(in: try catalog().orderedLessonIDs)
        XCTAssertEqual(ledger.totalXP, 30)
        XCTAssertNotNil(ledger.lessons["gateway"])
        XCTAssertEqual(ledger.activityDays.count, 1)
        XCTAssertNil(ledger.shortReviewDrafts)
        XCTAssertNil(ledger.reviewEvidence)
        XCTAssertEqual(ledger.evidenceStatus(for: "ipv4.local-vs-gateway"), .none)
        XCTAssertEqual(try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger)), ledger)
    }

    func testRevisedItemCannotSilentlyReuseOldAnswerOrReward() throws {
        let items = try XCTUnwrap(catalog().reviewItems)
        var session = correct(items[0], at: today)
        let changed = ReviewItem(id: items[0].id, revision: 2, lessonID: items[0].lessonID,
                                 knowledgePointID: items[0].knowledgePointID, objective: items[0].objective,
                                 scenarioFamilyID: items[0].scenarioFamilyID, scene: items[0].scene,
                                 prompt: items[0].prompt, options: items[0].options, correctID: "all-fail",
                                 hint: items[0].hint, explanation: items[0].explanation)
        XCTAssertNil(session.submit(item: changed))
        var ledger = ProgressLedger()
        ledger.complete(completed(), now: today, calendar: calendar)
        ledger.saveShortDraft(session, items: items)
        XCTAssertEqual(ledger.completeShortReview(session, items: [changed], now: day(1), calendar: calendar), 0)
        XCTAssertEqual(ledger.shortSession(for: "gateway", items: [changed])?.contentRevision, 2)
        XCTAssertEqual(ledger.shortReviewDrafts?["gateway"], session) // Retain the unavailable draft for recovery.
    }
}
