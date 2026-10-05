import Foundation

// A small, parameterized pilot: this lesson only practices whole-byte boundaries.
struct SubnetMaskIntroduction: Codable, Equatable {
    let ip: String
    let initialPrefix: Int
    let alternatePrefix: Int
    let practicePrefix: Int

    var isValid: Bool {
        IPv4AddressValue(ip: ip, prefix: initialPrefix) != nil &&
        [initialPrefix, alternatePrefix, practicePrefix].allSatisfy {
            [8, 16, 24].contains($0)
        } && Set([initialPrefix, alternatePrefix, practicePrefix]).count == 3
    }

    func prefix(for progress: SubnetMaskProgress) -> Int {
        if progress.stage == 3 { return practicePrefix }
        return progress.stage == 2 && progress.usesAlternate ? alternatePrefix : initialPrefix
    }
}

// Prefix math is independent of the pilot's narrower teaching range.
struct PrefixMask: Equatable {
    let prefix: Int

    init?(prefix: Int) {
        guard (0...32).contains(prefix) else { return nil }
        self.prefix = prefix
    }

    var octets: [Int] {
        (0..<4).map { index in
            let count = min(max(prefix - index * 8, 0), 8)
            return count == 0 ? 0 : (255 << (8 - count)) & 255
        }
    }

    var decimal: String { octets.map(String.init).joined(separator: ".") }
    var networkBitCount: Int { prefix }
    var hostBitCount: Int { 32 - prefix }

    func binaryOctet(_ octet: Int) -> String {
        let count = min(max(prefix - (octet - 1) * 8, 0), 8)
        return String(repeating: "1", count: count) + String(repeating: "0", count: 8 - count)
    }
}

struct SubnetMaskProgress: Codable, Equatable {
    private(set) var stage = 0
    private(set) var highestStage = 0
    private(set) var focusedOctet: Int?
    private(set) var inspectedNetwork = false
    private(set) var inspectedHost = false
    private(set) var usesAlternate = false
    private(set) var switchedCondition = false
    private(set) var selectedBoundary: Int?
    private(set) var boundarySubmitted = false
    private(set) var boundarySolved = false
    private(set) var finished = false

    var canAdvance: Bool {
        switch stage {
        case 0: return true
        case 1: return inspectedNetwork && inspectedHost
        case 2: return switchedCondition
        case 3: return boundarySolved
        default: return false
        }
    }

    mutating func inspect(_ octet: Int, configuration: SubnetMaskIntroduction) {
        guard configuration.isValid, stage == 1, (1...4).contains(octet) else { return }
        focusedOctet = octet
        if octet * 8 <= configuration.initialPrefix { inspectedNetwork = true }
        else { inspectedHost = true }
    }

    mutating func toggleCondition() {
        guard stage == 2 else { return }
        usesAlternate.toggle()
        switchedCondition = true
    }

    mutating func selectBoundary(_ octet: Int) {
        guard stage == 3, !boundarySolved, (1...4).contains(octet) else { return }
        selectedBoundary = octet
        boundarySubmitted = false
    }

    // nil means no new submission, so retries cannot inflate the error count.
    mutating func submitBoundary(configuration: SubnetMaskIntroduction) -> Bool? {
        guard configuration.isValid, stage == 3, !boundarySubmitted, !boundarySolved,
              let selectedBoundary else { return nil }
        boundarySubmitted = true
        boundarySolved = selectedBoundary * 8 == configuration.practicePrefix
        return boundarySolved
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
