import XCTest
@testable import WangGanCore

final class StepPlanTests: XCTestCase {
    private func catalog() throws -> LessonCatalog {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
    }

    func testIPv4VisualCalculatesBoundariesAndRejectsInvalidInput() throws {
        let first = try XCTUnwrap(IPv4AddressValue(ip: "192.168.1.10", prefix: 24))
        XCTAssertEqual(first.binaryOctets, ["11000000", "10101000", "00000001", "00001010"])
        XCTAssertEqual(first.networkAddress, "192.168.1.0")
        XCTAssertTrue(first.isCorrectBoundary(3))
        XCTAssertFalse(first.isCorrectBoundary(2))

        let second = try XCTUnwrap(IPv4AddressValue(ip: "10.20.30.40", prefix: 16))
        XCTAssertEqual(second.networkAddress, "10.20.0.0")
        XCTAssertTrue(second.isCorrectBoundary(2))
        XCTAssertEqual(IPv4AddressValue(ip: "192.168.1.200", prefix: 25)?.networkAddress, "192.168.1.128")
        XCTAssertNil(IPv4AddressValue(ip: "256.1.2.3", prefix: 24))
        XCTAssertNil(IPv4AddressValue(ip: "01.2.3.4", prefix: 24))
        XCTAssertNil(IPv4AddressValue(ip: "10.20.30.40", prefix: 33))
    }

    func testIPv4VisualDraftResumesAtPracticeWithoutChangingLegacyDrafts() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "subnet" })
        let visual = try XCTUnwrap(lesson.ipv4Visual)
        XCTAssertEqual(visual.examples.map(\.mode), [.explain, .practice])
        let plan = LessonPlan(lesson: lesson)

        var practice = LessonSession(lessonID: lesson.id)
        practice.stage = .explanation
        practice.ipv4VisualPhase = 1
        practice.ipv4SelectedOctet = 3
        practice.ipv4VisualSubmitted = true
        practice.ipv4VisualSolved = false
        practice.ipv4VisualFinished = false
        let restored = try JSONDecoder().decode(LessonSession.self, from: JSONEncoder().encode(practice))
        let step = StepSession(lesson: lesson, from: restored)
        XCTAssertEqual(step.stepIndex, plan.questionIndex + 1)
        XCTAssertEqual(step.ipv4SelectedOctet, 3)
        XCTAssertEqual(step.stageSession(lesson: lesson), restored)

        var afterVisual = practice
        afterVisual.ipv4VisualSolved = true
        afterVisual.ipv4VisualFinished = true
        let textStep = StepSession(lesson: lesson, from: afterVisual)
        XCTAssertEqual(textStep.stepIndex, plan.questionIndex + 2)

        var oldDraft = LessonSession(lessonID: lesson.id)
        oldDraft.stage = .explanation
        XCTAssertEqual(StepSession(lesson: lesson, from: oldDraft).stepIndex, plan.questionIndex + 2)
    }

    func testEveryLessonDerivesConsistentSteps() throws {
        let lessons = try catalog().lessons
        XCTAssertEqual(lessons.count, 5)
        for lesson in lessons {
            let plan = LessonPlan(lesson: lesson)
            XCTAssertEqual(Set(plan.steps.map(\.id)).count, plan.steps.count)
            XCTAssertEqual(plan.steps.filter { $0.kind == .conversation }.count,
                           lesson.question.scene.count + lesson.challenge.scene.count)
            XCTAssertEqual(plan.steps.filter { $0.kind == .question }.count, 2)
            XCTAssertEqual(plan.steps.filter { $0.kind == .diagram }.count, 1)
            XCTAssertEqual(plan.steps.filter { $0.kind == .text }.count, lesson.explanation.count)
            XCTAssertEqual(plan.steps.filter { $0.kind == .matching }.count, 1)
            XCTAssertEqual(plan.steps.first?.kind, .conversation)
            XCTAssertEqual(plan.steps.last?.kind, .summary)
            XCTAssertLessThan(plan.questionIndex, plan.matchingIndex)
            XCTAssertLessThan(plan.matchingIndex, plan.challengeIndex)
            XCTAssertLessThan(plan.challengeIndex, plan.summaryIndex)
        }
    }

    func testMigratedLessonsPlayThroughToCompletion() throws {
        for lessonID in ["gateway", "subnet", "arp", "hop", "dns"] {
            try assertLessonPlaysThroughToCompletion(lessonID)
        }
    }

    private func assertLessonPlaysThroughToCompletion(_ lessonID: String) throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == lessonID })
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lessonID: lesson.id)

        for _ in 0..<plan.questionSceneCount { plan.advance(&session) }
        XCTAssertEqual(session.stepIndex, plan.questionIndex)
        XCTAssertFalse(plan.canAdvance(session))
        plan.submitAnswer(lesson.question.correctID, in: &session)
        XCTAssertTrue(plan.canAdvance(session))
        plan.advance(&session)
        for _ in 0..<lesson.explanation.count { plan.advance(&session) }
        plan.advance(&session)
        XCTAssertEqual(session.stepIndex, plan.matchingIndex)

        for (left, right) in lesson.matching.solution { plan.connect(left, to: right, in: &session) }
        plan.submitMatching(in: &session)
        plan.advance(&session)
        for _ in 0..<plan.challengeSceneCount { plan.advance(&session) }
        XCTAssertEqual(session.stepIndex, plan.challengeIndex)

        plan.submitChallenge(lesson.challenge.correctID, in: &session)
        XCTAssertFalse(plan.isComplete(session))
        plan.advance(&session)
        XCTAssertTrue(plan.isComplete(session))
        XCTAssertEqual(session.mistakes, 0)
    }

    func testWrongChallengeRequiresRetryAndCountsMistake() throws {
        for lessonID in ["gateway", "subnet", "arp", "hop", "dns"] {
            try assertWrongChallengeRequiresRetry(lessonID)
        }
    }

    private func assertWrongChallengeRequiresRetry(_ lessonID: String) throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == lessonID })
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lessonID: lesson.id)
        for _ in 0..<plan.questionSceneCount { plan.advance(&session) }
        plan.submitAnswer(lesson.question.correctID, in: &session)
        plan.advance(&session)
        for _ in 0..<lesson.explanation.count { plan.advance(&session) }
        plan.advance(&session)
        for (left, right) in lesson.matching.solution { plan.connect(left, to: right, in: &session) }
        plan.submitMatching(in: &session)
        plan.advance(&session)
        for _ in 0..<plan.challengeSceneCount { plan.advance(&session) }

        let wrongID = try XCTUnwrap(lesson.challenge.options.first { $0.id != lesson.challenge.correctID }?.id)
        plan.submitChallenge(wrongID, in: &session)
        XCTAssertFalse(plan.canAdvance(session))
        XCTAssertEqual(session.mistakes, 1)
        plan.retryChallenge(in: &session)
        plan.submitChallenge(lesson.challenge.correctID, in: &session)
        plan.advance(&session)
        XCTAssertTrue(plan.isComplete(session))
        XCTAssertEqual(session.mistakes, 1)
    }

    func testStepPayloadAndSessionRoundTrip() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "gateway" })
        let plan = LessonPlan(lesson: lesson)
        let encoded = try JSONEncoder().encode(plan.steps)
        let steps = try JSONDecoder().decode([LessonStep].self, from: encoded)
        XCTAssertEqual(steps, plan.steps)

        var session = StepSession(lessonID: lesson.id)
        session.stepIndex = plan.questionIndex
        session.selectedAnswer = lesson.question.correctID
        session.answerSubmitted = true
        session.mistakes = 1
        let saved = try JSONEncoder().encode(session)
        let restored = try JSONDecoder().decode(StepSession.self, from: saved)
        XCTAssertEqual(restored, session)
    }

    func testStepPlanAgreesWithStageMachineOnMigratedLessons() throws {
        for lessonID in ["gateway", "subnet", "arp", "hop", "dns"] {
            try assertStepPlanAgreesWithStageMachine(for: lessonID)
        }
    }

    private func assertStepPlanAgreesWithStageMachine(for lessonID: String) throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == lessonID })
        let plan = LessonPlan(lesson: lesson)
        var stepSession = StepSession(lessonID: lesson.id)

        var stageSession = LessonSession(lessonID: lesson.id)
        for _ in 0..<lesson.question.scene.count {
            plan.advance(&stepSession)
            stageSession.revealNextScene(for: lesson.question, challenge: false)
        }
        XCTAssertEqual(stepSession.stepIndex, plan.questionIndex)
        XCTAssertTrue(stageSession.sceneIsComplete(for: lesson.question, challenge: false))

        let wrongID = try XCTUnwrap(lesson.question.options.first { $0.id != lesson.question.correctID }?.id)
        plan.submitAnswer(wrongID, in: &stepSession)
        stageSession.selectedAnswer = wrongID
        stageSession.submitQuestion(lesson.question)
        XCTAssertEqual(stepSession.mistakes, stageSession.mistakes)

        plan.advance(&stepSession)
        stageSession.advance(lesson: lesson)
        for _ in 0..<lesson.explanation.count {
            plan.advance(&stepSession)
            stageSession.advance(lesson: lesson)
        }
        plan.advance(&stepSession)
        XCTAssertEqual(stepSession.stepIndex, plan.matchingIndex)
        XCTAssertEqual(stageSession.stage, .matching)

        for (left, right) in lesson.matching.solution {
            plan.connect(left, to: right, in: &stepSession)
            stageSession.connect(left, to: right)
        }
        plan.submitMatching(in: &stepSession)
        stageSession.submitMatching(lesson.matching)
        XCTAssertTrue(stepSession.matchingSolved)
        XCTAssertTrue(stageSession.matchingSolved)

        plan.advance(&stepSession)
        stageSession.advance(lesson: lesson)
        XCTAssertEqual(stageSession.stage, .challenge)
        for _ in 0..<plan.challengeSceneCount { plan.advance(&stepSession) }
        XCTAssertEqual(stepSession.stepIndex, plan.challengeIndex)

        let wrongChallenge = try XCTUnwrap(lesson.challenge.options.first { $0.id != lesson.challenge.correctID }?.id)
        plan.submitChallenge(wrongChallenge, in: &stepSession)
        stageSession.challengeAnswer = wrongChallenge
        stageSession.submitChallenge(lesson.challenge)
        XCTAssertEqual(stepSession.mistakes, stageSession.mistakes)
        plan.retryChallenge(in: &stepSession)
        stageSession.retryChallenge(question: lesson.challenge)

        plan.submitChallenge(lesson.challenge.correctID, in: &stepSession)
        stageSession.challengeAnswer = lesson.challenge.correctID
        stageSession.submitChallenge(lesson.challenge)
        plan.advance(&stepSession)
        stageSession.advance(lesson: lesson)
        XCTAssertTrue(plan.isComplete(stepSession))
        XCTAssertEqual(stageSession.stage, .complete)
        XCTAssertEqual(stepSession.mistakes, stageSession.mistakes)
    }

    func testStageToStepAdapterRoundTripsEveryDraftPosition() throws {
        for lessonID in ["gateway", "subnet", "arp", "hop", "dns"] {
            try assertAdapterRoundTripsEveryDraftPosition(for: lessonID)
        }
    }

    private func assertAdapterRoundTripsEveryDraftPosition(for lessonID: String) throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == lessonID })
        var drafts: [LessonSession] = []
        var fresh = LessonSession(lessonID: lesson.id)
        drafts.append(fresh)
        for _ in 0..<(lesson.question.scene.count - 1) { fresh.revealNextScene(for: lesson.question, challenge: false) }
        drafts.append(fresh)
        var answered = fresh
        answered.selectedAnswer = lesson.question.correctID
        answered.submitQuestion(lesson.question)
        drafts.append(answered)
        var explained = answered
        explained.advance(lesson: lesson)
        explained.advance(lesson: lesson)
        drafts.append(explained)
        var matched = explained
        while matched.stage != .matching { matched.advance(lesson: lesson) }
        for (left, right) in lesson.matching.solution { matched.connect(left, to: right) }
        matched.submitMatching(lesson.matching)
        drafts.append(matched)
        var challenged = matched
        challenged.advance(lesson: lesson)
        challenged.revealNextScene(for: lesson.challenge, challenge: true)
        drafts.append(challenged)
        var wrong = challenged
        wrong.challengeAnswer = lesson.challenge.options.first { $0.id != lesson.challenge.correctID }!.id
        wrong.submitChallenge(lesson.challenge)
        drafts.append(wrong)
        var solved = challenged
        solved.challengeAnswer = lesson.challenge.correctID
        solved.submitChallenge(lesson.challenge)
        solved.advance(lesson: lesson)
        drafts.append(solved)

        for draft in drafts {
            let step = StepSession(lesson: lesson, from: draft)
            let restored = step.stageSession(lesson: lesson)
            XCTAssertEqual(step.id, draft.id)
            XCTAssertEqual(restored.id, step.id)
            assertEquivalent(draft, restored, lesson: lesson)
        }
    }

    private func assertEquivalent(_ a: LessonSession, _ b: LessonSession, lesson: Lesson) {
        XCTAssertEqual(a.stage, b.stage)
        XCTAssertEqual(a.mistakes, b.mistakes)
        XCTAssertEqual(a.selectedAnswer, b.selectedAnswer)
        XCTAssertEqual(a.answerSubmitted, b.answerSubmitted)
        XCTAssertEqual(a.matches, b.matches)
        XCTAssertEqual(a.matchingSubmitted, b.matchingSubmitted)
        XCTAssertEqual(a.matchingSolved, b.matchingSolved)
        XCTAssertEqual(a.challengeAnswer, b.challengeAnswer)
        XCTAssertEqual(a.challengeSubmitted, b.challengeSubmitted)
        XCTAssertEqual(a.challengeSolved, b.challengeSolved)
        if a.stage == .explanation || b.stage == .explanation {
            XCTAssertEqual(a.explanationIndex, b.explanationIndex)
        }
        XCTAssertEqual(a.sceneStep(for: lesson.question, challenge: false),
                       b.sceneStep(for: lesson.question, challenge: false))
        XCTAssertEqual(a.sceneStep(for: lesson.challenge, challenge: true),
                       b.sceneStep(for: lesson.challenge, challenge: true))
    }
}
