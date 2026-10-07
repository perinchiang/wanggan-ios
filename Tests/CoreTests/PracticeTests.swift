import XCTest
@testable import WangGanCore

final class PracticeTests: XCTestCase {
    private func content() throws -> PracticeLesson {
        // Mechanics use a neutral fixture so course edits do not remove matching coverage.
        func choice(_ id: String, role: PracticeRole, options: [String], correct: String,
                    kind: PracticeKind = .choice) -> PracticeQuestion {
            PracticeQuestion(id: id, role: role, kind: kind,
                             prompt: kind == .fillBlank ? "Fixture ____" : "Fixture",
                             figures: [], options: options.map { AnswerOption(id: $0, text: $0, feedback: "") },
                             correctID: correct, matching: nil, explanation: "Fixture")
        }
        let pairs = MatchingExercise(prompt: "Fixture", left: [
            MatchItem(id: "a", text: "A", symbol: ""), MatchItem(id: "b", text: "B", symbol: "")],
            right: [MatchItem(id: "wireless", text: "B", symbol: ""), MatchItem(id: "wired", text: "A", symbol: "")],
            solution: ["a": "wired", "b": "wireless"], explanation: "Fixture")
        return PracticeLesson(revision: 1, questions: [
            choice("cable-recognition", role: .exploration, options: ["a", "b"], correct: "a"),
            choice("wifi-recognition", role: .exploration, options: ["wired", "wireless"], correct: "wireless"),
            choice("cable-blank", role: .mastery, options: ["wifi", "cable"], correct: "cable", kind: .fillBlank),
            choice("wifi-device", role: .mastery, options: ["computer", "phone"], correct: "phone"),
            choice("computer-wifi", role: .mastery, options: ["wifi", "cable"], correct: "wifi"),
            PracticeQuestion(id: "connection-pairs", role: .mastery, kind: .matching, prompt: "Fixture",
                             figures: [], options: [], correctID: nil, matching: pairs, explanation: "Fixture")
        ])
    }
    private func question(_ id: String) throws -> PracticeQuestion {
        try XCTUnwrap(content().question(id))
    }
    private func reach(_ id: String, session: inout PracticeSession, lesson: PracticeLesson) {
        while session.currentID != id, let current = lesson.question(session.currentID) {
            session.attempt.select(current.correctID!, question: current)
            if current.kind == .fillBlank { session.attempt.submit(current) }
            session.advance(lesson: lesson)
        }
    }

    func testFillRequiresCheckAndCanBeUndoneBeforeChecking() throws {
        let q = try question("cable-blank")
        var attempt = PracticeAttempt()
        attempt.select("cable", question: q)
        XCTAssertNil(attempt.result)
        attempt.select("cable", question: q)
        XCTAssertNil(attempt.selectedID)
        attempt.submit(q)
        XCTAssertNil(attempt.result)
        attempt.select("wifi", question: q)
        attempt.submit(q)
        XCTAssertEqual(attempt.result, false)
        attempt.select("cable", question: q)
        attempt.submit(q)
        XCTAssertEqual(attempt.selectedID, "wifi", "Submitted answers stay locked until Continue")
        XCTAssertEqual(attempt.result, false)
    }

    func testExplorationMistakeIsNotTrackedAndMasteryMistakeMovesAfterOtherQuestions() throws {
        let lesson = try content()
        var session = PracticeSession(lesson: lesson)
        let first = try XCTUnwrap(lesson.question(session.currentID))
        session.attempt.select("b", question: first)
        XCTAssertEqual(session.currentID, first.id, "Feedback remains on this question")
        session.advance(lesson: lesson)
        XCTAssertFalse(session.queue.contains(first.id))
        XCTAssertEqual(session.mistakes, 0)
        reach("cable-blank", session: &session, lesson: lesson)
        let fill = try XCTUnwrap(lesson.question(session.currentID))
        session.attempt.select("wifi", question: fill)
        session.attempt.submit(fill)
        session.advance(lesson: lesson)
        XCTAssertEqual(session.currentID, "wifi-device")
        XCTAssertEqual(session.queue.last, fill.id)
        XCTAssertEqual(session.mistakes, 1)
        XCTAssertTrue(session.isValid(for: lesson))
    }

    func testMatchingSucceededAfterTwoMistakesCountsCorrectWithoutTailRetry() throws {
        let lesson = try content(), q = try question("connection-pairs")
        var session = PracticeSession(lesson: lesson)
        reach(q.id, session: &session, lesson: lesson)
        for _ in 0..<2 {
            XCTAssertFalse(session.attempt.pair("a", "wireless", question: q))
            XCTAssertNil(session.attempt.result)
            XCTAssertTrue(session.attempt.matches.isEmpty, "Wrong pairs do not reveal or fix the answer")
        }
        XCTAssertTrue(session.attempt.pair("a", "wired", question: q))
        XCTAssertNil(session.attempt.result)
        XCTAssertTrue(session.attempt.pair("b", "wireless", question: q))
        XCTAssertEqual(session.attempt.result, true)
        XCTAssertTrue(session.isValid(for: lesson))
        session.advance(lesson: lesson)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.mistakes, 0)
    }

    func testThirdMatchingErrorLocksWholeQuestionAndPreservesSuccessfulPairs() throws {
        let q = try question("connection-pairs")
        var attempt = PracticeAttempt()
        XCTAssertFalse(attempt.pair("a", "wireless", question: q))
        XCTAssertFalse(attempt.pair("a", "wireless", question: q))
        XCTAssertFalse(attempt.pair("a", "wireless", question: q))
        XCTAssertEqual(attempt.result, false)
        XCTAssertEqual(attempt.matchingErrors, 3)
        let saved = attempt
        XCTAssertFalse(attempt.pair("a", "wired", question: q))
        XCTAssertEqual(attempt, saved)
        // Completed pairs and invalid endpoints cannot consume extra attempts.
        attempt = PracticeAttempt()
        XCTAssertTrue(attempt.pair("a", "wired", question: q))
        XCTAssertFalse(attempt.pair("a", "wireless", question: q))
        XCTAssertFalse(attempt.pair("missing", "wireless", question: q))
        XCTAssertFalse(attempt.pair("b", "wired", question: q))
        XCTAssertEqual(attempt.matchingErrors, 0)
    }

    func testInterruptedMatchingRestoresTrialBudgetAndCompletedPairs() throws {
        let lesson = try content(), q = try question("connection-pairs")
        var session = LessonSession(lessonID: "home-two-boxes")
        session.practice = PracticeSession(lesson: lesson)
        reach(q.id, session: &session.practice!, lesson: lesson)
        session.practice!.attempt.pair("a", "wireless", question: q)
        session.practice!.attempt.pair("a", "wireless", question: q)
        let restored = try JSONDecoder().decode(LessonSession.self, from: JSONEncoder().encode(session))
        XCTAssertEqual(restored, session)
        XCTAssertEqual(restored.practice?.attempt.matchingErrors, 2)
        var resumed = try XCTUnwrap(restored.practice)
        resumed.attempt.pair("a", "wireless", question: q)
        XCTAssertEqual(resumed.attempt.result, false, "Relaunch must not reset the three-error budget")
        XCTAssertTrue(resumed.isValid(for: lesson))
    }

    func testMatchingErrorBudgetIsSharedAcrossPairsAndCorrectPairsDoNotResetIt() {
        let exercise = MatchingExercise(prompt: "Fixture", left: [
            MatchItem(id: "a", text: "A", symbol: ""), MatchItem(id: "b", text: "B", symbol: ""),
            MatchItem(id: "c", text: "C", symbol: "")], right: [
            MatchItem(id: "1", text: "1", symbol: ""), MatchItem(id: "2", text: "2", symbol: ""),
            MatchItem(id: "3", text: "3", symbol: "")], solution: ["a": "1", "b": "2", "c": "3"], explanation: "Fixture")
        let q = PracticeQuestion(id: "fixture", role: .mastery, kind: .matching, prompt: "Fixture",
                                 figures: [], options: [], correctID: nil, matching: exercise, explanation: "Fixture")
        var attempt = PracticeAttempt()
        attempt.pair("a", "2", question: q)
        attempt.pair("a", "3", question: q)
        attempt.pair("a", "1", question: q)
        XCTAssertEqual(attempt.matchingErrors, 2)
        attempt.pair("b", "3", question: q)
        XCTAssertEqual(attempt.result, false)
        XCTAssertEqual(attempt.matches, ["a": "1"])
        XCTAssertFalse(attempt.pair("b", "2", question: q))
    }

    func testPracticeCompletionPreservesExistingXPAndFirstCompletion() throws {
        let lesson = try XCTUnwrap(TestCatalog.shipped().lessons.first?.practice)
        var session = LessonSession(lessonID: "home-two-boxes")
        session.practice = PracticeSession(lesson: lesson)
        var ledger = ProgressLedger()
        XCTAssertEqual(ledger.complete(session), 0)
        while let q = lesson.question(session.practice?.currentID) {
            if let matching = q.matching {
                for item in matching.left {
                    session.practice!.attempt.pair(item.id, matching.solution[item.id]!, question: q)
                }
            } else {
                session.practice!.attempt.select(q.correctID!, question: q)
                session.practice!.attempt.submit(q)
            }
            session.practice!.advance(lesson: lesson)
        }
        session.stage = .complete
        XCTAssertTrue(session.practice!.isValid(for: lesson))
        XCTAssertEqual(ledger.complete(session), 30)
        let first = ledger.lessons
        XCTAssertEqual(ledger.complete(session), 30)
        session = LessonSession(lessonID: "home-two-boxes")
        session.stage = .complete
        session.matchingSolved = true
        session.challengeSolved = true
        XCTAssertEqual(ledger.complete(session), 0)
        XCTAssertEqual(ledger.totalXP, 30)
        XCTAssertEqual(ledger.lessons, first)
    }

    func testRealV2ShapeUpgradesWithoutReplacingLegacyDraftOrRewards() throws {
        let old = #"{"schemaVersion":2,"totalXP":340,"lessons":{"home-two-boxes":{"completedAt":812721600,"lastMistakes":1}},"activityDays":[812678400],"settledSessions":[],"drafts":{"home-two-boxes":{"id":"00000000-0000-0000-0000-000000000001","lessonID":"home-two-boxes","stage":1,"explanationIndex":2,"answerSubmitted":true,"matches":{},"matchingSubmitted":false,"matchingSolved":false,"challengeSubmitted":false,"challengeSolved":false,"mistakes":1}},"mainLessonID":null}"#
        let ledger = try JSONDecoder().decode(ProgressLedger.self, from: Data(old.utf8))
        XCTAssertEqual(ledger.schemaVersion, 3)
        XCTAssertEqual(ledger.totalXP, 340)
        XCTAssertNil(ledger.drafts["home-two-boxes"]?.practice)
        XCTAssertEqual(ledger.drafts["home-two-boxes"]?.explanationIndex, 2)
        XCTAssertTrue(ledger.drafts["home-two-boxes"]!.hasLegacyProgress)
        let restored = try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger))
        XCTAssertEqual(restored, ledger)
    }

    func testChangedOrCorruptQuestionIDsFailClosedRatherThanResettingDraft() throws {
        let lesson = try content()
        var session = PracticeSession(lesson: lesson)
        session.queue[0] = "deleted-question"
        XCTAssertFalse(session.isValid(for: lesson))
        session = PracticeSession(lesson: lesson)
        session.queue.removeAll()
        XCTAssertFalse(session.isValid(for: lesson))
    }

    func testShippedPracticeContinuesPastNewConceptsAndRetriesLearnedWifiName() throws {
        let catalog = try TestCatalog.shipped()
        try catalog.validate()
        let lesson = try XCTUnwrap(catalog.lessons.first?.practice)
        var session = PracticeSession(lesson: lesson)
        let mastery = try XCTUnwrap(lesson.questions.first(where: { $0.role == .mastery }))
        XCTAssertEqual(mastery.id, "home-wifi-name")
        for question in lesson.questions {
            XCTAssertEqual(session.currentID, question.id)
            XCTAssertTrue(session.isValid(for: lesson))
            let wrong = try XCTUnwrap(question.options.first(where: { $0.id != question.correctID }))
            session.attempt.select(wrong.id, question: question)
            if question.kind == .fillBlank { session.attempt.submit(question) }
            session.advance(lesson: lesson)
        }
        XCTAssertEqual(session.queue, [mastery.id], "Only the already introduced Wi-Fi name needs a retry")
        XCTAssertEqual(session.mistakes, 1)
        XCTAssertTrue(session.isValid(for: lesson))
        session.attempt.select(try XCTUnwrap(mastery.correctID), question: mastery)
        session.attempt.submit(mastery)
        session.advance(lesson: lesson)
        XCTAssertTrue(session.isComplete)
        XCTAssertTrue(session.isValid(for: lesson))
    }

    func testRevisionOneDraftAndRewardsSurviveRevisionTwoContentChange() throws {
        let oldLesson = try content()
        let updated = try XCTUnwrap(TestCatalog.shipped().lessons.first?.practice)
        var draft = LessonSession(lessonID: "home-two-boxes")
        draft.practice = PracticeSession(lesson: oldLesson)
        reach("connection-pairs", session: &draft.practice!, lesson: oldLesson)
        let matching = try XCTUnwrap(oldLesson.question(draft.practice?.currentID))
        draft.practice!.attempt.pair("a", "wireless", question: matching)
        draft.practice!.attempt.pair("a", "wireless", question: matching)
        var ledger = ProgressLedger()
        ledger.totalXP = 340
        ledger.lessons[draft.lessonID] = LessonProgress(completedAt: Date(timeIntervalSince1970: 1_700_000_000), lastMistakes: 1)
        ledger.saveDraft(draft, in: [draft.lessonID])
        let other = LessonSession(lessonID: "retired-content")
        ledger.drafts[other.lessonID] = other
        var restored = try JSONDecoder().decode(ProgressLedger.self, from: JSONEncoder().encode(ledger))
        restored.normalizeDrafts(in: [draft.lessonID])
        XCTAssertEqual(restored, ledger, "Content changes must preserve all drafts and previous completion records")
        let saved = try XCTUnwrap(restored.session(for: draft.lessonID).practice)
        XCTAssertTrue(saved.isValid(for: oldLesson))
        XCTAssertFalse(saved.isValid(for: updated), "Old answers cannot be applied to new questions")
        XCTAssertEqual(saved.attempt.matchingErrors, 2)
        XCTAssertTrue(PracticeSession(lesson: updated).isValid(for: updated))
        restored.discardDraft(draft)
        XCTAssertEqual(restored.totalXP, 340)
        XCTAssertEqual(restored.lessons, ledger.lessons)
        XCTAssertEqual(restored.drafts[other.lessonID], other)
    }

    func testLastErrorComesBackAfterKnownQuestionAndTrialBudgetResets() throws {
        let lesson = try content(), q = try question("connection-pairs")
        var session = PracticeSession(lesson: lesson)
        reach(q.id, session: &session, lesson: lesson)
        for _ in 0..<3 { session.attempt.pair("a", "wireless", question: q) }
        session.advance(lesson: lesson)
        XCTAssertNotEqual(session.currentID, q.id)
        XCTAssertEqual(session.queue.last, q.id)
        XCTAssertEqual(session.mistakes, 1)
        XCTAssertTrue(session.isValid(for: lesson))
        session = try JSONDecoder().decode(PracticeSession.self, from: JSONEncoder().encode(session))
        let separator = try XCTUnwrap(lesson.question(session.currentID))
        session.attempt.select(separator.correctID!, question: separator)
        session.attempt.submit(separator)
        session.advance(lesson: lesson)
        XCTAssertEqual(session.currentID, q.id)
        XCTAssertEqual(session.attempt.matchingErrors, 0)
        session.attempt.pair("a", "wired", question: q)
        session.attempt.pair("b", "wireless", question: q)
        session.advance(lesson: lesson)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.mistakes, 1)
        XCTAssertTrue(session.isValid(for: lesson))
    }
}
