import SwiftUI

/// Layout the visible cards first, then connect their measured edges.
struct HomeNetworkDiagram: View {
    let spec: HomeNetworkSpec
    @ScaledMetric(relativeTo: .caption) private var branchSpacing: CGFloat = 44

    private var opticalRooms: Bool { spec.roomMedium == .fiber }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(spec.title).font(.headline)
            VStack(alignment: .leading, spacing: 0) {
                Text(spec.uplinkLabel).font(.caption).foregroundStyle(Theme.ink)
                    .padding(.bottom, 8)
                HStack(spacing: 28) {
                    if let modem = spec.opticalModemLabel {
                        device(id: "optical-modem", symbol: "externaldrive.connected.to.line.below",
                               label: modem, expanded: true)
                    }
                    device(id: "gateway", symbol: "wifi.router", label: spec.gatewayLabel,
                           expanded: spec.opticalModemLabel != nil)
                }
                .padding(.horizontal, 36)
                .frame(maxWidth: .infinity)
                Color.clear.frame(height: branchSpacing)
                HStack(alignment: .top, spacing: 24) {
                    ForEach(Array(spec.rooms.prefix(2)), id: \.self) { room in
                        roomCard(room)
                    }
                }
                if let room = spec.rooms.dropFirst(2).first {
                    Color.clear.frame(height: 24)
                    roomCard(room)
                }
            }
            .backgroundPreferenceValue(HomeNetworkBoundsKey.self) { anchors in
                GeometryReader { geometry in
                    HomeNetworkCables(spec: spec, width: geometry.size.width,
                                      bounds: anchors.mapValues { geometry[$0] })
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
            Text(spec.note).font(.caption).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .accessibilityIdentifier("home-network-diagram")
    }

    private func device(id: String, symbol: String, label: String, expanded: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol).font(.title2)
            Text(label).font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: expanded ? .infinity : nil)
        .padding(10)
        .background(Theme.paper, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.line, lineWidth: 1))
        .anchorPreference(key: HomeNetworkBoundsKey.self, value: .bounds) { [id: $0] }
    }

    private func roomCard(_ room: String) -> some View {
        let television = room == spec.rooms.dropFirst(2).first
        return VStack(spacing: 6) {
            Text(room).font(.caption.weight(.bold))
            Image(systemName: opticalRooms ? "wifi.router" : (television ? "tv" : "desktopcomputer"))
                .font(.title3)
            Text(opticalRooms ? spec.roomDeviceLabel : (television ? "电视" : "电脑"))
                .font(.caption2).foregroundStyle(Theme.muted)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Theme.paper, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.line, lineWidth: 1))
        .anchorPreference(key: HomeNetworkBoundsKey.self, value: .bounds) { ["room-\(room)": $0] }
    }

    private var accessibilitySummary: String {
        let incoming: String
        if let modem = spec.opticalModemLabel {
            incoming = "\(spec.uplinkLabel)连接\(modem)，\(modem)通过网线连接\(spec.gatewayLabel)"
        } else {
            incoming = "\(spec.uplinkLabel)通过\(spec.uplink == .fiber ? "光纤" : "网线")连接\(spec.gatewayLabel)"
        }
        return "\(incoming)，再通过\(opticalRooms ? "光纤分配后" : "网线")连接\(spec.rooms.joined(separator: "、"))的\(spec.roomDeviceLabel)。"
    }
}

private struct HomeNetworkBoundsKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

private struct HomeNetworkCables: View {
    let spec: HomeNetworkSpec
    let width: CGFloat
    let bounds: [String: CGRect]

    var body: some View {
        ZStack {
            if let gateway = bounds["gateway"],
               let roomTop = spec.rooms.compactMap({ bounds["room-\($0)"]?.minY }).min() {
                let incoming = bounds["optical-modem"] ?? gateway
                cable(from: CGPoint(x: 0, y: incoming.midY),
                      to: CGPoint(x: incoming.minX, y: incoming.midY), medium: spec.uplink)
                if let modem = bounds["optical-modem"] {
                    cable(from: CGPoint(x: modem.maxX, y: modem.midY),
                          to: CGPoint(x: gateway.minX, y: gateway.midY), medium: .ethernet)
                }
                let junction = CGPoint(x: width / 2, y: (gateway.maxY + roomTop) / 2)
                Path { path in
                    path.move(to: CGPoint(x: gateway.midX, y: gateway.maxY))
                    path.addLine(to: CGPoint(x: gateway.midX, y: junction.y))
                    path.addLine(to: junction)
                }.stroke(Theme.ink.opacity(spec.roomMedium == .fiber ? 1 : 0.7), style: style(spec.roomMedium))
                ForEach(spec.rooms, id: \.self) { room in
                    if let target = bounds["room-\(room)"] {
                        Path { path in
                            path.move(to: junction)
                            path.addLine(to: CGPoint(x: target.midX, y: junction.y))
                            path.addLine(to: CGPoint(x: target.midX, y: target.minY))
                        }.stroke(Theme.ink.opacity(spec.roomMedium == .fiber ? 1 : 0.7), style: style(spec.roomMedium))
                    }
                }
            }
        }
    }

    private func cable(from: CGPoint, to: CGPoint, medium: PortMedium) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }.stroke(Theme.ink.opacity(medium == .fiber ? 1 : 0.7), style: style(medium))
    }

    private func style(_ medium: PortMedium) -> StrokeStyle {
        StrokeStyle(lineWidth: medium == .fiber ? 3 : 2, lineCap: .butt,
                    dash: medium == .fiber ? [] : [5, 4])
    }
}
