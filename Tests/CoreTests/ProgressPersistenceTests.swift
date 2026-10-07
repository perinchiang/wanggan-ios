import XCTest
@testable import WangGanCore

final class ProgressPersistenceTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return value
    }
    private var date: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 23))!
    }
    private func finish(_ id: String, mistakes: Int = 0) -> LessonSession {
        var session = LessonSession(lessonID: id)
        session.stage = .complete
        session.matchingSolved = true
        session.challengeSolved = true
        session.mistakes = mistakes
        return session
    }
    private func object<T: Encodable>(_ value: T) throws -> Any {
        try JSONSerialization.jsonObject(with: JSONEncoder().encode(value))
    }

    func testV1MigratesAllLessonDraftsHistoryAndOldRewardsIntoOneStore() throws {
        var ledger = ProgressLedger()
        let completed = finish("home-two-boxes", mistakes: 1)
        ledger.complete(completed, now: date, calendar: calendar)
        let previousRewardID = UUID()
        ledger.settledSessions[previousRewardID] = 5
        ledger.totalXP = 35
        var main = LessonSession(lessonID: "retired-main")
        main.stage = .explanation
        main.explanationIndex = 2
        main.mistakes = 2
        let earlier = LessonSession(lessonID: "retired-earlier")
        var rereading = LessonSession(lessonID: "home-two-boxes")
        rereading.stage = .challenge
        rereading.challengeAnswer = "allinone"
        rereading.challengeSubmitted = true
        rereading.challengeSolved = true
        rereading.challengeExplanationID = "fttr-rooms"

        var old = try XCTUnwrap(object(ledger) as? [String: Any])
        old["schemaVersion"] = 1
        old.removeValue(forKey: "drafts")
        old.removeValue(forKey: "mainLessonID")
        old["draft"] = try object(main)
        old["earlierDrafts"] = try object([earlier.lessonID: earlier])
        old["reviewDrafts"] = try object([rereading.lessonID: rereading])
        // No removed types are required even if their old payload is unreadable.
        old["shortReviewDrafts"] = ["obsolete": "unused payload"]
        old["reviewEvidence"] = ["unused payload"]
        var progress = try XCTUnwrap(old["lessons"] as? [String: [String: Any]])
        progress[completed.lessonID]?["lastPracticedAt"] = 812721600
        progress[completed.lessonID]?["nextReviewAt"] = 812764800
        progress[completed.lessonID]?["reviewLevel"] = 3
        old["lessons"] = progress

        var migrated = try JSONDecoder().decode(ProgressLedger.self, from: JSONSerialization.data(withJSONObject: old))
        migrated.normalizeDrafts(in: ["home-two-boxes"])
        XCTAssertEqual(migrated.schemaVersion, 2)
        XCTAssertEqual(migrated.totalXP, 35)
        XCTAssertEqual(migrated.lessons, ledger.lessons)
        XCTAssertEqual(migrated.activityDays, ledger.activityDays)
        XCTAssertEqual(migrated.settledSessions, ledger.settledSessions)
        XCTAssertEqual(migrated.draft, main)
        XCTAssertEqual(migrated.drafts[earlier.lessonID], earlier)
        XCTAssertEqual(migrated.session(for: rereading.lessonID), rereading)
        XCTAssertEqual(migrated.recommendedLessonID(in: ["home-two-boxes"]), "home-two-boxes")

        let encoded = try JSONEncoder().encode(migrated)
        let current = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(Set(current.keys), Set(["schemaVersion", "totalXP", "lessons", "activityDays", "settledSessions", "drafts", "mainLessonID"]))
        let currentProgress = try XCTUnwrap(current["lessons"] as? [String: [String: Any]])
        XCTAssertEqual(Set(try XCTUnwrap(currentProgress[completed.lessonID]).keys), Set(["completedAt", "lastMistakes"]))
        var restored = try JSONDecoder().decode(ProgressLedger.self, from: encoded)
        restored.normalizeDrafts(in: ["home-two-boxes"])
        XCTAssertEqual(restored, migrated)
        XCTAssertEqual(restored.complete(completed, now: date, calendar: calendar), 30)
        XCTAssertEqual(restored.totalXP, 35)
    }

    func testReadingAgainNeverRewardsAcrossDaysAndPreservesOriginalCompletion() throws {
        var ledger = ProgressLedger()
        let first = finish("home-two-boxes", mistakes: 1)
        XCTAssertEqual(ledger.complete(first, now: date, calendar: calendar), 30)
        let original = try XCTUnwrap(ledger.lessons[first.lessonID])
        for offset in [0, 1, 7, 90] {
            let later = try XCTUnwrap(calendar.date(byAdding: .day, value: offset, to: date))
            let next = finish(first.lessonID, mistakes: 3)
            XCTAssertEqual(ledger.complete(next, now: later, calendar: calendar), 0)
            XCTAssertEqual(ledger.complete(next, now: later, calendar: calendar), 0)
            XCTAssertEqual(ledger.lessons[first.lessonID], original)
        }
        XCTAssertEqual(ledger.totalXP, 30)
        XCTAssertEqual(ledger.activityDays.count, 4)
        XCTAssertEqual(ledger.settledSessions.values.filter { $0 > 0 }, [30])
    }

    func testOldCompletedMainDraftBecomesOrdinaryDraftWithoutMovingMainRecommendation() throws {
        let old = #"{"schemaVersion":1,"totalXP":30,"lessons":{"done":{"completedAt":812721600,"lastPracticedAt":812721600,"nextReviewAt":812764800,"reviewLevel":1,"lastMistakes":0}},"activityDays":[812678400],"settledSessions":[],"draft":{"id":"00000000-0000-0000-0000-000000000001","lessonID":"done","stage":1,"explanationIndex":1,"answerSubmitted":true,"matches":{},"matchingSubmitted":false,"matchingSolved":false,"challengeSubmitted":false,"challengeSolved":false,"mistakes":0}}"#
        var ledger = try JSONDecoder().decode(ProgressLedger.self, from: Data(old.utf8))
        ledger.normalizeDrafts(in: ["done", "next"])
        XCTAssertNil(ledger.draft)
        XCTAssertEqual(ledger.session(for: "done").explanationIndex, 1)
        XCTAssertEqual(ledger.recommendedLessonID(in: ["done", "next"]), "next")
        XCTAssertEqual(ledger.totalXP, 30)
    }

    func testUnknownVersionAndCorruptCurrentDraftsAreRejected() throws {
        var json = try XCTUnwrap(object(ProgressLedger()) as? [String: Any])
        json["schemaVersion"] = 99
        XCTAssertThrowsError(try JSONDecoder().decode(ProgressLedger.self, from: JSONSerialization.data(withJSONObject: json)))
        json["schemaVersion"] = 2
        json["drafts"] = ["broken": "not a session"]
        XCTAssertThrowsError(try JSONDecoder().decode(ProgressLedger.self, from: JSONSerialization.data(withJSONObject: json)))
    }
}
