import Foundation

struct IPv4Introduction: Codable, Equatable {
    let ip: String
}

// Presentation can move back; observed steps and completion only move forward.
struct IPv4IntroductionProgress: Codable, Equatable {
    private(set) var stage = 0
    private(set) var highestStage = 0
    private(set) var selectedOctet: Int?
    private(set) var rangeValue = 0
    private(set) var inspectedRange = false
    private(set) var finished = false

    var canAdvance: Bool {
        switch stage {
        case 0: return selectedOctet != nil
        case 1, 3: return true
        case 2: return inspectedRange
        default: return false
        }
    }

    mutating func selectOctet(_ value: Int) {
        guard stage == 0, (1...4).contains(value) else { return }
        selectedOctet = value
    }

    mutating func toggleRange() {
        guard stage == 2 else { return }
        rangeValue = rangeValue == 0 ? 255 : 0
        inspectedRange = true
    }

    mutating func advance() {
        guard canAdvance else { return }
        if stage == 3 { finished = true }
        else { stage += 1; highestStage = max(highestStage, stage) }
    }

    mutating func previous() {
        guard stage > 0 else { return }
        stage -= 1
    }
}
