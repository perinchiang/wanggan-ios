import XCTest
@testable import WangGanCore

final class IPv4FoundationTests: XCTestCase {
    private func catalog() throws -> LessonCatalog {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try JSONDecoder().decode(
            LessonCatalog.self,
            from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json"))
        )
    }

    private func complete(_ lesson: Lesson) -> LessonSession {
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lessonID: lesson.id)

        for _ in 0..<plan.questionSceneCount {
            plan.advance(&session)
        }
        plan.submitAnswer(lesson.question.correctID, in: &session)
        plan.advance(&session)

        if let foundation = lesson.ipv4Foundation {
            var progress = IPv4FoundationProgress()
            for _ in 0..<foundation.stageCount {
                progress.advance(stageCount: foundation.stageCount)
            }
            session.ipv4FoundationProgress = progress
        }
        plan.advance(&session)

        for (left, right) in lesson.matching.solution {
            plan.connect(left, to: right, in: &session)
        }
        plan.submitMatching(in: &session)
        plan.advance(&session)

        for _ in 0..<plan.challengeSceneCount {
            plan.advance(&session)
        }
        plan.submitChallenge(lesson.challenge.correctID, in: &session)
        plan.advance(&session)

        return session.stageSession(lesson: lesson)
    }

    func testFoundationProgressIsLinearAndBacktrackingDoesNotEraseEvidence() throws {
        var progress = IPv4FoundationProgress()
        progress.previous()
        XCTAssertEqual(progress.stage, 0)

        progress.advance()
        progress.advance()
        progress.advance()
        XCTAssertEqual(progress.stage, 3)
        XCTAssertEqual(progress.highestStage, 3)
        XCTAssertFalse(progress.finished)

        progress.previous()
        XCTAssertEqual(progress.stage, 2)
        XCTAssertEqual(progress.highestStage, 3)

        progress.advance()
        progress.advance()
        XCTAssertTrue(progress.finished)
        XCTAssertEqual(progress.stage, 3)

        let restored = try JSONDecoder().decode(
            IPv4FoundationProgress.self,
            from: JSONEncoder().encode(progress)
        )
        XCTAssertEqual(restored, progress)
    }

    func testFirstThreeFoundationLessonsAreActiveAndOldPilotsAreArchived() throws {
        let content = try catalog()
        try content.validate()

        XCTAssertEqual(
            Array(content.orderedLessonIDs.prefix(3)),
            ["ipv4-address-role", "ipv4-address-format", "ipv4-octet-binary"]
        )
        XCTAssertEqual(content.archivedLessonIDs, ["ipv4-address", "subnet-mask"])

        let foundations = content.orderedLessonIDs.prefix(3).compactMap { id in
            content.lessons.first { $0.id == id }?.ipv4Foundation?.kind
        }
        XCTAssertEqual(foundations, [.addressRole, .addressFormat, .octetBinary])
    }

    func testFoundationDraftRoundTripsAndCompletionUnlocksNextLesson() throws {
        let content = try catalog()
        let lesson = try XCTUnwrap(content.lessons.first { $0.id == "ipv4-address-role" })
        let plan = LessonPlan(lesson: lesson)
        var step = StepSession(lessonID: lesson.id)

        for _ in 0..<plan.questionSceneCount {
            plan.advance(&step)
        }
        plan.submitAnswer(lesson.question.correctID, in: &step)
        plan.advance(&step)

        var progress = IPv4FoundationProgress()
        progress.advance()
        progress.advance()
        step.ipv4FoundationProgress = progress

        let draft = step.stageSession(lesson: lesson)
        let encoded = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(LessonSession.self, from: encoded)
        let restored = StepSession(lesson: lesson, from: decoded)

        XCTAssertEqual(restored.ipv4FoundationProgress, progress)
        XCTAssertEqual(restored.stepIndex, step.stepIndex)

        var ledger = ProgressLedger()
        let completed = complete(lesson)
        XCTAssertEqual(ledger.complete(completed), 30)
        XCTAssertTrue(ledger.isUnlocked("ipv4-address-format", in: content.orderedLessonIDs))
        XCTAssertFalse(ledger.isUnlocked("ipv4-octet-binary", in: content.orderedLessonIDs))
    }

    func testArchivedDraftCanCoexistWithNewActiveDraft() throws {
        let content = try catalog()
        var ledger = ProgressLedger()

        var legacy = LessonSession(lessonID: "ipv4-address")
        legacy.stage = .explanation
        var oldProgress = IPv4IntroductionProgress()
        oldProgress.selectOctet(2)
        legacy.ipv4IntroductionProgress = oldProgress
        ledger.saveDraft(legacy, in: content.allLessonIDs)

        var active = LessonSession(lessonID: "ipv4-address-role")
        active.stage = .explanation
        var foundation = IPv4FoundationProgress()
        foundation.advance()
        active.ipv4FoundationProgress = foundation
        ledger.saveDraft(active, in: content.allLessonIDs)

        XCTAssertEqual(ledger.session(for: "ipv4-address"), legacy)
        XCTAssertEqual(ledger.session(for: "ipv4-address-role"), active)
        XCTAssertEqual(
            ledger.recommendedLessonID(in: content.orderedLessonIDs),
            "ipv4-address-role"
        )
    }
}
