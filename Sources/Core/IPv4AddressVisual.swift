import Foundation

enum IPv4VisualMode: String, Codable {
    case explain
    case practice
}

struct IPv4VisualExample: Codable, Equatable {
    let ip: String
    let prefix: Int
    let mode: IPv4VisualMode
}

struct IPv4VisualLesson: Codable, Equatable {
    let examples: [IPv4VisualExample]
}

struct IPv4AddressValue: Equatable {
    let octets: [UInt8]
    let prefix: Int

    init?(ip: String, prefix: Int) {
        guard (0...32).contains(prefix) else { return nil }
        let parts = ip.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return nil }
        let values = parts.compactMap { part -> UInt8? in
            guard !part.isEmpty, part.allSatisfy({ $0 >= "0" && $0 <= "9" }),
                  (part.count == 1 || part.first != "0") else { return nil }
            return UInt8(part)
        }
        guard values.count == 4 else { return nil }
        octets = values
        self.prefix = prefix
    }

    var binaryOctets: [String] {
        octets.map { String($0, radix: 2).leftPadded(to: 8, with: "0") }
    }

    var networkAddress: String {
        octets.enumerated().map { index, octet in
            let networkBits = min(max(prefix - index * 8, 0), 8)
            let mask = networkBits == 0 ? 0 : (255 << (8 - networkBits)) & 255
            return String(Int(octet) & mask)
        }.joined(separator: ".")
    }

    func isCorrectBoundary(_ selectedOctet: Int) -> Bool {
        prefix.isMultiple(of: 8) && selectedOctet == prefix / 8
    }
}

private extension String {
    func leftPadded(to length: Int, with character: Character) -> String {
        String(repeating: String(character), count: max(0, length - count)) + self
    }
}
