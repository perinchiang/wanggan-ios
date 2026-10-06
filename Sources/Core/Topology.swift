import Foundation

enum PortMedium: String, Codable {
    case power, fiber, ethernet
}

struct DevicePortConnection: Codable, Equatable, Identifiable {
    let id: String
    let label: String
    let medium: PortMedium
    let destination: String
}

/// Physical connectors and their destinations; power is never a data path.
struct DevicePortsSpec: Codable, Equatable {
    let title: String
    let ports: [DevicePortConnection]
    /// Optional optical branches from the distribution unit to room satellites.
    let fiberRooms: [String]?
    let note: String

    var isValid: Bool {
        !title.isEmpty && !note.isEmpty && !ports.isEmpty &&
        Set(ports.map(\.id)).count == ports.count &&
        ports.filter { $0.medium == .power }.count == 1 &&
        ports.allSatisfy { !$0.id.isEmpty && !$0.label.isEmpty && !$0.destination.isEmpty } &&
        (fiberRooms.map { !$0.isEmpty && Set($0).count == $0.count && $0.allSatisfy { !$0.isEmpty } } ?? true) &&
        (fiberRooms == nil || ports.contains { $0.medium == .fiber && $0.id == "downstream" })
    }
}

struct AnswerExplanation: Codable, Equatable, Identifiable {
    let id: String
    let text: String
    let diagram: DevicePortsSpec?
    let homeNetwork: HomeNetworkSpec?
    let termIntroduction: TermIntroduction?

    var isValid: Bool {
        !id.isEmpty && !text.isEmpty &&
        (diagram != nil || homeNetwork != nil || termIntroduction != nil) &&
        (diagram?.isValid ?? true) &&
        (homeNetwork?.isValid ?? true) && (termIntroduction?.isValid ?? true)
    }
}

struct TermIntroduction: Codable, Equatable {
    let name: String
    let englishName: String
    let chineseName: String

    var isValid: Bool {
        [name, englishName, chineseName].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

/// A simplified home plan: one gateway and up to three room endpoints.
/// Optical distribution is intentionally collapsed into a labelled junction.
struct HomeNetworkSpec: Codable, Equatable {
    let title: String
    let uplink: PortMedium
    let uplinkLabel: String
    let gatewayLabel: String
    let roomMedium: PortMedium
    let rooms: [String]
    let roomDeviceLabel: String
    let note: String

    var isValid: Bool {
        uplink != .power && roomMedium != .power &&
        !title.isEmpty && !uplinkLabel.isEmpty && !gatewayLabel.isEmpty &&
        !roomDeviceLabel.isEmpty && !note.isEmpty &&
        (1...3).contains(rooms.count) && Set(rooms).count == rooms.count &&
        rooms.allSatisfy { !$0.isEmpty }
    }
}

/// A node in a teaching topology: one device or medium shown as a native symbol.
struct TopologyNode: Codable, Equatable, Identifiable {
    let id: String
    let symbol: String
    let label: String
    /// 1-based reveal stage; stage 1 is visible when the diagram first appears.
    let stage: Int
    /// Grid coordinates, 0-based. Column 0 is the left edge.
    let column: Int
    let row: Int
}

/// A connection between two nodes, drawn as a line between their centers.
struct TopologyLink: Codable, Equatable, Identifiable {
    let from: String
    let to: String
    /// 1-based reveal stage; a link appears once its stage is reached.
    let stage: Int
    let wireless: Bool?
    var id: String { "\(from)-\(to)" }
}

/// Data-driven native diagram: nodes, links, and an optional packet flow path.
/// Lessons describe the topology as data; the app renders it with the flat
/// black / paper / lime design language instead of bundled artwork.
struct TopologySpec: Codable, Equatable {
    let nodes: [TopologyNode]
    let links: [TopologyLink]
    /// Ordered node IDs the traveling packet follows once every flow node is visible.
    let flow: [String]
    /// Spoken summary for VoiceOver; the rendered diagram is hidden from assistive tech.
    let accessibilitySummary: String

    var isValid: Bool {
        guard !nodes.isEmpty,
              Set(nodes.map(\.id)).count == nodes.count,
              nodes.allSatisfy({ !$0.id.isEmpty && !$0.symbol.isEmpty && !$0.label.isEmpty && $0.stage >= 1 && $0.column >= 0 && $0.row >= 0 }) else { return false }
        let nodeIDs = Set(nodes.map(\.id))
        guard !links.isEmpty,
              Set(links.map(\.id)).count == links.count,
              links.allSatisfy({ nodeIDs.contains($0.from) && nodeIDs.contains($0.to) && $0.from != $0.to && $0.stage >= 1 }) else { return false }
        guard flow.count >= 2,
              Set(flow).count == flow.count,
              flow.allSatisfy(nodeIDs.contains) else { return false }
        return !accessibilitySummary.isEmpty
    }

    /// The last stage at which any node or link still appears.
    var maxStage: Int {
        Swift.max(nodes.map(\.stage).max() ?? 1, links.map(\.stage).max() ?? 1)
    }

    /// The last stage at which any flow node appears; the flow animation starts then.
    var flowStage: Int {
        let stages = flow.compactMap { id in nodes.first { $0.id == id }?.stage }
        return stages.max() ?? maxStage
    }

    func nodes(visibleAt stage: Int) -> [TopologyNode] {
        nodes.filter { $0.stage <= stage }
    }

    func links(visibleAt stage: Int) -> [TopologyLink] {
        links.filter { $0.stage <= stage }
    }
}
