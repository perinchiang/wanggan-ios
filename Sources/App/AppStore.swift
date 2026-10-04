import SwiftUI
import Observation

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
                guard saved.schemaVersion == 1 else { throw ContentError.invalid("未知进度版本") }
                ledger = saved
                if let draft = ledger.draft,
                   !lessons.contains(where: { $0.id == draft.lessonID }) { ledger.draft = nil }
            } catch {
                defaults.set(data, forKey: "wanggan.progress.recovery")
                storageWarning = "旧进度暂时无法读取，原始数据已保留在本机备份。当前使用新进度。"
            }
        }
    }

    var lessons: [Lesson] { catalog?.lessons ?? [] }
    var currentLesson: Lesson? { lessons.first { ledger.lessons[$0.id] == nil } ?? lessons.first }
    var completedCount: Int { lessons.filter { ledger.lessons[$0.id] != nil }.count }
    var dueLessons: [Lesson] { lessons.filter { ledger.isDue($0.id) } }

    func isUnlocked(_ lesson: Lesson) -> Bool {
        guard let index = lessons.firstIndex(where: { $0.id == lesson.id }) else { return false }
        return index == 0 || ledger.lessons[lessons[index - 1].id] != nil
    }

    func session(for lesson: Lesson) -> LessonSession {
        if let draft = ledger.draft, draft.lessonID == lesson.id, draft.stage != .complete { return draft }
        return LessonSession(lessonID: lesson.id)
    }

    func saveDraft(_ session: LessonSession) {
        ledger.draft = session.stage == .complete ? nil : session
        persist()
    }

    func finish(_ session: LessonSession) -> Int {
        let result = ledger.complete(session)
        ledger.draft = nil
        persist()
        return result
    }

    func resetProgress() {
        ledger = ProgressLedger()
        defaults.removeObject(forKey: "wanggan.progress.recovery")
        persist()
    }

    private func persist() {
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
