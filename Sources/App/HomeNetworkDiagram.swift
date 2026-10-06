import SwiftUI

/// A compact house plan. Cable routes terminate at the actual gateway / room icon.
struct HomeNetworkDiagram: View {
    let spec: HomeNetworkSpec
    @ScaledMetric(relativeTo: .caption) private var diagramHeight: CGFloat = 285

    private var opticalRooms: Bool { spec.roomMedium == .fiber }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(spec.title).font(.headline)
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let gateway = CGPoint(x: width / 2, y: height * 0.12)
                let junction = CGPoint(x: width / 2, y: height * 0.3)
                ZStack {
                    ForEach(Array(spec.rooms.enumerated()), id: \.element) { index, room in
                        let point = roomPoint(index, width: width, height: height)
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.paper)
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.line, lineWidth: 1))
                            .frame(width: index == 2 ? width - 8 : width / 2 - 8, height: height * 0.29)
                            .position(point)
                    }
                    cable(from: CGPoint(x: 0, y: gateway.y), to: gateway, medium: spec.uplink)
                    Text(spec.uplinkLabel).font(.caption2).foregroundStyle(Theme.muted)
                        .position(x: width * 0.2, y: height * 0.03)
                    ForEach(Array(spec.rooms.enumerated()), id: \.element) { index, _ in
                        let point = roomPoint(index, width: width, height: height)
                        Path { path in
                            path.move(to: CGPoint(x: gateway.x, y: gateway.y + 16))
                            path.addLine(to: junction)
                            if index != 2 { path.addLine(to: CGPoint(x: point.x, y: junction.y)) }
                            path.addLine(to: CGPoint(x: point.x, y: point.y - 9))
                        }
                        .stroke(opticalRooms ? Theme.lime : Theme.ink.opacity(0.55),
                                style: StrokeStyle(lineWidth: opticalRooms ? 3 : 2, lineCap: .round,
                                                   dash: opticalRooms ? [] : [5, 4]))
                    }
                    Text(opticalRooms ? "光纤分支" : "网线分支")
                        .font(.caption2).foregroundStyle(Theme.muted)
                        .padding(.horizontal, 5).background(Theme.surface)
                        .position(x: width / 2, y: junction.y)
                    VStack(spacing: 3) {
                        Image(systemName: "wifi.router").font(.title2)
                        Text(spec.gatewayLabel).font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 10).background(Theme.surface)
                    .position(gateway)
                    ForEach(Array(spec.rooms.enumerated()), id: \.element) { index, room in
                        let point = roomPoint(index, width: width, height: height)
                        VStack(spacing: 5) {
                            Text(room).font(.caption.weight(.bold))
                            Image(systemName: opticalRooms ? "wifi.router" : (index == 2 ? "tv" : "desktopcomputer"))
                                .font(.title3).padding(.horizontal, 6).background(Theme.paper)
                            Text(opticalRooms ? spec.roomDeviceLabel : (index == 2 ? "电视" : "电脑"))
                                .font(.caption2).foregroundStyle(Theme.muted)
                        }.position(point)
                    }
                }
            }
            .frame(height: diagramHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(spec.uplinkLabel)通过\(spec.uplink == .fiber ? "光纤" : "网线")连接\(spec.gatewayLabel)，再通过\(opticalRooms ? "光纤分配后" : "网线")连接\(spec.rooms.joined(separator: "、"))的\(spec.roomDeviceLabel)。")
            Text(spec.note).font(.caption).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .accessibilityIdentifier("home-network-diagram")
    }

    private func roomPoint(_ index: Int, width: CGFloat, height: CGFloat) -> CGPoint {
        switch index {
        case 0: return CGPoint(x: width * 0.25, y: height * 0.51)
        case 1: return CGPoint(x: width * 0.75, y: height * 0.51)
        default: return CGPoint(x: width * 0.5, y: height * 0.85)
        }
    }

    private func cable(from: CGPoint, to: CGPoint, medium: PortMedium) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(medium == .fiber ? Theme.lime : Theme.ink.opacity(0.55),
                style: StrokeStyle(lineWidth: medium == .fiber ? 3 : 2, lineCap: .round,
                                   dash: medium == .fiber ? [] : [5, 4]))
    }
}
