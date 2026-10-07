import XCTest
@testable import WangGanCore

final class LearningTests: XCTestCase {
    private func catalog() throws -> LessonCatalog {
        try TestCatalog.compatibility()
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

    func testOnlyFirstLessonIsShipped() throws {
        let catalog = try TestCatalog.shipped()
        try catalog.validate()
        XCTAssertEqual(catalog.orderedLessonIDs, ["home-two-boxes"])
        XCTAssertEqual(catalog.lessons.map(\.id), ["home-two-boxes"])
        XCTAssertTrue(catalog.archivedLessonIDs.isEmpty)
        XCTAssertEqual(catalog.lessons.first?.title, "1-1")
        XCTAssertTrue(ProgressLedger().isUnlocked("home-two-boxes", in: catalog.orderedLessonIDs))
    }

    func testCatalogChaptersCoverEveryLessonExactlyOnce() throws {
        let catalog = try TestCatalog.shipped()
        try catalog.validate()
        XCTAssertFalse(catalog.course.chapters.isEmpty)
        XCTAssertEqual(catalog.allLessonIDs.count, catalog.lessons.count)
        XCTAssertEqual(Set(catalog.allLessonIDs), Set(catalog.lessons.map(\.id)))
        XCTAssertEqual(catalog.archivedLessonIDs, [])
        XCTAssertTrue(Set(catalog.orderedLessonIDs).isDisjoint(with: Set(catalog.archivedLessonIDs)))
        for chapter in catalog.course.chapters {
            XCTAssertEqual(catalog.lessons(in: chapter.id).map(\.id), chapter.orderedLessonIDs)
        }
    }

    func testOnlyFirstLessonUnlockedAtStartAndChainUnlocksInOrder() {
        var ledger = ProgressLedger()
        let ids = ["gateway", "subnet", "arp", "hop", "dns"]
        XCTAssertTrue(ledger.isUnlocked("gateway", in: ids))
        XCTAssertFalse(ledger.isUnlocked("subnet", in: ids))
        ledger.complete(finished("gateway"), now: today, calendar: calendar)
        XCTAssertTrue(ledger.isUnlocked("subnet", in: ids))
        XCTAssertFalse(ledger.isUnlocked("arp", in: ids))
    }

    func testCompletedLessonStaysUnlockedAfterNewLessonInsertedBeforeIt() {
        var ledger = ProgressLedger()
        ledger.complete(finished(), now: today, calendar: calendar)
        let ids = ["new-basics", "gateway", "subnet", "arp", "hop", "dns"]
        XCTAssertTrue(ledger.isUnlocked("new-basics", in: ids))
        XCTAssertTrue(ledger.isUnlocked("gateway", in: ids))
        XCTAssertTrue(ledger.isUnlocked("subnet", in: ids))
        XCTAssertFalse(ledger.isUnlocked("arp", in: ids))
        XCTAssertEqual(ledger.recommendedLessonID(in: ids), "new-basics")
    }

    func testCannotSkipUnansweredStages() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "gateway" })
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
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "gateway" })
        var session = LessonSession(lessonID: lesson.id)
        session.selectedAnswer = "all-fail"
        session.submitQuestion(lesson.question)
        session.submitQuestion(lesson.question)
        XCTAssertEqual(session.mistakes, 1)
        session.advance(lesson: lesson)
        XCTAssertEqual(session.stage, .explanation)
    }

    func testMatchingReassignmentIsOneToOneAndWrongAnswersCanBeCorrected() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "gateway" })
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
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "gateway" })
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

    func testPersistenceRoundTripIncludesDraftAndRewards() throws {
        var ledger = ProgressLedger()
        ledger.complete(finished(), now: today, calendar: calendar)
        var draft = LessonSession(lessonID: "subnet")
        draft.stage = .explanation
        draft.explanationIndex = 1
        ledger.saveDraft(draft, in: ["gateway", "subnet"])
        let saved = try JSONEncoder().encode(ledger)
        let restored = try JSONDecoder().decode(ProgressLedger.self, from: saved)
        XCTAssertEqual(ledger, restored)
        XCTAssertEqual(restored.draft?.explanationIndex, 1)
    }

    func testReadingCompletedLessonAndCompletionPreserveFartherMainCourse() throws {
        let ids = ["gateway", "subnet", "arp", "hop", "dns"]
        var ledger = ProgressLedger()
        ledger.complete(finished("gateway"), now: today, calendar: calendar)
        ledger.complete(finished("subnet"), now: today, calendar: calendar)
        var main = LessonSession(lessonID: "arp")
        main.stage = .explanation
        main.explanationIndex = 1
        ledger.saveDraft(main, in: ids)
        var reading = LessonSession(lessonID: "gateway")
        reading.questionSceneStep = 2
        ledger.saveDraft(reading, in: ids)
        let otherReading = LessonSession(lessonID: "subnet")
        ledger.saveDraft(otherReading, in: ids)
        XCTAssertEqual(ledger.recommendedLessonID(in: ids), "arp")
        XCTAssertEqual(ledger.session(for: "arp"), main)
        XCTAssertEqual(ledger.session(for: "gateway"), reading)

        var restored = try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger))
        reading.stage = .complete
        reading.matchingSolved = true
        reading.challengeSolved = true
        XCTAssertEqual(restored.complete(reading, now: today, calendar: calendar), 0)
        // The player's completion-state save must not erase the main draft either.
        restored.saveDraft(reading, in: ids)
        XCTAssertEqual(restored.draft, main)
        XCTAssertEqual(restored.drafts["subnet"], otherReading)
        XCTAssertNil(restored.drafts["gateway"])
        XCTAssertEqual(restored.recommendedLessonID(in: ids), "arp")
        XCTAssertEqual(restored.totalXP, 60)

        main.stage = .complete
        main.matchingSolved = true
        main.challengeSolved = true
        XCTAssertEqual(restored.complete(main, now: today, calendar: calendar), 30)
        XCTAssertNil(restored.draft)
        XCTAssertEqual(restored.recommendedLessonID(in: ids), ids[3])
    }

    func testDiscardCurrentMainDraftPreservesOtherDraftsAndHistory() throws {
        let ids = ["foundation", "gateway", "subnet", "arp", "hop"]
        var ledger = ProgressLedger()
        ledger.complete(finished("gateway"), now: today, calendar: calendar)
        ledger.complete(finished("subnet"), now: today, calendar: calendar)
        var main = LessonSession(lessonID: "arp")
        main.stage = .explanation
        let earlier = LessonSession(lessonID: "foundation")
        let reading = LessonSession(lessonID: "gateway")
        ledger.saveDraft(main, in: ids)
        ledger.saveDraft(earlier, in: ids)
        ledger.saveDraft(reading, in: ids)
        let before = ledger

        ledger.discardDraft(main)
        XCTAssertNil(ledger.draft)
        XCTAssertEqual(ledger.drafts, before.drafts.filter { $0.key != main.lessonID })
        XCTAssertEqual(ledger.lessons, before.lessons)
        XCTAssertEqual(ledger.activityDays, before.activityDays)
        XCTAssertEqual(ledger.settledSessions, before.settledSessions)
        XCTAssertEqual(ledger.totalXP, 60)
        let restored = try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger))
        XCTAssertEqual(restored.session(for: "arp").stage, .question)
        XCTAssertEqual(restored.session(for: "foundation"), earlier)
    }

    func testDiscardOtherLessonDraftDoesNotDisplaceMainCourse() throws {
        let ids = ["foundation", "gateway", "subnet", "arp", "hop"]
        var ledger = ProgressLedger()
        ledger.complete(finished("gateway"), now: today, calendar: calendar)
        ledger.complete(finished("subnet"), now: today, calendar: calendar)
        let main = LessonSession(lessonID: "arp")
        let earlier = LessonSession(lessonID: "foundation")
        let reading = LessonSession(lessonID: "gateway")
        let otherReading = LessonSession(lessonID: "subnet")
        for draft in [main, earlier, reading, otherReading] { ledger.saveDraft(draft, in: ids) }
        let history = ledger.lessons
        ledger.discardDraft(reading)
        XCTAssertNil(ledger.drafts["gateway"])
        XCTAssertEqual(ledger.drafts["subnet"], otherReading)
        XCTAssertEqual(ledger.draft, main)
        XCTAssertEqual(ledger.drafts["foundation"], earlier)
        ledger.discardDraft(earlier)
        XCTAssertNil(ledger.drafts["foundation"])
        XCTAssertEqual(ledger.recommendedLessonID(in: ids), "arp")
        XCTAssertEqual(ledger.session(for: "arp"), main)
        XCTAssertEqual(ledger.lessons, history)
        XCTAssertEqual(ledger.totalXP, 60)
    }

    func testDiscardStaleSessionCannotRemoveNewerDraft() {
        let stale = LessonSession(lessonID: "gateway")
        let current = LessonSession(lessonID: "gateway")
        var ledger = ProgressLedger()
        ledger.saveDraft(current, in: ["gateway"])
        ledger.discardDraft(stale)
        XCTAssertEqual(ledger.draft, current)
    }

    func testRecommendationKeepsFrontierWithoutDraftAndLastLessonAfterAllComplete() throws {
        let ids = try catalog().lessons.map(\.id)
        var ledger = ProgressLedger()
        XCTAssertNil(ledger.recommendedLessonID(in: []))
        ledger.complete(finished(ids[0]), now: today, calendar: calendar)
        ledger.complete(finished(ids[1]), now: today, calendar: calendar)
        ledger.saveDraft(LessonSession(lessonID: ids[0]), in: ids)
        XCTAssertEqual(ledger.recommendedLessonID(in: ids), ids[2])
        for id in ids.dropFirst(2) { ledger.complete(finished(id), now: today, calendar: calendar) }
        ledger.saveDraft(LessonSession(lessonID: ids[0]), in: ids)
        XCTAssertEqual(ledger.recommendedLessonID(in: ids), ids.last)
    }

    func testReopeningEarlierUnfinishedLessonCannotReplaceFartherDraft() throws {
        let ids = try catalog().lessons.map(\.id)
        var ledger = ProgressLedger()
        let farther = LessonSession(lessonID: ids[2])
        ledger.saveDraft(farther, in: ids)
        ledger.saveDraft(LessonSession(lessonID: ids[0]), in: ids)
        XCTAssertEqual(ledger.draft, farther)
        XCTAssertEqual(ledger.recommendedLessonID(in: ids), ids[2])
    }

    func testConversationProgressPersistsAndLegacyDraftsStillDecode() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "gateway" })
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
