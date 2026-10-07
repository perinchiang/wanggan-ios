import SwiftUI

/// A reusable connector diagram, with separate power, optical and Ethernet paths.
struct DevicePortsDiagram: View {
    let spec: DevicePortsSpec
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(spec.title, systemImage: "wifi.router")
                .font(.headline)
            VStack(spacing: 6) {
                ForEach(spec.ports) { port in
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(port.label).font(.headline)
                            Text("\(mediumName(port.medium)) → \(port.destination)").font(.body)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 8)
                    } else {
                    HStack(spacing: 8) {
                        socket(port.medium)
                            .frame(width: 22, height: 20)
                        Text(port.label).font(.caption.weight(.semibold))
                            .frame(width: 74, alignment: .leading)
                        VStack(spacing: 2) {
                            Text(mediumName(port.medium)).font(.caption2)
                            Rectangle().fill(port.medium == .fiber ? Theme.lime : Theme.ink.opacity(0.5))
                                .frame(height: 2)
                        }.frame(width: 30)
                        Text(port.destination).font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(port.medium == .fiber ? Theme.lime.opacity(0.2) : Theme.paper,
                                in: .rect(cornerRadius: 8))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(port.label)，通过\(mediumName(port.medium))连接\(port.destination)")
                    }
                }
            }
            if let rooms = spec.fiberRooms {
                if dynamicTypeSize.isAccessibilitySize {
                    ForEach(rooms, id: \.self) { room in
                        Text("分光器 → 光纤 → \(room)的子设备（WiFi · LAN）")
                            .font(.body).fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                GeometryReader { geometry in
                    Path { path in
                        let center = geometry.size.width / 2
                        path.move(to: CGPoint(x: center, y: 0))
                        path.addLine(to: CGPoint(x: center, y: 12))
                        for index in rooms.indices {
                            let x = geometry.size.width * (CGFloat(index) + 0.5) / CGFloat(rooms.count)
                            path.move(to: CGPoint(x: center, y: 12))
                            path.addLine(to: CGPoint(x: x, y: 12))
                            path.addLine(to: CGPoint(x: x, y: 30))
                        }
                    }.stroke(Theme.lime, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }.frame(height: 30).accessibilityHidden(true)
                HStack(alignment: .top, spacing: 6) {
                    ForEach(rooms, id: \.self) { room in
                        VStack(spacing: 5) {
                            Image(systemName: "wifi.router").font(.title3)
                            Text(room).font(.caption.weight(.bold))
                            Text("子设备").font(.caption)
                            Text("WiFi · LAN").font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Theme.lime.opacity(0.18), in: .rect(cornerRadius: 10))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("分光器通过光纤连接\(room)的子设备，子设备提供 WiFi 和 LAN 网口")
                    }
                }
                }
            }
            Text(spec.note).font(.caption).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .accessibilityIdentifier("device-ports-diagram")
    }

    private func mediumName(_ medium: PortMedium) -> String {
        switch medium {
        case .power: return "电源线"
        case .fiber: return "光纤"
        case .ethernet: return "网线"
        }
    }

    @ViewBuilder private func socket(_ medium: PortMedium) -> some View {
        switch medium {
        case .power:
            Circle().strokeBorder(Theme.ink, lineWidth: 2)
                .overlay { Circle().fill(Theme.ink).frame(width: 4, height: 4) }
        case .fiber:
            RoundedRectangle(cornerRadius: 3).fill(Theme.lime)
                .overlay { Rectangle().strokeBorder(Theme.ink, lineWidth: 2).padding(4) }
        case .ethernet:
            RoundedRectangle(cornerRadius: 2).strokeBorder(Theme.ink, lineWidth: 2)
                .overlay(alignment: .top) {
                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { _ in Rectangle().fill(Theme.ink).frame(width: 2, height: 4) }
                    }.padding(.top, 3)
                }
        }
    }
}
