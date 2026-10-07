import SwiftUI
import Observation

private struct ProgressHeader: Decodable {
    let schemaVersion: Int
}

@Observable @MainActor
final class LearningStore {
    private(set) var catalog: LessonCatalog?
    private(set) var ledger = ProgressLedger()
    private(set) var loadError: String?
    var storageWarning: String?
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: "haptics") }
    }
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let progressKey = "wanggan.progress.v1"
    @ObservationIgnored private var progressWritesEnabled = true

    init() {
        let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
        defaults = testing ? UserDefaults(suiteName: "wanggan.uitests")! : .standard
        if testing && ProcessInfo.processInfo.arguments.contains("--reset-progress") {
            defaults.removePersistentDomain(forName: "wanggan.uitests")
        }
        hapticsEnabled = defaults.object(forKey: "haptics") as? Bool ?? true
        do {
            guard let url = Bundle.main.url(forResource: "lessons", withExtension: "json") else {
                throw ContentError.invalid("找不到课程文件，请重新安装完整版本。")
            }
            let content = try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: url))
            try content.validate()
            catalog = content
        } catch { loadError = error.localizedDescription }

        if let data = defaults.data(forKey: progressKey) {
            do {
                let saved = try JSONDecoder().decode(ProgressLedger.self, from: data)
                ledger = saved
                let header = try JSONDecoder().decode(ProgressHeader.self, from: data)
                if header.schemaVersion == 1, defaults.data(forKey: "wanggan.progress.pre-v2") == nil {
                    defaults.set(data, forKey: "wanggan.progress.pre-v2")
                }
                if catalog != nil {
                    ledger.normalizeDrafts(in: allLessonIDs)
                    persist()
                }
            } catch {
                defaults.set(data, forKey: "wanggan.progress.recovery")
                progressWritesEnabled = false
                storageWarning = "旧进度暂时无法读取，原始数据已保留。当前进度暂不写入；重置学习进度后可重新开始。"
            }
        }

        let seedArgument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--seed-before-") })
        let seedIndex = ProcessInfo.processInfo.arguments.contains("--seed-completed-course")
            ? orderedLessonIDs.count
            : seedArgument.flatMap { orderedLessonIDs.firstIndex(of: String($0.dropFirst("--seed-before-".count))) }
        if testing, let index = seedIndex {
            // UI tests can open a later lesson without replaying every prerequisite.
            for lessonID in orderedLessonIDs.prefix(index) {
                var session = LessonSession(lessonID: lessonID)
                session.stage = .complete
                session.matchingSolved = true
                session.challengeSolved = true
                ledger.complete(session)
            }
            persist()
        }
    }

    var lessons: [Lesson] { catalog?.lessons ?? [] }
    var activeLessons: [Lesson] {
        orderedLessonIDs.compactMap { id in lessons.first { $0.id == id } }
    }
    var chapters: [Chapter] { catalog?.course.chapters ?? [] }
    var orderedLessonIDs: [String] { catalog?.orderedLessonIDs ?? [] }
    var allLessonIDs: [String] { catalog?.allLessonIDs ?? [] }
    var currentLesson: Lesson? {
        guard let id = ledger.recommendedLessonID(in: orderedLessonIDs) else { return nil }
        return lessons.first { $0.id == id }
    }
    var completedCount: Int { activeLessons.filter { ledger.lessons[$0.id] != nil }.count }

    func lessons(in chapter: Chapter) -> [Lesson] { catalog?.lessons(in: chapter.id) ?? [] }

    func isUnlocked(_ lesson: Lesson) -> Bool {
        ledger.isUnlocked(lesson.id, in: orderedLessonIDs)
    }

    func session(for lesson: Lesson) -> LessonSession {
        ledger.session(for: lesson.id)
    }

    func saveDraft(_ session: LessonSession) {
        ledger.saveDraft(session, in: allLessonIDs)
        persist()
    }

    func finish(_ session: LessonSession) -> Int {
        let result = ledger.complete(session)
        persist()
        return result
    }

    func discardDraft(_ session: LessonSession) {
        ledger.discardDraft(session)
        persist()
    }

    func resetProgress() {
        ledger = ProgressLedger()
        progressWritesEnabled = true
        defaults.removeObject(forKey: "wanggan.progress.pre-v2")
        defaults.removeObject(forKey: "wanggan.progress.recovery")
        persist()
    }

    private func persist() {
        guard progressWritesEnabled else { return }
        do { defaults.set(try JSONEncoder().encode(ledger), forKey: progressKey) }
        catch { storageWarning = "这次进度未能保存，请暂时不要关闭应用。\(error.localizedDescription)" }
    }
}

@main
struct WangGanApp: App {
    @State private var store = LearningStore()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.light)
                .tint(Theme.ink)
        }
    }
}
