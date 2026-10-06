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

        if let foundation = lesson.ipv4Foundation {
            var progress = IPv4FoundationProgress()
            for _ in 0..<foundation.stageCount {
                progress.advance(stageCount: foundation.stageCount)
            }
            session.ipv4FoundationProgress = progress
        }
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

    func testFoundationLessonsFollowTheStoryLessonAndOldPilotsAreArchived() throws {
        let content = try catalog()
        try content.validate()

        XCTAssertEqual(
            Array(content.orderedLessonIDs.prefix(4)),
            ["home-two-boxes", "ipv4-address-role", "ipv4-address-format", "ipv4-octet-binary"]
        )
        XCTAssertEqual(content.archivedLessonIDs, ["ipv4-address", "subnet-mask"])

        let foundations = content.orderedLessonIDs.compactMap { id -> IPv4FoundationKind? in
            content.lessons.first { $0.id == id }?.ipv4Foundation?.kind
        }
        XCTAssertEqual(foundations, [.addressRole, .addressFormat, .octetBinary])
    }

    func testFoundationDraftRoundTripsAndCompletionUnlocksNextLesson() throws {
        let content = try catalog()
        let lesson = try XCTUnwrap(content.lessons.first { $0.id == "ipv4-address-role" })
        let plan = LessonPlan(lesson: lesson)
        var step = StepSession(lessonID: lesson.id)

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

    func testObservationCompletionNeedsFinishedProgressAndRewardsExactlyOnce() throws {
        let content = try catalog()
        let foundationLessons = content.orderedLessonIDs
            .compactMap { id in content.lessons.first { $0.id == id } }
            .filter { $0.ipv4Foundation != nil }
        XCTAssertEqual(foundationLessons.map(\.id),
                       ["ipv4-address-role", "ipv4-address-format", "ipv4-octet-binary"])
        for lesson in foundationLessons {
            let plan = LessonPlan(lesson: lesson)
            XCTAssertEqual(plan.steps.map(\.kind), [.diagram, .summary])
            var fresh = StepSession(lessonID: lesson.id)
            plan.advance(&fresh)
            XCTAssertEqual(fresh.stepIndex, 0)
            fresh.stepIndex = plan.summaryIndex
            XCTAssertFalse(plan.isComplete(fresh))
            var ledger = ProgressLedger()
            var incomplete = fresh.stageSession(lesson: lesson)
            incomplete.stage = .complete
            incomplete.observationCompleted = true
            XCTAssertEqual(ledger.complete(incomplete), 0)
            let completed = complete(lesson)
            XCTAssertTrue(completed.observationCompleted == true)
            XCTAssertFalse(completed.matchingSolved)
            XCTAssertFalse(completed.challengeSolved)
            XCTAssertEqual(ledger.complete(completed), 30)
            XCTAssertEqual(ledger.complete(completed), 30)
            XCTAssertEqual(ledger.totalXP, 30)
            let decoded = try JSONDecoder().decode(LessonSession.self, from: JSONEncoder().encode(completed))
            XCTAssertTrue(plan.isComplete(StepSession(lesson: lesson, from: decoded)))
        }
    }

    func testLegacyFoundationQuestionAndMatchingDraftsResumeObservationWithoutLosingIdentity() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "ipv4-address-role" })
        var old = LessonSession(lessonID: lesson.id)
        let fresh = StepSession(lesson: lesson, from: old)
        XCTAssertEqual(fresh.stepIndex, 0)
        old.stage = .matching
        var progress = IPv4FoundationProgress()
        for _ in 0..<4 { progress.advance() }
        old.ipv4FoundationProgress = progress
        let restored = StepSession(lesson: lesson, from: old)
        XCTAssertEqual(restored.id, old.id)
        XCTAssertTrue(LessonPlan(lesson: lesson).isComplete(restored))
        XCTAssertFalse(restored.challengeSolved)
        XCTAssertFalse(restored.matchingSolved)
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
