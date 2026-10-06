import Foundation

struct ComicAsset: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let caption: String
}

struct ComicPanel: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let speaker: String
    let dialogue: String
    let scene: String?
    let sceneDescription: String?
    let assets: [ComicAsset]
    let action: String
}

struct ComicStory: Codable, Equatable {
    let panels: [ComicPanel]
    var isValid: Bool {
        !panels.isEmpty && Set(panels.map(\.id)).count == panels.count && panels.allSatisfy {
            !$0.title.isEmpty && !$0.speaker.isEmpty && !$0.dialogue.isEmpty && !$0.action.isEmpty &&
            ($0.scene == nil || !($0.sceneDescription ?? "").isEmpty) &&
            Set($0.assets.map(\.id)).count == $0.assets.count &&
            $0.assets.allSatisfy { !$0.id.isEmpty && !$0.name.isEmpty && !$0.caption.isEmpty }
        }
    }
}

struct ComicProgress: Codable, Equatable {
    private(set) var index = 0
    private(set) var finished = false
    mutating func advance(count: Int) {
        guard count > 0, !finished else { return }
        if index < count - 1 { index += 1 } else { finished = true }
    }
    mutating func previous() {
        guard !finished else { return }
        index = max(0, index - 1)
    }
}
