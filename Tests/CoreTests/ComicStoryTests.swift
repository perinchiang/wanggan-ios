import XCTest
@testable import WangGanCore

final class ComicStoryTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }
    private func catalog() throws -> LessonCatalog {
        try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
    }
    func testComicCannotFinishEarlyAndResumesRevealedPanels() throws {
        let content = try catalog()
        try content.validate()
        let lesson = try XCTUnwrap(content.lessons.first { $0.id == "home-two-boxes" })
        let story = try XCTUnwrap(lesson.comicStory)
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lessonID: lesson.id)
        plan.advance(&session)
        XCTAssertEqual(session.stepIndex, 0)
        var progress = ComicProgress()
        progress.advance(count: story.panels.count)
        session.comicProgress = progress
        let saved = session.stageSession(lesson: lesson)
        let decoded = try JSONDecoder().decode(LessonSession.self, from: JSONEncoder().encode(saved))
        var restored = StepSession(lesson: lesson, from: decoded)
        XCTAssertEqual(restored.id, session.id)
        XCTAssertEqual(restored.comicProgress?.index, 1)
        XCTAssertFalse(plan.isComplete(restored))
        var ledger = ProgressLedger()
        XCTAssertEqual(ledger.complete(saved), 0)
        for _ in 1..<story.panels.count { progress.advance(count: story.panels.count) }
        restored.comicProgress = progress
        plan.advance(&restored)
        XCTAssertTrue(plan.isComplete(restored))
        let completed = restored.stageSession(lesson: lesson)
        XCTAssertEqual(ledger.complete(completed), 30)
        _ = ledger.complete(completed)
        XCTAssertEqual(ledger.totalXP, 30)
        XCTAssertTrue(ledger.isUnlocked("ipv4-address-role", in: content.orderedLessonIDs))
    }
    func testAllComicImagesExistAndScenesHaveAccessibleDescriptions() throws {
        for lesson in try catalog().lessons {
            guard let story = lesson.comicStory else { continue }
            for panel in story.panels {
                let names = panel.assets.map { "comic-" + $0.id } + [panel.scene].compactMap { $0 }
                for name in names {
                    let directory = root.appendingPathComponent("Resources/Assets.xcassets/\(name).imageset")
                    let data = try Data(contentsOf: directory.appendingPathComponent("Contents.json"))
                    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
                    let images = try XCTUnwrap(object["images"] as? [[String: Any]])
                    for image in images {
                        let filename = try XCTUnwrap(image["filename"] as? String)
                        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent(filename).path))
                    }
                }
                if panel.scene != nil { XCTAssertFalse((panel.sceneDescription ?? "").isEmpty) }
            }
        }
    }
    func testExistingMainDraftSurvivesReadingNewComic() throws {
        let content = try catalog()
        var ledger = ProgressLedger()
        let old = LessonSession(lessonID: "subnet")
        ledger.saveDraft(old, in: content.allLessonIDs)
        var comic = LessonSession(lessonID: "home-two-boxes")
        comic.comicProgress = ComicProgress()
        ledger.saveDraft(comic, in: content.allLessonIDs)
        XCTAssertEqual(ledger.session(for: "subnet").id, old.id)
        XCTAssertEqual(ledger.recommendedLessonID(in: content.orderedLessonIDs), "subnet")
    }
}
