import Foundation

enum IPv4FoundationKind: String, Codable, Equatable {
    case addressRole
    case addressFormat
    case octetBinary
}

struct IPv4Foundation: Codable, Equatable {
    let kind: IPv4FoundationKind
    let ip: String
    let peerIP: String?
    let samples: [String]?
    let focusOctet: Int?

    var stageCount: Int { 4 }

    var isValid: Bool {
        guard IPv4AddressValue(ip: ip, prefix: 32) != nil else { return false }
        switch kind {
        case .addressRole:
            guard let peerIP else { return false }
            return IPv4AddressValue(ip: peerIP, prefix: 32) != nil
        case .addressFormat:
            guard let samples, samples.count >= 2 else { return false }
            return samples.allSatisfy { IPv4AddressValue(ip: $0, prefix: 32) != nil }
        case .octetBinary:
            guard let focusOctet else { return false }
            return (0...255).contains(focusOctet)
        }
    }
}

// Presentation can move backward while the farthest observed stage only moves forward.
struct IPv4FoundationProgress: Codable, Equatable {
    private(set) var stage = 0
    private(set) var highestStage = 0
    private(set) var finished = false

    var canAdvance: Bool { !finished }

    mutating func advance(stageCount: Int = 4) {
        guard stageCount > 0, !finished else { return }
        let last = stageCount - 1
        if stage >= last {
            finished = true
        } else {
            stage += 1
            highestStage = max(highestStage, stage)
        }
    }

    mutating func previous() {
        guard stage > 0 else { return }
        stage -= 1
    }
}
