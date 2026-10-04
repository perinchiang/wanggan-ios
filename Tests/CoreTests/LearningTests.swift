import XCTest
@testable import WangGanCore

final class LearningTests: XCTestCase {
    private func catalog() throws -> LessonCatalog {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
    }

    private func finished(_ id: String = "gateway", mistakes: Int = 0) -> LessonSession {
        var session = LessonSession(lessonID: id)
        session.stage = .complete
        session.matchingSolved = true
        session.challengeSolved = true
        session.mistakes = mistakes
        return session
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    private var today: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 12))!
    }

    func testAllShippedLessonsAreConsistent() throws {
        let catalog = try catalog()
        try catalog.validate()
        XCTAssertEqual(catalog.lessons.count, 5)
        for lesson in catalog.lessons {
            XCTAssertFalse(lesson.sources.contains { URL(string: $0)?.scheme != "https" })
        }
    }

    func testCannotSkipUnansweredStages() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first)
        var session = LessonSession(lessonID: lesson.id)
        session.advance(lesson: lesson)
        XCTAssertEqual(session.stage, .question)
        session.stage = .matching
        session.advance(lesson: lesson)
        XCTAssertEqual(session.stage, .matching)
        session.stage = .challenge
        session.advance(lesson: lesson)
        XCTAssertEqual(session.stage, .challenge)
    }

    func testWrongAnswerOpensExplanationAndCountsOnlyOnce() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first)
        var session = LessonSession(lessonID: lesson.id)
        session.selectedAnswer = "all-fail"
        session.submitQuestion(lesson.question)
        session.submitQuestion(lesson.question)
        XCTAssertEqual(session.mistakes, 1)
        session.advance(lesson: lesson)
        XCTAssertEqual(session.stage, .explanation)
    }

    func testMatchingReassignmentIsOneToOneAndWrongAnswersCanBeCorrected() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first)
        var session = LessonSession(lessonID: lesson.id)
        session.connect("nas", to: "router")
        session.connect("internet", to: "router")
        XCTAssertNil(session.matches["nas"])
        session.connect("nas", to: "host")
        session.submitMatching(lesson.matching)
        XCTAssertTrue(session.matchingSolved)

        var wrong = LessonSession(lessonID: lesson.id)
        wrong.connect("nas", to: "router")
        wrong.connect("internet", to: "host")
        wrong.submitMatching(lesson.matching)
        XCTAssertFalse(wrong.matchingSolved)
        wrong.connect("nas", to: "host")
        wrong.connect("internet", to: "router")
        wrong.submitMatching(lesson.matching)
        XCTAssertTrue(wrong.matchingSolved)
        XCTAssertEqual(wrong.mistakes, 1)
    }

    func testChallengeRequiresCorrectRetry() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first)
        var session = LessonSession(lessonID: lesson.id)
        session.stage = .challenge
        session.challengeAnswer = "no"
        session.submitChallenge(lesson.challenge)
        session.advance(lesson: lesson)
        XCTAssertEqual(session.stage, .challenge)
        session.retryChallenge(question: lesson.challenge)
        XCTAssertNil(session.challengeAnswer)
        session.challengeAnswer = "yes"
        session.submitChallenge(lesson.challenge)
        session.advance(lesson: lesson)
        XCTAssertEqual(session.stage, .complete)
    }

    func testRewardsAreIdempotentAndSameDayReplayCannotFarmXP() {
        var ledger = ProgressLedger()
        let session = finished()
        XCTAssertEqual(ledger.complete(session, now: today, calendar: calendar), 30)
        XCTAssertEqual(ledger.complete(session, now: today, calendar: calendar), 30)
        XCTAssertEqual(ledger.totalXP, 30)
        XCTAssertEqual(ledger.complete(finished(), now: today, calendar: calendar), 0)
        XCTAssertEqual(ledger.totalXP, 30)
        XCTAssertEqual(ledger.activityDays.count, 1)
        XCTAssertEqual(ledger.complete(LessonSession(lessonID: "subnet"), now: today, calendar: calendar), 0)
    }

    func testReviewRewardsAndIntervalsFollowLocalCalendar() throws {
        var ledger = ProgressLedger()
        ledger.complete(finished(), now: today, calendar: calendar)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        XCTAssertFalse(ledger.isDue("gateway", now: today))
        XCTAssertTrue(ledger.isDue("gateway", now: tomorrow))
        XCTAssertEqual(ledger.complete(finished(), now: tomorrow, calendar: calendar), 5)
        let progress = try XCTUnwrap(ledger.lessons["gateway"])
        XCTAssertEqual(progress.reviewLevel, 1)
        XCTAssertEqual(progress.nextReviewAt, calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: tomorrow)))
        XCTAssertEqual(ledger.complete(finished(), now: tomorrow, calendar: calendar), 0)
        XCTAssertEqual(ledger.totalXP, 35)
    }

    func testPersistenceRoundTripIncludesDraftAndRewards() throws {
        var ledger = ProgressLedger()
        ledger.complete(finished(), now: today, calendar: calendar)
        var draft = LessonSession(lessonID: "subnet")
        draft.stage = .explanation
        draft.explanationIndex = 1
        ledger.draft = draft
        let saved = try JSONEncoder().encode(ledger)
        let restored = try JSONDecoder().decode(ProgressLedger.self, from: saved)
        XCTAssertEqual(ledger, restored)
        XCTAssertEqual(restored.draft?.explanationIndex, 1)
    }

    func testConversationProgressPersistsAndLegacyDraftsStillDecode() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first)
        var session = LessonSession(lessonID: lesson.id)
        XCTAssertEqual(session.sceneStep(for: lesson.question, challenge: false), 0)
        XCTAssertFalse(session.sceneIsComplete(for: lesson.question, challenge: false))
        session.revealNextScene(for: lesson.question, challenge: false)
        let restored = try JSONDecoder().decode(LessonSession.self, from: JSONEncoder().encode(session))
        XCTAssertEqual(restored.sceneStep(for: lesson.question, challenge: false), 1)
        for _ in 0..<10 { session.revealNextScene(for: lesson.question, challenge: false) }
        XCTAssertEqual(session.questionSceneStep, lesson.question.scene.count)
        XCTAssertTrue(session.sceneIsComplete(for: lesson.question, challenge: false))
        XCTAssertFalse(session.sceneIsComplete(for: lesson.challenge, challenge: true))

        session.stage = .challenge
        session.challengeAnswer = lesson.challenge.correctID
        var oldDraft = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(session)) as? [String: Any])
        oldDraft.removeValue(forKey: "questionSceneStep")
        oldDraft.removeValue(forKey: "challengeSceneStep")
        var legacy = try JSONDecoder().decode(LessonSession.self, from: JSONSerialization.data(withJSONObject: oldDraft))
        XCTAssertEqual(legacy.stage, .challenge)
        XCTAssertEqual(legacy.challengeAnswer, lesson.challenge.correctID)
        XCTAssertTrue(legacy.sceneIsComplete(for: lesson.challenge, challenge: true))
        legacy.retryChallenge(question: lesson.challenge)
        XCTAssertTrue(legacy.sceneIsComplete(for: lesson.challenge, challenge: true))
    }
}
