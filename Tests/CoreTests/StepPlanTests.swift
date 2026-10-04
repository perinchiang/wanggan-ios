import XCTest
@testable import WangGanCore

final class StepPlanTests: XCTestCase {
    private func catalog() throws -> LessonCatalog {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
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

    func testGatewayPlaysThroughToCompletion() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "gateway" })
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lessonID: lesson.id)

        for _ in 0..<plan.questionSceneCount { plan.advance(&session) }
        XCTAssertEqual(session.stepIndex, plan.questionIndex)
        XCTAssertFalse(plan.canAdvance(session))
        plan.submitAnswer(lesson.question.correctID, in: &session)
        XCTAssertTrue(plan.canAdvance(session))
        plan.advance(&session)
        for _ in 0..<lesson.explanation.count { plan.advance(&session) }
        XCTAssertEqual(session.stepIndex, plan.matchingIndex)

        for (left, right) in lesson.matching.solution { plan.connect(left, to: right, in: &session) }
        plan.submitMatching(in: &session)
        plan.advance(&session)
        for _ in 1..<plan.challengeSceneCount { plan.advance(&session) }
        XCTAssertEqual(session.stepIndex, plan.challengeIndex)

        plan.submitChallenge(lesson.challenge.correctID, in: &session)
        XCTAssertFalse(plan.isComplete(session))
        plan.advance(&session)
        XCTAssertTrue(plan.isComplete(session))
        XCTAssertEqual(session.mistakes, 0)
    }

    func testWrongChallengeRequiresRetryAndCountsMistake() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "gateway" })
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lessonID: lesson.id)
        for _ in 0..<plan.questionSceneCount { plan.advance(&session) }
        plan.submitAnswer(lesson.question.correctID, in: &session)
        plan.advance(&session)
        for _ in 0..<lesson.explanation.count { plan.advance(&session) }
        for (left, right) in lesson.matching.solution { plan.connect(left, to: right, in: &session) }
        plan.submitMatching(in: &session)
        plan.advance(&session)
        for _ in 1..<plan.challengeSceneCount { plan.advance(&session) }

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

    func testStepPlanAgreesWithStageMachineOnGateway() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "gateway" })
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
        for _ in 0..<lesson.explanation.count {
            plan.advance(&stepSession)
            stageSession.advance(lesson: lesson)
        }
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
        for _ in 1..<plan.challengeSceneCount { plan.advance(&stepSession) }
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
}
